-- Snowflake Tasks Setup (Simplified)
-- This script creates a single task for monitoring the unified stream.

USE REPORTING_DB.CONFIG;

-- Drop existing tasks if they exist (for clean setup)
DROP TASK IF EXISTS REPORTING_DB.CONFIG.ECS_TRIGGER_TASK; -- Drop new one too for idempotency

-- Task for unified report triggers (runs every 2 minutes for responsive processing)
CREATE OR REPLACE TASK REPORTING_DB.CONFIG.ECS_TRIGGER_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0/2 * * * * UTC'  -- Every 2 minutes
  WHEN SYSTEM$STREAM_HAS_DATA('REPORTING_DB.CONFIG.REPORT_CONFIG_INSERT_STREAM')
AS
  CALL REPORTING_DB.CONFIG.SEND_ECS_TRIGGER();

-- Add comment to the task
ALTER TASK REPORTING_DB.CONFIG.ECS_TRIGGER_TASK SET COMMENT = 'Task to monitor the unified report stream and trigger the ECS service.';

-- Keep the maintenance task to update next run times for scheduled reports (runs every hour)
CREATE OR REPLACE TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0 * * * * UTC'  -- Every hour at minute 0
AS
  CALL REPORTING_DB.CONFIG.UPDATE_ALL_SCHEDULED_RUN_TIMES();

-- Add comment to the maintenance task
ALTER TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK SET COMMENT = 'Maintenance task to update next run times for scheduled reports.';


-- Stored procedures for managing tasks remain largely the same, but simplified

CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.START_ALL_TASKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    ALTER TASK REPORTING_DB.CONFIG.ECS_TRIGGER_TASK RESUME;
    ALTER TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK RESUME;
    RETURN 'All simplified tasks (ECS_TRIGGER_TASK, SCHEDULED_MAINTENANCE_TASK) have been started.';
END;
$$;

CREATE OR REPLACE PROCEDURE REPORTING_DB.CONFIG.STOP_ALL_TASKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    ALTER TASK REPORTING_DB.CONFIG.ECS_TRIGGER_TASK SUSPEND;
    ALTER TASK REPORTING_DB.CONFIG.SCHEDULED_MAINTENANCE_TASK SUSPEND;
    RETURN 'All simplified tasks (ECS_TRIGGER_TASK, SCHEDULED_MAINTENANCE_TASK) have been suspended.';
END;
$$;

-- Show created tasks
SHOW TASKS IN SCHEMA REPORTING_DB.CONFIG;

-- NOTE: Tasks are created in SUSPENDED state by default.
-- To start the tasks, run: CALL REPORTING_DB.CONFIG.START_ALL_TASKS();
