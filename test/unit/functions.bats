#!/usr/bin/env ./test/libs/bats/bin/bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'
load '../libs/kayobe-automation'

@test "is_absolute_path returns true if path starts with /" {
  assert is_absolute_path "/tmp/absolute-path"
}

@test "is_absolute_path returns false for relative path" {
  refute is_absolute_path "relative/path"
}

@test "die exits with error message" {
  run die $LINENO "grep-me"
  assert_failure
  assert_output --partial "grep-me"
}
