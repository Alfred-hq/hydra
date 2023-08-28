#!/bin/sh

if [ -f /a.tar.xz ]; then
    echo "decompressing spilo image..."
    if tar xpJf /a.tar.xz -C / > /dev/null 2>&1; then
        rm /a.tar.xz
        ln -snf dash /bin/sh
    else
        echo "failed to decompress spilo image"
        exit 1
    fi
fi

if [ "$1" = "init" ]; then
    exec /usr/bin/dumb-init -c --rewrite 1:0 -- /bin/sh /launch.sh
fi

sysctl -w vm.dirty_background_bytes=67108864 > /dev/null 2>&1
sysctl -w vm.dirty_bytes=134217728 > /dev/null 2>&1

if [ "$USE_OLD_LOCALES" = "true" ]; then
    ln -snf /usr/lib/locale/locale-archive.18 /run/locale-archive
else
    ln -snf /usr/lib/locale/locale-archive.22 /run/locale-archive
fi

mkdir -p "$PGLOG" "$PGDATA" "$RW_DIR/postgresql" "$RW_DIR/tmp" "$RW_DIR/certs"
if [ "$(id -u)" -ne 0 ]; then
    sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$(id -u):$(id -g):/" /etc/passwd > "$RW_DIR/tmp/passwd"
    cat "$RW_DIR/tmp/passwd" > /etc/passwd
    rm "$RW_DIR/tmp/passwd"
fi

## Ensure all logfiles exist, most appliances will have
## a foreign data wrapper pointing to these files
for i in $(seq 0 7); do
    if [ ! -f "${PGLOG}/postgresql-$i.csv" ]; then
        touch "${PGLOG}/postgresql-$i.csv"
    fi
done
chown -R postgres: "$PGROOT" "$RW_DIR/certs"
chmod -R go-w "$PGROOT"
chmod 01777 "$RW_DIR/tmp"
chmod 0700 "$PGDATA"

echo  "SPILO_CONFIGURATION not set, will get the configs from /local/spilo.yaml"
export SPILO_CONFIGURATION=$(cat /local/spilo.yaml)

python3 /scripts/configure_spilo.py all

if [ -n "$PG_TIMESCALE_AUTO_TUNE" ]; then
    python3 /scripts/patroni_pg_tune.py
fi


/scripts/patroni_wait.sh -t 3600 -r health -- patronictl edit-config --apply postgres.yml --force -q &
/scripts/patroni_wait.sh -t 3600 -r health -- patronictl edit-config --replace postgres.yml --force -q &

sv_stop() {
    sv -w 86400 stop patroni
    sv -w 86400 stop /etc/service/*
}

[ ! -d /etc/service ] && exit 1  # /etc/service has not been created due to an error, the container is no-op

trap sv_stop TERM QUIT INT

/usr/bin/runsvdir -P /etc/service &

wait