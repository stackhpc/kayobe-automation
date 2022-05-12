#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    args=()
    if [ "${KAYOBE_AUTOMATION_SKIP_PRECHECKS}" -ne 0 ]; then
        args+=("--skip-prechecks")
    fi
    run_kayobe overcloud service upgrade "${args[@]}"
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_ENV_PATH}/src/kayobe-config"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@:1}"
fi
