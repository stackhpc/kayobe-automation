#!/bin/bash

set -eu
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

KAYOBE_AUTOMATION_CONTEXT_PLAYBOOK="$(basename $1)"

function pull_request_branch_name {
    # playbook.sh/<uuid> -> playbook.sh/<playbook name>/<uuid>
    echo "playbook-run.sh/$KAYOBE_AUTOMATION_CONTEXT_PLAYBOOK/$(uuidgen)"
}

function main {
    log_info "Running custom playbook: $1"
    kayobe_init
    # Use eval so we can do something like: playbook-run.sh '$KAYOBE_CONFIG_PATH/ansible/test.yml'
    # NOTE: KAYOBE_CONFIG_PATH gets defined by kayobe_init
    local PLAYBOOK_PATH="$(eval echo $1)"
    if ! is_absolute_path "$PLAYBOOK_PATH"; then
        # Default to a path relative to repository root
        PLAYBOOK_PATH="$KAYOBE_CONFIG_PATH/../../$PLAYBOOK_PATH"
    fi
    if [ ! -f "$PLAYBOOK_PATH" ]; then
        die $LINENO "Playbook path does not exist: $PLAYBOOK_PATH"
    fi
    run_kayobe playbook run "$PLAYBOOK_PATH"
    pull_request "${KAYOBE_AUTOMATION_CONTEXT_REPO_ROOT}"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a playbook to run" \
            "Usage: playbook-run.sh <playbook>"
    fi
    main "$1"
fi
