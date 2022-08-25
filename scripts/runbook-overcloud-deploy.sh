#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    ${PARENT}/overcloud-host-configure.sh
    ${PARENT}/overcloud-service-deploy.sh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
