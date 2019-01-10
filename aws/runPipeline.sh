#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
DELAY_DEFAULT=30
CHECKONLY_DEFAULT="false"

function usage() {
    cat <<EOF

Run an AWS Data pipeline

Usage: $(basename $0) -t TIER -i COMPONENT -x INSTANCE -y VERSION 

where

    -h                  shows this text
(m) -i COMPONENT        is the name of the component in the solution where the task is defined
(m) -t TIER             is the name of the tier in the solution where the task is defined
(o) -x INSTANCE         is the instance of the task to be run
(o) -y VERSION          is the version of the task to be run
(o) -c CHECKONLY        check the running status of a pipelie

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:


NOTES:

1. This will activate the pipeline and leave it running
2. Pipelines take a long time so it is better to provide status via other means


EOF
    exit
}


# Parse options
while getopts ":c:hi:t:x:y:" opt; do
    case $opt in
        c)
            CHECKONLY="true"
            ;;
        h)
            usage
            ;;
        i)
            COMPONENT="${OPTARG}"
            ;;
        t)
            TIER="${OPTARG}"
            ;;
        x)  
            INSTANCE="${OPTARG}"
            ;;
        y)  
            VERSION="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

#Set Default
CHECKONLY=${CHECKONLY:-${CHECKONLY_DEFAULT}}

RESULT=0 

# Ensure mandatory arguments have been provided
[[ -z "${COMPONENT}" || -z "${TIER}" ]] && fatalMandatory

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

# Ensure we are in the right place
checkInSegmentDirectory

PIPELINE_NAME="${PRODUCT}-${ENVIRONMENT}"

if [[ -n "${SEGMENT}" && "${SEGMENT}" != "default" ]]; then
    PIPELINE_NAME="${PIPELINE_NAME}-${SEGMENT}"
fi

PIPELINE_NAME="${PIPELINE_NAME}-${TIER}-${COMPONENT}"

# Add Instance and Version to pipeline name
if [[ -n "${INSTANCE}" && "${INSTANCE}" != "default" ]]; then
    PIPELINE_NAME="${PIPELINE_NAME}-${INSTANCE}"
fi 

if [[ -n "${VERSION}" ]]; then
    PIPELINE_NAME="${PIPELINE_NAME}-${VERSION}"
fi

# Find the pipeline
PIPELINE_ID="$(aws --region ${REGION} datapipeline list-pipelines --query "pipelineIdList[?name==\`${PIPELINE_NAME}\`].id" --output text)"

if [[ -n "${PIPELINE_ID}" ]]; then
    if [[ "${CHECKONLY}" == "false" || "${CHECKONLY}" -eq false ]]; then 
        aws --region ${REGION} datapipeline activate-pipeline --pipeline-id "${PIPELINE_ID}" || error "Pipeline Could not be activated"; exit $?
    fi

    info "Pipeline runs for the last day"
    aws --region ${REGION} datapipeline list-runs --pipeline-id "${PIPELINE_ID}" --start-interval "$(date --utc +%FT%TZ --date="1 day ago"),$(date --utc +%FT%TZ)" \
    --query  "reverse(sort_by(@, &'@actualStartTime'))" \
    --output json
else 
    error "Pipeline could ${PIPELINE_NAME} could not be found"; exit 128
fi 
