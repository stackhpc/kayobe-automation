#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    node_config_dir=("${@:1}")
    log_info "Running overcloud service configuration generate --node-config-dir ${node_config_dir[@]}"
    kayobe_init
    run_kayobe overcloud service configuration generate --node-config-dir ${node_config_dir[@]}
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_ENV_PATH}/src/kayobe-config"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a node-config-dir to use" \
            "Usage: overcloud-service-configuration-generate.sh <node-config-dir>"
    fi
    main "${@:1}"
fi
