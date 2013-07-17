#!/bin/bash

SERVICE=${1:?no SERVICE given}
CMD=${2:?no CMD given}

SERVICE_STATE_FILE=/tmp/service.$SERVICE

case $CMD in
    status)
        STATE=$(cat $SERVICE_STATE_FILE)
        [[ -z STATE ]] && STATE = 42
        exit $STATE
        ;;
    start)
        echo 0 > $SERVICE_STATE_FILE
        exit 0
        ;;
    stop)
        echo 3 > $SERVICE_STATE_FILE
        exit 0
        ;;
    *)
        echo "unknown command $CMD on service $SERVICE" >&2
        exit 2
        ;;
esac
