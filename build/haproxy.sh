#!/bin/bash

set -eo pipefail

ETCD_PORT=${ETCD_PORT:-4001}
HOST_IP=${HOST_IP:-172.17.42.1}
ETCD=$HOST_IP:$ETCD_PORT
CONFD=/usr/local/bin/confd
TOML=/etc/confd/conf.d/haproxy.toml

echo "[proxy] booting container. ETCD: $ETCD."

# Try to make initial configuration every 5 seconds until successful
until ${CONFD} -onetime -node ${ETCD} -config-file ${TOML}; do
    echo "[haproxy] waiting for confd to create initial haproxy configuration."
    sleep 5
done

# Put a continual polling `confd` process into the background to watch
# for changes every 10 seconds
${CONFD} -interval 10 -node ${ETCD} -config-file ${TOML} &
echo "[haproxy] confd is now monitoring etcd for changes..."

# Start the Haproxy service using the generated config
echo "[haproxy] starting haproxy service..."
exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg
