#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORG="${TFC_ORG:-William-Hashicorp}"
MODULE_NAME="${MODULE_NAME:-william-dynamic-s3}"
MODULE_PROVIDER="${MODULE_PROVIDER:-aws}"
MODULE_VERSION="${MODULE_VERSION:-1.0.0}"
REPO="${GITHUB_REPO:-William-Hashicorp/tf-dynamic-variable}"
SOURCE_DIR="${SOURCE_DIR:-registry-module/william-dynamic-s3}"
TAG_PREFIX="${TAG_PREFIX:-william-dynamic-s3/}"
OAUTH_TOKEN_ID="${OAUTH_TOKEN_ID:-ot-JXu5wd5P2PmDkN8t}"
GIT_TAG="${TAG_PREFIX}v${MODULE_VERSION#v}"

TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.terraform.d/credentials.tfrc.json'))['credentials']['app.terraform.io']['token'])")
API="https://app.terraform.io/api/v2"
AUTH=(--header "Authorization: Bearer $TOKEN" --header "Content-Type: application/vnd.api+json")

echo "Linking ${ORG}/${MODULE_NAME}/${MODULE_PROVIDER} to ${REPO}/${SOURCE_DIR}"

create_vcs_module() {
  curl -sS "${AUTH[@]}" \
    --request POST \
    --data "$(cat <<EOF
{
  "data": {
    "type": "registry-modules",
    "attributes": {
      "name": "${MODULE_NAME}",
      "provider": "${MODULE_PROVIDER}",
      "vcs-repo": {
        "identifier": "${REPO}",
        "display-identifier": "${REPO}",
        "oauth-token-id": "${OAUTH_TOKEN_ID}",
        "source-directory": "${SOURCE_DIR}",
        "tag-prefix": "${TAG_PREFIX}"
      }
    }
  }
}
EOF
)" \
    "$API/organizations/${ORG}/registry-modules/vcs"
}

resync_module() {
  curl -sS "${AUTH[@]}" \
    --request POST \
    "$API/organizations/${ORG}/registry-modules/private/${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}/actions/resync"
}

if ! curl -sS -o /dev/null -w "%{http_code}" --header "Authorization: Bearer $TOKEN" \
  "$API/organizations/${ORG}/registry-modules/private/${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}" | grep -q 200; then
  RESP="$(create_vcs_module)"
  if ! echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'data' in d else 1)" 2>/dev/null; then
    echo "$RESP" >&2
    exit 1
  fi
  echo "Created VCS-linked registry module."
else
  echo "Registry module already exists."
fi

echo "Publishing git tag: ${GIT_TAG}"
git -C "$ROOT_DIR" tag -f -a "$GIT_TAG" -m "Release ${MODULE_NAME} module v${MODULE_VERSION#v}"
git -C "$ROOT_DIR" push origin "$GIT_TAG" --force

echo "Requesting registry resync..."
resync_module >/dev/null || true

echo "Done."
echo "Registry source: app.terraform.io/${ORG}/${MODULE_NAME}/${MODULE_PROVIDER}"
echo "Version tag: ${GIT_TAG}"
