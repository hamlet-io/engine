#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

DELAY_DEFAULT=30
TIER_DEFAULT="database"
function usage() {
    echo -e "\nSnapshot an RDS Database" 
    echo -e "\nUsage: $(basename $0) -t TIER -i COMPONENT -s SUFFIX -c -m -d DELAY -r RETAIN -a AGE\n"
    echo -e "\nwhere\n"
    echo -e "(o) -a AGE is the maximum age in days of snapshots to retain"
    echo -e "(o) -c (CREATE ONLY) initiates but does not monitor the snapshot creation process"
    echo -e "(o) -d DELAY is the interval between checking the progress of snapshot creation"
    echo -e "    -h shows this text"
    echo -e "(m) -i COMPONENT is the name of the database component in the solution"
    echo -e "(o) -m (MONITOR ONLY) monitors but does not initiate the snapshot creation process"
    echo -e "(o) -r RETAIN is the count of snapshots to retain"
    echo -e "(o) -s SUFFIX is appended to the snapshot identifier"
    echo -e "(o) -t TIER is the name of the database tier in the solution"
    echo -e "\nDEFAULTS:\n"
    echo -e "DELAY     = ${DELAY_DEFAULT} seconds"
    echo -e "TIER      = ${TIER_DEFAULT}"
    echo -e "\nNOTES:\n"
    echo -e "1. Snapshot identifer takes the form {product}-{environment}-{tier}-{component}-datetime-{suffix}"
    echo -e "2. RETAIN and AGE may be used together. If both are present, RETAIN is applied first"
    echo -e ""
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ "${COMPONENT}"  == "" ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the right place
if [[ "${LOCATION}" != "segment" ]]; then
    echo -e "\nWe don't appear to be in the right directory. Nothing to do"
    usage
fi

DB_INSTANCE_IDENTIFIER="${PID}-${SEGMENT}-${TIER}-${COMPONENT}"
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
            SNAPSHOTDATE=$(echo ${DATEPLUSSUFFIX%"$SUFFIX"} | tr -d "-")
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
        aws --region ${REGION} rds describe-db-snapshots --db-snapshot-identifier ${DB_SNAPSHOT_IDENTIFIER} 2>/dev/null | grep "Status" > STATUS.txt
        cat STATUS.txt
        grep "available" STATUS.txt >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -eq 0 ]; then break; fi
        grep "creating" STATUS.txt  >/dev/null 2>&1
        RESULT=$?
        if [ "$RESULT" -ne 0 ]; then break; fi
        sleep $DELAY
    done
fi

