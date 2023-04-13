#!/bin/bash

# TODO

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

print_title "Creating namespace $NAMESPACE if needed"
oc create namespace $NAMESPACE || true

print_title "Adding anyuid SCC to default SA"
# JCR will fail to installed without appropriate runtime permissions
oc adm policy add-scc-to-user anyuid -z default -n $NAMESPACE

print_title "Adding helm jfrog repo"
helm repo add jfrog https://charts.jfrog.io

print_title "Updating helm jfrog repo"
helm repo update jfrog

print_title "Installing JFrog Container Registry (Artifactory)"
helm upgrade -i jfrog-container-registry jfrog/artifactory-jcr \
  -n $NAMESPACE \
  --set artifactory.ingress.enabled=false \
  --set artifactory.postgresql.enabled=false \
  --set artifactory.artifactory.persistence.enabled=true

print_title "Waiting for Load Balancer External IP to be provisioned"
JCR_IP=""
until [[ -n "${JCR_IP}" ]]; do
    echo -n "."
    sleep 1
    JCR_IP=$(oc get svc jfrog-container-registry-artifactory-nginx -o json -n $NAMESPACE | jq -r '.status.loadBalancer.ingress[0] | .ip')
    if [[ "$JCR_IP" == "null" ]]; then
        JCR_IP=""
    fi
done

echo
echo "External JCR IP: $JCR_IP"