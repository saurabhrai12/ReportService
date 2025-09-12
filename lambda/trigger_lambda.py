"""
AWS Lambda Function for ECS Service Trigger
This function receives triggers from Snowflake and wakes up the ECS service
Supports both ADHOC and SCHEDULED trigger types
"""

import json
import boto3
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ecs_client = boto3.client('ecs')
cloudwatch = boto3.client('cloudwatch')

def extract_trigger_type(event: Dict[str, Any]) -> str:
    """Extract trigger type from the event"""
    trigger_type = 'ADHOC'  # Default
    
    try:
        # Check path parameters (from API Gateway)
        if 'pathParameters' in event and event['pathParameters']:
            if 'trigger_type' in event['pathParameters']:
                trigger_type = event['pathParameters']['trigger_type'].upper()
            elif 'proxy' in event['pathParameters']:
                # Handle proxy+ paths like /trigger/adhoc
                proxy_path = event['pathParameters']['proxy']
                if proxy_path:
                    path_parts = proxy_path.split('/')
                    if len(path_parts) > 0:
                        potential_type = path_parts[-1].upper()
                        if potential_type in ['ADHOC', 'SCHEDULED']:
                            trigger_type = potential_type
        
        # Check resource path
        if 'resource' in event:
            if 'adhoc' in event['resource'].lower():
                trigger_type = 'ADHOC'
            elif 'scheduled' in event['resource'].lower():
                trigger_type = 'SCHEDULED'
        
        # Check request body
        if 'body' in event and event['body']:
            try:
                body = json.loads(event['body'])
                if 'trigger_type' in body:
                    trigger_type = body['trigger_type'].upper()
                elif 'type' in body:
                    trigger_type = body['type'].upper()
            except json.JSONDecodeError:
                logger.warning("Failed to parse request body as JSON")
                
    except Exception as e:
        logger.warning(f"Error extracting trigger type: {e}")
        
    return trigger_type

def send_cloudwatch_metric(trigger_type: str, success: bool) -> None:
    """Send custom metrics to CloudWatch"""
    try:
        metric_data = [
            {
                'MetricName': 'TriggerRequests',
                'Dimensions': [
                    {
                        'Name': 'TriggerType',
                        'Value': trigger_type
                    },
                    {
                        'Name': 'Status',
                        'Value': 'Success' if success else 'Error'
                    }
                ],
                'Value': 1,
                'Unit': 'Count',
                'Timestamp': datetime.utcnow()
            }
        ]
        
        cloudwatch.put_metric_data(
            Namespace='ReportService/Triggers',
            MetricData=metric_data
        )
        
    except Exception as e:
        logger.error(f"Failed to send CloudWatch metrics: {e}")

def get_ecs_service_info(service_arn: str) -> Optional[Dict[str, Any]]:
    """Get current ECS service information"""
    try:
        # Extract cluster from service ARN
        # ARN format: arn:aws:ecs:region:account:service/cluster-name/service-name
        arn_parts = service_arn.split('/')
        if len(arn_parts) >= 3:
            cluster_name = arn_parts[-2]
            service_name = arn_parts[-1]
        else:
            # Fallback: assume service ARN is just the service name
            cluster_name = None
            service_name = service_arn
        
        response = ecs_client.describe_services(
            cluster=cluster_name,
            services=[service_name]
        )
        
        if response['services']:
            return response['services'][0]
        else:
            logger.error(f"ECS service not found: {service_arn}")
            return None
            
    except Exception as e:
        logger.error(f"Error getting ECS service info: {e}")
        return None

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for ECS service triggers
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    start_time = datetime.utcnow()
    request_id = context.aws_request_id
    
    logger.info(f"Processing trigger request {request_id}")
    logger.debug(f"Event: {json.dumps(event, default=str)}")
    
    try:
        # Extract trigger type from request
        trigger_type = extract_trigger_type(event)
        logger.info(f"Processing {trigger_type} trigger request")
        
        # Get ECS service ARN from environment
        service_arn = os.environ.get('ECS_SERVICE_ARN')
        if not service_arn:
            error_msg = "ECS_SERVICE_ARN environment variable not set"
            logger.error(error_msg)
            send_cloudwatch_metric(trigger_type, False)
            
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps({
                    'error': error_msg,
                    'request_id': request_id
                })
            }
        
        # Get current service info
        service_info = get_ecs_service_info(service_arn)
        if not service_info:
            error_msg = f"Failed to get ECS service information for {service_arn}"
            logger.error(error_msg)
            send_cloudwatch_metric(trigger_type, False)
            
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'error': error_msg,
                    'request_id': request_id
                })
            }
        
        current_desired_count = service_info['desiredCount']
        current_running_count = service_info['runningCount']
        
        logger.info(f"Current service state - Desired: {current_desired_count}, Running: {current_running_count}")
        
        # Update service desired count to 1 (wake it up)
        # If it's already running, this will ensure it stays awake
        response = ecs_client.update_service(
            service=service_arn,
            desiredCount=1
        )
        
        logger.info(f"ECS service update response: {response}")
        
        # Calculate processing time
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        
        # Send success metrics
        send_cloudwatch_metric(trigger_type, True)
        
        # Prepare response
        response_body = {
            'message': f'ECS service triggered successfully for {trigger_type} processing',
            'service_arn': service_arn,
            'trigger_type': trigger_type,
            'previous_desired_count': current_desired_count,
            'new_desired_count': 1,
            'processing_time_ms': round(processing_time * 1000, 2),
            'timestamp': start_time.isoformat(),
            'request_id': request_id
        }
        
        logger.info(f"Successfully processed {trigger_type} trigger in {processing_time:.3f}s")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'X-Request-ID': request_id
            },
            'body': json.dumps(response_body, default=str)
        }
        
    except Exception as e:
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        error_msg = str(e)
        
        logger.error(f"Error processing trigger request: {error_msg}", exc_info=True)
        
        # Send error metrics
        trigger_type = extract_trigger_type(event)
        send_cloudwatch_metric(trigger_type, False)
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Request-ID': request_id
            },
            'body': json.dumps({
                'error': error_msg,
                'message': 'Failed to trigger ECS service',
                'processing_time_ms': round(processing_time * 1000, 2),
                'timestamp': start_time.isoformat(),
                'request_id': request_id
            }, default=str)
        }

# For local testing
if __name__ == "__main__":
    # Mock event for ADHOC trigger
    mock_event = {
        'resource': '/trigger/adhoc',
        'pathParameters': {
            'trigger_type': 'adhoc'
        },
        'httpMethod': 'POST',
        'body': json.dumps({
            'trigger_type': 'ADHOC',
            'source': 'Snowflake'
        })
    }
    
    # Mock context
    class MockContext:
        def __init__(self):
            self.aws_request_id = 'test-request-123'
            self.function_name = 'test-function'
            self.function_version = '1'
    
    # Set environment variable for testing
    os.environ['ECS_SERVICE_ARN'] = 'arn:aws:ecs:us-east-1:123456789:service/test-cluster/test-service'
    
    # Test the function
    context = MockContext()
    result = lambda_handler(mock_event, context)
    
    print("Test Result:")
    print(json.dumps(result, indent=2))