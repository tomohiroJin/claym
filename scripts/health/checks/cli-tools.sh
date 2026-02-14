# shellcheck shell=bash
# モダン CLI ツール関連のチェック

check_modern_cli_tools() {
  local tools=(zoxide eza tldr delta)
  local missing=()
  local tool
  for tool in "${tools[@]}"; do
    if ! have "$tool"; then
      missing+=("$tool")
    fi
  done

  if ((${#missing[@]} > 0)); then
    set_result "WARN" "Modern CLI tools missing: ${missing[*]}" "Rebuild container to install missing tools"
    return
  fi

  set_result "PASS" "All modern CLI tools installed" ""
}

check_modern_cli_versions() {
  local commands=(
    "zoxide --version"
    "eza --version"
    "tldr --version"
    "delta --version"
  )
  local outputs=()
  local cmd
  for cmd in "${commands[@]}"; do
    local binary=${cmd%% *}
    if ! have "$binary"; then
      outputs+=("$binary: <missing>")
      continue
    fi
    if ! out=$(env LC_ALL=C $cmd 2>/dev/null | head -n1); then
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
    set_result "WARN" "Unable to read versions for: ${missing_versions[*]}" "Rebuild container or verify tool installation"
  else
    set_result "PASS" "Modern CLI tool versions collected" "${outputs[*]}"
  fi
}

check_shell_aliases() {
  # zsh エイリアスの存在確認（実際のシェル環境で評価されるため、ここでは設定ファイルの存在のみ確認）
  local zshrc="/home/vscode/.zshrc"
  if [[ ! -f "$zshrc" ]]; then
    set_result "WARN" ".zshrc not found" "Rebuild container to configure shell aliases"
    return
  fi

  local required_aliases=(
    "alias ll="
    "alias ls="
    "alias cat="
    "alias find="
    "alias top="
    "zoxide init"
  )
  local missing_aliases=()
  local alias_pattern
  for alias_pattern in "${required_aliases[@]}"; do
    if ! grep -q "$alias_pattern" "$zshrc"; then
      missing_aliases+=("$alias_pattern")
    fi
  done

  if ((${#missing_aliases[@]} > 0)); then
    set_result "WARN" "Shell aliases not configured: ${missing_aliases[*]}" "Rebuild container to add aliases to .zshrc"
    return
  fi

  set_result "PASS" "Shell aliases configured in .zshrc" ""
}

check_git_delta_config() {
  # Git の pager 設定を確認
  local pager
  pager=$(git config --global core.pager 2>/dev/null || true)
  if [[ "$pager" != "delta" ]]; then
    set_result "WARN" "Git not configured to use delta (pager: ${pager:-not set})" "Run 'git config --global core.pager delta'"
    return
  fi

  local navigate
  navigate=$(git config --global delta.navigate 2>/dev/null || true)
  if [[ "$navigate" != "true" ]]; then
    set_result "WARN" "Git delta navigation not enabled" "Run 'git config --global delta.navigate true'"
    return
  fi

  set_result "PASS" "Git configured to use delta" ""
}

register_check "modern-cli-tools" "Modern CLI tools" true true check_modern_cli_tools
register_check "modern-cli-versions" "Modern CLI versions" false false check_modern_cli_versions
register_check "shell-aliases" "Shell aliases" false false check_shell_aliases
register_check "git-delta-config" "Git delta config" false false check_git_delta_config
