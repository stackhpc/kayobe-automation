#!/usr/bin/env ./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'
load '../libs/kayobe-automation-load'

kayobe_automation_load cd/playbook-run.sh this/is/a/test.yml

@test "pull_request_branch_name includes playbook name" {
  run pull_request_branch_name
  assert_output --partial "playbook-run.sh/test.yml/"
}