-- Updated Snowflake API Integration Setup (Simplified)
-- This script creates the unified API integration and external function.
-- Run this AFTER deploying the Terraform infrastructure to get the actual API Gateway URL.

USE REPORTING_DB.CONFIG;

DROP API INTEGRATION IF EXISTS AWS_ECS_TRIGGER_INTEGRATION;

-- Create API integration for AWS API Gateway
-- The ROLE_ARN and a prefix for API_ALLOWED_PREFIXES will be populated by the deploy script.
CREATE OR REPLACE API INTEGRATION AWS_ECS_TRIGGER_INTEGRATION
  API_PROVIDER = 'aws_api_gateway'
  API_AWS_ROLE_ARN = 'arn:aws:iam::203977009513:role/report-service-snowflake-integration-role'
  ENABLED = TRUE
  API_ALLOWED_PREFIXES = ('https://cjozwgpj6h.execute-api.us-east-1.amazonaws.com/')
  COMMENT = 'Unified integration for triggering the ECS service from Snowflake';

-- Unified external function to trigger the ECS service
-- The URL will be populated by the deploy script.
CREATE OR REPLACE EXTERNAL FUNCTION TRIGGER_ECS_SERVICE()
RETURNS VARIANT
API_INTEGRATION = AWS_ECS_TRIGGER_INTEGRATION
HEADERS = ('Content-Type' = 'application/json')
MAX_BATCH_ROWS = 1
COMMENT = 'Triggers the generic report processing endpoint in ECS'
AS 'https://cjozwgpj6h.execute-api.us-east-1.amazonaws.com/prod/trigger';

-- Test the external function (uncomment to test after setup)
-- SELECT TRIGGER_ECS_SERVICE();

-- Show the created integration and function
DESC INTEGRATION AWS_ECS_TRIGGER_INTEGRATION;
SHOW EXTERNAL FUNCTIONS LIKE 'TRIGGER_ECS_SERVICE';

-- Instructions for completing the setup:
/*
SETUP INSTRUCTIONS:

✅ Terraform infrastructure has been deployed.
✅ This script has been updated with values from the deployment.

NEXT STEPS:
1. Run this script in Snowflake to create the API integration and external function.
2. Verify the setup by running: DESC INTEGRATION AWS_ECS_TRIGGER_INTEGRATION;
3. Test the trigger: SELECT TRIGGER_ECS_SERVICE();
4. Start the Snowflake Task: CALL REPORTING_DB.CONFIG.START_ALL_TASKS();
*/
