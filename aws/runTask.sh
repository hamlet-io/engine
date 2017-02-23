#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults
DELAY_DEFAULT=30
TIER_DEFAULT="web"
COMPONENT_DEFAULT="www"

function usage() {
    cat <<EOF

Run an ECS task

Usage: $(basename $0) -t TIER -i COMPONENT -w TASK -e ENV -v VALUE -d DELAY

where

(o) -d DELAY is the interval between checking the progress of the task
(o) -e ENV is the name of an environment variable to define for the task
    -h shows this text
(o) -i COMPONENT is the name of the component in the solution where the task is defined
(o) -t TIER is the name of the tier in the solution where the task is defined
(o) -v VALUE is the value for the last environment value defined (via -e) for the task
(m) -w TASK is the name of the task to be run

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
            ENV_STRUCTURE="${ENV_STRUCTURE}{\"name\":\"${ENV_NAME}\", \"value\":\"${OPTARG}\"}"
            ;;
        w)
            TASK="${OPTARG}"
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

DELAY="${DELAY:-${DELAY_DEFAULT}}"
TIER="${TIER:-${TIER_DEFAULT}}"
COMPONENT="${COMPONENT:-${COMPONENT_DEFAULT}}"
ENV_STRUCTURE="${ENV_STRUCTURE}]"

# Ensure mandatory arguments have been provided
if [[ "${TASK}"  == "" ]]; then
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

# Extract key identifiers
RID=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Id")
CID=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Components[] | objects | select(.Name==\"${COMPONENT}\") | .Id")
KID=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Tiers[] | objects | select(.Name==\"${TIER}\") | .Components[] | objects | select(.Name==\"${COMPONENT}\") | .ECS.Tasks[] | objects | select(.Name==\"${TASK}\") | .Id")

# Find the cluster
CLUSTER_ARN=$(aws --region ${REGION} ecs list-clusters | jq -r ".clusterArns[] | capture(\"(?<arn>.*${PRODUCT}-${SEGMENT}.*ecsX${RID}X${CID}.*)\").arn")
if [[ -z "${CLUSTER_ARN}" ]]; then
    echo -e "\nUnable to locate ECS cluster" >&2
    exit
fi

# Find the task definition
TASK_DEFINITION_ARN=$(aws --region ${REGION} ecs list-task-definitions | jq -r ".taskDefinitionArns[] | capture(\"(?<arn>.*${PRODUCT}-${SEGMENT}.*ecsTaskX${RID}X${CID}X${KID}.*)\").arn")
if [[ -z "${TASK_DEFINITION_ARN}" ]]; then
    echo -e "\nUnable to locate task definition" >&2
    exit
fi

aws --region ${REGION} ecs run-task --cluster "${CLUSTER_ARN}" --task-definition "${TASK_DEFINITION_ARN}" --count 1 --overrides "{\"containerOverrides\":[{\"name\":\"${TIER}-${COMPONENT}-${TASK}\",${ENV_STRUCTURE}}]}" > STATUS.txt
RESULT=$?
if [ "$RESULT" -ne 0 ]; then exit; fi
cat STATUS.txt
TASK_ARN=$(cat STATUS.txt | jq -r ".tasks[0].taskArn")

while true; do
    aws --region ${REGION} ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks ${TASK_ARN} 2>/dev/null | jq ".tasks[] | select(.taskArn == \"${TASK_ARN}\") | {lastStatus: .lastStatus}" > STATUS.txt
    cat STATUS.txt
    grep "STOPPED" STATUS.txt >/dev/null 2>&1
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then break; fi
    grep "PENDING\|RUNNING" STATUS.txt  >/dev/null 2>&1
    RESULT=$?
    if [ "$RESULT" -ne 0 ]; then break; fi
    sleep $DELAY
done

# Show the exit codes and return an error if they are not 0
aws --region ${REGION} ecs describe-tasks --cluster ${CLUSTER_ARN} --tasks ${TASK_ARN} 2>/dev/null | jq ".tasks[].containers[] | {name: .name, exitCode: .exitCode}" > STATUS.txt
cat STATUS.txt
RESULT=$(cat STATUS.txt | jq ".exitCode" | grep -m 1 -v "^0$" | tr -d '"')
RESULT=${RESULT:-0}


