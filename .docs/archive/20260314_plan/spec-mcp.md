# Phase 1: MCP 追加 + ENABLE_TOOL_SEARCH 詳細仕様

## 追加する MCP サーバ

| MCP | パッケージ | 起動コマンド | トランスポート |
|-----|-----------|-------------|--------------|
| Sequential Thinking | `@modelcontextprotocol/server-sequential-thinking` | `npx -y @modelcontextprotocol/server-sequential-thinking` | stdio |
| Memory | `@modelcontextprotocol/server-memory` | `npx -y @modelcontextprotocol/server-memory` | stdio |
| Git | `mcp-server-git` (PyPI) | `uvx mcp-server-git --repository ${ROOT}` | stdio |

## 変更対象ファイルと変更内容

### 1. `.devcontainer/Dockerfile`

**変更箇所**: npm グローバルインストールブロック

```dockerfile
# 追加行（既存の npm install -g ブロック内に追加）
    @modelcontextprotocol/server-sequential-thinking@latest \
```

- Memory MCP と Git MCP は npx/uvx 経由で起動するため Dockerfile への追加は不要
- Sequential Thinking は事前インストールすることで初回起動を高速化

### 2. `.devcontainer/post-create-setup.sh`

**変更箇所**: register 関数の追加（`register_firecrawl` の前）

追加する関数:

```bash
register_sequential_thinking() {
  if ! $HAVE_NPX; then
    warn "npx が見つからないため Sequential Thinking MCP 登録をスキップしました。"
    return
  fi
  mcp_register_command_all "sequential-thinking" \
    npx -y @modelcontextprotocol/server-sequential-thinking
}

register_memory() {
  if ! $HAVE_NPX; then
    warn "npx が見つからないため Memory MCP 登録をスキップしました。"
    return
  fi
  local memory_dir="${ROOT}/local/memory-bank"
  mkdir -p "$memory_dir"
  mcp_register_env_command_all "memory" \
    "MEMORY_FILE_PATH=${memory_dir}/memory.json" \
    npx -y @modelcontextprotocol/server-memory
}

register_git() {
  if ! $HAVE_UV; then
    warn "uv が見つからないため Git MCP 登録をスキップしました。"
    return
  fi
  mcp_register_command_all "git" \
    uvx mcp-server-git --repository "$ROOT"
}
```

**呼び出し追加**（既存の register 呼び出しリストに追加）:

```bash
register_sequential_thinking
register_memory
register_git
```

### 3. `.claude/settings.local.json`

**変更内容**:

- トップレベルに `"enableToolSearch": true` を追加
- `mcpServers` に 3 つの MCP 定義を追加:

```json
"sequential-thinking": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
},
"memory": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-memory"],
  "env": {
    "MEMORY_FILE_PATH": "${workspaceFolder}/local/memory-bank/memory.json"
  }
},
"git": {
  "command": "uvx",
  "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
}
```

- `permissions.allow` に以下を追加:

```json
"mcp__sequential_thinking__*",
"mcp__memory__*",
"mcp__git__*"
```

### 4. `.gemini/settings.json`

**変更内容**: `mcpServers` に同じ 3 つの MCP 定義を追加（パスは `/workspaces/claym` 固定）

### 5. `templates/.codex/config.toml.example`

**変更内容**: MCP サーバー設定ブロックに 3 つの MCP 定義を追加

```toml
# Sequential Thinking: 段階的思考プロセス
[mcp_servers.sequential-thinking]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sequential-thinking"]

# Memory: ナレッジグラフ（ワークスペース内に永続化）
[mcp_servers.memory]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-memory"]
env = { MEMORY_FILE_PATH = "/workspaces/YOUR_PROJECT_NAME/local/memory-bank/memory.json" }

# Git: リポジトリ操作
[mcp_servers.git]
command = "uvx"
args = ["mcp-server-git", "--repository", "/workspaces/YOUR_PROJECT_NAME"]
```

注意: パスは既存の serena/filesystem と同様に `YOUR_PROJECT_NAME` プレースホルダーを使用。

### 6. `templates/.claude/settings.local.json.example`

`.claude/settings.local.json` と同じ変更を反映（パスは `${workspaceFolder}` 変数を使用）

### 7. `templates/.gemini/settings.json.example`

`.gemini/settings.json` と同じ変更を反映（パスは `${workspaceFolder}` 変数を使用）

### 8. `docs/container-tooling.md`

**変更内容**: 「バンドル済み MCP サーバー」テーブルに 3 つの MCP を追加

| MCP 名 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| sequential-thinking | 段階的思考プロセスをサポート | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| memory | ナレッジグラフによる情報永続化 | `npx -y @modelcontextprotocol/server-memory` |
| mcp-server-git | Git リポジトリ操作 | `uvx mcp-server-git --repository .` |

### 9. `scripts/health/checks/mcp.sh`

**変更箇所**: `required` 配列に 3 つの MCP を追加

```bash
# 変更前
local required=(serena playwright markitdown imagesorcery filesystem)

# 変更後
local required=(serena playwright markitdown imagesorcery filesystem sequential-thinking memory git)
```

## Memory MCP の永続化設計

- 環境変数 `MEMORY_FILE_PATH` でファイルパスを指定
- 保存先: `${workspaceFolder}/local/memory-bank/memory.json`
- `local/` は既に `.gitignore` で除外済み（`local/` → `!local/.gitkeep`）
- `post-create-setup.sh` で `local/memory-bank/` ディレクトリを自動作成

## ENABLE_TOOL_SEARCH 設定

- `.claude/settings.local.json` のトップレベルに `"enableToolSearch": true` を追加
- テンプレート（`templates/.claude/settings.local.json.example`）にも反映
- MCP ツールが多数登録されている環境でのトークン消費を削減する効果がある
