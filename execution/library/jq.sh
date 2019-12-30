#!/usr/bin/env bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

jq -L "${GENERATION_DIR}/.jq" "$@"
RESULT=$?

