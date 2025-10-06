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

      local config_path="${HOME}/.codex/config.toml"
      mkdir -p "$(dirname "${config_path}")"

      if python3 - "${config_path}" "${name}" "${url}" <<'PY'
import re
import sys
import tomllib
from pathlib import Path

config_path = Path(sys.argv[1])
name = sys.argv[2]
url = sys.argv[3]

if config_path.exists():
    data = tomllib.loads(config_path.read_text())
else:
    data = {}

mcp_servers = data.setdefault('mcp_servers', {})
server = mcp_servers.get(name, {})
for key in ('command', 'args', 'env'):
    server.pop(key, None)
server['transport'] = 'sse'
server['url'] = url
mcp_servers[name] = server

_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+$")

def format_key(key: str) -> str:
    if _KEY_RE.match(key):
        return key
    escaped = key.replace('\\', '\\\\').replace('"', '\\"')
    return f'"{escaped}"'


def join_path(keys) -> str:
    return '.'.join(format_key(str(k)) for k in keys)


def format_value(value):
    if isinstance(value, str):
        escaped = value.replace('\\', '\\\\').replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        items = ', '.join(format_value(item) for item in value)
        return f'[{items}]'
    raise TypeError(f'Unsupported type: {type(value)}')


def is_array_of_tables(value) -> bool:
    if not isinstance(value, list) or not value:
        return False
    return all(isinstance(item, dict) for item in value)


def emit_table(path, table, out_lines):
    out_lines.append(f"[{join_path(path)}]")
    nested = []
    array_tables = []
    for key, value in table.items():
        if isinstance(value, dict):
            nested.append((key, value))
        elif is_array_of_tables(value):
            array_tables.append((key, value))
        else:
            out_lines.append(f"{format_key(str(key))} = {format_value(value)}")
    for key, value in nested:
        if out_lines and out_lines[-1] != '':
            out_lines.append('')
        emit_table(path + [key], value, out_lines)
    for key, items in array_tables:
        for item in items:
            if out_lines and out_lines[-1] != '':
                out_lines.append('')
            emit_array_table(path + [key], item, out_lines)


def emit_array_table(path, table, out_lines):
    out_lines.append(f"[[{join_path(path)}]]")
    nested = []
    array_tables = []
    for key, value in table.items():
        if isinstance(value, dict):
            nested.append((key, value))
        elif is_array_of_tables(value):
            array_tables.append((key, value))
        else:
            out_lines.append(f"{format_key(str(key))} = {format_value(value)}")
    for key, value in nested:
        if out_lines and out_lines[-1] != '':
            out_lines.append('')
        emit_table(path + [key], value, out_lines)
    for key, items in array_tables:
        for item in items:
            if out_lines and out_lines[-1] != '':
                out_lines.append('')
            emit_array_table(path + [key], item, out_lines)


lines = []
for key, value in data.items():
    if isinstance(value, dict):
        if lines and lines[-1] != '':
            lines.append('')
        emit_table([key], value, lines)
    elif is_array_of_tables(value):
        for item in value:
            if lines and lines[-1] != '':
                lines.append('')
            emit_array_table([key], item, lines)
    else:
        lines.append(f"{format_key(str(key))} = {format_value(value)}")

config_path.write_text('\n'.join(lines).rstrip() + '\n')
PY
      then
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
