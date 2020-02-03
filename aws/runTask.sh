#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults
DELAY_DEFAULT=30

function usage() {
    cat <<EOF

Run an ECS task

Usage: $(basename $0) -t TIER -i COMPONENT -w TASK -e ENV -v VALUE -d DELAY

where

(o) -c CONTAINER_ID         is the name of the container that environment details are applied to
(o) -d DELAY                is the interval between checking the progress of the task
(o) -e ENV                  is the name of an environment variable to define for the task
    -h                      shows this text
(m) -i COMPONENT            is the name of the ecs component in the solution where the task is defined
(o) -j COMPONENT_INSTANCE   is the instance of the ecs cluster to run the task on
(o) -k COMPONENT_VERSION    is the version of the ecs clsuter to run the task on
(m) -t TIER                 is the name of the tier in the solution where the task is defined
(o) -v VALUE                is the value for the last environment value defined (via -e) for the task
(m) -w TASK                 is the name of the task to be run
(o) -x INSTANCE             is the instance of the task to be run
(o) -y VERSION              is the version of the task to be run

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

DELAY     = ${DELAY_DEFAULT} seconds

NOTES:

1. The ECS cluster is found using the provided tier and component combined with the product and segment
2. ENV and VALUE should always appear in pairs

EOF
    exit
}

ENV_STRUCTURE="\"environment\":["
ENV_NAME=

# Parse options
while getopts ":c:d:e:hi:j:k:t:v:x:y:w:" opt; do
    case $opt in
        c)
            CONTAINER_ID="${OPTARG}"
            ;;
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
        j)
            COMPONET_INSTANCE="${OPTARG}"
            ;;
        k)
            COMPONENT_VERSION="${OPTARG}"
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

DELAY="${DELAY:-${DELAY_DEFAULT}}"
ENV_STRUCTURE="${ENV_STRUCTURE}]"

# Ensure mandatory arguments have been provided
if [[ -z "${TASK}" || -z "${TIER}" || -z "${COMPONENT}" ]]; then
     fatalMandatory
     exit 255
fi

# Set up the context
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

status_file="$(getTopTempDir)/run_task_status.txt"

# Ensure we are in the right place
checkInSegmentDirectory

# Generate a blueprint that we can use to find hosting details
info "Generating blueprint to find details..."
${GENERATION_DIR}/createBlueprint.sh >/dev/null || exit $?
ENV_BLUEPRINT="${PRODUCT_STATE_DIR}/cot/${ENVIRONMENT}/${SEGMENT}/blueprint.json"

# Search through the blueprint to find the cluster and the task
COMPONENT_BLUEPRINT="$(getJSONValue "${ENV_BLUEPRINT}" \
                                    " .Tenants[]        | objects | select(.Name==\"${TENANT}\") \
                                    | .Products[]       | objects | select(.Name==\"${PRODUCT}\") \
                                    | .Environments[]   | objects | select(.Name==\"${ENVIRONMENT}\") \
                                    | .Segments[]       | objects | select(.Name==\"${SEGMENT}\") \
                                    | .Tiers[]          | objects | select(.Name==\"${TIER}\") \
                                    | .Components[]     | objects | select(.Name==\"${COMPONENT}\") \
                                    | .Occurrences[]    | objects | \
                                            select( \
                                                .Core.Type==\"ecs\" \
                                                and .Core.Component.RawName==\"${COMPONENT}\" \
                                                and .Core.Instance.Name==\"${COMPONENT_INSTANCE}\" \
                                                and .Core.Version.Name==\"${COMPONENT_VERSION}\" \
                                            ) \
                                    | .Occurrences[] | objects | \
                                            select( \
                                                .Core.Type==\"task\" \
                                                and .Core.Component.RawName==\"${TASK}\" \
                                                and .Core.Instance.Name==\"${INSTANCE}\" \
                                                and .Core.Version.Name==\"${VERSION}\" \
                                            )")"

CLUSTER_ARN="$( echo "${COMPONENT_BLUEPRINT}" | jq -r '.State.Attributes.ECSHOST' )"
DEFAULT_CONTAINER="$( echo "${COMPONENT_BLUEPRINT}" | jq -r '.Configuration.Solution.Containers | keys | .[0]' )"
TASK_DEFINITION_ID="-$( echo "${COMPONENT_BLUEPRINT}" | jq -r '.State.ResourceGroups.default.Resources.task.Id' )-"

# Handle container name
if [[ -n "${CONTAINER_ID}" ]]; then
    CONTAINER="${CONTAINER_ID}"
else
    CONTAINER="${DEFAULT_CONTAINER%-*}"
fi

if [[ "${SEGMENT}" == "default" ]]; then
    SEGMENT=""
fi

TASK_DEFINITION_ARN="$(aws --region "${REGION}" ecs list-task-definitions --query "taskDefinitionArns[?contains(@, '${TASK_DEFINITION_ID}') == \`true\`]|[?contains(@, '${PRODUCT}-${ENVIRONMENT}-${SEGMENT}') == \`true\`] | [0]" --output text )"

info "Found the following task details \n * ClusterARN=${CLUSTER_ARN} \n * TaskDefinitionArn=${TASK_DEFINITION_ARN} \n * Container=${CONTAINER}"

# Check the cluster
if [[ -n "${CLUSTER_ARN}" ]]; then
    CLUSTER_STATUS="$(aws --region "${REGION}" ecs describe-clusters --clusters "${CLUSTER_ARN}" --output text --query 'clusters[0].status')"
    debug "Cluster Status ${CLUSTER_STATUS}"
    if [[ "${CLUSTER_STATUS}" != "ACTIVE" ]]; then
        fatal "ECS Cluster ${CLUSTER_ARN} could not be found or was not active"
        exit
    fi
else
    fatal "ECS Cluster not found - Component=${COMPONENT}"
    exit
fi

# Find the task definition
if [[ -z "${TASK_DEFINITION_ARN}" ]]; then
    fatal "Unable to locate task definition"
    exit
fi

# Find the container
TASK_ARN="$(aws --region "${REGION}" ecs run-task --cluster "${CLUSTER_ARN}" --task-definition "${TASK_DEFINITION_ARN}" --count 1 --overrides "{\"containerOverrides\":[{\"name\":\"${CONTAINER}\",${ENV_STRUCTURE}}]}" --query 'tasks[0].taskArn' --output text || exit $? )"

info "Watching task..."
while true; do
    LAST_STATUS="$(aws --region ${REGION} ecs describe-tasks --cluster "${CLUSTER_ARN}" --tasks "${TASK_ARN}" --query "tasks[?taskArn=='${TASK_ARN}'].lastStatus" --output text || break $?)"

    echo "...${LAST_STATUS}"

    if [[ "${LAST_STATUS}" == "STOPPED" ]]; then
        break
    fi
    sleep $DELAY
done

# Show the exit codes and return an error if they are not 0
TASK_FINAL_STATUS="$( aws --region "${REGION}" ecs describe-tasks --cluster "${CLUSTER_ARN}" --tasks "${TASK_ARN}" --query "tasks[?taskArn=='${TASK_ARN}'].{taskArn: taskArn, overrides: overrides, containers: containers }" || exit $? )"

info "Task Results"
echo "${TASK_FINAL_STATUS}"

# Use the exit status of the override container to determine the result
RESULT=$( echo "${TASK_FINAL_STATUS}" | jq -r ".[].containers[] | select(.name=\"${CONTAINER}\") | .exitCode" )
RESULT=${RESULT:-0}
