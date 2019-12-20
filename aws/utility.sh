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

function information() {
  message "${LOG_LEVEL_INFORMATION}" "$@"
}

function info() {
  information "$@"
}

function warning() {
  message "${LOG_LEVEL_WARNING}" "$@"
}

function warn() {
  warning "$@"
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

  echo "$(dd bs=256 count=1 if=/dev/urandom | base64 | env LC_CTYPE=C tr -dc '[:punct:][:alnum:]' | tr -d '@"/+'  | fold -w "${length}" | head -n 1)" || return $?
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
    if [[ "${#matches[@]}" -gt 0 ]]; then
      break
    fi
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
  return 0
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
  return 0
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
  local tmp_dir="$1"; shift

  [[ -z "${template}" ]] && template="XXXXXX"
  [[ -z "${tmp_dir}" ]] && tmp_dir="$(getTempRootDir)"

  [[ -n "${tmp_dir}" ]] &&
    mktemp -d "${tmp_dir}/${template}" ||
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

  # Popped value not returned but keep the code here for now
  local index=$(( $count - 1 ))
  local tmp_dir="${tmp_dir_stack[@]:${index}:1}"

  popStack "tmp_dir_stack" "${count}"
}

function getTopTempDir() {
  echo -n "${tmp_dir_stack[@]:0:1}"
}

function getTempFile() {
  local template="$1"; shift
  local tmp_dir="$1"; shift

  [[ -z "${template}" ]] && template="XXXXXX"
  [[ -z "${tmp_dir}" ]] && tmp_dir="$(getTempRootDir)"

  [[ -n "${tmp_dir}" ]] &&
    mktemp    "${tmp_dir}/${template}" ||
    mktemp -t "${template}"
}

# -- Cli file generation --
function split_cli_file() {
  local cli_file="$1"; shift
  local outdir="$1"; shift

  for resource in $( jq -r 'keys[]' <"${cli_file}" ) ; do
    for command in $( jq -r ".$resource | keys[]"<"${cli_file}" ); do
        jq ".${resource}.${command}" >"${outdir}/cli-${resource}-${command}.json" <"${cli_file}"
    done
  done
}

# -- JSON manipulation --

function runJQ() {
  local arguments=("$@")

  # TODO(mfl): remove once path length limitations in jq are fixed

  local file_seen="false"
  local file
  local tmp_dir="."
  local modified_arguments=()
  local return_status

  for argument in "${arguments[@]}"; do
    if [[ -f "${argument}" ]]; then
      if [[ "${file_seen}" != "true" ]]; then
        pushTempDir "${FUNCNAME[0]}_XXXXXX"
        tmp_dir="$(getTopTempDir)"
        file_seen="true"
      fi
      file="$( getTempFile "XXXXXX" "${tmp_dir}" )"
      cp "${argument}" "${file}" > /dev/null
      modified_arguments+=("./$(fileName "${file}" )")
    else
      modified_arguments+=("${argument}")
    fi
  done

  # TODO(mfl): Add -L once path length limitations fixed
  (cd ${tmp_dir}; jq "${modified_arguments[@]}"); return_status=$?
  [[ "${file_seen}" == "true" ]] && popTempDir
  return ${return_status}
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

# -- KMS --
function decrypt_kms_string() {
  local region="$1"; shift
  local value="$1"; shift

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local tmp_file="$(getTopTempDir)/value"
  local return_status

  echo "${value}" | base64 --decode > "${tmp_file}"
  aws --region "${region}" kms decrypt --ciphertext-blob "fileb://${tmp_file}" --output text --query Plaintext | base64 --decode; return_status=$?

  popTempDir
  return ${return_status}
}

function encrypt_kms_string() {
  local region="$1"; shift
  local value="$1"; shift
  local kms_key_id="$1"; shift

  aws --region "${region}" kms encrypt --key-id "${kms_key_id}" --plaintext "${value}" --query CiphertextBlob --output text
}

function encrypt_kms_file() {
  local region="$1"; shift
  local input_file="$1"; shift
  local output_file="$1"; shift
  local kms_key_id="$1"; shift

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local tmp_dir="$(getTopTempDir)"
  local return_status

  cp "${input_file}" "${tmp_dir}/encrypt_file" || return_status=255

  if [[ -z "${return_status}" ]]; then
    (cd "${tmp_dir}"; aws --region "${region}" --output text kms encrypt \
      --key-id "${kms_key_id}" --query CiphertextBlob \
      --plaintext "fileb://encrypt_file" > "${output_file}"; return_status=$?)
  fi

  popTempDir

  return ${return_status}
}

# -- IAM --
function create_iam_accesskey() {
  local region="$1"; shift
  local username="$1"; shift

  accesskey="$(aws --region "${region}" iam create-access-key --user-name "${username}" )" || return $?

  if [[ -n "${accesskey}" ]]; then
    access_key_id="$( echo "${accesskey}" | jq -r '.AccessKey.AccessKeyId')"
    secret_access_key="$( echo "${accesskey}" | jq -r '.AccessKey.SecretAccessKey')"

    echo "${access_key_id} ${secret_access_key}"
    return 0

  else
    fatal "Could not generate accesskey for ${username}"
    return 255
  fi
}

function get_iam_smtp_password() {
  local secretkey="$1"; shift

  (echo -en "\x02"; echo -n 'SendRawEmail' \
  | openssl dgst -sha256 -hmac $secretkey -binary) \
  | openssl enc -base64
}

function manage_iam_userpassword() {
  local region="$1"; shift
  local action="$1"; shift
  local username="$1"; shift
  local password="$1"; shift

  login_profile="$(aws --region "${region}" iam get-login-profile --user-name "${username}" --query 'LoginProfile.UserName' --output text 2>/dev/null )"

  case "${action}" in
    delete)
      if [[ "${login_profile}" == "${username}" ]]; then
        aws --region "${region}" iam delete-login-profile --user-name "${username}" || return $?
      fi
      ;;

    *)
      if [[ "${login_profile}" != "${username}" ]]; then
        aws --region "${region}" iam create-login-profile --user-name "${username}" --password "${password}" --no-password-reset-required || return $?
      else
        aws --region "${region}" iam update-login-profile --user-name "${username}" --password "${password}" --no-password-reset-required || return $?
      fi
      ;;
  esac
  return 0
}

# -- CloudWatch Events --
function delete_cloudwatch_event() {
    local region="$1"; shift
    local ruleName="$1"; shift
    local includeRule="$1"; shift

    local return_status=0

    if [[ -n "$(aws --region "${region}" events list-rules --query "Rules[?Name == '$ruleName'].Name" --output text)" ]]; then

      rule_targets="$( aws --region "${region}" events list-targets-by-rule --rule "${ruleName}" --query "Targets[*].Id | join(' ',@)" --output text)"
      if [[ -n "${rule_targets}" ]]; then
        aws --region "${region}" events remove-targets --rule "${ruleName}" --ids ${rule_targets} || return $?
      fi

      if [[ "${includeRule}" == "true" ]]; then
        aws --region "${region}" events delete-rule --name "${ruleName}" || return $?
      fi

    fi

    return ${return_status}
}

function create_cloudwatch_event () {
  local region="$1"; shift
  local ruleName="$1"; shift
  local eventRoleId="$1"; shift
  local ruleConfigFile="$1"; shift
  local targetConfigFile="$1"; shift

  local return_status=0

  if [[ "${eventRoleId}" != arn:* ]]; then
    eventRoleArn="$(get_cloudformation_stack_output "${region}" "${cfnStackName}" "${eventRoleId}" "arn" || return $?)"
  else
    eventRoleArn="${eventRoleId}"
  fi

  arnLookupTargetConfigFile="$(filePath ${targetConfigFile})/ArnLookup-$(fileBase ${targetConfigFile})"
  jq --arg eventRoleArn "${eventRoleArn}" '.Targets[0].RoleArn= $eventRoleArn' < "${targetConfigFile}" > "${arnLookupTargetConfigFile}"

  delete_cloudwatch_event "${region}" "${ruleName}" "false" || return $?
  aws --region "${region}" events put-rule --name "${ruleName}" --cli-input-json "file://${ruleConfigFile}" || return $?
  aws --region "${region}" events put-targets --rule "${ruleName}" --cli-input-json "file://${arnLookupTargetConfigFile}" || return $?

  return ${return_status}
}

# -- CloudFormation --
function get_cloudformation_stack_output() {
  local region="$1"; shift
  local stackName="$1"; shift
  local resourceId="$1"; shift
  local attributeType="$1"; shift

  if [[ -z "${attributeType}" || "${attributeType}" == "ref" ]]; then
    stackOutputKey="${resourceId}"
  else
    stackOutputKey="${resourceId}X${attributeType}"
  fi

  stack_id="$(aws --region "${region}" cloudformation list-stacks --stack-status-filter "CREATE_COMPLETE" "UPDATE_COMPLETE" --query "StackSummaries[?StackName == '$stackName'].StackId" --output text || return $?)"
  if [[ -n "${stack_id}" ]]; then
    aws --region "${region}" cloudformation describe-stacks --stack-name "${stackName}" --query "Stacks[*].Outputs[?OutputKey == '${stackOutputKey}'].OutputValue" --output text || return $?
  fi
}

# -- Content Node --
function copy_contentnode_file() {
  local files="$1"; shift
  local engine="$1"; shift
  local path="$1"; shift
  local prefix="$1"; shift
  local nodepath="$1"; shift
  local branch="$1"; shift
  local copymode="$1"; shift

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
                if [[ ! -d "${contentnodedir}" ]]; then
                  mkdir -p "${contentnodedir}"
                fi
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
              if [[ -d "${hubpath}" && "${copymode}" == "replace" ]]; then
                rm -rf "${hubpath}" || return $?
              fi
              mkdir -p "${hubpath}"
              cp -R ${contentnodedir}/* ${hubpath} || return $?
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

# -- Cognito --

function update_cognito_userpool() {
  local region="$1"; shift
  local userpoolid="$1"; shift
  local configfile="$1"; shift

  aws --region "${region}" cognito-idp update-user-pool --user-pool-id "${userpoolid}" --cli-input-json "file://${configfile}"
}

function update_cognito_userpool_client() {
  local region="$1"; shift
  local userpoolid="$1"; shift
  local userpoolclientid="$1"; shift
  local configfile="$1"; shift

  aws --region "${region}" cognito-idp update-user-pool-client --user-pool-id "${userpoolid}" --client-id "${userpoolclientid}" --cli-input-json "file://${configfile}"
}

function update_cognito_userpool_authprovider() {
  local region="$1"; shift
  local userpoolid="$1"; shift
  local authprovidername="$1"; shift
  local authprovidertype="$1"; shift
  local encryption_scheme="$1"; shift
  local oidc_client_secret="$1"; shift
  local configfile="$1"; shift

  if [[ "${authprovidertype}" == "OIDC" ]]; then
    if [[ "${oidc_client_secret}" == "${encryption_scheme}"* ]]; then
        decrypted_oidc_client_secret="$( decrypt_kms_string "${region}" "${oidc_client_secret#${encryption_scheme}}" || return $? )"
    else
        decrypted_oidc_client_secret="${oidc_client_secret}"
    fi

    jq --arg client_secret "${decrypted_oidc_client_secret}" -r '.ProviderDetails.client_secret=$client_secret' < "${configfile}" > "${configfile}_clientsecret" || return $?

    if [[ -f "${configfile}_clientsecret" ]]; then
      mv "${configfile}_clientsecret" "${configfile}"
    fi
  fi

  current_provider_type="$(aws --region "${region}" cognito-idp describe-identity-provider --user-pool-id "${userpoolid}" --provider-name "${authprovidername}" --query "IdentityProvider.ProviderType" --output text 2>/dev/null || true )"

  if [[ -n "${current_provider_type}" && ( "${current_provider_type}" != "${authprovidertype}" ) ]]; then
    # delete the provider if the type is different
    aws --region "${region}" cognito-idp delete-identity-provider --user-pool-id "${userpoolid}" --provider-name "${authprovidername}" || return $?
  fi

  if [[ -z "${current_provider_type}" || ( "${current_provider_type}" != "${authprovidertype}" ) ]]; then
    # create the provider
    aws --region "${region}" cognito-idp create-identity-provider --user-pool-id "${userpoolid}" --provider-name "${authprovidername}" --provider-type "${authprovidertype}" --cli-input-json "file://${configfile}" || return $?
  fi

  if [[ "${current_provider_type}" == "${authprovidertype}" ]]; then
    # update the provider
    aws --region "${region}" cognito-idp update-identity-provider --user-pool-id "${userpoolid}" --provider-name "${authprovidername}" --cli-input-json "file://${configfile}" || return $?
  fi

}

function cleanup_cognito_userpool_authproviders() {
  local region="$1"; shift
  local userpoolid="$1"; shift
  local expectedproviders="$1"; shift
  local removeall="$1"; shift

  current_providers="$(aws --region "${region}" cognito-idp list-identity-providers --user-pool-id "${userpoolid}" --query "Providers[*].ProviderName" --output text)"

  if [[ "${current_providers}" != "None" && -n "${current_providers}" ]]; then
    arrayFromList expected_provider_list "${expectedproviders}"
    arrayFromList current_provider_list "${current_providers}"

    for provider in "${current_provider_list[@]}"; do
      if [[ $( ! inArray "expected_provider_list" "${provider}" ) || "${removeall}" == "true" ]]; then
        info "Removing auth provider ${provider} from ${userpoolid}"
        aws --region "${region}" cognito-idp delete-identity-provider --user-pool-id "${userpoolid}" --provider-name "${provider}" || return $?
      fi
    done

  else
    info "No providers found moving on.."
  fi
}

function manage_cognito_userpool_domain() {
  local region="$1"; shift
  local userpoolid="$1"; shift
  local configfile="$1"; shift
  local action="$1"; shift
  local domaintype="$1"; shift

  local return_status=0

  domain="$( jq -r '.Domain' < $configfile )"
  domain_userpool="$( aws --region ${region} cognito-idp describe-user-pool-domain --domain ${domain} --query "DomainDescription.UserPoolId" --output text )"

  if [[ "${domain_userpool}" == "None" ]]; then

    case "${action}" in
        create)
            info "Adding domain to userpool"

            case "${domaintype}" in
              internal)
                userpool_domain="$(aws --region ${region} cognito-idp describe-user-pool --user-pool-id "${userpoolid}" --query "UserPool.Domain" --output text)"
                ;;
              custom)
                userpool_domain="$(aws --region ${region} cognito-idp describe-user-pool --user-pool-id "${userpoolid}" --query "UserPool.CustomDomain" --output text)"
                ;;
            esac

            if [[ "${userpool_domain}" != "${domain}" && "${userpool_domain}" != "None" && -n "${userpool_domain}" ]]; then
              aws --region "${region}" cognito-idp delete-user-pool-domain --user-pool-id "${userpoolid}" --domain "${userpool_domain}" || return $?
            fi

            if [[ ( "${userpool_domain}" == "None" || "${userpool_domain}" != "${domain}" ) && -n "${userpool_domain}" ]]; then
              aws --region "${region}" cognito-idp create-user-pool-domain --user-pool-id "${userpoolid}" --cli-input-json "file://${configfile}" || return $?
              return_status=$?
            fi
            ;;
        delete)
            info "Domain not assigned to a userpool. Nothing to do"
            ;;
    esac

  elif [[ "${domain_userpool}" != "${userpoolid}" ]]; then
    error "User Pool Domain ${domain} is used by userpool ${domain_userpool}"
    return_status=255

  else
    case "${action}" in
        create)
            info "User Pool domain already configured"
            ;;
        delete)
            info "Deleting domain from user pool"
            aws --region "${region}" cognito-idp delete-user-pool-domain --user-pool-id "${userpoolid}" --domain "${domain}" || return $?
            ;;
    esac
  fi

  return ${return_status}
}

function get_cognito_userpool_custom_distribution() {
  local region="$1"; shift
  local domain="${1}"; shift

  aws --region "${region}" cognito-idp describe-user-pool-domain --domain ${domain} --query "DomainDescription.CloudFrontDistribution" --output text || return $?
}

# -- Data Pipeline --
function create_data_pipeline() {
  local region="$1"; shift
  local configfile="$1"; shift

  pipeline="$(aws --region "${region}" datapipeline create-pipeline --cli-input-json "file://${configfile}" || return $?)"
  if [[ -n "${pipeline}" ]]; then
    echo "${pipeline}" | jq -r '.pipelineId | select (.!=null)'
    return 0

  else
    fatal "Could not create pipeline"
    return 255
  fi
}

function update_data_pipeline() {
  local region="$1"; shift
  local pipelineid="$1"; shift
  local definitionfile="$1"; shift
  local parameterobjectfile="$1"; shift
  local parametervaluefile="$1"; shift
  local cfnStackName="$1"; shift
  local securityGroupId="$1"; shift

  # Add resources created during stack creation
  securityGroup="$(get_cloudformation_stack_output "${region}" "${cfnStackName}" "${securityGroupId}" "ref" || return $?)"

  arnLookupValueFile="$(filePath ${parametervaluefile})/ArnLookup-$(fileBase ${parametervaluefile})"
  jq --arg pipelineRole "${pipelineRole}" --arg resourceRole "${resourceRole}" --arg securityGroup "${securityGroup}" '.values.my_SECURITY_GROUP_ID = $securityGroup ' < "${parametervaluefile}" > "${arnLookupValueFile}"

  pipeline_details="$(aws --region "${region}" datapipeline put-pipeline-definition --pipeline-id "${pipelineid}" --pipeline-definition "file://${definitionfile}" --parameter-objects "file://${parameterobjectfile}" --parameter-values-uri "file://${arnLookupValueFile}" )"
  pipeline_errored="$(echo "${pipeline_details}" | jq -r '.errored ')"

  if [[ "${pipeline_errored}" == "false" ]]; then
    info "Pipeline definition update successful"
    info "${pipeline_details}"
    return 0
  else
    fatal "Pipeline definition did not work as expected"
    fatal "${pipeline_details}"
    return 255
  fi
}

#-- DynamoDB --
function upsert_dynamodb_item() {
  local region="$1"; shift
  local tableName="$1"; shift
  local configfile="$1"; shift
  local cfnStackName="$1"; shift

  aws --region "${region}" dynamodb update-item --table-name "${tableName}" --return-values "UPDATED_NEW" --cli-input-json "file://${configfile}" || return $?

  return 0
}

function scan_dynamodb_table() {
  local region="$1"; shift
  local tableName="$1"; shift
  local configfile="$1"; shift
  local cfnStackName="$1"; shift

  items="$(aws --region "${region}" dynamodb scan --table-name "${tableName}" --cli-input-json "file://${configfile}" --query "Items[*]" --output json || return $? )"

  # return each item as a new line
  items="$( echo "${items}" | jq -c '.[]' )"

  echo "${items}"

  return 0
}

function delete_dynamodb_items() {
  local region="$1"; shift
  local tableName="$1"; shift
  local itemKeys="$1"; shift
  local cfnStackName="$1"; shift

  arrayFromList items_to_delete "${itemKeys}"

  for item in "${items_to_delete[@]}"; do
    aws --region "${region}" dynamodb delete-item --table-name "${tableName}" --key "${item}" || return $?
  done
}

#-- ECS --
function create_ecs_scheduled_task() {
  local region="$1"; shift
  local ruleName="$1"; shift
  local ruleConfigFile="$1"; shift
  local targetConfigFile="$1"; shift
  local cfnStackName="$1"; shift
  local taskId="$1"; shift
  local eventRoleId="$1"; shift
  local securityGroupId="$1"; shift

  ecsTaskArn="$(get_cloudformation_stack_output "${region}" "${cfnStackName}" "${taskId}" "arn" || return $?)"
  securityGroup="$(get_cloudformation_stack_output "${region}" "${cfnStackName}" "${securityGroupId}" "ref" || return $?)"

  arnLookupConfigFile="$(filePath ${targetConfigFile})/ArnLookup-$(fileBase ${targetConfigFile})"
  jq --arg ecsTaskArn "${ecsTaskArn}" --arg securityGroup "$securityGroup" '.Targets[0].EcsParameters.TaskDefinitionArn = $ecsTaskArn | .Targets[0].EcsParameters.NetworkConfiguration.awsvpcConfiguration.SecurityGroups = [ $securityGroup ]' < "${targetConfigFile}" > "${arnLookupConfigFile}"

  create_cloudwatch_event "${region}" "${ruleName}" "${eventRoleId}" "${ruleConfigFile}" "${arnLookupConfigFile}"  || return $?

  return 0
}

# -- ElasticSearch --
function update_es_domain() {
  local region="$1"; shift
  local esid="$1"; shift
  local configfile="$1"; shift

  aws --region "${region}" es update-elasticsearch-domain-config --domain-name "${esid}" --cli-input-json "file://${configfile}" || return $?
}

# -- Elastic Load Balancing --
function create_elbv2_rule() {
  local region="$1"; shift
  local listenerid="$1"; shift
  local configfile="$1"; shift

  rule_arn="$(aws --region "${region}" elbv2 create-rule --listener-arn "${listenerid}" --cli-input-json "file://${configfile}" --query 'Rules[0].RuleArn' --output text || return $? )"

  if [[ "${rule_arn}" == "None" ]]; then
    fatal "Rule was not created"
    return 255
  else
    echo "${rule_arn}"
    return 0
  fi
}

function cleanup_elbv2_rules() {
  local region="$1"; shift
  local listenerarn="$1"; shift

  pushTempDir "elbv2_listener_cleanup_XXXXXX"
  local tmp_file="$(getTopTempDir)/cleanup.sh"

  all_listener_rules="$(aws --region "${region}" elbv2 describe-rules --listener-arn "${listenerarn}" --query 'Rules[?!IsDefault].RuleArn' --output json )"

  info "Removing all listener rules from ${listenerarn}"
  if [[ -n "${all_listener_rules}" ]]; then
    echo "${all_listener_rules}" | jq --arg region "${region}" -r '.[] | "aws --region \($region) elbv2 delete-rule --rule-arn \(.) || { status=$?; popTempDir; return $status; }"' > "${tmp_file}"
    if [[ -f "${tmp_file}" ]]; then
      chmod u+x "${tmp_file}"
      "${tmp_file}"
    fi
  fi

  popTempDir
  return 0
}


# -- S3 --

function isBucketAccessible() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift

  local result_file="$(getTopTempDir)/is_bucket_accessible_XXXXXX.txt"

  aws --region ${region} s3 ls "s3://${bucket}/${prefix}${prefix:+/}" > "${result_file}" 2>&1
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

  # Does the bucket/prefix exist?
  if isBucketAccessible "${region}" "${bucket}"; then
    pushTempDir "${FUNCNAME[0]}_XXXXXX"
    local tmp_dir="$(getTopTempDir)"
    local return_status

    # Copy files locally so we can synch with S3, potentially including deletes
    for file in "${syncFiles[@]}" ; do
      if [[ -f "${file}" ]]; then
        case "$(fileExtension "${file}")" in
          zip)
            # Always use local time to force redeploy of files
            # in case we are reverting to an earlier version
            unzip -DD "${file}" -d "${tmp_dir}"
            ;;
          *)
            cp "${file}" "${tmp_dir}"
            ;;
        esac
      fi
    done

    # Now synch with s3
    aws --region ${region} s3 sync "${optional_arguments[@]}" "${tmp_dir}/" "s3://${bucket}/${prefix}${prefix:+/}"; return_status=$?

    popTempDir
    return ${return_status}
  fi
  return 0
}

function deleteTreeFromBucket() {
  local region="$1"; shift
  local bucket="$1"; shift
  local prefix="$1"; shift
  local optional_arguments=("$@")

  # Does the bucket/prefix exist?
  isBucketAccessible "${region}" "${bucket}" "${prefix}" || return 0

  # Delete everything below the prefix
  aws --region "${region}" s3 rm "${optional_arguments[@]}" --recursive "s3://${bucket}/${prefix}${prefix:+/}"
}

function deleteBucket() {
  local region="$1"; shift
  local bucket="$1"; shift
  local optional_arguments=("$@")

  # Does the bucket exist?
  isBucketAccessible "${region}" "${bucket}" || return 0

  # Delete the bucket
  aws --region "${region}" s3 rb "${optional_arguments[@]}" "s3://${bucket}" --force
}

# -- SNS --
function deploy_sns_platformapp() {
  local region="$1"; shift
  local name="$1"; shift
  local existing_arn="$1"; shift
  local encryption_scheme="$1"; shift
  local engine="$1"; shift
  local configfile="$1"; shift

  platform_principal="$(jq -rc '.Attributes.PlatformPrincipal | select (.!=null)' < "${configfile}" )"
  platform_credential="$(jq -rc '.Attributes.PlatformCredential | select (.!=null)' < "${configfile}" )"

  #Decrypt the principal and certificate if they are encrypted
  if [[ "${platform_principal}" == "${encryption_scheme}"* ]]; then
      decrypted_platform_principal="$( decrypt_kms_string "${region}" "${platform_principal#${encryption_scheme}}" || return $? )"
  else
      decrypted_platform_principal="${platform_principal}"
  fi

  if [[ "${platform_credential}" == "${encryption_scheme}"* ]]; then
    decrypted_platform_credential="$( decrypt_kms_string "${region}" "${platform_credential#${encryption_scheme}}" || return $? )"
  else
    decrypted_platform_credential="${platform_credential}"
  fi

  jq -rc '. | del(.Attributes.PlatformPrincipal) | del(.Attributes.PlatformCredential)' < "${configfile}" > "${configfile}_decrypted"

  if [[ -n "${existing_arn}" ]]; then
    platform_app_arn="${existing_arn}"
    update_platform_app="$(aws --region "${region}" sns set-platform-application-attributes --platform-application-arn "${platform_app_arn}" --attributes PlatformPrincipal="${decrypted_platform_principal}",PlatformCredential="${decrypted_platform_credential}"  || return $? )"
  else
    platform_app_arn="$(aws --region "${region}" sns create-platform-application --name "${name}" \
      --attributes PlatformPrincipal="${decrypted_platform_principal}",PlatformCredential="${decrypted_platform_credential}" \
      --platform="${engine}" --query 'PlatformApplicationArn' --output text )"
  fi

  update_platform_app="$(aws --region "${region}" sns set-platform-application-attributes --platform-application-arn "${platform_app_arn}" --cli-input-json "file://${configfile}_decrypted"  || return $? )"

  if [[ -z "${platform_app_arn}" ]]; then
    fatal "Platform app was not deployed"
    return 255
  else
    echo "${platform_app_arn}"
    return 0
  fi

}

function delete_sns_platformapp() {
  local region="$1"; shift
  local arn="$1"; shift

  aws --region "${region}" sns delete-platform-application --platform-application-arn "${arn}" || return $?
}

function cleanup_sns_platformapps() {
  local region="$1"; shift
  local mobile_notifier_name="$1"; shift
  local expected_platform_arns="$1"; shift

  pushTempDir "${mobile_notifier_name}_cleanup_XXXXXX"
  local tmp_file="$(getTopTempDir)/cleanup.sh"

  all_platform_apps="$(aws --region "${region}" sns list-platform-applications )"
  current_platform_arns="$(echo "${all_platform_apps}" | jq --arg namefilter "${mobile_notifier_name}" -rc '.PlatformApplications[] | select( .PlatformApplicationArn | endswith("/" + $namefilter)) | [ .PlatformApplicationArn ]')"

  if [[ -n "${current_platform_arns}" ]]; then
    unexpected_platform_arns="$(echo "${expected_platform_arns}" | jq --argjson currentarns "${current_platform_arns}" '. - $currentarns')"
    info "Found the following unexpected Platforms: ${unexpected_platform_arns}"
    echo "${unexpected_platform_arns}" | jq --arg region "${region}" -r '.[] | "delete_sns_platform \($region) \(.)"' > "${tmp_file}"

    if [[ -f "${tmp_file}" ]]; then
      chmod u+x "${tmp_file}"
      "${tmp_file}"
    fi
  fi

  popTempDir
  return $?
}

function update_sms_account_attributes() {
  local region="$1"; shift
  local configfile="$1"; shift

  aws --region "${region}" sns set-sms-attributes --cli-input-json "file://${configfile}" || return $?
}

# -- PKI --
function create_pki_credentials() {
  local dir="$1"; shift
  local region="$1"; shift
  local account="$1"; shift
  local publickeyname="$1"; shift
  local privatekeyname="$1"; shift

  if [[ (! -f "${dir}/aws-ssh-crt.pem") &&
        (! -f "${dir}/aws-ssh-prv.pem") &&
        (! -f "${dir}/.aws-ssh-crt.pem") &&
        (! -f "${dir}/.aws-ssh-prv.pem") &&
        (! -f "${dir}/.aws-${account}-${region}-ssh-crt.pem") &&
        (! -f "${dir}/.aws-${account}-${region}-ssh-prv.pem") ]]; then
      openssl genrsa -out "${dir}/${privatekeyname}.plaintext" 2048 || return $?
      openssl rsa -in "${dir}/${privatekeyname}.plaintext" -pubout > "${dir}/${publickeyname}" || return $?
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
  local region="$1"; shift
  local account="$1"; shift
  local publickeyname="$1"; shift
  local privatekeyname="$1"; shift

  local restore_nullglob="$(shopt -p nullglob)"
  shopt -s nullglob

  rm -f "${dir}"/.aws-${account}-${region}-ssh-crt* "${dir}"/.aws-${account}-${region}-ssh-prv* "${dir}"/${publickeyname}* "${dir}"/${privatekeyname}*

  ${restore_nullglob}
}
# -- SSH --

function check_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift

  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}" > /dev/null 2>&1
}

function show_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift

  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}"
}

function update_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift
  local crt_file="$1"; shift

  local crt_content=$(dos2unix < "${crt_file}" | awk 'BEGIN {RS="\n"} /^[^-]/ {printf $1}')
  aws --region "${region}" ec2 import-key-pair --key-name "${name}" --public-key-material "${crt_content}"
}

function delete_ssh_credentials() {
  local region="$1"; shift
  local name="$1"; shift

  aws --region "${region}" ec2 describe-key-pairs --key-name "${name}" > /dev/null 2>&1 && \
    { aws --region "${region}" ec2 delete-key-pair --key-name "${name}" || return $?; }

  return 0
}


# -- SSM --

function update_ssm_document() {
  local region="$1"; shift
  local name="$1"; shift
  local version="$1"; shift
  local contentfile="$1"; shift

  local currentHash="$(aws ssm describe-document --region "${region}" --name "${name}" --document-version "${version}" --query 'Document.Hash' --output text || return $?)"
  local newHash="$(shasum -a 256 ${contentfile} | cut -d " " -f 1 || return $?)"

  if [[ "${currentHash}" != "${newHash}" ]]; then
    aws ssm update-document --region "${region}" --name "${name}" --document-version "${version}" --content "file://${contentfile}" || return $?
  else
    info "No changes required"
  fi

  return $?
}

# -- OAI --

function update_oai_credentials() {
  local region="$1"; shift
  local name="$1"; shift
  local result_file="${1:-$( getTempFile update_oai_XXXXXX.json)}"; shift

  local oai_list_file="$( getTempFile oai_list_XXXXXX.json)"
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

  local oai_delete_file="$( getTempFile oai_delete_XXXXXX.json)"
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

function add_tag_rds_resource() {
  local region="$1"; shift
  local rds_identifier="$1"; shift
  local key="${1}"; shift
  local value="${1}"; shift

  aws --region "${region}" rds add-tags-to-resource --resource-name "${rds_identifier}" --tags "Key=${key},Value=${value}" || return $?

}

function create_snapshot() {
  local region="$1"; shift
  local db_type="$1"; shift
  local db_identifier="$1"; shift
  local db_snapshot_identifier="$1"; shift

  # Check that the database exists
  if [[ "${db_type}" == "cluster" ]]; then
    db_info=$(aws --region "${region}" rds describe-db-clusters --db-cluster-identifier ${db_identifier} )

    if [[ -n "${db_info}" ]]; then
      aws --region "${region}" rds create-db-cluster-snapshot --db-cluster-snapshot-identifier "${db_snapshot_identifier}"  --db-cluster-identifier "${db_identifier}" 1> /dev/null || return $?
    else
      info "Could not find db ${db_identifier} - Skipping pre-deploy snapshot"
      return 0
    fi

    sleep 5s
    while [ "${exit_status}" != "0" ]
    do
        SNAPSHOT_STATE="$(aws --region "${region}" rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier "${db_snapshot_identifier}" --query 'DBClusterSnapshots[0].Status' || return $? )"
        SNAPSHOT_PROGRESS="$(aws --region "${region}" rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier "${db_snapshot_identifier}" --query 'DBClusterSnapshots[0].PercentProgress' || return $? )"
        info "Snapshot id ${db_snapshot_identifier} creation: state is ${SNAPSHOT_STATE}, ${SNAPSHOT_PROGRESS}%..."

        aws --region "${region}" rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier "${db_snapshot_identifier}"
        exit_status="$?"
    done

    db_snapshot=$(aws --region "${region}" rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier "${db_snapshot_identifier}" || return $?)
    info "Snapshot Created - $(echo "${db_snapshot}" | jq -r '.DBClusterSnapshots[0] | .DBSnapshotIdentifier + " " + .SnapshotCreateTime' )"

  else
    db_info=$(aws --region "${region}" rds describe-db-instances --db-instance-identifier ${db_identifier} )

    if [[ -n "${db_info}" ]]; then
      aws --region "${region}" rds create-db-snapshot --db-snapshot-identifier "${db_snapshot_identifier}"  --db-instance-identifier "${db_identifier}" 1> /dev/null || return $?
    else
      info "Could not find db ${db_identifier} - Skipping pre-deploy snapshot"
      return 0
    fi

    sleep 5s
    while [ "${exit_status}" != "0" ]
    do
        SNAPSHOT_STATE="$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" --query 'DBSnapshots[0].Status' || return $? )"
        SNAPSHOT_PROGRESS="$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" --query 'DBSnapshots[0].PercentProgress' || return $? )"
        info "Snapshot id ${db_snapshot_identifier} creation: state is ${SNAPSHOT_STATE}, ${SNAPSHOT_PROGRESS}%..."

        aws --region "${region}" rds wait db-snapshot-available --db-snapshot-identifier "${db_snapshot_identifier}"
        exit_status="$?"
    done

    db_snapshot=$(aws --region "${region}" rds describe-db-snapshots --db-snapshot-identifier "${db_snapshot_identifier}" || return $?)
    info "Snapshot Created - $(echo "${db_snapshot}" | jq -r '.DBSnapshots[0] | .DBSnapshotIdentifier + " " + .SnapshotCreateTime' )"
  fi
}

function encrypt_snapshot() {
  local region="$1"; shift
  local db_type="$1"; shift
  local db_snapshot_identifier="$1"; shift
  local kms_key_id="$1"; shift

  if [[ "${db_type}" == "cluster" ]]; then
    # Check the snapshot status
    snapshot_info=$(aws --region "${region}" rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier "${db_snapshot_identifier}" || return $? )

    if [[ -n "${snapshot_info}" ]]; then
      if [[ $(echo "${snapshot_info}" | jq -r '.DBClusterSnapshots[0].Status == "available"') ]]; then

        if [[ $(echo "${snapshot_info}" | jq -r '.DBClusterSnapshots[0].StorageEncrypted') == false ]]; then

          info "Converting snapshot ${db_snapshot_identifier} to an encrypted snapshot"

          # create encrypted snapshot
          aws --region "${region}" rds copy-db-cluster-snapshot \
            --source-db-cluster-snapshot-identifier "${db_snapshot_identifier}" \
            --target-db-cluster-snapshot-identifier "encrypted-${db_snapshot_identifier}" \
            --kms-key-id "${kms_key_id}" 1> /dev/null || return $?

          info "Waiting for temp encrypted snapshot to become available..."
          sleep 2
          aws --region "${region}" rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier "encrypted-${db_snapshot_identifier}" || return $?

          info "Removing plaintext snapshot..."
          # delete the original snapshot
          aws --region "${region}" rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier "${db_snapshot_identifier}"  1> /dev/null || return $?
          aws --region "${region}" rds wait db-cluster-snapshot-deleted --db-cluster-snapshot-identifier "${db_snapshot_identifier}"  || return $?

          # Copy snapshot back to original identifier
          info "Renaming encrypted snapshot..."
          aws --region "${region}" rds copy-db-cluster-snapshot \
            --source-db-cluster-snapshot-identifier "encrypted-${db_snapshot_identifier}" \
            --target-db-cluster-snapshot-identifier "${db_snapshot_identifier}" 1> /dev/null || return $?

          sleep 2
          aws --region "${region}" rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier "${db_snapshot_identifier}"  || return $?

          # Remove the encrypted temp snapshot
          aws --region "${region}" rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier "encrypted-${db_snapshot_identifier}"  1> /dev/null || return $?
          aws --region "${region}" rds wait db-cluster-snapshot-deleted --db-cluster-snapshot-identifier "encrypted-${db_snapshot_identifier}"  || return $?

          db_snapshot=$(aws --region "${region}" rds describe-db-cluster-snapshots --db-cluster-snapshot-identifier "${db_snapshot_identifier}" || return $?)
          info "Snapshot Converted - $(echo "${db_snapshot}" | jq -r '.DBClusterSnapshots[0] | .DBClusterSnapshotIdentifier + " " + .SnapshotCreateTime + " Encrypted: " + (.StorageEncrypted|tostring)' )"

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

  else

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
  fi
}

function set_rds_master_password() {
  local region="$1"; shift
  local db_type="$1"; shift
  local db_identifier="$1"; shift
  local password="$1"; shift

  info "Resetting master password for RDS instance ${db_identifier}"
  if [[ "${db_type}" == "cluster" ]]; then
    aws --region "${region}" rds modify-db-cluster --db-cluster-identifier "${db_identifier}" --master-user-password "${password}" 1> /dev/null
  else
    aws --region "${region}" rds modify-db-instance --db-instance-identifier ${db_identifier} --master-user-password "${password}" 1> /dev/null
  fi
}

function get_rds_hostname() {
  local region="$1"; shift
  local db_type="$1"; shift
  local db_identifier="$1"; shift
  local db_endpoint_type="$1"; shift

  if [[ "${db_type}" == "cluster" ]]; then
    if [[ "${db_endpoint_type}" == "read" ]]; then
        hostname="$(aws --region "${region}" rds describe-db-clusters --db-cluster-identifier ${db_identifier} --query 'DBClusters[0].ReaderEndpoint' --output text)"
    else
        hostname="$(aws --region "${region}" rds describe-db-clusters --db-cluster-identifier ${db_identifier} --query 'DBClusters[0].Endpoint' --output text)"
    fi
  else
    hostname="$(aws --region "${region}" rds describe-db-instances --db-instance-identifier ${db_identifier} --query 'DBInstances[0].Endpoint.Address' --output text)"
  fi

  if [[ "${hostname}" != "None" ]]; then
    echo "${hostname}"
    return 0
  else
    fatal "hostname not found for rds instance ${db_identifier}"
    return 255
  fi
}

function check_rds_snapshot_username() {
  local region="$1"; shift
  local db_snapshot_identifier="$1"; shift
  local expected_username="$1"; shift

  info "Checking snapshot username matches expected username"

  snapshot_info="$(aws --region ${region} rds describe-db-snapshots --include-shared --include-public --db-snapshot-identifier ${db_snapshot_identifier} || return $? )"

  if [[ -n "${snapshot_info}" ]]; then
    snapshot_username="$( echo "${snapshot_info}" | jq -r '.DBSnapshots[0].MasterUsername' )"

    if [[ "${snapshot_username}" != "${expected_username}" ]]; then

      error "Snapshot Username does not match the expected username"
      error "Update the RDS username configuration to match the snapshot username"
      error "    Snapshot username: ${snapshot_username}"
      error "    Configured username: ${expected_username}"
      return 128

    else

      info "Snapshot Username is the same as the expected username"
      return 0

    fi
  else

    error "Snapshot ${db_snapshot_identifier} - Not Found"
    return 255

  fi
}

function get_rds_url() {
  local scheme="$1"; shift
  local username="$1"; shift
  local password="$1"; shift
  local fqdn="$1"; shift
  local port="$1"; shift
  local database_name="$1"; shift

  echo "${scheme}://${username}:${password}@${fqdn}:${port}/${database_name}"
}

function update_rds_ca_identifier() {
  local region="$1"; shift
  local db_identifier="$1"; shift
  local ca_identifier="$1"; shift

  info "Updating CA for RDS instance ${db_identifier} to ${ca_identifier}"
  aws --region "${region}" rds wait db-instance-available --db-instance-identifier "${db_identifier}" || return $?
  aws --region "${region}" rds modify-db-instance --apply-immediately --db-instance-identifier ${db_identifier} --ca-certificate-identifier "${ca_identifier}" 1> /dev/null || return $?
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

# -- semver handling --
# Comparisons/naming roughly aligned to https://github.com/npm/node-semver
# in case we want to replace these routines with calls to this package via
# docker

function semver_valid {
  local version="$1"

  [[ "$version" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\-([^+]+))?(\+(.*))?$ ]] ||
    { echo -n "?"; return 1; }

  local major=${BASH_REMATCH[1]}
  local minor=${BASH_REMATCH[2]}
  local patch=${BASH_REMATCH[3]}
  local prere=${BASH_REMATCH[5]}
  local build=${BASH_REMATCH[7]}

  echo -n ${major} ${minor} ${patch} ${prere} ${build}
  return 0
}

# Strip any leading "v" (note we handle leading = in semver_satisfies)
# Convert any range indicators ("x" or "X") to 0
# * not supported as substitute for x
function semver_clean {
  local version="$1"

  # Handle the full format
  if [[ "$version" =~ ^v?(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)(\-([^+]+))?(\+(.*))?$ ]]; then

    local major="$(echo ${BASH_REMATCH[1]} | tr "xX" "0")"
    local minor="$(echo ${BASH_REMATCH[2]} | tr "xX" "0")"
    local patch="$(echo ${BASH_REMATCH[3]} | tr "xX" "0")"
    local prere=${BASH_REMATCH[5]}
    local build=${BASH_REMATCH[7]}

    echo -n "${major}.${minor}.${patch}${prere:+-}${prere}${build:++}${build}"
    return 0
  fi

  # Handle major.minor
  if [[ "$version" =~ ^v?(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)$ ]]; then

    local major="$(echo ${BASH_REMATCH[1]} | tr "xX" "0")"
    local minor="$(echo ${BASH_REMATCH[2]} | tr "xX" "0")"

    echo -n "${major}.${minor}.0"
    return 0
  fi

  # Handle major
  if [[ "$version" =~ ^v?(0|[1-9][0-9]*|x|X)$ ]]; then

    local major="$(echo ${BASH_REMATCH[1]} | tr "xX" "0")"

    echo -n "${major}.0.0"
    return 0
  fi

  # Not valid
  echo -n "?"
  return 1
}

function semver_compare {
  local v1="$(semver_clean "$1")"; shift
  local v2="$(semver_clean "$1")"; shift

  semver_valid "${v1}" > /dev/null &&
      semver_valid "${v2}" > /dev/null ||
      { echo -n "?"; return 1; }

  local v1_components=($(semver_valid "${v1}"))
  local v2_components=($(semver_valid "${v2}"))

  # MAJOR, MINOR and PATCH should compare numericaly
  for i in 0 1 2; do
    local diff=$((${v1_components[$i]} - ${v2_components[$i]}))
    if [[ ${diff} -lt 0 ]]; then
      echo -n -1; return 0
    elif [[ ${diff} -gt 0 ]]; then
      echo -n 1; return 0
    fi
  done

  # PREREL should compare with the ASCII order.
  if [[ -z "${v1_components[3]}" ]] && [[ -n "${v2_components[3]}" ]]; then
    echo -n -1; return 0;
  elif [[ -n "${v1_components[3]}" ]] && [[ -z "${v2_components[3]}" ]]; then
    echo -n 1; return 0;
  elif [[ -n "${v1_components[3]}" ]] && [[ -n "${v2_components[3]}" ]]; then
    if [[ "${v1_components[3]}" > "${v2_components[3]}" ]]; then
      echo -n 1; return 0;
    elif [[ "${v1_components[3]}" < "${v2_components[3]}" ]]; then
      echo -n -1; return 0;
    fi
  fi

  echo -n 0
}

# a range is a list of comparator sets joined by "||"" or "|", true if one of sets is true
# a comparator set is a list of comparators, true if all comparators are true
# a comparator is an operator and a version
function semver_satisfies {
  local version="$1"; shift
  local range=$@

  # First determine the comparator sets
  # Standardise on single "|" as separator
  declare -a comparator_sets
  arrayFromList comparator_sets "${range//||/|}" "|"

  for comparator_set in "${comparator_sets[@]}"; do
    debug "Checking comparator set \"${comparator_set}\" ..."

    # Now determine the comparators for each set
    declare -a comparators
    arrayFromList comparators "${comparator_set}"

    # Assume all comparators will match
    local match=0

    for comparator in "${comparators[@]}"; do
      debug "Checking comparator \"${comparator}\" ..."

      # Split into operator and version
      [[ "$comparator" =~ ^(<|<=|>|>=|=)(.+)$ ]] || return 1
      local operator="${BASH_REMATCH[1]}"
      local comparator_version="$(semver_clean "${BASH_REMATCH[2]}")"

      # Do the version comparison
      comparator_result="$(semver_compare "${version}" "${comparator_version}")"
      [[ "${comparator_result}" == "?" ]] && return 1

      debug "Comparing \"${version}\" to \"${comparator_version}\", result=${comparator_result}"

      # Process the operator
      case "${operator}" in
        \<)
          [[ "${comparator_result}" -lt 0 ]] && continue
          ;;

        \<=)
          [[ "${comparator_result}" -le 0 ]] && continue
          ;;

        \>)
          [[ "${comparator_result}" -gt 0 ]] && continue
          ;;

        \>=)
          [[ "${comparator_result}" -ge 0 ]] && continue
          ;;

        =)
          [[ "${comparator_result}" -eq 0 ]] && continue
          ;;

        *)
          match=1
          ;;
      esac
      match=1
      break
    done

    # All comparators matched so success (this comparator set is true)
    [[ ${match} -eq 0 ]] && return 0

  done

  return 1
}

function semver_upgrade_list() {
  local upgrade_list=($1);shift
  local maximum_version="$1";shift

  local required_upgrades=()


  # assume upgrade list is ordered
  case "$(semver_compare "${maximum_version}" "${upgrade_list[-1]}")" in
    1|0)
      # Simple optimisation for the common case of all versions being required
      echo -n "${upgrade_list[*]}"
      ;;

    *)
      for upgrade_version in "${upgrade_list[@]}"; do
        if [[ "$(semver_compare "${upgrade_version}" "${maximum_version}")" == "1" ]]; then
          # Ignore all higher versions
          break
        else
          required_upgrades+=("${upgrade_version}")
          continue
        fi
      done

      echo -n "${required_upgrades[*]}"
      ;;
  esac

  return 0
}


# -- Cloudfront handling --
function invalidate_distribution() {
    local region="$1"; shift
    local distribution_id="$1"; shift

    local paths=("/*")
    [[ -n "$1" ]] && local paths=("$@")

    # Note paths is intentionally not escaped as each token needs to be separately parsed
    aws --region "${region}" cloudfront create-invalidation --distribution-id "${distribution_id}" --paths "${paths[@]}"
}

# -- ENI interface removal  --
function release_enis() {
    local region="$1"; shift
    local requester_id="$1"; shift

    eni_interfaces="$( aws --region "${region}" ec2 describe-network-interfaces --filters Name=requester-id,Values="*${requester_id}" || return $? )"

    if [[ -n "${eni_interfaces}" ]]; then
      for attachment_id in $( echo "${eni_interfaces}" | jq -r '.NetworkInterfaces[].Attachment.AttachmentId | select (.!=null)' ) ; do
        if [[ -n "${attachment_id}" ]]; then
            info "Detaching ${attachment_id} ..."
            aws --region "${region}" ec2 detach-network-interface --attachment-id "${attachment_id}"
        fi
      done
      for network_interface_id in $( echo "${eni_interfaces}" | jq -r '.NetworkInterfaces[].NetworkInterfaceId | select (.!=null)' ) ; do
        info "Deleting ${network_interface_id} ..."
        aws --region "${region}" ec2 wait network-interface-available --network-interface-id "${network_interface_id}"
        aws --region "${region}" ec2 delete-network-interface --network-interface-id "${network_interface_id}"
      done
    fi
}
