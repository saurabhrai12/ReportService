-- Create monitoring views for operational visibility

-- View for queue status summary
CREATE OR REPLACE VIEW QUEUE_STATUS_SUMMARY AS
SELECT
    status,
    COUNT(*) as entry_count,
    MIN(created_at) as oldest_entry,
    MAX(created_at) as newest_entry
FROM PROCESSING_QUEUE
GROUP BY status;

-- View for processing metrics
CREATE OR REPLACE VIEW PROCESSING_METRICS AS
SELECT
    DATE(created_at) as processing_date,
    COUNT(*) as total_entries,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_entries,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_entries,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_entries,
    SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing_entries,
    ROUND(
        (SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) * 100.0) /
        NULLIF(SUM(CASE WHEN status IN ('completed', 'failed') THEN 1 ELSE 0 END), 0),
        2
    ) as success_rate_pct
FROM PROCESSING_QUEUE
GROUP BY DATE(created_at)
ORDER BY processing_date DESC;

-- View for processor performance
CREATE OR REPLACE VIEW PROCESSOR_PERFORMANCE AS
SELECT
    processor_id,
    COUNT(*) as total_processed,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, claimed_at,
        COALESCE(completed_at, failed_at))), 2) as avg_processing_time_seconds,
    MIN(claimed_at) as first_claim,
    MAX(COALESCE(completed_at, failed_at)) as last_completion
FROM PROCESSING_QUEUE
WHERE processor_id IS NOT NULL
  AND status IN ('completed', 'failed')
GROUP BY processor_id
ORDER BY total_processed DESC;

-- View for stale entries (processing too long)
CREATE OR REPLACE VIEW STALE_ENTRIES AS
SELECT
    id,
    processor_id,
    claimed_at,
    TIMESTAMPDIFF(MINUTE, claimed_at, CURRENT_TIMESTAMP()) as minutes_processing,
    retry_count,
    data
FROM PROCESSING_QUEUE
WHERE status = 'processing'
  AND claimed_at < DATEADD(MINUTE, -30, CURRENT_TIMESTAMP())
ORDER BY claimed_at ASC;

-- View for failed entries analysis
CREATE OR REPLACE VIEW FAILED_ENTRIES_ANALYSIS AS
SELECT
    LEFT(COALESCE(error_message, 'Unknown error'), 100) as error_category,
    COUNT(*) as failure_count,
    MIN(failed_at) as first_failure,
    MAX(failed_at) as last_failure,
    AVG(retry_count) as avg_retry_count
FROM PROCESSING_QUEUE
WHERE status = 'failed'
GROUP BY LEFT(COALESCE(error_message, 'Unknown error'), 100)
ORDER BY failure_count DESC;