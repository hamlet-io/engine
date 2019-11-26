#!/usr/bin/env bash

# Trigger the creation of a CSR

certificate_name="$1"; shift
cn="$1"; shift
san="$1"; shift

options=("-keyout" "${certificate_name}-ssl-prv.pem" "-out" "${certificate_name}-ssl-csr.pem")

cat > /tmp/ssl.conf <<EOF
[ req ]
prompt = no
default_bits		= 2048
distinguished_name	= req_distinguished_name
attributes		= req_attributes
req_extensions = v3_req # The extensions to add to a certificate request

# This sets a mask for permitted string types. There are several options.
# default: PrintableString, T61String, BMPString.
# pkix	 : PrintableString, BMPString (PKIX recommendation before 2004)
# utf8only: only UTF8Strings (PKIX recommendation after 2004).
# nombstr : PrintableString, T61String (no BMPStrings or UTF8Strings).
# MASK:XXXX a literal mask value.
# WARNING: ancient versions of Netscape crash on BMPStrings or UTF8Strings.
string_mask = utf8only


[ req_distinguished_name ]
countryName            = AU
stateOrProvinceName 	 = Australian Capital Territory
localityName           = Belconnen
organizationName       = Department of Silly Walks
organizationalUnitName = Walks Register
commonName			       = ${cn}

[ req_attributes ]

[ v3_req ]

basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOF

[[ -n "${san}" ]] && cat >> /tmp/ssl.conf <<EOF
subjectAltName = @alt_names

[alt_names]
${san:+DNS.1 = }${san}

EOF

openssl req -new -newkey rsa:2048 -sha256 -nodes "${options[@]}" -config /tmp/ssl.conf

# The CSR can be viewed via

# openssl req -text -in ${certificate_name}-ssl-csr.pem
#