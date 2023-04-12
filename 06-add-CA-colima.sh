#!/bin/bash

SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi
. "$SCRIPT_DIR/common.sh"

# add CA cert to colima trust store

print_title "Transfering $CA_ROOT_CERT to colima"
scp $CA_ROOT_CERT colima:~/myCA.pem

print_title "Loading Root Cert into Trust Store (docker)"
colima ssh <<'ENDSSH'
sudo mv ~/myCA.pem /usr/local/share/ca-certificates/myCA.crt
sudo update-ca-certificates
sudo service docker restart
ENDSSH