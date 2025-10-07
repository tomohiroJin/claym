#!/usr/bin/env bash
# mcp_cli.sh
# MCP 登録用の CLI 検出と登録ヘルパを提供。

# 使用可能な CLI の順序を統一
readonly MCP_CLI_ORDER=(claude codex gemini)
declare -a MCP_AVAILABLE_CLIS=()

declare -A MCP_CLI_LABELS=(
  [claude]="Claude"
  [codex]="Codex"
  [gemini]="Gemini"
)

# CLI ごとに 1 度だけスキップ警告を出すためのフラグ
declare -A MCP_CLI_WARNED=()

readonly MCP_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_CODEX_CONFIG_WRITER="${MCP_HELPERS_DIR}/codex_config_writer.py"

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
    gemini)
      if gemini mcp add "$name" "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
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

  if [[ "$cli" == gemini ]]; then
    warn "${label}: '${name}' (SSE) は現行 CLI で未サポートの可能性があります。スキップします。"
    return
  fi

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
    gemini)
      if env "$env_kv" gemini mcp add "$name" "$@" >/dev/null 2>&1; then
        info "${label}: '${name}' 登録完了"
      else
        warn "${label}: '${name}' の登録でエラー（既に登録済みの可能性）"
      fi
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
