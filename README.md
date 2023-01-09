# postgres2s3
💾 Backup all PostgreSQL databases to S3 Storage

## Usage
```bash
$ docker run \ 
        -e POSTGRES_HOST=localhost
        -e POSTGRES_USER=postgres
        -e POSTGRES_PASSWORD=postgrespw
        -e S3_ENDPOINT=http://localhost:9000
        -e S3_ACCESS_KEY=accessKey
        -e S3_SECRET_KEY=secretKey
        -e S3_BUCKET=backups
        -e ENCRYPTION_PASSWORD=supersecretpassword
        --rm
        nikitakoschelenko/postgres2s3
```

## Environment variables
#### `POSTGRES_HOST`*
Host of the PostgreSQL database.

#### `POSTGRES_PORT`*
Port of the PostgreSQL database. Default to `5432`.

#### `POSTGRES_USER`*
Username of the PostgreSQL user.

#### `POSTGRES_PASSWORD`*
Password of the PostgreSQL user.

#### `S3_ENDPOINT`*
Endpoint URL of the S3.

#### `S3_ACCESS_KEY`*
Access key of the S3.

#### `S3_SECRET_KEY`*
Secret key of the S3.

#### `S3_BUCKET`*
Name of the bucket for saving backups to S3.

#### `S3_FILE_PREFIX`
Prefix for the backup file name for saving to S3. Default to `backup-`.

#### `ENCRYPTION_PASSWORD`
Password for encryption.

#### `PG_DUMPALL_EXTRA_ARGS`
Extra options for `pg_dumpall` command.

#### `OPENSSL_ENC_EXTRA_ARGS`
Extra options for `openssl enc` command.

#### `AWS_S3_CP_EXTRA_ARGS`
Extra options for `aws s3 cp` command.

## Decryption
```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in backup.bak.gz.enc -out backup.bak.gz
```

## Kubernetes
To use with Kubernetes, you need to create a CronJob:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgresql-backup
  namespace: shared
spec:
  schedule: 0 */8 * * *
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: postgresql-backup
              image: nikitakoschelenko/postgres2s3:15.1
              env:
                - name: POSTGRES_HOST
                  value: postgresql.shared
                - name: POSTGRES_USER
                  valueFrom:
                    secretKeyRef:
                      name: postgresql-backup-secret
                      key: POSTGRES_USER
                - name: POSTGRES_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: postgresql-backup-secret
                      key: POSTGRES_PASSWORD
                - name: S3_ENDPOINT
                  value: http://minio.shared:9000/
                - name: S3_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: postgresql-backup-secret
                      key: S3_ACCESS_KEY
                - name: S3_SECRET_KEY
                  valueFrom:
                    secretKeyRef:
                      name: postgresql-backup-secret
                      key: S3_SECRET_KEY
                - name: S3_BUCKET
                  value: backups
                - name: S3_PREFIX
                  value: postresql/backup-
                - name: ENCRYPTION_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: postgresql-backup-secret
                      key: ENCRYPTION_PASSWORD
          restartPolicy: OnFailure
```
