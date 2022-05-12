#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    kayobe_init
    args=()
    # Validation in kayobe_init guarentees we can use numeric comparison.
    if [ "${KAYOBE_AUTOMATION_PUSH_IMAGE}" -ne 0 ]; then
        log_info "Images are configured to be pushed"
        args+=("--push")
    fi
    if [ ! -z ${KAYOBE_AUTOMATION_CONTAINER_BUILD_REGEX:+x} ]; then
        args+=("$KAYOBE_AUTOMATION_CONTAINER_BUILD_REGEX")
    fi
    run_kayobe overcloud container image build "${args[@]}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
