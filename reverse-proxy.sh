#!/bin/bash

# dynamically add reverse proxy 
# caddy reverse-proxy --from https://proxy.example.org:$from --to :$to

source config

hash curl 2>/dev/null || { echo >&2 "please install curl"; exit 1; }
hash jq 2>/dev/null || { echo >&2 "please install jq"; exit 1; }
[ -f "config" ] || { echo >&2 "please create config file"; exit 1; }
[ -z "$HOST" ] && { echo >&2 "please set HOST variable in config file"; exit 1; }

INSTANCE=$1

FROM=$((4000+$INSTANCE))
TO=$((8000+$INSTANCE))
NAME="rp${INSTANCE}"

# default Caddy config URL
CONFIG=http://localhost:2019/config

trap ctrl_c INT

function ctrl_c() {
    echo ""
    echo === terminating...
}

# note: On ubuntu, `PrivateTmp=true` is used in /lib/systemd/system/caddy.service
# Ergo: do not use /tmp
LOGDIR=/home/ubuntu/log

# create log dir if necessary, group writeable for caddy
sg caddy "mkdir -pm 770 $LOGDIR"

# create log file, group writeable for caddy
FILENAME=$(sg caddy "mktemp --suffix=.log $NAME-XXXX -p $LOGDIR")
chmod g+w ${FILENAME}

echo "=== adding reverse proxy $NAME (https://$HOST:$FROM -> localhost:$TO)"

jq -n --arg name "$NAME" --arg host "${HOST}" --arg from ":${FROM}" --arg to "localhost:${TO}" --arg hostport "${HOST}:${FROM}" -f jq/caddy-revproxy-template.jq  | curl -s -X POST "$CONFIG/apps/http/servers/$NAME" -H "Content-Type: application/json" -d @-

echo === adding access log $NAME

jq -n --arg name "${NAME}" --arg log "http.log.access.${NAME}" --arg filename ${FILENAME} -f jq/caddy-logging-template.jq | curl -s -X POST "$CONFIG/logging/logs/$NAME" -H "Content-Type: application/json" -d @-

tail -f ${FILENAME}

echo === removing reverse proxy $NAME
curl -s -X DELETE "$CONFIG/apps/http/servers/$NAME"
echo === removing access log $NAME
curl -s -X DELETE "$CONFIG/logging/logs/$NAME"
rm ${FILENAME}
