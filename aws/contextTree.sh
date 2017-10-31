#!/bin/bash

# GEN3 Context Tree Functions
#
# This script is designed to be sourced into other scripts

# -- Composites --

function parse_stack_filename() {
  local file="$1"; shift

  # Parse file name for key values
  # Assume Account is part of the stack filename
  if contains "$(fileName "${file}")" "([a-z0-9]+)-(.+)-([1-9][0-9]{10})-([a-z]{2}-[a-z]+-[1-9])(-pseudo)?-(.+)"; then
    stack_level="${BASH_REMATCH[1]}"
    stack_deployment_unit="${BASH_REMATCH[2]}"
    stack_account="${BASH_REMATCH[3]}"
    stack_region="${BASH_REMATCH[4]}"
    return 0
  fi
  if contains "$(fileName "${file}")" "([a-z0-9]+)-(.+)-([a-z]{2}-[a-z]+-[1-9])(-pseudo)?-(.+)"; then
    stack_level="${BASH_REMATCH[1]}"
    stack_deployment_unit="${BASH_REMATCH[2]}"
    stack_region="${BASH_REMATCH[3]}"
    stack_account=""
    return 0
  fi

  return 1
}

function add_standard_pairs_to_stack() {
  local account="$1"; shift
  local region="$1"; shift
  local level="$1"; shift
  local deployment_unit="$1"; shift
  local input_file="$1"; shift
  local output_file="$1"; shift

  local result_file="./temp_add_standard_pairs_to_stack.json"

  runJQ -f ${GENERATION_DIR}/formatOutputs.jq \
    --arg Account "${account}" \
    --arg Region "${region}" \
    --arg Level "${level}" \
    --arg DeploymentUnit "${deployment_unit}" \
    < "${input_file}" > "${result_file}" || return $?

  # Copy/overwrite the output
  [[ -n "${output_file}" ]] && \
    cp "${result_file}" "${output_file}" ||
    cp "${result_file}" "${input_file}"
}

function create_pseudo_stack() {
  local comment="$1"; shift
  local file="$1"; shift
  local pairs=("$@")

  local temp_file="./temp_create_pseudo_stack.json"

  # TODO(mfl): Probably a more elegant way to do this with jq

  # Create the name/value pairs
  cat << EOF > "${temp_file}"
{
  "Stacks": [
    {
      "Comment": "${comment}",
      "Outputs": [
EOF
  # now the keypairs
  for ((i=0; i<${#pairs[@]}; i++)); do
    [[ (i -gt 0) && (i%2 -eq 0) ]] && echo "," >> "${temp_file}"
    [[ i%2 -eq 0 ]] && \
    cat << EOF >> "${temp_file}"
        {
            "OutputKey": "${pairs[i]}",
EOF
    [[ i%2 -ne 0 ]] && \
    cat << EOF >> "${temp_file}"
            "OutputValue": "${pairs[i]}"
        }
EOF
  done

  cat << EOF >> "${temp_file}"
      ]
    }
  ]
}
EOF

  runJQ --indent 4 "." < "${temp_file}" > "${file}"
}

function assemble_composite_stack_outputs() {

  # Create the composite stack outputs
  local restore_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  local stack_array=()
  [[ (-n "${ACCOUNT}") ]] &&
      addToArray "stack_array" "${ACCOUNT_INFRASTRUCTURE_DIR}"/aws/cf/acc*-stack.json
  [[ (-n "${PRODUCT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}"/aws/cf/product*-"${REGION}"*-stack.json
  [[ (-n "${SEGMENT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}"/cf/*-"${REGION}"*-stack.json

  ${restore_nullglob}

  debug "STACK_OUTPUTS=${stack_array[*]}"
  export COMPOSITE_STACK_OUTPUTS="${ROOT_DIR}/composite_stack_outputs.json"
  if [[ $(arraySize "stack_array") -ne 0 ]]; then
    # Add default account, region, stack level and deployment unit
    local modified_stack_array=()
    for stack in "${stack_array[@]}"; do
      # Ignore any existing temp files
      [[ "${stack}" =~ temp_ ]] && continue

      # Annotate as necessary
      if parse_stack_filename "${stack}"; then
        modified_stack_filename="temp_$(fileName "${stack}")"
        add_standard_pairs_to_stack \
          "${stack_account:-${AWSID}}" \
          "${stack_region}" \
          "${stack_level}" \
          "${stack_deployment_unit}" \
          "${stack}" \
          "${modified_stack_filename}"
        modified_stack_array+=("${modified_stack_filename}")
      else
        modified_stack_array+=("${stack}")
      fi
    done
    debug "MODIFIED_STACK_OUTPUTS=${modified_stack_array[*]}"
    ${GENERATION_DIR}/manageJSON.sh -f "[.[].Stacks | select(.!=null) | .[].Outputs | select(.!=null) ]" -o ${COMPOSITE_STACK_OUTPUTS} "${modified_stack_array[@]}"
  else
    echo "[]" > ${COMPOSITE_STACK_OUTPUTS}
  fi
}

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

  ! arrayIsEmpty "files" && \
    { syncFilesToBucket "${REGION}" "$(getOperationsBucket)" \
        "${prefix}/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}" \
        "files" "${optional_arguments[@]}" --delete ||
      return $?; }
  return 0
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
  [[ (-z "${level}") || (-z "${unit}") ]] && return 1

  # Ensure level is kwown
  ! (grep -qw "${level,,}" <<< "${LEVELS[*]}") && return 1
  
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
