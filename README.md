# kayobe-automation

WARNING: Experimental

Scripts for automating kayobe.

## Installation

Check out your kayobe-config repository and add the submodule.

    cd <kayobe-config-repository>
    git submodule add https://github.com/stackhpc/kayobe-automation.git .automation
    cd .automation
    git checkout 0.0.1
    cd ..
    git add .automation
    git add .gitmodules
    git commit -m "Add kayobe-automation"

Where `0.0.1` is the tag of the release you want to use. The submodule will act
like a separate git respository, so if you make any changes you will to change
into `.automation` directory and commit those separately.

You can change the branch at a later date with:

    cd .automation
    git checkout <new-tag>
    cd ..
    git add .automation
    git commit -m "Update kayobe-automation"

## Configuration

Use the examples in examples/* for inspiration.

## Environment variables

`KAYOBE_AUTOMATION_SSH_PRIVATE_KEY`: Private key used to login to kayobe managed hosts

`KAYOBE_AUTOMATION_LOG_LEVEL`: Verbosity of logging. Choose one of: `debug`, `info`, `warn`, `error`

`KAYOBE_VAULT_PASSWORD`: Kayobe vault password.

`KAYOBE_AUTOMATION_PR_AUTH_TOKEN`: (Required when `KAYOBE_AUTOMATION_PR_TYPE` is set) Auth token to use when submitting pull-requests. Typically you need to create a service account and generate a person access token.

`TEMPEST_OPENRC`: openrc file to use when running tempest

## gitlab

You need to customise `/etc/gitlab-runner/config.toml` to add support for docker in docker:

    [[runners]]
      name = "seed"
      url = "https://gitlab.com/"
      token = "redacted"
      executor = "docker"
      [runners.custom_build_dir]
      [runners.cache]
        [runners.cache.s3]
        [runners.cache.gcs]
        [runners.cache.azure]
      [runners.docker]
        tls_verify = false
        image = "centos:8"
        privileged = true
        disable_entrypoint_overwrite = false
        oom_kill_disable = false
        disable_cache = false
        volumes = ["/certs/client", "/cache", "/opt/kayobe/images"]
        shm_size = 0

This also uses a volume so that IPA images can be shared between pipelines.

## Formatting

Dependencies: go

Install the git hooks:

    [stack@seed .automation]$ virtualenv ~/will/venv/pre-commit
    [stack@seed .automation]$ source ~/will/venv/pre-commit/bin/activate
    (pre-commit) [stack@seed .automation]$ pip install pre-commit
    (pre-commit) [stack@seed .automation]$ pre-commit install

This will run the formatter on commit.

To run manually:

    (pre-commit) [stack@seed .automation]$ pre-commit run --all-files
