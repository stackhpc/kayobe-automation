#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"


function main {
    kayobe_init
    args=()
    git merge --no-edit $1
    run_kayobe overcloud service prechecks "${args[@]}" "${@}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a git ref." \
            "Usage: overcloud-service-prechecks.sh <git ref>"
    fi
    main "$1"
fi
