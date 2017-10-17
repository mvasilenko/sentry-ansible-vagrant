#!/bin/bash
set -e

source /root/.env

backup_host="root@192.168.33.20"
fname="$DBNAME-$(date +%Y%m%d-%H%M%S).sql.gz"
dname="/data/"
rm -rf "$dname"
mkdir -p "$dname"

PGHOST="$POSTGRES_PORT_5432_TCP_ADDR" \
PGPORT="$POSTGRES_PORT_5432_TCP_PORT" \
PGUSER="$POSTGRES_ENV_POSTGRES_USER" \
PGPASSWORD="$POSTGRES_ENV_POSTGRES_PASSWORD" \
pg_dump -Fc --clean --no-owner -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$DBNAME" | gzip -c | cat > "$dname$fname"

scp "$dname/$fname" $backup_host:

cp s3cfg ~/.s3cfg
echo "access_key=${AWS_KEY}" >> ~/.s3cfg
echo "secret_key=${AWS_SECRET}" >> ~/.s3cfg

if [ -z "${AWS_KEY}" ]; then
    echo "ERROR: The environment variable key is not set."
    exit 1
fi

if [ -z "${AWS_SECRET}" ]; then
    echo "ERROR: The environment variable secret is not set."
    exit 1
fi

/usr/bin/s3cmd put --rr "$dname/$fname" s3://$AWS_S3_PATH$fname


cd /
rm -rf "$dname"

