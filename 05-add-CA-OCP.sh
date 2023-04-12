#!/bin/bash

# TODO
# 
# ref: https://access.redhat.com/documentation/en-us/openshift_container_platform/4.1/html/builds/setting-up-trusted-ca
# ref: https://docs.openshift.com/container-platform/4.12/rest_api/config_apis/image-config-openshift-io-v1.html#image-config-openshift-io-v1

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

if [[ ! -f "$CA_ROOT_CERT" ]]; then
    print_title "Root CA CERT missing"
    exit 1
fi

cluster_ip=$(get_jcr_cluster_ip)
external_ip=$(get_jcr_external_ip)

if kubectl get configmap registry-cas -n openshift-config 1>/dev/null 2>&1 ; then
    print_title "OpenShift Registry CAs ConfigMap already exists"

    answer=""
    read -p 'Overwrite [Y/n]: ' answer
    answer=$(echo $answer | tr '[:upper:]' '[:lower:]')
    if ! [[ -z $answer || $answer == "y" || $answer == "yes" ]]; then
        exit 1
    fi

    kubectl delete configmap registry-cas -n openshift-config
fi

print_title "Creating Registry CAs ConfigMap"
kubectl create configmap registry-cas -n openshift-config \
  --from-file=$external_ip=$CA_ROOT_CERT \
  --from-file=$cluster_ip=$CA_ROOT_CERT


print_title "Patching OpenShift Image Config"
# ref: https://docs.openshift.com/container-platform/4.12/rest_api/config_apis/image-config-openshift-io-v1.html#image-config-openshift-io-v1
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge