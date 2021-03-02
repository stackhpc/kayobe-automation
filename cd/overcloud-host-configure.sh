#!/bin/bash

set -eu
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    run_kayobe overcloud host configure
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_REPO_ROOT}"
}

main
