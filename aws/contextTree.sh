#!/bin/bash

# GEN3 Context Tree Functions
#
# This script is designed to be sourced into other scripts

# -- Stacks --

function parseStackFilename() {
  local file="$1"; shift

  # Parse stack name for key values
  # Account is not yet part of the stack filename
  contains "$(fileName "${file}")" "([a-z0-9]+)-(.+)-([a-z]{2}-[a-z]+-[1-9])-stack.json"
  STACK_LEVEL="${BASH_REMATCH[1]}"
  STACK_ACCOUNT=""
  STACK_REGION="${BASH_REMATCH[3]}"
  STACK_DEPLOYMENT_UNIT="${BASH_REMATCH[2]}"
}

# -- Composites --

function getCompositeStackOutput() {
  local file="$1"; shift
  local keys=("$@")
  
  local patterns=()

  for key in "${keys[@]}"; do
    patterns+=(".[] | .${key}")
  done
  getJSONValue "${file}" "${patterns[@]}"
}

function getCmk() {
  local level="$1"; shift

  getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "cmkX${level}" "cmkX${level}Xcmk"
}

function getBucketName() {
  local keys=("$@")

  getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "${keys[@]}"
}

function getBluePrintParameter() {
  local patterns=("$@")

  getJSONValue "${COMPOSITE_BLUEPRINT}" "${patterns[@]}"
}

# -- Buckets --

function getOperationsBucket() {
  getBucketName "s3XsegmentXops"
}

function getCodeBucket() {
  getBucketName "s3XaccountXcode"
}

function syncCMDBFilesToOperationsBucket() {
  local base_dir="$1"; shift
  local prefix="$1"; shift
  local optional_arguments=("$@")
  
  local restore_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  local files=()
  files+=(${base_dir}/asFile/*)
  files+=(${base_dir}/${DEPLOYMENT_UNIT}/asFile/*)
  files+=(${base_dir}/${BUILD_DEPLOYMENT_UNIT}/asFile/*)

  ${restore_nullglob}

  syncFilesToBucket "${REGION}" "$(getOperationsBucket)" \
    "${prefix}/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}" \
    "files" "${optional_arguments[@]}" --delete
}

function deleteCMDBFilesFromOperationsBucket() {
  local prefix="$1"; shift
  local optional_arguments=("$@")

  deleteTreeFromBucket ${REGION} "$(getOperationsBucket)" \
    "${prefix}/${PRODUCT}/${SEGMENT}${DEPLOYMENT_UNIT}" \
    "${optional_arguments[@]}"
}

# -- GEN3 directory structure --

function findGen3RootDir() {
  local current="$1"; shift

  # First check for an explicitly marked root
  local marked_root_dir="$(findAncestorDir root.json "${current}")"
  [[ -n "${marked_root_dir}" ]] && echo -n "${marked_root_dir}" && return 0

  # Now look for the first dir containing both a config and infrastructure directory
  local config_root_dir="$(filePath "$(findAncestorDir config "${current}")")"
  local infrastructure_root_dir="$(filePath "$(findAncestorDir infrastructure "${current}")")"
  local root_dir="${config_root_dir:-${infrastructure_root_dir}}"

  [[ (-d "${root_dir}/config") && (-d "${root_dir}/infrastructure") ]] && echo -n "${root_dir}" && return 0

  return 1
}

function findGen3TenantDir() {
  local root_dir="$1"; shift
  local tenant="$1"; shift

  findDir "${root_dir}" \
    "${tenant}/tenant.json" \
    "${tenant}/config/tenant.json" \
    "tenant.json"
}

function findGen3AccountDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  findDir "${root_dir}" \
    "${account}/account.json" \
    "${account}/config/account.json"
}

function findGen3AccountInfrastructureDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  findDir "${root_dir}" \
    "infrastructure/**/${account}" \
    "${account}/infrastructure"
}

function findGen3ProductDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  findDir "${root_dir}" \
    "${product}/product.json" \
    "${product}/config/product.json"
}

function findGen3ProductInfrastructureDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  findDir "${root_dir}" \
    "infrastructure/**/${product}" \
    "${product}/infrastructure"
}

function findGen3SegmentDir() {
  local root_dir="$1"; shift
  local product="${1:-${PRODUCT}}"; shift
  local segment="${1:-${SEGMENT}}"; shift

  local product_dir="$(findGen3ProductDir "${root_dir}" "${product}")"
  [[ -z "${product_dir}" ]] && return 1

  findDir "${product_dir}" \
    "solutions/${segment}/segment.json" \
    "solutions/${segment}/container.json"
}

function getGen3Env() {
  local env="$1"; shift
  local prefix="$1"; shift

  local env_name="${prefix}${env}"
  echo "${!env_name}"
}

function setGen3DirEnv() {
  local env="$1"; shift
  local prefix="$1"; shift
  local directories=("$@")

  local env_name="${prefix}${env}"
  for directory in "${directories[@]}"; do
    if [[ -d "${directory}" ]]; then
      declare -gx "${env_name}=${directory}"
      return 0
    fi
  done

  error $(locationMessage "Can't locate ${env} directory.")

  return 1
}

function findGen3Dirs() {
  local root_dir="$1"; shift
  local tenant="${1:-${TENANT}}"; shift
  local account="${1:-${ACCOUNT}}"; shift
  local product="${1:-${PRODUCT}}"; shift     
  local segment="${1:-${SEGMENT}}"; shift
  local prefix="$1"; shift

  setGen3DirEnv "ROOT_DIR" "${prefix}" "${root_dir}"
      
  setGen3DirEnv "TENANT_DIR" "${prefix}" \
    "$(findGen3TenantDir "${root_dir}" "${tenant}" )" || return 1

  setGen3DirEnv "ACCOUNT_DIR" "${prefix}" \
    "$(findGen3AccountDir "${root_dir}" "${account}" )" || return 1

  setGen3DirEnv "ACCOUNT_INFRASTRUCTURE_DIR" "${prefix}" \
    "$(findGen3AccountInfrastructureDir "${root_dir}" "${account}" )" || return 1

  declare -gx ${prefix}ACCOUNT_APPSETTINGS_DIR=$(getGen3Env "ACCOUNT_DIR" "${prefix}")/appsettings
  declare -gx ${prefix}ACCOUNT_CREDENTIALS_DIR=$(getGen3Env "ACCOUNT_INFRASTRUCTURE_DIR" "${prefix}")/credentials

  if [[ -n "${product}" ]]; then
    setGen3DirEnv "PRODUCT_DIR" "${prefix}" \
      "$(findGen3ProductDir "${root_dir}" "${product}")" || return 1

    setGen3DirEnv "PRODUCT_INFRASTRUCTURE_DIR" "${prefix}" \
      "$(findGen3ProductInfrastructureDir "${root_dir}" "${product}")" || return 1

    declare -gx ${prefix}PRODUCT_APPSETTINGS_DIR=$(getGen3Env "PRODUCT_DIR" "${prefix}")/appsettings
    declare -gx ${prefix}PRODUCT_SOLUTIONS_DIR=$(getGen3Env "PRODUCT_DIR" "${prefix}")/solutions
    declare -gx ${prefix}PRODUCT_CREDENTIALS_DIR=$(getGen3Env "PRODUCT_INFRASTRUCTURE_DIR" "${prefix}")/credentials

    if [[ -n "${segment}" ]]; then
      setGen3DirEnv "SEGMENT_DIR"  "${prefix}" \
        "$(findGen3SegmentDir "${root_dir}" "${product}" "${segment}")" || return 1

      declare -gx ${prefix}SEGMENT_APPSETTINGS_DIR=$(getGen3Env "PRODUCT_APPSETTINGS_DIR" "${prefix}")/${segment}
      declare -gx ${prefix}SEGMENT_CREDENTIALS_DIR=$(getGen3Env "PRODUCT_CREDENTIALS_DIR" "${prefix}")/${segment}
    fi
  fi

  return 0
}

function checkInRootDirectory() {
  local location="${1:-${LOCATION}}"

  [[ ! ("root" =~ ${location}) ]] && fatalDirectory "root"
}

function checkInAccountDirectory() {
  local location="${1:-${LOCATION}}"

  [[ ! ("account" =~ ${location}) ]] && fatalDirectory "account"
}

function checkInProductDirectory() {
  local location="${1:-${LOCATION}}"

  [[ ! ("product" =~ ${location}) ]] && fatalDirectory "product"
}

function checkInSegmentDirectory() {
  local location="${1:-${LOCATION}}"

  [[ ! ("segment" =~ ${location}) ]] && fatalDirectory "segment"
}

function fatalProductOrSegmentDirectory() {
  fatalDirectory "product or segment"
}

# -- Deployment Units --

function isValidUnit() {
  local level="$1"; shift
  local unit="$1"; shift

  # Known levels
  declare -ga LEVELS=("account" "product" "application" "solution" "segment" "multiple")

  # Ensure arguments have been provided
  [[ (-n "${level}") && (-n "${unit}") ]] || return 1

  # Ensure level is kwown
  ! grep -w "${level,,}" <<< "${LEVELS[*]}" && return 1

  # Default deployment units for each level
  declare -ga ACCOUNT_UNITS_ARRAY=("s3" "cert" "roles" "apigateway" "waf")
  declare -ga PRODUCT_UNITS_ARRAY=("s3" "sns" "cert" "cmk")
  declare -ga APPLICATION_UNITS_ARRAY=(${unit})
  declare -ga SOLUTION_UNITS_ARRAY=(${unit})
  declare -ga SEGMENT_UNITS_ARRAY=("iam" "lg" "eip" "s3" "cmk" "cert" "vpc" "nat" "ssh" "dns" "eipvpc" "eips3vpc")
  declare -ga MULTIPLE_UNITS_ARRAY=("iam" "dashboard")

  # Apply explicit unit lists and check for presence of unit
  # Allow them to be separated by commas or spaces in line with the separator
  # definitions in setContext.sh for the automation framework
  if namedef_supported; then
    declare -n UNITS_SOURCE="${level^^}_UNITS"
    declare -n UNITS_ARRAY="${level^^}_UNITS_ARRAY"
  else
    eval "declare UNITS_SOURCE=(\"\${${level^^}_UNITS}\")"
    eval "declare UNITS_ARRAY=(\"\${${level^^}_UNITS_ARRAY[@]}\")"
  fi
  [[ -n "${UNITS_SOURCE}" ]] && IFS=", " read -ra UNITS_ARRAY <<< "${UNITS_SOURCE}"

  # Return result
  grep -iw "${unit}" <<< "${UNITS_ARRAY[*]}" >/dev/null 2>&1
}

# All good