#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
DELAY_DEFAULT=30
TIER_DEFAULT="web"
COMPONENT_DEFAULT="www"

function usage() {
    cat <<EOF

Run an ECS task

Usage: $(basename $0) -t TIER -i COMPONENT -w TASK -e ENV -v VALUE -d DELAY

where

(o) -c CONTAINER    is the name of the container that environment details are applied to
(o) -d DELAY        is the interval between checking the progress of the task
(o) -e ENV          is the name of an environment variable to define for the task
    -h              shows this text
(o) -i COMPONENT    is the name of the component in the solution where the task is defined
(o) -t TIER         is the name of the tier in the solution where the task is defined
(o) -v VALUE        is the value for the last environment value defined (via -e) for the task
(m) -w TASK         is the name of the task to be run

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

DELAY     = ${DELAY_DEFAULT} seconds
TIER      = ${TIER_DEFAULT}
COMPONENT = ${COMPONENT_DEFAULT}

NOTES:

1. The ECS cluster is found using the provided tier and component combined with the product and segment
2. ENV and VALUE should always appear in pairs

EOF
    exit
}

ENV_STRUCTURE="\"environment\":["
ENV_NAME=

# Parse options
while getopts ":d:e:hi:t:v:w:" opt; do
    case $opt in
        d)
            DELAY="${OPTARG}"
            ;;
        e)
            # Separate environment variable definitions
            if [[ -n "${ENV_NAME}" ]]; then 
              ENV_STRUCTURE="${ENV_STRUCTURE},"
            fi
            ENV_NAME="${OPTARG}"
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
        v)
            # TODO: add escaping of quotes in OPTARG
            ENV_STRUCTURE="${ENV_STRUCTURE}{\"name\":\"${ENV_NAME}\", \"value\":\"${OPTARG}\"}"
            ;;
        w)
            TASK="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

DELAY="${DELAY:-${DELAY_DEFAULT}}"
TIER="${TIER:-${TIER_DEFAULT}}"
COMPONENT="${COMPONENT:-${COMPONENT_DEFAULT}}"
ENV_STRUCTURE="${ENV_STRUCTURE}]"

# Ensure mandatory arguments have been provided
[[ -z "${TASK}" ]] && fatalMandatory

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

status_file="$(getTopTempDir)/run_task_status.txt"

# Ensure we are in the right place
checkInSegmentDirectory

# Extract key identifiers
RID=$(getJSONValue "${COMPOSITE_BLUEPRINT}" ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Id")
CID=$(getJSONValue "${COMPOSITE_BLUEPRINT}" ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Components[] | objects | select(.Name==\"${COMPONENT}\") | .Id")
KID=$(getJSONValue "${COMPOSITE_BLUEPRINT}" ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Components[] | objects | select(.Name==\"${COMPONENT}\") | .ECS.Tasks[] | objects | select(.Name==\"${TASK}\") | .Id")

# Remove component type
CID="${CID%-*}"

# Handle task mode
KID="${KID/-/X}"

# Handle container name
if [[ -n "${CONTIANER}" ]]; then 
    CONTAINER="${KID%X*}"
fi

# Find the cluster
CLUSTER_ARN=$(aws --region ${REGION} ecs list-clusters | jq -r ".clusterArns[] | capture(\"(?<arn>.*${PRODUCT}-${ENVIRONMENT}-${SEGMENT}.*ecsX${RID}X${CID}.*)\").arn")
if [[ -z "${CLUSTER_ARN}" ]]; then
    CLUSTER_ARN=$(aws --region ${REGION} ecs list-clusters | jq -r ".clusterArns[] | capture(\"(?<arn>.*${PRODUCT}-${ENVIRONMENT}.*ecsX${RID}X${CID}.*)\").arn")

    if [[ -z "${CLUSTER_ARN}" ]]; then
        fatal "Unable to locate ECS cluster"
        return 255
    fi
fi

# Find the task definition
TASK_DEFINITION_ARN=$(aws --region ${REGION} ecs list-task-definitions | jq -r ".taskDefinitionArns[] | capture(\"(?<arn>.*${PRODUCT}-${ENVIRONMENT}-${SEGMENT}.*ecsTaskX${RID}X${CID}X${KID}.*)\").arn")
if [[ -z "${TASK_DEFINITION_ARN}" ]]; then
    TASK_DEFINITION_ARN=$(aws --region ${REGION} ecs list-task-definitions | jq -r ".taskDefinitionArns[] | capture(\"(?<arn>.*${PRODUCT}-${ENVIRONMENT}.*ecsTaskX${RID}X${CID}X${KID}.*)\").arn")

    if [[ -z "${TASK_DEFINITION_ARN}" ]]; then
        fatal "Unable to locate task definition"
        return 255
    fi
fi

# Find the container - support legacy naming
for CONTAINER_NAME in "${CONTAINER}" "${TIER}-${COMPONENT}-${CONTAINER}"; do
    aws --region ${REGION} ecs run-task --cluster "${CLUSTER_ARN}" --task-definition "${TASK_DEFINITION_ARN}" --count 1 --overrides "{\"containerOverrides\":[{\"name\":\"${CONTAINER_NAME}\",${ENV_STRUCTURE}}]}" > "${status_file}" 2>&1
    RESULT=$?
    [[ "$RESULT" -eq 0 ]] && break
done

if [ "$RESULT" -ne 0 ]; then exit; fi

cat "${status_file}"
TASK_ARN=$(jq -r ".tasks[0].taskArn" < "${status_file}")

while true; do
    aws --region ${REGION} ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks ${TASK_ARN} 2>/dev/null | jq ".tasks[] | select(.taskArn == \"${TASK_ARN}\") | {lastStatus: .lastStatus}" > "${status_file}"
    cat "${status_file}"
    grep "STOPPED" "${status_file}" >/dev/null 2>&1
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then break; fi
    grep "PENDING\|RUNNING" "${status_file}"  >/dev/null 2>&1
    RESULT=$?
    if [ "$RESULT" -ne 0 ]; then break; fi
    sleep $DELAY
done

# Show the exit codes and return an error if they are not 0
aws --region ${REGION} ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks ${TASK_ARN} 2>/dev/null | jq ".tasks[].containers[] | {name: .name, exitCode: .exitCode}" > "${status_file}"
cat "${status_file}"
RESULT=$(jq ".exitCode" < "${status_file}" | grep -m 1 -v "^0$" | tr -d '"' )
RESULT=${RESULT:-0}