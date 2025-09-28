#!/bin/bash

# Snowflake Database Setup Script
set -e

echo "🗄️ Setting up Snowflake database..."

# Check if snowsql is installed
if ! command -v snowsql &> /dev/null; then
    echo "❌ SnowSQL is required but not installed"
    echo "Please install SnowSQL: https://docs.snowflake.com/en/user-guide/snowsql-install-config.html"
    exit 1
fi

# Check environment variables
if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ -z "$SNOWFLAKE_USER" ] || [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "❌ Please set the following environment variables:"
    echo "   SNOWFLAKE_ACCOUNT"
    echo "   SNOWFLAKE_USER"
    echo "   SNOWFLAKE_PASSWORD"
    echo "   SNOWFLAKE_WAREHOUSE (optional, defaults to COMPUTE_WH)"
    echo "   SNOWFLAKE_DATABASE (optional, defaults to REPORTING_DB)"
    echo "   SNOWFLAKE_SCHEMA (optional, defaults to PUBLIC)"
    exit 1
fi

SNOWFLAKE_WAREHOUSE=${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}
SNOWFLAKE_DATABASE=${SNOWFLAKE_DATABASE:-REPORTING_DB}
SNOWFLAKE_SCHEMA=${SNOWFLAKE_SCHEMA:-PUBLIC}

echo "📋 Configuration:"
echo "   Account: $SNOWFLAKE_ACCOUNT"
echo "   User: $SNOWFLAKE_USER"
echo "   Warehouse: $SNOWFLAKE_WAREHOUSE"
echo "   Database: $SNOWFLAKE_DATABASE"
echo "   Schema: $SNOWFLAKE_SCHEMA"

# Create database and schema if they don't exist
echo "🏗️ Creating database and schema..."

snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS $SNOWFLAKE_DATABASE;
USE DATABASE $SNOWFLAKE_DATABASE;
CREATE SCHEMA IF NOT EXISTS $SNOWFLAKE_SCHEMA;
USE SCHEMA $SNOWFLAKE_SCHEMA;
EOF

# Run database setup scripts
echo "🔧 Running database setup scripts..."

# Create table
echo "  📝 Creating processing queue table..."
snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
    -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
    -f snowflake/01_create_table.sql

# Create monitoring views
echo "  📊 Creating monitoring views..."
snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
    -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
    -f snowflake/03_monitoring_views.sql

# Optionally insert sample data
read -p "Would you like to insert sample data for testing? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  🎲 Inserting sample data..."
    snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -p $SNOWFLAKE_PASSWORD \
        -d $SNOWFLAKE_DATABASE -s $SNOWFLAKE_SCHEMA \
        -f snowflake/02_sample_data.sql
fi

echo "✅ Database setup completed successfully!"
echo ""
echo "You can now monitor the queue with these views:"
echo "  - QUEUE_STATUS_SUMMARY: Current queue status"
echo "  - PROCESSING_METRICS: Daily processing metrics"
echo "  - PROCESSOR_PERFORMANCE: Individual processor performance"
echo "  - STALE_ENTRIES: Entries stuck in processing"
echo "  - FAILED_ENTRIES_ANALYSIS: Analysis of failed entries"