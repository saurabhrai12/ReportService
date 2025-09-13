#!/usr/bin/env python3
"""
Enhanced Report Service with Dual Trigger Support
This service supports both ADHOC (immediate) and SCHEDULED (time-based) report processing
"""

import os
import time
import logging
import signal
import sys
import json
import boto3
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
import snowflake.connector
from snowflake.connector import DictCursor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class EnhancedReportService:
    """Enhanced Report Service with dual trigger type handling"""
    
    def __init__(self):
        """Initialize the enhanced report service"""
        self.snowflake_config = self._load_snowflake_config()
        
        # AWS clients
        self.ecs_client = boto3.client('ecs')
        self.s3_client = boto3.client('s3')
        self.sns_client = boto3.client('sns', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))
        
        # Configuration
        self.reports_bucket = os.getenv('REPORTS_BUCKET', 'your-reports-bucket')
        self.ecs_service_arn = os.getenv('ECS_SERVICE_ARN')
        self.running = True
        
        # Performance tracking
        self.stats = {
            'adhoc_processed': 0,
            'scheduled_processed': 0,
            'total_processed': 0,
            'errors': 0,
            'start_time': datetime.now()
        }
        
        # Handle graceful shutdown
        signal.signal(signal.SIGTERM, self.shutdown_handler)
        signal.signal(signal.SIGINT, self.shutdown_handler)
        
        logger.info("Enhanced Report Service initialized")
        
    def _load_snowflake_config(self) -> dict:
        """Load Snowflake configuration from AWS Secrets Manager"""
        try:
            # Try to load from Secrets Manager first
            secrets_client = boto3.client('secretsmanager', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))
            response = secrets_client.get_secret_value(SecretId='report-service/snowflake')
            secret = json.loads(response['SecretString'])
            
            logger.info(f"Loaded Snowflake config from Secrets Manager for account: {secret.get('account', 'unknown')}")
            return secret
            
        except Exception as e:
            logger.warning(f"Failed to load from Secrets Manager: {e}")
            logger.info("Falling back to environment variables")
            
            # Fallback to environment variables
            return {
                'user': os.getenv('SNOWFLAKE_USER'),
                'password': os.getenv('SNOWFLAKE_PASSWORD'),
                'account': os.getenv('SNOWFLAKE_ACCOUNT', 'your-account'),
                'database': os.getenv('SNOWFLAKE_DATABASE', 'REPORTING_DB'),
                'schema': os.getenv('SNOWFLAKE_SCHEMA', 'CONFIG'),
                'warehouse': os.getenv('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH')
            }
        
    def shutdown_handler(self, signum: int, frame) -> None:
        """Handle graceful shutdown signals"""
        logger.info(f"Received shutdown signal {signum}, stopping service...")
        self.running = False
        
    def get_snowflake_connection(self) -> snowflake.connector.SnowflakeConnection:
        """Get Snowflake connection with error handling"""
        try:
            conn = snowflake.connector.connect(**self.snowflake_config)
            logger.debug("Snowflake connection established")
            return conn
        except Exception as e:
            logger.error(f"Failed to connect to Snowflake: {e}")
            raise
            
    def validate_connection(self) -> bool:
        """Validate Snowflake connection and required tables"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor()
            
            # Check if required tables exist
            cursor.execute("""
                SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'CONFIG' 
                AND TABLE_NAME = 'REPORT_CONFIG'
            """)
            
            table_count = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            
            if table_count == 0:
                logger.error("Required table REPORT_CONFIG not found")
                return False
                
            logger.info("Snowflake connection and tables validated successfully")
            return True
            
        except Exception as e:
            logger.error(f"Connection validation failed: {e}")
            return False
            
    def check_for_adhoc_work(self) -> int:
        """Check for ADHOC reports that need processing"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT COUNT(*) 
                FROM REPORTING_DB.CONFIG.V_PENDING_ADHOC_REPORTS
            """)
            
            count = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            
            logger.debug(f"Found {count} pending ADHOC reports")
            return count
            
        except Exception as e:
            logger.error(f"Error checking for ADHOC work: {e}")
            return 0
            
    def check_for_scheduled_work(self) -> int:
        """Check for SCHEDULED reports that are due"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT COUNT(*) 
                FROM REPORTING_DB.CONFIG.V_DUE_SCHEDULED_REPORTS
            """)
            
            count = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            
            logger.debug(f"Found {count} due SCHEDULED reports")
            return count
            
        except Exception as e:
            logger.error(f"Error checking for SCHEDULED work: {e}")
            return 0
            
    def get_adhoc_reports(self) -> List[Dict[str, Any]]:
        """Get pending ADHOC reports ordered by priority"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor(DictCursor)
            
            cursor.execute("""
                SELECT 
                    CONFIG_ID, REPORT_NAME, REPORT_TYPE, PRIORITY,
                    REPORT_CONFIG, OUTPUT_FORMAT,
                    NOTIFY_ON_COMPLETION, NOTIFICATION_RECIPIENTS,
                    CREATED_TIMESTAMP
                FROM REPORTING_DB.CONFIG.V_PENDING_ADHOC_REPORTS
                ORDER BY PRIORITY ASC, CREATED_TIMESTAMP DESC
            """)
            
            reports = cursor.fetchall()
            cursor.close()
            conn.close()
            
            logger.info(f"Retrieved {len(reports)} ADHOC reports")
            return reports
            
        except Exception as e:
            logger.error(f"Error getting ADHOC reports: {e}")
            return []
            
    def get_scheduled_reports(self) -> List[Dict[str, Any]]:
        """Get due SCHEDULED reports ordered by due time"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor(DictCursor)
            
            cursor.execute("""
                SELECT 
                    CONFIG_ID, REPORT_NAME, REPORT_TYPE, 
                    SCHEDULE_EXPRESSION, NEXT_RUN_TIME, LAST_RUN_TIME,
                    REPORT_CONFIG, OUTPUT_FORMAT,
                    NOTIFY_ON_COMPLETION, NOTIFICATION_RECIPIENTS,
                    CREATED_TIMESTAMP
                FROM REPORTING_DB.CONFIG.V_DUE_SCHEDULED_REPORTS
                ORDER BY NEXT_RUN_TIME ASC NULLS FIRST
            """)
            
            reports = cursor.fetchall()
            cursor.close()
            conn.close()
            
            logger.info(f"Retrieved {len(reports)} due SCHEDULED reports")
            return reports
            
        except Exception as e:
            logger.error(f"Error getting SCHEDULED reports: {e}")
            return []
            
    def update_report_status(self, config_id: str, status: str, error_message: Optional[str] = None) -> bool:
        """Update report status in Snowflake"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor()
            
            if error_message:
                cursor.execute(f"""
                    UPDATE REPORTING_DB.CONFIG.REPORT_CONFIG 
                    SET STATUS = '{status}',
                        ERROR_MESSAGE = '{error_message.replace("'", "''")}',
                        ERROR_TIMESTAMP = CURRENT_TIMESTAMP(),
                        UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()
                    WHERE CONFIG_ID = '{config_id}'
                """)
            else:
                cursor.execute(f"""
                    UPDATE REPORTING_DB.CONFIG.REPORT_CONFIG 
                    SET STATUS = '{status}',
                        UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()
                    WHERE CONFIG_ID = '{config_id}'
                """)
                
            conn.commit()
            cursor.close()
            conn.close()
            
            logger.debug(f"Updated report {config_id} status to {status}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating report status for {config_id}: {e}")
            return False
            
    def update_scheduled_report_times(self, config_id: str) -> bool:
        """Update last run time and calculate next run time for scheduled reports"""
        try:
            conn = self.get_snowflake_connection()
            cursor = conn.cursor()
            
            # Update last run time and calculate next run time
            cursor.execute(f"""
                UPDATE REPORTING_DB.CONFIG.REPORT_CONFIG 
                SET LAST_RUN_TIME = CURRENT_TIMESTAMP(),
                    STATUS = 'PENDING',
                    UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()
                WHERE CONFIG_ID = '{config_id}'
            """)
            
            # Get schedule expression for next run calculation
            cursor.execute(f"""
                SELECT SCHEDULE_EXPRESSION 
                FROM REPORTING_DB.CONFIG.REPORT_CONFIG 
                WHERE CONFIG_ID = '{config_id}'
            """)
            
            result = cursor.fetchone()
            if result and result[0]:
                schedule_expression = result[0]
                # Call stored procedure to update next run time
                cursor.execute(f"""
                    CALL REPORTING_DB.CONFIG.UPDATE_NEXT_RUN_TIME('{config_id}', '{schedule_expression}')
                """)
                
            conn.commit()
            cursor.close()
            conn.close()
            
            logger.debug(f"Updated scheduled times for report {config_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating scheduled times for {config_id}: {e}")
            return False
            
    def generate_report(self, report: Dict[str, Any], trigger_type: str) -> Tuple[bool, Optional[str]]:
        """
        Generate report - implement your specific logic here
        Returns (success, output_path_or_error)
        """
        config_id = report['CONFIG_ID']
        report_name = report['REPORT_NAME']
        report_type = report['REPORT_TYPE']
        
        try:
            logger.info(f"Generating {trigger_type} report: {config_id} - {report_name}")
            
            # Parse report configuration
            report_config = {}
            if report.get('REPORT_CONFIG'):
                if isinstance(report['REPORT_CONFIG'], str):
                    report_config = json.loads(report['REPORT_CONFIG'])
                else:
                    report_config = report['REPORT_CONFIG']
                    
            # Different processing strategies based on trigger type
            if trigger_type == 'ADHOC':
                # ADHOC reports - immediate, high priority processing
                processing_time = self._process_adhoc_report(report, report_config)
                
            elif trigger_type == 'SCHEDULED':
                # SCHEDULED reports - batch-optimized processing
                processing_time = self._process_scheduled_report(report, report_config)
                
            # Generate output path
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_format = report.get('OUTPUT_FORMAT', 'EXCEL').lower()
            output_path = f"{report_type.lower()}/{config_id}_{timestamp}.{output_format}"
            
            # Simulate file upload to S3
            self._upload_report_to_s3(output_path, f"Mock {report_name} content")
            
            # Send notifications if required
            if report.get('NOTIFY_ON_COMPLETION'):
                self._send_notification(report, output_path, True)
                
            logger.info(f"Completed {trigger_type} report: {config_id} in {processing_time:.2f}s")
            return True, output_path
            
        except Exception as e:
            error_msg = f"Failed to generate report {config_id}: {str(e)}"
            logger.error(error_msg)
            
            # Send failure notification if required
            if report.get('NOTIFY_ON_COMPLETION'):
                self._send_notification(report, None, False, error_msg)
                
            return False, error_msg
            
    def _process_adhoc_report(self, report: Dict[str, Any], config: Dict[str, Any]) -> float:
        """Process ADHOC report with high priority, immediate processing"""
        start_time = time.time()
        
        # Simulate immediate processing - optimized for speed
        # In real implementation, this would:
        # 1. Query data with optimized queries
        # 2. Generate report with minimal formatting
        # 3. Prioritize speed over comprehensive features
        
        processing_delay = config.get('processing_time', 2)  # Default 2 seconds for ADHOC
        time.sleep(processing_delay)
        
        return time.time() - start_time
        
    def _process_scheduled_report(self, report: Dict[str, Any], config: Dict[str, Any]) -> float:
        """Process SCHEDULED report with batch optimization"""
        start_time = time.time()
        
        # Simulate batch processing - optimized for throughput
        # In real implementation, this would:
        # 1. Use batch data queries
        # 2. Generate comprehensive reports
        # 3. Optimize for quality over speed
        
        processing_delay = config.get('processing_time', 5)  # Default 5 seconds for SCHEDULED
        time.sleep(processing_delay)
        
        return time.time() - start_time
        
    def _upload_report_to_s3(self, key: str, content: str) -> bool:
        """Upload generated report to S3"""
        try:
            self.s3_client.put_object(
                Bucket=self.reports_bucket,
                Key=key,
                Body=content.encode('utf-8'),
                ContentType='text/plain'
            )
            logger.debug(f"Uploaded report to S3: s3://{self.reports_bucket}/{key}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to upload report to S3: {e}")
            return False
            
    def _send_notification(self, report: Dict[str, Any], output_path: Optional[str], 
                          success: bool, error_message: Optional[str] = None) -> None:
        """Send notification about report completion"""
        try:
            recipients = report.get('NOTIFICATION_RECIPIENTS', '')
            if not recipients:
                return
                
            subject = f"Report {'Completed' if success else 'Failed'}: {report['REPORT_NAME']}"
            
            if success:
                message = f"""
Report completed successfully:
- Report ID: {report['CONFIG_ID']}
- Report Name: {report['REPORT_NAME']}
- Report Type: {report['REPORT_TYPE']}
- Output Location: s3://{self.reports_bucket}/{output_path}
- Completed At: {datetime.now().isoformat()}
                """
            else:
                message = f"""
Report failed:
- Report ID: {report['CONFIG_ID']}
- Report Name: {report['REPORT_NAME']}
- Report Type: {report['REPORT_TYPE']}
- Error: {error_message}
- Failed At: {datetime.now().isoformat()}
                """
                
            # In real implementation, you would send email or SNS notification
            logger.info(f"Notification sent to {recipients}: {subject}")
            
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")
            
    def process_adhoc_reports(self) -> int:
        """Process all pending ADHOC reports with high priority"""
        reports = self.get_adhoc_reports()
        processed_count = 0
        
        for report in reports:
            config_id = report['CONFIG_ID']
            
            try:
                # Update status to processing
                if not self.update_report_status(config_id, 'PROCESSING'):
                    continue
                    
                # Generate the report
                success, result = self.generate_report(report, 'ADHOC')
                
                if success:
                    # Update to completed
                    self.update_report_status(config_id, 'COMPLETED')
                    processed_count += 1
                    self.stats['adhoc_processed'] += 1
                    
                else:
                    # Update to failed
                    self.update_report_status(config_id, 'FAILED', result)
                    self.stats['errors'] += 1
                    
            except Exception as e:
                logger.error(f"Error processing ADHOC report {config_id}: {e}")
                self.update_report_status(config_id, 'FAILED', str(e))
                self.stats['errors'] += 1
                
        self.stats['total_processed'] += processed_count
        return processed_count
        
    def process_scheduled_reports(self) -> int:
        """Process all due SCHEDULED reports in batch mode"""
        reports = self.get_scheduled_reports()
        processed_count = 0
        
        for report in reports:
            config_id = report['CONFIG_ID']
            
            try:
                # Update status to processing
                if not self.update_report_status(config_id, 'PROCESSING'):
                    continue
                    
                # Generate the report
                success, result = self.generate_report(report, 'SCHEDULED')
                
                if success:
                    # Update to completed and calculate next run time
                    self.update_report_status(config_id, 'COMPLETED')
                    self.update_scheduled_report_times(config_id)
                    processed_count += 1
                    self.stats['scheduled_processed'] += 1
                    
                else:
                    # Update to failed
                    self.update_report_status(config_id, 'FAILED', result)
                    self.stats['errors'] += 1
                    
            except Exception as e:
                logger.error(f"Error processing SCHEDULED report {config_id}: {e}")
                self.update_report_status(config_id, 'FAILED', str(e))
                self.stats['errors'] += 1
                
        self.stats['total_processed'] += processed_count
        return processed_count
        
    def scale_down_when_idle(self) -> None:
        """Scale down ECS service when no work is available"""
        try:
            if not self.ecs_service_arn:
                logger.warning("ECS_SERVICE_ARN not set, cannot auto-scale")
                return
                
            self.ecs_client.update_service(
                service=self.ecs_service_arn,
                desiredCount=0
            )
            
            # Log final statistics
            runtime = datetime.now() - self.stats['start_time']
            logger.info(f"Service statistics:")
            logger.info(f"  Runtime: {runtime}")
            logger.info(f"  ADHOC reports processed: {self.stats['adhoc_processed']}")
            logger.info(f"  SCHEDULED reports processed: {self.stats['scheduled_processed']}")
            logger.info(f"  Total reports processed: {self.stats['total_processed']}")
            logger.info(f"  Errors: {self.stats['errors']}")
            
            logger.info("Scaled down ECS service to 0 - going to sleep")
            
        except Exception as e:
            logger.error(f"Error scaling down: {e}")
            
    def run(self) -> None:
        """Enhanced main service loop with dual trigger type handling"""
        logger.info("Enhanced Report Service started")
        
        # Validate configuration
        if not self.validate_connection():
            logger.error("Service validation failed, exiting")
            sys.exit(1)
            
        try:
            while self.running:
                # Check for both types of work
                adhoc_count = self.check_for_adhoc_work()
                scheduled_count = self.check_for_scheduled_work()
                
                total_processed = 0
                
                # Process ADHOC reports first (higher priority)
                if adhoc_count > 0:
                    logger.info(f"Processing {adhoc_count} ADHOC reports with high priority...")
                    processed = self.process_adhoc_reports()
                    total_processed += processed
                    logger.info(f"Processed {processed} ADHOC reports")
                    
                # Process SCHEDULED reports (batch mode)
                if scheduled_count > 0:
                    logger.info(f"Processing {scheduled_count} SCHEDULED reports in batch mode...")
                    processed = self.process_scheduled_reports()
                    total_processed += processed
                    logger.info(f"Processed {processed} SCHEDULED reports")
                    
                # Check if there's more work after processing
                if total_processed > 0:
                    # Quick recheck for new work
                    adhoc_count = self.check_for_adhoc_work()
                    scheduled_count = self.check_for_scheduled_work()
                    
                # If no work available, scale down
                if adhoc_count == 0 and scheduled_count == 0:
                    logger.info("No work available, scaling down...")
                    self.scale_down_when_idle()
                    break
                    
                
                
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            
        logger.info("Enhanced Report Service stopping")


def main():
    """Main entry point"""
    try:
        service = EnhancedReportService()
        service.run()
    except KeyboardInterrupt:
        logger.info("Service interrupted by user")
    except Exception as e:
        logger.error(f"Service failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()