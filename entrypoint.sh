#! /bin/sh

if [[ -z "$POSTGRES_HOST" ]]; then
  echo "POSTGRES_HOST environment variable is required"
  exit 1
fi

POSTGRES_PORT="${POSTGRES_PORT:-5432}"

if [[ -z "$POSTGRES_USER" ]]; then
  echo "POSTGRES_USER environment variable is required"
  exit 1
fi

if [[ -z "$POSTGRES_PASSWORD" ]]; then
  echo "POSTGRES_PASSWORD environment variable is required"
  exit 1
fi

if [[ -z "$S3_ENDPOINT" ]]; then
  echo "S3_ENDPOINT environment variable is required"
  exit 1
fi

if [[ -z "$S3_ACCESS_KEY" ]]; then
  echo "S3_ACCESS_KEY environment variable is required"
  exit 1
fi

if [[ -z "$S3_SECRET_KEY" ]]; then
  echo "S3_SECRET_KEY environment variable is required"
  exit 1
fi

if [[ -z "$S3_BUCKET" ]]; then
  echo "S3_BUCKET environment variable is required"
  exit 1
fi

S3_FILE_PREFIX="${S3_FILE_PREFIX:-backup-}"

pg_dumpall -V
echo "Creating a dump of all databases..."

SOURCE_FILE="output.bak.gz"
DESTINATION_FILE="${S3_FILE_PREFIX}$(date +"%Y-%m-%dT%H:%M:%SZ").bak.gz"

export PGPASSWORD=$POSTGRES_PASSWORD
pg_dumpall -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $PG_DUMPALL_EXTRA_ARGS | gzip > $SOURCE_FILE

echo "Dump created"

if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
  echo "Encryption disabled"
else
  echo "Encryption of the dump..."

  openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -in $SOURCE_FILE -out ${SOURCE_FILE}.enc -k $ENCRYPTION_PASSWORD $OPENSSL_ENC_EXTRA_ARGS

  SOURCE_FILE="${SOURCE_FILE}.enc"
  DESTINATION_FILE="${DESTINATION_FILE}.enc"

  echo "Dump encrypted"
fi

echo "Uploading the dump to S3..."

export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY
aws s3 cp $SOURCE_FILE s3://$S3_BUCKET/$DESTINATION_FILE --endpoint-url $S3_ENDPOINT $AWS_S3_CP_EXTRA_ARGS

echo "Dump uploaded"
