#!/bin/bash

# Trigger the creation of a CSR

# openssl config should be edited 
#
# req_extensions = v3_req # The extensions to add to a certificate request
#
# [ v3_req ]
# basicConstraints = CA:FALSE
# keyUsage = nonRepudiation, digitalSignature, keyEncipherment
# extendedKeyUsage = serverAuth, clientAuth

openssl req -new -newkey rsa:2048 -sha256 -nodes -keyout ${1}-ssl-prv.pem -out ${1}-ssl-csr.pem

# The CSR can be viewed via

# openssl req -text -in {domain}-ssl-csr.pem