#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<EOF

Manage crypto for files 

Usage: $(basename $0) -f CRYPTO_FILE -e -d -u

where

(o) -d              if file should be decrypted
(o) -e              if file should be encrypted
(o) -f CRYPTO_FILE  is the path to the file managed
    -h              shows this text
(o) -u              if file should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. If no operation is provided, the current file contents are displayed

EOF
    exit
}

# Parse options
while getopts ":def:hu" opt; do
    case $opt in
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
        u)
            export CRYPTO_UPDATE="true"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}" >&2
            exit
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            exit
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