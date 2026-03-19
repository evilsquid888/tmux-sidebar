#!/usr/bin/env bash
set -euo pipefail

for test_file in "$@"; do
  printf 'RUN %s\n' "$test_file"
  bash "$test_file"
done
