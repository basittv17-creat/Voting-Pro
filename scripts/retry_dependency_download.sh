#!/usr/bin/env bash
# Retry only a rate-limited dependency fetch. Preserve compiler and signing failures.
set -eu
log=$(mktemp)
trap 'rm -f "$log"' EXIT
for delay in 15 45 0; do
  set +e
  "$@" 2>&1 | tee "$log"
  statuses=("${PIPESTATUS[@]}")
  set -e
  if (( statuses[1] != 0 )); then exit "${statuses[1]}"; fi
  if (( statuses[0] == 0 )); then exit 0; fi
  if (( delay == 0 )) || ! grep -Eiq 'status code 429|HTTP[^[:alnum:]]+429|429 Too Many Requests' "$log"; then
    exit "${statuses[0]}"
  fi
  sleep "$delay"
done
