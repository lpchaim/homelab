#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ansible-vault encrypt "${SCRIPT_DIR}/../group_vars/all/vault.yml"
