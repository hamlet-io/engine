#!/usr/bin/env bash

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
  info "Preparing the context..."
  . "${GENERATION_DIR}/setStackContext.sh"

  return 0
}

function copy_contentnode_file() { 
  local files="$1"; shift
  local engine="$1"; shift
  local path="$1"; shift
  local prefix="$1"; shift
  local nodepath="$1"; shift
  local branch="$1"; 

  local contentnodedir="${tmp_dir}/contentnode"
  local contenthubdir="${tmp_dir}/contenthub"
  local hubpath="${contenthubdir}/${prefix}${nodepath}"

  # Copy files into repo 
  if [[ -f "${files}" ]]; then 

    case ${engine} in 
      github) 

        # Copy files locally so we can synch with git
        for file in "${files[@]}" ; do
          if [[ -f "${file}" ]]; then
            case "$(fileExtension "${file}")" in
              zip)
                unzip "${file}" -d "${contentnodedir}" || return $?
                ;;
              *)
                cp "${file}" "${contentnodedir}" || return $?
                ;;
            esac
          fi
        done

        # Clone the Repo
        local host="github.com"
        clone_git_repo "${engine}" "${host}" "${path}" "${branch}" "${contenthubdir}" || return $?

        case ${STACK_OPERATION} in 

          delete) 
            if [[ -n "${hubpath}" ]]; then
              rm -rf "${hubpath}" || return $?
            else 
              fatal "Hub path not defined" 
              return 1
            fi
          ;;
          
          create|update)
            if [[ -n "${hubpath}" ]]; then
              rm -rf "${hubpath}" || return $?
              cp -R "${contentnodedir}/" "${hubpath}" || return $?
            else
              fatal "Hub path not defined"
              return 1
            fi
          ;;
        esac

        # Commit Repo
        cd "${contenthubdir}"
        push_git_repo "${host}/${path}" "${branch}" "origin" \
            "ContentNodeDeployment-${PRODUCT}-${SEGMENT}-${DEPLOYMENT_UNIT}" \
            "${GIT_USER}" "${GIT_EMAIL}" || return $?

      ;;
    esac 
  else 
    info "No files found to copy" 
  fi

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
  local apiHost="$1"; shift
  local scheme="$1"; shift
  local basePath="$1"; shift
  local version="$1"; shift
  local description="$1"; shift
  local apiDocs="$1"; shift
  local apiDocDir="${tmp_dir}/apidocs"
  local swaggerJson="${apiDocDir}/swagger.json"

  mkdir -p "${apiDocDir}"

  if [[ "${apiDocs##*.}" == "zip" ]]; then
      unzip -o "${apiDocs}" -d "${apiDocDir}"
      RESULT=$?
      [[ $RESULT -ne 0 ]] &&
          fatal "Unable to unzip ${apiDocs}" && return 1
  fi

  if [[ -f ${swaggerJson} ]]; then  

    if [[ -n "${basePath}" ]]; then 
        jq -r --arg basePath "${basePath}" '.basePath = $basePath' < ${swaggerJson} > "${swaggerJson}_host"
        mv "${swaggerJson}_host" ${swaggerJson}
    fi

    if [[ -n "${scheme}" ]]; then 
        jq -r --arg scheme "${scheme}" '.schemes = ( $scheme / "," )' < ${swaggerJson} > "${swaggerJson}_host"
        mv "${swaggerJson}_host" ${swaggerJson}
    fi

    if [[ -n "${apiHost}" ]]; then 
        jq -r --arg apiHost "${apiHost}" '.host = $apiHost' < ${swaggerJson} > "${swaggerJson}_host"
        mv "${swaggerJson}_host" ${swaggerJson}
    fi

    if [[ -n "${version}" ]]; then 
        jq -r --arg version "${version}" '.info.version = $version' < ${swaggerJson} > "${swaggerJson}_host"
        mv "${swaggerJson}_host" ${swaggerJson}
    fi

    if [[ -n "${description}" ]]; then
        jq -r --arg description "${description}" '.info.description = .info.description + " \n" + $description' < ${swaggerJson} > "${swaggerJson}_host"
        mv "${swaggerJson}_host" ${swaggerJson}
    fi
  fi

  if [[ "${apiDocs##*.}" == "zip" ]]; then
    rm "${apiDocs}"
    zip -rj "${apiDocs}" "${apiDocDir}"
  fi

  return 0
}

function wait_for_stack_execution() { 
  
  info "Watching stack execution..."

  local stack_status_file="${tmp_dir}/stack_status"

  while true; do

    case ${STACK_OPERATION} in 
      update)
        status_attribute="StackStatus"
        operation_to_check="UPDATE"
        aws --region ${REGION} cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${STACK}"
        exit_status=$?
      ;;

      create)
        status_attribute="StackStatus"
        operation_to_check="CREATE"
        aws --region ${REGION} cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${STACK}"
        exit_status=$?
      ;;

      delete) 
        status_attribute="StackStatus"
        operation_to_check="DELETE"
        aws --region ${REGION} cloudformation describe-stacks --stack-name "${STACK_NAME}" > "${STACK}" 2>/dev/null
        exit_status=$?
      ;;

      *)
        fatal "\"${STACK_OPERATION}\" is not one of the known stack operations."; return 1
      ;;
    esac

    [[ ("${STACK_OPERATION}" == "delete") && ("${exit_status}" -eq 255) ]] &&
      { exit_status=0; break; }

    if [[ "${STACK_MONITOR}" = "true" ]]; then 

      # Check the latest status
      grep "${status_attribute}" "${STACK}" > "${stack_status_file}"
      cat "${stack_status_file}"

      # Watch for roll backs 
      egrep "*ROLLBACK_COMPLETE\"" "${stack_status_file}" >/dev/null 2>&1 && \
        { warning "Stack ${STACK_NAME} could not complete and a rollback was performed"; exit_status=1; break;}
        
      # Watch for failures
      egrep "*FAILED\"" "${stack_status_file}" >/dev/null 2>&1 && \
        { fatal "Stack ${STACK_NAME} failed, fix stack before retrying"; exit_status=255; break;}

      # Finished if complete
      egrep "(${operation_to_check})_COMPLETE\"" "${stack_status_file}" >/dev/null 2>&1 && \
        { [[ -f "${potential_change_file}" ]] && cp "${potential_change_file}" "${CHANGE}"; break; }

      # Abort if not still in progress
      egrep "(${operation_to_check}).*_IN_PROGRESS\"" "${stack_status_file}"  >/dev/null 2>&1 ||
        { exit_status=$?; break; }

      # All good, wait a while longer
      sleep ${STACK_WAIT}
    else 
      break
    fi

    # Check to see if the work has already been completed
    case ${exit_status} in
      0) ;;
      255)
        grep -q "No updates are to be performed" < "${stack_status_file}" &&
          warning "No updates needed for stack ${STACK_NAME}. Treating as successful.\n"; break ||
          { cat "${stack_status_file}"; return ${exit_status}; }
      ;;
      *) 
      return ${exit_status} ;;
    esac

  done
}

function process_stack() {

  local stripped_template_file="${tmp_dir}/stripped_template"

  local exit_status=0
  
  if [[ "${STACK_INITIATE}" = "true" ]]; then
    case ${STACK_OPERATION} in
      delete)
        [[ -n "${DRYRUN}" ]] && \
          fatal "Dryrun not applicable when deleting a stack" && return 1

        info "Deleting the "${STACK_NAME}" stack..."
        aws --region ${REGION} cloudformation delete-stack --stack-name "${STACK_NAME}" 2>/dev/null
        # For delete, we don't check result as stack may not exist

        wait_for_stack_execution
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

        if [[ "${STACK_OPERATION}" == "update" ]]; then 

          info "Update operation - submitting change set to determine update action..."
          INITIAL_CHANGE_SET_NAME="initial-$(date +'%s')"
          aws --region ${REGION} cloudformation create-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${INITIAL_CHANGE_SET_NAME}" \
              --template-body "file://${stripped_template_file}" \
              --capabilities CAPABILITY_IAM > /dev/null || return $?

          #Wait for change set to be processed 
          aws --region ${REGION} cloudformation wait change-set-create-complete \
              --stack-name "${STACK_NAME}" --change-set-name "${INITIAL_CHANGE_SET_NAME}" &>/dev/null            
        
          if [[ -n "${DRYRUN}" ]]; then 

            info "Dry run results"

            # Return the change set results
            aws --region ${REGION} cloudformation describe-change-set \
              --stack-name "${STACK_NAME}" --change-set-name "${INITIAL_CHANGE_SET_NAME}" && return $?

          else

            # Check ChangeSet for results 
            aws --region ${REGION} cloudformation describe-change-set \
                --stack-name "${STACK_NAME}" --change-set-name "${INITIAL_CHANGE_SET_NAME}" > "${potential_change_file}" 2>/dev/null || return $?
            
            if [[ $( jq  -r '.Status == "FAILED"' < "${potential_change_file}" ) == "true" ]]; then

              cat "${potential_change_file}" | jq -r '.StatusReason' | grep -q "The submitted information didn't contain changes." &&
                warning "No updates needed for stack ${STACK_NAME}. Treating as successful.\n" ||
                cat "${potential_change_file}"; return ${exit_status}; 

            else 

              replacement=$( cat "${potential_change_file}" | jq '[.Changes[].ResourceChange.Replacement] | contains(["True"])' )
              REPLACE_TEMPLATES=$( for i in ${ALTERNATIVE_TEMPLATES} ; do echo $i | awk '/-replace[0-9]-template\.json$/'  ; done  | sort  )

              if [[ "${replacement}" == "true" && -n "${REPLACE_TEMPLATES}" ]]; then

                  info "Replacement update - Using replacement templates"

                  for REPLACE_TEMPLATE in ${REPLACE_TEMPLATES}; do 
                    info "Executing replace template : $(fileBase "${REPLACE_TEMPLATE}")..."

                    jq -c '.' < ${REPLACE_TEMPLATE} > "${stripped_template_file}"

                    CHANGE_SET_NAME="$( fileBase "${REPLACE_TEMPLATE}" )-$(date +'%s')"
                    aws --region ${REGION} cloudformation create-change-set \
                        --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" \
                        --template-body "file://${stripped_template_file}" \
                        --capabilities CAPABILITY_IAM  || return $?

                    #Wait for change set to be processed 
                    aws --region ${REGION} cloudformation wait change-set-create-complete \
                        --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" &>/dev/null  

                    # Check ChangeSet for results 
                    aws --region ${REGION} cloudformation describe-change-set \
                        --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}"  > "${potential_change_file}" 2>/dev/null || return $?
                    
                    if [[ $( jq  -r '.Status == "FAILED"' < "${potential_change_file}" ) == "true" ]]; then

                      cat "${potential_change_file}" | jq -r '.StatusReason' | grep -q "The submitted information didn't contain changes." &&
                        warning "No further updates needed for stack ${STACK_NAME}. Treating as successful.\n" ||
                        cat "${potential_change_file}"; return ${exit_status}; 
                    
                    else

                      # Running 
                      aws --region ${REGION} cloudformation execute-change-set \
                          --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" > /dev/null || return $?

                      wait_for_stack_execution
                    
                    fi
                  done
              
              else

                info "Standard update - executing change set..."
                # Execute a normal change 
                CHANGE_SET_NAME="${INITIAL_CHANGE_SET_NAME}"
                aws --region ${REGION} cloudformation execute-change-set \
                      --stack-name "${STACK_NAME}" --change-set-name "${CHANGE_SET_NAME}" > /dev/null || return $?

                wait_for_stack_execution

              fi
            fi
          fi

        else 

            # Create Action 
            info "Creating the "${STACK_NAME}" stack..."
            aws --region ${REGION} cloudformation create-stack --stack-name "${STACK_NAME}" --template-body "file://${stripped_template_file}" --capabilities CAPABILITY_IAM > /dev/null || return $?

            wait_for_stack_execution

        fi
        ;;
  
      *)
        fatal "\"${STACK_OPERATION}\" is not one of the known stack operations."; return 1
        ;;
    esac
  fi
  

  # Clean up the stack if required
  if [[ "${STACK_OPERATION}" == "delete" ]]; then
    if [[ ("${exit_status}" -eq 0) || !( -s "${STACK}" ) ]]; then
      rm -f "${STACK}"
    fi
    if [[ ("${exit_status}" -eq 0) || !( -s "${CHANGE}" ) ]]; then
      rm -f "${CHANGE}"
    fi
  fi

  return "${exit_status}"
}

function main() {

  options "$@" || return $?

  pushTempDir "manage_stack_XXXX"
  tmp_dir="$(getTopTempDir)"
  tmpdir="${tmp_dir}"
  potential_change_file="${tmp_dir}/potential_changes"

  pushd ${CF_DIR} > /dev/null 2>&1

  # Run the prologue script if present
  # Refresh the stack outputs in case something from pseudo stack is needed
  [[ -s "${PROLOGUE}" ]] && \
    { info "Processing prologue script ..." && . "${PROLOGUE}" && assemble_composite_stack_outputs || return $?; }

  process_stack_status=0
  # Process the stack
  if [[ -f "${TEMPLATE}" ]]; then 
     process_stack || process_stack_status=$?
  fi

  # Check to see if the work has already been completed
  case ${process_stack_status} in
    0) 
      info "${STACK_OPERATION} completed for ${STACK_NAME}"
    ;;
    *) 
      fatal "Change set for ${STACK_NAME} did not complete"
      return ${process_stack_status} 
    ;;
  esac
  
  # Run the epilogue script if present
  # Refresh the stack outputs in case something from the just created stack is needed
  # by the epilogue script
  [[ -s "${EPILOGUE}" ]] && \
  { info "Processing epilogue script ..." && assemble_composite_stack_outputs && . "${EPILOGUE}" || return $?; }

  return 0
}

main "$@"
