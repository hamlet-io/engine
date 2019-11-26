#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults
DEFAULT_PIPELINE_STATUS_ONLY="false"
DEFAULT_PIPELINE_ALLOW_CONCURRENT="false"

function usage() {
    cat <<EOF

Run an AWS Data pipeline

Usage: $(basename $0) -t TIER -i COMPONENT -x INSTANCE -y VERSION

where

    -h                              shows this text
(m) -i COMPONENT                    is the name of the component in the solution where the task is defined
(m) -t TIER                         is the name of the tier in the solution where the task is defined
(o) -x INSTANCE                     is the instance of the task to be run
(o) -y VERSION                      is the version of the task to be run
(o) -s PIPELINE_STATUS_ONLY              check the running status of a pipelie
(o) -c PIPELINE_ALLOW_CONCURRENT    activate the pipeline if another one is running

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

PIPELINE_STATUS_ONLY=${DEFAULT_PIPELINE_STATUS_ONLY}
PIPELINE_ALLOW_CONCURRENT=${DEFAULT_PIPELINE_ALLOW_CONCURRENT}

NOTES:

1. This will activate the pipeline and leave it running
2. Pipelines take a long time so it is better to provide status via other means

EOF
    exit
}

function options() {
    # Parse options
    while getopts ":chi:st:x:y:" opt; do
        case $opt in

            c)
                PIPELINE_ALLOW_CONCURRENT="true"
                ;;
            h)
                usage
                ;;
            i)
                COMPONENT="${OPTARG}"
                ;;
            s)
                PIPELINE_STATUS_ONLY="true"
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
}


function main() {

    options "$@" || return $?

    #Set Defaults
    PIPELINE_STATUS_ONLY="${PIPELINE_STATUS_ONLY:-${DEFAULT_PIPELINE_STATUS_ONLY}}"
    PIPELINE_ALLOW_CONCURRENT="${PIPELINE_ALLOW_CONCURRENT:-${DEFAULT_PIPELINE_ALLOW_CONCURRENT}}"

    # Ensure mandatory arguments have been provided
    [[ -z "${COMPONENT}" || -z "${TIER}" ]] && fatalMandatory

    # Set up the context
    . "${GENERATION_BASE_DIR}/execution/setContext.sh"

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
    PIPELINE_ID="$(aws --region ${REGION} datapipeline list-pipelines --query "pipelineIdList[?name==\`${PIPELINE_NAME}\`].id" --output text || return $?)"

    if [[ -n "${PIPELINE_ID}" ]]; then

        info "Pipeline found Id: ${PIPELINE_ID}"
        PIPELINE_STATE="$(aws --region ${REGION} datapipeline list-runs --pipeline-id "${PIPELINE_ID}" --start-interval "$(date --utc +%FT%TZ --date="1 day ago"),$(date --utc +%FT%TZ)" --query "reverse(sort_by(@, &'@actualStartTime'))" --output json || return $?)"
        ACTIVE_JOBS="$(echo "${PIPELINE_STATE}" | jq -r '[ .[] | select( ."@status" == "RUNNING" or ."@status" == "ACTIVATING" or ."@status" == "DEACTIVATING" or ."@status" == "PENDING" or ."@status" == "SCHEDULED" or ."@status" == "SHUTTING_DOWN" or ."@status" == "WAITING_FOR_RUNNER" or ."@status" == "WAITING_ON_DEPENDENCIES" or ."@status" ==  "VALIDATING" )]')"

        if [[ "${PIPELINE_STATUS_ONLY}" == "false" && ( "${PIPELINE_ALLOW_CONCURRENT}" == "true" || "$( echo "${ACTIVE_JOBS}" | jq -r '. | length' )" == "0" ) ]]; then
            info "Activating pipeline ${PIPELINE_NAME} - ${PIPELINE_ID}"
            aws --region ${REGION} datapipeline activate-pipeline --pipeline-id "${PIPELINE_ID}" || return $?
            sleep 30
        fi

        PIPELINE_STATE="$(aws --region ${REGION} datapipeline list-runs --pipeline-id "${PIPELINE_ID}" --start-interval "$(date --utc +%FT%TZ --date="1 day ago"),$(date --utc +%FT%TZ)" --query "reverse(sort_by(@, &'@actualStartTime'))" --output json || return $?)"
        ACTIVE_JOBS="$(echo "${PIPELINE_STATE}" | jq -r '[ .[] | select( ."@status" == "RUNNING" or ."@status" == "ACTIVATING" or ."@status" == "DEACTIVATING" or ."@status" == "PENDING" or ."@status" == "SCHEDULED" or ."@status" == "SHUTTING_DOWN" or ."@status" == "WAITING_FOR_RUNNER" or ."@status" == "WAITING_ON_DEPENDENCIES" or ."@status" ==  "VALIDATING" )]')"

        if [[  "$( echo "${ACTIVE_JOBS}" | jq -r '. | length' )" -gt "0" ]]; then
            info "Active pipeline jobs for ${PIPELINE_NAME} - ${PIPELINE_ID}"
            echo "${ACTIVE_JOBS}" | jq '.'
        else
            info "No Active pipeline jobs for ${PIPELINE_NAME} - ${PIPELINE_ID}"
        fi
    else
        fatal "Pipline with name ${PIPELINE_NAME} not found"
        return 255
    fi

    # All good
    return 0
}

main "$@" || exit $?
