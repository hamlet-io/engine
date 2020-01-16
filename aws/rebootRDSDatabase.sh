#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

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
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Ensure mandatory arguments have been provided
[[ -z "${COMPONENT}" ]] && fatalMandatory

# Set up the context
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

status_file="$(getTopTempDir)/reboot_rds_status.txt"

# Ensure we are in the right place
checkInSegmentDirectory

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
        aws --region ${REGION} rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_IDENTIFIER} 2>/dev/null | grep "DBInstanceStatus" > "${status_file}"
        cat "${status_file}"
        grep "available" "${status_file}" >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -eq 0 ]; then break; fi
        grep "rebooting" "${status_file}"  >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -ne 0 ]; then break; fi
        sleep $DELAY
    done
fi
