#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"


#Defaults
INCLUDE_LOG_TAIL_DEFAULT="true"

tmpdir="$(getTempDir "cote_inf_XXX")"

function usage() {
    cat <<EOF

Run an AWS Lambda Function

Usage: $(basename $0) -u DEPLOYMENT_UNIT -i INPUT_PAYLOAD -l INCLUDE_LOG_TAIL

where

    -h                  shows this text
(m) -f FUNCTION_ID      is the id of the function in the lambda deployment to run
(m) -u DEPLOYMENT_UNIT  is the lambda deployment unit you want to execute
(o) -i INPUT_PAYLOAD    is the json based payload you want to run the lambda with
(o) -l INCLUDE_LOG_TAIL include the last 4kb of the execution log

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:


NOTES:


EOF
    exit
}


function options() {

    # Parse options
    while getopts ":f:hi:lu:" opt; do
        case $opt in
            h)
                usage
                ;;
            i)
                INPUT_PAYLOAD="${OPTARG}"
                ;;
            l)
                INCLUDE_LOG_TAIL="true"
                ;;
            u)
                DEPLOYMENT_UNIT="${OPTARG}"
                ;;
            f)
                FUNCTION_ID="${OPTARG}"
                ;;
            \?)
                fatalOption
                ;;
            :)
                fatalOptionArgument
                ;;
        esac
    done

    #Defaults
    INCLUDE_LOG_TAIL=${INCLUDE_LOG_TAIL:-$INCLUDE_LOG_TAIL_DEFAULT}
}

function main() {

    options "$@" || return $?

    # Ensure mandatory arguments have been provided
    [[ -z "${DEPLOYMENT_UNIT}" || -z "${FUNCTION_ID}" ]] && fatalMandatory; return $?

    # Set up the context
    . "${GENERATION_BASE_DIR}/execution/setContext.sh"

    # Ensure we are in the right place
    checkInSegmentDirectory

    # Create build blueprint
    ${GENERATION_DIR}/createBuildblueprint.sh -u "${DEPLOYMENT_UNIT}"  -o "${AUTOMATION_DATA_DIR}" >/dev/null || return $?

    COT_TEMPLATE_DIR="${PRODUCT_STATE_DIR}/cot/${ENVIRONMENT}/${SEGMENT}"
    BUILD_BLUEPRINT="${COT_TEMPLATE_DIR}/build_blueprint-${DEPLOYMENT_UNIT}-config.json"

    DEPLOYMENT_UNIT_TYPE="$(jq -r '.Type' < "${BUILD_BLUEPRINT}" )"

    LAMBDA_OUTPUT_FILE="${tmpdir}/${DEPLOYMENT_UNIT}_output.txt"

    if [[ "${DEPLOYMENT_UNIT_TYPE}" -ne "lambda" ]]; then
        fatal "Component type is not a lambda function"
        return 255
    fi

    if [[ -n "${INPUT_PAYLOAD}" ]]; then
        INPUT_PAYLOAD="$( echo "${INPUT_PAYLOAD}" | jq -r '.' )"
        if [[ -z "${INPUT_PAYLOAD}" ]]; then
            fatal "Invalid input payload - must be in JSON format"
            return 255
        fi
    fi

    LAMBDA_ARN="$( jq --arg functionId ${FUNCTION_ID} -r '.Occurrence.Occurrences[] | select( .Core.SubComponent.Id==$functionId ) | .State.Attributes.ARN' < "${BUILD_BLUEPRINT}")"

    if [[ -n "${LAMBDA_ARN}" ]]; then

        LAMBDA_EXECUTE=$(aws --region ${REGION} lambda invoke --function-name "${LAMBDA_ARN}" \
            --invocation-type "RequestResponse" --log-type "Tail" \
            --payload "${INPUT_PAYLOAD}" \
            "${LAMBDA_OUTPUT_FILE}" || return $? )

        FUNCTION_ERROR="$( echo "${LAMBDA_EXECUTE}" | jq -r '.FunctionError' )"
        LOG_RESULTS="$( echo "${LAMBDA_EXECUTE}" | jq -r '. | .LogResult' | base64 --decode )"
        RETURN_PAYLOAD="$( echo "${LAMBDA_EXECUTE}" | jq -r '.Payload' )"

        if [[ "$(cat "${LAMBDA_OUTPUT_FILE}")" -ne 'null' ]]; then
            info "Output File:"
            cat "${LAMBDA_OUTPUT_FILE}"
            info "---------------------"
        fi

        if [[ "${RETURN_PAYLOAD}" -ne 'null' ]]; then
            info "Lambda Return Payload:"
            info "${RETURN_PAYLOAD}"
            info "-------------------------"
        fi

        if [[ "${INCLUDE_LOG_TAIL}" == "true" ]]; then
            info "Lambda Execution Logs:"
            info "${LOG_RESULTS}"
            info "-----------------------"
        fi

        if [[ "${FUNCTION_ERROR}" -ne "null" ]]; then
            fatal "An error occurred in the lambda function - Details provided in the return payload"
            return 128
        fi

     else
        error "Lambda ARN not found for ${DEPLOYMENT_UNIT} has it been deployed?"
        return 128
    fi

    # All good
    info "Lambda execute complete"
    return 0
}

main "$@"
