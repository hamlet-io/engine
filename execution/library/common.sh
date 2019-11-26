#!/usr/bin/env bash

# Generation framework common definitions
#
# This script is designed to be sourced into other scripts

. ${GENERATION_DIR}/utility.sh
. ${GENERATION_DIR}/contextTree.sh

function getLogLevel() {
  checkLogLevel "${GENERATION_LOG_LEVEL}"
}

# Override default implementation
function getTempRootDir() {
  echo -n "${GENERATION_TMPDIR}"
}

