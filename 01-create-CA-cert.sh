#!/bin/bash

# Only needs to be executed once or when CA certs expire
SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

function doCA () {
    mkdir -p $CERTS_DIR
    # Generate the private CA key (prompts for password)

    print_title "Generating CA ROOT KEY at $CA_ROOT_KEY"
    openssl genrsa -des3 -out $CA_ROOT_KEY 2048

    # Generate the CA root cert (expire in 5 years)
    # At least one attribute must be populated in the prompts (ie: Country)
    print_title "Generating CA ROOT CERT at $CA_ROOT_CERT"
    openssl req -x509 -new -nodes -key $CA_ROOT_KEY -sha256 -days 1825 -out $CA_ROOT_CERT

    print_title "Certs List from $CERTS_DIR"
    ls -l $CERTS_DIR
}

## Root Key/Cert
if [[ -f "$CA_ROOT_KEY" ]]; then
    keyvar=""
    read -p 'CA Root Key already exists, overwrite [y/N]: ' keyvar 
    keyvar=$(echo $keyvar | tr '[:upper:]' '[:lower:]')
    if [[ $keyvar == "y" || $keyvar == "yes" ]]; then
        doCA
    fi
else
    doCA
fi