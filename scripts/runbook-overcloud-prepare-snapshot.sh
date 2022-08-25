#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    ${PARENT}/overcloud-host-command-run.sh -b --command 'dnf clean all'
    ${PARENT}/overcloud-host-command-run.sh -b --command 'docker system prune -af'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
