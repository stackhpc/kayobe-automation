#!/bin/bash

set -euE
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

KAYOBE_AUTOMATION_CONTEXT_SCRIPT="$(basename $1)"

function pull_request_branch_name {
    # script.sh/<uuid> -> script.sh/<script name>/<uuid>
    echo "script-run.sh/$KAYOBE_AUTOMATION_CONTEXT_SCRIPT/$(uuidgen)"
}

function main {
    script=$1
    args=("${@:2}")
    shift $#
    log_info "Running custom script: $script"
    log_debug "Script args: ${args[@]}"
    kayobe_init
    # Use eval so we can do something like: script-run.sh '$KAYOBE_CONFIG_PATH/../../tools/foo.sh'
    # NOTE: KAYOBE_CONFIG_PATH gets defined by kayobe_init
    local SCRIPT_PATH="$(eval echo $script)"
    if ! is_absolute_path "$SCRIPT_PATH"; then
        # Default to a path relative to repository root
        SCRIPT_PATH="$KAYOBE_CONFIG_PATH/../../$SCRIPT_PATH"
    fi
    if [ ! -f "$SCRIPT_PATH" ]; then
        die $LINENO "Script path does not exist: $SCRIPT_PATH"
    fi
    $SCRIPT_PATH "${args[@]}"
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_ENV_PATH}/src/kayobe-config"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a script to run" \
            "Usage: script-run.sh <script>"
    fi
    main "${@:1}"
fi
