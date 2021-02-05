#!/bin/bash

set -eu
set -o pipefail

# Outputs a kolla-config diff between source and target branches

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../functions"


function validate {
    # Does nothing at the moment, but we want to do something in here a later date.
    true
}

function config_extras {
    # Overrides from config.sh
    KAYOBE_CONFIG_SECRET_PATHS_DEFAULT=( "etc/kayobe/kolla/passwords.yml" "etc/kayobe/secrets.yml")
    KAYOBE_CONFIG_SECRET_PATHS=("${KAYOBE_CONFIG_SECRET_PATHS[@]:-${KAYOBE_CONFIG_SECRET_PATHS_DEFAULT[@]}}")
}

function redact_file {
    echo Redacting $1 with reference ${2:-None}
    export ANSIBLE_VAULT_PASSWORD="$KAYOBE_VAULT_PASSWORD"
    if [ "$2" != "" ]; then
        $KAYOBE_HELPERS_PATH/redact.py <(ansible-vault view --vault-password-file $KAYOBE_HELPERS_PATH/vault-helper.sh $1) <(ansible-vault view --vault-password-file $KAYOBE_HELPERS_PATH/vault-helper.sh $2) > $1.redact
    else
        $KAYOBE_HELPERS_PATH/redact.py <(ansible-vault view --vault-password-file $KAYOBE_HELPERS_PATH/vault-helper.sh $1) > $1.redact
    fi
    mv $1.redact $1
}

function encrypt_file {
    echo Encrypting $1
    export ANSIBLE_VAULT_PASSWORD=dummy-password
    ansible-vault encrypt --vault-password-file $KAYOBE_HELPERS_PATH/vault-helper.sh $1
}

function redact_config_dir {
   for item in "${KAYOBE_CONFIG_SECRET_PATHS[@]}"; do
      reference=""
      if [ "$2" != "" ]; then
        reference="$2/src/kayobe-config/$item"
      fi
      redact_file "$1/src/kayobe-config/$item" "$reference"
   done
}

function encrypt_config_dir {
   for item in "${KAYOBE_CONFIG_SECRET_PATHS[@]}"; do
      encrypt_file "$1/src/kayobe-config/$item"
   done
}

function init {
    config_init
    config_extras
    validate
    environment_diagnostics
    install_dependencies
    workaround_start_sshd
    install_kayobe_venv
    environment_setup
    workarounds
}

function prepare_config_dir {
    # $1: directory to clone to
    # $2: ref to checkout
    mkdir -p $1/src/kayobe-config
    cp -rf "$KAYOBE_REPO_ROOT" "$1/src/kayobe-config"
    if [ "$2" != "" ]; then
      cd $1/src/kayobe-config
      git checkout $2
    fi
}

function workarounds {
  # These files must exist if ironic is enabled
  sudo_if_available mkdir -p /opt/kayobe/images/ipa/
  sudo_if_available touch /opt/kayobe/images/ipa/ipa.kernel
  sudo_if_available touch /opt/kayobe/images/ipa/ipa.initramfs
}

function generate_config {
    # TODO: Support different kayobe versions for source and target? Need to think about
    # whether to always use latest automation code or whether to use version commited on
    # on branch.
    # These override the kayobe-env defautlts if set:
    unset KOLLA_VENV_PATH
    unset KOLLA_SOURCE_PATH
    . $1/src/kayobe-config/kayobe-env
    export KAYOBE_VAULT_PASSWORD_OLD=$KAYOBE_VAULT_PASSWORD
    export KAYOBE_VAULT_PASSWORD=dummy-password
    kayobe control host bootstrap
    output_dir=$1/output
    echo "Generating config to $output_dir"
    kayobe playbook run "$KAYOBE_ANSIBLE_PATH/kayobe-automation-prepare-config-diff.yml"
    kayobe overcloud service configuration generate --node-config-dir "$output_dir"'/{{inventory_hostname}}' --skip-prechecks -e "@$KAYOBE_CONFIG_PATH/../../../kayobe-extra-vars.yml" --kolla-extra-vars "@$KAYOBE_CONFIG_PATH/../../../kolla-extra-vars.yml" ${KAYOBE_EXTRA_ARGS}
    export KAYOBE_VAULT_PASSWORD=$KAYOBE_VAULT_PASSWORD_OLD
}

function main {

    init

    target_dir=$(mktemp -d --suffix -configgen-target)
    source_dir=$(mktemp -d --suffix -configgen-source)

    prepare_config_dir "$target_dir" $1
    prepare_config_dir "$source_dir" ""

    # Order is important as we need to reference target_dir before we redact it
    redact_config_dir $source_dir $target_dir
    redact_config_dir $target_dir ""

    # Encryption expected on passwords.yml due to lookup in kayobe, see:
    # https://github.com/openstack/kayobe/blob/869185ea7be5d6b5b21c964a620839d5475196fd/ansible/roles/kolla-ansible/library/kolla_passwords.py#L81
    #
    # We need to compare the unencrypted files to generate "changed" strings,
    # so encryption must be in a separate step after prepare and redact
    encrypt_config_dir "$target_dir"
    encrypt_config_dir "$source_dir"

    generate_config "$target_dir"
    generate_config "$source_dir"

    # diff gives non-zero exit status if there is a difference
    if sudo_if_available diff -Naur $target_dir/output $source_dir/output > /tmp/kayobe-config-diff; then
        echo 'The diff was empty!'
    else
        echo 'The diff was non-empty. Please check the diff output.'
    fi
}

if [ "$#" -lt 1 ]; then
    die $LINENO "Error: You must provide a git ref to compare to." \
                "Usage: config-diff.sh <git ref>"
fi

main $1
