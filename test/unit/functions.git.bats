#!/usr/bin/env ./test/libs/bats/bin/bats
load '../libs/bats-support/load'
load '../libs/bats-assert/load'
load '../libs/kayobe-automation'

# NOTE: I've split this out from functions.bats due to the custom setup and
# teardown.

setup() {
    set -eu
    work_dir=$(mktemp -d --suffix kayobe-automation-testing)
    cd "$work_dir"
    git init
    set +eu
}

teardown() {
  set -eu
  rm -rf "$work_dir"
  set +eu
}

@test "git_is_dirty return false on clean repository" {
  refute git_is_dirty $tempdir
}

@test "git_is_dirty return true if file not commited" {
  touch dummy-file
  assert git_is_dirty $tempdir
}

@test "git_untracked_count returns correct count" {
  assert_equal "$(git_untracked_count )" 0
  touch dummy-file
  assert_equal "$(git_untracked_count )" 1
  touch dummy-file-2
  assert_equal "$(git_untracked_count )" 2
}

@test "git_modified_count returns correct count" {
  assert_equal "$(git_modified_count)" 0
  touch dummy-file
  assert_equal "$(git_modified_count)" 0
  git add dummy-file
  assert_equal "$(git_modified_count)" 0
  git commit -m "dummy commit"
  assert_equal "$(git_modified_count)" 0
  echo "test" > dummy-file
  assert_equal "$(git_modified_count)" 1
}
