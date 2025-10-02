#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    sudo --preserve-env=containerWorkspaceFolder,CONTAINER_WORKSPACE_FOLDER bash "$SCRIPT_PATH" "$@"
    exit $?
  else
    echo "WARN: root 権限が必要ですが sudo が利用できないため所有者変更処理をスキップしました。" >&2
    exit 0
  fi
fi

# shellcheck source=./scripts/helpers/logging.sh
source "${SCRIPT_DIR}/scripts/helpers/logging.sh"
# shellcheck source=./scripts/helpers/imagesorcery.sh
source "${SCRIPT_DIR}/scripts/helpers/imagesorcery.sh"

log_dirs=()
if mapfile -t log_dirs < <(imagesorcery_log_dirs); then
  if (( ${#log_dirs[@]} == 0 )); then
    warn "imagesorcery-mcp のログディレクトリを検出できなかったためスキップしました"
  else
    for dir in "${log_dirs[@]}"; do
      if ! mkdir -p "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの作成に失敗しました: $dir"
        continue
      fi
      if ! chown -R vscode:vscode "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの所有者設定に失敗しました: $dir"
      fi
      if ! chmod 755 "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの権限設定に失敗しました: $dir"
      fi
    done
  fi
else
  warn "imagesorcery-mcp のログディレクトリ検出処理が失敗しました"
fi

SERENA_DIR="/opt/serena"
if [[ -d "$SERENA_DIR" ]]; then
  if ! chown -R vscode:vscode "$SERENA_DIR" >/dev/null 2>&1; then
    warn "Serena ディレクトリの所有者変更に失敗しました: $SERENA_DIR"
  fi
fi
