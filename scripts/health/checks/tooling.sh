# shellcheck shell=bash
# ツールチェーン関連のチェック

check_cli_paths() {
  local required=(claude codex gemini uv npx npm rg markitdown-mcp imagesorcery-mcp mcp-github)
  local missing=()
  local cmd
  declare -A seen=()
  for cmd in "${required[@]}"; do
    [[ -n "${seen[$cmd]:-}" ]] && continue
    seen[$cmd]=1
    if ! have "$cmd"; then
      missing+=("$cmd")
    fi
  done
  if ((${#missing[@]})); then
    set_result "FAIL" "Missing commands: ${missing[*]}" "Rebuild container or install listed CLI tools"
    return
  fi
  set_result "PASS" "All required CLI commands are on PATH" ""
}

check_cli_versions() {
  local commands=(
    "claude --version"
    "codex --version"
    "gemini --version"
    "uv --version"
    "npm --version"
  )
  local outputs=()
  local cmd
  for cmd in "${commands[@]}"; do
    local binary=${cmd%% *}
    if ! have "$binary"; then
      outputs+=("$binary: <missing>")
      continue
    fi
    if ! out=$(timeout 10 env LC_ALL=C $cmd 2>/dev/null < /dev/null | head -n1); then
      outputs+=("$binary: <unavailable>")
    else
      outputs+=("$binary: $out")
    fi
  done
  local missing_versions=()
  for line in "${outputs[@]}"; do
    if [[ "$line" == *"<missing>"* || "$line" == *"<unavailable>"* ]]; then
      missing_versions+=("$line")
    fi
  done
  if ((${#missing_versions[@]})); then
    set_result "WARN" "Unable to read versions for: ${missing_versions[*]}" "Confirm commands support --version or update this check"
  else
    set_result "PASS" "Collected CLI versions" "${outputs[*]}"
  fi
}

check_mcp_python_environment() {
  local expected_cmds=(markitdown-mcp imagesorcery-mcp mcp-github)
  local missing_cmds=()
  local cmd
  for cmd in "${expected_cmds[@]}"; do
    if ! have "$cmd"; then
      missing_cmds+=("$cmd")
    fi
  done

  local venv="${VIRTUAL_ENV:-/opt/mcp-venv}"
  local python_cmd=""
  if [[ -n "$venv" && -x "$venv/bin/python" ]]; then
    python_cmd="$venv/bin/python"
  elif have python3; then
    python_cmd="python3"
  fi

  local -a import_failures=()
  if [[ -n "$python_cmd" ]]; then
    local target module label
    local -a import_targets=(
      "markitdown_mcp:markitdown-mcp"
      "imagesorcery_mcp:imagesorcery-mcp"
      "mcp_github:mcp-github"
    )
    for target in "${import_targets[@]}"; do
      IFS=':' read -r module label <<<"$target"
      if ! "$python_cmd" -c "import ${module}" >/dev/null 2>&1; then
        import_failures+=("$label")
      fi
    done
  else
    import_failures+=("Python runtime not found (${venv}/bin/python or python3)")
  fi

  if ((${#missing_cmds[@]})) || ((${#import_failures[@]})); then
    local -a parts=()
    if ((${#missing_cmds[@]})); then
      parts+=("commands: ${missing_cmds[*]}")
    fi
    if ((${#import_failures[@]})); then
      parts+=("imports: ${import_failures[*]}")
    fi
    local message
    message=$(IFS='; '; echo "${parts[*]}")
    local remedy="Rebuild the devcontainer or reinstall MCP packages in ${venv}"
    set_result "FAIL" "Python MCP environment issues — ${message}" "$remedy"
    return
  fi

  set_result "PASS" "Python MCP CLI commands and imports are healthy" ""
}

check_api_keys() {
  local vars=(ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY GITHUB_TOKEN FIRECRAWL_API_KEY)
  local present=()
  local absent=()
  local var
  for var in "${vars[@]}"; do
    if [[ -n "${!var:-}" ]]; then
      present+=("$var")
    else
      absent+=("$var")
    fi
  done
  local msg="Set: ${present[*]:-none}; Unset: ${absent[*]:-none}"
  if ((${#present[@]} == 0)); then
    set_result "WARN" "$msg" "Export the API keys required for desired MCPs"
  else
    set_result "PASS" "$msg" ""
  fi
}

check_git_safe_directory() {
  local entries
  entries=$(git config --system --get-all safe.directory 2>/dev/null || true)
  if [[ -z "$entries" ]]; then
    set_result "WARN" "safe.directory not configured" "Run 'sudo git config --system --add safe.directory $REPO_ROOT'"
    return
  fi
  if ! grep -Fxq "$REPO_ROOT" <<<"$entries"; then
    set_result "WARN" "safe.directory missing $REPO_ROOT" "Add workspace path to system git config"
    return
  fi
  set_result "PASS" "git safe.directory includes workspace path" ""
}

register_check "cli-paths" "CLI availability" true true check_cli_paths
register_check "cli-versions" "CLI versions" false false check_cli_versions
register_check "mcp-python-env" "Python MCP environment" false false check_mcp_python_environment
register_check "api-keys" "API keys" false true check_api_keys
register_check "git-safe-directory" "Git safe.directory" false false check_git_safe_directory
