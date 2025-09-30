#!/usr/bin/env bash
# post-create-setup.sh
# コンテナ作成直後に実行される初期化スクリプト。
# 目的：
#  - Claude Code CLI に各種 MCP サーバを登録（冪等）
#  - （任意）API キーがある場合のみ GitHub MCP / Firecrawl MCP を登録
#  - ワークスペースルートを基準に Filesystem / Serena を安全に稼働
#
# 注意：
#  - Codex CLI / Gemini CLI への MCP 自動登録は、現状の CLI 仕様が変わりやすいため
#    デフォルトでは実施しません（必要に応じてこのスクリプトに追記してください）。
#  - 何度実行しても致命的なエラーにならないよう best-effort で進みます。

set -Eeuo pipefail

# ===== ユーティリティ =====
info () { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn () { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err  () { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }
have () { command -v "$1" >/dev/null 2>&1; }

# VS Code Dev Containers では作業ディレクトリはワークスペース直下のはず。
ROOT="${WORKSPACE_FOLDER:-$PWD}"
info "Workspace: ${ROOT}"

# ===== 事前チェック =====
# imagesorcery-mcp のログディレクトリ権限を設定
info "imagesorcery-mcp のログディレクトリ権限を設定中..."
if [[ -d "/opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs" ]]; then
  sudo chown -R vscode:vscode /opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs >/dev/null 2>&1 || warn "ログディレクトリの権限設定に失敗しました"
  sudo chmod 755 /opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs >/dev/null 2>&1 || warn "ログディレクトリの権限設定に失敗しました"
else
  sudo mkdir -p /opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs >/dev/null 2>&1 || warn "ログディレクトリの作成に失敗しました"
  sudo chown -R vscode:vscode /opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs >/dev/null 2>&1 || warn "ログディレクトリの権限設定に失敗しました"
  sudo chmod 755 /opt/pipx/venvs/imagesorcery-mcp/lib/python3.12/site-packages/imagesorcery_mcp/logs >/dev/null 2>&1 || warn "ログディレクトリの権限設定に失敗しました"
fi

HAVE_CLAUDE=false
if have claude; then
  HAVE_CLAUDE=true
else
  warn "Claude Code CLI が見つかりません。Claude 向け MCP 登録はスキップします。"
fi

HAVE_CODEX=false
if have codex; then
  HAVE_CODEX=true
else
  warn "Codex CLI が見つかりません。Codex 向け MCP 登録はスキップします。"
fi

if ! $HAVE_CLAUDE && ! $HAVE_CODEX; then
  warn "MCP 登録対象の CLI が存在しないため処理を終了します。"
  exit 0
fi

# uv / npx / python などの存在チェック（見つからない場合は後続で必要部分のみ警告）
HAVE_UV=false; have uv && HAVE_UV=true
HAVE_NPX=false; have npx && HAVE_NPX=true
HAVE_PY=false; have python3 && HAVE_PY=true

# ===== Claude 用 登録ヘルパ =====
# 既存登録の検出は CLI 仕様変更の影響を受けやすいので、
# ここでは「追加を試み、重複エラーは無視」という方針で冪等化します。
add_claude_mcp () {
  # 使い方: add_claude_mcp <表示名> -- <command> [args...]
  local name="$1"; shift
  info "Claude: MCP '${name}' を登録します..."
  if claude mcp add "$name" "$@" >/dev/null 2>&1; then
    info "Claude: '${name}' 登録完了"
  else
    # 既に登録済みや軽微なエラーは無視（ログのみ）
    warn "Claude: '${name}' の登録でエラー（既に登録済みの可能性）"
  fi
}

add_claude_mcp_sse () {
  # 使い方: add_claude_mcp_sse <表示名> <sse_url>
  local name="$1" url="$2"
  info "Claude: MCP '${name}' (SSE) を登録します..."
  if claude mcp add --transport sse "$name" "$url" >/dev/null 2>&1; then
    info "Claude: '${name}' 登録完了"
  else
    warn "Claude: '${name}' の登録でエラー（既に登録済みの可能性）"
  fi
}

add_claude_mcp_with_env () {
  # 使い方: add_claude_mcp_with_env <表示名> VAR=VALUE -- <cmd> [args...]
  local name="$1" env_kv="$2"; shift 2
  info "Claude: MCP '${name}' を環境変数付きで登録します (${env_kv})..."
  if claude mcp add "$name" -e "$env_kv" -- "$@" >/dev/null 2>&1; then
    info "Claude: '${name}' 登録完了"
  else
    warn "Claude: '${name}' の登録でエラー（既に登録済みの可能性）"
  fi
}

# ===== Codex 用 登録ヘルパ =====
add_codex_mcp () {
  # 使い方: add_codex_mcp <表示名> <command> [args...]
  local name="$1"; shift
  info "Codex: MCP '${name}' を登録します..."
  if codex mcp add "$name" "$@" >/dev/null 2>&1; then
    info "Codex: '${name}' 登録完了"
  else
    warn "Codex: '${name}' の登録でエラー（既に登録済みの可能性）"
  fi
}

add_codex_mcp_with_env () {
  # 使い方: add_codex_mcp_with_env <表示名> VAR=VALUE <cmd> [args...]
  local name="$1" env_kv="$2"; shift 2
  info "Codex: MCP '${name}' を環境変数付きで登録します (${env_kv})..."
  if codex mcp add "$name" --env "$env_kv" "$@" >/dev/null 2>&1; then
    info "Codex: '${name}' 登録完了"
  else
    warn "Codex: '${name}' の登録でエラー（既に登録済みの可能性）"
  fi
}

# ===== 登録実行 =====
# 1) Serena MCP（uv 実行・プロジェクト限定）
if $HAVE_UV; then
  if $HAVE_CLAUDE; then
    add_claude_mcp "serena" -- uv run --directory /opt/serena serena \
      start-mcp-server --context ide-assistant --project "$ROOT"
  fi
  if $HAVE_CODEX; then
    add_codex_mcp "serena" uv run --directory /opt/serena serena \
      start-mcp-server --context ide-assistant --project "$ROOT"
  fi
else
  warn "uv が見つからないため Serena MCP 登録をスキップしました。必要なら 'uv' を導入してください。"
fi

# 2) Playwright MCP（ブラウザ自動取得済みを前提）
if $HAVE_NPX; then
  if $HAVE_CLAUDE; then
    add_claude_mcp "playwright" -- npx @playwright/mcp@latest
  fi
  if $HAVE_CODEX; then
    add_codex_mcp "playwright" npx @playwright/mcp@latest
  fi
else
  warn "npx が見つからないため Playwright MCP 登録をスキップしました。Node/npm の導入を確認してください。"
fi

# 3) MarkItDown MCP（ドキュメント → Markdown 変換）
if have markitdown-mcp; then
  if $HAVE_CLAUDE; then
    add_claude_mcp "markitdown" -- markitdown-mcp
  fi
  if $HAVE_CODEX; then
    add_codex_mcp "markitdown" markitdown-mcp
  fi
else
  warn "markitdown-mcp が見つかりません。'pip install markitdown-mcp' 後に再実行してください。"
fi

# 4) ImageSorcery MCP（画像処理・OCR・物体検出）
if have imagesorcery-mcp; then
  if $HAVE_CLAUDE; then
    add_claude_mcp "imagesorcery" -- imagesorcery-mcp
  fi
  if $HAVE_CODEX; then
    add_codex_mcp "imagesorcery" imagesorcery-mcp
  fi
else
  warn "imagesorcery-mcp が見つかりません。'pip install imagesorcery-mcp && imagesorcery-mcp --post-install' 後に再実行してください。"
fi

# 5) Filesystem MCP（ワークスペース配下のみアクセス許可）
if $HAVE_NPX; then
  if $HAVE_CLAUDE; then
    add_claude_mcp "filesystem" -- npx -y @modelcontextprotocol/server-filesystem "$ROOT"
  fi
  if $HAVE_CODEX; then
    add_codex_mcp "filesystem" npx -y @modelcontextprotocol/server-filesystem "$ROOT"
  fi
else
  warn "npx が見つからないため Filesystem MCP 登録をスキップしました。"
fi

# 6) Context7 MCP（SSE 経由ドキュメント検索）
if $HAVE_CLAUDE; then
  add_claude_mcp_sse "context7" "https://mcp.context7.com/sse"
fi
if $HAVE_CODEX; then
  warn "Codex: context7 (SSE) は現行 CLI で未サポートのためスキップしました。"
fi

# 7) GitHub MCP（PAT がある場合のみ）
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  if $HAVE_UV; then
    if $HAVE_CLAUDE; then
      add_claude_mcp_with_env "github" "GITHUB_TOKEN=${GITHUB_TOKEN}" -- uvx mcp-github
    fi
    if $HAVE_CODEX; then
      add_codex_mcp_with_env "github" "GITHUB_TOKEN=${GITHUB_TOKEN}" uvx mcp-github
    fi
  else
    warn "uv が見つからないため GitHub MCP 登録をスキップしました。"
  fi
else
  info "GITHUB_TOKEN が未設定のため GitHub MCP は登録しません。後で設定して再実行してください。"
fi

# 8) Firecrawl MCP（API キーがある場合のみ）
if [[ -n "${FIRECRAWL_API_KEY:-}" ]]; then
  if $HAVE_NPX; then
    if $HAVE_CLAUDE; then
      add_claude_mcp_with_env "firecrawl" "FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY}" -- npx -y firecrawl-mcp
    fi
    if $HAVE_CODEX; then
      add_codex_mcp_with_env "firecrawl" "FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY}" npx -y firecrawl-mcp
    fi
  else
    warn "npx が見つからないため Firecrawl MCP 登録をスキップしました。"
  fi
else
  info "FIRECRAWL_API_KEY が未設定のため Firecrawl MCP は登録しません。"
fi

# ===== 仕上げメッセージ =====
cat <<'EOF'

────────────────────────────────────────
MCP 登録の初期設定が完了しました（Claude Code / Codex 用）。

■ 使い始める
  - 端末で `claude chat` または `codex` を実行し、各 MCP が利用できるか確認してください。
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
  - 再登録: 本スクリプトを再実行（重複は自動的に無視）

※ Gemini CLI については、公式に MCP 管理コマンドが提供され次第、このスクリプトに追記してください。
────────────────────────────────────────
EOF

info "post-create-setup.sh 完了"
