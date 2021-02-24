#!/usr/bin/env bash

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

$PARENT/libs/bats/bin/bats $PARENT/unit/