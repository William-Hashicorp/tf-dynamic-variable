#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="$ROOT_DIR/registry-module/william-dynamic-s3"
ORG="${TFC_ORG:-William-Hashicorp}"
MODULE_NAME="${MODULE_NAME:-william-dynamic-s3}"
MODULE_PROVIDER="${MODULE_PROVIDER:-aws}"
MODULE_VERSION="${MODULE_VERSION:-1.0.0}"

TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.terraform.d/credentials.tfrc.json'))['credentials']['app.terraform.io']['token'])")
API="https://app.terraform.io/api/v2"
AUTH=(--header "Authorization: Bearer $TOKEN" --header "Content-Type: application/vnd.api+json")

echo "Publishing ${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}@${MODULE_VERSION}"

create_module() {
  curl -sS "${AUTH[@]}" \
    --request POST \
    --data "$(cat <<EOF
{
  "data": {
    "type": "registry-modules",
    "attributes": {
      "name": "${MODULE_NAME}",
      "provider": "${MODULE_PROVIDER}",
      "registry-name": "private"
    }
  }
}
EOF
)" \
    "$API/organizations/${ORG}/registry-modules"
}

create_version() {
  curl -sS "${AUTH[@]}" \
    --request POST \
    --data "$(cat <<EOF
{
  "data": {
    "type": "registry-module-versions",
    "attributes": {
      "version": "${MODULE_VERSION}"
    }
  }
}
EOF
)" \
    "$API/organizations/${ORG}/registry-modules/private/${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}/versions"
}

MODULE_RESP="$(create_module)"
if echo "$MODULE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
  echo "Created registry module record."
else
  if echo "$MODULE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); errs=d.get('errors',[]); sys.exit(0 if any('unique' in e.get('detail','').lower() or 'already' in e.get('detail','').lower() for e in errs) else 1)" 2>/dev/null; then
    echo "Registry module record already exists."
  else
    echo "$MODULE_RESP" >&2
    echo "Failed to create registry module." >&2
    exit 1
  fi
fi

VERSION_RESP="$(create_version)"
UPLOAD_URL=$(echo "$VERSION_RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'data' in d:
    print(d['data']['links']['upload'])
else:
    print('')
")

if [[ -z "$UPLOAD_URL" ]]; then
  if echo "$VERSION_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); errs=d.get('errors',[]); sys.exit(0 if errs else 1)" 2>/dev/null; then
    echo "Version ${MODULE_VERSION} already published. Skipping upload."
    exit 0
  fi
  echo "$VERSION_RESP" >&2
  echo "Failed to create module version." >&2
  exit 1
fi

TMP_TAR="$(mktemp /tmp/william-dynamic-s3.XXXXXX.tar.gz)"
trap 'rm -f "$TMP_TAR"' EXIT

tar -czf "$TMP_TAR" -C "$MODULE_DIR" .

curl -sS --request PUT \
  --header "Content-Type: application/octet-stream" \
  --data-binary @"$TMP_TAR" \
  "$UPLOAD_URL" >/dev/null

echo "Uploaded module archive."
echo "Registry source: app.terraform.io/${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}"
echo "Version: ${MODULE_VERSION}"
