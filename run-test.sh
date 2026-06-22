#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_BIN="${TF_BIN:-$ROOT_DIR/.bin/terraform}"

if [[ ! -x "$TF_BIN" ]]; then
  TF_BIN="$(command -v terraform)"
fi

echo "Using: $($TF_BIN version | head -1)"
echo

echo "==> Step 1: init (dynamic module source + version)"
$TF_BIN -chdir="$ROOT_DIR" init -upgrade

echo
echo "==> Step 2: validate"
$TF_BIN -chdir="$ROOT_DIR" validate

echo
echo "==> Step 3: plan (requires valid AWS credentials)"
if $TF_BIN -chdir="$ROOT_DIR" plan -input=false -out="$ROOT_DIR/tfplan"; then
  echo
  echo "SUCCESS: init, validate, and plan completed."
  echo "Apply with: TF_BIN=$TF_BIN $TF_BIN -chdir=\"$ROOT_DIR\" apply tfplan"
else
  echo
  echo "Plan failed (often expired AWS credentials). Init + validate already prove dynamic module source/version."
  exit 1
fi
