#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    export KAYOBE_SKIP_TAGS="${KAYOBE_SKIP_TAGS:+${KAYOBE_SKIP_TAGS},}kayobe-generate-config"
    run_kayobe overcloud deployment image build --force-rebuild "${@}"
    pull_request "${KAYOBE_AUTOMATION_ENV_KAYOBE_CONFIG_PATH}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@:1}"
fi
