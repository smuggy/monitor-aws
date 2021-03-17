#!/usr/bin/env bash
#
# cron script to write snapshots
PATH=/usr/bin:/usr/local/bin
rm -f /tmp/snapshot.log

logit() {
  time=$(date +%H%M%S)
  echo "${time}: $1" >> /tmp/snapshot.log
}

logit "Starting"
snapshot_dir="/var/lib/consul/snapshots"

if [[ ! -f /var/lib/consul/secrets/global-token ]] ;  then
  echo "global-token missing"
  exit 1
fi

export CONSUL_HTTP_ADDR="{{ consul_http_addr }}"
export CONSUL_HTTP_TOKEN=$(cat /var/lib/consul/secrets/global-token)

hostname=$(hostname)
current_date=$(date +%Y%m%d)
lastweek_date=$(date '-5 days' +%Y%m%d)
current_timestamp=$(date +%Y%m%d%H%M)
snapshot_bucket="{{ consul_snapshot_bucket }}"

logit "Delete old snapshots"
find ${snapshot_dir} -name \*.snap -mtime +3 -exec /usr/bin/rm -f {} \;
find ${snapshot_dir} -name \*.tar -mtime +3 -exec /usr/bin/rm -f {} \;
cd /var/lib/consul

snap_filename="snapshots/backup"
agent_filename="secrets/agent-token"
global_filename="secrets/global-token"

logit "Create new snapshot"
consul snapshot save ${snap_filename}-${current_timestamp}.snap
if [[ $? -ne 0 ]] ; then
  echo "Snapshot failed"
  exit 1
fi

cp ${snap_filename}-${current_timestamp}.snap ${snap_filename}.snap
if [[ $? -ne 0 ]] ; then
  echo "copy failed"
  exit 1
fi




logit "Leaving"
exit 0