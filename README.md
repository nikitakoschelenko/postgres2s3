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
  # at minute 0 past every 8th hour
  schedule: 0 */8 * * *
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: postgresql-backup
              image: nikitakoschelenko/postgres2s3:15.1-rc.1
              # use envFrom to load Secrets and ConfigMaps into environment variables
              envFrom:
                - configMapRef:
                    name: postgresql-backup-configmap
                - secretRef:
                    name: postgresql-backup-secret
          restartPolicy: OnFailure
```

Use config map for not-secret configuration data:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-backup-configmap
  namespace: shared
data:
  POSTGRES_HOST: postgresql.shared
  S3_ENDPOINT: http://minio.shared:9000/
  S3_BUCKET: backups
  S3_FILE_PREFIX: postresql/backup-
```

Use secrets for things which are actually secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-backup-secret
  namespace: shared
type: Opaque
data:
  # base64 encode the values stored in a Kubernetes Secret: $ pbpaste | base64 | pbcopy
  # the --decode flag is convenient: $ pbpaste | base64 --decode
  POSTGRES_USER: cG9zdGdyZXM=
  POSTGRES_PASSWORD: cG9zdGdyZXNwdw==
  S3_ACCESS_KEY: YWNjZXNzS2V5
  S3_SECRET_KEY: c2VjcmV0S2V5
  ENCRYPTION_PASSWORD: c3VwZXJzZWNyZXRwYXNzd29yZA==
```
