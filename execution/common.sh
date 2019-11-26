#!/usr/bin/env bash

# Generation framework common definitions
#
# This script is designed to be sourced into other scripts

. ${GENERATION_BASE_DIR}/execution/utility.sh
. ${GENERATION_BASE_DIR}/execution/contextTree.sh

function getLogLevel() {
  checkLogLevel "${GENERATION_LOG_LEVEL}"
}

# Override default implementation
function getTempRootDir() {
  echo -n "${GENERATION_TMPDIR}"
}
