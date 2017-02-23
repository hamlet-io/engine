#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults
STACK_INITIATE_DEFAULT="true"
STACK_MONITOR_DEFAULT="true"
STACK_OPERATION_DEFAULT="update"
STACK_WAIT_DEFAULT=30

function usage() {
    cat <<EOF

Manage a CloudFormation stack

Usage: $(basename $0) -t TYPE -s SLICE -i -m -w STACK_WAIT -r REGION -n STACK_NAME -d

where

(o) -d (STACK_OPERATION=delete) to delete the stack
    -h shows this text
(o) -i (STACK_MONITOR=false) initiates but does not monitor the stack operation
(o) -m (STACK_INITIATE=false) monitors but does not initiate the stack operation
(o) -n STACK_NAME to override standard stack naming
(o) -r REGION is the AWS region identifier for the region in which the stack should be managed
(m) -s SLICE is the slice used to determine the stack template
(m) -t TYPE is the stack type - "account", "product", "segment", "solution" or "application"
(o) -w STACK_WAIT is the interval between checking the progress of the stack operation

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

STACK_INITIATE = ${STACK_INITIATE_DEFAULT}
STACK_MONITOR = ${STACK_MONITOR_DEFAULT}
STACK_OPERATION = ${STACK_OPERATION_DEFAULT}
STACK_WAIT = ${STACK_WAIT_DEFAULT} seconds

NOTES:

1. You must be in the correct directory corresponding to the requested stack type
2. REGION is only relevant for the "product" type, where multiple product stacks are necessary
   if the product uses resources in multiple regions
3. "segment" is now used in preference to "container" to avoid confusion with docker
4. If stack doesn't exist in AWS, the update operation will create the stack
5. Overriding the stack name is not recommended except where legacy naming has to be maintained

EOF
    exit
}

# Parse options
while getopts ":dhimn:r:s:t:w:" opt; do
    case $opt in
        d)
            STACK_OPERATION=delete
            ;;
        h)
            usage
            ;;
        i)
            STACK_MONITOR=false
            ;;
        m)
            STACK_INITIATE=false
            ;;
        n)
            STACK_NAME="${OPTARG}"
            ;;
        r)
            REGION="${OPTARG}"
            ;;
        s)
            SLICE="${OPTARG}"
            ;;
        t)
            TYPE="${OPTARG}"
            ;;
        w)
            STACK_WAIT="${OPTARG}"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}" >&2
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            usage
            ;;
    esac
done

# Apply defaults
STACK_OPERATION=${STACK_OPERATION:-${STACK_OPERATION_DEFAULT}}
STACK_WAIT=${STACK_WAIT:-${STACK_WAIT_DEFAULT}}
STACK_INITIATE=${STACK_INITIATE:-${STACK_INITIATE_DEFAULT}}
STACK_MONITOR=${STACK_MONITOR:-${STACK_MONITOR_DEFAULT}}


# Set up the context
. ${GENERATION_DIR}/setStackContext.sh

pushd ${CF_DIR} > /dev/null 2>&1

if [[ ! -f "$TEMPLATE" ]]; then
    echo -e "\n\"${TEMPLATE}\" not found. Are we in the correct place in the directory tree?" >&2
    usage
fi

# Assume all good
RESULT=0

if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
        delete)
            aws --region ${REGION} cloudformation delete-stack --stack-name $STACK_NAME 2>/dev/null

            # For delete, we don't check result as stack may not exist
            ;;

        update)
            # Compress the template to avoid aws cli size limitations
            cat $TEMPLATE | jq -c '.' > stripped_${TEMPLATE}
        
            # Check if stack needs to be created
            aws --region ${REGION} cloudformation describe-stacks --stack-name $STACK_NAME > $STACK 2>/dev/null
            RESULT=$?
            if [[ "$RESULT" -ne 0 ]]; then
                STACK_OPERATION="create"
            fi

            # Initiate the required operation
            aws --region ${REGION} cloudformation ${STACK_OPERATION,,}-stack --stack-name $STACK_NAME --template-body file://stripped_${TEMPLATE} --capabilities CAPABILITY_IAM

            # Check result of operation
            RESULT=$?
            if [[ "$RESULT" -ne 0 ]]; then exit; fi
            ;;

        *)
            echo -e "\n\"${STACK_OPERATION}\" is not one of the known stack operations." >&2
            usage
            ;;
    esac
fi

if [[ "${STACK_MONITOR}" = "true" ]]; then
    while true; do
        aws --region ${REGION} cloudformation describe-stacks --stack-name $STACK_NAME > $STACK 2>/dev/null
        if [[ ("${STACK_OPERATION}" == "delete") && ("$?" -eq 255) ]]; then
            # Assume stack doesn't exist
            RESULT=0
            break
        fi
        grep "StackStatus" $STACK > STATUS.txt
        cat STATUS.txt
        grep "${STACK_OPERATION^^}_COMPLETE" STATUS.txt >/dev/null 2>&1
        RESULT=$?
        if [[ "$RESULT" -eq 0 ]]; then break;fi
        grep "${STACK_OPERATION^^}_IN_PROGRESS" STATUS.txt  >/dev/null 2>&1
        RESULT=$?
        if [[ "$RESULT" -ne 0 ]]; then break;fi
        sleep ${STACK_WAIT}
    done
fi

if [[ ("${STACK_OPERATION}" == "delete") && ("${RESULT}" -eq 0) ]]; then
    rm -f $STACK
fi
