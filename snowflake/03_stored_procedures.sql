-- Snowflake Stored Procedures for Trigger Handling (Simplified)
-- This script creates a single stored procedure to handle a unified report trigger.

USE REPORTING_DB.CONFIG;

-- Create AWS API integration for ECS trigger
-- This will be updated by the 05 script with the correct ARN and URL

CREATE OR REPLACE API INTEGRATION AWS_ECS_TRIGGER_INTEGRATION
    API_PROVIDER = 'aws_api_gateway'
    API_AWS_ROLE_ARN = 'arn:aws:iam::203977009513:role/report-service-snowflake-integration-role'
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://5e41doe73l.execute-api.us-east-1.amazonaws.com/')
    COMMENT = 'Unified integration for triggering the ECS service from Snowflake';

-- Update the external function with correct URL
CREATE OR REPLACE EXTERNAL FUNCTION TRIGGER_ECS_SERVICE()
RETURNS VARIANT
API_INTEGRATION = AWS_ECS_TRIGGER_INTEGRATION
HEADERS = ('Content-Type' = 'application/json')
MAX_BATCH_ROWS = 1
COMMENT = 'Triggers the generic report processing endpoint in ECS'
AS 'https://5e41doe73l.execute-api.us-east-1.amazonaws.com/prod/trigger';

-- Unified stored procedure to send the ECS trigger
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.SEND_ECS_TRIGGER()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    change_count INTEGER DEFAULT 0;
    trigger_response STRING;
BEGIN
    SELECT COUNT(*) INTO change_count FROM REPORTING_DB.CONFIG.V_INSERT_STREAM_DATA;

    IF (change_count > 0) THEN
        -- Consume the stream data
        CREATE OR REPLACE TEMPORARY TABLE TEMP_STREAM_CONSUMED AS
        SELECT * FROM REPORTING_DB.CONFIG.V_INSERT_STREAM_DATA;

        -- Call the external function to trigger ECS
        SELECT TRIGGER_ECS_SERVICE()::STRING INTO trigger_response;

        -- Log success
        INSERT INTO REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG (
            TRIGGER_TYPE,
            TRIGGER_COUNT,
            TRIGGER_TIMESTAMP,
            TRIGGER_RESPONSE,
            STATUS
        ) VALUES (
            'UNIFIED',
            change_count,
            CURRENT_TIMESTAMP(),
            trigger_response,
            'SUCCESS'
        );

        RETURN 'SUCCESS: Triggered ECS for ' || change_count || ' reports';
    ELSE
        RETURN 'No new reports to trigger.';
    END IF;
END;
$$;

-- Keep utility stored procedures for schedule management
-- These are still useful for managing reports with TRIGGER_TYPE = 'SCHEDULED'

CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.CALCULATE_NEXT_RUN_TIME(
    CRON_EXPRESSION STRING,
    BASE_TIMESTAMP TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
)
RETURNS TIMESTAMP_LTZ
LANGUAGE SQL
AS
$$
DECLARE
    next_run TIMESTAMP_LTZ;
    cron_parts ARRAY;
    minute_part STRING;
    hour_part STRING;
    day_part STRING;
    month_part STRING;
    weekday_part STRING;
    calculated_timestamp TIMESTAMP_LTZ;
BEGIN
    -- Parse cron expression: minute hour day month weekday
    -- Example: "0 9 1 * *" = first day of month at 9 AM
    -- Example: "0 9 * * 1" = every Monday at 9 AM
    -- Example: "0 */2 * * *" = every 2 hours

    cron_parts := SPLIT(CRON_EXPRESSION, ' ');

    IF (ARRAY_SIZE(cron_parts) != 5) THEN
        RETURN NULL; -- Invalid cron expression
    END IF;

    minute_part := cron_parts[0];
    hour_part := cron_parts[1];
    day_part := cron_parts[2];
    month_part := cron_parts[3];
    weekday_part := cron_parts[4];

    -- Simple cron calculation (this is a basic implementation)
    -- For production, you might want to use a more sophisticated cron parser

    calculated_timestamp := BASE_TIMESTAMP;

    -- Daily at specific time: "0 9 * * *" (9 AM daily)
    IF (day_part = '*' AND month_part = '*' AND weekday_part = '*') THEN
        calculated_timestamp := DATEADD('HOUR', hour_part::INTEGER, DATE_TRUNC('DAY', BASE_TIMESTAMP));
        calculated_timestamp := DATEADD('MINUTE', minute_part::INTEGER, calculated_timestamp);
        IF (calculated_timestamp <= BASE_TIMESTAMP) THEN
            calculated_timestamp := DATEADD('DAY', 1, calculated_timestamp);
        END IF;

    -- Monthly on specific day: "0 9 1 * *" (1st of month at 9 AM)
    ELSEIF (month_part = '*' AND weekday_part = '*' AND day_part != '*') THEN
        calculated_timestamp := DATEADD('DAY', day_part::INTEGER - 1, DATE_TRUNC('MONTH', BASE_TIMESTAMP));
        calculated_timestamp := DATEADD('HOUR', hour_part::INTEGER, calculated_timestamp);
        calculated_timestamp := DATEADD('MINUTE', minute_part::INTEGER, calculated_timestamp);
        IF (calculated_timestamp <= BASE_TIMESTAMP) THEN
            calculated_timestamp := DATEADD('MONTH', 1, calculated_timestamp);
        END IF;

    -- Weekly on specific weekday: "0 9 * * 1" (Mondays at 9 AM)
    ELSEIF (day_part = '*' AND month_part = '*' AND weekday_part != '*') THEN
        -- Calculate next occurrence of the weekday
        calculated_timestamp := DATEADD('DAY', weekday_part::INTEGER, DATE_TRUNC('WEEK', BASE_TIMESTAMP));
        calculated_timestamp := DATEADD('HOUR', hour_part::INTEGER, calculated_timestamp);
        calculated_timestamp := DATEADD('MINUTE', minute_part::INTEGER, calculated_timestamp);
        IF (calculated_timestamp <= BASE_TIMESTAMP) THEN
            calculated_timestamp := DATEADD('DAY', 7, calculated_timestamp);
        END IF;

    -- Hourly: "0 */2 * * *" (every 2 hours)
    ELSEIF (CONTAINS(hour_part, '*/')) THEN
        LET interval_hours := REPLACE(hour_part, '*/', '')::INTEGER;
        calculated_timestamp := DATEADD('HOUR', interval_hours, DATE_TRUNC('HOUR', BASE_TIMESTAMP));
        calculated_timestamp := DATEADD('MINUTE', minute_part::INTEGER, calculated_timestamp);
        IF (calculated_timestamp <= BASE_TIMESTAMP) THEN
            calculated_timestamp := DATEADD('HOUR', interval_hours, calculated_timestamp);
        END IF;

    ELSE
        -- Default to next day same time for unsupported patterns
        calculated_timestamp := DATEADD('DAY', 1, BASE_TIMESTAMP);
    END IF;

    RETURN calculated_timestamp;

EXCEPTION
    WHEN OTHER THEN
        -- Return NULL for invalid expressions
        RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.UPDATE_NEXT_RUN_TIME(
    CONFIG_ID_PARAM STRING,
    CRON_EXPRESSION_PARAM STRING
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    next_run_time TIMESTAMP_LTZ;
    update_result STRING;
BEGIN
    -- Calculate next run time
    CALL REPORTING_DB.CONFIG.CALCULATE_NEXT_RUN_TIME(CRON_EXPRESSION_PARAM) INTO next_run_time;

    IF (next_run_time IS NOT NULL) THEN
        -- Update the report configuration
        UPDATE REPORTING_DB.CONFIG.REPORT_CONFIG
        SET NEXT_RUN_TIME = next_run_time,
            UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()
        WHERE CONFIG_ID = CONFIG_ID_PARAM;

        update_result := 'Updated next run time for ' || CONFIG_ID_PARAM || ' to ' || next_run_time::STRING;
    ELSE
        update_result := 'Failed to calculate next run time for ' || CONFIG_ID_PARAM || ' with expression: ' || CRON_EXPRESSION_PARAM;
    END IF;

    RETURN update_result;

EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error updating next run time for ' || CONFIG_ID_PARAM || ': Error occurred';
END;
$$;

CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.UPDATE_ALL_SCHEDULED_RUN_TIMES()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    update_count INTEGER := 0;
    total_count INTEGER := 0;
    current_config_id STRING;
    current_schedule_expression STRING;
    next_run_time TIMESTAMP_LTZ;
    report_cursor CURSOR FOR
        SELECT CONFIG_ID, SCHEDULE_EXPRESSION
        FROM REPORTING_DB.CONFIG.REPORT_CONFIG
        WHERE TRIGGER_TYPE = 'SCHEDULED'
          AND IS_ACTIVE = TRUE
          AND SCHEDULE_EXPRESSION IS NOT NULL
          AND (NEXT_RUN_TIME IS NULL OR NEXT_RUN_TIME <= CURRENT_TIMESTAMP());
BEGIN
    -- Open cursor and iterate through scheduled reports
    OPEN report_cursor;

    FOR record IN report_cursor DO
        total_count := total_count + 1;

        current_config_id := record.CONFIG_ID;
        current_schedule_expression := record.SCHEDULE_EXPRESSION;

        -- Calculate next run time for this report
        CALL REPORTING_DB.CONFIG.CALCULATE_NEXT_RUN_TIME(current_schedule_expression) INTO next_run_time;

        IF (next_run_time IS NOT NULL) THEN
            -- Update the next run time
            UPDATE REPORTING_DB.CONFIG.REPORT_CONFIG
            SET NEXT_RUN_TIME = next_run_time,
                UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()
            WHERE CONFIG_ID = current_config_id;

            update_count := update_count + 1;
        END IF;
    END FOR;

    CLOSE report_cursor;

    RETURN 'Updated next run times for ' || update_count || ' of ' || total_count || ' scheduled reports';

EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error updating scheduled run times';
END;
$$;

-- Create or replace audit log table for trigger events
CREATE TABLE IF NOT EXISTS REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG (
    LOG_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    TRIGGER_TYPE VARCHAR(20) NOT NULL,
    TRIGGER_COUNT INTEGER,
    TRIGGER_TIMESTAMP TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    TRIGGER_RESPONSE VARIANT,
    ERROR_MESSAGE VARCHAR(5000),
    STATUS VARCHAR(20) DEFAULT 'SUCCESS' -- Valid values: 'SUCCESS', 'ERROR', 'WARNING'
);

-- Add comment to audit table
ALTER TABLE REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG SET COMMENT = 'Audit log for ECS trigger events';

-- Create or replace view for recent trigger activity
CREATE OR REPLACE VIEW REPORTING_DB.CONFIG.V_RECENT_TRIGGER_ACTIVITY AS
SELECT
    TRIGGER_TYPE,
    TRIGGER_COUNT,
    TRIGGER_TIMESTAMP,
    STATUS,
    CASE WHEN STATUS = 'ERROR' THEN ERROR_MESSAGE ELSE TRIGGER_RESPONSE::STRING END as DETAILS
FROM REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG
WHERE TRIGGER_TIMESTAMP >= DATEADD('HOUR', -24, CURRENT_TIMESTAMP())
ORDER BY TRIGGER_TIMESTAMP DESC;

-- Show the created procedures
SHOW PROCEDURES IN SCHEMA REPORTING_DB.CONFIG;