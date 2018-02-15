#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
STACK_INITIATE_DEFAULT="true"
STACK_MONITOR_DEFAULT="true"
STACK_OPERATION_DEFAULT="update"
STACK_WAIT_DEFAULT=30
STACK_ALTERNATIVES_DEFAULT="false"

function usage() {
  cat <<EOF

Manage a CloudFormation stack

Usage: $(basename $0) -l LEVEL -u DEPLOYMENT_UNIT -i -m -w STACK_WAIT -r REGION -n STACK_NAME -y -d

where

(o) -a (STACK_ALTERNATIVES=true) Use alternative change sets is available
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
  while getopts ":adhil:mn:r:s:t:u:w:yz:" option; do
    case "${option}" in
      a) STACK_ALTERNATIVES=true ;;
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
  STACK_ALTERNATIVES=${STACK_ALTERNATIVES:-${STACK_ALTERNATIVES_DEFAULT}}

  # Set up the context
  info "Preparing the context..."
  . "${GENERATION_DIR}/setStackContext.sh"

  return 0
}

function copy_cmdb_files() {
  if [[ "${LEVEL}" == "application" ]]; then
    case ${STACK_OPERATION} in
      delete)
        deleteCMDBFilesFromOperationsBucket "appsettings" || return $?
        deleteCMDBFilesFromOperationsBucket "credentials" || return $?
        ;;
  
      create|update)
        syncCMDBFilesToOperationsBucket "${SEGMENT_APPSETTINGS_DIR}" \
          "appsettings" ${DRYRUN} || return $?
        syncCMDBFilesToOperationsBucket "${SEGMENT_CREDENTIALS_DIR}" \
          "credentials" ${DRYRUN} || return $?
        ;;
    esac
  fi

  return 0
}

function copy_config_file() {  

  local files=()

  case ${STACK_OPERATION} in
    delete)
      # Nothing to do as synch will use an empty directory
      ;;
    create|update)
      # Change filename to config.json
      cp "$1" "${tmpdir}/config.json"
      files+=("${tmpdir}/config.json")
      ;;
  esac

  # Update S3
  syncFilesToBucket "${REGION}" "$(getOperationsBucket)" \
    "appsettings/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}/config" \
    "files" ${DRYRUN} --delete

  return 0
}

function copy_spa_file() {

  local files=()

  case ${STACK_OPERATION} in
    delete)
      # Nothing to do as synch will use an empty directory
      ;;
    create|update)
      files+=("$@")
      ;;
  esac

  syncFilesToBucket "${REGION}" "$(getOperationsBucket)" \
    "appsettings/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}/spa" \
    "files" ${DRYRUN} --delete

  return 0
}

function copy_apidoc_file() { 
  
  local apidocbucket="$1"; shift

  local files=()

  case ${STACK_OPERATION} in
    delete)
      #Nothing to do as the sync will use an empty directory
      ;;
    create|update)
      files+=("$@")
      ;;
  esac

  syncFilesToBucket "${REGION}" "${apidocbucket}" \
  "" \
  "files" ${DRYRUN} --delete

  return 0
}

function add_host_to_apidoc() { 
  # adds the API Host endpoint to the swagger spec
  local apihost="$1"; shift
  local apidocs="$1"
  local swaggerjson="${tmpdir}/swagger.json"

  if [[ "${apidocs##*.}" == "zip" ]]; then
      unzip -o "${apidocs}" -d "${tmpdir}"
      RESULT=$?
      [[ $RESULT -ne 0 ]] &&
          fatal "Unable to unzip ${apidocs}" && exit
  fi

  if [[ -f ${swaggerjson} ]]; then 
     jq --arg apihost $apihost '. + { host: $apihost} ' < ${swaggerjson} > "${swaggerjson}_host"
    mv "${swaggerjson}_host" ${swaggerjson}
  fi

  if [[ "${apidocs##*.}" == "zip" ]]; then
    rm "${apidocs}"
    zip -rj "${apidocs}" "${tmpdir}"
  fi

  return 0
}

function process_stack() {

  local stack_status_file="${tmpdir}/stack_status"
  local stripped_template_file="${tmpdir}/stripped_template"
  local operation_to_check=
  local exit_status=0
  local status_attribute=

  case ${STACK_OPERATION} in
    delete) operation_to_check="DELETE" ;;
    update) operation_to_check="CREATE|UPDATE" ;;
  esac
  
  if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
      delete)
        [[ -n "${DRYRUN}" ]] && \
          fatal "Dryrun not applicable when deleting a stack" && return 1

        info "Deleting the "${STACK_NAME}" stack..."
        aws --region ${REGION} cloudformation delete-stack --stack-name "${STACK_NAME}" 2>/dev/null
  
        # For delete, we don't check result as stack may not exist
        ;;
  
      update)
        # Compress the template to minimise the impact of aws cli size limitations
        jq -c '.' < ${TEMPLATE} > "${stripped_template_file}"

        # Check if stack needs to be created
        info "Check if the "${STACK_NAME}" stack is already present..."
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
          STACK="${tmpdir}/${CHANGE_SET_NAME}_${STACK}"
          aws --region ${REGION} cloudformation create-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" \
              --template-body "file://${stripped_template_file}" \
              --capabilities CAPABILITY_IAM ||
            return $?
        
        elif [[ ${STACK_ALTERNATIVES} == true && "${STACK_OPERATION}" == "update" ]]; then

          STACK="${tmpdir}/${CHANGE_SET_NAME}_${STACK}"

          # Create initial Change Set
          CHANGE_SET_NAME="primary$(date +'%s')"
          aws --region ${REGION} cloudformation create-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" \
              --template-body "file://${stripped_template_file}" \
              --capabilities CAPABILITY_IAM &>/dev/null || return $?
          
          #Wait for change set to be processed 
          aws --region ${REGION} cloudformation wait change-set-create-complete \
              --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" &>/dev/null

          # Check ChangeSet for results 
          change_set_results=$(aws --region ${REGION} cloudformation describe-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" || return $?) 
          
          if [[ $( echo "${change_set_results}" | jq '.Status == "FAILED" ') -eq false ]]; then 

            replacement=$( echo "${change_set_results}" | jq '.Changes[].ResourceChange.Replacement | contains("True")' )

            info "ChangeSet Status: ${replacement} Changes: $(echo "${change_set_results}" | jq -r '.Changes[].ResourceChange.Replacement') "

            if [[ "${replacement}" == "true" ]]; then 
                for ALTERNATIVE_TEMPLATE in ${ALTERNATIVE_TEMPLATES}; do 
                  info "ALTERNATIVE TEMPLATE: ${ALTERNATIVE_TEMPLATE} Match: $(contains "$(fileName "${ALTERNATIVE_TEMPLATE}")" "*-replace-template.json")"
                  if contains "${ALTERNATIVE_TEMPLATE}" "*-replace-template.json"; then
                    info "Found replacement template will apply it as a change set template"

                    alternative_template_file = jq -c '.' < ${ALTERNATIVE_TEMPLATE} > "${stripped_template_file}"
                    
                    # Create Replace Change Set
                    alternative_set_name="replace$(date +'%s')"
                    aws --region ${REGION} cloudformation create-change-set \
                        --stack-name "${STACK_NAME}" --change-set-name "${alternative_set_name}" \
                        --template-body "file://${alternative_template_file}" \
                        --capabilities CAPABILITY_IAM &>/dev/null || return $?
                    
                    #Wait for change set to be processed 
                    aws --region ${REGION} cloudformation wait change-set-create-complete \
                        --stack-name "${STACK_NAME}" --change-set-name "${alternative_set_name}" &>/dev/null

                    # Check ChangeSet for results 
                    change_set_results=$(aws --region ${REGION} cloudformation describe-change-set \
                        --stack-name "${STACK_NAME}" --change-set-name "${alternative_set_name}" || return $?) 

                    if [[ $( echo "${change_set_results}" | jq '.Status == "FAILED" ') -eq false ]]; then 
                      aws --region ${REGION} cloudformation execute-change-set \
                          --stack-name "${STACK_NAME}" --change-set-name "${alternative_set_name}" &>/dev/null

                      #Wait for change set to be processed 
                      aws --region ${REGION} cloudformation wait stack-update-complete \
                        --stack-name "${STACK_NAME}"  &>/dev/null

                      # Check ChangeSet for results 
                      change_set_results=$(aws --region ${REGION} cloudformation describe-change-set \
                        --stack-name "${STACK_NAME}" --change-set-name "${alternative_set_name}" || return $?) 

                    fi

                  fi
                done
            fi
          fi
        else

          info "Creating/updating the "${STACK_NAME}" stack..."
          aws --region ${REGION} cloudformation ${STACK_OPERATION,,}-stack \
              --stack-name "${STACK_NAME}" --template-body "file://${stripped_template_file}" \
              --capabilities CAPABILITY_IAM > "${stack_status_file}" 2>&1
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
  
      [[ ("${STACK_OPERATION}" == "delete") && ("${exit_status}" -eq 255) ]] &&
        { exit_status=0; break; }

      # Check the latest status
      grep "${status_attribute}" "${STACK}" > "${stack_status_file}"
      cat "${stack_status_file}"

      # Finished if complete
      egrep "(${operation_to_check})_COMPLETE\"" "${stack_status_file}" >/dev/null 2>&1 && break

      # Abort if not still in progress
      egrep "(${operation_to_check}).*_IN_PROGRESS\"" "${stack_status_file}"  >/dev/null 2>&1 ||
        { exit_status=$?; break; }

      # All good, wait a while longer
      sleep ${STACK_WAIT}
    done
  fi

  # Clean up the stack if required
  if [[ "${STACK_OPERATION}" == "delete" ]]; then
    if [[ ("${exit_status}" -eq 0) || !( -s "${STACK}" ) ]]; then
      rm -f "${STACK}"
    fi
  fi

  # Results of dryrun if required
  [[ -n "${DRYRUN}" ]] && cat "${STACK}"

  return "${exit_status}"
}

function main() {

  options "$@" || return $?

  tmpdir="$(getTempDir "manage_stack_XXX")"

  pushd ${CF_DIR} > /dev/null 2>&1

  # Run the prologue script if present
  # Refresh the stack outputs in case something from pseudo stack is needed
  [[ -s "${PROLOGUE}" ]] && \
    { info "Processing prologue script ..." && . "${PROLOGUE}" && assemble_composite_stack_outputs || return $?; }

  # Update any file based configuration
  copy_cmdb_files || return $?
  
  # Update any config file
  [[ -f "${CONFIG}" ]] && \
    { info "Copying config file ..." && copy_config_file "${CONFIG}" || return $?; }

  # Process the stack
  [[ -f "${TEMPLATE}" ]] && { process_stack || return $?; }
  
  # Run the epilogue script if present
  # Refresh the stack outputs in case something from the just created stack is needed
  # by the epilogue script
  [[ -s "${EPILOGUE}" ]] && \
  { info "Processing epilogue script ..." && assemble_composite_stack_outputs && . "${EPILOGUE}" || return $?; }

  return 0
}

main "$@"
