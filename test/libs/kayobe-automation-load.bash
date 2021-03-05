#!/bin/bash

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# We can't get path from bats script as it is copied to a temporary directory
export KAYOBE_AUTOMATION_REPO_ROOT="$PARENT/../../"

function kayobe_automation_load {
    . "$KAYOBE_AUTOMATION_REPO_ROOT"/$1 "${@:2}"
    # bats does not support -u
    set +u
}
