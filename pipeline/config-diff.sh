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

function post_config_init {
    # Flag that can be used to conditionally set values in kayobe config.
    export KAYOBE_AUTOMATION_CONFIG_DIFF=true

    # Overrides from config.sh
    KAYOBE_CONFIG_SECRET_PATHS_DEFAULT=(
        "etc/kayobe/kolla/passwords.yml"
        "etc/kayobe/secrets.yml"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/secrets.yml"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/kolla/passwords.yml"
        ${KAYOBE_CONFIG_SECRET_PATHS_EXTRA[@]}
    )
    KAYOBE_CONFIG_SECRET_PATHS=("${KAYOBE_CONFIG_SECRET_PATHS[@]:-${KAYOBE_CONFIG_SECRET_PATHS_DEFAULT[@]}}")
    # TODO: could auto detect which files? e.g. "grep -irl "ANSIBLE_VAULT;1" etc/kayobe/kolla/config"
    KAYOBE_CONFIG_VAULTED_FILES_PATHS_DEFAULT=(
        "etc/kayobe/kolla/config/octavia/server_ca.key.pem"
        "etc/kayobe/kolla/config/octavia/client.cert-and-key.pem"
        "etc/kayobe/kolla/config/octavia/client_ca.key.pem"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/kolla/config/octavia/client_ca.key.pem"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/kolla/config/octavia/server_ca.key.pem"
        "etc/kayobe/environments/$KAYOBE_ENVIRONMENT/kolla/config/octavia/client.cert-and-key.pem"
        ${KAYOBE_CONFIG_VAULTED_FILES_PATHS_EXTRA[@]}
    )
    KAYOBE_CONFIG_VAULTED_FILES_PATHS=("${KAYOBE_CONFIG_VAULTED_FILES_PATHS[@]:-${KAYOBE_CONFIG_VAULTED_FILES_PATHS_DEFAULT[@]}}")

    # Some values are currently determined dynamically from container versions
    export KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY="${KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY:-td-agent}"
    export KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_VERSION="${KAYOBE_AUTOMATION_CONFIG_DIFF_FLUENTD_BINARY:-0.14}"

    export KAYOBE_AUTOMATION_CONFIG_DIFF_INJECT_FACTS="${KAYOBE_AUTOMATION_CONFIG_DIFF_INJECT_FACTS=-0}"
    export KAYOBE_AUTOMATION_CONFIG_DIFF_AUTO_UNSET_ENVIRONMENT="${KAYOBE_AUTOMATION_CONFIG_DIFF_AUTO_UNSET_ENVIRONMENT=-0}"

}

function redact_file {
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

    . $env_path/src/kayobe-config/kayobe-env
    . $env_path/venvs/kayobe/bin/activate

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
    kayobe overcloud service configuration generate --node-config-dir "$output_dir"'/{{inventory_hostname}}' --skip-prechecks -e "@$KAYOBE_CONFIG_PATH/../../../kayobe-extra-vars.yml" --kolla-extra-vars "@$KAYOBE_CONFIG_PATH/../../../kolla-extra-vars.yml" ${KAYOBE_EXTRA_ARGS}

    export KAYOBE_VAULT_PASSWORD="$kayobe_vault_password_old"
    export KAYOBE_ENVIRONMENT="$kayobe_environment_old"
}

function main {

    kayobe_init

    # We need to use the same path for source and target to avoid noise in the diff output.
    # Example: https://github.com/openstack/kolla-ansible/blob/5e638b757bdda9fbddf0fe0be5d76caa3419af74/ansible/roles/common/templates/td-agent.conf.j2#L9
    environment_path=/tmp/kayobe-env

    local ANSIBLE_VAULT="$environment_path/venvs/kayobe/bin/ansible-vault"

    # These directories will contain the generated output.
    target_dir=$(mktemp -d --suffix -configgen-target)
    source_dir=$(mktemp -d --suffix -configgen-source)
    target_kayobe_config_dir=$(mktemp -d --suffix -configgen-kayobe-config-target)
    source_kayobe_config_dir=$(mktemp -d --suffix -configgen-kayobe-config-source)

    clean_copy "$KAYOBE_CONFIG_SOURCE_PATH" "$source_kayobe_config_dir"
    clean_copy "$KAYOBE_CONFIG_SOURCE_PATH" "$target_kayobe_config_dir"

    # Checkout the git reference provided as an argument to this script
    checkout "$target_kayobe_config_dir" $1
    create_kayobe_environment "$environment_path" "$target_kayobe_config_dir"
    redact_config_dir "$environment_path"
    # Encryption expected on passwords.yml due to lookup in kayobe, see:
    # https://github.com/openstack/kayobe/blob/869185ea7be5d6b5b21c964a620839d5475196fd/ansible/roles/kolla-ansible/library/kolla_passwords.py#L81
    encrypt_config_dir "$environment_path"
    generate_config "$environment_path" "$target_dir"

    # Move it out the way so that we can use the same path
    mv "$environment_path" "$environment_path-$(date '+%Y-%m-%d-%H.%M.%S')"

    # Perform same steps as above, but for the source branch
    # Merge in the target branch so that we don't see changes that were added since we branched.
    merge "$source_kayobe_config_dir" $1
    create_kayobe_environment "$environment_path" "$source_kayobe_config_dir"
    # Supplying a reference kayobe-config will do a diff on the secrets
    redact_config_dir "$environment_path" "$target_kayobe_config_dir"
    encrypt_config_dir "$environment_path"
    generate_config "$environment_path" "$source_dir"

    # diff gives non-zero exit status if there is a difference
    if sudo_if_available diff -Naur $target_dir $source_dir >/tmp/kayobe-config-diff; then
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
