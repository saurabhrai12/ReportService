-- Snowflake Streams Setup for Change Detection (Simplified)
-- This script creates a single stream to monitor all new report insertions.

USE REPORTING_DB.CONFIG;

-- Drop existing streams if they exist (for clean setup)

DROP STREAM IF EXISTS REPORTING_DB.CONFIG.REPORT_CONFIG_INSERT_STREAM; -- Drop new one too for idempotency

-- Create a single stream for all new report insertions
CREATE STREAM REPORTING_DB.CONFIG.REPORT_CONFIG_INSERT_STREAM
ON TABLE REPORTING_DB.CONFIG.REPORT_CONFIG
APPEND_ONLY = TRUE  -- Only capture INSERTs for new reports
COMMENT = 'Unified stream for monitoring all new report insertions.';

-- Create a view for the new stream data
CREATE OR REPLACE VIEW REPORTING_DB.CONFIG.V_INSERT_STREAM_DATA AS
SELECT
    CONFIG_ID,
    REPORT_NAME,
    TRIGGER_TYPE,
    STATUS,
    CREATED_TIMESTAMP,
    METADATA$ACTION,
    METADATA$ISUPDATE,
    METADATA$ROW_ID
FROM REPORTING_DB.CONFIG.REPORT_CONFIG_INSERT_STREAM
WHERE METADATA$ACTION = 'INSERT';

-- Utility view to check if the stream has data
CREATE OR REPLACE VIEW REPORTING_DB.CONFIG.V_STREAM_STATUS AS
SELECT
    'UNIFIED_INSERT' as STREAM_TYPE,
    SYSTEM$STREAM_HAS_DATA('REPORTING_DB.CONFIG.REPORT_CONFIG_INSERT_STREAM') as HAS_DATA,
    (SELECT COUNT(*) FROM REPORTING_DB.CONFIG.V_INSERT_STREAM_DATA) as PENDING_COUNT,
    CURRENT_TIMESTAMP() as CHECKED_AT;

-- Show stream information
SHOW STREAMS IN SCHEMA REPORTING_DB.CONFIG;

-- Test the stream by checking its status
SELECT * FROM REPORTING_DB.CONFIG.V_STREAM_STATUS;
