#!/bin/bash
set -e

TIMESTAMP=$(date +%Y%m%dT%H%M%S)
FILENAME="${S3_PREFIX}/${POSTGRES_DATABASE}_${TIMESTAMP}.sql.gz"

echo "Creating dump of ${POSTGRES_DATABASE} from ${POSTGRES_HOST}..."

PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  "$POSTGRES_DATABASE" \
  | gzip \
  | AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY" \
    aws s3 cp - "s3://${S3_BUCKET}/${FILENAME}" --region "$S3_REGION"

echo "Backup complete: s3://${S3_BUCKET}/${FILENAME}"
