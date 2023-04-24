#!/usr/bin/env bash

set -eEuo pipefail

_on_error() {
  trap '' ERR
  line_path=$(caller)
  line=${line_path% *}
  path=${line_path#* }

  echo ""
  echo "ERR $path:$line $BASH_COMMAND exited with $1"

  _shutdown 1
}
trap '_on_error $?' ERR

_shutdown() {
  trap '' TERM INT

  code=${1:-0}

  kill 0 & wait

  exit "$code"
}

trap _shutdown TERM INT

case "${1:-}" in
  hang)
    echo "HANG"
    tail -f /dev/null & wait
  ;;
esac

k8s_leader_lease_name=${K8S_LEADER_LEASE_NAME:-}

if [[ "$k8s_leader_lease_name" != "" ]]
then
  (
    echo "$(date) started"
    while true; do
      k8s-leader  --lease-name "${k8s_leader_lease_name}" --lease-namespace "$NAMESPACE" --identity "$HOSTNAME" || true
      echo "$(date) exited"
      sleep 1
    done
  ) >/tmp/k8s-leader.log 2>&1 &
  echo $! >/tmp/k8s-leader.pid

  echo """

  TRYING TO ACQUIRE LEADERSHIP WITH k8s-leader with lease name '${k8s_leader_lease_name} in namespace '${NAMESPACE}' using identity '${HOSTNAME}' ..."
  while true; do
    if [[ -f /tmp/k8s-leader ]]; then
      leader_hostname=$(cat /tmp/k8s-leader)
      if [[ "$leader_hostname" == "$HOSTNAME" ]]; then
        break
      fi
    fi

    sleep 1
  done
  echo "...WE ARE THE LEADER!"
fi


[[ "${PORT:-}" = "" ]] && export PORT=9090

echo "starting chisel in port '${PORT}'"

chisel server --port 9090 --reverse --keepalive 5s & wait
