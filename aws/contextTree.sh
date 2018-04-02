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

function assemble_settings() {
  local result_file="${1:-${COMPOSITE_SETTINGS}}";shift
  local root_dir="${1:-${ROOT_DIR}}"

  pushTempDir "assemble_settings_XXX"
  local tmp_dir="$( getCurrentTempDir )"
  local tmp_file_list=()

  local id
  local name
  local tmp_file

  # Process accounts
  readarray -t account_files < <(find "${root_dir}" -name account.json)

  # Settings
  for account_file in "${account_files[@]}"; do

    id="$(getJSONValue "${account_file}" ".Account.Id")"
    name="$(getJSONValue "${account_file}" ".Account.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${ACCOUNT}") && ("${ACCOUNT,,}" != "${name,,}") ]] && continue

    pushd "$(filePath "${account_file}")/appsettings" > /dev/null 2>&1 || continue

    tmp_file="$( getTempFile "account_appsettings_XXX.json" "${tmp_dir}")"
    readarray -t setting_files < <(find . -type f -name "appsettings.json" )
    convertFilesToJSONObject "AppSettings Accounts" "${name}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
    tmp_file_list+=("${tmp_file}")
    popd > /dev/null
  done

  # Process products
  readarray -t product_files < <(find "${root_dir}" -name product.json)

  # Settings
  for product_file in "${product_files[@]}"; do

    id="$(getJSONValue "${product_file}" ".Product.Id")"
    name="$(getJSONValue "${product_file}" ".Product.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${PRODUCT}") && ("${PRODUCT,,}" != "${name,,}") ]] && continue

    pushd "$(filePath "${product_file}")/appsettings" > /dev/null 2>&1 || continue

    # Appsettings
    readarray -t setting_files < <(find . -type f \( -not -name "*build.json" -and -not -path "*/asFile/*" \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_appsettings_XXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "AppSettings Products" "${name}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # Builds
    readarray -t setting_files < <(find . -type f \( -name "*build.json" -and -not -path "*/asFile/*" \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_builds_XXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Builds Products" "${name}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # asFiles
    readarray -t setting_files < <(find . -type f \( -path "*/asFile/*" \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_appsettings_asfile_XXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "AppSettings Products" "${name}" "true" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    popd > /dev/null

  done

  # App credentials
  for product_file in "${product_files[@]}"; do

    id="$(getJSONValue "${product_file}" ".Product.Id")"
    name="$(getJSONValue "${product_file}" ".Product.Name")"
    [[ -z "${name}" ]] && name="${id}"
    [[ (-n "${PRODUCT}") && ("${PRODUCT,,}" != "${name,,}") ]] && continue

    pushd "$(findGen3ProductInfrastructureDir "${root_dir}" "${name}")/credentials" > /dev/null 2>&1 || continue

    # Credentials
    readarray -t setting_files < <(find . -type f \( -name "credentials.json" -and -not -path "*/asFile/*" \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_credentials_XXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Credentials Products" "${name}" "false" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    # asFiles
    readarray -t setting_files < <(find . -type f \( -path "*/asFile/*" \) )
    if ! arrayIsEmpty "setting_files" ; then
      tmp_file="$( getTempFile "product_credentials_asfile_XXX.json" "${tmp_dir}")"
      convertFilesToJSONObject "Credentials Products" "${name}" "true" "${setting_files[@]}" > "${tmp_file}" || return 1
      tmp_file_list+=("${tmp_file}")
    fi

    popd > /dev/null

  done

  # Generate the merged output
  jqMerge "${tmp_file_list[@]}" > "${result_file}"; code=$?
  popTempDir
  return ${code}
}

function assemble_credentials() {
  local result_file="${1:-${COMPOSITE_CREDENTIALS}}"

  pushd "${PRODUCT_CREDENTIALS_DIR}" > /dev/null
  readarray -t files < <(find -name credentials.json)
  convertFilesToJSONObject "" "${PRODUCT}" "${files[@]}" > "${result_file}"
  popd > /dev/null
}

function assemble_composite_stack_outputs() {
  local result_file="${1:-${COMPOSITE_STACK_OUTPUTS}}"

  # Create the composite stack outputs
  local restore_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  local stack_array=()
  [[ (-n "${ACCOUNT}") ]] &&
      addToArray "stack_array" "${ACCOUNT_INFRASTRUCTURE_DIR}"/aws/cf/acc*-stack.json
  [[ (-n "${PRODUCT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}"/aws/cf/product*-"${REGION}"*-stack.json
  [[ (-n "${SEGMENT}") && (-n "${REGION}") ]] &&
      addToArray "stack_array" "${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}"/cf/*-stack.json

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
    echo "[]" > ${result_file}
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

function encrypt_file() {
  local region="$1"; shift
  local level="$1"; shift
  local input_file="$1"; shift
  local output_file="$1"; shift

  local cmk=$(getCmk "${level}")
  local temp_file=

  cp "${input_file}" "./temp_encrypt_file"

  aws --region "${region}" --output text kms encrypt \
    --key-id "${cmk}" --query CiphertextBlob \
    --plaintext "fileb://temp_encrypt_file" > "${output_file}"
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

  local reference="$()"

  echo -n "{\"Reference\" : \"" > "${upgraded_file}"
  cat "${legacy_file}" >> "${upgraded_file}"
  echo -n "\"}" >> "${upgraded_file}"

  return 0
}

function upgrade_credentials() {
  local legacy_file="$1"; shift
  local upgraded_file="$1"; shift

    if [[ "$(jq ".Credentials | length" < "${legacy_file}" )" -gt 0 ]]; then
      runJQ ".Credentials" "${legacy_file}"  > "${upgraded_file}"
    else
      cat "${legacy_file}" > "${upgraded_file}"
    fi
}

function upgrade_cmdb() {
  local root_dir="${1:-${ROOT_DIR}}";shift
  local dry_run="$1";shift

  pushTempDir "upgrade_cmdb_XXX"
  local tmp_dir="$( getCurrentTempDir )"
  local tmp_file

  local upgrade_needed="false"
  local upgrade_succeeded="true"

  # All build references now in json format
  readarray -t legacy_files < <(find "${root_dir}" -type f -name "build.ref" )
  for legacy_file in "${legacy_files[@]}"; do
    upgrade_needed="true"
    trace "Upgrading ${legacy_file} ..."
    tmp_file="$(getTempFile "build_XXX.json" "${tmp_dir}")"
    upgrade_build_ref "${legacy_file}" "${tmp_file}" || { upgrade_succeeded="false"; continue; }

    if [[ -n "${dry_run}" ]]; then
      willLog "trace" && { echo; cat "${tmp_file}"; echo; }
      continue
    fi
    cp "${tmp_file}" "$(filePath "${legacy_file}")/build.json" || { upgrade_succeeded="false"; continue; }
    git_rm "${legacy_file}" || { upgrade_succeeded="false"; continue; }
  done

  # All shared build references now in json format
  readarray -t legacy_files < <(find "${root_dir}" -type f -name "*.ref" )
  for legacy_file in "${legacy_files[@]}"; do
    upgrade_needed="true"
    trace "Upgrading ${legacy_file} ..."
    tmp_file="$(getTempFile "shared_XXX.json" "${tmp_dir}")"
    upgrade_shared_build_ref "${legacy_file}" "${tmp_file}" || { upgrade_succeeded="false"; continue; }

    if [[ -n "${dry_run}" ]]; then
      willLog "trace" && { echo; cat "${tmp_file}"; echo; }
      continue
    fi
    cp "${tmp_file}" "$(filePath "${legacy_file}")/shared_build.json" || { upgrade_succeeded="false"; continue; }
    git_rm "${legacy_file}" || { upgrade_succeeded="false"; continue; }
  done

  # Strip top level "Credentials" attribute from credentials
  readarray -t legacy_files < <(find "${root_dir}" -type f -name "credentials.json" )
  for legacy_file in "${legacy_files[@]}"; do
    if [[ "$(jq ".Credentials | length" < "${legacy_file}" )" -gt 0 ]]; then
      upgrade_needed="true"
      trace "Upgrading ${legacy_file} ..."
      tmp_file="$(getTempFile "credentials_XXX.json" "${tmp_dir}")"
      upgrade_credentials "${legacy_file}" "${tmp_file}" || { upgrade_succeeded="false"; continue; }

      if [[ -n "${dry_run}" ]]; then
        willLog "trace" && { echo; cat "${tmp_file}"; echo; }
        continue
      fi
      cp "${tmp_file}" "${legacy_file}" || { upgrade_succeeded="false"; continue; }
    fi
  done

  # Change of naming from "container" to "segment"
  readarray -t legacy_files < <(find "${root_dir}" -type f -name "container.json" )
  for legacy_file in "${legacy_files[@]}"; do
    upgrade_needed="true"
    trace "Upgrading ${legacy_file} ..."
    tmp_file="$(getTempFile "container_XXX.json" "${tmp_dir}")"
    cp "${legacy_file}" "${tmp_file}" || { upgrade_succeeded="false"; continue; }

    if [[ -n "${dry_run}" ]]; then
      willLog "trace" && { echo; cat "${tmp_file}"; echo; }
      continue
    fi
    git_mv "${legacy_file}" "$(filePath "${legacy_file}")/segment.json" || { upgrade_succeeded="false"; continue; }
  done

  popTempDir

  # Is an upgrade needed?
  if [[ -n "${dry_run}" ]]; then
    [[ "${upgrade_needed}" == "false" ]]
  else
    [[ "${upgrade_succeeded}" == "true" ]]
  fi
  return $?
}
