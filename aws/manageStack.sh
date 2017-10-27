#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
STACK_INITIATE_DEFAULT="true"
STACK_MONITOR_DEFAULT="true"
STACK_OPERATION_DEFAULT="update"
STACK_WAIT_DEFAULT=30

function usage() {
    cat <<EOF

Manage a CloudFormation stack

Usage: $(basename $0) -l LEVEL -u DEPLOYMENT_UNIT -i -m -w STACK_WAIT -r REGION -n STACK_NAME -y -d

where

(o) -d (STACK_OPERATION=delete) to delete the stack
    -h                          shows this text
(o) -i (STACK_MONITOR=false)    initiates but does not monitor the stack operation
(m) -l LEVEL                    is the stack level - "account", "product", "segment", "solution", "application" or "multiple"
(o) -m (STACK_INITIATE=false)   monitors but does not initiate the stack operation
(o) -n STACK_NAME               to override standard stack naming
(o) -r REGION                   is the AWS region identifier for the region in which the stack should be managed
(d) -s DEPLOYMENT_UNIT          same as -u
(d) -t LEVEL                    same as -l
(m) -u DEPLOYMENT_UNIT          is the deployment unit used to determine the stack template
(o) -w STACK_WAIT               is the interval between checking the progress of the stack operation
(o) -y (DRYRUN=--dryrun)        for a dryrun - show what will happen without actually updating the stack
(o) -z DEPLOYMENT_UNIT_SUBSET  is the subset of the deployment unit required 

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

STACK_INITIATE  = ${STACK_INITIATE_DEFAULT}
STACK_MONITOR   = ${STACK_MONITOR_DEFAULT}
STACK_OPERATION = ${STACK_OPERATION_DEFAULT}
STACK_WAIT      = ${STACK_WAIT_DEFAULT} seconds

NOTES:
1. You must be in the correct directory corresponding to the requested stack level
2. REGION is only relevant for the "product" level, where multiple product stacks are necessary
   if the product uses resources in multiple regions
3. "segment" is now used in preference to "container" to avoid confusion with docker
4. If stack doesn't exist in AWS, the update operation will create the stack
5. Overriding the stack name is not recommended except where legacy naming has to be maintained
6. A dryrun creates a change set, then displays it. It only applies when
   the STACK_OPERATION=update

EOF
}

function set_context() {
  # Parse options
  while getopts ":dhil:mn:r:s:t:u:w:yz:" option; do
    case "${option}" in
      d) STACK_OPERATION=delete ;;
      h) usage; return 1 ;;
      i) STACK_MONITOR=false ;;
      l) LEVEL="${OPTARG}" ;;
      m) STACK_INITIATE=false ;;
      n) STACK_NAME="${OPTARG}" ;;
      r) REGION="${OPTARG}" ;;
      s) DEPLOYMENT_UNIT="${OPTARG}" ;;
      t) LEVEL="${OPTARG}" ;;
      u) DEPLOYMENT_UNIT="${OPTARG}" ;;
      w) STACK_WAIT="${OPTARG}" ;;
      y) DRYRUN="--dryrun" ;;
      z) DEPLOYMENT_UNIT_SUBSET="${OPTARG}" ;;
      \?) fatalOption; return 1 ;;
      :) fatalOptionArgument; return 1  ;;
    esac
  done
  
  # Apply defaults
  STACK_OPERATION=${STACK_OPERATION:-${STACK_OPERATION_DEFAULT}}
  STACK_WAIT=${STACK_WAIT:-${STACK_WAIT_DEFAULT}}
  STACK_INITIATE=${STACK_INITIATE:-${STACK_INITIATE_DEFAULT}}
  STACK_MONITOR=${STACK_MONITOR:-${STACK_MONITOR_DEFAULT}}
 
  # Set up the context
  . "${GENERATION_DIR}/setStackContext.sh"

  [[ ! -f "${CF_DIR}/${TEMPLATE}" ]] && fatalLocation "\"${TEMPLATE}\" not found." && return 1
  
  return 0
}

function main() {

  set_context "$@" || return 1

  pushd ${CF_DIR} > /dev/null 2>&1

  # Assume all good
  RESULT=0
  STACK_STATUS_FILE="./temp_stack_status"

  # Update any file base configuration
  # Do this before stack in case it needs any of the files
  # to be present in the bucket e.g. swagger file
  if [[ "${LEVEL}" == "application" ]]; then
    case ${STACK_OPERATION} in
      delete)
        deleteCMDBFilesFromOperationsBucket "appsettings"
        deleteCMDBFilesFromOperationsBucket "credentials"
        ;;
  
      update)
        syncCMDBFilesToOperationsBucket "${SEGMENT_APPSETTINGS_DIR}" "appsettings" ${DRYRUN}
        syncCMDBFilesToOperationsBucket "${SEGMENT_CREDENTIALS_DIR}" "credentials" ${DRYRUN}
        ;;
    esac
  fi
  
  if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
      delete)
        [[ -n "${DRYRUN}" ]] && fatal "Dryrun not applicable when deleting a stack"

        OPERATION_TO_CHECK="DELETE"

        aws --region ${REGION} cloudformation delete-stack --stack-name $STACK_NAME 2>/dev/null
  
        # For delete, we don't check result as stack may not exist
        ;;
  
      update)
        # Compress the template to avoid aws cli size limitations
        jq -c '.' < ${TEMPLATE} > stripped_${TEMPLATE}

        OPERATION_TO_CHECK="CREATE|UPDATE"

        # Check if stack needs to be created
        aws --region ${REGION} cloudformation describe-stacks --stack-name $STACK_NAME > $STACK 2>/dev/null
        RESULT=$?
        if [[ "$RESULT" -ne 0 ]]; then
            STACK_OPERATION="create"
        fi
  
        [[ (-n "${DRYRUN}") && ("${STACK_OPERATION}" == "create") ]] &&
            fatal "Dryrun not applicable when creating a stack"
  
        # Initiate the required operation
        if [[ -n "${DRYRUN}" ]]; then
  
          # Force monitoring to wait for change set to be complete
          STACK_OPERATION="create"
          STACK_MONITOR="true"
  
          # Change set naming
          CHANGE_SET_NAME="cs$(date +'%s')"
          STACK="temp_${CHANGE_SET_NAME}_${STACK}"
          aws --region ${REGION} cloudformation create-change-set --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" --template-body file://stripped_${TEMPLATE} --capabilities CAPABILITY_IAM
          RESULT=$? && [[ "$RESULT" -ne 0 ]] && exit
        else
          aws --region ${REGION} cloudformation ${STACK_OPERATION,,}-stack --stack-name "${STACK_NAME}" --template-body file://stripped_${TEMPLATE} --capabilities CAPABILITY_IAM > "${STACK_STATUS_FILE}" 2>&1
          RESULT=$?
          case "${RESULT}" in
            0) ;;
            255)
              grep -q "No updates are to be performed" < "${STACK_STATUS_FILE}" &&
                warning "No updates needed for stack ${STACK_NAME}. Treating as successful.\n" ||
                (cat "${STACK_STATUS_FILE}"; exit)
              ;;
            *) exit ;;
          esac
        fi
        ;;
  
      *)
        fatal "\"${STACK_OPERATION}\" is not one of the known stack operations."
        ;;
    esac
  fi
  
  if [[ "${STACK_MONITOR}" = "true" ]]; then
    while true; do
  
      if [[ -n "${DRYRUN}" ]]; then
        STATUS_ATTRIBUTE="Status"
        aws --region ${REGION} cloudformation describe-change-set --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" > "${STACK}" 2>/dev/null
        RESULT=$?
      else
        STATUS_ATTRIBUTE="StackStatus"
        aws --region ${REGION} cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${STACK}" 2>/dev/null
        RESULT=$?
      fi
  
      if [[ ("${STACK_OPERATION}" == "delete") && ("${RESULT}" -eq 255) ]]; then
        # Assume stack doesn't exist
        RESULT=0
        break
      fi

      grep "${STATUS_ATTRIBUTE}" "${STACK}" > "${STACK_STATUS_FILE}"
      cat "${STACK_STATUS_FILE}"

      egrep "(${OPERATION_TO_CHECK})_COMPLETE\"" "${STACK_STATUS_FILE}" >/dev/null 2>&1
      RESULT=$? && [[ "${RESULT}" -eq 0 ]] && break

      egrep "(${OPERATION_TO_CHECK}).*_IN_PROGRESS\"" "${STACK_STATUS_FILE}"  >/dev/null 2>&1
      RESULT=$? && [[ "${RESULT}" -ne 0 ]] && break

      sleep ${STACK_WAIT}
    done
  fi
  
  if [[ "${STACK_OPERATION}" == "delete" ]]; then
    if [[ ("${RESULT}" -eq 0) || !( -s "${STACK}" ) ]]; then
      rm -f "${STACK}"
    fi
  fi
  if [[ -n "${DRYRUN}" ]]; then
    cat "${STACK}"
  fi
}

main "$@"

