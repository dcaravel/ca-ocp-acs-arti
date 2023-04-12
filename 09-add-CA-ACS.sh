#!/bin/bash

# TODO
# 
# ref: https://docs.openshift.com/acs/3.74/configuration/add-trusted-ca.html

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

script="ca-setup.sh"
if [[ ! -f "$script" ]]; then 
    print_title "Downloading $script"
    curl -L "https://raw.githubusercontent.com/openshift/openshift-docs/rhacs-docs/files/ca-setup.sh" -o $script
    chmod +x $script
fi

print_title "Executing $script" 
./$script -f $CA_ROOT_CERT

print_title "Restarting Central"
kubectl -n stackrox delete pod -l app=central || true

print_title "Restarting Scanner"
kubectl -n stackrox delete pod -l app=scanner || true