#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    run_kayobe overcloud service deploy
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_REPO_ROOT}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
