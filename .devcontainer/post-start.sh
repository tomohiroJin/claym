#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./scripts/helpers/logging.sh
source "${SCRIPT_DIR}/scripts/helpers/logging.sh"
# shellcheck source=./scripts/helpers/imagesorcery.sh
source "${SCRIPT_DIR}/scripts/helpers/imagesorcery.sh"

WORKSPACE="${containerWorkspaceFolder:-${CONTAINER_WORKSPACE_FOLDER:-$PWD}}"
if [[ -n "$WORKSPACE" ]]; then
  if ! sudo chown -R vscode:vscode "$WORKSPACE" >/dev/null 2>&1; then
    warn "ワークスペースの所有者変更に失敗しました: $WORKSPACE"
  fi
else
  warn "ワークスペースパスが特定できなかったため所有者変更をスキップしました"
fi

log_dirs=()
if mapfile -t log_dirs < <(imagesorcery_log_dirs); then
  if (( ${#log_dirs[@]} == 0 )); then
    warn "imagesorcery-mcp のログディレクトリを検出できなかったためスキップしました"
  else
    for dir in "${log_dirs[@]}"; do
      if ! sudo mkdir -p "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの作成に失敗しました: $dir"
        continue
      fi
      if ! sudo chown -R vscode:vscode "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの所有者設定に失敗しました: $dir"
      fi
      if ! sudo chmod 755 "$dir" >/dev/null 2>&1; then
        warn "ログディレクトリの権限設定に失敗しました: $dir"
      fi
    done
  fi
else
  warn "imagesorcery-mcp のログディレクトリ検出処理が失敗しました"
fi

SERENA_DIR="/opt/serena"
if [[ -d "$SERENA_DIR" ]]; then
  if ! sudo chown -R vscode:vscode "$SERENA_DIR" >/dev/null 2>&1; then
    warn "Serena ディレクトリの所有者変更に失敗しました: $SERENA_DIR"
  fi
fi

START_SCRIPT="/usr/local/bin/start-serena.sh"
if [[ -f "$START_SCRIPT" ]]; then
  nohup bash "$START_SCRIPT" >/dev/null 2>&1 &
  if [[ $? -ne 0 ]]; then
    warn "start-serena.sh の起動に失敗しました"
  else
    info "start-serena.sh をバックグラウンドで起動しました"
  fi
else
  info "start-serena.sh が見つからないため自動起動をスキップしました"
fi
