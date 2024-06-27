#!/bin/bash

set -euE
set -o pipefail

# Outputs a kolla-config diff between source and target branches

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"

# We want to setup an environment for the source and target branches, so
# skip setting up the default one by undefining the functions that perform
# the steps we do not want to do not want to perform in the init function
unset environment_setup

function validate {
    # Does nothing at the moment, but we want to do something in here a later date.
    true
}

function post_config_set {
    # This pipeline shouldn't create pull requests
    KAYOBE_AUTOMATION_PR_TYPE=disabled
}

function pre_config_init {
    # Flag that can be used to conditionally set values in kayobe config.
    export KAYOBE_AUTOMATION_CONFIG_DIFF=1
}

function post_config_init {
    KAYOBE_CONFIG_SECRET_PATHS_DEFAULT=(
        "etc/kayobe/kolla/passwords.yml"
        "etc/kayobe/secrets.yml"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/secrets.yml"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/kolla/passwords.yml"
        ${KAYOBE_CONFIG_SECRET_PATHS_EXTRA[@]}
    )
    KAYOBE_CONFIG_SECRET_PATHS=("${KAYOBE_CONFIG_SECRET_PATHS[@]:-${KAYOBE_CONFIG_SECRET_PATHS_DEFAULT[@]}}")

    find_redacted_files "/stack/kayobe-automation-env/src/kayobe-config/etc/kayobe"

    # Some values are currently determined dynamically from container versions
    export KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY="${KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY:-td-agent}"
    export KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_VERSION="${KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY:-0.14}"

    export KAYOBE_AUTOMATION_CONFIG_DIFF_INJECT_FACTS="${KAYOBE_AUTOMATION_CONFIG_DIFF_INJECT_FACTS=-0}"
    export KAYOBE_AUTOMATION_CONFIG_DIFF_AUTO_UNSET_ENVIRONMENT="${KAYOBE_AUTOMATION_CONFIG_DIFF_AUTO_UNSET_ENVIRONMENT=-0}"
}

function find_redacted_files {
    KAYOBE_CONFIG_VAULTED_FILES_PATHS=()
    local directory="$1"

    echo $directory

    # Search for vaulted files recursively in the directory
    while IFS= read -r -d '' file; do
        if grep -q "ANSIBLE_VAULT;1" "$file"; then
            truncated_path="${file#"$directory/"}"
            vaulted_file="etc/kayobe/$truncated_path"
            if ! [[ "${KAYOBE_CONFIG_SECRET_PATHS_DEFAULT[*]}" =~ "$vaulted_file" ]]; then
                KAYOBE_CONFIG_VAULTED_FILES_PATHS+=("etc/kayobe/$truncated_path")
            fi
        fi
    done < <(find "$directory" -type f -print0)
    echo ${KAYOBE_CONFIG_VAULTED_FILES_PATHS[*]}
}

function redact_file {
    if [ ! -z ${ANSIBLE_VERBOSITY:+x} ]; then
        _ANSIBLE_VERBOSITY=$ANSIBLE_VERBOSITY
    fi
    unset ANSIBLE_VERBOSITY
    if [ ! -f "$1" ]; then
        log_info "Skipping redaction of: $1"
        return
    fi
    log_info Redacting $1 with reference ${2:-None}
    export KAYOBE_AUTOMATION_VAULT_PASSWORD="$KAYOBE_VAULT_PASSWORD"
    if [ "$2" != "" ] && [ -e "$2" ]; then
        $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-redact <($ANSIBLE_VAULT view --vault-password-file $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-vault-helper $1) <($ANSIBLE_VAULT view --vault-password-file $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-vault-helper $2) >$1.redact
    else
        $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-redact <($ANSIBLE_VAULT view --vault-password-file $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-vault-helper $1) >$1.redact
    fi
    mv $1.redact $1
    if [ ! -z ${_ANSIBLE_VERBOSITY:+x} ]; then
        export ANSIBLE_VERBOSITY=$_ANSIBLE_VERBOSITY
    fi
}

function encrypt_file {
    if [ ! -f "$1" ]; then
        return
    fi
    log_info Encrypting $1
    export KAYOBE_AUTOMATION_VAULT_PASSWORD=dummy-password
    $ANSIBLE_VAULT encrypt --vault-password-file $KAYOBE_AUTOMATION_UTILS_PATH/kayobe-automation-vault-helper $1
}

function redact_config_dir {
    declare -A unique_paths
    for item in "${KAYOBE_CONFIG_SECRET_PATHS[@]}"; do
        if [ ! -e "$1/src/kayobe-config/$item" ]; then
            continue
        fi
        reference=""
        if [ ! -z "${2:+x}" ]; then
            reference="$2/$item"
        fi
        unique_paths[$(realpath "$1/src/kayobe-config/$item")]="$reference"
    done

    for item in "${!unique_paths[@]}"; do
        redact_file "$item" "${unique_paths[$item]}"
    done

    # replace vaulted files with md5sum of the vaulted file
    for item in "${KAYOBE_CONFIG_VAULTED_FILES_PATHS[@]}"; do
        # skip if file doesn't exist
        if [ -f "$1/src/kayobe-config/$item" ]; then
            md5sum "$1/src/kayobe-config/$item" | cut -d " " -f 1 >"$1/src/kayobe-config/$item"
        fi
    done
}

function encrypt_config_dir {
    declare -A unique_paths
    for item in "${KAYOBE_CONFIG_SECRET_PATHS[@]}"; do
        if [ ! -e "$1/src/kayobe-config/$item" ]; then
            continue
        fi
        unique_paths[$(realpath "$1/src/kayobe-config/$item")]=1
    done

    for item in "${!unique_paths[@]}"; do
        encrypt_file "$item"
    done
}

function checkout {
    pushd $1
    git checkout $2
    popd
}

function merge {
    pushd $1
    git merge --no-edit $2
    popd
}

function post_workarounds {
    # These files must exist if ironic is enabled. Use dummy files to prevent task from
    # failing which expects these files to be present.
    sudo_if_available mkdir -p /opt/kayobe/images/ipa/
    sudo_if_available touch /opt/kayobe/images/ipa/ipa.kernel
    sudo_if_available touch /opt/kayobe/images/ipa/ipa.initramfs
    # NOTE: We can remove this when we no longer care about train. It has been renamed in
    # future versions.
    sudo_if_available touch /opt/kayobe/images/ipa/ipa.vmlinuz
}

function generate_config {
    # TODO: Support different kayobe versions for source and target? Need to think about
    # whether to always use latest automation code or whether to use version commited on
    # on branch.
    # These override the kayobe-env defautlts if set:
    unset KOLLA_VENV_PATH
    unset KOLLA_SOURCE_PATH
    env_path=$1
    output_dir=$2

    # Shift arguments passed to the function so the sourced scripts don't get
    # them as well. See https://unix.stackexchange.com/a/151896 for details.
    shift $#

    set +eu
    . $env_path/src/kayobe-config/kayobe-env
    . $env_path/venvs/kayobe/bin/activate
    set -eu

    local kayobe_environment_path="$env_path/src/kayobe-config/etc/kayobe/environments/${KAYOBE_ENVIRONMENT}"
    local kayobe_ansible_path="$env_path/venvs/kayobe/share/kayobe/ansible"
    local kayobe_environment_old="${KAYOBE_ENVIRONMENT}"
    local kayobe_vault_password_old="$KAYOBE_VAULT_PASSWORD"

    if [ ! -d "${kayobe_environment_path}" ] && [ ${KAYOBE_AUTOMATION_CONFIG_DIFF_AUTO_UNSET_ENVIRONMENT} -ne 0 ]; then
        # For compatability with non-multi environments setup.
        log_warn "Environment folder: ${kayobe_environment_path} not found. Unsetting kayobe environment."
        unset KAYOBE_ENVIRONMENT
    fi

    export KAYOBE_VAULT_PASSWORD=dummy-password

    kayobe control host bootstrap
    log_info "Generating config to $output_dir"
    kayobe playbook run "$kayobe_ansible_path/kayobe-automation-prepare-config-diff.yml"
    kolla_ansible_cfg=$env_path/src/kayobe-config/etc/kayobe/kolla/ansible.cfg
    crudini --set $kolla_ansible_cfg defaults gathering smart
    crudini --set $kolla_ansible_cfg defaults fact_caching jsonfile
    crudini --set $kolla_ansible_cfg defaults fact_caching_connection $env_path/src/kayobe-config/kayobe-automation-config-diff-kolla-facts

    declare -a kolla_limit
    if [ ! -z ${KOLLA_LIMIT:+x} ]; then
        kolla_limit=(--kolla-limit "$KOLLA_LIMIT")
    fi

    declare -a kolla_tags
    if [ ! -z ${KOLLA_TAGS:+x} ]; then
        kolla_tags=(--kolla-tags "$KOLLA_TAGS")
    fi

    declare -a kayobe_tags
    if [ ! -z ${KAYOBE_TAGS:+x} ]; then
        kayobe_tags=(--tags "$KAYOBE_TAGS")
    fi

    declare -a kayobe_limit
    if [ ! -z ${KAYOBE_LIMIT:+x} ]; then
        kayobe_limit=(--limit "$KAYOBE_LIMIT")
    fi

    kayobe overcloud service configuration generate --node-config-dir "$output_dir"'/{{inventory_hostname}}' --skip-prechecks -e "@$KAYOBE_CONFIG_PATH/../../../kayobe-extra-vars.yml" --kolla-extra-vars "@$KAYOBE_CONFIG_PATH/../../../kolla-extra-vars.yml" "${kayobe_limit[@]}" "${kayobe_tags[@]}" "${kolla_limit[@]}" "${kolla_tags[@]}" ${KAYOBE_EXTRA_ARGS}

    export KAYOBE_VAULT_PASSWORD="$kayobe_vault_password_old"
    export KAYOBE_ENVIRONMENT="$kayobe_environment_old"
}

function main {

    kayobe_init

    # These directories will contain the generated output.
    target_dir=$(mktemp -d --suffix -configgen-target)
    source_dir=$(mktemp -d --suffix -configgen-source)
    target_kayobe_config_dir=$(mktemp -d --suffix -configgen-kayobe-config-target)
    source_kayobe_config_dir=$(mktemp -d --suffix -configgen-kayobe-config-source)

    clean_copy "$KAYOBE_CONFIG_SOURCE_PATH" "$source_kayobe_config_dir"
    clean_copy "$KAYOBE_CONFIG_SOURCE_PATH" "$target_kayobe_config_dir"

    function normalize_file_text() {
        local file="$1"
        local text="$2"

        sed -i "s#/tmp/$text/\(.*\)#/tmp/\1#g" "$file"
    }

    function normalize_files_in_folder() {
        local folder="$1"
        local text="$2"

        # Find all files in the folder and its subfolders and loop through them
        find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
            normalize_file_text "$file" "$text"
        done
    }

    function generate_target_config {
        target_environment_path=/tmp/target-kayobe-env
        export ANSIBLE_LOG_PATH=/tmp/target-kayobe.log
        local ANSIBLE_VAULT="$target_environment_path/venvs/kayobe/bin/ansible-vault"
        # Checkout the git reference provided as an argument to this script
        checkout "$target_kayobe_config_dir" $1
        create_kayobe_environment "$target_environment_path" "$target_kayobe_config_dir"
        redact_config_dir "$target_environment_path"
        encrypt_config_dir "$target_environment_path"
        generate_config "$target_environment_path" "$target_dir"
        normalize_files_in_folder "$target_environment_path" "target-kayobe-env"
    }

    function generate_source_config {
        source_environment_path=/tmp/source-kayobe-env
        export ANSIBLE_LOG_PATH=/tmp/source-kayobe.log
        local ANSIBLE_VAULT="$source_environment_path/venvs/kayobe/bin/ansible-vault"
        # Perform same steps as above, but for the source branch
        # Merge in the target branch so that we don't see changes that were added since we branched.
        merge "$source_kayobe_config_dir" $1
        find_redacted_files "$source_kayobe_config_dir/etc/kayobe"
        create_kayobe_environment "$source_environment_path" "$source_kayobe_config_dir"
        redact_config_dir "$source_environment_path" "$target_kayobe_config_dir"
        encrypt_config_dir "$source_environment_path"
        generate_config "$source_environment_path" "$source_dir"
        normalize_files_in_folder "$source_environment_path" "source-kayobe-env"
    }

    generate_target_config $1 >/dev/null 2>&1 &
    generate_source_config $1 &
    wait < <(jobs -p)

    # diff gives non-zero exit status if there is a difference
    if sudo_if_available diff -Nur $target_dir $source_dir >/tmp/kayobe-config-diff; then
        echo 'The diff was empty!'
    else
        echo 'The diff was non-empty. Please check the diff output.'
        cat /tmp/kayobe-config-diff
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 1 ]; then
        die $LINENO "Error: You must provide a git ref to compare to." \
            "Usage: config-diff.sh <git ref>"
    fi
    main "$1"
fi
