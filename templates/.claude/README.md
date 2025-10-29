# Claude Code 設定テンプレート

このディレクトリには Claude Code の設定テンプレートが含まれています。

## ファイル一覧

- `settings.local.json.example` - MCP サーバー設定と権限設定のテンプレート
- `CLAUDE.md` - カスタム指示（日本語設定など）

## settings.local.json の構造

### mcpServers セクション

Claude Code で使用する MCP サーバーの設定です。

| サーバー名 | 説明 | コマンド |
|-----------|------|---------|
| serena | コードベース解析・編集 | `uv run --directory /opt/serena serena start-mcp-server` |
| filesystem | ファイル操作 | `npx -y @modelcontextprotocol/server-filesystem` |
| playwright | ブラウザ自動化 | `npx @playwright/mcp@latest` |
| markitdown | ドキュメント変換 | `markitdown-mcp` |
| imagesorcery | 画像処理 | `imagesorcery-mcp` |
| github | GitHub API統合 | `uvx mcp-github` |
| context7 | ドキュメント検索 | `npx -y @upstash/context7-mcp` |
| fetch | Web検索・ページ取得 | `uvx mcp-server-fetch` |

### permissions セクション

Claude Code の操作権限を制御します。

#### allow（自動承認）

以下の操作は確認なしで自動的に実行されます：

**ファイル読み取り**:
- `Read(//workspaces/**)` - プロジェクトディレクトリ配下の全ファイル
- `Read(//root/.codex/**)` - Claude Code 設定ファイル

**基本的なシェルコマンド**（情報表示系）:
- `echo`, `ls`, `cat`, `tail`, `head`, `grep`, `find`

**Git操作**:
- `git status`, `git diff`, `git log`, `git add`, `git commit`, `git checkout`, `git pull`

**GitHub CLI**:
- `gh pr:*`, `gh auth:*`

**Python開発**:
- `python3:*`, `poetry:*`, `.venv/bin/python:*`, `.venv/bin/pytest:*`

**MCP サーバー**:
- Serena: `get_symbols_overview`, `find_symbol`, `search_for_pattern`, `list_dir`
- Filesystem: `list_directory`, `directory_tree`, `read_text_file`
- GitHub: 全操作 (`*`)
- Playwright: 全操作 (`*`)
- Fetch: 全操作 (`*`)

**Web検索**:
- `WebSearch`

#### deny（拒否）

現在は空です。危険な操作を完全にブロックする場合に使用します。

#### ask（確認が必要）

以下の操作は実行前に確認プロンプトが表示されます：

**破壊的な操作**:
- `rm:*`, `sudo rm:*`

**システム変更**:
- `sudo:*`, `chmod:*`, `chown:*`

**Git の破壊的操作**:
- `git push --force:*`, `git reset --hard:*`

**パッケージインストール**:
- `apt:*`, `apt-get:*`, `pip install:*`

## 使用方法

### 1. テンプレートをコピー

```bash
cp templates/.claude/settings.local.json.example .claude/settings.local.json
cp templates/.claude/CLAUDE.md .claude/CLAUDE.md
```

または自動セットアップスクリプトを使用：

```bash
bash scripts/setup/init-ai-configs.sh
```

### 2. カスタマイズ

#### MCP サーバーの追加・削除

不要なMCPサーバーを削除する場合：

```json
{
  "mcpServers": {
    "serena": { ... },
    "filesystem": { ... }
    // "playwright": { ... }  ← 削除
  }
}
```

新しいMCPサーバーを追加する場合：

```json
{
  "mcpServers": {
    "serena": { ... },
    "custom-mcp": {
      "command": "npx",
      "args": ["-y", "custom-mcp-server"]
    }
  }
}
```

#### 権限のカスタマイズ

自動承認に追加：

```json
{
  "permissions": {
    "allow": [
      "Read(//workspaces/**)",
      "Read(//root/.codex/**)",
      "Bash(npm:*)"  // ← npm コマンドを自動承認
    ]
  }
}
```

確認が必要な操作に追加：

```json
{
  "permissions": {
    "ask": [
      "Bash(rm:*)",
      "Bash(docker:*)"  // ← docker コマンドは確認必須
    ]
  }
}
```

## 注意事項

### JSONコメント

Claude Code の設定ファイルは**標準JSON形式**です。コメント（`//`）は使用できません。

❌ **NG（エラーになる）**:
```json
{
  // これはコメント
  "mcpServers": { ... }
}
```

✅ **OK**:
```json
{
  "mcpServers": { ... }
}
```

説明が必要な場合は、このREADMEファイルを参照してください。

### セキュリティ

- APIキーやトークンは**環境変数**で管理してください
- `settings.local.json` はgitの管理対象外です（`.gitignore`に含まれます）
- 権限設定は**最小権限の原則**に従ってください

### バージョン管理

プロジェクトで設定を共有する場合：

- `settings.local.json.example` をコミット（テンプレート）
- `settings.local.json` は `.gitignore` に追加（個人設定）

## トラブルシューティング

### Claude Code が起動しない

1. JSON構文をチェック：
```bash
python3 -m json.tool .claude/settings.local.json
```

2. MCPサーバーのコマンドパスを確認：
```bash
which uvx
which npx
```

3. VSCode のバージョンを確認（1.98.0以上が必要）

### MCP サーバーが動作しない

1. サーバーが正しくインストールされているか確認：
```bash
uvx mcp-server-fetch --help
npx @playwright/mcp@latest --help
```

2. VSCode Developer Tools でログを確認：
   - `Help` > `Toggle Developer Tools` > `Console`

## 関連ドキュメント

- [セットアップスクリプト](../../docs/scripts-setup-tools.md) - 設定の再生成・バックアップ
- [テンプレートREADME](../README.md) - 全体の概要
- [コンテナツール一覧](../../docs/container-tooling.md) - プリインストール済みツール

---

**更新日**: 2025-10-19
