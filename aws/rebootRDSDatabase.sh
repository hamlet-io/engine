#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults
DELAY_DEFAULT=30
TIER_DEFAULT="database"

function usage() {
    cat <<EOF

Reboot an RDS Database

Usage: $(basename $0) -t TIER -i COMPONENT -f -d DELAY

where

(o) -d DELAY            is the interval between checking the progress of reboot
(o) -f                  force reboot via failover
    -h                  shows this text
(m) -i COMPONENT        is the name of the database component in the solution
(o) -r (REBOOT ONLY)    initiates but does not monitor the reboot process
(o) -t TIER             is the name of the database tier in the solution

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

DELAY     = ${DELAY_DEFAULT} seconds
TIER      = ${TIER_DEFAULT}

NOTES:

EOF
    exit
}

DELAY=${DELAY_DEFAULT}
TIER=${TIER_DEFAULT}
FORCE_FAILOVER=false
WAIT=true
# Parse options
while getopts ":d:fhi:rt:" opt; do
    case $opt in
        d)
            DELAY="${OPTARG}"
            ;;
        f)
            FORCE_FAILOVER=true
            ;;
        h)
            usage
            ;;
        i)
            COMPONENT="${OPTARG}"
            ;;
        r)
            WAIT=false
            ;;
        t)
            TIER="${OPTARG}"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}" >&2
            exit
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            exit
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ "${COMPONENT}"  == "" ]]; then
  echo -e "\nInsufficient arguments" >&2
  exit
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the right place
if [[ "${LOCATION}" != "segment" ]]; then
    echo -e "\nWe don't appear to be in the right directory. Nothing to do" >&2
    exit
fi

FAILOVER_OPTION="--no-force-failover"
if [[ "${FORCE_FAILOVER}" == "true" ]]; then
    FAILOVER_OPTION="--no-force-failover"
fi

DB_INSTANCE_IDENTIFIER="${PRODUCT}-${SEGMENT}-${TIER}-${COMPONENT}"

# Trigger the reboot
aws --region ${REGION} rds reboot-db-instance --db-instance-identifier ${DB_INSTANCE_IDENTIFIER}
RESULT=$?
if [ "$RESULT" -ne 0 ]; then exit; fi

if [[ "${WAIT}" == "true" ]]; then
    while true; do
        aws --region ${REGION} rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_IDENTIFIER} 2>/dev/null | grep "DBInstanceStatus" > STATUS.txt
        cat STATUS.txt
        grep "available" STATUS.txt >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -eq 0 ]; then break; fi
        grep "rebooting" STATUS.txt  >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -ne 0 ]; then break; fi
        sleep $DELAY
    done
fi

