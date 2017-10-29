#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
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

function options() {
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

  [[ ! -f "${CF_DIR}/${TEMPLATE}" ]] && \
    fatalLocation "\"${TEMPLATE}\" not found." && return 1
  
  return 0
}

function main() {

  options "$@" || return $?

  pushd ${CF_DIR} > /dev/null 2>&1

  stack_status_file="./temp_stack_status"
  
  # Run the prologue script if present
  [[ -s "${PROLOGUE}" ]] && { . "${PROLOGUE}" || return $?; }

  # Update any file base configuration
  # Do this before stack in case it needs any of the files
  # to be present in the bucket
  if [[ "${LEVEL}" == "application" ]]; then
    case ${STACK_OPERATION} in
      delete)
        deleteCMDBFilesFromOperationsBucket "appsettings"
        deleteCMDBFilesFromOperationsBucket "credentials"
        ;;
  
      update)
        syncCMDBFilesToOperationsBucket "${SEGMENT_APPSETTINGS_DIR}" \
          "appsettings" "${DRYRUN}"
        syncCMDBFilesToOperationsBucket "${SEGMENT_CREDENTIALS_DIR}" \
          "credentials" "${DRYRUN}"
        if [[ -f "${CONFIG}" ]]; then
          local files=("${CONFIG}")
          syncFilesToBucket "${REGION}" "$(getOperationsBucket)" \
            "${prefix}/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}/config" \
            "files" "${DRYRUN}"
        fi
        ;;
    esac
  fi
  
  if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
      delete)
        [[ -n "${DRYRUN}" ]] && \
          fatal "Dryrun not applicable when deleting a stack" && return 1

        operation_to_check="DELETE"

        aws --region ${REGION} cloudformation delete-stack --stack-name $STACK_NAME 2>/dev/null
  
        # For delete, we don't check result as stack may not exist
        ;;
  
      update)
        # Compress the template to minimise the impact of aws cli size limitations
        jq -c '.' < ${TEMPLATE} > stripped_${TEMPLATE}

        operation_to_check="CREATE|UPDATE"

        # Check if stack needs to be created
        aws --region ${REGION} cloudformation describe-stacks \
            --stack-name $STACK_NAME > $STACK 2>/dev/null ||
          STACK_OPERATION="create"
  
        [[ (-n "${DRYRUN}") && ("${STACK_OPERATION}" == "create") ]] &&
            fatal "Dryrun not applicable when creating a stack" && return 1
  
        # Initiate the required operation
        if [[ -n "${DRYRUN}" ]]; then
  
          # Force monitoring to wait for change set to be complete
          STACK_OPERATION="create"
          STACK_MONITOR="true"
  
          # Change set naming
          CHANGE_SET_NAME="cs$(date +'%s')"
          STACK="temp_${CHANGE_SET_NAME}_${STACK}"
          aws --region ${REGION} cloudformation create-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" \
              --template-body file://stripped_${TEMPLATE} \
              --capabilities CAPABILITY_IAM ||
            return $?
        else
          aws --region ${REGION} cloudformation ${STACK_OPERATION,,}-stack --stack-name "${STACK_NAME}" --template-body file://stripped_${TEMPLATE} --capabilities CAPABILITY_IAM > "${stack_status_file}" 2>&1
          exit_status=$?
          case ${exit_status} in
            0) ;;
            255)
              grep -q "No updates are to be performed" < "${stack_status_file}" &&
                warning "No updates needed for stack ${STACK_NAME}. Treating as successful.\n" ||
                { cat "${stack_status_file}"; return ${exit_status}; }
              ;;
            *) return ${exit_status} ;;
          esac
        fi
        ;;
  
      *)
        fatal "\"${STACK_OPERATION}\" is not one of the known stack operations."; return 1
        ;;
    esac
  fi
  
  if [[ "${STACK_MONITOR}" = "true" ]]; then
    while true; do
  
      if [[ -n "${DRYRUN}" ]]; then
        status_attribute="Status"
        aws --region ${REGION} cloudformation describe-change-set --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" > "${STACK}" 2>/dev/null
        exit_status=$?
      else
        status_attribute="StackStatus"
        aws --region ${REGION} cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${STACK}" 2>/dev/null
        exit_status=$?
      fi
  
      [[ ("${STACK_OPERATION}" == "delete") && ("${exit_status}" -eq 255) ]] && break

      grep "${status_attribute}" "${STACK}" > "${stack_status_file}"
      cat "${stack_status_file}"

      egrep "(${operation_to_check})_COMPLETE\"" "${stack_status_file}" >/dev/null 2>&1 && break

      egrep "(${operation_to_check}).*_IN_PROGRESS\"" "${stack_status_file}"  >/dev/null 2>&1 || break

      sleep ${STACK_WAIT}
    done
  fi
  
  if [[ "${STACK_OPERATION}" == "delete" ]]; then
    if [[ ("${exit_status}" -eq 0) || !( -s "${STACK}" ) ]]; then
      rm -f "${STACK}"
    fi
  fi

  # Results of dryrun if required
  [[ -n "${DRYRUN}" ]] && cat "${STACK}"
  
  # Run the epilogue script if present
  [[ -s "${EPILOGUE}" ]] && { . "${PROLOGUE}" || return $?; }

  return 0
}

main "$@"
