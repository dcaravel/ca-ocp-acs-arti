#!/bin/bash

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"


external_ip=$(get_jcr_external_ip)

print_title "Opening $external_ip - default creds admin/password"
open https://$external_ip