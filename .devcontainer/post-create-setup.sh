#!/usr/bin/env bash
# post-create-setup.sh
# コンテナ作成直後に実行される初期化スクリプト。
# 目的：
#  - Claude Code CLI / Codex CLI / Gemini CLI に各種 MCP サーバを登録（冪等）
#  - （任意）API キーがある場合のみ GitHub MCP / Firecrawl MCP を登録
#  - ワークスペースルートを基準に Filesystem / Serena を安全に稼働
#
# 注意：
#  - Codex CLI / Gemini CLI への MCP 自動登録は、現状の CLI 仕様が変わりやすいため
#    必要に応じて本スクリプトを調整してください。
#  - 何度実行しても致命的なエラーにならないよう best-effort で進みます。

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${WORKSPACE_FOLDER:-$PWD}"
DEVCONTAINER_DIR="${ROOT}/.devcontainer"
HELPERS_DIR=""

if [[ -d "${DEVCONTAINER_DIR}/scripts/helpers" ]]; then
  HELPERS_DIR="${DEVCONTAINER_DIR}/scripts/helpers"
elif [[ -d "${SCRIPT_DIR}/scripts/helpers" ]]; then
  HELPERS_DIR="${SCRIPT_DIR}/scripts/helpers"
else
  echo "ERROR: ヘルパースクリプト群が見つかりませんでした。" >&2
  echo "       .devcontainer/scripts/helpers を配置してから再実行してください。" >&2
  exit 1
fi

# shellcheck source=.devcontainer/scripts/helpers/logging.sh
# shellcheck disable=SC1090
source "${HELPERS_DIR}/logging.sh"
# shellcheck source=.devcontainer/scripts/helpers/mcp_cli.sh
# shellcheck disable=SC1090
source "${HELPERS_DIR}/mcp_cli.sh"
# shellcheck source=.devcontainer/scripts/helpers/imagesorcery.sh
# shellcheck disable=SC1090
source "${HELPERS_DIR}/imagesorcery.sh"

info "Workspace: ${ROOT}"

ensure_imagesorcery_log_dir() {
  info "imagesorcery-mcp のログディレクトリ権限を設定中..."

  local log_dirs=()
  if mapfile -t log_dirs < <(imagesorcery_log_dirs); then
    if (( ${#log_dirs[@]} == 0 )); then
      warn "imagesorcery-mcp のログディレクトリが検出できなかったためスキップしました"
      return
    fi
  else
    warn "imagesorcery-mcp のログディレクトリ検出処理が失敗しました"
    return
  fi

  for log_dir in "${log_dirs[@]}"; do
    if ! sudo mkdir -p "$log_dir" >/dev/null 2>&1; then
      warn "ログディレクトリの作成に失敗しました: $log_dir"
      continue
    fi
    if ! sudo chown -R vscode:vscode "$log_dir" >/dev/null 2>&1; then
      warn "ログディレクトリの所有者設定に失敗しました: $log_dir"
    fi
    if ! sudo chmod 755 "$log_dir" >/dev/null 2>&1; then
      warn "ログディレクトリの権限設定に失敗しました: $log_dir"
    fi
  done
}


ensure_imagesorcery_log_dir

if ! mcp_detect_available_clis; then
  exit 0
fi

HAVE_UV=false
if have uv; then
  HAVE_UV=true
else
  warn "uv が見つかりません。必要な MCP の登録をスキップする場合があります。"
fi

HAVE_NPX=false
if have npx; then
  HAVE_NPX=true
else
  warn "npx が見つかりません。Node/npm の導入を確認してください。"
fi

register_serena() {
  if ! $HAVE_UV; then
    warn "uv が見つからないため Serena MCP 登録をスキップしました。必要なら 'uv' を導入してください。"
    return
  fi
  mcp_register_command_all "serena" \
    uv run --directory /opt/serena serena \
    start-mcp-server --context ide-assistant --project "$ROOT"
}

register_playwright() {
  if ! $HAVE_NPX; then
    warn "npx が見つからないため Playwright MCP 登録をスキップしました。"
    return
  fi
  mcp_register_command_all "playwright" \
    npx @playwright/mcp@latest
}

register_markitdown() {
  if ! have markitdown-mcp; then
    warn "markitdown-mcp が見つかりません。'pip install markitdown-mcp' 後に再実行してください。"
    return
  fi
  mcp_register_command_all "markitdown" \
    markitdown-mcp
}

register_imagesorcery() {
  if ! have imagesorcery-mcp; then
    warn "imagesorcery-mcp が見つかりません。'pip install imagesorcery-mcp && imagesorcery-mcp --post-install' 後に再実行してください。"
    return
  fi
  mcp_register_command_all "imagesorcery" \
    imagesorcery-mcp
}

register_filesystem() {
  if ! $HAVE_NPX; then
    warn "npx が見つからないため Filesystem MCP 登録をスキップしました。"
    return
  fi
  mcp_register_command_all "filesystem" \
    npx -y @modelcontextprotocol/server-filesystem "$ROOT"
}

register_context7() {
  mcp_register_sse_all "context7" "https://mcp.context7.com/sse"
}

register_github() {
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    info "GITHUB_TOKEN が未設定のため GitHub MCP は登録しません。後で設定して再実行してください。"
    return
  fi
  if ! $HAVE_UV; then
    warn "uv が見つからないため GitHub MCP 登録をスキップしました。"
    return
  fi
  mcp_register_env_command_all "github" "GITHUB_TOKEN=${GITHUB_TOKEN}" \
    uvx mcp-github
}

register_firecrawl() {
  if [[ -z "${FIRECRAWL_API_KEY:-}" ]]; then
    info "FIRECRAWL_API_KEY が未設定のため Firecrawl MCP は登録しません。"
    return
  fi
  if ! $HAVE_NPX; then
    warn "npx が見つからないため Firecrawl MCP 登録をスキップしました。"
    return
  fi
  mcp_register_env_command_all "firecrawl" "FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY}" \
    npx -y firecrawl-mcp
}

register_serena
register_playwright
register_markitdown
register_imagesorcery
register_filesystem
register_context7
register_github
register_firecrawl

cat <<'EOF'

────────────────────────────────────────
MCP 登録の初期設定が完了しました（Claude Code / Codex / Gemini 用）。

■ 使い始める
  - 端末で `claude chat`、`codex`、または `gemini` を実行し、各 MCP が利用できるか確認してください。
  - API キーが未設定の場合は、ホスト側の環境変数に設定し
    Dev Container を再接続すると、remoteEnv 経由で渡されます。

■ よくある調整
  - Filesystem MCP のアクセス範囲を変えたい場合：
      このスクリプト内の "$ROOT" を任意のサブディレクトリに変更してください。
  - Serena のプロンプト最適化コンテキスト：
      `--context ide-assistant` を他のモードに変更可能です（Serena のドキュメント参照）。

■ 解除・再登録
  - Claude: `claude mcp remove <name>`
  - Codex:  `codex mcp remove <name>`
  - Gemini:  `gemini mcp remove <name>`
  - 再登録: 本スクリプトを再実行（重複は自動的に無視）

※ 各 CLI で MCP の動作に問題がある場合は、コンテナを再起動してから本スクリプトを再実行してください。
────────────────────────────────────────
EOF

info "post-create-setup.sh 完了"
