#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function post_validate {
    if [ ! -z ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES:+x} ] && [ ! -f "${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES}" ]; then
        die $LINENO "KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES: ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES} does not exist"
    fi
}

function post_config_set {
    # This pipeline shouldn't create pull requests
    KAYOBE_AUTOMATION_PR_TYPE=disabled
}

function post_config_init {
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/load-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST=${KAYOBE_AUTOMATION_TEMPEST_LOADLIST:-default}
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_LOADLIST}}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/skip-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST=${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST:-$KAYOBE_AUTOMATION_TEMPEST_LOADLIST}
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST}}"
}

function main {
    call_with_hooks config_init
    call_with_hooks validate
    mkdir /home/rally/artifacts || true
    if [ ! -z ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES:+x} ]; then
        log_info "Configuring tempest.conf overrides"
        cp ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES} ~/tempest-overrides.conf
    fi
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH}" ]; then
        log_info "Configuring load list"
        cp ${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH} ~/tempest-load-list
    fi
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH}" ]; then
        log_info "Configuring skip list"
        cp ${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH} ~/tempest-skip-list
    fi
    # TODO(johngarbutt) add tempest extensions via config
    rally verify add-verifier-ext --source https://github.com/stackhpc/vipu_tempest_plugin.git --id default
    rally verify list-verifier-tests --id default
    /usr/bin/rally-verify-wrapper.sh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
