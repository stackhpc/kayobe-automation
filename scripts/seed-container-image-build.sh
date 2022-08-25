#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    push_arg=""
    # Validation in kayobe_init guarentees we can use numeric comparison.
    if [ "${KAYOBE_AUTOMATION_PUSH_IMAGE}" -ne 0 ]; then
        log_info "Images are configured to be pushed"
        push_arg="--push"
    fi
    run_kayobe seed container image build "${@}" $push_arg
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@:1}"
fi
