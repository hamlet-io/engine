#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults

function usage() {
    cat <<EOF

Manage crypto for files

Usage: $(basename $0) -f CRYPTO_FILE -e -d -u -a KEYALIAS -k KEYID

where

(o) -a              is the cmk alias
(o) -d              if file should be decrypted
(o) -e              if file should be encrypted
(o) -f CRYPTO_FILE  is the path to the file managed
    -h              shows this text
(o) -k KEYID        for the master key to be used
(o) -u              if file should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. If no operation is provided, the current file contents are displayed

EOF
    exit
}

# Parse options
while getopts ":a:def:hk:u" opt; do
    case $opt in
        a)
            export ALIAS="${OPTARG}"
            ;;
        d)
            export CRYPTO_OPERATION="decrypt"
            ;;
        e)
            export CRYPTO_OPERATION="encrypt"
            ;;
        f)
            export CRYPTO_FILE="${OPTARG}"
            ;;
        h)
            usage
            ;;
        k)
            export KEYID="${OPTARG}"
            ;;
        u)
            export CRYPTO_UPDATE="true"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Perform the operation required
case $CRYPTO_OPERATION in
    encrypt)
        ${GENERATION_DIR}/manageCrypto.sh -e
        ;;
    decrypt)
        ${GENERATION_DIR}/manageCrypto.sh -b -d -v
        ;;
    *)
        ${GENERATION_DIR}/manageCrypto.sh -n
        ;;
esac
RESULT=$?
