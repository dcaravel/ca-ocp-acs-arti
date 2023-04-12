#!/bin/bash

# TODO

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"


print_title "Prompting for registry credentials"

read -p "Username: " username
read -s -p "Password: " password
echo

print_title "Prompting for registry creds"


secret_name_ext=jcr-ext-pull-secret
print_title "Creating secret $secret_name_ext in current context"
if kubectl get secret $secret_name_ext 1>/dev/null 2>&1 ; then
    kubectl delete secret $secret_name_ext
fi
external_ip=$(get_jcr_external_ip)
kubectl create secret docker-registry $secret_name_ext --docker-server=$external_ip \
        --docker-username="$username" --docker-password="$password" \
        --docker-email=no-reply@example.com

secret_name_int=jcr-int-pull-secret
print_title "Creating secret $secret_name_int in current context"
if kubectl get secret $secret_name_int 1>/dev/null 2>&1 ; then
    kubectl delete secret $secret_name_int
fi
internal_ip=$(get_jcr_cluster_ip)
kubectl create secret docker-registry $secret_name_int --docker-server=$internal_ip \
        --docker-username="$username" --docker-password="$password" \
        --docker-email=no-reply@example.com

print_title "Adding secret $secret_name_ext and $secret_name_int to default SA in current context"
kubectl patch serviceaccount default -p "{\"imagePullSecrets\": [{\"name\": \"$secret_name_ext\"},{\"name\": \"$secret_name_int\"}]}"
