#!/bin/bash
set -euo pipefail

test_root=$(mktemp -d /tmp/mac-storage-auditor-test.XXXXXX)
trap 'rm -rf "$test_root"' EXIT

fake_home="$test_root/home"
mkdir -p \
  "$fake_home/Library/Caches/example-cache" \
  "$fake_home/Library/Application Support/example-app" \
  "$fake_home/Documents/demo/node_modules/pkg" \
  "$fake_home/Downloads" \
  "$fake_home/Desktop" \
  "$fake_home/Developer" \
  "$fake_home/Movies" \
  "$fake_home/.Trash"

printf 'cache' >"$fake_home/Library/Caches/example-cache/item"
printf 'state' >"$fake_home/Library/Application Support/example-app/state"
printf 'dependency' >"$fake_home/Documents/demo/node_modules/pkg/index.js"

report="$test_root/report.md"
bash "$(dirname "$0")/../skills/mac-storage-auditor/scripts/scan_macos_storage.sh" \
  --home "$fake_home" \
  --output "$report" \
  --quick \
  --top 5

grep -q '# macOS Storage Audit Evidence' "$report"
grep -q 'example-cache' "$report"
grep -q 'node_modules' "$report"
grep -q 'Mutation policy: read-only' "$report"

test -f "$fake_home/Library/Caches/example-cache/item"
test -f "$fake_home/Documents/demo/node_modules/pkg/index.js"

echo 'test_scan.sh: PASS'
