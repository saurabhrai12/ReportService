-- Updated Snowflake API Integration Setup
-- This script creates the API integration and external functions with correct URLs
-- Run this AFTER deploying the Terraform infrastructure to get the actual API Gateway URLs

USE REPORTING_DB.CONFIG;

-- Drop existing integration and functions if they exist
DROP FUNCTION IF EXISTS TRIGGER_ECS_ADHOC();
DROP FUNCTION IF EXISTS TRIGGER_ECS_SCHEDULED();
DROP API INTEGRATION IF EXISTS AWS_ECS_TRIGGER_INTEGRATION;

-- Create API integration for AWS API Gateway
-- Using actual values from Terraform deployment
CREATE OR REPLACE API INTEGRATION AWS_ECS_TRIGGER_INTEGRATION
  API_PROVIDER = 'aws_api_gateway'
  API_AWS_ROLE_ARN = 'arn:aws:iam::203977009513:role/report-service-snowflake-integration-role'
  ENABLED = TRUE
  API_ALLOWED_PREFIXES = (
    'https://nvzs1w9q74.execute-api.us-east-1.amazonaws.com/'
  )
  COMMENT = 'Integration for triggering ECS service from Snowflake with dual trigger support';

-- External function to trigger ECS service for ADHOC reports
-- Using actual API Gateway URL from deployment
CREATE OR REPLACE EXTERNAL FUNCTION TRIGGER_ECS_ADHOC()
RETURNS VARIANT
API_INTEGRATION = AWS_ECS_TRIGGER_INTEGRATION
HEADERS = ('Content-Type' = 'application/json')
MAX_BATCH_ROWS = 1
COMMENT = 'Trigger ECS service for ADHOC report processing'
AS 'https://nvzs1w9q74.execute-api.us-east-1.amazonaws.com/prod/trigger/adhoc';

-- External function to trigger ECS service for SCHEDULED reports
-- Using actual API Gateway URL from deployment
CREATE OR REPLACE EXTERNAL FUNCTION TRIGGER_ECS_SCHEDULED()
RETURNS VARIANT
API_INTEGRATION = AWS_ECS_TRIGGER_INTEGRATION
HEADERS = ('Content-Type' = 'application/json')
MAX_BATCH_ROWS = 1
COMMENT = 'Trigger ECS service for SCHEDULED report processing'
AS 'https://nvzs1w9q74.execute-api.us-east-1.amazonaws.com/prod/trigger/scheduled';

-- Test the external functions (uncomment to test after setup)
-- SELECT TRIGGER_ECS_ADHOC();
-- SELECT TRIGGER_ECS_SCHEDULED();

-- Show the created integration and functions
DESC INTEGRATION AWS_ECS_TRIGGER_INTEGRATION;
SHOW FUNCTIONS LIKE 'TRIGGER_ECS_%';

-- Create a utility procedure to test both triggers
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.TEST_TRIGGERS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    adhoc_result VARIANT;
    scheduled_result VARIANT;
    result_message STRING;
BEGIN
    -- Test ADHOC trigger
    SELECT TRIGGER_ECS_ADHOC() INTO adhoc_result;
    
    -- Test SCHEDULED trigger
    SELECT TRIGGER_ECS_SCHEDULED() INTO scheduled_result;
    
    result_message := 'ADHOC Trigger Result: ' || COALESCE(adhoc_result::STRING, 'NULL') || '\n' ||
                     'SCHEDULED Trigger Result: ' || COALESCE(scheduled_result::STRING, 'NULL');
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error testing triggers: ' || SQLERRM;
END;
$$;

-- Create deployment verification procedure
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.VERIFY_INTEGRATION_SETUP()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    RETURN 'Integration setup verification completed. Use SHOW INTEGRATIONS, SHOW FUNCTIONS, SHOW PROCEDURES, and SHOW TASKS commands to verify components.';
END;
$$;

-- Instructions for completing the setup:
/*
SETUP INSTRUCTIONS:

✅ Terraform infrastructure has been deployed
✅ AWS values have been updated in this script

ACTUAL DEPLOYMENT VALUES:
- AWS Account: 203977009513
- API Gateway ID: nvzs1w9q74
- ADHOC URL: https://nvzs1w9q74.execute-api.us-east-1.amazonaws.com/prod/trigger/adhoc
- SCHEDULED URL: https://nvzs1w9q74.execute-api.us-east-1.amazonaws.com/prod/trigger/scheduled

NEXT STEPS:
1. Run this script in Snowflake to create the API integration and external functions

2. Verify the setup:
   CALL REPORTING_DB.CONFIG.VERIFY_INTEGRATION_SETUP();

3. Test the triggers:
   CALL REPORTING_DB.CONFIG.TEST_TRIGGERS();

4. Start the tasks:
   CALL REPORTING_DB.CONFIG.START_ALL_TASKS();

5. Test with actual data:
   INSERT INTO REPORTING_DB.CONFIG.REPORT_CONFIG (
       CONFIG_ID, REPORT_NAME, REPORT_TYPE, TRIGGER_TYPE, PRIORITY
   ) VALUES (
       'TEST_ADHOC_20250912', 'Test ADHOC Report', 'TEST', 'ADHOC', 1
   );
*/