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
