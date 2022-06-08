# kayobe-automation

Scripts and tools for automating Kayobe operations. Intended for use in CI/CD
pipelines.

## Installation

kayobe-automation is typically installed as a Git submodule within a Kayobe
configuration repository. This allows the version of kayobe-automation in use
to be controlled.

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

Configuration for kayobe-automation is typically provided via files in a
`.automation.conf` directory at the root of the kayobe-config repository.
The following files are supported:

* `config.sh`: Mandatory bash script that will be sourced by kayobe-automation
  scripts. Typically it will export environment variables necessary to configure
  kayobe-automation.

Use the examples in examples/\* for inspiration.

## Environment variables

`KAYOBE_URI`: **Deprecated** Kayobe source repository URI. It is preferred to install Kayobe via a `requirements.txt` file in kayobe-config.

`KAYOBE_BRANCH`: **Deprecated** Kayobe source repository branch name. It is preferred to install Kayobe via a `requirements.txt` file in kayobe-config.

`KAYOBE_ENVIRONMENT`: Optional Kayobe environment name.

`KAYOBE_AUTOMATION_CONFIG_PATH`: Path to kayobe-automation configuration directory. Defaults to `.automation.conf` in the kayobe-config root directory.

`KAYOBE_AUTOMATION_SSH_PRIVATE_KEY`: Private key used to login to kayobe managed hosts

`KAYOBE_AUTOMATION_LOG_LEVEL`: Verbosity of logging. Choose one of: `debug`, `info`, `warn`, `error`

`KAYOBE_VAULT_PASSWORD`: Kayobe vault password.

`KAYOBE_AUTOMATION_PR_AUTH_TOKEN`: (Required when `KAYOBE_AUTOMATION_PR_TYPE` is set) Auth token to use when submitting pull-requests. Typically you need to create a service account and generate a person access token.

`TEMPEST_OPENRC`: openrc file to use when running tempest

## Pipeline scripts

kayobe-automation provides various pipeline scripts in the `pipeline`
directory. Many of these are wrappers around Kayobe commands.

## Container images

### Kayobe

kayobe-automation provides a Dockerfile to build a container image for running
commands in `docker/kayobe/`.

Building the image requires the use of [Docker
buildkit](https://docs.docker.com/develop/develop-images/build_enhancements/).

On Ubuntu, you may need to [do the
following](https://blog.sylo.space/can-not-login-docker-account/):
```
sudo apt install golang-docker-credential-helpers
```

To build, from the root of the kayobe-config repository:
```
DOCKER_BUILDKIT=1 docker build --file .automation/docker/kayobe/Dockerfile --tag kayobe:latest .
```

To use the image to run one of the pipeline scripts, from the root of the
kayobe-config repository:
```
docker run -it --rm -v $(pwd):/stack/kayobe-config kayobe:latest /stack/kayobe-config/.automation/pipeline/overcloud-host-configure.sh
```

It may be necessary to provide certain environment variables at runtime, e.g.
`KAYOBE_ENVIRONMENT` or `KAYOBE_VAULT_PASSWORD`. This may be done via `docker
run -e ENV_VAR=value ...`.

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
