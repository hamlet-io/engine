#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
DEPLOYMENT_INITIATE_DEFAULT="true"
DEPLOYMENT_MONITOR_DEFAULT="true"
DEPLOYMENT_OPERATION_DEFAULT="update"
DEPLOYMENT_WAIT_DEFAULT=30
DEPLOYMENT_SCOPE_DEFAULT="resourceGroup"

function usage() {
  cat <<EOF

  Manage an Azure Resource Manager (ARM) deployment

  Usage: $(basename $0) -l LEVEL -r REGION -s DEPLOYMENT_SCOPE -u DEPLOYMENT_UNIT -n DEPLOYMENT_NAME

  where

  (o) -d (DEPLOYMENT_OPERATION=delete)  to delete the deployment
      -h                                shows this text
  (o) -i (DEPLOYMENT_MONITOR=false)     initiates but does not monitor the deployment operation.
  (m) -l LEVEL                          is the deployment level - "account", "product", "segment", "solution", "application" or "multiple"
  (o) -m (DEPLOYMENT_INITIATE=false)    monitors but does not initiate the deployment operation.
  (o) -n DEPLOYMENT_NAME                to override the standard deployment naming.
  (o) -r REGION                         is the Azure location/region code for this deployment.
  (o) -s DEPLOYMENT_SCOPE               the deployment scope - "subscription" or "resourceGroup"
  (m) -u DEPLOYMENT_UNIT                is the deployment unit used to determine the deployment template.
  (o) -w DEPLOYMENT_WAIT                the interval between checking the progress of a stack operation.
  (o) -z DEPLOYMENT_UNIT_SUBSET         is the subset of the deployment unit required.

  (m) mandatory, (o) optional, (d) deprecated

  DEFAULTS:

  DEPLOYMENT_INITIATE  = ${DEPLOYMENT_INITIATE_DEFAULT}
  DEPLOYMENT_MONITOR   = ${DEPLOYMENT_MONITOR_DEFAULT}
  DEPLOYMENT_OPERATION = ${DEPLOYMENT_OPERATION_DEFAULT}
  DEPLOYMENT_WAIT      = ${DEPLOYMENT_WAIT_DEFAULT} seconds
  DEPLOYMENT_SCOPE     = ${DEPLOYMENT_SCOPE_DEFAULT}

EOF
}

function options() {
  # Parse options
  while getopts ":dhil:mn:r:s:u:w:z:" option; do
    case "${option}" in
      d) DEPLOYMENT_OPERATION=delete ;;
      h) usage; return 1 ;;
      i) DEPLOYMENT_MONITOR=false ;;
      l) LEVEL="${OPTARG}" ;;
      m) DEPLOYMENT_INITIATE=false ;;
      n) DEPLOYMENT_NAME="${OPTARG}" ;;
      r) REGION="${OPTARG}" ;;
      s) DEPLOYMENT_SCOPE="${OPTARG}" ;;
      u) DEPLOYMENT_UNIT="${OPTARG}" ;;
      w) DEPLOYMENT_WAIT="${OPTARG}" ;;
      # TODO(rossmurr4y): Impliment az cli dry-run when available - https://github.com/Azure/azure-cli/issues/5549
      z) DEPLOYMENT_UNIT_SUBSET="${OPTARG}" ;;
      \?) fatalOption; return 1 ;;
      :) fatalOptionArgument; return 1;;
    esac
  done

  # Apply defaults if necessary
  DEPLOYMENT_OPERATION=${DEPLOYMENT_OPERATION:-${DEPLOYMENT_OPERATION_DEFAULT}}
  DEPLOYMENT_WAIT=${DEPLOYMENT_WAIT:-${DEPLOYMENT_WAIT_DEFAULT}}
  DEPLOYMENT_INITIATE=${DEPLOYMENT_INITIATE:-${DEPLOYMENT_INITIATE_DEFAULT}}
  DEPLOYMENT_MONITOR=${DEPLOYMENT_MONITOR:-${DEPLOYMENT_MONITOR_DEFAULT}}
  DEPLOYMENT_SCOPE=${DEPLOYMENT_SCOPE:-${DEPLOYMENT_SCOPE_DEFAULT}}

  # Add component suffix to the deployment name.
  DEPLOYMENT_GROUP_NAME="${DEPLOYMENT_NAME}-${DEPLOYMENT_UNIT}"

  # Set up the context
  info "Preparing the context..."
  . "${GENERATION_DIR}/setStackContext.sh"

  return 0
}

function construct_parameter_inputs() {

  # if composites haven't run yet, do so
  [[ ! -e ${COMPOSITE_STACK_OUTPUTS} ]] &&
    assemble_composite_stack_outputs

  # temp files
  arm_composite_stack_outputs="${tmp_dir}/arm_composite_stack_outputs"
  #TODO(rossmurr4y): template parameter defaults - account for defaults using ARM functions.
  #template_parameter_defaults="${tmp_dir}/template_parameter_defaults"
  template_configs="${tmp_dir}/template_configs"
  parameter_library="${tmp_dir}/parameter_library"

  # Merge Composite Outputs + Template Config Files + Parameter Defaults into one lookup library
  # Precedence: Composite Outputs > Template Configs > Default Values
  jq 'to_entries | map({(.key): (.value.value)}) | .[]' < ${COMPOSITE_STACK_OUTPUTS} | jq -s 'add' > ${arm_composite_stack_outputs}
  #TODO(rossmurr4y): template parameter defaults - account for defaults using ARM functions.
  #jq '.parameters | map_values(select(has("defaultValue"))) | if . == null then {} else . end' < ${TEMPLATE} | jq 'to_entries | map({(.key): (.value.defaultValue)}) | .[]' | jq -s 'add' > ${template_parameter_defaults}
  [[ -f ${CONFIG} ]] &&
    jq '.parameters | to_entries | map({(.key): (.value.value)}) | .[]' < ${CONFIG} | jq -s 'add' > ${template_configs}

  # Construct filter multiplier args
  merge_filter_files=()
  #TODO(rossmurr4y): template parameter defaults - account for defaults using ARM functions.
  #if [[ -f ${template_parameter_defaults}  && $(cat "${template_parameter_defaults}") != "null" && $(cat "${template_parameter_defaults}") != "{}" ]]; then  
  #  merge_filter_files+=("${template_parameter_defaults}")
  #fi
  if [[ -f ${template_configs}  && $(cat "${template_configs}") != "null" && $(cat "${template_configs}") != "{}" ]]; then 
    merge_filter_files+=("${template_configs}")
  fi 
  if [[ -f ${arm_composite_stack_outputs} && $(cat "${arm_composite_stack_outputs}") != "null" && $(cat "${arm_composite_stack_outputs}") != "[]" ]]; then
   merge_filter_files+=("${arm_composite_stack_outputs}")
  fi 
  jqMerge "${merge_filter_files[@]}" > ${parameter_library}

  # from the parameter library, return only the ones required by template
  arrayFromList template_required_parameters "$(jq '.parameters | keys | .[]' < ${TEMPLATE})"
  output_parameter_json=('{}')
  for parameter in ${template_required_parameters[@]}; do 
    output_parameter_json+=$(cat "${parameter_library}" | jq --argjson parameter "${parameter}" 'to_entries[] | select( .key == $parameter ) | { (.key) : {"value": (.value)}}' )
  done
  template_inputs=$(echo "${output_parameter_json}" | jq -s 'add')

  #TODO(rossmurr4y): template parameter defaults - once parameter defaults are implimented
  #                  we can compare the template required parameter count (minus any using
  #                  ARM functions) with the with the number of items in template_inputs to
  #                  provide more helpful error handling.

  echo "${template_inputs}"
  return 0
}

function wait_for_deployment_execution() {

  # Assign the object path to the deployment state.
  status_attribute='.properties.provisioningState'

  info "Watching deployment execution..."

  while true; do

    case ${DEPLOYMENT_OPERATION} in
      update | create)
        if [[" ${DEPLOYMENT_SCOPE}" == "resourceGroup" ]]; then
          DEPLOYMENT=$(az group deployment show --resource-group "${DEPLOYMENT_GROUP_NAME}" --name "${DEPLOYMENT_GROUP_NAME}")
        else
          DEPLOYMENT=$(az deployment show --name "${DEPLOYMENT_GROUP_NAME}")
        fi
      ;;
      delete) 
        # Delete the group not the deployment. Deleting a deployment has no impact on deployed resources in Azure.
        DEPLOYMENT=$(az group show --resource-group "${DEPLOYMENT_GROUP_NAME}" 2>/dev/null) 
      ;;
      *)
        fatal "\"${DEPLOYMENT_OPERATION}\" is not one of the known stack operations."; return 1
      ;;
    esac

    if [[ "${DEPLOYMENT_MONITOR}" = "true" ]]; then

      DEPLOYMENT_STATE="$(echo "${DEPLOYMENT}" | jq -r "${status_attribute}")"
      NOW=$( date '+%F_%H:%M:%S' )

      info "[${NOW}] Provisioning State is \"${DEPLOYMENT_STATE}\"."

      case ${DEPLOYMENT_STATE} in
        Failed) 
          exit_status=255
        ;;
        Running | Accepted | Deleting)
          info "    Retry in ${DEPLOYMENT_WAIT} seconds..."
          sleep ${DEPLOYMENT_WAIT} 
        ;;
        Succeeded) 
          # Retreive the deployment
          echo "${DEPLOYMENT}" | jq '.' > ${STACK} || return $?
          exit_status=0
          break
        ;;
        *)
          if [[ "${DEPLOYMENT_OPERATION}" == "delete" ]]; then
            # deletion successful
            exit_status=0
            break
          else
            fatal "Unexpected deployment state of \"${DEPLOYMENT_STATE}\" "
            exit_status=255
          fi
        ;;
      esac

    fi

    case ${exit_status} in
      0)
      ;;
      255) 
        fatal "Deployment \"${DEPLOYMENT_GROUP_NAME}\" failed, fix deployment before retrying"
        break
      ;;
      *)
        return ${exit_status} ;;
    esac

  done

}

function process_deployment() {

  stripped_template_file="${tmp_dir}/stripped_template"
  stripped_parameter_file="${tmp_dir}/stripped_parameters"

  # Strip excess from the template + parameters
  jq -c '.' < ${TEMPLATE} > "${stripped_template_file}"
  stripped_parameters="$(construct_parameter_inputs)"
  echo "${stripped_parameters}" | jq -c '.' > "${stripped_parameter_file}"

  exit_status=0

  if [[ "${DEPLOYMENT_INITIATE}" = "true" ]]; then

    case ${DEPLOYMENT_OPERATION} in
      create | update)

        if [[ "${DEPLOYMENT_SCOPE}" == "resourceGroup" ]]; then

          # Check resource group status
          info "Checking if the ${DEPLOYMENT_GROUP_NAME} resource group exists..."
          deployment_group_exists=$(az group exists --resource-group "${DEPLOYMENT_GROUP_NAME}")
          if [[ ${deployment_group_exists} = "false" ]]; then
            az group create --resource-group "${DEPLOYMENT_GROUP_NAME}" --location "${REGION}"
          fi

          # validate resource group level deployment
          info "Validating template..."
          az group deployment validate \
            --resource-group "${DEPLOYMENT_GROUP_NAME}" \
            --template-file "${stripped_template_file}" \
            --parameters @"${stripped_parameter_file}" > /dev/null || return $?
          info "Template is valid."

          # Execute the deployment to the resource group
          info "Starting deployment of ${DEPLOYMENT_GROUP_NAME} to the resource group."
          az group deployment create \
            --resource-group "${DEPLOYMENT_GROUP_NAME}" \
            --name "${DEPLOYMENT_GROUP_NAME}" \
            --template-file "${stripped_template_file}" \
            --parameters @"${stripped_parameter_file}" \
            --no-wait > /dev/null || return $?
        
        elif [[ "${DEPLOYMENT_SCOPE}" == "subscription" ]]; then

          # validate subscription level deployment
          info "Validating template..."
          az deployment validate \
            --location "${REGION}" \
            --template-file "${stripped_template_file}" \
            --parameters @"${stripped_parameter_file}" > /dev/null || return $?
          info "Template is valid."

          # Execute the deployment to the subscription
          info "Starting deployment of ${DEPLOYMENT_GROUP_NAME} to the subscription."
          az deployment create \
            --location "${REGION}" \
            --name "${DEPLOYMENT_GROUP_NAME}" \
            --template-file "${stripped_template_file}" \
            --parameters @"${stripped_parameter_file}" \
            --no-wait > /dev/null || return $?

        fi

        wait_for_deployment_execution
      ;;
      delete)

        if [[ "${deployment_group_exists}" = "true" ]]; then

          # Delete the resource group
          info "Deleting the ${DEPLOYMENT_GROUP_NAME} resource group"
          az group delete --resource-group "${DEPLOYMENT_GROUP_NAME}" --no-wait --yes

          wait_for_deployment_execution

          # Clean up the stack if required
          if [[ ("${exit_status}" -eq 0) || !( -s "${STACK}" ) ]]; then
            rm -f "${STACK}"
          fi

        else
          info "No Resource Group found for: ${DEPLOYMENT_GROUP_NAME}. Nothing to do."
          return 0
        fi


      ;;
      *)
        fatal "\"${DEPLOYMENT_OPERATION}\" is not one of the known stack operations."; return 1
        ;;
    esac
  fi

  return "${exit_status}"
}

function main() {

  options "$@" || return $?

  pushTempDir "manage_deployment_XXXXXX"
  export tmp_dir="$(getTopTempDir)"

  pushd ${CF_DIR} > /dev/null 2>&1

  # TODO(rossmurr4y): impliment prologue script when necessary.

  process_deployment_status=0
  # Process the deployment
  info "processing the deployment"
  process_deployment || process_deployment_status=$?

  # Check for completion
  case ${process_deployment_status} in
    0)
      info "${DEPLOYMENT_OPERATION} completed for ${DEPLOYMENT_GROUP_NAME}."
    ;;
    *)
      fatal "There was an issue during deployment."
      return ${process_deployment_status}
  esac

  assemble_composite_stack_outputs

  # TODO(rossmurr4y): impliment epilogue script when necessary.

  return 0
}

main "$@" || true