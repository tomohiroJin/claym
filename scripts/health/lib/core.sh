# shellcheck shell=bash
# チェック登録・実行の中核ロジック

declare -gA CHECK_LABEL=()
declare -gA CHECK_CRITICAL=()
declare -gA CHECK_QUICK=()
declare -gA CHECK_FN=()
declare -ga CHECK_ORDER=()

declare -ga RESULTS=()
FAILED_CRITICAL=false
FAILED_OPTIONAL=false

CHECK_STATUS="PASS"
CHECK_MESSAGE=""
CHECK_HINT=""

register_check() {
  local id="$1" label="$2" critical="$3" quick="$4" fn="$5"
  CHECK_ORDER+=("$id")
  CHECK_LABEL["$id"]="$label"
  CHECK_CRITICAL["$id"]=$critical
  CHECK_QUICK["$id"]=$quick
  CHECK_FN["$id"]=$fn
}

set_result() {
  CHECK_STATUS="$1"
  CHECK_MESSAGE="$2"
  CHECK_HINT="$3"
}

should_skip_check() {
  local id="$1"
  if is_skipped "$id"; then
    return 0
  fi
  if [[ "$RUN_MODE" == "quick" && "${CHECK_QUICK[$id]}" != true ]]; then
    return 0
  fi
  return 1
}

list_checks() {
  printf '利用可能なチェック ID ( --skip で指定可能 )\n'
  local id
  for id in "${CHECK_ORDER[@]}"; do
    printf '  %-20s %s\n' "$id" "${CHECK_LABEL[$id]}"
  done
}

run_check() {
  local id="$1"
  local label="${CHECK_LABEL[$id]}"
  local critical="${CHECK_CRITICAL[$id]}"
  local fn="${CHECK_FN[$id]}"

  CHECK_STATUS="PASS"
  CHECK_MESSAGE=""
  CHECK_HINT=""

  "$fn"

  if [[ "$critical" != true && "$CHECK_STATUS" == "FAIL" ]]; then
    CHECK_STATUS="WARN"
  fi

  if [[ "$CHECK_STATUS" == "FAIL" ]]; then
    FAILED_CRITICAL=true
  elif [[ "$CHECK_STATUS" == "WARN" ]]; then
    FAILED_OPTIONAL=true
  fi

  local display_message="$CHECK_MESSAGE"
  if [[ -n "$CHECK_HINT" ]]; then
    display_message+=" (hint: $CHECK_HINT)"
  fi

  RESULTS+=("$id|$CHECK_STATUS|$CHECK_MESSAGE|$CHECK_HINT")

  if [[ "$OUTPUT_FORMAT" == "text" ]]; then
    print_status "$CHECK_STATUS" "$label" "$display_message"
  fi
}

emit_json_summary() {
  python3 - "$SUMMARY_STATUS" "$SUMMARY_MESSAGE" "$FAILED_CRITICAL" "$FAILED_OPTIONAL" "${RESULTS[@]}" <<'PY'
import json, sys
summary_status, summary_message, critical_failed, optional_failed = sys.argv[1:5]
results_data = sys.argv[5:]
critical_failed = critical_failed.lower() == "true"
optional_failed = optional_failed.lower() == "true"
checks = []
for line in results_data:
    line = line.rstrip("\n")
    if not line:
        continue
    parts = line.split("|")
    while len(parts) < 4:
        parts.append("")
    check_id, status, message, hint = parts[:4]
    checks.append({
        "id": check_id,
        "status": status,
        "message": message,
        "hint": hint,
    })
summary = {
    "status": summary_status,
    "message": summary_message,
    "critical_failed": critical_failed,
    "warnings_present": optional_failed,
}
json.dump({"summary": summary, "checks": checks}, sys.stdout)
print()
PY
}

summarize_results() {
  if [[ "$FAILED_CRITICAL" == true ]]; then
    SUMMARY_STATUS="FAIL"
    SUMMARY_MESSAGE="Critical checks failed"
  elif [[ "$FAILED_OPTIONAL" == true ]]; then
    SUMMARY_STATUS="WARN"
    SUMMARY_MESSAGE="Warnings detected (non-critical)"
  else
    SUMMARY_STATUS="PASS"
    SUMMARY_MESSAGE="All checks passed"
  fi
}

run_all_checks() {
  RESULTS=()
  FAILED_CRITICAL=false
  FAILED_OPTIONAL=false

  local id
  for id in "${CHECK_ORDER[@]}"; do
    if should_skip_check "$id"; then
      continue
    fi
    run_check "$id"
  done

  summarize_results

  if [[ "$OUTPUT_FORMAT" == "text" ]]; then
    print_status "$SUMMARY_STATUS" "Summary" "$SUMMARY_MESSAGE"
  else
    emit_json_summary
  fi

  if [[ "$FAILED_CRITICAL" == true ]]; then
    return 1
  elif [[ "$FAILED_OPTIONAL" == true ]]; then
    return 2
  fi
  return 0
}
