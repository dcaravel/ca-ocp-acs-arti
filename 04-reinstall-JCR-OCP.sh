#!/bin/bash

# Will create a kubernetes secret containing the arti.local keys

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

if [[ ! -f "$ARTI_CERT" || ! -f "$ARTI_KEY" ]]; then
    print_title "CERT and/or KEY missing"
fi

secret_name=nginx-tls 

print_title "Creating $secret_name secret w/ JCR certs"
kubectl delete secret $secret_name -n $NAMESPACE 2>/dev/null || true
kubectl create secret tls $secret_name --cert=$ARTI_CERT --key=$ARTI_KEY -n $NAMESPACE

print_title "Upgrading JFrog Container Registry (Artifactory) with TLS cert"
helm upgrade -i jfrog-container-registry jfrog/artifactory-jcr --version $VERSION \
  -n $NAMESPACE \
  --set artifactory.nginx.tlsSecretName="$secret_name"