# shellcheck shell=bash
# システム関連のチェック

check_system_basics() {
  local os_release=/etc/os-release
  local os_name="" version="" tz_file="/etc/timezone" tz_value=""

  if [[ -f "$os_release" ]]; then
    os_name=$(grep '^NAME=' "$os_release" | cut -d'=' -f2- | tr -d '"')
    version=$(grep '^VERSION_ID=' "$os_release" | cut -d'=' -f2- | tr -d '"')
  fi

  if [[ "$os_name" != "Debian GNU/Linux" || "$version" != "12" ]]; then
    set_result "FAIL" "Detected ${os_name:-unknown} ${version:-unknown}; expected Debian GNU/Linux 12" "Rebuild the dev container from the provided Dockerfile"
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

  set_result "PASS" "Debian GNU/Linux 12 with timezone ${tz_value:-$expected_tz}" ""
}

check_workspace_permissions() {
  # ワークスペースへの読み書きアクセスをチェック
  if [[ ! -r "$REPO_ROOT" ]] || [[ ! -w "$REPO_ROOT" ]]; then
    set_result "FAIL" "Workspace not readable/writable" "Verify permissions for $REPO_ROOT"
    return
  fi

  # テストファイルを作成して書き込み権限を確認
  local test_file="${REPO_ROOT}/.health-check-test"
  if ! touch "$test_file" 2>/dev/null; then
    set_result "FAIL" "Cannot write to workspace" "Verify write permissions for $REPO_ROOT"
    return
  fi
  rm -f "$test_file" 2>/dev/null

  local missing=()
  if mapfile -t log_dirs < <(imagesorcery_log_dirs); then
    local dir
    for dir in "${log_dirs[@]}"; do
      [[ -z "$dir" ]] && continue
      if [[ ! -d "$dir" ]]; then
        missing+=("$dir")
        continue
      fi
      if [[ ! -r "$dir" ]] || [[ ! -w "$dir" ]]; then
        set_result "WARN" "ImageSorcery log dir $dir not accessible" "Run post-start script or fix permissions"
        return
      fi
    done
    if ((${#missing[@]} > 0)); then
      set_result "WARN" "ImageSorcery log dirs missing: ${missing[*]}" "Re-run post-start script to create log directories"
      return
    fi
  fi

  set_result "PASS" "Workspace and ImageSorcery logs are accessible" ""
}

register_check "system-basics" "System basics" true true check_system_basics
register_check "workspace-perms" "Workspace permissions" true true check_workspace_permissions
