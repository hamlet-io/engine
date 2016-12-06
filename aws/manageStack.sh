#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

STACK_INITIATE_DEFAULT="true"
STACK_MONITOR_DEFAULT="true"
STACK_OPERATION_DEFAULT="update"
STACK_WAIT_DEFAULT=30
function usage() {
    echo -e "\nManage a CloudFormation stack"
    echo -e "\nUsage: $(basename $0) -t TYPE -s SLICE -i -m -w STACK_WAIT -r REGION -d\n"
    echo -e "\nwhere\n"
    echo -e "(o) -d (STACK_OPERATION=delete) to delete the stack"
    echo -e "    -h shows this text"
    echo -e "(o) -i (STACK_MONITOR=false) initiates but does not monitor the stack operation"
    echo -e "(o) -m (STACK_INITIATE=false) monitors but does not initiate the stack operation"
    echo -e "(o) -r REGION is the AWS region identifier for the region in which the stack should be managed"
    echo -e "(m) -s SLICE is the slice used to determine the stack template"
    echo -e "(m) -t TYPE is the stack type - \"account\", \"product\", \"segment\", \"solution\" or \"application\""
    echo -e "(o) -w STACK_WAIT is the interval between checking the progress of the stack operation"
    echo -e "\nDEFAULTS:\n"
    echo -e "STACK_INITIATE = ${STACK_INITIATE_DEFAULT}"
    echo -e "STACK_MONITOR = ${STACK_MONITOR_DEFAULT}"
    echo -e "STACK_OPERATION = ${STACK_OPERATION_DEFAULT}"
    echo -e "STACK_WAIT = ${STACK_WAIT_DEFAULT} seconds"
    echo -e "\nNOTES:\n"
    echo -e "1. You must be in the correct directory corresponding to the requested stack type"
    echo -e "2. REGION is only relevant for the \"product\" type, where multiple product stacks are necessary"
    echo -e "   if the product uses resources in multiple regions"  
    echo -e "3. \"segment\" is now used in preference to \"container\" to avoid confusion with docker"
    echo -e "4. If stack doesn't exist in AWS, the update operation will create the stack"
    echo -e ""
    exit
}

# Parse options
while getopts ":dhimr:s:t:w:" opt; do
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
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
    echo -e "\n\"${TEMPLATE}\" not found. Are we in the correct place in the directory tree?"
    usage
fi

# Assume all good
RESULT=0

if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
        delete)
            aws --region ${REGION} cloudformation delete-stack --stack-name $STACKNAME 2>/dev/null

            # For delete, we don't check result as stack may not exist
            ;;

        update)
            # Compress the template to avoid aws cli size limitations
            cat $TEMPLATE | jq -c '.' > stripped_${TEMPLATE}
        
            # Check if stack needs to be created
            aws --region ${REGION} cloudformation describe-stacks --stack-name $STACKNAME > $STACK 2>/dev/null
            RESULT=$?
            if [[ "$RESULT" -ne 0 ]]; then
                STACK_OPERATION="create"
            fi

            # Initiate the required operation
            aws --region ${REGION} cloudformation ${STACK_OPERATION,,}-stack --stack-name $STACKNAME --template-body file://stripped_${TEMPLATE} --capabilities CAPABILITY_IAM

            # Check result of operation
            RESULT=$?
            if [[ "$RESULT" -ne 0 ]]; then exit; fi
            ;;

        *)
            echo -e "\n\"${STACK_OPERATION}\" is not one of the known stack operations."
            usage
            ;;
    esac
fi

if [[ "${STACK_MONITOR}" = "true" ]]; then
    while true; do
        aws --region ${REGION} cloudformation describe-stacks --stack-name $STACKNAME > $STACK 2>/dev/null
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
