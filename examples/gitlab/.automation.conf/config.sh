# Enter config overrides in here

# FIXME: Config validation is failing here: https://github.com/openstack/kayobe/blob/c8d7f2e21b08d212dd5df0a3af9e068215171021/ansible/kolla-ansible.yml#L133
#        As we have not configured the seed network interfaces. Remove this once they are configured.
KAYOBE_EXTRA_ARGS_DEFAULTS="${KAYOBE_EXTRA_ARGS_DEFAULTS:=--skip-tags config-validation}"
KAYOBE_EXTRA_ARGS="${KAYOBE_EXTRA_ARGS:-} ${KAYOBE_EXTRA_ARGS_DEFAULTS}"

KAYOBE_AUTOMATION_TEMPEST_CONF_OVERRIDES="${KAYOBE_AUTOMATION_CONFIG_PATH}/tempest/tempest-production.overrides.conf"

# See: https://github.com/stackhpc/docker-rally/blob/master/bin/rally-verify-wrapper.sh for a full list of tempest parameters that can be overriden.
# You can override tempest parameters like so:
export TEMPEST_CONCURRENCY=2
