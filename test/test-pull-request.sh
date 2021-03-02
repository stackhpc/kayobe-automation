#!/bin/bash

set -eu
set -o pipefail

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

function main {
    # This is a manually run test that will submit a gitlab PR. Variables are a bit hardcoded.
    # You need to export a valid personal access token with:
    # export KAYOBE_AUTOMATION_PR_AUTH_TOKEN=mytoken
    export KAYOBE_AUTOMATION_PR_TYPE="${KAYOBE_AUTOMATION_PR_TYPE:-gitlab}"
    export KAYOBE_AUTOMATION_PR_TITLE="Testing that merge requests work"

    if [ "$KAYOBE_AUTOMATION_PR_TYPE" == "gitlab" ]; then
        export KAYOBE_AUTOMATION_PR_TARGET_BRANCH=master
        export KAYOBE_AUTOMATION_PR_GITLAB_PROJECT_ID=24715064
        local repo=https://will70:${KAYOBE_AUTOMATION_PR_AUTH_TOKEN}@gitlab.com/will70/test
        # This now gets automatically set
        #export KAYOBE_AUTOMATION_PR_URL=https://gitlab.com/api/v4/projects/$KAYOBE_AUTOMATION_PR_GITLAB_PROJECT_ID/merge_requests
    elif [ "$KAYOBE_AUTOMATION_PR_TYPE" == "github" ]; then
        local owner=jovial
        local repository=test-pr
        export KAYOBE_AUTOMATION_PR_TARGET_BRANCH=main
        export KAYOBE_AUTOMATION_PR_GITHUB_USER=jovial
        export KAYOBE_AUTOMATION_PR_URL="https://api.github.com/repos/${owner}/${repository}/pulls"
        local repo="https://${KAYOBE_AUTOMATION_PR_GITHUB_USER}:${KAYOBE_AUTOMATION_PR_AUTH_TOKEN}@github.com/${owner}/${repository}"
    else
        die $LINENO "Unsupported value for KAYOBE_AUTOMATION_PR_TYPE: $KAYOBE_AUTOMATION_PR_TYPE"
    fi

    # Should report clean ..
    export KAYOBE_AUTOMATION_PR_PATHSPEC="dummy"
    # Should report dirty
    export KAYOBE_AUTOMATION_PR_PATHSPEC="dummy *file"

    config_init

    local fake_git_path=/tmp/kayobe-automation-fake-git/
    rm -rf "$fake_git_path" || true
    git clone $repo $fake_git_path
    cd "$fake_git_path"
    echo "$(uuidgen)" > $fake_git_path/file
    pull_request $fake_git_path
}

main
