#!/usr/bin/env bash

# Utility Functions
#
# This script is designed to be sourced into other scripts

# -- Detect is namedef support available
function namedef_supported() {
  [[ "${BASH_VERSION}" =~ ([^.]+)\.([^.]+)\.(.+) ]] || return 1

  [[ (${BASH_REMATCH[1]} -gt 4) || (${BASH_REMATCH[2]} -ge 3) ]]
}

# -- Error handling  --

export LOG_LEVEL_DEBUG="debug"
export LOG_LEVEL_TRACE="trace"
export LOG_LEVEL_INFORMATION="info"
export LOG_LEVEL_WARNING="warn"
export LOG_LEVEL_ERROR="error"
export LOG_LEVEL_FATAL="fatal"

declare -A LOG_LEVEL_ORDER
LOG_LEVEL_ORDER=(
  ["${LOG_LEVEL_DEBUG}"]="0"
  ["${LOG_LEVEL_TRACE}"]="1"
  ["${LOG_LEVEL_INFORMATION}"]="3"
  ["${LOG_LEVEL_WARNING}"]="5"
  ["${LOG_LEVEL_ERROR}"]="7"
  ["${LOG_LEVEL_FATAL}"]="9"
)

function checkLogLevel() {
  local level="$1"

  [[ (-n "${level}") && (-n "${LOG_LEVEL_ORDER[${level}]}") ]] && { echo -n "${level}"; return 0; }
  [[ -n "${GENERATION_DEBUG}" ]] && { echo -n "${LOG_LEVEL_DEBUG}"; return 0; }
  echo -n "${LOG_LEVEL_INFORMATION}"
  return 0
}

# Default implementation - can be overriden by caller
function getLogLevel() {
  checkLogLevel
}

# Default implementation - can be overriden by caller but must honour parameter order
function outputLogEntry() {
  local severity="${1^}"; shift
  local parts=("$@")

  echo -e "\n(${severity})" "${parts[@]}"
  return 0
}

function willLog() {
  local severity="$1"

  [[ ${LOG_LEVEL_ORDER[$(getLogLevel)]} -le ${LOG_LEVEL_ORDER[${severity}]} ]]
}

function message() {
  local severity="$1"; shift
  local parts=("$@")

  if willLog "${severity}"; then
    outputLogEntry "${severity}" "${parts[@]}"
  else
    return 0
  fi
}

function locationMessage() {
  local restore_nullglob=$(shopt -p nullglob)
  local restore_globstar=$(shopt -p globstar)
  shopt -u nullglob globstar

  echo -n "$@" "Are we in the right place?"

  ${restore_nullglob}
  ${restore_globstar}
}

function cantProceedMessage() {
  echo -n "$@" "Nothing to do."
}

function debug() {
  message "${LOG_LEVEL_DEBUG}" "$@"
}

function trace() {
  message "${LOG_LEVEL_TRACE}" "$@"
}

function info() {
  message "${LOG_LEVEL_INFORMATION}" "$@"
}

function warning() {
  message "${LOG_LEVEL_WARNING}" "$@"
}

function error() {
  message "${LOG_LEVEL_ERROR}" "$@" >&2
}

function fatal() {
  message "${LOG_LEVEL_FATAL}" "$@" >&2
}

function fatalOption() {
  local option="${1:-${OPTARG}}"

  fatal "Invalid option: \"-${option}\""
}

function fatalOptionArgument() {
  local option="${1:-${OPTARG}}"

  fatal "Option \"-${option}\" requires an argument"
}

function fatalCantProceed() {
  fatal "$(cantProceedMessage "$@")"
}

function fatalLocation() {
  local restore_nullglob=$(shopt -p nullglob)
  local restore_globstar=$(shopt -p globstar)
  shopt -u nullglob globstar

  fatal "$(locationMessage "$@")"

  ${restore_nullglob}
  ${restore_globstar}
}

function fatalDirectory() {
  local name="$1"; shift

  fatalLocation "We don\'t appear to be in the ${name} directory."
}

function fatalMandatory() {
  fatal "Mandatory arguments missing. Check usage via -h option."
}

# -- String manipulation --

function join() {
  local IFS="$1"; shift
  echo -n "$*"
}

function contains() {
  local string="$1"; shift
  local pattern="$1"; shift

  [[ "${string}" =~ ${pattern} ]]
}

function generateComplexString() { 
  # String suitable for a password - Alphanumeric and special characters
  local length="$1"; shift 

  echo "$(dd bs=256 count=1 if=/dev/urandom | base64 | env LC_CTYPE=C tr -dc '[:punct:][:alnum:]' | tr -d '@"/'  | fold -w "${length}" | head -n 1)" || return $?
}

function generateSimpleString() { 
  # Simple string - Alphanumeric only
  local length="$1"; shift 

  echo "$(dd bs=256 count=1 if=/dev/urandom | base64 | env LC_CTYPE=C tr -dc '[:alnum:]' | fold -w "${length}" | head -n 1)" || return $?
}

# -- File manipulation --

function formatPath() {
  join "/" "$@"
}

function filePath() {
  local file="$1"; shift

  contains "${file}" "/" &&
    echo -n "${file%/*}" ||
    echo -n ""
}

function fileName() {
  local file="$1"; shift

  echo -n "${file##*/}"
}

function fileBase() {
  local file="$1"; shift

  local name="$(fileName "${file}")"
  echo -n "${name%.*}"
}

function fileExtension() {
  local file="$1"; shift

  local name="$(fileName "${file}")"
  echo -n "${name##*.}"
}

function fileContents() {
  local file="$1"; shift

  [[ -f "${file}" ]] && cat "${file}"
}

function fileContentsInEnv() {
  local env="$1"; shift
  local files=("$@"); shift

  for file in "${files[@]}"; do
    if [[ -f "${file}" ]]; then
      declare -gx ${env}="$(fileContents "${file}")"
      break
    fi
  done
}

function findAncestorDir() {
  local ancestor="$1"; shift
  local current="${1:-$(pwd)}"

  while [[ -n "${current}" ]]; do
    # Ancestor can either be a directory or a marker file
    if [[ ("$(fileName "${current}")" == "${ancestor}") ||
            ( -f "${current}/${ancestor}" ) ]]; then
      echo -n "${current}"
      return 0
    fi
    current="$(filePath "${current}")"
  done

  return 1
}

function findDir() {
  local root_dir="$1"; shift
  local patterns=("$@")

  local restore_nullglob="$(shopt -p nullglob)"
  local restore_globstar="$(shopt -p globstar)"
  shopt -s nullglob globstar

  local matches=()
  for pattern in "${patterns[@]}"; do
    matches+=("${root_dir}"/**/${pattern})
  done

  ${restore_nullglob}
  ${restore_globstar}

  for match in "${matches[@]}"; do
    [[ -f "${match}" ]] && echo -n "$(filePath "${match}")" && return 0
    [[ -d "${match}" ]] && echo -n "${match}" && return 0
  done

  return 1
}

function findFile() {

  local restore_nullglob="$(shopt -p nullglob)"
  local restore_globstar="$(shopt -p globstar)"
  shopt -s nullglob globstar

  # Note that any spaces in file specs must be escaped
  local matches=($@)

  ${restore_nullglob}
  ${restore_globstar}

  for match in "${matches[@]}"; do
    [[ -f "${match}" ]] && echo -n "${match}" && return 0
  done

  return 1
}

function findFiles() {

  local restore_nullglob="$(shopt -p nullglob)"
  local restore_globstar="$(shopt -p globstar)"
  shopt -s nullglob globstar

  # Note that any spaces in file specs must be escaped
  local matches=($@)

  ${restore_nullglob}
  ${restore_globstar}

  local file_match="false"

  for match in "${matches[@]}"; do
    if [[ -f "${match}" ]]; then
      echo "${match}"
      local file_match="true"
    fi
  done

  if [[ "${file_match}" == "true" ]]; then
    return 0
  fi

  return 1
}

# -- Array manipulation --

function inArray() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi
  local pattern="$1"

  contains "${array[*]}" "${pattern}"
}

function arrayFromList() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    local array=()
  fi
  local list="$1"; shift
  local separators="${1:- ,}"

  # Handle situation of multi-line inputs e.g. from Jenkins multi-line string parameter plugin
  readarray -t list_lines <<< "${list}"

  IFS="${separators}" read -ra array <<< "$(join "${separators:0:1}" "${list_lines[@]}" )"
  if ! namedef_supported; then
    eval "${array_name}=(\"\${array[@]}\")"
  fi
}

function arrayFromCommand() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    local array=()
  fi
  local command="$1"; shift

  readarray -t array < <(${command})
  if ! namedef_supported; then
    eval "${array_name}=(\"\${array[@]}\")"
  fi
}

function listFromArray() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi

  local separators="${1:- ,}"

  join "${separators}" "${array[@]}"
}

function arraySize() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi

  echo -n "${#array[@]}"
}

function arrayIsEmpty() {
  local array="$1";

  [[ $(arraySize "${array}") -eq 0 ]]
}

function reverseArray() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi
  local target="$1"; shift

  if [[ -n "${target}" ]]; then
    if namedef_supported; then
      local -n result="${target}"
    else
      local result=()
    fi
  else
    local result=()
  fi

  result=()
  for (( index=${#array[@]}-1 ; index>=0 ; index-- )) ; do
    result+=("${array[index]}")
  done

  if [[ (-n "${target}") ]]; then
    if ! namedef_supported; then
      eval "${target}=(\"\${result[@]}\")"
    fi
  else
    if namedef_supported; then
      array=("${result[@]}")
    else
      eval "${array_name}=(\"\${result[@]}\")"
    fi
  fi
}

function addToArrayInternal() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi
  local type="$1"; shift
  local prefix="$1"; shift
  local elements=("$@")

  for element in "${elements[@]}"; do
    if [[ -n "${element}" ]]; then
      [[ "${type,,}" == "stack" ]] &&
        array=("${prefix}${element}" "${array[@]}") ||
        array+=("${prefix}${element}")
    fi
  done

  ! namedef_supported && eval "${array_name}=(\"\${array[@]}\")"
}

function removeFromArrayInternal() {
  if namedef_supported; then
    local -n array="$1"; shift
  else
    local array_name="$1"; shift
    eval "local array=(\"\${${array_name}[@]}\")"
  fi
  local type="$1"; shift
  local count="${1:-1}"; shift

  local remaining=$(( ${#array[@]} - ${count} ))
  [[ ${remaining} -lt 0 ]] && remaining=0

  [[ "${type,,}" == "stack" ]] &&
    array=("${array[@]:${count}}") ||
    array=("${array[@]:0:${remaining}}")

  ! namedef_supported && eval "${array_name}=(\"\${array[@]}\")"
}

function addToArray() {
  local array="$1"; shift
  local elements=("$@")

  addToArrayInternal "${array}" "array" "" "${elements[@]}"
}

function addToArrayHead() {
  local array="$1"; shift
  local elements=("$@")

  addToArrayInternal "${array}" "stack" "" "${elements[@]}"
}

function removeFromArray() {
  local array="$1"; shift
  local count="$1"; shift

  removeFromArrayInternal "${array}" "array" "${count}"
}

function removeFromArrayHead() {
  local array="$1"; shift
  local count="$1"; shift

  removeFromArrayInternal "${array}" "stack" "${count}"
}

function pushStack() {
  local array="$1"; shift
  local elements=("$@")

  addToArrayHead "${array}" "${elements[@]}"
}

function popStack() {
  local array="$1"; shift
  local count="$1"; shift

  removeFromArrayHead "${array}" "${count}"
}

# -- Temporary file management --

# OS Temporary directory
function getOSTempRootDir() {
  uname | grep -iq "MINGW64" &&
    echo -n "c:/tmp" ||
    echo -n "$(filePath $(mktemp -u -t tmp.XXXXXXXXXX))"
}

# Default implementation - can be overriden by caller
function getTempRootDir() {
  getOSTempRootDir
}

function getTempDir() {
  local template="$1"; shift
  local temp_path="$1"; shift

  [[ -z "${template}" ]] && template="XXX"
  [[ -z "${temp_path}" ]] && temp_path="$(getTempRootDir)"

  [[ -n "${temp_path}" ]] &&
    mktemp -d "${temp_path}/${template}" ||
    mktemp -d "$(getOSTempRootDir)/${template}"
}

export tmp_dir_stack=()

function pushTempDir() {
  local template="$1"; shift

  local tmp_dir="$( getTempDir "${template}" "${tmp_dir_stack[0]}" )"

  pushStack "tmp_dir_stack" "${tmp_dir}"
}

function popTempDir() {
  local count="${1:-1}"; shift

  local index=$(( $count - 1 ))
  local tmp_dir="${tmp_dir_stack[@]:${index}:1}"

  popStack "tmp_dir_stack" "${count}"
}

function getCurrentTempDir() {
  echo -n "${tmp_dir_stack[@]:0:1}"
}

function getTempFile() {
  local template="$1"; shift
  local temp_path="$1"; shift

  [[ -z "${template}" ]] && template="XXX"
  [[ -z "${temp_path}" ]] && temp_path="$(getTempRootDir)"

  [[ -n "${temp_path}" ]] &&
    mktemp    "${temp_path}/${template}" ||
    mktemp -t "${template}"
}

function cleanup() {
  local root_dir="${1:-.}"

  find "${root_dir}" -name "composite_*" -delete
  find "${root_dir}" -name "STATUS.txt" -delete
  find "${root_dir}" -name "stripped_*" -delete
  find "${root_dir}" -name "ciphertext*" -delete
  find "${root_dir}" -name "temp_*" -type f -delete

  # Handle cleanup of temporary directories
  temp_dirs=($(find "${root_dir}" -name "temp_*" -type d))
  for temp_dir in "${temp_dirs[@]}"; do
    # Subdir may already have been deleted by parent temporary directory
    if [[ -e "${temp_dir}" ]]; then
      rm -rf "${temp_dir}"
    fi
  done
}

# -- JSON manipulation --

function runJQ() {
  local arguments=("$@")

  # TODO(mfl): remove once path length limitations in jq are fixed

  local file_seen="false"
  local tmp_dir="."
  local modified_arguments=()

  for argument in "${arguments[@]}"; do
    if [[ -f "${argument}" ]]; then
      if [[ "${file_seen}" != "true" ]]; then
        pushTempDir "runjq_XXX"
        local tmp_dir="$( getCurrentTempDir )"
        file_seen="true"
      fi
      local file="$( getTempFile "XXX" "${tmp_dir}" )"
      cp "${argument}" "${file}" > /dev/null
      modified_arguments+=("./$(fileName "${file}" )")
    else
      modified_arguments+=("${argument}")
    fi
  done

  # TODO(mfl): Add -L once path length limitations fixed
  (cd ${tmp_dir}; jq "${modified_arguments[@]}"); code=$?
  [[ "${file_seen}" == "true" ]] && popTempDir
  return ${code}
}

function jqMergeFilter() {
  local files=("$@")

  local command_line=""
  local index=0

  for f in "${files[@]}"; do
    [[ "${index}" > 0 ]] && command_line+=" * "
    command_line+=".[${index}]"
    index=$(( $index + 1 ))
  done

  echo -n "${command_line}"
}

function jqMerge() {
  local files=("$@")

  if [[ "${#files[@]}" -gt 0 ]]; then
    runJQ -s "$( jqMergeFilter "${files[@]}" )" "${files[@]}"
  else
    echo -n "{}"
    return 0
  fi
}

function getJSONValue() {
  local file="$1"; shift
  local patterns=("$@")

  local value=""

  for pattern in "${patterns[@]}"; do
    value="$(runJQ -r "${pattern} | select (.!=null)" < "${file}")"
    [[ -n "${value}" ]] && echo -n "${value}" && return 0
  done

  return 1
}

function addJSONAncestorObjects() {
  local file="$1"; shift
  local ancestors=("$@")

  # Reverse the order of the ancestors
  local pattern="."

  for (( index=${#ancestors[@]}-1 ; index >= 0 ; index-- )) ; do
    [[ -n "${ancestors[index]}" ]] && pattern="{\"${ancestors[index]}\" : ${pattern} }"
  done

  runJQ "${pattern}" < "${file}"
}

function convertFilesToJSONObject() {
  local base_ancestors=($1); shift
  local prefixes=($1); shift
  local as_file="$1";shift
  local files=("$@")

  pushTempDir "convertFilesToJSONObject_XXX"
  local tmp_dir="$( getCurrentTempDir )"
  local base_file="${tmp_dir}/base.json"
  local processed_files=("${base_file}")

  echo -n "{}" > "${base_file}"

  for file in "${files[@]}"; do

    local source_file="${file}"
    local attribute="$( fileBase "${file}" | tr "-" "_" )"

    if [[ "${as_file}" == "true" ]]; then
      source_file="$(getTempFile "asfile_${attribute,,}_XXX.json" "${tmp_dir}")"
      echo -n "{\"${attribute^^}\" : {\"Value\" : \"$(fileName "${file}")\", \"AsFile\" : \"${file}\" }}" > "${source_file}" || return 1
    else
      case "$(fileExtension "${file}")" in
        json)
          ;;

        escjson)
          source_file="$(getTempFile "escjson_${attribute,,}_XXX.json" "${tmp_dir}")"
          runJQ \
            "{\"${attribute^^}\" : {\"Value\" : tojson, \"FromFile\" : \"${file}\" }}" \
            "${file}" > "${source_file}" || return 1
          ;;

        *)
          # Assume raw input
          source_file="$(getTempFile "raw_${attribute,,}_XXX.json" "${tmp_dir}")"
          runJQ -sR \
            "{\"${attribute^^}\" : {\"Value\" : ., \"FromFile\" : \"${file}\" }}" \
            "${file}" > "${source_file}" || return 1
          ;;

      esac
    fi

    local file_ancestors=("${prefixes[@]}" $(filePath "${file}" | tr "./" " ") )
    local processed_file="$(getTempFile "processed_XXX.json" "${tmp_dir}")"
    addJSONAncestorObjects "${source_file}" "${base_ancestors[@]}" $(join "-" "${file_ancestors[@]}") > "${processed_file}" || return 1
    processed_files+=("${processed_file}")
  done

  jqMerge "${processed_files[@]}"; code=$?
  popTempDir
  return ${code}
}

# -- KMS --
function decrypt_kms_string() { 
  local value="$1"; shift

  local tmpdir="$( getTempDir "kms_XXX" )"
  local file="$( getTempFile "XXX" "${tmpdir}" )"
  echo "${value}" | base64 --decode > "${file}"
  aws kms decrypt --ciphertext-blob fileb://${file} --output text --query Plaintext | base64 --decode || return $?
}

function encrypt_kms_string() { 
  local region="$1"; shift
  local value="$1"; shift 
  local kms_key_id="$1"; shift 

  aws kms encrypt --key-id "${kms_key_id}" --plaintext "${value}" --query CiphertextBlob --output text || return $?
}

# -- S3 --

function isBucketAccessible() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift

  local result_file="$( getTempFile "s3_access_XXX.txt")"

  aws --region ${region} s3 ls "s3://${bucket}/${prefix}${prefix:+/}" > "${result_file}"
  return $?
}

function copyFilesFromBucket() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift
  local dir="$1"; shift
  local optional_arguments=("$@")

  aws --region ${region} s3 cp --recursive "${optional_arguments[@]}" "s3://${bucket}/${prefix}${prefix:+/}" "${dir}/"
}

function syncFilesToBucket() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift
  if namedef_supported; then
    local -n syncFiles="$1"; shift
  else
    eval "local syncFiles=(\"\${${1}[@]}\")"; shift
  fi
  local optional_arguments=("$@")

  local tmp_dir="$( getTempDir "s3_sync_XXX")"


  # Copy files locally so we can synch with S3, potentially including deletes
  for file in "${syncFiles[@]}" ; do
    if [[ -f "${file}" ]]; then
      case "$(fileExtension "${file}")" in
        zip)
          unzip "${file}" -d "${tmp_dir}"
          ;;
        *)
          cp "${file}" "${tmp_dir}"
          ;;
      esac
    fi
  done

  # Now synch with s3
  aws --region ${region} s3 sync "${optional_arguments[@]}" "${tmp_dir}/" "s3://${bucket}/${prefix}${prefix:+/}"
}

function deleteTreeFromBucket() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift
  local optional_arguments=("$@")

  # Delete everything below the prefix
  aws --region "${region}" s3 rm "${optional_arguments[@]}" --recursive "s3://${bucket}/${prefix}/"
}

# -- PKI --
function create_pki_credentials() {
  local dir="$1"; shift

  if [[ (! -f "${dir}/aws-ssh-crt.pem") &&
        (! -f "${dir}/aws-ssh-prv.pem") ]]; then
      openssl genrsa -out "${dir}/aws-ssh-prv.pem.plaintext" 2048 || return $?
      openssl rsa -in "${dir}/aws-ssh-prv.pem.plaintext" -pubout > "${dir}/aws-ssh-crt.pem" || return $?
  fi

  if [[ ! -f "${dir}/.gitignore" ]]; then
    cat << EOF > "${dir}/.gitignore"
*.plaintext
*.decrypted
*.ppk
EOF
  fi

  return 0
}

function delete_pki_credentials() {
  local dir="$1"; shift

  local restore_nullglob="$(shopt -p nullglob)"
  shopt -s nullglob

  rm -f "${dir}"/aws-ssh-crt* "${dir}"/aws-ssh-prv*

  ${restore_nullglob}
}

# -- SSH --

function update_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift
  local crt_file="$1"; shift

  local crt_content=

  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}" > /dev/null 2>&1 ||
    { crt_content=$(dos2unix < "${crt_file}" | awk 'BEGIN {RS="\n"} /^[^-]/ {printf $1}'); \
    aws --region "${region}" ec2 import-key-pair --key-name "${name}" --public-key-material "${crt_content}"; }

  # Show the current credential
  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}"
}

function delete_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift

  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}" > /dev/null 2>&1 && \
    { aws --region "${region}" ec2 delete-key-pair --key-name "${name}" || return $?; }

  return 0
}

# -- OAI --

function update_oai_credentials() {
  local region="$1"; shift
  local name="$1"; shift
  local result_file="${1:-$( getTempFile update_oai_XXX.json)}"; shift

  local oai_list_file="$( getTempFile oai_list_XXX.json)"
  local oai_id=

  # Check for existing identity
  aws --region "${region}" cloudfront list-cloud-front-origin-access-identities > "${oai_list_file}" || return $?
  jq ".CloudFrontOriginAccessIdentityList.Items[] | select(.Comment==\"${name}\")" < "${oai_list_file}" > "${result_file}" || return $?
  oai_id=$(jq -r ".Id" < "${result_file}") || return $?

  # Create if not there already
  if [[ -z "${oai_id}" ]]; then
    set -o pipefail
    aws --region "${region}" cloudfront create-cloud-front-origin-access-identity \
      --cloud-front-origin-access-identity-config "{\"Comment\" : \"${name}\", \"CallerReference\" : \"${name}\"}" | jq ".CloudFrontOriginAccessIdentity" > "${result_file}" || return $?
    set +o pipefail
  fi

  # Show the current credential
  cat "${result_file}"

  return 0
}

function delete_oai_credentials() {
  local region="$1"; shift
  local name="$1"; shift

  local oai_delete_file="$( getTempFile oai_delete_XXX.json)"
  local oai_id=
  local oai_etag=

  # Check for existing identity
  aws --region "${region}" cloudfront list-cloud-front-origin-access-identities > "${oai_delete_file}" || return $?
  oai_id=$(jq -r ".CloudFrontOriginAccessIdentityList.Items[] | select(.Comment==\"${name}\") | .Id" < "${oai_delete_file}") || return $?

  # delete if present
  if [[ -n "${oai_id}" ]]; then
    # Retrieve the ETag value
    aws --region "${region}" cloudfront get-cloud-front-origin-access-identity --id "${oai_id}" > "${oai_delete_file}" || return $?
    oai_etag=$(jq -r ".ETag" < "${oai_delete_file}") || return $?
    # Delete the OAI
    aws --region "${region}" cloudfront delete-cloud-front-origin-access-identity --id "${oai_id}" --if-match "${oai_etag}" || return $?
  fi

  return 0
}

# -- RDS --
function create_snapshot() {
  local region="$1"; shift
  local db_identifier="$1"; shift
  local db_snapshot_identifier="$1"; shift

  # Check that the database exists
  db_info=$(aws --region "${region}" rds describe-db-instances --db-instance-identifier ${db_identifier} )

  if [[ -n "${db_info}" ]]; then
    aws --region "${region}" rds create-db-snapshot --db-snapshot-identifier "${db_snapshot_identifier}" --db-instance-identifier "${db_identifier}" 1> /dev/null || return $?
    aws --region "${region}" rds wait db-snapshot-available --db-snapshot-identifier "${db_snapshot_identifier}"  || return $?
    db_snapshot=$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" || return $?)
  fi
  info "Snapshot Created - $(echo "${db_snapshot}" | jq -r '.DBSnapshots[0] | .DBSnapshotIdentifier + " " + .SnapshotCreateTime' )"
}

function encrypt_snapshot() { 
  local region="$1"; shift
  local db_snapshot_identifier="$1"; shift
  local kms_key_id="$1"; shift 

  # Check the snapshot status 
  snapshot_info=$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" || return $? )

  if [[ -n "${snapshot_info}" ]]; then 
    if [[ $(echo "${snapshot_info}" | jq -r '.DBSnapshots[0].Status == "Available"') ]]; then

      if [[ $(echo "${snapshot_info}" | jq -r '.DBSnapshots[0].Encrypted') == false ]]; then 

        info "Converting snapshot ${db_snapshot_identifier} to an encrypted snapshot"

        # create encrypted snapshot
        aws --region "${region}" rds copy-db-snapshot \
          --source-db-snapshot-identifier "${db_snapshot_identifier}" \
          --target-db-snapshot-identifier "encrypted-${db_snapshot_identifier}" \
          --kms-key-id "${kms_key_id}" 1> /dev/null || return $?

        info "Waiting for temp encrypted snapshot to become available..."
        sleep 2
        aws --region "${region}" rds wait db-snapshot-available --db-snapshot-identifier "encrypted-${db_snapshot_identifier}" || return $?

        info "Removing plaintext snapshot..."
        # delete the original snapshot
        aws --region "${region}" rds delete-db-snapshot --db-snapshot-identifier "${db_snapshot_identifier}"  1> /dev/null || return $?
        aws --region "${region}" rds wait db-snapshot-deleted --db-snapshot-identifier "${db_snapshot_identifier}"  || return $? 

        # Copy snapshot back to original identifier
        info "Renaming encrypted snapshot..."
        aws --region "${region}" rds copy-db-snapshot \
          --source-db-snapshot-identifier "encrypted-${db_snapshot_identifier}" \
          --target-db-snapshot-identifier "${db_snapshot_identifier}" 1> /dev/null || return $?
        
        sleep 2
        aws --region "${region}" rds wait db-snapshot-available --db-snapshot-identifier "${db_snapshot_identifier}"  || return $?
        
        # Remove the encrypted temp snapshot
        aws --region "${region}" rds delete-db-snapshot --db-snapshot-identifier "encrypted-${db_snapshot_identifier}"  1> /dev/null || return $?
        aws --region "${region}" rds wait db-snapshot-deleted --db-snapshot-identifier "encrypted-${db_snapshot_identifier}"  || return $? 

        db_snapshot=$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" || return $?)
        info "Snapshot Converted - $(echo "${db_snapshot}" | jq -r '.DBSnapshots[0] | .DBSnapshotIdentifier + " " + .SnapshotCreateTime + " Encrypted: " + (.Encrypted|tostring)' )"

        return 0

      else 

        echo "Snapshot ${db_snapshot_identifier} already encrypted"
        return 0
        
      fi
    
    else 
      echo "Snapshot not in a usuable state $(echo "${snapshot_info}")"
      return 255 
    fi
  fi
}

function set_rds_master_password() { 
  local region="$1"; shift
  local db_identifier="$1"; shift
  local password="$1"; shift 

  info "Resetting master password for RDS instance ${db_identifier}"
  aws --region "${region}" rds modify-db-instance --db-instance-identifier ${db_identifier} --master-user-password "${password}" 1> /dev/null || return $?
}

# -- Git Repo Management --
function in_git_repo() {
  git status >/dev/null 2>&1
}

function clone_git_repo() {
  local repo_provider="$1"; shift
  local repo_host="$1"; shift
  local repo_path="$1"; shift
  local repo_branch="$1"; shift
  local local_dir="$1";

  [[  (-z "${repo_provider}") ||
      (-z "${repo_host}") ||
      (-z "${repo_path}") ||
      (-z "${repo_branch}") ||
      (-z "${local_dir}") ]] && fatalMandatory && return 1

  local credentials_var="${repo_provider^^}_CREDENTIALS"
  local repo_url="https://${!credentials_var}@${repo_host}/${repo_path}"

  trace "Cloning the ${repo_url} repo and checking out the ${repo_branch} branch ..."

  git clone -b "${repo_branch}" "${repo_url}" "${local_dir}"
  RESULT=$? && [[ ${RESULT} -ne 0 ]] && fatal "Can't clone ${repo_url} repo" && return 1

  return 0
}

function push_git_repo() {
  local repo_url="$1"; shift
  local repo_branch="$1"; shift
  local repo_remote="$1"; shift
  local commit_message="$1"; shift
  local git_user="$1"; shift
  local git_email="$1";

    [[ (-z "${repo_url}") ||
        (-z "${repo_branch}") ||
        (-z "${repo_remote}") ||
        (-z "${commit_message}") ||
        (-z "${git_user}") ||
        (-z "${git_email}") ]] && fatalMandatory && return 1

    git remote show "${repo_remote}" >/dev/null 2>&1
    RESULT=$? && [[ ${RESULT} -ne 0 ]] && fatal "Remote ${repo_remote} is not initialised" && return 1

    # Ensure git knows who we are
    git config user.name  "${git_user}"
    git config user.email "${git_email}"

    # Add anything that has been added/modified/deleted
    git add -A

    if [[ -n "$(git status --porcelain)" ]]; then
        # Commit changes
        trace "Committing to the ${repo_url} repo..."
        git commit -m "${commit_message}"
        RESULT=$? && [[ ${RESULT} -ne 0 ]] && fatal "Can't commit to the ${repo_url} repo" && return 1

        REPO_PUSH_REQUIRED="true"
    fi

    # Update upstream repo
    if [[ "${REPO_PUSH_REQUIRED}" == "true" ]]; then
        trace "Pushing the ${repo_url} repo upstream..."
        git push ${repo_remote} ${repo_branch}
        RESULT=$? && [[ ${RESULT} -ne 0 ]] && \
            fatal "Can't push the ${repo_url} repo changes to upstream repo ${repo_remote}" && return 1
    fi

  return 0
}

function git_mv() {
  in_git_repo && git mv "$@" || mv "$@"
}

function git_rm() {
  in_git_repo && git rm "$@" || rm "$@"
}

