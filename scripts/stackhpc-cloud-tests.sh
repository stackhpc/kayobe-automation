#!/bin/sh

function inject_ssh_keys {
    # These are read when generating kolla passwords
    if [ ! -z ${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY:+x} ]; then
        echo "${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY}" >~/.ssh/"${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME}"
        chmod 600 ~/.ssh/"${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME}"
        ssh-keygen -y -f ~/.ssh/"${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME}" >~/.ssh/"${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME}.pub"
        chmod 600 ~/.ssh/"${KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME}.pub"
    fi
}

sudo chmod 0777 /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/environments/ci-multinode/kolla/passwords.yml
sudo chmod 0777 /stack/vault.password
sudo chmod 0777 /stack/kayobe-automation-env/src/kayobe-config/etc/kayobe/environments/ci-multinode/kolla/certificates/ca/openbao.crt
export KAYOBE_VAULT_PASSWORD=$(cat vault.password)

/stack/kayobe-automation-env/src/kayobe-config/.automation/pipeline/playbook-run.sh '$KAYOBE_CONFIG_PATH/ansible/tools/stackhpc-cloud-tests.yml' -e sct_version=main
