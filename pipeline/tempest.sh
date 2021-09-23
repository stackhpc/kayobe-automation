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
    export KAYOBE_AUTOMATION_RALLY_FORCE_PULL="${KAYOBE_AUTOMATION_RALLY_FORCE_PULL=:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME:-}"
    export KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD="${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD:-}"
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

    rally_force_pull_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_FORCE_PULL:+x} ]; then
        rally_force_pull_override="-e rally_force_pull='$KAYOBE_AUTOMATION_RALLY_FORCE_PULL'"
    fi

    rally_docker_registry_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY:+x} ]; then
        rally_docker_registry_override="-e rally_docker_registry='$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY'"
    fi

    rally_docker_registry_username_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME:+x} ]; then
        rally_docker_registry_username_override="-e rally_docker_registry_username='$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_USERNAME'"
    fi

    rally_docker_registry_password_override=""
    if [ ! -z ${KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD:+x} ]; then
        rally_docker_registry_password_override="-e rally_docker_registry_password='$KAYOBE_AUTOMATION_RALLY_DOCKER_REGISTRY_PASSWORD'"
    fi

    mkdir -p $HOME/tempest-artifacts || true
    sudo_if_available chown $USER:$USER $HOME/tempest-artifacts
    run_kayobe_automation_playbook kayobe-automation-run-tempest.yml \
	    -e results_path_local=$HOME/tempest-artifacts \
	    $rally_image_override $rally_tag_override $rally_force_pull_override \
	    $rally_docker_registry_override $rally_docker_registry_username_override \
	    $rally_docker_registry_password_override
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
