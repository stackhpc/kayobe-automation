#!/usr/bin/env ./test/libs/bats/bin/bats
load '../libs/bats-support/load'
load '../libs/bats-assert/load'
load '../libs/kayobe-automation'

# NOTE: I've split this out from functions.bats due to the custom setup and
# teardown.

setup() {
    # Backup old options otherwise we can break tests won't run and
    # will show passed.
    OLDOPTS=$(set +o)
    work_dir=$(mktemp -d --suffix kayobe-automation-testing)
    cd "$work_dir"
    git init
    # Restore old options
    case $- in
      *e*) OLDOPTS="$OLDOPTS; set -e";;
      *) OLDOPTS="$OLDOPTS; set +e";;
    esac
}

teardown() {
  set -eu
  rm -rf "$work_dir"
  set +eu
}

@test "git_is_dirty returns false on clean repository" {
  refute is_git_dirty
}

@test "git_is_dirty returns true if file not commited" {
  touch dummy-file
  assert is_git_dirty
}

@test "git_is_dirty returns false if file doesn't match spec" {
  touch dummy-file
  touch dummy-file-2
  refute is_git_dirty "*.yml"
}

@test "git_is_dirty returns true if file matches spec" {
  touch dummy-file
  assert is_git_dirty "*"
}

@test "git_is_dirty returns true if one of patterns matches" {
  touch dummy-file
  touch dummy.txt
  assert is_git_dirty ".yml" "*.txt" "*.py"
}

@test "git_is_dirty returns true with subdirectory match" {
  touch dummy-file
  mkdir test
  touch test/dummy-file.txt
  assert is_git_dirty ".yml" "**/*.txt" "*.py"
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
