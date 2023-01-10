#! /bin/sh

# with these settings, certain common errors will cause the script to immediately fail, explicitly and loudly
set -euo pipefail

# required environment variables
: "${POSTGRES_HOST}"
: "${POSTGRES_USER}"
: "${POSTGRES_PASSWORD}"
: "${S3_ENDPOINT}"
: "${S3_ACCESS_KEY}"
: "${S3_SECRET_KEY}"
: "${S3_BUCKET}"

# not required environment variables with default values
: "${POSTGRES_PORT:=5432}"
: "${S3_FILE_PREFIX:=backup-}"
: "${PG_DUMPALL_EXTRA_ARGS:=}"
: "${OPENSSL_ENC_EXTRA_ARGS:=}"
: "${AWS_S3_CP_EXTRA_ARGS:=}"

# print pg_dumpall version
pg_dumpall -V

echo "Creating a dump of all databases..."

LOCAL_FILE="output.bak.gz"
REMOTE_FILE="${S3_FILE_PREFIX}$(date +"%Y-%m-%dT%H:%M:%SZ").bak.gz"

# PGPASSWORD is required for pg_dumpall
export PGPASSWORD=$POSTGRES_PASSWORD

# dump all databases and gzip to file
pg_dumpall -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $PG_DUMPALL_EXTRA_ARGS | gzip > $LOCAL_FILE

echo "Dump created"

# if encryption password is set and not an empty string
if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
  echo "Encryption disabled"
else
  echo "Encryption of the dump..."

  # encrypt local dump
  openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -in $LOCAL_FILE -out ${LOCAL_FILE}.enc -k $ENCRYPTION_PASSWORD $OPENSSL_ENC_EXTRA_ARGS

  # update file extensions
  LOCAL_FILE="${LOCAL_FILE}.enc"
  REMOTE_FILE="${REMOTE_FILE}.enc"

  echo "Dump encrypted"
fi

echo "Uploading the dump to S3..."

# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY is required for aws
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY

# upload local dump to s3
aws s3 cp $LOCAL_FILE s3://$S3_BUCKET/$REMOTE_FILE --endpoint-url $S3_ENDPOINT $AWS_S3_CP_EXTRA_ARGS

echo "Dump uploaded"
