#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ansible-vault decrypt "${SCRIPT_DIR}/../group_vars/all/vault.yml"
