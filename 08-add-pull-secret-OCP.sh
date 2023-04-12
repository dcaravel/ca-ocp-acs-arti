#!/bin/bash

# TODO

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

external_ip=$(get_jcr_external_ip)

print_title "Prompting for registry credentials"

read -p "Username: " username
read -s -p "Password: " password
echo

secret_name=jcr-pull-secret
print_title "Creating secret $secret_name in current context"

if kubectl get secret $secret_name 1>/dev/null 2>&1 ; then
    kubectl delete secret $secret_name
fi

kubectl create secret docker-registry jcr-pull-secret --docker-server=$external_ip \
        --docker-username="$username" --docker-password="$password" \
        --docker-email=no-reply@example.com

print_title "Adding secret $secret_name to default SA in current context"
kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"$secret_name\"}]}"
