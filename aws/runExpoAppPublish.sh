#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

#Defaults
DEFAULT_EXPO_VERSION="2.11.6"
DEFAULT_TURTLE_VERSION="0.5.12"
DEFAULT_BINARY_EXPIRATION="1210000"
DEFAULT_RUN_SETUP="false"

tmpdir="$(getTempDir "cote_inf_XXX")"

function decrypt_kms_file() {
    local region="$1"; shift
    local encrypted_file_path="$1"; shift

    base64 --decode < "${encrypted_file_path}" > "${encrypted_file_path}.base64"
    BASE64_CLEARTEXT_VALUE="$(aws --region ${region} kms decrypt --ciphertext-blob "${encrypted_file_path}.base64"  --output text --query Plaintext)"
    echo "${BASE64_CLEARTEXT_VALUE}" | base64 --decode > "${encrypted_file_path%".kms"}"
    rm -rf "${encrypted_file_path}.base64"

    if [[ -e "${encrypted_file_path%".kms"}" ]]; then
        return 0
    else
        error "could not decrypt file ${encrypted_file_path}"
        return 128
    fi
}

function env_setup() {

    # hombrew install 
    brew install \
        jq \
        yarn \
        python || return $?

    brew cask install \
        fastlane || return $?

    # Make sure we have required software installed 
    pip3 install \
        qrcode[pil] \
        awscli || return $?

    # yarn install
    yarn global add \
        expo-cli@"${EXPO_VERSION}" \
        turtle-cli@"${TURTLE_VERSION}" || return $?
}

function usage() {
    cat <<EOF

Run a task based build of an Expo app binary

Usage: $(basename $0) -u DEPLOYMENT_UNIT -i INPUT_PAYLOAD -l INCLUDE_LOG_TAIL

where

    -h                        shows this text
(m) -u DEPLOYMENT_UNIT        is the mobile app deployment unit
(o) -s RUN_SETUP              run setup installation to prepare
(o) -t BINARY_EXPIRATION      how long presigned urls are active for once created ( seconds )


(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:
BINARY_EXPIRATION = ${DEFAULT_BINARY_EXPIRATION}
BUILD_FORMATS = ${DEFAULT_BUILD_FORMATS}
BINARY_EXPIRATION = ${DEFAULT_BINARY_EXPIRATION}
RUN_SETUP = ${DEFAULT_RUN_SETUP}

NOTES:
RELEASE_CHANNEL default is environment

EOF
    exit
}

function options() { 

    # Parse options
    while getopts ":f:hst:u:" opt; do
        case $opt in
            h)
                usage
                ;;
            u)
                DEPLOYMENT_UNIT="${OPTARG}"
                ;;
            s)
                RUN_SETUP="true"
                ;;
            t)
                BINARY_EXPIRATION="${OPTARG}"
                ;;
            \?)
                fatalOption
                ;;
            :)
                fatalOptionArgument
                ;;
        esac
    done

    #Defaults
    RUN_SETUP="${RUN_SETUP:-DEFAULT_RUN_SETUP}"
    TURTLE_VERSION="${TURTLE_VERSION:-$DEFAULT_TURTLE_VERSION}"
    EXPO_VERSION="${EXPO_VERSION:-$DEFAULT_EXPO_VERSION}"
}


function main() {

  options "$@" || return $?

  [[ "${RUN_SETUP}" == "true" ]] && env_setup || return $?

  # Ensure mandatory arguments have been provided
  [[ -z "${DEPLOYMENT_UNIT}" ]] && fatalMandatory

  # Set up the context
  . "${GENERATION_DIR}/setContext.sh"

  # Ensure we are in the right place
  checkInSegmentDirectory

  # Create build blueprint
  . "${GENERATION_DIR}/createBuildblueprint.sh" -u "${DEPLOYMENT_UNIT}" 

  COT_TEMPLATE_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/cot/${ENVIRONMENT}/${SEGMENT}"
  BUILD_BLUEPRINT="${COT_TEMPLATE_DIR}/build_blueprint-${DEPLOYMENT_UNIT}-.json"
  DEPLOYMENT_UNIT_TYPE="$(jq -r '.Type' < "${BUILD_BLUEPRINT}" )"
  
  if [[ "${DEPLOYMENT_UNIT_TYPE}" -ne "mobileapp" ]]; then 
      fatal "Component type is not a mobile app function"
      return 255
  fi

  # The source of the prepared code repository zip
  EXPO_SRC_BUCKET="$( jq -r '.Occurrence.State.Attributes.CODE_SRC_BUCKET' < "${BUILD_BLUEPRINT}" )"
  EXPO_SRC_PREFIX="$( jq -r '.Occurrence.State.Attributes.CODE_SRC_PREFIX' < "${BUILD_BLUEPRINT}" )"

  # The staging location of credential data
  EXPO_CREDENTIALS_BUCKET="$( jq -r '.Occurrence.Configuration.Settings.Core.OPSDATA_BUCKET.Value' < "${BUILD_BLUEPRINT}" )"
  EXPO_CREDNTIALS_PREFIX="$( jq -r '.Occurrence.Configuration.Settings.Core.CREDENTIALS_PREFIX.Value' < "${BUILD_BLUEPRINT}" )"

  EXPO_APPDATA_BUCKET="$( jq -r '.Occurrence.Configuration.Settings.Core.APPDATA_BUCKET.Value' < "${BUILD_BLUEPRINT}" )"
  EXPO_APPDATA_PREFIX="$( jq -r '.Occurrence.Configuration.Settings.Core.APPDATA_PREFIX.Value' < "${BUILD_BLUEPRINT}" )"

  # Where the public artefacts will be published to
  EXPO_PUBLIC_BUCKET="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_BUCKET' <"${BUILD_BLUEPRINT}" )"
  EXPO_PUBLIC_PREFIX="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_PREFIX' <"${BUILD_BLUEPRINT}" )"
  EXPO_PUBLIC_URL="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_URL' <"${BUILD_BLUEPRINT}" )"

  EXPO_BUILD_FORMAT_LIST="$( jq -r '.Occurrence.State.Attributes.APP_BUILD_FORMATS' <"${BUILD_BLUEPRINT}" )"

  EXPO_RELEASE_CHANNEL="$( jq -r '.Occurrence.State.Attributes.RELEASE_CHANNEL' <"${BUILD_BLUEPRINT}" )"

  # Make sure we are in the build source directory
  cd ${tmpdir}

  EXPO_BINARY_PATH="${tmpdir}/binary"
  EXPO_SRC_PATH="${tmpdir}/src"
  EXPO_CREDS_PATH="${tmpdir}/creds"

  mkdir "${EXPO_STATIC_PATH}"
  mkdir "${EXPO_BINARY_PATH}"


  TURTLE_EXTRA_BUILD_ARGS="--release-channel ${EXPO_RELEASE_CHANNEL}"

  # get build contents 
  aws --region "${AWS_REGION}" s3 sync "s3://${EXPO_SRC_BUCKET}/${EXPO_SRC_PREFIX}/scrpits.zip" "${tmpdir}/scripts.zip" || return $?
  
  unzip "${tmpdir}/scripts.zip" -d "${EXPO_SRC_PATH}" || return $?
  cd "${EXPO_STATIC_PATH}"

  # decrypt secrets from credentials store
  aws --region "${AWS_REGION}" s3 sync "s3://${EXPO_CREDENITALS_BUCKET}/${EXPO_CREDENTIALS_PREFIX}" "${EXPO_CREDS_PATH}" || return $?
  find "${EXPO_CREDS_PATH}" -name \*.kms -exec decrypt_kms_file "${AWS_REGION}" "{}" \;

  #Export the Static assets 
  expo export --public-url "https://${EXPO_PUBLIC_URL}${EXPO_PUBLIC_PREFIX}" --output-dir '/app/dist' || return $?
  aws --region "${AWS_REGION}" s3 sync "/app/dist" "${EXPO_PUBLIC_BUCKET}/${EXPO_PUBLIC_PREFIX}" || return $?

  # get the version of the expo SDK which is required 
  EXPO_SDK_VERSION="$(jq -r '.expo.sdkVersion' < ./app.json)"
  arrayFromList build_formats "${EXPO_BUILD_FORMAT_LIST}"

  for build_format in "${build_formats[@]}"; do

      EXPO_BINARY_FILE_PREFIX="${build_format}"
      case "${build_format}" in
        "android")
            EXPO_BINARY_FILE_EXTENSION="apk"
            EXPO_ANDROID_KEYSTORE_ALIAS="$( jq -r '.Occurrence.Configuration.Settings.Core.EXPO_ANDROID_KEYSTORE_ALIAS.Value' < "${BUILD_BLUEPRINT}" )"

            EXPO_ANDROID_KEYSTORE_PASSWORD="$( jq -r '.Occurrence.Configuration.Settings.Core.EXPO_ANDROID_KEYSTORE_PASSWORD.Value' < "${BUILD_BLUEPRINT}" )"
            EXPO_ANDROID_KEYSTORE_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${EXPO_ANDROID_KEYSTORE_PASSWORD}")"
            
            EXPO_ANDROID_KEY_PASSWORD="$( jq -r '.Occurrence.Configuration.Settings.Core.EXPO_ANDROID_KEY_PASSWORD.Value' < "${BUILD_BLUEPRINT}" )"
            EXPO_ANDROID_KEY_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${EXPO_ANDROID_KEY_PASSWORD}")"

            EXPO_ANDROID_KEYSTORE_FILE="${EXPO_CREDS_PATH}/expo_android_keystore.jks"

            TURTLE_EXTRA_BUILD_ARGS="${TURTLE_EXTRA_BUILD_ARGS} --keystore-path ${EXPO_ANDROID_KEYSTORE_FILE} --keystore-alias ${EXPO_ANDROID_KEYSTORE_ALIAS}"

        "ios")
            EXPO_BINARY_FILE_EXTENSION="ipa"
            EXPO_IOS_DIST_APPLE_ID="$( jq -r '.Occurrence.Configuration.Settings.Core.EXPO_IOS_DIST_APPLE_ID.Value' < "${BUILD_BLUEPRINT}" )"

            EXPO_IOS_DIST_P12_PASSWORD="$( jq -r '.Occurrence.Configuration.Settings.Core.EXPO_IOS_DIST_P12_PASSWORD.Value' < "${BUILD_BLUEPRINT}" )"
            EXPO_IOS_DIST_P12_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${EXPO_IOS_DIST_P12_PASSWORD}")"
            
            EXPO_IOS_DIST_PROVISIONING_PROFILE="${EXPO_CREDS_PATH}/expo_ios_profile.mobileprovision"
            EXPO_IOS_DIST_P12_FILE="${EXPO_CREDS_PATH}/expo_ios_distribution.p12"

            TURTLE_EXTRA_BUILD_ARGS="${TURTLE_EXTRA_BUILD_ARGS} --team-id ${EXPO_IOS_DIST_APPLE_ID} --dist-p12-path ${EXPO_IOS_DIST_P12_FILE} --provisioning-profile-path ${EXPO_IOS_DIST_PROVISIONING_PROFILE}"
        "*")
            echo "Unkown build format" && return 128
      esac

      EXPO_BINARY_FILE_NAME="${EXPO_BINARY_FILE_PREFIX}.${EXPO_BINARY_FILE_EXTENSION}"
      EXPO_BINARY_FILE_PATH="${EXPO_BINARY_PATH}/${EXPO_BINARY_FILE_NAME}"

      # Setup Turtle
      turtle setup:"${build_format}" --sdk-version "${EXPO_SDK_VERSION}" || return $?

      # Build using turtle
      turtle build:"${build_format}" --public-url "${EXPO_PUBLIC_URL}${EXPO_PUBLIC_PREFIX}" --build-dir "${EXPO_STATIC_PATH}" --output "${EXPO_BINARY_FILE_PATH}" ${TURTLE_EXTRA_BUILD_ARGS} || return $?

      if [[ -f "${EXPO_BINARY_FILE_PATH}" ]]; then 
        
        EXPO_BINARY_QR_FILE_NAME="${EXPO_BINARY_FILE_PREFIX}-qr.png"
        EXPO_BINARY_QR_FILE_PATH="${EXPO_BINARY_PATH}/${EXPO_BINARY_QR_FILE_NAME}"
        qr "${EXPO_PUBLIC_URL/http/exp}/${build_format}-index.json" > "${EXPO_BINARY_QR_FILE_PATH}" || return $?
        EXPO_BINARY_QR_BASE64="$(base64 < ${EXPO_BINARY_QR_FILE_PATH})"

        aws --region "${AWS_REGION}" s3 cp --exclude "*" --include "${EXPO_BINARY_FILE_PREFIX}*" "${EXPO_BINARY_FILE_PATH}" "s3://${EXPO_APPDATA_BUCKET}/${EXPO_APPDATA_PREFIX}/" || return $?
        EXPO_BINARY_PRESIGNED_URL="$(aws --region "${AWS_REGION}" s3 presign --expires-in "${BINARY_EXPIRATION}" "s3://${APP_DATA_BUCKET}/${APP_DATA_PREFIX}/binary/${EXPO_BINARY_FILE_NAME}" || return $?)"

        info "Presigned URL=${EXPO_BINARY_PRESIGNED_URL}"

      fi
  done
  
  # All good
  return 0
}

main "$@"