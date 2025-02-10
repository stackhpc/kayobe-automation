#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function post_validate {
    if [ ! -z ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES:+x} ] && [ ! -f "${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES}" ]; then
        die $LINENO "KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES: ${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES} does not exist"
    fi
    # Special case the default value of 'default'.
    if [ "$(basename $KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH)" != "default" ] &&
        [ ! -f $KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH ]; then
        die $LINENO "KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH: ${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH} does not exist"
    fi
}

function post_config_set {
    # This pipeline shouldn't create pull requests
    KAYOBE_AUTOMATION_PR_TYPE=disabled
}

function post_config_init {
    export KAYOBE_AUTOMATION_RALLY_IMAGE="${KAYOBE_AUTOMATION_RALLY_IMAGE:-}"
    export KAYOBE_AUTOMATION_RALLY_TAG="${KAYOBE_AUTOMATION_RALLY_TAG:-}"
    export KAYOBE_AUTOMATION_RALLY_FORCE_PULL="${KAYOBE_AUTOMATION_RALLY_FORCE_PULL:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD:-}"
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/load-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST=${KAYOBE_AUTOMATION_TEMPEST_LOADLIST:-default}
    export KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_LOADLIST}}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/skip-lists}"
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST=${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST:-$KAYOBE_AUTOMATION_TEMPEST_LOADLIST}
    export KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST}}"
    export KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_SEARCH_PATH="${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_SEARCH_PATH:-${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/accounts}"
    export KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS=${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS:-INVALID_ACCOUNTS_PATH}
    export KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_FULL_PATH="${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_FULL_PATH:-${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_SEARCH_PATH}/${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS}}"
}

function main {
    kayobe_init
    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES}" ]; then
        log_info "Configuring tempest.conf overrides"
        export TEMPEST_CONF_OVERRIDES="$(<$KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES)"
    fi

    args=("-e" "results_path_local=$HOME/tempest-artifacts")

    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH}" ]; then
        log_info "Configuring load list"
        args+=("-e" "tempest_load_list_path=$KAYOBE_AUTOMATION_TEMPEST_LOADLIST_FULL_PATH")
    fi

    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH}" ]; then
        log_info "Configuring skip list"
        args+=("-e" "tempest_skip_list_path=$KAYOBE_AUTOMATION_TEMPEST_SKIPLIST_FULL_PATH")
    fi

    if [ -f "${KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_FULL_PATH}" ]; then
        log_info "Configuring pre-provisioned accounts"
        args+=("-e" "tempest_accounts_path=$KAYOBE_AUTOMATION_TEMPEST_ACCOUNTS_FULL_PATH")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_IMAGE:+x} ]; then
        args+=("-e" "rally_image=$KAYOBE_AUTOMATION_RALLY_IMAGE")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_TAG:+x} ]; then
        args+=("-e" "rally_tag=$KAYOBE_AUTOMATION_RALLY_TAG")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_FORCE_PULL:+x} ]; then
        args+=("-e" "rally_force_pull=$KAYOBE_AUTOMATION_RALLY_FORCE_PULL")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY:+x} ]; then
        args+=("-e" "rally_docker_registry=$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME:+x} ]; then
        args+=("-e" "rally_docker_registry_username=$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD:+x} ]; then
        args+=("-e" "rally_docker_registry_password=$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD")
    fi

    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_NO_SENSITIVE_LOG:+x} ]; then
        args+=("-e" "rally_no_sensitive_log=$KAYOBE_AUTOMATION_RALLY_NO_SENSITIVE_LOG")
    fi

    args+=("${@}")

    mkdir -p $HOME/tempest-artifacts || true
    sudo_if_available chown $USER:$USER $HOME/tempest-artifacts

    run_kayobe_automation_playbook kayobe-automation-run-tempest.yml "${args[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@:1}"
fi
