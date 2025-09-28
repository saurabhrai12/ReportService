-- Create the processing queue table
CREATE TABLE IF NOT EXISTS PROCESSING_QUEUE (
    id BIGINT AUTOINCREMENT PRIMARY KEY,
    data VARIANT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    processor_id VARCHAR(100),
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    claimed_at TIMESTAMP_LTZ,
    completed_at TIMESTAMP_LTZ,
    failed_at TIMESTAMP_LTZ,
    error_message VARCHAR(1000)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_processing_queue_status ON PROCESSING_QUEUE(status);
CREATE INDEX IF NOT EXISTS idx_processing_queue_processor_id ON PROCESSING_QUEUE(processor_id);
CREATE INDEX IF NOT EXISTS idx_processing_queue_created_at ON PROCESSING_QUEUE(created_at);
CREATE INDEX IF NOT EXISTS idx_processing_queue_claimed_at ON PROCESSING_QUEUE(claimed_at);

-- Add comments for documentation
COMMENT ON TABLE PROCESSING_QUEUE IS 'Queue table for processing entries with external services';
COMMENT ON COLUMN PROCESSING_QUEUE.id IS 'Unique identifier for each entry';
COMMENT ON COLUMN PROCESSING_QUEUE.data IS 'JSON data to be processed';
COMMENT ON COLUMN PROCESSING_QUEUE.status IS 'Processing status: pending, processing, completed, failed';
COMMENT ON COLUMN PROCESSING_QUEUE.processor_id IS 'ID of the processor handling this entry';
COMMENT ON COLUMN PROCESSING_QUEUE.retry_count IS 'Number of retry attempts';
COMMENT ON COLUMN PROCESSING_QUEUE.created_at IS 'Timestamp when entry was created';
COMMENT ON COLUMN PROCESSING_QUEUE.claimed_at IS 'Timestamp when entry was claimed for processing';
COMMENT ON COLUMN PROCESSING_QUEUE.completed_at IS 'Timestamp when processing completed successfully';
COMMENT ON COLUMN PROCESSING_QUEUE.failed_at IS 'Timestamp when processing failed';
COMMENT ON COLUMN PROCESSING_QUEUE.error_message IS 'Error message if processing failed';