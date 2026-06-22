#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/tfc-common.sh
source "$ROOT_DIR/scripts/tfc-common.sh"

ORG="${TFC_ORG:-William-Hashicorp}"
WORKSPACE="${TFC_WORKSPACE:-tf-dynamic-module-source-test}"
MESSAGE="${1:-Run complete dynamic module source/version test on HCP Terraform}"

WORKSPACE_ID="$(tfc_get_workspace_id "$ORG" "$WORKSPACE")"
echo "Queueing apply run on ${ORG}/${WORKSPACE} (${WORKSPACE_ID})"

RUN_RESPONSE="$(tfc_queue_run "$WORKSPACE_ID" false "$MESSAGE")"
RUN_ID="$(echo "$RUN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")"
echo "Run: https://app.terraform.io/app/${ORG}/workspaces/${WORKSPACE}/runs/${RUN_ID}"
echo

FINAL_RESPONSE="$(tfc_poll_run "$RUN_ID")"
tfc_print_run_result "$FINAL_RESPONSE"

STATUS="$(echo "$FINAL_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes']['status'])")"
case "$STATUS" in
  applied|planned_and_finished) ;;
  *)
    exit 1
    ;;
esac

echo
echo "Workspace outputs:"
tfc_print_workspace_outputs "$WORKSPACE_ID"
