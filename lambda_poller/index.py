import os
import json
import boto3
import snowflake.connector
from datetime import datetime, timedelta
import math
import uuid
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')
secrets_client = boto3.client('secretsmanager')

# Configuration
ENVIRONMENT = os.environ['ENVIRONMENT']
ECS_CLUSTER = os.environ['ECS_CLUSTER']
ECS_TASK_DEFINITION = os.environ['ECS_TASK_DEFINITION']
ECS_SUBNETS = json.loads(os.environ['ECS_SUBNETS'])
ECS_SECURITY_GROUP = os.environ['ECS_SECURITY_GROUP']

# Snowflake configuration
SNOWFLAKE_ACCOUNT = os.environ['SNOWFLAKE_ACCOUNT']
SNOWFLAKE_WAREHOUSE = os.environ['SNOWFLAKE_WAREHOUSE']
SNOWFLAKE_DATABASE = os.environ['SNOWFLAKE_DATABASE']
SNOWFLAKE_SCHEMA = os.environ['SNOWFLAKE_SCHEMA']
SNOWFLAKE_TABLE = os.environ['SNOWFLAKE_TABLE']

# Processing configuration
ENTRIES_PER_CONTAINER = 8
MAX_CONTAINERS = 25
STALE_THRESHOLD_MINUTES = 30

def get_snowflake_credentials():
    """Retrieve Snowflake credentials from Secrets Manager"""
    secret_name = f"{ENVIRONMENT}-snowflake-credentials"
    response = secrets_client.get_secret_value(SecretId=secret_name)
    secret = json.loads(response['SecretString'])
    return secret['username'], secret['password']

def get_snowflake_connection():
    """Create Snowflake connection"""
    username, password = get_snowflake_credentials()
    return snowflake.connector.connect(
        user=username,
        password=password,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA
    )

def reset_stale_entries(conn):
    """Reset entries that have been processing for too long"""
    cursor = conn.cursor()
    try:
        stale_time = datetime.utcnow() - timedelta(minutes=STALE_THRESHOLD_MINUTES)

        query = f"""
        UPDATE {SNOWFLAKE_TABLE}
        SET status = 'pending',
            processor_id = NULL,
            claimed_at = NULL,
            retry_count = retry_count + 1
        WHERE status = 'processing'
          AND claimed_at < %s
        """

        cursor.execute(query, (stale_time,))
        stale_count = cursor.rowcount

        if stale_count > 0:
            logger.info(f"Reset {stale_count} stale entries")

        conn.commit()
        return stale_count

    finally:
        cursor.close()

def get_pending_entries_count(conn):
    """Get count of pending entries"""
    cursor = conn.cursor()
    try:
        query = f"""
        SELECT COUNT(*)
        FROM {SNOWFLAKE_TABLE}
        WHERE status = 'pending'
          AND (retry_count < 3 OR retry_count IS NULL)
        """

        cursor.execute(query)
        result = cursor.fetchone()
        return result[0] if result else 0

    finally:
        cursor.close()

def calculate_containers_needed(entry_count):
    """Calculate number of containers needed"""
    if entry_count == 0:
        return 0

    containers_needed = math.ceil(entry_count / ENTRIES_PER_CONTAINER)
    return min(containers_needed, MAX_CONTAINERS)

def launch_ecs_tasks(count):
    """Launch ECS tasks"""
    launched = []

    for i in range(count):
        try:
            processor_id = f"{ENVIRONMENT}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}"

            response = ecs_client.run_task(
                cluster=ECS_CLUSTER,
                taskDefinition=ECS_TASK_DEFINITION,
                launchType='FARGATE',
                networkConfiguration={
                    'awsvpcConfiguration': {
                        'subnets': ECS_SUBNETS,
                        'securityGroups': [ECS_SECURITY_GROUP],
                        'assignPublicIp': 'DISABLED'
                    }
                },
                overrides={
                    'containerOverrides': [
                        {
                            'name': 'processor',
                            'environment': [
                                {
                                    'name': 'PROCESSOR_ID',
                                    'value': processor_id
                                },
                                {
                                    'name': 'MAX_ENTRIES',
                                    'value': str(ENTRIES_PER_CONTAINER)
                                }
                            ]
                        }
                    ]
                }
            )

            if response['tasks']:
                task_arn = response['tasks'][0]['taskArn']
                launched.append({
                    'taskArn': task_arn,
                    'processorId': processor_id
                })
                logger.info(f"Launched task {task_arn} with processor_id {processor_id}")

        except Exception as e:
            logger.error(f"Failed to launch task {i+1}/{count}: {str(e)}")

    return launched

def handler(event, context):
    """Lambda handler function"""
    logger.info(f"Starting Snowflake poller - Environment: {ENVIRONMENT}")

    conn = None
    try:
        # Connect to Snowflake
        conn = get_snowflake_connection()

        # Reset stale entries
        stale_count = reset_stale_entries(conn)

        # Get pending entries count
        pending_count = get_pending_entries_count(conn)
        logger.info(f"Found {pending_count} pending entries")

        # Calculate containers needed
        containers_needed = calculate_containers_needed(pending_count)
        logger.info(f"Need to launch {containers_needed} containers")

        # Launch ECS tasks
        if containers_needed > 0:
            launched_tasks = launch_ecs_tasks(containers_needed)
            logger.info(f"Successfully launched {len(launched_tasks)} tasks")

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'pendingEntries': pending_count,
                    'staleEntriesReset': stale_count,
                    'containersLaunched': len(launched_tasks),
                    'tasks': launched_tasks
                })
            }
        else:
            logger.info("No entries to process")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'pendingEntries': 0,
                    'staleEntriesReset': stale_count,
                    'containersLaunched': 0,
                    'tasks': []
                })
            }

    except Exception as e:
        logger.error(f"Error in poller: {str(e)}")
        raise

    finally:
        if conn:
            conn.close()