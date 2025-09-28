import os
import sys
import json
import boto3
import snowflake.connector
import asyncio
import aiohttp
import ssl
import tempfile
from datetime import datetime
import logging
import signal
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
PROCESSOR_ID = os.environ.get('PROCESSOR_ID', 'unknown')
MAX_ENTRIES = int(os.environ.get('MAX_ENTRIES', '8'))
ENVIRONMENT = os.environ['ENVIRONMENT']
CERT_BUCKET = os.environ['CERT_BUCKET']

# Snowflake configuration
SNOWFLAKE_ACCOUNT = os.environ['SNOWFLAKE_ACCOUNT']
SNOWFLAKE_WAREHOUSE = os.environ['SNOWFLAKE_WAREHOUSE']
SNOWFLAKE_DATABASE = os.environ['SNOWFLAKE_DATABASE']
SNOWFLAKE_SCHEMA = os.environ['SNOWFLAKE_SCHEMA']
SNOWFLAKE_TABLE = os.environ['SNOWFLAKE_TABLE']
SNOWFLAKE_USER = os.environ['SNOWFLAKE_USER']
SNOWFLAKE_PASSWORD = os.environ['SNOWFLAKE_PASSWORD']

# External service configuration
EXTERNAL_SERVICE_URL = os.environ.get('EXTERNAL_SERVICE_URL', 'https://api.example.com/process')

s3_client = boto3.client('s3')

class CertificateManager:
    """Manages downloading and storing certificates"""

    def __init__(self):
        self.cert_dir = tempfile.mkdtemp()
        self.cert_path = None
        self.key_path = None
        self.ca_path = None

    def download_certificates(self):
        """Download certificates from S3"""
        try:
            cert_prefix = f"{ENVIRONMENT}/"

            # Download client certificate
            self.cert_path = os.path.join(self.cert_dir, 'client.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}client.pem",
                self.cert_path
            )

            # Download client key
            self.key_path = os.path.join(self.cert_dir, 'client-key.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}client-key.pem",
                self.key_path
            )

            # Download CA certificate
            self.ca_path = os.path.join(self.cert_dir, 'ca-cert.pem')
            s3_client.download_file(
                CERT_BUCKET,
                f"{cert_prefix}ca-cert.pem",
                self.ca_path
            )

            logger.info("Successfully downloaded certificates")
            return True

        except Exception as e:
            logger.error(f"Failed to download certificates: {str(e)}")
            return False

    def get_ssl_context(self):
        """Create SSL context with client certificates"""
        ssl_context = ssl.create_default_context(cafile=self.ca_path)
        ssl_context.load_cert_chain(certfile=self.cert_path, keyfile=self.key_path)
        return ssl_context

    def cleanup(self):
        """Clean up temporary certificate files"""
        try:
            if self.cert_path and os.path.exists(self.cert_path):
                os.remove(self.cert_path)
            if self.key_path and os.path.exists(self.key_path):
                os.remove(self.key_path)
            if self.ca_path and os.path.exists(self.ca_path):
                os.remove(self.ca_path)
            if self.cert_dir and os.path.exists(self.cert_dir):
                os.rmdir(self.cert_dir)
        except Exception as e:
            logger.warning(f"Certificate cleanup error: {str(e)}")

class SnowflakeProcessor:
    """Main processor class"""

    def __init__(self):
        self.processor_id = PROCESSOR_ID
        self.cert_manager = CertificateManager()
        self.conn = None
        self.shutdown = False

    def get_connection(self):
        """Get Snowflake connection"""
        return snowflake.connector.connect(
            user=SNOWFLAKE_USER,
            password=SNOWFLAKE_PASSWORD,
            account=SNOWFLAKE_ACCOUNT,
            warehouse=SNOWFLAKE_WAREHOUSE,
            database=SNOWFLAKE_DATABASE,
            schema=SNOWFLAKE_SCHEMA
        )

    def claim_entries(self, count):
        """Atomically claim entries for processing"""
        cursor = self.conn.cursor()
        try:
            # Use a single UPDATE statement with LIMIT for atomic claiming
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'processing',
                processor_id = %s,
                claimed_at = %s
            WHERE id IN (
                SELECT id
                FROM {SNOWFLAKE_TABLE}
                WHERE status = 'pending'
                  AND (retry_count < 3 OR retry_count IS NULL)
                ORDER BY created_at ASC
                LIMIT %s
                FOR UPDATE
            )
            RETURNING id, data
            """

            cursor.execute(query, (self.processor_id, datetime.utcnow(), count))

            entries = []
            for row in cursor:
                entries.append({
                    'id': row[0],
                    'data': json.loads(row[1]) if isinstance(row[1], str) else row[1]
                })

            self.conn.commit()
            logger.info(f"Claimed {len(entries)} entries")
            return entries

        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to claim entries: {str(e)}")
            return []
        finally:
            cursor.close()

    def mark_entry_completed(self, entry_id):
        """Mark an entry as completed"""
        cursor = self.conn.cursor()
        try:
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'completed',
                completed_at = %s
            WHERE id = %s AND processor_id = %s
            """

            cursor.execute(query, (datetime.utcnow(), entry_id, self.processor_id))
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to mark entry {entry_id} as completed: {str(e)}")
        finally:
            cursor.close()

    def mark_entry_failed(self, entry_id, error_message):
        """Mark an entry as failed"""
        cursor = self.conn.cursor()
        try:
            query = f"""
            UPDATE {SNOWFLAKE_TABLE}
            SET status = 'failed',
                failed_at = %s,
                error_message = %s
            WHERE id = %s AND processor_id = %s
            """

            cursor.execute(query, (datetime.utcnow(), error_message[:1000], entry_id, self.processor_id))
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to mark entry {entry_id} as failed: {str(e)}")
        finally:
            cursor.close()

    async def process_entry(self, session, entry, ssl_context):
        """Process a single entry by calling external service"""
        entry_id = entry['id']

        try:
            logger.info(f"Processing entry {entry_id}")

            # Prepare request payload
            payload = {
                'entry_id': entry_id,
                'data': entry['data'],
                'processor_id': self.processor_id,
                'timestamp': datetime.utcnow().isoformat()
            }

            # Call external service
            async with session.post(
                EXTERNAL_SERVICE_URL,
                json=payload,
                ssl=ssl_context,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:

                if response.status == 200:
                    result = await response.json()
                    logger.info(f"Successfully processed entry {entry_id}")
                    self.mark_entry_completed(entry_id)
                    return {'entry_id': entry_id, 'status': 'success', 'result': result}
                else:
                    error_msg = f"External service returned status {response.status}"
                    logger.error(f"Failed to process entry {entry_id}: {error_msg}")
                    self.mark_entry_failed(entry_id, error_msg)
                    return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}

        except asyncio.TimeoutError:
            error_msg = "External service timeout"
            logger.error(f"Timeout processing entry {entry_id}")
            self.mark_entry_failed(entry_id, error_msg)
            return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error processing entry {entry_id}: {error_msg}")
            self.mark_entry_failed(entry_id, error_msg)
            return {'entry_id': entry_id, 'status': 'failed', 'error': error_msg}

    async def process_batch(self, entries):
        """Process a batch of entries concurrently"""
        ssl_context = self.cert_manager.get_ssl_context()

        connector = aiohttp.TCPConnector(ssl=ssl_context)
        async with aiohttp.ClientSession(connector=connector) as session:
            tasks = [
                self.process_entry(session, entry, ssl_context)
                for entry in entries
            ]

            results = await asyncio.gather(*tasks, return_exceptions=True)

            # Log results
            successful = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
            failed = len(results) - successful

            logger.info(f"Batch processing completed: {successful} successful, {failed} failed")
            return results

    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, initiating shutdown...")
        self.shutdown = True

    def run(self):
        """Main processing loop"""
        # Set up signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)

        try:
            # Download certificates
            if not self.cert_manager.download_certificates():
                logger.error("Failed to download certificates, exiting")
                return 1

            # Connect to Snowflake
            self.conn = self.get_connection()
            logger.info(f"Connected to Snowflake as processor {self.processor_id}")

            # Claim entries
            entries = self.claim_entries(MAX_ENTRIES)

            if not entries:
                logger.info("No entries to process")
                return 0

            logger.info(f"Starting to process {len(entries)} entries")

            # Process entries
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            results = loop.run_until_complete(self.process_batch(entries))
            loop.close()

            # Summary
            successful = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
            logger.info(f"Processing complete: {successful}/{len(entries)} successful")

            return 0

        except Exception as e:
            logger.error(f"Fatal error: {str(e)}")
            return 1

        finally:
            # Cleanup
            if self.conn:
                self.conn.close()
            self.cert_manager.cleanup()

def main():
    """Entry point"""
    processor = SnowflakeProcessor()
    sys.exit(processor.run())

if __name__ == '__main__':
    main()