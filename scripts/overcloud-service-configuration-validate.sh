#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    output_dir=("${@:1}")
    log_info "Running overcloud service configuration validate --output-dir ${output_dir[@]}"
    kayobe_init
    run_kayobe overcloud service configuration validate --output-dir ${output_dir[@]}
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide an output_dir to use" \
            "Usage: overcloud-service-configuration-validate.sh <output_dir>"
    fi
    main "${@:1}"
fi
