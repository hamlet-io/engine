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

function create_pseudo_stack() {
  local comment="$1"; shift
  local file="$1"; shift
  local pairs=("$@")

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
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

function getFilesAsJSON() {
  local result_file="$1";shift
  local files=("$@")

  local file_array=()
  local return_status

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local tmp_dir="$(getTopTempDir)"

  # Create standardised versions of the files
  if [[ $(arraySize "files") -ne 0 ]]; then
    for file in "${files[@]}"; do
      local file_name="$( fileName ${file} )"
      local relative_file_path="$( filePath ${file} )"
      local file_path="$( cd "${relative_file_path}"; pwd )"
      local tmp_file="$( getTempFile "XXXXXX" "${tmp_dir}" )"
      addToArray "file_array" "${tmp_file}"
      if $(contains "${file}" "asFile"); then
        # Only want the filename
        echo {} | jq --arg file_name "${file_name}" --arg file_path "${file_path}" \
            '{ "FileName" : $file_name, "FilePath" : $file_path, "Content" : [] }' >> "${tmp_file}"
      else
        # Want file content - handle a few content variants
        case "$(fileExtension "${file_name}")" in
          json)
            jq --arg file_name "${file_name}" --arg file_path "${file_path}" \
                '{ "FileName" : $file_name, "FilePath" : $file_path, "Content" : [.] }' < "${file}" > "${tmp_file}"
            ;;

          escjson)
            jq --arg file_name "${file_name}" --arg file_path "${file_path}" \
                '{ "FileName" : $file_name, "FilePath" : $file_path, "Content" : [tojson] }' < "${file}" > "${tmp_file}"
            ;;

          *)
            # Assume raw input
            jq -sR --arg file_name "${file_name}" --arg file_path "${file_path}" \
                '{ "FileName" : $file_name, "FilePath" : $file_path, "Content" : [.] }' < "${file}" > "${tmp_file}"
            ;;

        esac
      fi
    done

    # Slurp all of the standardised files and put them into a single file as an array
    # Freemarker doesn't support the null json value in ?eval so we need to remove any null values
    runJQ --indent 2 -s -f "${GENERATION_BASE_DIR}/execution/nullStrip.jq" "${file_array[@]}" > "${result_file}"; return_status=$?
  else
    echo "[]" > "${result_file}"; return_status=0
  fi

  popTempDir
  return ${return_status}
}

function convertFilesToJSONObject() {
  local ancestors=($1); shift
  local root_dir="$1";shift
  local base_dir="$1";shift
  local result_file="$1";shift
  local files=("$@")

  local filter='{ "RootDirectory" : $root_dir, "BaseDirectory" : $base_dir, "Files" : . }'
  local return_status

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local tmp_dir="$(getTopTempDir)"

  # First assemble all the files
  getFilesAsJSON "${tmp_dir}/files.json" "${files[@]}"; return_status=$?
  if [[ $return_status -eq 0 ]]; then

    # Add any ancestors
    for (( index=${#ancestors[@]}-1 ; index >= 0 ; index-- )) ; do
      filter="{\"${ancestors[index]}\" : ${filter} }"
    done

    # Add the root and base directories
    jq --arg root_dir "${root_dir}" --arg base_dir "${base_dir}" \
      "${filter}" < "${tmp_dir}/files.json" > "${result_file}"; return_status=$?
  fi

  popTempDir
  return ${return_status}
}

function assemble_settings() {
  local root_dir="${1:-${ROOT_DIR}}"; shift
  local result_file="${1:-${COMPOSITE_SETTINGS}}"; shift

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
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

  # debug "Account=${account_files[@]}"

  # Settings
  for account_file in "${account_files[@]}"; do

    id="$(getJSONValue "${account_file}" ".Account.Id")"
    name="$(getJSONValue "${account_file}" ".Account.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${ACCOUNT}") && ("${ACCOUNT,,}" != "${name,,}") ]] && continue

    local account_dir="$(findGen3AccountSettingsDir "${root_dir}" "${name}")"
    debug "Processing account dir ${account_dir} ..."
    pushd "${account_dir}" > /dev/null 2>&1 || continue

    readarray -t setting_files < <(find . -type f -name "*.json" )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="${tmp_dir}/accounts_settings_${name}.json"
      convertFilesToJSONObject "Accounts Settings ${name}" "${root_dir}" "${account_dir}" "${tmp_file}" "${setting_files[@]}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi
    popd > /dev/null
  done

  # Process products
  readarray -t product_files < <(find "${root_dir}" \( \
    -name product.json \
    -and -not -path "*/.*/*" \) | sort)

  # debug "Products=${product_files[@]}"

  for product_file in "${product_files[@]}"; do

    id="$(getJSONValue "${product_file}" ".Product.Id")"
    name="$(getJSONValue "${product_file}" ".Product.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${PRODUCT}") && ("${PRODUCT,,}" != "${name,,}") ]] && continue

    # Settings
    local settings_dir="$(findGen3ProductSettingsDir "${root_dir}" "${name}")"
    if [[ -d "${settings_dir}" ]]; then
      debug "Processing settings dir ${settings_dir} ..."
      pushd "${settings_dir}" > /dev/null 2>&1 || continue

      readarray -t setting_files < <(find . -type f \( \
        -not \( -name ".*" -or -path "*/.*/*" \) \) )
      if ! arrayIsEmpty "setting_files" ; then
        tmp_file="${tmp_dir}/products_settings_${name}.json"
        convertFilesToJSONObject "Products Settings ${name}" "${root_dir}" "${settings_dir}" "${tmp_file}" "${setting_files[@]}"  || return 1
        tmp_file_list+=("${tmp_file}")
      fi

      popd > /dev/null
    fi

    # Builds
    local builds_dir="$(findGen3ProductBuildsDir "${root_dir}" "${name}")"
    if [[ (-d "${builds_dir}") && ("${settings_dir}" != "${builds_dir}") ]]; then
      debug "Processing builds dir ${builds_dir} ..."
      pushd "${builds_dir}" > /dev/null

      readarray -t build_files < <(find . -type f \( \
        -not \( -name ".*" -or -path "*/.*/*" \) \) )
      if ! arrayIsEmpty "build_files" ; then
        tmp_file="${tmp_dir}/products_builds_${name}.json"
        convertFilesToJSONObject "Products Builds ${name}" "${root_dir}" "${builds_dir}" "${tmp_file}" "${build_files[@]}"  || return 1
        tmp_file_list+=("${tmp_file}")
      fi

      popd > /dev/null
    fi

    # Operations
    local operations_dir="$(findGen3ProductOperationsDir "${root_dir}" "${name}")"
    if [[ -d "${operations_dir}" ]]; then
      debug "Processing operations dir ${operations_dir} ..."
      pushd "${operations_dir}" > /dev/null

      readarray -t operations_files < <(find . -type f \( \
        -not \( -name ".*" -or -path "*/.*/*" \) \) )
      if ! arrayIsEmpty "operations_files" ; then
        tmp_file="${tmp_dir}/products_operations_${name}.json"
        convertFilesToJSONObject "Products Operations ${name}" "${root_dir}" "${operations_dir}" "${tmp_file}" "${operations_files[@]}"  || return 1
        tmp_file_list+=("${tmp_file}")
      fi

      popd > /dev/null
    fi
  done

  # Generate the merged output
  debug "Generating ${result_file} ..."
  jqMerge "${tmp_file_list[@]}" > "${result_file}"; return_status=$?

  popTempDir
  return ${return_status}
}

function assemble_composite_definitions() {

  local tmp_file="$( getTempFile "definitions_XXXXXX" "${tmp_dir}" )"

  # Gather the relevant definitions
  local restore_nullglob=$(shopt -p nullglob)
  local restore_globstar=$(shopt -p globstar)
  shopt -s nullglob
  shopt -s globstar

  local definitions_array=()
  [[ (-n "${ACCOUNT}") ]] &&
      addToArray "definitions_array" "${ACCOUNT_STATE_DIR}"/cf/shared/**/defn*-definition.json
  [[ (-n "${PRODUCT}") && (-n "${REGION}") ]] &&
      addToArray "definitions_array" "${PRODUCT_STATE_DIR}"/cf/shared/**/defn*-"${REGION}"*-definition.json
  [[ (-n "${ENVIRONMENT}") && (-n "${SEGMENT}") && (-n "${REGION}") ]] &&
      addToArray "definitions_array" "${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"/**/*${ACCOUNT}*-definition.json

  ${restore_globstar}
  ${restore_nullglob}

  debug "DEFINITIONS=${definitions_array[*]}"
  jqMerge "${definitions_array[@]}" > "${tmp_file}"

  # Escape any freemarker markup
  export COMPOSITE_DEFINITIONS="${CACHE_DIR}/composite_definitions.json"
  sed 's/${/$\\{/g' < "${tmp_file}" > "${COMPOSITE_DEFINITIONS}"
}

function assemble_composite_stack_outputs() {

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local tmp_dir="$(getTopTempDir)"

  # Create the composite stack outputs
  local restore_nullglob=$(shopt -p nullglob)
  local restore_globstar=$(shopt -p globstar)
  shopt -s nullglob
  shopt -s globstar

  local stack_array=()
  [[ (-n "${ACCOUNT}") ]] &&
      addToArray "stack_array" "${ACCOUNT_STATE_DIR}"/*/shared/**/acc*-stack.json
  [[ (-n "${ENVIRONMENT}") && (-n "${SEGMENT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_STATE_DIR}"/*/"${ENVIRONMENT}/${SEGMENT}"/**/*${ACCOUNT}*-stack.json

  ${restore_globstar}
  ${restore_nullglob}

  debug "STACK_OUTPUTS=${stack_array[*]}"

  export COMPOSITE_STACK_OUTPUTS="${CACHE_DIR}/composite_stack_outputs.json"

  getFilesAsJSON "${COMPOSITE_STACK_OUTPUTS}" "${stack_array[@]}"; return_status=$?

  popTempDir
  return ${return_status}
}

function getBluePrintParameter() {
  local patterns=("$@")

  getJSONValue "${COMPOSITE_BLUEPRINT}" "${patterns[@]}"
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

function findGen3AccountSettingsDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  local account_dir="$(findGen3AccountDir "${root_dir}" "${account}")"
  if [[ -n "${account_dir}" ]]; then
    echo -n "${account_dir}/settings"
    return 0
  fi
  return 1
}

function findGen3AccountInfrastructureDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  findDir "${root_dir}" \
    "${account}/infrastructure" \
    "infrastructure/**/${account}"
}

# It would be very rare that accounts would have standard settings and operations
# settings as normally the accounts tree is controlled by the operations team.
# Thus the settings directory should be adequate. Nonetheless it allows consistency
# if the operations team always put their settings in the operations directory,
# regardless of repo.
function findGen3AccountOperationsDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  # TODO(mfl): Remove infrastructure checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${account}/operations/settings" \
    "operations/**/${account}/settings" \
    "${account}/infrastructure/operations" \
    "infrastructure/**/${account}/operations"
}

function findGen3AccountStateDir() {
  local root_dir="$1"; shift
  local account="$1"; shift

  # TODO(mfl): Remove infrastructure checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${account}/state" \
    "state/**/${account}" \
    "${account}/infrastructure" \
    "infrastructure/**/${account}"
}

function findGen3ProductDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  findDir "${root_dir}" \
    "${product}/product.json" \
    "${product}/config/product.json"
}

function findGen3ProductSettingsDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  local product_dir="$(findGen3ProductDir "${root_dir}" "${product}")"
  if [[ -n "${product_dir}" ]]; then
    echo -n "${product_dir}/settings"
    return 0
  fi
  return 1
}

function findGen3ProductInfrastructureDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  findDir "${root_dir}" \
    "${product}/infrastructure" \
    "infrastructure/**/${product}"
}

function findGen3ProductOperationsDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  # TODO(mfl): Remove infrastructure checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${product}/operations/settings" \
    "operations/**/${product}/settings" \
    "${product}/infrastructure/operations" \
    "infrastructure/**/${product}/operations"
}

function findGen3ProductSolutionsDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  # TODO(mfl): Remove config checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${product}/infrastructure/solutions" \
    "infrastructure/**/${product}/solutions" \
    "${product}/config/solutionsv2" \
    "config/**/${product}/solutionsv2"
}

function findGen3ProductBuildsDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  # TODO(mfl): Remove config checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${product}/infrastructure/builds" \
    "infrastructure/**/${product}/builds" \
    "${product}/config/settings" \
    "config/**/${product}/settings"
}

function findGen3ProductStateDir() {
  local root_dir="$1"; shift
  local product="$1"; shift

  # TODO(mfl): Remove infrastructure checks when all repos converted to >=v2.0.0
  findDir "${root_dir}" \
    "${product}/state" \
    "state/**/${product}" \
    "${product}/infrastructure" \
    "infrastructure/**/${product}"
}

function findGen3ProductEnvironmentDir() {
  local root_dir="$1"; shift
  local product="$1"; shift
  local environment="$1"; shift

  local solutions_dir="$(findGen3ProductSolutionsDir "${root_dir}" "${product}")"
  [[ -z "${solutions_dir}" ]] && return 1

  findDir "${solutions_dir}" "${environment}/environment.json"
}

function findGen3ProductEnvironmentSegmentDir() {
  local root_dir="$1"; shift
  local product="$1"; shift
  local environment="$1"; shift
  local segment="$1"; shift

  local environment_dir="$(findGen3ProductEnvironmentDir "${root_dir}" "${product}" "${environment}")"
  [[ -z "${environment_dir}" ]] && return 1

  findDir "${environment_dir}" "${segment}/segment.json"
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

  setGen3DirEnv "ACCOUNT_SETTINGS_DIR" "${prefix}" \
    "$(findGen3AccountSettingsDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_SETTINGS_DIR=${ACCOUNT_SETTINGS_DIR}"

  setGen3DirEnv "ACCOUNT_INFRASTRUCTURE_DIR" "${prefix}" \
    "$(findGen3AccountInfrastructureDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_INFRASTRUCTURE_DIR=${ACCOUNT_INFRASTRUCTURE_DIR}"

  setGen3DirEnv "ACCOUNT_OPERATIONS_DIR" "${prefix}" \
    "$(findGen3AccountOperationsDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_OPERATIONS_DIR=${ACCOUNT_OPERATIONS_DIR}"

  setGen3DirEnv "ACCOUNT_STATE_DIR" "${prefix}" \
    "$(findGen3AccountStateDir "${root_dir}" "${account}" )" || return 1
  debug "ACCOUNT_STATE_DIR=${ACCOUNT_STATE_DIR}"

  if [[ -n "${product}" ]]; then
    setGen3DirEnv "PRODUCT_DIR" "${prefix}" \
      "$(findGen3ProductDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_DIR=${PRODUCT_DIR}"

    setGen3DirEnv "PRODUCT_SETTINGS_DIR" "${prefix}" \
      "$(findGen3ProductSettingsDir "${root_dir}" "${product}" )" || return 1
    debug "PRODUCT_SETTINGS_DIR=${PRODUCT_SETTINGS_DIR}"

    setGen3DirEnv "PRODUCT_INFRASTRUCTURE_DIR" "${prefix}" \
      "$(findGen3ProductInfrastructureDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_INFRASTRUCTURE_DIR=${PRODUCT_INFRASTRUCTURE_DIR}"

    setGen3DirEnv "PRODUCT_OPERATIONS_DIR" "${prefix}" \
      "$(findGen3ProductOperationsDir "${root_dir}" "${product}" )" || return 1
    debug "PRODUCT_OPERATIONS_DIR=${PRODUCT_OPERATIONS_DIR}"

    setGen3DirEnv "PRODUCT_SOLUTIONS_DIR" "${prefix}" \
      "$(findGen3ProductSolutionsDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_SOLUTIONS_DIR=${PRODUCT_SOLUTIONS_DIR}"

    setGen3DirEnv "PRODUCT_BUILDS_DIR" "${prefix}" \
      "$(findGen3ProductBuildsDir "${root_dir}" "${product}")" || return 1
    debug "PRODUCT_BUILDS_DIR=${PRODUCT_BUILDS_DIR}"

    setGen3DirEnv "PRODUCT_STATE_DIR" "${prefix}" \
      "$(findGen3ProductStateDir "${root_dir}" "${product}" )" || return 1
    debug "PRODUCT_STATE_DIR=${PRODUCT_STATE_DIR}"

    declare -gx ${prefix}PRODUCT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/shared
    declare -gx ${prefix}PRODUCT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/shared
    declare -gx ${prefix}PRODUCT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/shared

    if [[ -n "${environment}" ]]; then
      debug "ENVIRONMENT_DIR=$(findGen3ProductEnvironmentDir "${root_dir}" "${product}" "${environment}")"
      declare -gx ${prefix}ENVIRONMENT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/${environment}
      declare -gx ${prefix}ENVIRONMENT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/${environment}
      declare -gx ${prefix}ENVIRONMENT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/${environment}

      if [[ -n "${segment}" ]]; then
        debug "SEGMENT_DIR=$(findGen3ProductEnvironmentSegmentDir "${root_dir}" "${product}" "${environment}" "${segment}")"
        declare -gx ${prefix}SEGMENT_SHARED_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/shared/${segment}
        declare -gx ${prefix}SEGMENT_SHARED_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/shared/${segment}
        declare -gx ${prefix}SEGMENT_SHARED_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/shared/${segment}

        declare -gx ${prefix}SEGMENT_SETTINGS_DIR=$(getGen3Env   "PRODUCT_SETTINGS_DIR"   "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_BUILDS_DIR=$(getGen3Env     "PRODUCT_BUILDS_DIR"   "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_SOLUTIONS_DIR=$(getGen3Env  "PRODUCT_SOLUTIONS_DIR"  "${prefix}")/${environment}/${segment}
        declare -gx ${prefix}SEGMENT_OPERATIONS_DIR=$(getGen3Env "PRODUCT_OPERATIONS_DIR" "${prefix}")/${environment}/${segment}
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
    ["unitlist"]="false" \
    ["blueprint"]="false" \
    ["buildblueprint"]="true" \
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
    declare -ga ACCOUNT_UNITS_ARRAY=("iam" "lg" "audit" "s3" "cert" "roles" "apigateway" "waf" "sms" "console")
    declare -ga PRODUCT_UNITS_ARRAY=("s3" "sns" "cert" "cmk")
    declare -ga BUILDBLUEPRINT_UNITS_ARRAY=(${unit})
    declare -ga APPLICATION_UNITS_ARRAY=(${unit})
    declare -ga SOLUTION_UNITS_ARRAY=(${unit})
    declare -ga SEGMENT_UNITS_ARRAY=(${unit})
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

function formatUnitCFDir() {
  local base_dir="${1}"; shift
  local level="${1,,}"; shift
  local unit="${1,,}"; shift
  local placement="${1,,}"; shift
  local region="${1,,}"; shift

  # Determine placement by region if not explicitly provided
  if [[ -z "${placement}" ]]; then
    case "${region}" in
      us-east-1)
        local placement="global"
        ;;
      *)
        local placement="default"
        ;;
    esac
  fi

  echo -n "${base_dir}/${unit}/${placement}"
  return 0
}

function getUnitCFDir() {
  local base_dir="${1}"; shift
  local level="${1,,}"; shift
  local unit="${1,,}"; shift
  local placement="${1,,}"; shift
  local region="${1,,}"; shift

  # Check for legacy files that don't contain the deployment unit
  case "${level}" in
    account)
      if [[
          ("${unit}" == "s3") && (-f "${base_dir}/account-${region}-template.json") ]]; then
        echo -n "${base_dir}" && return 0
      fi
      ;;

    product)
      if [[
          ("${unit}" == "cmk") && (-f "${base_dir}/product-${region}-template.json") ]]; then
        echo -n "${base_dir}" && return 0
      fi
      ;;

    solution)
      if [[ -f "${base_dir}/solution-${region}-template.json" ]]; then
        echo -n "${base_dir}" && return 0
      fi
      ;;

    segment)
      if [[
          (!("${unit}" =~ cmk|cert|dns )) &&
          (-f "${base_dir}/container-${region}-template.json") ]]; then
        echo -n "${base_dir}" && return 0
      fi
      if [[
          ("${unit}" == "cmk") &&
          (
            (-f "${base_dir}/seg-key-${region}-template.json") ||
            (-f "${base_dir}/cont-key-${region}-template.json")
          ) ]]; then
        echo -n "${base_dir}" && return 0
      fi
      ;;
  esac

  formatUnitCFDir "${base_dir}" "${level}" "${unit}" "${placement}" "${region}"
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

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
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
    tmp_file="$(getTempFile "build_XXXXXX.json" "${tmp_dir}")"
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
      tmp_file="$(getTempFile "shared_XXXXXX.json" "${tmp_dir}")"
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
        tmp_file="$(getTempFile "credentials_XXXXXX.json" "${tmp_dir}")"
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
      tmp_file="$(getTempFile "container_XXXXXX.json" "${tmp_dir}")"
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

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
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

            # Move the pem files to make them invisible to the generation process
            debug "Moving ${pem_file} to ${segment_dir}/.${file_name} ..."
            mv "${pem_file}" "${segment_dir}/.${file_name}"

            local segment_ignore_file="${segment_dir}/.gitignore"
            if [[ ! -f "${segment_ignore_file}" ]]; then
              debug "Creating ${segment_ignore_file} ..."
              cat << EOF > "${segment_ignore_file}"
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
    readarray -t source_dirs < <(find "${root_dir}" -type d -name "${source}" )
    for source_dir in "${source_dirs[@]}"; do
      local target_dir="$(filePath "${source_dir}")/${upgrade_v1_1_0_sources[${source}]}"
      debug "Checking ${source_dir} ..."
      [[ ! -d "${target_dir}" ]] && continue
      info "Deleting ${source_dir} ..."
      [[ -n "${dry_run}" ]] && continue
      git_rm -rf "${source_dir}" || return 1
    done
  done

  return 0
}

function cleanup_cmdb_repo_to_v1_1_1() {
  # Rerun 1.1.0 to pick up errors in original implementation
  # Previously it only worked for product repos but now should
  # work for all repos
  cleanup_cmdb_repo_to_v1_1_0 "$@"
}

function cleanup_cmdb_repo_to_v2_0_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  readarray -t config_dirs < <(find "${root_dir}" -type d -name "config" )
  for config_dir in "${config_dirs[@]}"; do
    local solutions_dir="${config_dir}/solutionsv2"
    if [[ -d "${solutions_dir}" ]]; then
      info "Deleting ${solutions_dir} ..."
      [[ -n "${dry_run}" ]] && continue
      git_rm -rf "${solutions_dir}" || return 1
    fi
  done

  return 0
}

# container_* files now should be fragment_*
function upgrade_cmdb_repo_to_v1_2_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  readarray -t legacy_files < <(find "${root_dir}" -type f \
    -name "container_*.ftl" )
  for legacy_file in "${legacy_files[@]}"; do
    debug "Checking ${legacy_file}..."
    replacement_filename="$(fileName "${legacy_file}")"
    replacement_filename="${replacement_filename/container_/fragment_}"
    replacement_file="$(filePath "${legacy_file}")/${replacement_filename}"
    [[ -f "${replacement_file}" ]] && continue
    info "Renaming ${legacy_file} to ${replacement_file}..."

    if [[ -n "${dry_run}" ]]; then
      continue
    fi
    git_mv "${legacy_file}" "${replacement_file}" || { return_status=1; break; }
  done

  popTempDir

  return ${return_status}
}

function upgrade_cmdb_repo_to_v1_3_0() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  # Find accounts
  local -A account_mappings
  readarray -t account_files < <(find "${GENERATION_DATA_DIR}" -type f -name "account.json" )
  for account_file in "${account_files[@]}"; do
    aws_id="$( jq -r '.Account.AWSId' <"${account_file}" )"
    account_id="$( jq -r '.Account.Id' < "${account_file}" )"
    account_mappings+=(["${aws_id}"]="${account_id}")
  done

  readarray -t cf_dirs < <(find "${root_dir}" -type d -name "cf" )
  for cf_dir in "${cf_dirs[@]}"; do
    readarray -t cmk_stacks < <(find "${cf_dir}" -type f -name "seg-cmk-*[0-9]-stack.json" )
    for cmk_stack in "${cmk_stacks[@]}"; do

      info "Looking for CMK account in ${cmk_stack} ..."
      cmk_account="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Account" ) | .OutputValue' < "${cmk_stack}" )"
      cmk_region="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Region" ) | .OutputValue' < "${cmk_stack}" )"

      if [[ -n "${cmk_account}" ]]; then
        cmk_account_id="${account_mappings[${cmk_account}]}"
        cmk_path="$(filePath "${cmk_stack}")"

        readarray -t segment_stacks < <(find "${cmk_path}"  -type f -name "*stack.json")
        for stack_file in "${segment_stacks[@]}"; do

          parse_stack_filename "${stack_file}"
          stack_dir="$(filePath "${stack_file}")"
          stack_filename="$(fileName "${stack_file}")"

          # Add Standard Account and Region Stack Outputs
          stackoutput_account="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Account" ) | .OutputValue' < "${stack_file}" )"
          stackoutput_region="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Region" ) | .OutputValue' < "${stack_file}" )"
          stackoutput_level="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Level" ) | .OutputValue' < "${stack_file}" )"
          stackoutput_deployment_unit="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="DeploymentUnit" ) | .OutputValue' < "${stack_file}" )"

          if [[ -z "${stackoutput_account}" ]]; then
              debug "Adding Account Output to ${stack_file} ..."
              jq -r --arg account "${cmk_account}" '.Stacks[].Outputs += [{ "OutputKey" : "Account", "OutputValue" : $account  }]' < "${stack_file}" > "${tmp_dir}/${stack_filename}"
              if [[ $? == 0 ]]; then
                mv "${tmp_dir}/${stack_filename}" "${stack_file}"
              fi
          fi

          if [[ -z "${stackoutput_region}" ]]; then
              debug "Adding Region Output to ${stack_file} ..."
              jq -r --arg region "${stack_region}" '.Stacks[].Outputs += [{ "OutputKey" : "Region", "OutputValue" : $region  }]' < "${stack_file}" > "${tmp_dir}/${stack_filename}"
              if [[ $? == 0 ]]; then
                mv "${tmp_dir}/${stack_filename}" "${stack_file}"
              fi
          fi


          if [[ -z "${stack_account}" ]]; then

            # Rename file to inclue Region and Account
            stack_file_name="$(fileName "${stack_file}" )"
            new_stack_file_name="${stack_file_name/"-${stack_region}-"/-${cmk_account_id}-${stack_region}-}"

            if [[ "${stack_file_name}" != "${new_stack_file_name}" && "${stack_file_name}" != *"${cmk_account_id}"* ]]; then
              debug "Moving ${stack_file} to ${stack_dir}/${new_stack_file_name} ..."

              if [[ -n "${dry_run}" ]]; then
                continue
              fi

              git_mv "${stack_file}" "${stack_dir}/${new_stack_file_name}"
            fi
          fi
        done

        # Rename SSH keys to include Account/Region
        operations_path="${cmk_path/"infrastructure/cf"/infrastructure/operations}"

        info "Checking for SSH Keys in ${operations_path} ..."
        readarray -t pem_files < <(find "${operations_path}" -type f -name ".aws-ssh*.pem*" )

        for pem_file in "${pem_files[@]}"; do
          local pem_file_path="$(filePath "${pem_file}")"
          local file_name="$(fileName "${pem_file}")"
          local new_file_name="${file_name/aws-/aws-${cmk_account_id}-${cmk_region}-}"

          # Move the pem files to make them invisible to the generation process
          debug "Moving ${pem_file} to ${pem_file_path}/${new_file_name} ..."

          if [[ -n "${dry_run}" ]]; then
            continue
          fi
          git_mv "${pem_file}" "${pem_file_path}/${new_file_name}"
        done
      fi
    done
  done

  popTempDir

  return $return_status
}

function upgrade_cmdb_repo_to_v1_3_1() {
  local root_dir="$1";shift
  local dry_run="$1";shift

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  # Find accounts
  local -A account_mappings
  readarray -t account_files < <(find "${GENERATION_DATA_DIR}" -type f -name "account.json" )
  for account_file in "${account_files[@]}"; do
    aws_id="$( jq -r '.Account.AWSId' <"${account_file}" )"
    account_id="$( jq -r '.Account.Id' < "${account_file}" )"
    account_mappings+=(["${aws_id}"]="${account_id}")
  done

  readarray -t cf_dirs < <(find "${root_dir}" -type d -name "cf" )
  for cf_dir in "${cf_dirs[@]}"; do
    readarray -t cmk_stacks < <(find "${cf_dir}" -type f -name "seg-cmk-*[0-9]-stack.json" )
    for cmk_stack in "${cmk_stacks[@]}"; do

      info "Looking for CMK account in ${cmk_stack} ..."
      cmk_account="$( jq -r '.Stacks[0].Outputs[] | select( .OutputKey=="Account" ) | .OutputValue' < "${cmk_stack}" )"

      if [[ -n "${cmk_account}" ]]; then
        cmk_account_id="${account_mappings[${cmk_account}]}"
        cmk_path="$(filePath "${cmk_stack}")"

        readarray -t segment_cf < <(find "${cmk_path}"  -type f )
        for cf_file in "${segment_cf[@]}"; do

          parse_stack_filename "${cf_file}"
          stack_dir="$(filePath "${cf_file}")"

          if [[ -z "${stack_account}" ]]; then

            # Rename file to inclue Region and Account
            cf_file_name="$(fileName "${cf_file}" )"
            new_cf_file_name="${cf_file_name/"-${stack_region}-"/-${cmk_account_id}-${stack_region}-}"

            move_file=1
            if [[ "${cf_file_name}" != "${new_cf_file_name}" && "${cf_file_name}" != *"${cmk_account_id}"* ]]; then
              if [[ -e "${stack_dir}/${new_cf_file_name}" ]]; then
                diff "${cf_file}" "${stack_dir}/${new_cf_file_name}" > /dev/null
                if [[ $? -eq 0 ]]; then
                  move_file=0
                else
                  fatal "Rename failed - ${stack_dir}/${new_cf_file_name} already exists. Manual intervention necessary."
                  return_status=1
                  break
                fi
              fi

              if [[ "${move_file}" != 0 ]]; then
                debug "Moving ${cf_file} to ${stack_dir}/${new_cf_file_name} ..."
              else
                warning "${cf_file} already upgraded - removing ..."
              fi

              if [[ -n "${dry_run}" ]]; then
                continue
              fi

              if [[ "${move_file}" != 0 ]]; then
                git_mv "${cf_file}" "${stack_dir}/${new_cf_file_name}"
              else
                git_rm "${cf_file}"
              fi
            fi
          fi
        done
      fi
      [[ "${return_status}" -ne 0 ]] && break
    done
    [[ "${return_status}" -ne 0 ]] && break
  done

  popTempDir

  return $return_status
}

function upgrade_cmdb_repo_to_v1_3_2() {
  # Rerun 1.3.1 to pick up errors in original implementation
  # Should be a no-op when run immediately after current 1.3.1
  # implementation
  upgrade_cmdb_repo_to_v1_3_1 "$@"
}

function upgrade_cmdb_repo_to_v2_0_0() {
  # Reorganise cmdb to make it easier to manage via branches and dynamic cmdbs
  #
  # State is now in its own directory at the same level as config and infrastructure
  # Solutions is now under infrastructure
  # Builds are separated from settings and are now under infrastructure
  # Operations are now in their own directory at same level as config and
  # infrastructure. For consistency with config, a settings subdirectory has been
  # added.
  #
  # With this layout,
  # - infrastructure should be the same across environments assuming no builds
  #   are being promoted
  # - product and operations settings are managed consistently
  # - all the state info is cleanly separated (so potentially in its own repo)
  #
  # /config/settings
  # /operations/settings
  # /infrastructure/solutions
  # /infrastructure/builds
  # /state/cf
  # /state/cot
  #
  # If config and infrastructure are not in the one repo, then the upgrade must
  # be performed manually and the cmdb version manually updated
  local root_dir="$1";shift
  local dry_run="$1";shift


  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  readarray -t config_dirs < <(find "${root_dir}" -type d -name "config" )
  for config_dir in "${config_dirs[@]}"; do
    local base_dir="$(filePath "${config_dir}")"
    local config_dir="${base_dir}/config"
    local infrastructure_dir="${base_dir}/infrastructure"
    local state_dir="${base_dir}/state"
    local operations_dir="${base_dir}/operations"

    local state_subdirs=("${infrastructure_dir}/cf" "${infrastructure_dir}/cot")

    if [[ -d "${infrastructure_dir}" ]]; then
      debug "${dry_run}Checking ${base_dir} ..."

      # Move the state into its own top level tree
      mkdir -p "${state_dir}"
      for state_subdir in "${state_subdirs[@]}"; do
        if [[ -d "${state_subdir}" ]]; then
          info "${dry_run}Moving ${state_subdir} to ${state_dir} ..."
          [[ -n "${dry_run}" ]] && continue
          git_mv "${state_subdir}" "${state_dir}" || { return_status=1; break; }
        fi
      done

      # Move operations settings into their own top level tree
      orig_operations_settings_dir="${infrastructure_dir}/operations"
      new_operations_settings_dir="${operations_dir}/settings"
      if [[ -d "${orig_operations_settings_dir}" ]]; then
        info "${dry_run}Moving ${orig_operations_settings_dir} to ${new_operations_settings_dir} ..."
        [[ -n "${dry_run}" ]] && continue
        if [[ ! -d "${new_operations_settings_dir}" ]]; then
          mkdir -p "${operations_dir}"
          git_mv "${orig_operations_settings_dir}" "${new_operations_settings_dir}" || { return_status=1; break; }
        fi
      fi

      # Copy the solutions tree from config to infrastructure and rename
      local solutions_dir="${config_dir}/solutionsv2"
      if [[ -d "${solutions_dir}" ]]; then
        info "${dry_run}Copying ${solutions_dir} to ${infrastructure_dir} ..."
        if [[ -z "${dry_run}" ]]; then
          # Leave existing solutions dir in place as it may be the current directory
          cp -pr "${solutions_dir}" "${infrastructure_dir}" || return_status=1
        fi
        info "${dry_run}Renaming ${infrastructure_dir}/solutionsv2 to ${infrastructure_dir}/solutions ..."
        if [[ -z "${dry_run}" ]]; then
          mv "${infrastructure_dir}/solutionsv2" "${infrastructure_dir}/solutions"
        fi
      fi

      # Copy the builds into their own tree
      local settings_dir="${config_dir}/settings"
      local builds_dir="${infrastructure_dir}/builds"
      if [[ ! -d "${builds_dir}" ]]; then
        info "${dry_run}Copying ${settings_dir} to ${builds_dir} ..."
        if [[ -z "${dry_run}" ]]; then
          cp -pr "${settings_dir}" "${builds_dir}"
        fi
      fi

      # Remove the build files from the settings tree
      # Blob will pick up build references and shared builds
      info "${dry_run}Cleaning the settings tree ..."
      readarray -t setting_files < <(find "${settings_dir}" -type f \( \
        -name "*build.json" \) )
      for setting_file in "${setting_files[@]}"; do
        info "${dry_run}Deleting ${setting_file} ..."
        [[ -n "${dry_run}" ]] && continue
        git_rm "${setting_file}" || { return_status=1; break; }
      done

      # Build tree should only contain build references and shared builds
      info "${dry_run}Cleaning the builds tree ..."
      [[ -n "${dry_run}" ]] &&
        readarray -t build_files < <(find "${settings_dir}"   -type f \( \
        -not -name "*build.json" \) ) ||
        readarray -t build_files < <(find "${builds_dir}"   -type f \( \
        -not -name "*build.json" \) )
      for build_file in "${build_files[@]}"; do
        info "${dry_run}Deleting ${build_file} ..."
        [[ -n "${dry_run}" ]] && continue
        rm "${build_file}" || { return_status=1; break; }
      done

    else
      warn "${dry_run}Update to v2.0.0 for ${config_dir} must be manually performed for split cmdb repos"
    fi
  done

  popTempDir

  return $return_status
}

function upgrade_cmdb_repo_to_v2_0_1() {
  # Reorganise state files into a directory tree based on deployment unit and placement
  #
  # The format of the state tree will follow the pattern
  # state/{df}/{env}/{seg}/{du}/{placement}
  #
  # Delete definition files because their file name contains the occurrence name not the
  # deployment unit. They will be regenerated into the correct dir on the next build.
  local root_dir="$1";shift
  local dry_run="$1";shift


  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status=0

  readarray -t state_dirs < <(find "${root_dir}" -type d -name "state" )
  for state_dir in "${state_dirs[@]}"; do

    readarray -t deployment_frameworks < <(find "${state_dir}" -mindepth 1 -maxdepth 1 -type d )
    for df_dir in "${deployment_frameworks[@]}"; do
      local deployment_framework="$(fileName "${df_dir}")"

      debug "${dry_run}Checking ${deployment_framework} deployment framework ..."
      readarray -t state_files < <(find "${df_dir}" -type f )
      for state_file in "${state_files[@]}"; do

        local state_filepath="$(filePath "${state_file}")"
        local state_filename="$(fileName "${state_file}")"

        local stack_deployment_unit=""

        # Filename format varies with deployment framework
        if
          contains "${state_filename}" "([a-z0-9]+)-(.+)-([a-z][a-z0-9]+)-([a-z]{2}-[a-z]+-[1-9])(-pseudo)?-(.+)" ||
          contains "${state_filename}" "([a-z0-9]+)-(.+)-([a-z][a-z0-9]+)-(eastus|australiaeast|australiasoutheast|australiacentral|australiacentral2)(-pseudo)?-(.+)"; then

          local stack_level="${BASH_REMATCH[1]}"
          local stack_deployment_unit="${BASH_REMATCH[2]}"
          local stack_region="${BASH_REMATCH[4]}"
        fi

        if [[ -z "${stack_deployment_unit}" ]]; then
          # Legacy account formats
          if contains "${state_filename}" "account-([a-z][a-z0-9]+)-([a-z]{2}-[a-z]+-[1-9])-(.+)"; then
            local stack_level="account"
            local stack_deployment_unit="${BASH_REMATCH[1]}"
            local stack_region="${BASH_REMATCH[2]}"
          fi
          if contains "${state_filename}" "account-([a-z]{2}-[a-z]+-[1-9])-(.+)"; then
            local stack_level="account"
            local stack_deployment_unit="s3"
            local stack_region="${BASH_REMATCH[1]}"
          fi
        fi

        if [[ -z "${stack_deployment_unit}" ]]; then
          # Legacy product formats
          if contains "${state_filename}" "product-([a-z]{2}-[a-z]+-[1-9])-(.+)"; then
            local stack_level="product"
            local stack_deployment_unit="cmk"
            local stack_region="${BASH_REMATCH[1]}"
          fi
        fi

        if [[ -z "${stack_deployment_unit}" ]]; then
          # Legacy segment formats
          if contains "${state_filename}" "seg-key-([a-z]{2}-[a-z]+-[1-9])-(.+)"; then
            local stack_level="seg"
            local stack_deployment_unit="cmk"
            local stack_region="${BASH_REMATCH[1]}"
          fi
          if contains "${state_filename}" "cont-([a-z][a-z0-9]+)-([a-z]{2}-[a-z]+-[1-9])-(.+)"; then
            local stack_level="seg"
            local stack_deployment_unit="${BASH_REMATCH[1]}"
            local stack_region="${BASH_REMATCH[2]}"
          fi
        fi

        if [[ -z "${stack_deployment_unit}" ]]; then
          warn "${dry_run}Ignoring ${state_file}, doesn't match one of the expected state filename formats ..."
          continue
        fi

        case "${stack_level}" in
          defn)
            # Definition files are copied on every template creation
            info "${dry_run}Deleting ${state_file} ..."
            [[ -n "${dry_run}" ]] && continue
            git_rm -f "${state_file}" || { return_status=1; }
            ;;

          *)
            # Add deployment unit based subdirectories
            if contains "${state_filepath}" "${stack_deployment_unit}"; then
              debug "${dry_run}Ignoring ${state_file}, already moved ..."
            else
              local du_dir=$(formatUnitCFDir "${state_filepath}" "${stack_level}" "${stack_deployment_unit}" "" "${stack_region}" )
              info "${dry_run}Moving ${state_file} to ${du_dir} ..."
              [[ -n "${dry_run}" ]] && continue
              if [[ ! -d "${du_dir}" ]]; then
                mkdir -p "${du_dir}"
              fi
              git_mv "${state_file}" "${du_dir}" || { return_status=1; }
            fi
            ;;
        esac
      done
      [[ "${return_status}" -ne 0 ]] && break
    done
    [[ "${return_status}" -ne 0 ]] && break
  done

  popTempDir

  return $return_status
}

declare -A gen3_compatability
# Entry example:  ["2.0.0"]=">=7.0.0"
gen3_compatability=()

function is_upgrade_compatible() {
  local cmdb_version="$(semver_clean "$1")"; shift
  local gen3_version="$1"; shift

  local compatible_range="${gen3_compatability[${cmdb_version}]}"

  if [[ -n "${compatible_range}" ]]; then

    # Must know the gen3 version
    [[ -z "${gen3_version}" ]] && return 2

    semver_satisfies "${gen3_version}" "${compatible_range}"
    return $?
  fi

  # Upgrade is compatible
  return 0
}

function process_cmdb() {
  local root_dir="$1";shift
  local action="$1";shift
  local gen3_version="$1";shift
  local version_list="$1";shift
  local dry_run="${1:+(Dryrun) }";shift

  declare -a versions
  arrayFromList versions "${version_list}"
  local return_status=0

  # Find all the repos
  readarray -t cmdb_git_repos < <(find "${root_dir}" -type d -name ".git" | sort )

  pushTempDir "${FUNCNAME[0]}_$(fileName "${root_dir}")_XXXXXX"
  local tmp_version_file="$(getTopTempDir)/new_version.json"
  local tmp_result_file="$(getTopTempDir)/new_cmdb.json"

  # Process each one
  for cmdb_git_repo in "${cmdb_git_repos[@]}"; do

    local cmdb_repo="$(filePath "${cmdb_git_repo}")"
    debug "Checking repo ${cmdb_repo} ..."

    local cmdb_version_file="${cmdb_repo}/.cmdb"
    local current_version=""
    local pin_version=""

    if [[ -f "${cmdb_version_file}" ]]; then
      current_version="$(jq -r ".Version.${action^} | select(.!=null)" < "${cmdb_version_file}")"
      pin_version="$(jq -r ".Pin.${action^} | select(.!=null)" < "${cmdb_version_file}")"
      debug "Repo is at ${action,,} version ${current_version:-<not initialised>}"
    else
      echo -n "{}" > "${cmdb_version_file}"
    fi

    [[ -z "${current_version}" ]] && current_version="v0.0.0"

    # Most of the time we expect no upgrade to be required
    local last_check="$(semver_compare "${current_version}" "${versions[-1]}")"
    if [[ "${last_check}" != "-1" ]]; then
      debug "${action^} of repo "${cmdb_repo}" to ${versions[-1]} is not required - skipping all version checks"
      continue
    fi

    for version in "${versions[@]}"; do
      # Nothing to do if not less than version being checked
      local semver_check="$(semver_compare "${current_version}" "${version}")"

      if [[ "${semver_check}" == "-1" ]]; then
        info "${dry_run}${action^} of repo "${cmdb_repo}" to ${version} required ..."
      else
        debug "${action^} of repo "${cmdb_repo}" to ${version} is not required"
        continue
      fi

      # Check if version is pinned
      if [[ -n "${pin_version}" ]]; then
        local pin_check="$(semver_compare "${version}" "${pin_version}")"
        if [[ "${pin_check}" == "1" ]]; then
          warn "${action^} of repo "${cmdb_repo}" to ${version} prevented by pin version ${pin_version}"
          break
        else
          debug "${dry_run}${action^} of repo "${cmdb_repo}" to ${version} permitted by pin version ${pin_version} ..."
        fi
      fi

      # Ensure current gen3 framework version is compatible with the upgrade
      is_upgrade_compatible "${version}" "${gen3_version}"; upgrade_status=$?
      case "${upgrade_status}" in
        2)
          warn "${dry_run}${action^} of repo "${cmdb_repo}" to ${version} requires the GEN3 framework version to be defined. Skipping upgrade process ..."
          break
          ;;
        1)
          warn "${dry_run}${action^} of repo "${cmdb_repo}" to ${version} is not compatible with the current gen3 framework version of ${gen3_version}. Skipping upgrade process ..."
          break
          ;;
      esac

      pushd "${cmdb_repo}" > /dev/null 2>&1
      ${action,,}_cmdb_repo_to_${version//./_} "${cmdb_repo}" "${dry_run}"; return_status=$?
      popd > /dev/null 2>&1

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
  local gen3_version="$1";shift
  local dry_run="$1";shift
  local maximum_version="${1:-v1.3.2}";shift

  local upgrade_order=("v1.0.0" "v1.1.0" "v1.2.0" "v1.3.0" "v1.3.1" "v1.3.2" "v2.0.0" "v2.0.1")

  debug "Maximum CMDB upgrade version required is ${maximum_version}"

  local required_versions="$(semver_upgrade_list "${upgrade_order[*]}" "${maximum_version}")"

  debug "Required CMDB upgrade order is ${required_versions}"

  process_cmdb "${root_dir}" "upgrade" "${gen3_version}" "${required_versions}" ${dry_run}
}

function cleanup_cmdb() {
  local root_dir="$1";shift
  local gen3_version="$1";shift
  local dry_run="$1";shift
  local maximum_version="${1:-v1.1.1}";shift

  local upgrade_order=("v1.0.0" "v1.1.0" "v1.1.1")

  debug "Maximum CMDB cleanup version required is ${maximum_version}"

  local required_versions="$(semver_upgrade_list "${upgrade_order[*]}" "${maximum_version}")"

  debug "Required CMDB cleanup order is ${required_versions}"

  process_cmdb "${root_dir}" "cleanup" "${gen3_version}" "${required_versions}" ${dry_run}
}
