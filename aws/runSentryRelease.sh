#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

#Defaults
DEFAULT_SENTRY_CLI_VERSION="1.46.0"
DEFAULT_RUN_SETUP="false"

# Get the generation context so we can run template generation
. "${GENERATION_DIR}/setContext.sh"

function env_setup() {

    # yarn install
    yarn global add \
        @sentry/cli@"${SENTRY_CLI_VERSION}" || return $?
    
	# make sure yarn global bin is on path
    export PATH="$(yarn global bin):$PATH"
}

function usage() {
    cat <<EOF

Upload sourcemap files to sentry for a specific release

Usage: $(basename $0) -m SENTRY_SOURCE_MAP_S3_URL -r SENTRY_RELEASE -s

where

    -h                              shows this text
(m) -m SENTRY_SOURCE_MAP_S3_URL     s3 link to sourcemap files
(o) -s RUN_SETUP              		run setup installation to prepare
(m) -r SENTRY_RELEASE_NAME          sentry release name

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

EOF
    exit
}

function options() { 

    # Parse options
    while getopts ":hm:r:s" opt; do
        case $opt in
            h)
                usage
                ;;
            m)
                SENTRY_SOURCE_MAP_S3_URL="${OPTARG}"
                ;;
            r)
                SENTRY_RELEASE_NAME="${OPTARG}"
                ;;
            s)
                RUN_SETUP="true"
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
    SENTRY_CLI_VERSION="${SENTRY_CLI_VERSION:-$DEFAULT_SENTRY_CLI_VERSION}"

}


function main() {

  options "$@" || return $?

  if [[ "${RUN_SETUP}" == "true" ]]; then 
    env_setup || return $?
  fi

  # Ensure mandatory arguments have been provided
  [[ -z "${SENTRY_SOURCE_MAP_S3_URL}" || -z "${SENTRY_RELEASE_NAME}" ]] && fatalMandatory

  SOURCE_MAP_PATH="${AUTOMATION_DATA_DIR}/source_map"

  mkdir -p "${SOURCE_MAP_PATH}"

  info "Getting source code from from ${SENTRY_SOURCE_MAP_S3_URL}"
  aws --region "${AWS_REGION}" s3 cp --recursive "${SENTRY_SOURCE_MAP_S3_URL}" "${SOURCE_MAP_PATH}" || return $?

  # TODO: Check if a release with a specified name exists. Create one if needed.
  sentry-cli releases files "${SENTRY_RELEASE_NAME}" upload-sourcemaps "${SOURCE_MAP_PATH}" --rewrite || return $?

  DETAIL_MESSAGE="${DETAIL_MESSAGE} Source map files uploaded for the release ${SENTRY_RELEASE_NAME}."

  echo "DETAIL_MESSAGE=${DETAIL_MESSAGE}" >> ${AUTOMATION_DATA_DIR}/context.properties

  # All good
  return 0
}

main "$@" || exit $?
