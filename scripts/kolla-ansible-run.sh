#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kolla_command=("${@:1}")
    log_info "Running kolla-ansible command: args: ${kolla_command[@]}"
    kayobe_init
    # NOTE: KAYOBE_CONFIG_PATH gets defined by kayobe_init
    run_kayobe kolla ansible run "${kolla_command[@]}"
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_ENV_PATH}/src/kayobe-config"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a kolla ansible command to run" \
            "Usage: kolla-ansible-run.sh <kolla ansible command>"
    fi
    main "${@:1}"
fi
