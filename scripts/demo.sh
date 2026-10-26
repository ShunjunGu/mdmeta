#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.moon/bin:${PATH}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== moon version =="
moon version

echo "== moon test =="
moon test

echo "== CLI help =="
moon run cmd/main -- --help

echo "== list examples/post.md =="
moon run cmd/main -- list examples/post.md

echo "== get title =="
moon run cmd/main -- get examples/post.md title

echo "== validate OK =="
moon run cmd/main -- validate examples/post.md --require title --require date --type title=string

echo "== validate FAIL (expect issues) =="
set +e
moon run cmd/main -- validate examples/incomplete.md --require title --require date
code=$?
set -e
if [[ "$code" -eq 0 ]]; then
  echo "expected non-zero exit for incomplete.md" >&2
  exit 1
fi
echo "(ok: exit=$code)"

echo "== batch JSON (mixed ok/errors expected) =="
set +e
moon run cmd/main -- batch examples --require title --require date
batch_code=$?
set -e
# batch may exit non-zero when any file fails validation; that is OK for demo
echo "(batch exit=$batch_code)"

echo "== DEMO OK =="
