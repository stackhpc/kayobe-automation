
# Enter config overrides in here

# FIXME: Config validation is failing here: https://github.com/openstack/kayobe/blob/c8d7f2e21b08d212dd5df0a3af9e068215171021/ansible/kolla-ansible.yml#L133
#        As we have not configured the seed network interfaces. Remove this once they are configured.
KAYOBE_EXTRA_ARGS_DEFAULTS="${KAYOBE_EXTRA_ARGS_DEFAULTS:=--skip-tags config-validation}"
KAYOBE_EXTRA_ARGS="${KAYOBE_EXTRA_ARGS:-} ${KAYOBE_EXTRA_ARGS_DEFAULTS}"
