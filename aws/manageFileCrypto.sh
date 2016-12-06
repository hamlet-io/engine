#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
  echo -e "\nManage crypto for files" 
  echo -e "\nUsage: $(basename $0) -f CRYPTO_FILE -e -d -u\n"
  echo -e "\nwhere\n"
  echo -e "(o) -d if file should be decrypted"
  echo -e "(o) -e if file should be encrypted"
  echo -e "(o) -f CRYPTO_FILE is the path to the file managed"
  echo -e "    -h shows this text"
  echo -e "(o) -u if file should be updated"
  echo -e "\nDEFAULTS:\n"
  echo -e "\nNOTES:\n"
  echo -e "1. If no operation is provided, the current file contents are displayed"
  echo -e ""
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
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