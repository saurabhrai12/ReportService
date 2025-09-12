#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/invoke_lambdas.sh [function-name]
# Default function name
FN_NAME=${1:-report-service-ecs-trigger}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

SCHEDULED_PAYLOAD="$ROOT_DIR/lambda_test_payload.json"
ADHOC_PAYLOAD="$ROOT_DIR/test_payload.json"

OUT_DIR="$ROOT_DIR"

echo "Invoking $FN_NAME with SCHEDULED payload..."
aws lambda invoke \
  --cli-binary-format raw-in-base64-out \
  --function-name "$FN_NAME" \
  --payload fileb://"$SCHEDULED_PAYLOAD" \
  "$OUT_DIR/lambda_response_scheduled.json" | cat
echo
cat "$OUT_DIR/lambda_response_scheduled.json" || true
echo

echo "Invoking $FN_NAME with ADHOC payload..."
aws lambda invoke \
  --cli-binary-format raw-in-base64-out \
  --function-name "$FN_NAME" \
  --payload fileb://"$ADHOC_PAYLOAD" \
  "$OUT_DIR/lambda_response_adhoc.json" | cat
echo
cat "$OUT_DIR/lambda_response_adhoc.json" || true
echo

