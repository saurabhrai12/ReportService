import json
import boto3
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')

def lambda_handler(event, context):
    try:
        # Check if this is a Snowflake external function call
        is_snowflake_call = False
        if 'body' in event and event['body']:
            try:
                body = json.loads(event['body'])
                if 'data' in body and isinstance(body['data'], list):
                    is_snowflake_call = True
            except json.JSONDecodeError:
                pass
        
        # Extract trigger type from the request path or body
        trigger_type = 'ADHOC'  # Default
        
        # Check if trigger type is specified in the path
        if 'pathParameters' in event and event['pathParameters']:
            if 'trigger_type' in event['pathParameters']:
                trigger_type = event['pathParameters']['trigger_type'].upper()
        
        # Check if trigger type is in the request body
        if 'body' in event and event['body']:
            try:
                body = json.loads(event['body'])
                if 'trigger_type' in body:
                    trigger_type = body['trigger_type'].upper()
            except json.JSONDecodeError:
                pass
        
        logger.info(f"Processing {trigger_type} trigger request")
        
        service_arn = os.environ['ECS_SERVICE_ARN']
        
        # Extract cluster and service name from ARN
        # ARN format: arn:aws:ecs:region:account:service/cluster-name/service-name
        arn_parts = service_arn.split('/')
        if len(arn_parts) >= 3:
            cluster_name = arn_parts[-2]
            service_name = arn_parts[-1]
        else:
            # Fallback to default cluster if parsing fails
            cluster_name = 'default'
            service_name = service_arn
        
        logger.info(f"Updating ECS service: {service_name} in cluster: {cluster_name}")
        
        # Update service desired count to 1 (wake it up)
        response = ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            desiredCount=1
        )
        
        logger.info(f"ECS service update response: {response}")
        
        # Prepare success message
        success_message = {
            'message': f'ECS service triggered successfully for {trigger_type} processing',
            'service': service_arn,
            'trigger_type': trigger_type,
            'desired_count': 1,
            'timestamp': context.aws_request_id
        }
        
        # Return different formats based on caller
        if is_snowflake_call:
            # Snowflake external function format
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'data': [
                        [0, json.dumps(success_message)]
                    ]
                })
            }
        else:
            # API Gateway format
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps(success_message)
            }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        
        error_message = {
            'error': str(e),
            'message': 'Failed to trigger ECS service'
        }
        
        # Return different error formats based on caller
        if is_snowflake_call:
            # Snowflake external function format
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'data': [
                        [0, json.dumps(error_message)]
                    ]
                })
            }
        else:
            # API Gateway format
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps(error_message)
            }