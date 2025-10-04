# shellcheck shell=bash
# システム関連のチェック

check_system_basics() {
  local os_release=/etc/os-release
  local os_name="" version="" tz_file="/etc/timezone" tz_value=""

  if [[ -f "$os_release" ]]; then
    os_name=$(grep '^NAME=' "$os_release" | cut -d'=' -f2- | tr -d '"')
    version=$(grep '^VERSION_ID=' "$os_release" | cut -d'=' -f2- | tr -d '"')
  fi

  if [[ "$os_name" != "Ubuntu" || "$version" != "24.04" ]]; then
    set_result "FAIL" "Detected ${os_name:-unknown} ${version:-unknown}; expected Ubuntu 24.04" "Rebuild the dev container from the provided Dockerfile"
    return
  fi

  if [[ -f "$tz_file" ]]; then
    tz_value=$(<"$tz_file")
  fi
  local expected_tz="${TZ:-Asia/Tokyo}"
  if [[ -n "$tz_value" && "$tz_value" != "$expected_tz" ]]; then
    set_result "WARN" "Timezone reported as $tz_value (expected $expected_tz)" "Update /etc/timezone or TZ env if this is intentional"
    return
  fi

  set_result "PASS" "Ubuntu 24.04 with timezone ${tz_value:-$expected_tz}" ""
}

check_workspace_permissions() {
  local owner
  if ! owner=$(stat -c '%U' "$REPO_ROOT" 2>/dev/null); then
    set_result "FAIL" "Unable to read workspace ownership" "Verify permissions for $REPO_ROOT"
    return
  fi
  if [[ "$owner" != "vscode" ]]; then
    set_result "FAIL" "Workspace owned by $owner (expected vscode)" "Run 'sudo chown -R vscode:vscode $REPO_ROOT'"
    return
  fi

  local missing=()
  if mapfile -t log_dirs < <(imagesorcery_log_dirs); then
    local dir dir_owner
    for dir in "${log_dirs[@]}"; do
      [[ -z "$dir" ]] && continue
      if [[ ! -d "$dir" ]]; then
        missing+=("$dir")
        continue
      fi
      if ! dir_owner=$(stat -c '%U' "$dir" 2>/dev/null); then
        missing+=("$dir (stat failed)")
        continue
      fi
      if [[ "$dir_owner" != "vscode" ]]; then
        set_result "WARN" "ImageSorcery log dir $dir owned by $dir_owner" "Run post-start script or fix ownership to vscode"
        return
      fi
    done
    if ((${#missing[@]} > 0)); then
      set_result "WARN" "ImageSorcery log dirs missing: ${missing[*]}" "Re-run post-start script to create log directories"
      return
    fi
  fi

  set_result "PASS" "Workspace and ImageSorcery logs owned by vscode" ""
}

register_check "system-basics" "System basics" true true check_system_basics
register_check "workspace-perms" "Workspace permissions" true true check_workspace_permissions
