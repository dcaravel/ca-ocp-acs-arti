#!/bin/bash

set -euo pipefail

# certs / keys will be stored here
CERTS_DIR=$HOME/.certs

CA_ROOT_KEY=$CERTS_DIR/myCA.key
CA_ROOT_CERT=$CERTS_DIR/myCA.pem

ARTI_KEY=$CERTS_DIR/arti.local.key
ARTI_CSR=$CERTS_DIR/arti.local.csr
ARTI_CERT=$CERTS_DIR/arti.local.crt

NAMESPACE=artifactory-jcr

function get_jcr_external_ip() {
    kubectl get svc jfrog-container-registry-artifactory-nginx -o json -n $NAMESPACE | jq -r '.status.loadBalancer.ingress[0] | .ip'
}

function get_jcr_cluster_ip() {
    kubectl get svc jfrog-container-registry-artifactory-nginx -o json -n $NAMESPACE | jq '.spec.clusterIP' -r
}

function print_title() {
    title=$1
    if [[ -z "$title" ]]; then
        echo "Title missing"
        return 1
    fi

    echo
    echo "==== $title ===="
    echo
}