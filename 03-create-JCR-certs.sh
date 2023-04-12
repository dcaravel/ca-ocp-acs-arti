#!/bin/bash

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

## Local Key/CSR/Cert
if [[ -f "$ARTI_KEY" ]]; then
    keyvar=""
    read -p 'Key already exists, overwrite [Y/n]: ' keyvar
    keyvar=$(echo $keyvar | tr '[:upper:]' '[:lower:]')
    if ! [[ -z $keyvar || $keyvar == "y" || $keyvar == "yes" ]]; then
        exit 1
    fi
fi

# Create Key
print_title "Generating Artifactory key"
openssl genrsa -out $ARTI_KEY 2048

# Create CSR
print_title "Generating Artifactory csr"
openssl req -new -key $ARTI_KEY -out $ARTI_CSR

# Create Cert (expire in 1 yr)
print_title "Generating Artifactory cert"

# get JCR IP
cluster_ip=$(get_jcr_cluster_ip)
external_ip=$(get_jcr_external_ip)
sed "s/{{JCR_CLUSTER_IP}}/$cluster_ip/g; s/{{JCR_EXTERNAL_IP}}/$external_ip/ " arti_cert.ext.tmpl > arti_cert.ext

openssl x509 -req -in $ARTI_CSR -CA $CA_ROOT_CERT -CAkey $CA_ROOT_KEY \
  -CAcreateserial -out $ARTI_CERT -days 365 -sha256 -extfile ./arti_cert.ext

print_title "Generated cert with following Subject Alternative Names (SANs)"
grep -E "DNS|IP" arti_cert.ext

print_title "Certs List"
ls -l $CERTS_DIR