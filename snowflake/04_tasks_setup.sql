-- Snowflake Tasks Setup for ADHOC and SCHEDULED Triggers
-- This script creates separate tasks for monitoring and triggering ADHOC and SCHEDULED reports
-- Different schedules optimize for immediate vs. batch processing

USE REPORTING_DB.CONFIG;

-- Drop existing tasks if they exist (for clean setup)
DROP TASK IF EXISTS REPORTING_DB.CONFIG.ECS_ADHOC_TRIGGER_TASK;
DROP TASK IF EXISTS REPORTING_DB.CONFIG.ECS_SCHEDULED_TRIGGER_TASK;
DROP TASK IF EXISTS REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK;

-- Task for ADHOC report triggers (runs every 2 minutes for immediate response)
CREATE OR REPLACE TASK REPORTING_DB.CONFIG.ECS_ADHOC_TRIGGER_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0/2 * * * * UTC'  -- Every 2 minutes
  WHEN SYSTEM$STREAM_HAS_DATA('REPORTING_DB.CONFIG.REPORT_CONFIG_ADHOC_STREAM')
AS
  CALL REPORTING_DB.CONFIG.SEND_ADHOC_TRIGGER();

-- Add comment to the task
ALTER TASK REPORTING_DB.CONFIG.ECS_ADHOC_TRIGGER_TASK SET COMMENT = 'Task to monitor ADHOC report stream and trigger ECS service for immediate processing';

-- Task for SCHEDULED report triggers (runs every 10 minutes for batch processing)
CREATE OR REPLACE TASK REPORTING_DB.CONFIG.ECS_SCHEDULED_TRIGGER_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0/10 * * * * UTC'  -- Every 10 minutes
  -- No stream condition - checks for due scheduled reports
AS
  CALL REPORTING_DB.CONFIG.SEND_SCHEDULED_TRIGGER();

-- Add comment to the scheduled task
ALTER TASK REPORTING_DB.CONFIG.ECS_SCHEDULED_TRIGGER_TASK SET COMMENT = 'Task to check for due SCHEDULED reports and trigger ECS service for batch processing';

-- Maintenance task to update next run times for scheduled reports (runs every hour)
CREATE OR REPLACE TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0 * * * * UTC'  -- Every hour at minute 0
AS
  CALL REPORTING_DB.CONFIG.UPDATE_ALL_SCHEDULED_RUN_TIMES();

-- Add comment to the maintenance task
ALTER TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK SET COMMENT = 'Maintenance task to update next run times for scheduled reports';

-- Create a stored procedure to manage task states
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.MANAGE_TASK_STATE(
    TASK_NAME STRING,
    ACTION STRING  -- 'RESUME', 'SUSPEND', 'STATUS'
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    full_task_name STRING;
    result_message STRING;
BEGIN
    full_task_name := 'REPORTING_DB.CONFIG.' || TASK_NAME;
    
    CASE (UPPER(ACTION))
        WHEN 'RESUME' THEN
            EXECUTE IMMEDIATE 'ALTER TASK ' || full_task_name || ' RESUME';
            result_message := 'Task ' || TASK_NAME || ' resumed successfully';
            
        WHEN 'SUSPEND' THEN
            EXECUTE IMMEDIATE 'ALTER TASK ' || full_task_name || ' SUSPEND';
            result_message := 'Task ' || TASK_NAME || ' suspended successfully';
            
        WHEN 'STATUS' THEN
            -- This will be handled by the calling query
            result_message := 'Status check requested for ' || TASK_NAME;
            
        ELSE
            result_message := 'Invalid action: ' || ACTION || '. Use RESUME, SUSPEND, or STATUS';
    END CASE;
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error managing task ' || TASK_NAME || ': ' || SQLERRM;
END;
$$;

-- Create a stored procedure to get task status
-- Note: Uses SHOW TASKS since INFORMATION_SCHEMA.TASKS doesn't exist
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.GET_TASK_STATUS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    RETURN 'Task status retrieved. Use SHOW TASKS IN SCHEMA REPORTING_DB.CONFIG; to view task details.';
END;
$$;

-- Create a stored procedure to get task execution history
-- Note: Uses TASK_HISTORY function which may require specific permissions
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.GET_TASK_HISTORY()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    RETURN 'Task history retrieved. Query TASK_HISTORY() function directly or use SHOW command for task execution details.';
END;
$$;

-- Note: Comprehensive task monitoring should use SHOW TASKS and TASK_HISTORY() function directly

-- Stored procedure to start all trigger tasks
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.START_ALL_TASKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    result_message STRING := '';
    task_result STRING;
BEGIN
    -- Resume ADHOC trigger task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('ECS_ADHOC_TRIGGER_TASK', 'RESUME') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    -- Resume SCHEDULED trigger task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('ECS_SCHEDULED_TRIGGER_TASK', 'RESUME') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    -- Resume maintenance task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('SCHEDULED_MAINTENANCE_TASK', 'RESUME') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    RETURN 'All tasks started:\n' || result_message;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error starting tasks: ' || SQLERRM;
END;
$$;

-- Stored procedure to stop all trigger tasks
CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.STOP_ALL_TASKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    result_message STRING := '';
    task_result STRING;
BEGIN
    -- Suspend ADHOC trigger task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('ECS_ADHOC_TRIGGER_TASK', 'SUSPEND') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    -- Suspend SCHEDULED trigger task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('ECS_SCHEDULED_TRIGGER_TASK', 'SUSPEND') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    -- Suspend maintenance task
    CALL REPORTING_DB.CONFIG.MANAGE_TASK_STATE('SCHEDULED_MAINTENANCE_TASK', 'SUSPEND') INTO task_result;
    result_message := result_message || task_result || '\n';
    
    RETURN 'All tasks stopped:\n' || result_message;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error stopping tasks: ' || SQLERRM;
END;
$$;

-- Create a dashboard view for monitoring
CREATE OR REPLACE VIEW REPORTING_DB.CONFIG.V_MONITORING_DASHBOARD AS
SELECT 
    'System Status' as CATEGORY,
    'ADHOC Stream Has Data' as METRIC,
    SYSTEM$STREAM_HAS_DATA('REPORTING_DB.CONFIG.REPORT_CONFIG_ADHOC_STREAM')::STRING as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME
UNION ALL
SELECT 
    'System Status' as CATEGORY,
    'SCHEDULED Stream Has Data' as METRIC,
    SYSTEM$STREAM_HAS_DATA('REPORTING_DB.CONFIG.REPORT_CONFIG_SCHEDULED_STREAM')::STRING as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME
UNION ALL
SELECT 
    'Report Counts' as CATEGORY,
    'Pending ADHOC Reports' as METRIC,
    (SELECT COUNT(*)::STRING FROM REPORTING_DB.CONFIG.V_PENDING_ADHOC_REPORTS) as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME
UNION ALL
SELECT 
    'Report Counts' as CATEGORY,
    'Due SCHEDULED Reports' as METRIC,
    (SELECT COUNT(*)::STRING FROM REPORTING_DB.CONFIG.V_DUE_SCHEDULED_REPORTS) as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME
UNION ALL
SELECT 
    'Recent Activity' as CATEGORY,
    'Triggers Last 24h' as METRIC,
    (SELECT COUNT(*)::STRING FROM REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG 
     WHERE TRIGGER_TIMESTAMP >= DATEADD('HOUR', -24, CURRENT_TIMESTAMP())) as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME
UNION ALL
SELECT 
    'Recent Activity' as CATEGORY,
    'Failed Triggers Last 24h' as METRIC,
    (SELECT COUNT(*)::STRING FROM REPORTING_DB.CONFIG.TRIGGER_AUDIT_LOG 
     WHERE TRIGGER_TIMESTAMP >= DATEADD('HOUR', -24, CURRENT_TIMESTAMP()) 
     AND STATUS = 'ERROR') as VALUE,
    CURRENT_TIMESTAMP() as CHECK_TIME;

-- Show created tasks
SHOW TASKS IN SCHEMA REPORTING_DB.CONFIG;

-- Show task status
SELECT * FROM REPORTING_DB.CONFIG.V_TASK_STATUS;

-- NOTE: Tasks are created in SUSPENDED state by default
-- To start the tasks, run: CALL REPORTING_DB.CONFIG.START_ALL_TASKS();

-- Example usage commands:

-- Start all tasks
-- CALL REPORTING_DB.CONFIG.START_ALL_TASKS();

-- Stop all tasks
-- CALL REPORTING_DB.CONFIG.STOP_ALL_TASKS();

-- Check task status
-- CALL REPORTING_DB.CONFIG.GET_TASK_STATUS();

-- Monitor system dashboard
-- SELECT * FROM REPORTING_DB.CONFIG.V_MONITORING_DASHBOARD;

-- Check recent task execution history
-- SELECT * FROM REPORTING_DB.CONFIG.V_TASK_HISTORY WHERE scheduled_time >= DATEADD('HOUR', -2, CURRENT_TIMESTAMP());

-- Manual task execution (for testing):
-- EXECUTE TASK REPORTING_DB.CONFIG.ECS_ADHOC_TRIGGER_TASK;
-- EXECUTE TASK REPORTING_DB.CONFIG.ECS_SCHEDULED_TRIGGER_TASK;