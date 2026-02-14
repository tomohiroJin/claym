# shellcheck shell=bash
# MCP や関連サービスのチェック

collect_mcp_list() {
  local cli="$1" output=""
  case "$cli" in
    claude) output=$(timeout 10 claude mcp list 2>/dev/null < /dev/null || true) ;;
    codex) output=$(timeout 10 codex mcp list 2>/dev/null < /dev/null || true) ;;
    gemini) output=$(timeout 10 gemini mcp list 2>/dev/null < /dev/null || true) ;;
  esac
  printf '%s' "$output"
}

check_mcp_registrations() {
  local required=(serena playwright markitdown imagesorcery filesystem)
  local optional=(context7)
  local summary=()
  local cli
  local missing_global=()
  local warn_global=()

  for cli in claude codex gemini; do
    if ! have "$cli"; then
      warn_global+=("$cli (CLI missing)")
      continue
    fi
    local list
    list=$(collect_mcp_list "$cli")
    if [[ -z "$list" ]]; then
      warn_global+=("$cli (no MCP entries detected)")
      continue
    fi
    local missing=()
    local name
    for name in "${required[@]}"; do
      if ! grep -qi "${name}" <<<"$list"; then
        missing+=("$name")
      fi
    done
    if ((${#missing[@]})); then
      summary+=("$cli missing: ${missing[*]}")
      missing_global+=("$cli")
    else
      summary+=("$cli ok")
    fi
    for name in "${optional[@]}"; do
      if ! grep -qi "${name}" <<<"$list"; then
        warn_global+=("$cli missing optional ${name}")
      fi
    done
  done

  if ((${#missing_global[@]})); then
    set_result "WARN" "Missing MCP registrations (${summary[*]})" "Re-run post-create setup to re-register MCPs"
    return
  fi
  if ((${#warn_global[@]})); then
    set_result "WARN" "Warnings: ${warn_global[*]}" "Add optional MCPs if required for your workflow"
    return
  fi
  set_result "PASS" "Claude, Codex, and Gemini MCP lists contain required entries" ""
}

check_serena_ready() {
  local dir="/opt/serena"
  if [[ ! -d "$dir" ]]; then
    set_result "FAIL" "Serena directory missing at $dir" "Verify clone step in Dockerfile completed"
    return
  fi
  # アクセス権限をチェック（読み書き可能であることを確認）
  if [[ ! -r "$dir" ]] || [[ ! -x "$dir" ]]; then
    set_result "WARN" "Serena directory not accessible" "Run post-start script or fix permissions for $dir"
    return
  fi
  if ! timeout 30 uv run --directory "$dir" serena --help >/dev/null 2>&1 < /dev/null; then
    set_result "WARN" "Serena CLI failed to respond" "Run 'uv run --directory /opt/serena serena --help' manually for details"
    return
  fi
  set_result "PASS" "Serena repository ready and executable" ""
}

check_playwright_assets() {
  local cache_dir="${HOME}/.cache/ms-playwright"
  if [[ ! -d "$cache_dir" ]]; then
    set_result "WARN" "Playwright cache dir missing at $cache_dir" "Run 'npx playwright install chromium --with-deps'"
    return
  fi
  local chromium_dir
  chromium_dir=$(find "$cache_dir" -maxdepth 1 -type d -name 'chromium-*' | head -n1 || true)
  if [[ -z "$chromium_dir" ]]; then
    set_result "WARN" "No chromium bundle found in $cache_dir" "Re-run Playwright install step"
    return
  fi
  set_result "PASS" "Playwright Chromium assets present" ""
}

check_log_diagnostics() {
  local dirs
  if ! mapfile -t dirs < <(imagesorcery_log_dirs); then
    set_result "WARN" "Unable to resolve ImageSorcery log directories" "Run post-create setup to regenerate logs"
    return
  fi
  local latest_file=""
  local dir
  for dir in "${dirs[@]}"; do
    [[ -z "$dir" ]] && continue
    if [[ -d "$dir" ]]; then
      local candidate
      candidate=$(ls -1t "$dir"/*.log 2>/dev/null | head -n1 || true)
      if [[ -n "$candidate" ]]; then
        latest_file="$candidate"
        break
      fi
    fi
  done
  if [[ -z "$latest_file" ]]; then
    set_result "WARN" "No ImageSorcery log file found" "Run an ImageSorcery MCP command to generate logs"
    return
  fi
  local tail_output
  tail_output=$(tail -n5 "$latest_file" 2>/dev/null || true)
  if [[ -z "$tail_output" ]]; then
    set_result "WARN" "Failed to read $latest_file" "Check file permissions"
    return
  fi
  set_result "PASS" "ImageSorcery log available at $latest_file" "$tail_output"
}

register_check "mcp-registrations" "MCP registrations" false true check_mcp_registrations
register_check "serena-ready" "Serena readiness" false false check_serena_ready
register_check "playwright-assets" "Playwright assets" false false check_playwright_assets
register_check "log-diagnostics" "ImageSorcery logs" false false check_log_diagnostics
