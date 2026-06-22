#!/usr/bin/env bash
# Shared helpers for HCP Terraform run API calls.

tfc_api_token() {
  python3 -c "import json; print(json.load(open('$HOME/.terraform.d/credentials.tfrc.json'))['credentials']['app.terraform.io']['token'])"
}

tfc_api() {
  local method="$1"
  local path="$2"
  shift 2
  curl -sS \
    --request "$method" \
    --header "Authorization: Bearer $(tfc_api_token)" \
    --header "Content-Type: application/vnd.api+json" \
    "$@" \
    "https://app.terraform.io/api/v2${path}"
}

# HCP Terraform uses status=applied for both successful apply and destroy runs.
tfc_run_is_terminal() {
  local status="$1"
  case "$status" in
    applied|planned_and_finished|errored|discarded|canceled|policy_soft_failed)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tfc_poll_run() {
  local run_id="$1"
  local poll_interval="${2:-10}"
  local max_attempts="${3:-60}"
  local status=""
  local is_destroy=""
  local attempt=0

  while (( attempt < max_attempts )); do
    attempt=$((attempt + 1))
    local response
    response="$(tfc_api GET "/runs/${run_id}")"

    status="$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes']['status'])")"
    is_destroy="$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes']['is-destroy'])")"

    echo "[$attempt] status=${status} is-destroy=${is_destroy}"

    if tfc_run_is_terminal "$status"; then
      echo "$response"
      return 0
    fi

    sleep "$poll_interval"
  done

  echo "Timed out waiting for run ${run_id} (last status: ${status})" >&2
  return 1
}

tfc_queue_run() {
  local workspace_id="$1"
  local is_destroy="$2"
  local message="$3"

  tfc_api POST "/runs" --data "$(cat <<EOF
{
  "data": {
    "type": "runs",
    "attributes": {
      "message": "${message}",
      "is-destroy": ${is_destroy}
    },
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "${workspace_id}"
        }
      }
    }
  }
}
EOF
)"
}

tfc_print_run_result() {
  local response="$1"
  python3 -c "
import sys, json
run = json.load(sys.stdin)['data']['attributes']
status = run['status']
is_destroy = run.get('is-destroy', False)

if status == 'applied':
    label = 'Destroy' if is_destroy else 'Apply'
    print(f'SUCCESS: {label} completed (status=applied).')
elif status == 'planned_and_finished':
    print('SUCCESS: Plan completed with no changes (status=planned_and_finished).')
else:
    print(f'Run finished with status={status} is-destroy={is_destroy}')
" <<<"$response"
}

tfc_get_workspace_id() {
  local org="$1"
  local workspace_name="$2"
  tfc_api GET "/organizations/${org}/workspaces/${workspace_name}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])"
}

tfc_print_workspace_outputs() {
  local workspace_id="$1"
  tfc_api GET "/workspaces/${workspace_id}/current-state-version-outputs" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin).get('data', [])
if not data:
    print('No workspace outputs.')
    raise SystemExit(0)
for item in data:
    attrs = item['attributes']
    print(f\"{attrs['name']} = {attrs.get('value')}\")
"
}
