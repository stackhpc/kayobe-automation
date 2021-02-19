#!/bin/bash

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${PARENT}/../../functions"

# bats does not support -u
set +u