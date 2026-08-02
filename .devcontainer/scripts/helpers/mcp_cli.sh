#!/usr/bin/env bash
# mcp_cli.sh
# MCP 登録用の CLI 検出と登録ヘルパを提供。

# 使用可能な CLI の順序を統一
# agy = Antigravity CLI（Gemini CLI の後継。2026-06-18 に移行）
readonly MCP_CLI_ORDER=(claude codex agy)
declare -a MCP_AVAILABLE_CLIS=()

declare -A MCP_CLI_LABELS=(
  [claude]="Claude"
  [codex]="Codex"
  [agy]="Antigravity"
)

# CLI ごとに 1 度だけスキップ警告を出すためのフラグ
declare -A MCP_CLI_WARNED=()

readonly MCP_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_CODEX_CONFIG_WRITER="${MCP_HELPERS_DIR}/codex_config_writer.py"
readonly MCP_ANTIGRAVITY_CONFIG_WRITER="${MCP_HELPERS_DIR}/antigravity_config_writer.py"

# Antigravity CLI は `mcp add` サブコマンドを持たず、JSON 設定を直接編集する仕様。
# 設定パスは ANTIGRAVITY_MCP_CONFIG で上書きできる（テスト用）。
_mcp_antigravity_config_path() {
  printf '%s' "${ANTIGRAVITY_MCP_CONFIG:-${HOME}/.gemini/config/mcp_config.json}"
}

# Antigravity CLI へ MCP を登録する共通処理。
# 第1引数: サーバー名、第2引数: 環境変数 KEY=VALUE（空文字なら無し）、以降: 起動コマンド
_mcp_antigravity_write() {
  local name="$1" env_kv="$2"
  shift 2

  if ! have python3; then
    warn "Antigravity: Python3 が見つからないため '${name}' 登録をスキップしました。"
    return 0
  fi
  if [[ ! -f "${MCP_ANTIGRAVITY_CONFIG_WRITER}" ]]; then
    warn "Antigravity: 設定スクリプトが見つからないため '${name}' 登録をスキップしました。"
    return 0
  fi

  local writer_args=(--config "$(_mcp_antigravity_config_path)" --name "$name")
  [[ -n "$env_kv" ]] && writer_args+=(--env "$env_kv")

  if python3 "${MCP_ANTIGRAVITY_CONFIG_WRITER}" "${writer_args[@]}" -- "$@"; then
    info "Antigravity: '${name}' 登録完了"
  else
    warn "Antigravity: '${name}' の設定ファイル更新でエラーが発生しました"
  fi
}

_mcp_cli_label() {
  local cli="$1"
  printf '%s' "${MCP_CLI_LABELS[$cli]:-$cli}"
}

_detect_single_cli() {
  local cli="$1"
  local label
  label=$(_mcp_cli_label "$cli")

  if have "$cli"; then
    MCP_AVAILABLE_CLIS+=("$cli")
  else
    warn "${label} CLI が見つかりません。${label} 向け MCP 登録はスキップします。"
    MCP_CLI_WARNED["$cli"]=true
  fi
}

mcp_detect_available_clis() {
  MCP_AVAILABLE_CLIS=()
  MCP_CLI_WARNED=()

  local cli
  for cli in "${MCP_CLI_ORDER[@]}"; do
    _detect_single_cli "$cli"
  done

  if ((${#MCP_AVAILABLE_CLIS[@]} == 0)); then
    warn "MCP 登録対象の CLI が存在しないため処理を終了します。"
    return 1
  fi

  return 0
}

_mcp_register_command() {
  local cli="$1" name="$2"
  shift 2

  local label
  label=$(_mcp_cli_label "$cli")

  info "${label}: MCP '${name}' を登録します..."
  case "$cli" in
    claude)
      if claude mcp add "$name" -- "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
      ;;
    codex)
      if codex mcp add "$name" "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
      ;;
    agy)
      _mcp_antigravity_write "$name" "" "$@"
      ;;
    *)
      warn "${label}: 未対応の CLI 種別です (${cli})"
      ;;
  esac
}

_mcp_register_sse() {
  local cli="$1" name="$2" url="$3"
  local label
  label=$(_mcp_cli_label "$cli")

  info "${label}: MCP '${name}' (SSE) を登録します..."
  case "$cli" in
    claude)
      if claude mcp add --transport sse "$name" "$url" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
      ;;
    codex)
      if ! have python3; then
        warn "${label}: Python3 が見つからないため '${name}' (SSE) 登録をスキップしました。"
        return 0
      fi

      if [[ ! -f "${MCP_CODEX_CONFIG_WRITER}" ]]; then
        warn "${label}: Codex 用設定スクリプトが見つからないため '${name}' (SSE) 登録をスキップしました。"
        return 0
      fi

      local config_path="${HOME}/.codex/config.toml"
      mkdir -p "$(dirname "${config_path}")"

      if python3 "${MCP_CODEX_CONFIG_WRITER}" --config "${config_path}" --name "${name}" --url "${url}"; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の設定ファイル更新でエラーが発生しました"
      fi
      ;;
    agy)
      if ! have python3; then
        warn "${label}: Python3 が見つからないため '${name}' (SSE) 登録をスキップしました。"
        return 0
      fi
      if [[ ! -f "${MCP_ANTIGRAVITY_CONFIG_WRITER}" ]]; then
        warn "${label}: Antigravity 用設定スクリプトが見つからないため '${name}' (SSE) 登録をスキップしました。"
        return 0
      fi

      if python3 "${MCP_ANTIGRAVITY_CONFIG_WRITER}" \
        --config "$(_mcp_antigravity_config_path)" --name "${name}" --url "${url}"; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の設定ファイル更新でエラーが発生しました"
      fi
      ;;
    *)
      warn "${label}: 未対応の CLI 種別です (${cli})"
      ;;
  esac
}

_mcp_register_env_command() {
  local cli="$1" name="$2" env_kv="$3"
  shift 3

  local label
  label=$(_mcp_cli_label "$cli")

  info "${label}: MCP '${name}' を環境変数付きで登録します (${env_kv})..."
  case "$cli" in
    claude)
      if claude mcp add "$name" -e "$env_kv" -- "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
      ;;
    codex)
      if codex mcp add "$name" --env "$env_kv" "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
      ;;
    agy)
      _mcp_antigravity_write "$name" "$env_kv" "$@"
      ;;
    *)
      warn "${label}: 未対応の CLI 種別です (${cli})"
      ;;
  esac
}

mcp_register_command_all() {
  local name="$1"
  shift
  local cli
  for cli in "${MCP_AVAILABLE_CLIS[@]}"; do
    _mcp_register_command "$cli" "$name" "$@"
  done
}

mcp_register_sse_all() {
  local name="$1" url="$2"
  local cli
  for cli in "${MCP_AVAILABLE_CLIS[@]}"; do
    _mcp_register_sse "$cli" "$name" "$url"
  done
}

mcp_register_env_command_all() {
  local name="$1" env_kv="$2"
  shift 2
  local cli
  for cli in "${MCP_AVAILABLE_CLIS[@]}"; do
    _mcp_register_env_command "$cli" "$name" "$env_kv" "$@"
  done
}
