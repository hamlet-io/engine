#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"
. "${GENERATION_PLUGIN_DIRS}/azure/utility.sh"

# Defaults
DEPLOYMENT_INITIATE_DEFAULT="true"
DEPLOYMENT_MONITOR_DEFAULT="true"
DEPLOYMENT_OPERATION_DEFAULT="update"
DEPLOYMENT_WAIT_DEFAULT=30
DEPLOYMENT_SCOPE_DEFAULT="resourceGroup"
RESOURCE_GROUP_DEFAULT="default"

function usage() {
  cat <<EOF

  Manage an Azure Resource Manager (ARM) deployment

  Usage: $(basename $0) -l LEVEL -r REGION -s DEPLOYMENT_SCOPE -u DEPLOYMENT_UNIT -n DEPLOYMENT_NAME

  where

  (o) -d (DEPLOYMENT_OPERATION=delete)  to delete the deployment
  (o) -g RESOURCE_GROUP                 Defines the Resource Group to deploy into. Mandatory with DEPLOYMENT_SCOPE as "resourceGroup".
      -h                                shows this text
  (o) -i (DEPLOYMENT_MONITOR=false)     initiates but does not monitor the deployment operation.
  (m) -l LEVEL                          is the deployment level - "account", "product", "segment", "solution", "application" or "multiple"
  (o) -m (DEPLOYMENT_INITIATE=false)    monitors but does not initiate the deployment operation.
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
  RESOURCE_GROUP       = ${RESOURCE_GROUP_DEFAULT}

EOF
}

function options() {
  # Parse options
  while getopts ":dg:hil:mr:s:u:w:z:" option; do
    case "${option}" in
      d) DEPLOYMENT_OPERATION=delete ;;
      g) RESOURCE_GROUP="${OPTARG}" ;;
      h) usage; return 1 ;;
      i) DEPLOYMENT_MONITOR=false ;;
      l) LEVEL="${OPTARG}" ;;
      m) DEPLOYMENT_INITIATE=false ;;
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
  RESOURCE_GROUP=${RESOURCE_GROUP:-${RESOURCE_GROUP_DEFAULT}}

  # Add component suffix to the deployment name.
  if [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]]; then
    DEPLOYMENT_NAME="${DEPLOYMENT_SCOPE}-${LEVEL}-${DEPLOYMENT_UNIT}-${DEPLOYMENT_UNIT_SUBSET}"
  else
    DEPLOYMENT_NAME="${DEPLOYMENT_SCOPE}-${LEVEL}-${DEPLOYMENT_UNIT}"
  fi

  # Set up the context
  info "Preparing the context..."
  . "${GENERATION_BASE_DIR}/execution/setStackContext.sh"

  return 0
}

function succeed_or_fail() {
  if [[ ${1} == "succeed" ]]; then
    printf "[ \xE2\x9C\x94 ] "
  else
    printf "[ \xE2\x9D\x8C ] "
  fi
}

function register_resource_providers() {
  local file="$1"; shift

  #providers_raw=$(cat ${file} | jq -c '.resources | map(.type | split("/")[0] ) | unique')
  mapfile -t providers < <(cat ${file} | jq --raw-output '.resources | map(.type | split("/")[0]) | unique | .[]')

  for i in "${!providers[@]}"; do
    az provider register --namespace ${providers[$i]} > /dev/null || return $?
    echo " $(succeed_or_fail "succeed") ${providers[$i]}"
  done
}

function wait_for_deployment_execution() {

  # Assign the object path to the deployment state.
  status_attribute='.properties.provisioningState'

  info "Watching deployment execution..."

  while true; do

    case ${DEPLOYMENT_OPERATION} in
      update | create)
        if [[ "${DEPLOYMENT_SCOPE}" == "resourceGroup" ]]; then
          DEPLOYMENT=$(az group deployment show --resource-group "${RESOURCE_GROUP}" --name "${DEPLOYMENT_NAME}")
        else
          DEPLOYMENT=$(az deployment show --name "${DEPLOYMENT_NAME}")
        fi
      ;;
      delete)
        # Delete the group not the deployment. Deleting a deployment has no impact on deployed resources in Azure.
        DEPLOYMENT=$(az group show --resource-group "${RESOURCE_GROUP}" 2>/dev/null)
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
        fatal "Deployment \"${DEPLOYMENT_NAME}\" in Resource Group \"${RESOURCE_GROUP}\" failed, fix deployment before retrying"
        break
      ;;
      *)
        return ${exit_status} ;;
    esac

  done

}

function process_deployment() {

  exit_status=0

  # Register Resource Providers
  info "Registering Resource Providers."
  register_resource_providers "${TEMPLATE}"

  if [[ "${DEPLOYMENT_INITIATE}" = "true" ]]; then

    case ${DEPLOYMENT_OPERATION} in
      create | update)

        if [[ "${DEPLOYMENT_SCOPE}" == "resourceGroup" ]]; then

          # Check resource group status
          info "Creating resource group ${RESOURCE_GROUP} if required..."
          deployment_group_exists=$(az group exists --resource-group "${RESOURCE_GROUP}")
          if [[ ${deployment_group_exists} = "false" ]]; then
            az group create --resource-group "${RESOURCE_GROUP}" --location "${REGION}" > /dev/null || return $?
          fi

          # validate resource group level deployment
          group_deployment_args=(
            "resource-group ${RESOURCE_GROUP}"
            "template-file ${TEMPLATE}"
          )

          if [[ -e ${PARAMETERS} ]]; then
            # --parameters accepts a file in @<path> syntax
            group_deployment_args=(
              "${group_deployment_args[@]}"
              "parameters @${PARAMETERS}"
            )
          fi

          info "Validating template..."
          az group deployment validate ${group_deployment_args[@]/#/--} > /dev/null || return $?
          info "Template is valid."

          # add remaining deployment options
          group_deployment_args=(
            "${group_deployment_args[@]}"
            "name ${DEPLOYMENT_NAME}"
            "no-wait"
          )

          # Execute the deployment to the resource group
          info "Starting deployment of ${DEPLOYMENT_NAME} to the Resource Group ${RESOURCE_GROUP}."
          az group deployment create ${group_deployment_args[@]/#/--} > /dev/null || return $?

        elif [[ "${DEPLOYMENT_SCOPE}" == "subscription" ]]; then

          subscription_deployment_args=(
            "location ${REGION}"
            "template-file ${TEMPLATE}"
          )

          if [[ -e ${PARAMETERS} ]]; then
            subscription_deployment_args=(
              "${subscription_deployment_args[@]}"
              "parameters @${PARAMETERS}"
            )
          fi

          # validate subscription level deployment
          info "Validating template..."
          az deployment validate ${subscription_deployment_args[@]/#/--} > /dev/null || return $?
          info "Template is valid."

          subscription_deployment_args=(
            "${subscription_deployment_args[@]}"
            "name ${DEPLOYMENT_NAME}"
            "no-wait"
          )

          # Execute the deployment to the subscription
          info "Starting deployment of ${DEPLOYMENT_NAME} to the subscription."
          az deployment create ${subscription_deployment_args[@]/#/--} > /dev/null || return $?

        fi

        wait_for_deployment_execution
      ;;
      delete)

        if [[ "${deployment_group_exists}" = "true" ]]; then

          # Delete the resource group
          info "Deleting the ${RESOURCE_GROUP} resource group"
          az group delete --resource-group "${RESOURCE_GROUP}" --no-wait --yes

          wait_for_deployment_execution

          # Clean up the stack if required
          if [[ ("${exit_status}" -eq 0) || !( -s "${STACK}" ) ]]; then
            rm -f "${STACK}"
          fi

        else
          info "No Resource Group found for: ${RESOURCE_GROUP}. Nothing to do."
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

  # Run the prologue script if present
  # Refresh the stack outputs in case something from pseudo stack is needed
  [[ -s "${PROLOGUE}" ]] && \
    { info "Processing prologue script ..." && . "${PROLOGUE}" || return $?; }

  process_deployment_status=0
  # Process the deployment
  info "processing the deployment"
  process_deployment || process_deployment_status=$?

  # Check for completion
  case ${process_deployment_status} in
    0)
      info "${DEPLOYMENT_OPERATION} completed for ${RESOURCE_GROUP:-DEPLOYMENT_NAME}."
    ;;
    *)
      fatal "There was an issue during deployment."
      return ${process_deployment_status}
  esac

  # Run the epilogue script if present
  # Refresh the stack outputs in case something from the just created stack is needed
  # by the epilogue script
  [[ -s "${EPILOGUE}" ]] && \
  { info "Processing epilogue script ..." && . "${EPILOGUE}" || return $?; }

  return 0
}

main "$@" || true
