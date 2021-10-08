#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function post_config_init {
    export KAYOBE_AUTOMATION_PACKAGES="${KAYOBE_AUTOMATION_PACKAGES:-*}"
}

function main {
    kayobe_init
    run_kayobe seed hypervisor host package update --packages "$KAYOBE_AUTOMATION_PACKAGES"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
