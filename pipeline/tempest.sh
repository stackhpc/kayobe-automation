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
    export KAYOBE_AUTOMATION_RALLY_IMAGE="${KAYOBE_AUTOMATION_RALLY_IMAGE:-}"
    export KAYOBE_AUTOMATION_RALLY_TAG="${KAYOBE_AUTOMATION_RALLY_TAG:-}"
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/load-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST=${KAYOBE_AUTOMATION_TEMPEST_LOADLIST:-default}
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_LOADLIST}}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/skip-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST=${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST:-$KAYOBE_AUTOMATION_TEMPEST_LOADLIST}
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST}}"
}

function main {
    kayobe_init
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES}" ]; then
        log_info "Configuring tempest.conf overrides"
        export TEMPEST_CONF_OVERRIDES="$(<$KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES)"
    fi
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH}" ]; then
        log_info "Configuring load list"
        export TEMPEST_LOAD_LIST="$(<$KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH)"
    fi
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH}" ]; then
        log_info "Configuring skip list"
        export TEMPEST_SKIP_LIST="$(<$KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH)"
    fi

    rally_image_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_IMAGE:+x} ]; then
        rally_image_override="-e rally_image='$KAYOBE_AUTOMATION_RALLY_IMAGE'"
    fi

    rally_tag_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_TAG:+x} ]; then
        rally_tag_override="-e rally_tag='$KAYOBE_AUTOMATION_RALLY_TAG'"
    fi

    mkdir -p $HOME/tempest-artifacts || true
    sudo_if_available chown $USER:$USER $HOME/tempest-artifacts
    run_kayobe_automation_playbook kayobe-automation-run-tempest.yml -e results_path_local=$HOME/tempest-artifacts $rally_image_override $rally_tag_override
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
