#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults
DELAY_DEFAULT=30
TIER_DEFAULT="database"

function usage() {
    cat <<EOF

Snapshot an RDS Database

Usage: $(basename $0) -t TIER -i COMPONENT -s SUFFIX -c -m -d DELAY -r RETAIN -a AGE

where

(o) -a AGE              is the maximum age in days of snapshots to retain
(o) -c (CREATE ONLY)    initiates but does not monitor the snapshot creation process
(o) -d DELAY            is the interval between checking the progress of snapshot creation
    -h                  shows this text
(m) -i COMPONENT        is the name of the database component in the solution
(o) -m (MONITOR ONLY)   monitors but does not initiate the snapshot creation process
(o) -r RETAIN           is the count of snapshots to retain
(o) -s SUFFIX           to be postpended to the snapshot identifier
(o) -t TIER             is the name of the database tier in the solution

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

DELAY     = ${DELAY_DEFAULT} seconds
TIER      = ${TIER_DEFAULT}

NOTES:

1. Snapshot identifer takes the form {product}-{environment}-{tier}-{component}-datetime-{suffix}
2. RETAIN and AGE may be used together. If both are present, RETAIN is applied first

EOF
    exit
}

DELAY=${DELAY_DEFAULT}
TIER=${TIER_DEFAULT}
CREATE=true
WAIT=true
# Parse options
while getopts ":a:cd:hi:mr:s:t:" opt; do
    case $opt in
        a)
            AGE="${OPTARG}"
            ;;
        c)
            WAIT=false
            ;;
        d)
            DELAY="${OPTARG}"
            ;;
        h)
            usage
            ;;
        i)
            COMPONENT="${OPTARG}"
            ;;
        m)
            CREATE=false
            ;;
        r)
            RETAIN="${OPTARG}"
            ;;
        s)
            SUFFIX="${OPTARG}"
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

status_file="$(getTopTempDir)/snapshot_rds_status.txt"

# Ensure we are in the right place
checkInSegmentDirectory

ENVIRONMENT_SUFFIX="-${ENVIRONMENT}"
SEGMENT_SUFFIX="-${SEGMENT}"
if [[ ("${SEGMENT}" == "${ENVIRONMENT}") ||
        ("${SEGMENT}" == "default") ]]; then
    SEGMENT_SUFFIX=""
fi
TIER_SUFFIX="-${TIER}"
COMPONENT_SUFFIX="-${COMPONENT}"

DB_INSTANCE_IDENTIFIER="${PRODUCT}${ENVIRONMENT_SUFFIX}${SEGMENT_SUFFIX}${TIER_SUFFIX}${COMPONENT_SUFFIX}"
DB_SNAPSHOT_IDENTIFIER="${DB_INSTANCE_IDENTIFIER}-$(date -u +%Y-%m-%d-%H-%M-%S)"
if [[ "${SUFFIX}" != "" ]]; then
    DB_SNAPSHOT_IDENTIFIER="${DB_SNAPSHOT_IDENTIFIER}-${SUFFIX}"
fi

if [[ "${CREATE}" == "true" ]]; then
    aws --region ${REGION} rds create-db-snapshot --db-snapshot-identifier ${DB_SNAPSHOT_IDENTIFIER} --db-instance-identifier ${DB_INSTANCE_IDENTIFIER}
    RESULT=$?
    if [ "$RESULT" -ne 0 ]; then exit; fi
fi

if [[ ("${RETAIN}" != "") || ("${AGE}" != "") ]]; then
    if [[ "${RETAIN}" != "" ]]; then
        LIST=$(aws --region ${REGION} rds describe-db-snapshots --snapshot-type manual | grep DBSnapshotIdentifier | grep ${DB_INSTANCE_IDENTIFIER} | cut -d'"' -f 4 | sort | head -n -${RETAIN})
    else
        LIST=$(aws --region ${REGION} rds describe-db-snapshots --snapshot-type manual | grep DBSnapshotIdentifier | grep ${DB_INSTANCE_IDENTIFIER} | cut -d'"' -f 4 | sort)
    fi
    if [[ "${AGE}" != "" ]]; then
        BASELIST=${LIST}
        LIST=""
        LASTDATE=$(date --utc +%Y%m%d%H%M%S -d "$AGE days ago")
        for SNAPSHOT in $(echo $BASELIST); do
            DATEPLUSSUFFIX=${SNAPSHOT#"$DB_INSTANCE_IDENTIFIER-"}
            SUFFIX=${DATEPLUSSUFFIX#????-??-??-??-??-??}
            SNAPSHOTDATE=$(tr -d "-" <<< ${DATEPLUSSUFFIX%"$SUFFIX"})
            if [[ $LASTDATE > $SNAPSHOTDATE ]]; then
                LIST="${LIST} ${SNAPSHOT}"
            fi
        done
    fi
    if [[ "${LIST}" != "" ]]; then
        for SNAPSHOT in $(echo $LIST); do
            aws --region ${REGION} rds delete-db-snapshot --db-snapshot-identifier $SNAPSHOT
        done
    fi
fi

RESULT=1
if [[ "${WAIT}" == "true" ]]; then
    while true; do
        aws --region ${REGION} rds describe-db-snapshots --db-snapshot-identifier ${DB_SNAPSHOT_IDENTIFIER} 2>/dev/null | grep "Status" > "${status_file}"
        cat "${status_file}"
        grep "available" "${status_file}" >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -eq 0 ]; then break; fi
        grep "creating" "${status_file}"  >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -ne 0 ]; then break; fi
        sleep $DELAY
    done
fi
