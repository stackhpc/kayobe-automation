#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    ${PARENT}/overcloud-host-configure.sh
    ${PARENT}/overcloud-host-upgrade.sh
    # Avoid services that could break VM connectivity
    ${PARENT}/overcloud-service-upgrade.sh –kolla-skip-tags neutron,nova
    # Upgrade the rest
    ${PARENT}/overcloud-service-upgrade.sh
    ${PARENT}/overcloud-host-command-run.sh -b --command 'docker system prune -af'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
