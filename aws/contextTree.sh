#!/usr/bin/env bash

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
  if contains "$(fileName "${file}")" "([a-z0-9]+)-(.+-.+)-(.+)-([a-z]{2}-[a-z]+-[1-9])(-pseudo)?-(.+)"; then
    stack_level="${BASH_REMATCH[1]}"
    stack_deployment_unit="${BASH_REMATCH[2]}"
    stack_region="${BASH_REMATCH[4]}"
    stack_account=""
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

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local result_file="$(getTopTempDir)/add_standard_pairs_to_stack.json"
  local return_status

  runJQ -f ${GENERATION_DIR}/formatOutputs.jq \
    --arg Account "${account}" \
    --arg Region "${region}" \
    --arg Level "${level}" \
    --arg DeploymentUnit "${deployment_unit}" \
    < "${input_file}" > "${result_file}"; return_status=$?

  if [[ ${return_status} -eq 0 ]]; then
    # Copy/overwrite the output
    [[ -n "${output_file}" ]] && \
      cp "${result_file}" "${output_file}" ||
      cp "${result_file}" "${input_file}"; return_status=$?
  fi

  popTempDir
  return ${return_status}
}

function create_pseudo_stack() {
  local comment="$1"; shift
  local file="$1"; shift
  local pairs=("$@")

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local tmp_file="$(getTopTempDir)/create_pseudo_stack.json"
  local return_status

  # TODO(mfl): Probably a more elegant way to do this with jq

  # Create the name/value pairs
  cat << EOF > "${tmp_file}"
{
  "Stacks": [
    {
      "Comment": "${comment}",
      "Outputs": [
EOF
  # now the keypairs
  for ((i=0; i<${#pairs[@]}; i++)); do
    [[ (i -gt 0) && (i%2 -eq 0) ]] && echo "," >> "${tmp_file}"
    [[ i%2 -eq 0 ]] && \
    cat << EOF >> "${tmp_file}"
        {
            "OutputKey": "${pairs[i]}",
EOF
    [[ i%2 -ne 0 ]] && \
    cat << EOF >> "${tmp_file}"
            "OutputValue": "${pairs[i]}"
        }
EOF
  done

  cat << EOF >> "${tmp_file}"
      ]
    }
  ]
}
EOF

  runJQ --indent 4 "." < "${tmp_file}" > "${file}"; return_status=$?

  popTempDir
  return ${return_status}
}

function convertFilesToJSONObject() {
  local base_ancestors=($1); shift
  local prefixes=($1); shift
  local root_dir="$1";shift
  local as_file="$1";shift
  local files=("$@")

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local base_file="${tmp_dir}/base.json"
  local processed_files=("${base_file}")
  local return_status

  echo -n "{}" > "${base_file}"

  for file in "${files[@]}"; do

    local file_name="$(fileName "${file}")"
    local file_path="$(filePath "${file}")"
    local file_absolute_path="$(cd "${file_path}"; pwd)"
    local file_root_relative_path="${file_absolute_path##${root_dir}/}"
    local relative_file="${file_root_relative_path}/${file_name}"

    local source_file="${file}"
    local attribute="$( fileBase "${file}" | tr "-" "_" )"

    if [[ "${as_file}" == "true" ]]; then
      source_file="$(getTempFile "asfile_${attribute,,}_XXXX.json" "${tmp_dir}")"
      echo -n "{\"${attribute^^}\" : {\"Value\" : \"$(fileName "${file}")\", \"AsFile\" : \"${relative_file}\" }}" > "${source_file}" || return 1
    else
      case "$(fileExtension "${file}")" in
        json)
          ;;

        escjson)
          source_file="$(getTempFile "escjson_${attribute,,}_XXXX.json" "${tmp_dir}")"
          runJQ \
            "{\"${attribute^^}\" : {\"Value\" : tojson, \"FromFile\" : \"${relative_file}\" }}" \
            "${file}" > "${source_file}" || return 1
          ;;

        *)
          # Assume raw input
          source_file="$(getTempFile "raw_${attribute,,}_XXXX.json" "${tmp_dir}")"
          runJQ -sR \
            "{\"${attribute^^}\" : {\"Value\" : ., \"FromFile\" : \"${relative_file}\" }}" \
            "${file}" > "${source_file}" || return 1
          ;;

      esac
    fi

    local file_ancestors=("${prefixes[@]}" $(filePath "${file}" | tr "./" " ") )
    local processed_file="$(getTempFile "processed_XXXX.json" "${tmp_dir}")"
    addJSONAncestorObjects "${source_file}" "${base_ancestors[@]}" $(join "-" "${file_ancestors[@]}" | tr "[:upper:]" "[:lower:]") > "${processed_file}" || return 1
    processed_files+=("${processed_file}")
  done

  jqMerge "${processed_files[@]}"; return_status=$?
  popTempDir
  return ${return_status}
}

function assemble_settings() {
  local root_dir="${1:-${ROOT_DIR}}"; shift
  local result_file="${1:-${COMPOSITE_SETTINGS}}"; shift

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local tmp_file_list=()

  local id
  local name
  local tmp_file
  local return_status

  # Process accounts
  readarray -t account_files < <(find "${root_dir}" \( \
    -name account.json \
    -and -not -path "*/.*/*" \) | sort)

#  debug "Account=${account_files[@]}"

  # Settings
  for account_file in "${account_files[@]}"; do

    id="$(getJSONValue "${account_file}" ".Account.Id")"
    name="$(getJSONValue "${account_file}" ".Account.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${ACCOUNT}") && ("${ACCOUNT,,}" != "${name,,}") ]] && continue

    local account_dir="$(filePath "${account_file}")/settings"
    debug "Processing ${account_dir} ..."
    pushd "${account_dir}" > /dev/null 2>&1 || continue

    tmp_file="$( getTempFile "account_settings_XXXX.json" "${tmp_dir}")"
    readarray -t setting_files < <(find . -type f -name "*.json" )
    convertFilesToJSONObject "Settings Accounts" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
    tmp_file_list+=("${tmp_file}")
    popd > /dev/null
  done

  # Process products
  readarray -t product_files < <(find "${root_dir}" \( \
    -name product.json \
    -and -not -path "*/.*/*" \) | sort)

#  debug "Products=${product_files[@]}"

  # Settings
  for product_file in "${product_files[@]}"; do

    id="$(getJSONValue "${product_file}" ".Product.Id")"
    name="$(getJSONValue "${product_file}" ".Product.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${PRODUCT}") && ("${PRODUCT,,}" != "${name,,}") ]] && continue

    local product_dir="$(filePath "${product_file}")/settings"
    debug "Processing ${product_dir} ..."
    pushd "${product_dir}" > /dev/null 2>&1 || continue

    # Settings
    readarray -t setting_files < <(find . -type f \( \
      -not \( -name "*build.json" -or -name "*credentials.json" -or -name "*sensitive.json" \) \
      -and -not \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_settings_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Settings Products" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # Sensitive
    readarray -t setting_files < <(find . -type f \( \
      -name "*credentials.json" -or -name "*sensitive.json" \
      -and -not \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_sensitive_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Sensitive Products" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # Builds
    readarray -t setting_files < <(find . -type f \( \
      -name "*build.json" \
      -and -not \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_builds_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Builds Products" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # asFiles
    readarray -t setting_files < <(find . -type f \( \
      \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_settings_asfile_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Settings Products" "${name}" "${root_dir}" "true" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    popd > /dev/null

  done

  # Operations
  for product_file in "${product_files[@]}"; do

    id="$(getJSONValue "${product_file}" ".Product.Id")"
    name="$(getJSONValue "${product_file}" ".Product.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${PRODUCT}") && ("${PRODUCT,,}" != "${name,,}") ]] && continue

    local operations_dir="$(findGen3ProductInfrastructureDir "${root_dir}" "${name}")/operations"
    debug "Processing ${operations_dir} ..."
    pushd "${operations_dir}" > /dev/null 2>&1 || continue

    # Settings
    readarray -t setting_files < <(find . -type f \( \
      -not \( -name "*build.json" -or -name "*credentials.json" -or -name "*sensitive.json" \) \
      -and -not \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "operations_settings_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Settings Products" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # Sensitive
    readarray -t setting_files < <(find . -type f \( \
      -name "*credentials.json" -or -name "*sensitive.json" \
      -and -not \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "operations_sensitive_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Sensitive Products" "${name}" "${root_dir}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # asFiles
    readarray -t setting_files < <(find . -type f \( \
      \( -path "*/asfile/*" -or -path "*/asFile/*" \) \
      -and -not \( -name ".*" -or -path "*/.*/*" \) \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "operations_settings_asfile_XXXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Settings Products" "${name}" "${root_dir}" "true" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    popd > /dev/null

  done

  # Generate the merged output
  debug "Generating ${result_file} ..."
  jqMerge "${tmp_file_list[@]}" > "${result_file}"; return_status=$?

  popTempDir
  return ${return_status}
}

function assemble_composite_stack_outputs() {

  # Create the composite stack outputs
  local restore_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local tmp_dir="$(getTopTempDir)"

  local stack_array=()
  [[ (-n "${ACCOUNT}") ]] &&
      addToArray "stack_array" "${ACCOUNT_INFRASTRUCTURE_DIR}"/cf/shared/acc*-stack.json
  [[ (-n "${PRODUCT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}"/cf/shared/product*-"${REGION}"*-stack.json
  [[ (-n "${ENVIRONMENT}") && (-n "${SEGMENT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"/*-stack.json

  ${restore_nullglob}

  debug "STACK_OUTPUTS=${stack_array[*]}"
  export COMPOSITE_STACK_OUTPUTS="${CACHE_DIR}/composite_stack_outputs.json"
  if [[ $(arraySize "stack_array") -ne 0 ]]; then
    # Add default account, region, stack level and deployment unit
    local modified_stack_array=()
    for stack in "${stack_array[@]}"; do
      # Annotate as necessary
      if parse_stack_filename "${stack}"; then
        modified_stack_filename="${tmp_dir}/$(fileName "${stack}")"
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
    ${GENERATION_DIR}/manageJSON.sh -f "[.[].Stacks | select(.!=null) | .[].Outputs | select(.!=null) ]" -o "${COMPOSITE_STACK_OUTPUTS}" "${modified_stack_array[@]}"
  else
    echo "[]" > "${COMPOSITE_STACK_OUTPUTS}"
  fi

  popTempDir
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

function encrypt_file() {
  local region="$1"; shift
  local level="$1"; shift
  local input_file="$1"; shift
  local output_file="$1"; shift

  pushTempDir "${FUNCNAME[0]}_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local cmk=$(getCmk "${level}")
  local return_status

  cp "${input_file}" "${tmp_dir}/encrypt_file"

  (cd "${tmp_dir}"; aws --region "${region}" --output text kms encrypt \
    --key-id "${cmk}" --query CiphertextBlob \
    --plaintext "fileb://encrypt_file" > "${output_file}"; return_status=$?)

  popTempDir
  return ${return_status}
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

function findGen3TenantInfrastructureDir() {
  local root_dir="$1"; shift
  local tenant="$1"; shift

  findDir "${root_dir}" \
    "${tenant}/infrastructure"
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

function findGen3EnvironmentDir() {
  local root_dir="$1"; shift
  local product="${1:-${PRODUCT}}"; shift
  local environment="${1:-${ENVIRONMENT}}"; shift

  local product_dir="$(findGen3ProductDir "${root_dir}" "${product}")"
  [[ -z "${product_dir}" ]] && return 1

  findDir "${product_dir}" "solutionsv2/${environment}/environment.json"
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
  local environment="${1:-${ENVIRONMENT}}"; shift
  local segment="${1:-${SEGMENT}}"; shift
  local prefix="$1"; shift

  setGen3DirEnv "ROOT_DIR" "${prefix}" "${root_dir}"
  debug "ROOT_DIR=${ROOT_DIR}"

  setGen3DirEnv "TENANT_DIR" "${prefix}" \
    "$(findGen3TenantDir "${root_dir}" "${tenant}" )" || return 1
  debug "TENANT_DIR=${TENANT_DIR}"

  setGen3DirEnv "ACCOUNT_DIR" "${prefix}" \
    "$(findGen3AccountDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_DIR=${ACCOUNT_DIR}"

  setGen3DirEnv "ACCOUNT_INFRASTRUCTURE_DIR" "${prefix}" \
    "$(findGen3AccountInfrastructureDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_INFRASTRUCTURE_DIR=${ACCOUNT_INFRASTRUCTURE_DIR}"

  declare -gx ${prefix}ACCOUNT_SETTINGS_DIR=$(getGen3Env "ACCOUNT_DIR" "${prefix}")/settings
  declare -gx ${prefix}ACCOUNT_OPERATIONS_DIR=$(getGen3Env "ACCOUNT_INFRASTRUCTURE_DIR" "${prefix}")/operations

  if [[ -n "${product}" ]]; then
    setGen3DirEnv "PRODUCT_DIR" "${prefix}" \
      "$(findGen3ProductDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_DIR=${PRODUCT_DIR}"

    setGen3DirEnv "PRODUCT_INFRASTRUCTURE_DIR" "${prefix}" \
      "$(findGen3ProductInfrastructureDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_INFRASTRUCTURE_DIR=${PRODUCT_INFRASTRUCTURE_DIR}"

    declare -gx ${prefix}PRODUCT_SETTINGS_DIR=$(getGen3Env   "PRODUCT_DIR"                "${prefix}")/settings
    declare -gx ${prefix}PRODUCT_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_DIR"                "${prefix}")/solutionsv2
    declare -gx ${prefix}PRODUCT_OPERATIONS_DIR=$(getGen3Env "PRODUCT_INFRASTRUCTURE_DIR" "${prefix}")/operations

    declare -gx ${prefix}PRODUCT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/shared
    declare -gx ${prefix}PRODUCT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/shared
    declare -gx ${prefix}PRODUCT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/shared

    if [[ -n "${environment}" ]]; then

      declare -gx ${prefix}ENVIRONMENT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/${environment}
      declare -gx ${prefix}ENVIRONMENT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/${environment}
      declare -gx ${prefix}ENVIRONMENT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/${environment}
      debug "ENVIRONMENT_DIR=$(getGen3Env "PRODUCT_SOLUTIONS_DIR" "${prefix}")/${environment}"

      if [[ -n "${segment}" ]]; then

        declare -gx ${prefix}SEGMENT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/shared/${segment}
        declare -gx ${prefix}SEGMENT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/shared/${segment}
        declare -gx ${prefix}SEGMENT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/shared/${segment}

        declare -gx ${prefix}SEGMENT_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_BUILDS_DIR=$(getGen3Env     "PRODUCT_SETTINGS_DIR"   "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/${environment}/${segment}
        debug "SEGMENT_DIR=$(getGen3Env "PRODUCT_SOLUTIONS_DIR" "${prefix}")/${environment}/${segment}"
      fi
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

function checkInEnvironmentDirectory() {
  local location="${1:-${LOCATION}}"

  [[ ! ("environment" =~ ${location}) ]] && fatalDirectory "environment"
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
  local level="${1,,}"; shift
  local unit="${1,,}"; shift

  local result=0

  # Known levels
  declare -gA unit_required=( \
    ["blueprint"]="false" \
    ["account"]="true" \
    ["product"]="true" \
    ["application"]="true" \
    ["solution"]="true" \
    ["segment"]="true" \
    ["multiple"]="true" )

  # Ensure arguments have been provided
  [[ (-z "${unit_required[${level}]}") || ((-z "${unit}") && ("${unit_required[${level}]}" == "true")) ]] && return 1

  # Check unit if required
  if [[ "${unit_required[${level}]}" == "true" ]]; then
    # Default deployment units for each level
    declare -ga ACCOUNT_UNITS_ARRAY=("audit" "s3" "cert" "roles" "apigateway" "waf")
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
    result=$?
  fi
  return ${result}
}

# -- Upgrade CMDB --

function upgrade_build_ref() {
  local legacy_file="$1"; shift
  local upgraded_file="$1"; shift

  IFS= " " read -ra build_array < "${legacy_file}"
  [[ -z "${build_Array[0]}" ]] && fatal "Unable to upgrade build reference in ${file}" && return 1

  echo -n "{\"Commit\" : \"${build_array[0]}\"" > "${upgraded_file}"
  [[-n "${build_array[1]}" ]] && echo -n ", \"Tag\" : \"${build_array[1]}\"" >> "${upgraded_file}"
  echo -n ", \"Formats\" : [\"docker\"]}" >> "${upgraded_file}"

  return 0
}

function upgrade_shared_build_ref() {
  local legacy_file="$1"; shift
  local upgraded_file="$1"; shift

  echo -n "{\"Reference\" : \"" > "${upgraded_file}"
  cat "${legacy_file}" >> "${upgraded_file}"
  echo -n "\"}" >> "${upgraded_file}"

  return 0
}

function upgrade_credentials() {
  local legacy_file="$1"; shift
  local upgraded_file="$1"; shift

    if [[ "$(jq ".Credentials | if .==null then [] else [1] end | length" < "${legacy_file}" )" -gt 0 ]]; then
      runJQ ".Credentials" "${legacy_file}"  > "${upgraded_file}"
    else
      cat "${legacy_file}" > "${upgraded_file}"
    fi
}

# Remove .ref files, simplify credentials files
function upgrade_cmdb_repo_to_v1_0_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local tmp_file

  local return_status=0

  # All build references now in json format
  readarray -t legacy_files < <(find "${root_dir}" -type f \
    -name "build.ref" )
  for legacy_file in "${legacy_files[@]}"; do
    debug "Checking ${legacy_file}..."
    replacement_file="$(filePath "${legacy_file}")/build.json"
    [[ -f "${replacement_file}" ]] && continue
    info "Upgrading ${legacy_file} ..."
    tmp_file="$(getTempFile "build_XXXX.json" "${tmp_dir}")"
    upgrade_build_ref "${legacy_file}" "${tmp_file}" || { return_status=1; break; }

    if [[ -n "${dry_run}" ]]; then
      willLog "trace" && { echo; cat "${tmp_file}"; echo; }
      continue
    fi
    cp "${tmp_file}" "${replacement_file}" || { return_status=1; break; }
  done

  # All shared build references now in json format
  if [[ ${return_status} -eq 0 ]]; then
    readarray -t legacy_files < <(find "${root_dir}" -type f \
      \( -name "*.ref" -and -not -name "build.ref" \) )
    for legacy_file in "${legacy_files[@]}"; do
      debug "Checking ${legacy_file}..."
      replacement_file="$(filePath "${legacy_file}")/shared_build.json"
      [[ -f "${replacement_file}" ]] && continue
      info "Upgrading ${legacy_file} ..."
      tmp_file="$(getTempFile "shared_XXXX.json" "${tmp_dir}")"
      upgrade_shared_build_ref "${legacy_file}" "${tmp_file}" || { return_status=1; break; }

      if [[ -n "${dry_run}" ]]; then
        willLog "trace" && { echo; cat "${tmp_file}"; echo; }
        continue
      fi
      cp "${tmp_file}" "${replacement_file}" || { return_status=1; break; }
    done
  fi

  # Strip top level "Credentials" attribute from credentials
  if [[ ${return_status} -eq 0 ]]; then
    readarray -t legacy_files < <(find "${root_dir}" -type f \
      -name "credentials.json" )
    for legacy_file in "${legacy_files[@]}"; do
      debug "Checking ${legacy_file}..."
      if [[ "$(jq ".Credentials | if .==null then [] else [1] end | length" < "${legacy_file}" )" -gt 0 ]]; then
        upgrade_needed="true"
        info "Upgrading ${legacy_file} ..."
        tmp_file="$(getTempFile "credentials_XXXX.json" "${tmp_dir}")"
        upgrade_credentials "${legacy_file}" "${tmp_file}" || { return_status=1; break; }

      if [[ -n "${dry_run}" ]]; then
          willLog "trace" && { echo; cat "${tmp_file}"; echo; }
          continue
        fi
        cp "${tmp_file}" "${legacy_file}" || { return_status=1; break; }
      fi
    done
  fi

  # Change of naming from "container" to "segment"
  if [[ ${return_status} -eq 0 ]]; then
    readarray -t legacy_files < <(find "${root_dir}" -type f \
      -name "container.json" )
    for legacy_file in "${legacy_files[@]}"; do
      debug "Checking ${legacy_file}..."
      replacement_file="$(filePath "${legacy_file}")/segment.json"
      [[ -f "${replacement_file}" ]] && continue
      upgrade_needed="true"
      info "Upgrading ${legacy_file} ..."
      tmp_file="$(getTempFile "container_XXXX.json" "${tmp_dir}")"
      cp "${legacy_file}" "${tmp_file}" || { return_status=1; break; }

      if [[ -n "${dry_run}" ]]; then
        willLog "trace" && { echo; cat "${tmp_file}"; echo; }
        continue
      fi
      cp "${legacy_file}" "${replacement_file}" || { return_status=1; break; }
    done
  fi

  popTempDir

  return ${return_status}
}

function cleanup_cmdb_repo_to_v1_0_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  # All build references now in json format
  readarray -t legacy_files < <(find "${root_dir}" -type f \
    -name "build.ref" )
  for legacy_file in "${legacy_files[@]}"; do
    info "${dry_run}Deleting ${legacy_file} ..."
    [[ -n "${dry_run}" ]] && continue
    git_rm -f "${legacy_file}" || return 1
  done

  # All shared build references now in json format
  readarray -t legacy_files < <(find "${root_dir}" -type f \
    \( -name "*.ref" -and -not -name "build.ref" \) )
  for legacy_file in "${legacy_files[@]}"; do
    info "${dry_run}Deleting ${legacy_file} ..."
    [[ -n "${dry_run}" ]] && continue
    git_rm -f "${legacy_file}" || return 1
  done

  # Change of naming from "container" to "segment"
  readarray -t legacy_files < <(find "${root_dir}" -type f \
    -name "container.json" )
  for legacy_file in "${legacy_files[@]}"; do
    info "${dry_run}Deleting ${legacy_file} ..."
    [[ -n "${dry_run}" ]] && continue
    git_rm -f "${legacy_file}" || return 1
  done

  return 0
}

# Introduce separate environment and segment dirs
function upgrade_cmdb_repo_to_v1_1_0_settings() {
  local root_dir="$1";shift
  local dry_run="$1";shift
  local target_dir="$1";shift

  # Create the shared file location for default segment
  local shared_dir="${target_dir}/shared"
  mkdir -p "${shared_dir}" || return 1

  # Copy across the shared files
  readarray -t sub_files < <(find "${root_dir}" -mindepth 1 -maxdepth 1 -type f )
  for sub_file in "${sub_files[@]}"; do
    debug "Copying ${sub_file} to ${shared_dir} ..."
    [[ -n "${dry_run}" ]] && continue
    cp "${sub_file}" "${shared_dir}" || return 1
  done

  # Process each sub dir
  readarray -t sub_dirs < <(find "${root_dir}" -mindepth 1 -maxdepth 1 -type d )
  for sub_dir in "${sub_dirs[@]}"; do
    local environment="$(fileName "${sub_dir}")"
    local segment_dir="${target_dir}/${environment}/default"
    mkdir -p "${segment_dir}" || return 1

    debug "Copying ${sub_dir} to ${segment_dir} ..."
    [[ -n "${dry_run}" ]] && continue
    cp -rp "${sub_dir}"/* "${segment_dir}" || return 1

    # Remove anything unwanted
    readarray -t segment_files < <(find "${segment_dir}" -type f \
      -name "*.ref" \
      -or -name "container.json" )
    for segment_file in "${segment_files[@]}"; do
      debug "Deleting ${segment_file} ..."
      rm "${segment_file}" || return 1
    done
  done
  return 0
}

function upgrade_cmdb_repo_to_v1_1_0_state() {
  local root_dir="$1";shift
  local dry_run="$1";shift
  local target_dir="$1";shift

  # Create the shared file location
  local shared_dir="${target_dir}/shared"
  mkdir -p "${shared_dir}" || return 1

  # Copy across the shared files
  if [[ -d "${root_dir}/cf" ]]; then
    readarray -t sub_files < <(find "${root_dir}/cf" -mindepth 1 -maxdepth 1 -type f )
    for sub_file in "${sub_files[@]}"; do
      debug "Copying ${sub_file} to ${shared_dir} ..."
      [[ -n "${dry_run}" ]] && continue
      cp "${sub_file}" "${shared_dir}" || return 1
    done
  fi

  # Process each sub dir
  readarray -t sub_dirs < <(find "${root_dir}" -mindepth 1 -maxdepth 1 -type d \( \
    -not -name "cf" \) )
  for sub_dir in "${sub_dirs[@]}"; do
    local environment="$(fileName "${sub_dir}")"
    local segment_dir="${target_dir}/${environment}/default"
    mkdir -p "${segment_dir}" || return 1

    [[ ! -d "${sub_dir}/cf" ]] && continue
    debug "Copying ${sub_dir}/cf to ${segment_dir} ..."
    [[ -n "${dry_run}" ]] && continue
    cp -rp "${sub_dir}"/cf/* "${segment_dir}" || return 1
  done
  return 0
}

declare -A upgrade_v1_1_0_sources
upgrade_v1_1_0_sources=( \
  ["appsettings"]="settings" \
  ["solutions"]="solutionsv2" \
  ["credentials"]="operations" \
  ["aws"]="cf")

# config segment folders now under an environment folder
function upgrade_cmdb_repo_to_v1_1_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  for source in "${!upgrade_v1_1_0_sources[@]}"; do
    readarray -t source_dirs < <(find "${root_dir}" -type d -name "${source}" )
    for source_dir in "${source_dirs[@]}"; do
      local target_dir="$(filePath "${source_dir}")/${upgrade_v1_1_0_sources[${source}]}"
      debug "Checking ${source_dir} ..."
      [[ -d "${target_dir}" ]] && continue
      info "Converting ${source_dir} into ${target_dir} ..."
      if [[ "${source}" == "aws" ]]; then
        upgrade_cmdb_repo_to_v1_1_0_state "${source_dir}" "${dryrun}" "${target_dir}" ||
        { return_status=$?; break; }
      else
        upgrade_cmdb_repo_to_v1_1_0_settings "${source_dir}" "${dryrun}" "${target_dir}" ||
        { return_status=$?; break; }
      fi

      [[ -n "${dry_run}" ]] && continue

      # Special processing
      case "${source}" in
        solutions)
          # Shared solution files are specific to the default segment
          local shared_default_dir="${target_dir}/shared/default"
          mkdir -p "${shared_default_dir}" || { return_status=$?; break; }

          readarray -t solution_files < <(find "${target_dir}/shared" -mindepth 1 -maxdepth 1 -type f)
          for solution_file in "${solution_files[@]}"; do
            debug "Moving ${solution_file} to ${shared_default_dir} ..."
            mv "${solution_file}" "${shared_default_dir}"
          done

          # Process environments
          readarray -t segment_files < <(find "${target_dir}" -type f -name "segment.json")
          for segment_file in "${segment_files[@]}"; do
            local segment_dir="$(filePath "${segment_file}")"
            local environment_dir="$(filePath "${segment_dir}")"

            # Add environment.json file
            local environment_id="$(jq -r ".Segment.Environment | select(.!=null)" < "${segment_file}")"
            local environment_file="${environment_dir}/environment.json"
            debug "Creating ${environment_file} ..."
            cat << EOF > "${environment_file}"
{
  "Environment" : {
    "Id" : "${environment_id}"
  }
}
EOF
            # Remove segment attributes that are now elsewhere
            debug "Cleaning ${segment_file} ..."
            local tmp_file="${tmp_dir}/segment.json"
            jq "del(.Segment.Id) | del(.Segment.Name) | del(.Segment.Title) | del(.Segment.Environment)" \
              < "${segment_file}" \
              > "${tmp_file}"  ||
            { return_status=$?; break; }
            cp "${tmp_file}" "${segment_file}"
          done

          local shared_segment_file="${shared_default_dir}/segment.json"
          debug "Creating ${shared_segment_file} ..."
          cat << EOF > "${shared_segment_file}"
{
  "Segment" : {
    "Id" : "default"
  }
}
EOF
          ;;

        credentials)
          readarray -t pem_files < <(find "${target_dir}" -type f -name "aws-ssh*.pem")
          for pem_file in "${pem_files[@]}"; do
            local file_name="$(fileName "${pem_file}")"
            local segment_dir="$(filePath "${pem_file}")"
            local environment_dir="$(filePath "${segment_dir}")"

            # Move the file so it can be shared by all segments in the environment
            # Also make it invisible to the generation process
            debug "Moving ${pem_file} to ${environment_dir}/.${file_name} ..."
            mv "${pem_file}" "${environment_dir}/.${file_name}"

            local environment_ignore_file="${environment_dir}/.gitignore"
            if [[ ! -f "${environment_ignore_file}" ]]; then
              debug "Creating ${environment_ignore_file} ..."
              cat << EOF > "${environment_ignore_file}"
*.plaintext
*.decrypted
*.ppk
EOF
            fi
          done
          ;;
      esac
      done
  done

  popTempDir

  return ${return_status}
}

function cleanup_cmdb_repo_to_v1_1_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  for source in "${!upgrade_v1_1_0_sources[@]}"; do
    readarray -t source_dirs < <(find "${root_dir}" -mindepth 1 -maxdepth 1 -type d \
      -name "${source}" )
    for source_dir in "${source_dirs[@]}"; do
      info "Deleting ${source_dir} ..."
      [[ -n "${dry_run}" ]] && continue
      git_rm -rf "${source_dir}" || return 1
    done
  done

  return 0
}

function process_cmdb() {
  local root_dir="$1";shift
  local action="$1";shift
  local version_list="$1";shift
  local dry_run="${1:+(Dryrun) }";shift

  declare -a versions
  arrayFromList versions "${version_list}"
  local return_status=0

  # Find all the repos
  readarray -t cmdb_git_repos < <(find "${root_dir}" -type d -name ".git" | sort )

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXX"
  local tmp_version_file="$(getTopTempDir)/new_version.json"
  local tmp_result_file="$(getTopTempDir)/new_cmdb.json"

  # Process each one
  for cmdb_git_repo in "${cmdb_git_repos[@]}"; do

    local cmdb_repo="$(filePath "${cmdb_git_repo}")"
    debug "Checking repo ${cmdb_repo} ..."

    local cmdb_version_file="${cmdb_repo}/.cmdb"
    local current_version=""

    if [[ -f "${cmdb_version_file}" ]]; then
      current_version="$(jq -r ".Version.${action^} | select(.!=null)" < "${cmdb_version_file}")"
      debug "Repo is at ${action,,} version ${current_version:-<not initialised>}"
    else
      echo -n "{}" > "${cmdb_version_file}"
    fi

    [[ -z "${current_version}" ]] && current_version="v0.0.0"

    for version in "${versions[@]}"; do
      # Nothing to do if not less than version being checked
      local semver_check="$(semver_compare "${current_version}" "${version}")"

      if [[ "${semver_check}" == "-1" ]]; then
        info "${dry_run}${action^} of repo "${cmdb_repo}" to ${version} required ..."
      else
        debug "${action^} of repo "${cmdb_repo}" to ${version} is not required"
        continue
      fi

      ${action,,}_cmdb_repo_to_${version//./_} "${cmdb_repo}" "${dry_run}"; return_status=$?

      if [[ "${return_status}" -eq 0 ]]; then
        # Only check the first version to be applied for a dryrun
        if [[ -n "${dry_run}" ]]; then
          debug "${dry_run}Skipping later versions"
          break
        fi

        # Record the action
        info "${action^} of repo "${cmdb_repo}" to ${version} successful"
        echo -n "{\"Version\" : {\"${action^}\" : \"${version}\"}}" > "${tmp_version_file}"
        jqMerge "${cmdb_version_file}" "${tmp_version_file}" > "${tmp_result_file}" &&
          { cp "${tmp_result_file}" "${cmdb_version_file}"; current_version="${version}"; } ||
          return_status=$?
      fi
      [[ "${return_status}" -ne 0 ]] && break
    done

    [[ "${return_status}" -ne 0 ]] && break
  done

  popTempDir
  return ${return_status}
}

function upgrade_cmdb() {
  local root_dir="$1";shift
  local dry_run="$1";shift
  local versions="$1";shift

  local required_versions=(${versions})
  [[ -z "${versions}" ]] && required_versions=("v1.0.0" "v1.1.0")

  process_cmdb "${root_dir}" "upgrade" "${required_versions[*]}" ${dry_run}
}

function cleanup_cmdb() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  local required_versions=(${versions})
  [[ -z "${versions}" ]] && required_versions=("v1.0.0")

  process_cmdb "${root_dir}" "cleanup" "${required_versions[*]}" ${dry_run}
}
