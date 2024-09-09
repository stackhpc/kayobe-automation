#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    run_kayobe overcloud database recover "${@}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@:1}"
fi
