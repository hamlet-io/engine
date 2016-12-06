#!/bin/bash

# Provide an SSH certificate at the product level
if [[ (! -f ${1}/aws-ssh-crt.pem) &&
      (! -f ${1}/aws-ssh-prv.pem) ]]; then
    openssl genrsa -out ${1}/aws-ssh-prv.pem 2048
    openssl rsa -in ${1}/aws-ssh-prv.pem -pubout > ${1}/aws-ssh-crt.pem
fi
