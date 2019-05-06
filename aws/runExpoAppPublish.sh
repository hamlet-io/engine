#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

#Defaults
DEFAULT_EXPO_VERSION="2.11.9"
DEFAULT_TURTLE_VERSION="0.5.12"
DEFAULT_BINARY_EXPIRATION="1210000"
DEFAULT_RUN_SETUP="false"
DEFAULT_FORCE_BINARY_BUILD="false"
DEFAULT_QR_BUILD_FORMATS="ios,android"

tmpdir="$(getTempDir "cote_inf_XXX")"

# Get the generation context so we can run template generation
. "${GENERATION_DIR}/setContext.sh"

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
    brew upgrade || return $?
    brew install \
        jq \
        yarn \
        python || return $?

    brew cask upgrade || return $?
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
(o) -f FORCE_BINARY_BUILD     force the build of binary images
(q) -q QR_BUILD_FORMATS       specify the formats you would like to generate QR urls for

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:
BINARY_EXPIRATION = ${DEFAULT_BINARY_EXPIRATION}
BUILD_FORMATS = ${DEFAULT_BUILD_FORMATS}
BINARY_EXPIRATION = ${DEFAULT_BINARY_EXPIRATION}
RUN_SETUP = ${DEFAULT_RUN_SETUP}
QR_BUILD_FORMATS = ${DEFAULT_QR_BUILD_FORMATS}

NOTES:
RELEASE_CHANNEL default is environment

EOF
    exit
}

function options() { 

    # Parse options
    while getopts ":fhsq:t:u:" opt; do
        case $opt in
            f)
                FORCE_BINARY_BUILD="true"
                ;;
            h)
                usage
                ;;
            u)
                DEPLOYMENT_UNIT="${OPTARG}"
                ;;
            q)
                QR_BUILD_FORMATS="${OPTARG}"
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
    BINARY_EXPIRATION="${BINARY_EXPIRATION:-$DEFAULT_BINARY_EXPIRATION}"
    FORCE_BINARY_BUILD="${FORCE_BINARY_BUILD:-$DEFAULT_FORCE_BINARY_BUILD}"
    QR_BUILD_FORMATS="${QR_BUILD_FORMATS:-$DEFAULT_QR_BUILD_FORMATS}"
}


function main() {

  options "$@" || return $?

  if [[ "${RUN_SETUP}" == "true" ]]; then 
    env_setup || return $?
  fi

   # make sure fastlane is on path
   export PATH="$HOME/.fastlane/bin:$PATH"

  # Ensure mandatory arguments have been provided
  [[ -z "${DEPLOYMENT_UNIT}" ]] && fatalMandatory

  # Create build blueprint
  . "${GENERATION_DIR}/createBuildblueprint.sh" -u "${DEPLOYMENT_UNIT}" 

  BUILD_BLUEPRINT="${AUTOMATION_DATA_DIR}/build_blueprint-${DEPLOYMENT_UNIT}-.json"

  if [[ "${DEPLOYMENT_UNIT_TYPE}" -ne "mobileapp" ]]; then 
      fatal "Component type is not a mobile app function"
      return 255
  fi

  # The source of the prepared code repository zip
  SRC_BUCKET="$( jq -r '.Occurrence.State.Attributes.CODE_SRC_BUCKET' < "${BUILD_BLUEPRINT}" )"
  SRC_PREFIX="$( jq -r '.Occurrence.State.Attributes.CODE_SRC_PREFIX' < "${BUILD_BLUEPRINT}" )"

  # Operations data - Credentials, config etc.
  OPSDATA_BUCKET="$( jq -r '.Occurrence.Configuration.Settings.Core.OPSDATA_BUCKET.Value' < "${BUILD_BLUEPRINT}" )"
  CREDENTIALS_PREFIX="$( jq -r '.Occurrence.Configuration.Settings.Core.CREDENTIALS_PREFIX.Value' < "${BUILD_BLUEPRINT}" )"
  CONFIG_FILE="$( jq -r '.Occurrence.State.Attributes.CONFIG_FILE' < "${BUILD_BLUEPRINT}" )"

  APPDATA_BUCKET="$( jq -r '.Occurrence.Configuration.Settings.Core.APPDATA_BUCKET.Value' < "${BUILD_BLUEPRINT}" )"
  EXPO_APPDATA_PREFIX="$( jq -r '.Occurrence.Configuration.Settings.Core.APPDATA_PREFIX.Value' < "${BUILD_BLUEPRINT}" )"

  # Where the public artefacts will be published to
  PUBLIC_BUCKET="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_BUCKET' <"${BUILD_BLUEPRINT}" )"
  PUBLIC_PREFIX="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_PREFIX' <"${BUILD_BLUEPRINT}" )"
  PUBLIC_URL="$( jq -r '.Occurrence.State.Attributes.OTA_ARTEFACT_URL' <"${BUILD_BLUEPRINT}" )"

  BUILD_FORMAT_LIST="$( jq -r '.Occurrence.State.Attributes.APP_BUILD_FORMATS' <"${BUILD_BLUEPRINT}" )"
  arrayFromList BUILD_FORMATS "${BUILD_FORMAT_LIST}"

  BUILD_REFERENCE="$( jq -r '.Occurrence.Configuration.Settings.Build.BUILD_REFERENCE.Value' <"${BUILD_BLUEPRINT}" )"
  BUILD_NUMBER="$(date +"%Y%m%d.1%H%M%S")"
  RELEASE_CHANNEL="$( jq -r '.Occurrence.State.Attributes.RELEASE_CHANNEL' <"${BUILD_BLUEPRINT}" )"

  arrayFromList EXPO_QR_BUILD_FORMATS "${QR_BUILD_FORMATS}"

  BUILD_BINARY="false"

  # Make sure we are in the build source directory
  BINARY_PATH="${AUTOMATION_DATA_DIR}/binary"
  SRC_PATH="${AUTOMATION_DATA_DIR}/src"
  OPS_PATH="${AUTOMATION_DATA_DIR}/ops"
  REPORTS_PATH="${AUTOMATION_DATA_DIR}/reports"

  mkdir -p "${BINARY_PATH}"
  mkdir -p "${SRC_PATH}"
  mkdir -p "${OPS_PATH}"
  mkdir -p "${REPORTS_PATH}"

  TURTLE_EXTRA_BUILD_ARGS="--release-channel ${RELEASE_CHANNEL}"

  # Prepare the code build environment
  info "Getting source code from from s3://${SRC_BUCKET}/${SRC_PREFIX}/scripts.zip"
  aws --region "${AWS_REGION}" s3 cp "s3://${SRC_BUCKET}/${SRC_PREFIX}/scripts.zip" "${tmpdir}/scripts.zip" || return $?
  
  unzip -q "${tmpdir}/scripts.zip" -d "${SRC_PATH}" || return $?

  cd "${SRC_PATH}"
  yarn install --production=false

  # decrypt secrets from credentials store
  info "Getting credentials from s3://${OPSDATA_BUCKET}/${CREDENTIALS_PREFIX}"
  aws --region "${AWS_REGION}" s3 sync "s3://${OPSDATA_BUCKET}/${CREDENTIALS_PREFIX}" "${OPS_PATH}" || return $?
  find "${OPS_PATH}" -name \*.kms -exec decrypt_kms_file "${AWS_REGION}" "{}" \;

  # get config file 
  info "Gettting configuration file from s3://${OPSDATA_BUCKET}/${CONFIG_FILE}"
  aws --region "${AWS_REGION}" s3 cp "s3://${OPSDATA_BUCKET}/${CONFIG_FILE}" "${OPS_PATH}/config.json" || return $?

  # get the version of the expo SDK which is required 
  EXPO_SDK_VERSION="$(jq -r '.expo.sdkVersion' < ./app.json)"
  EXPO_APP_VERSION="$(jq -r '.expo.version' < ./app.json)"
  EXPO_CURRENT_APP_VERSION="${EXPO_APP_VERSION}"

  # Determine Binary Build status
  EXPO_CURRENT_SDK_BUILD="$(aws s3api list-objects-v2 --bucket "${PUBLIC_BUCKET}" --prefix "${PUBLIC_PREFIX}/packages/${EXPO_SDK_VERSION}" --query "join(',', Contents[*].Key)" --output text)"
  arrayFromList EXPO_CURRENT_SDK_FILES "${EXPO_CURRENT_SDK_BUILD}"

  # Determine if App Version has been incremented 
  if [[ -n "${EXPO_CURRENT_SDK_BUILD}" ]]; then 
    for sdk_file in "${EXPO_CURRENT_SDK_FILES[@]}" ; do
        if [[ "${sdk_file}" == */${BUILD_FORMATS[0]}-index.json ]]; then
            aws --region "${AWS_REGION}" s3 cp "s3://${PUBLIC_BUCKET}/${sdk_file}" "${AUTOMATION_DATA_DIR}/current-app-manifest.json"
        fi
    done

    if [[ -f "${AUTOMATION_DATA_DIR}/current-app-manifest.json" ]]; then 
        EXPO_CURRENT_APP_VERSION="$(jq -r '.version' < "${AUTOMATION_DATA_DIR}/current-app-manifest.json" )"
    fi 
  fi

  if [[ -z "${EXPO_CURRENT_SDK_BUILD}" || "${FORCE_BINARY_BUILD}" == "true" || "${EXPO_CURRENT_APP_VERSION}" != "${EXPO_APP_VERSION}" ]]; then 
    BUILD_BINARY="true"
  fi

  # Update the app.json with build context information - Also ensure we always have a unique IOS build number
  jq --slurpfile envConfig "${OPS_PATH}/config.json" '.expo.extra.build_reference=env.BUILD_REFERENCE | .expo.ios.buildNumber=env.BUILD_NUMBER | .expo.extra= .expo.extra + $envConfig[]' <  "./app.json" > "${tmpdir}/environment-app.json"  
  mv "${tmpdir}/environment-app.json" "./app.json"

  # Create a build for the SDK
  info "Creating an OTA for this version of the SDK"
  expo export --public-url "${PUBLIC_URL}" --output-dir "${SRC_PATH}/app/dist/build/${EXPO_SDK_VERSION}"  || return $?
  aws --region "${AWS_REGION}" s3 sync --delete "${SRC_PATH}/app/dist/build/${EXPO_SDK_VERSION}" "s3://${PUBLIC_BUCKET}/${PUBLIC_PREFIX}/packages/${EXPO_SDK_VERSION}" || return $?

  # Merge all existing SDK packages into a master distribution
  aws --region "${AWS_REGION}" s3 cp --recursive --exclude "${EXPO_SDK_VERSION}/*" "s3://${PUBLIC_BUCKET}/${PUBLIC_PREFIX}/packages/" "${SRC_PATH}/app/dist/packages/"
  EXPO_EXPORT_MERGE_ARGUMENTS=""
  for dir in ${SRC_PATH}/app/dist/packages/*/ ; do
    EXPO_EXPORT_MERGE_ARGUMENTS="${EXPO_EXPORT_MERGE_ARGUMENTS} --merge-src-dir "${dir}""
  done

  # Create master export 
  info "Creating master OTA artefact with Extra Dirs: ${EXPO_EXPORT_MERGE_ARGUMENTS}"
  expo export --public-url "${PUBLIC_URL}" --output-dir "${SRC_PATH}/app/dist/master/" ${EXPO_EXPORT_MERGE_ARGUMENTS}  || return $?
  aws --region "${AWS_REGION}" s3 sync "${SRC_PATH}/app/dist/master/" "s3://${PUBLIC_BUCKET}/${PUBLIC_PREFIX}" || return $? 

  DETAILED_HTML_QR_MESSAGE="<h4>Expo Client App QR Codes</h4> <p>Use these codes to load the app through the Expo Client</p>"

  DETAILED_HTML_BINARY_MESSAGE="<h4>Expo Binary Builds</h4>"
  if [[ "${BUILD_BINARY}" == "false" ]]; then 
    DETAILED_HTML_BINARY_MESSAGE="${DETAILED_HTML_BINARY_MESSAGE} <p> No binary builds were generated for this publish </p>"
  fi

  for build_format in "${BUILD_FORMATS[@]}"; do

      BINARY_FILE_PREFIX="${build_format}"
      case "${build_format}" in
        "android")
            BINARY_FILE_EXTENSION="apk"
            ANDROID_KEYSTORE_ALIAS="$( jq -r '.Occurrence.Configuration.Environment.Sensitive.ANDROID_KEYSTORE_ALIAS' < "${BUILD_BLUEPRINT}" )"

            ANDROID_KEYSTORE_PASSWORD="$( jq -r '.Occurrence.Configuration.Environment.Sensitive.ANDROID_KEYSTORE_PASSWORD' < "${BUILD_BLUEPRINT}" )"
            ANDROID_KEYSTORE_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${ANDROID_KEYSTORE_PASSWORD#"base64:"}")"
            
            ANDROID_KEY_PASSWORD="$( jq -r '.Occurrence.Configuration.Environment.Sensitive.ANDROID_KEY_PASSWORD' < "${BUILD_BLUEPRINT}" )"
            ANDROID_KEY_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${ANDROID_KEY_PASSWORD#"base64:"}")"

            ANDROID_KEYSTORE_FILE="${OPS_PATH}/expo_android_keystore.jks"

            TURTLE_EXTRA_BUILD_ARGS="${TURTLE_EXTRA_BUILD_ARGS} --keystore-path ${ANDROID_KEYSTORE_FILE} --keystore-alias ${ANDROID_KEYSTORE_ALIAS}"
            ;;
        "ios")
            BINARY_FILE_EXTENSION="ipa"
            IOS_DIST_APPLE_ID="$( jq -r '.Occurrence.Configuration.Environment.Sensitive.IOS_DIST_APPLE_ID' < "${BUILD_BLUEPRINT}" )"

            IOS_DIST_P12_PASSWORD="$( jq -r '.Occurrence.Configuration.Environment.Sensitive.IOS_DIST_P12_PASSWORD' < "${BUILD_BLUEPRINT}" )"
            export IOS_DIST_P12_PASSWORD="$( decrypt_kms_string "${AWS_REGION}" "${IOS_DIST_P12_PASSWORD#"base64:"}")"
            
            IOS_DIST_PROVISIONING_PROFILE="${OPS_PATH}/ios_profile.mobileprovision"
            IOS_DIST_P12_FILE="${OPS_PATH}/ios_distribution.p12"

            TURTLE_EXTRA_BUILD_ARGS="${TURTLE_EXTRA_BUILD_ARGS} --team-id ${IOS_DIST_APPLE_ID} --dist-p12-path ${IOS_DIST_P12_FILE} --provisioning-profile-path ${IOS_DIST_PROVISIONING_PROFILE}"
            ;;
        "*")
            echo "Unkown build format" && return 128
            ;;
      esac

      if [[ "${BUILD_BINARY}" == "true" ]]; then 

        info "Building App Binary for ${build_format}"
        EXPO_BINARY_FILE_NAME="${BINARY_FILE_PREFIX}-${EXPO_APP_VERSION}-${BUILD_NUMBER}.${BINARY_FILE_EXTENSION}"
        EXPO_BINARY_FILE_PATH="${BINARY_PATH}/${EXPO_BINARY_FILE_NAME}"

        # Setup Turtle
        turtle setup:"${build_format}" --sdk-version "${EXPO_SDK_VERSION}" || return $?

        # Build using turtle
        turtle build:"${build_format}" --public-url "${PUBLIC_URL}/${build_format}-index.json" --output "${EXPO_BINARY_FILE_PATH}" ${TURTLE_EXTRA_BUILD_ARGS} "${SRC_PATH}" || return $?

        if [[ -f "${EXPO_BINARY_FILE_PATH}" ]]; then 

            aws --region "${AWS_REGION}" s3 sync --exclude "*" --include "${BINARY_FILE_PREFIX}*" "${BINARY_PATH}" "s3://${APPDATA_BUCKET}/${EXPO_APPDATA_PREFIX}/" || return $?
            EXPO_BINARY_PRESIGNED_URL="$(aws --region "${AWS_REGION}" s3 presign --expires-in "${BINARY_EXPIRATION}" "s3://${APPDATA_BUCKET}/${EXPO_APPDATA_PREFIX}/${EXPO_BINARY_FILE_NAME}" )"
            DETAILED_HTML_BINARY_MESSAGE="${DETAILED_HTML_BINARY_MESSAGE}<p><strong>${build_format}</strong> <a href="${EXPO_BINARY_PRESIGNED_URL}">${build_format} - ${EXPO_APP_VERSION} - ${BUILD_NUMBER}</a>" 

        fi
      else 
        info "Skipping build of app binary for ${build_format}"
      fi

  done

  for qr_build_format in "${EXPO_QR_BUILD_FORMATS[@]}"; do 

       #Generate EXPO QR Code 
      EXPO_QR_FILE_PREFIX="${qr_build_format}"
      EXPO_QR_FILE_NAME="${EXPO_QR_FILE_PREFIX}-qr.png"
      EXPO_QR_FILE_PATH="${REPORTS_PATH}/${EXPO_QR_FILE_NAME}"

      qr "${PUBLIC_URL/http/exp}/${qr_build_format}-index.json?release-channel=${RELEASE_CHANNEL}" > "${EXPO_QR_FILE_PATH}" || return $?

      DETAILED_HTML_QR_MESSAGE="${DETAILED_HTML_QR_MESSAGE}<p><strong>${qr_build_format}</strong> <br> <img src=\"./${EXPO_QR_FILE_NAME}\" alt=\"EXPO QR Code\" width=\"200px\" /></p>"
  
  done

  DETAILED_HTML="<html><body> <h4>Expo Mobile App Publish</h4> <p> A new Expo mobile app publish has completed </p> <ul> <li><strong>Public URL</strong> ${PUBLIC_URL}</li> <li><strong>Release Channel</strong> ${RELEASE_CHANNEL}</li><li><strong>SDK Version</strong> ${EXPO_SDK_VERSION}</li><li><strong>App Version</strong> ${EXPO_APP_VERSION}</li><li><strong>Build Number</strong> ${BUILD_NUMBER}</li><li><strong>Code Commit</strong> ${BUILD_REFERENCE}</li></ul> ${DETAILED_HTML_QR_MESSAGE} ${DETAILED_HTML_BINARY_MESSAGE} </body></html>" 
  echo "${DETAILED_HTML}" > "${REPORTS_PATH}/build-report.html"

  aws --region "${AWS_REGION}" s3 sync "${REPORTS_PATH}/" "s3://${PUBLIC_BUCKET}/${PUBLIC_PREFIX}/reports/" || return $?

  if [[ "${BUILD_BINARY}" == "true" ]]; then 
    DETAIL_MESSAGE="${DETAIL_MESSAGE} *Expo Publish Complete* - *NEW BINARIES CREATED* -  More details available <${PUBLIC_URL}/reports/build-report.html|Here>"
  else
    DETAIL_MESSAGE="${DETAIL_MESSAGE} *Expo Publish Complete* - More details available <${PUBLIC_URL}/reports/build-report.html|Here>"
  fi 

  echo "DETAIL_MESSAGE=${DETAIL_MESSAGE}" >> ${AUTOMATION_DATA_DIR}/context.properties

  # All good
  return 0
}

main "$@" || exit $?
