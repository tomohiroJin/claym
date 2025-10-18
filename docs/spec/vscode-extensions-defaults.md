# VSCode拡張機能のプロンプト・設定デファクトスタンダード仕様書

## 概要

このドキュメントは、Claude Code、Codex CLI、GEMINI の VSCode 拡張機能における、
プロンプト設定・構成ファイルのベストプラクティスとデファクトスタンダードを定義します。

## 目的

- 各AI拡張機能の一貫した設定パターンを確立
- プロジェクト固有の設定とユーザー固有の設定を明確に分離
- MCP (Model Context Protocol) サーバーの標準的な構成を定義
- チーム開発における設定の再現性を向上

## 対象ツール

### 1. Claude Code (Anthropic)
- **設定ディレクトリ**: `.claude/`
- **設定ファイル**: `settings.local.json`
- **特徴**: MCP サーバーの豊富なサポート、permissions 管理

### 2. Codex CLI (OpenAI)
- **設定ディレクトリ**: `.codex/` (プロジェクト固有)
- **設定ファイル**: `config.toml`
- **特徴**: TOML形式、SSE (Server-Sent Events) 対応

### 3. GEMINI (Google)
- **設定ディレクトリ**: `.gemini/`
- **設定ファイル**: `settings.json`
- **特徴**: UI設定、OAuth認証、MCP サーバー構成

## 現状分析

### Claude Code (.claude/settings.local.json)

現在の構成:
```json
{
  "permissions": {
    "allow": [
      "Bash(bash:*)",
      "Read(//home/vscode/**)",
      "Bash(git:*)",
      "mcp__serena__*",
      "WebSearch",
      // その他多数の権限
    ],
    "deny": [],
    "ask": []
  }
}
```

**特徴**:
- きめ細かい権限管理
- ワイルドカード対応
- 段階的な許可レベル (allow/deny/ask)

### GEMINI (.gemini/settings.json)

現在の構成:
```json
{
  "general": {
    "preferredEditor": "vscode"
  },
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  },
  "mcpServers": {
    "serena": { "command": "uv", "args": [...] },
    "playwright": { "command": "npx", "args": [...] },
    "markitdown": { "command": "markitdown-mcp", "args": [] },
    "imagesorcery": { "command": "imagesorcery-mcp", "args": [] },
    "filesystem": { "command": "npx", "args": [...] },
    "github": { "command": "uvx", "args": [...] },
    "context7": { "command": "npx", "args": [...] }
  }
}
```

**特徴**:
- UI設定の統合
- MCP サーバーの一元管理
- 認証方式の選択

### Codex CLI

現在の実装:
- `.devcontainer/scripts/helpers/codex_config_writer.py` による設定生成
- TOML形式での構成管理
- SSE (Server-Sent Events) トランスポート対応

## 標準MCP サーバー構成

### 推奨MCPサーバー一覧

| サーバー名 | 用途 | コマンド | 優先度 |
|-----------|------|----------|--------|
| serena | コードベース解析・編集 | uv run serena | 必須 |
| filesystem | ファイル操作 | npx @modelcontextprotocol/server-filesystem | 必須 |
| github | GitHub API 統合 | uvx mcp-github | 推奨 |
| playwright | ブラウザ自動化 | npx @playwright/mcp@latest | 推奨 |
| context7 | ドキュメント検索 | npx @upstash/context7-mcp | 推奨 |
| markitdown | ドキュメント変換 | markitdown-mcp | オプション |
| imagesorcery | 画像処理 | imagesorcery-mcp | オプション |

### MCPサーバー設定パターン

#### Python系 (uv/uvx)
```json
{
  "command": "uv",
  "args": ["run", "--directory", "/opt/serena", "serena", "start-mcp-server"]
}
```

#### Node.js系 (npx)
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspaces/claym"]
}
```

#### スタンドアロン系
```json
{
  "command": "markitdown-mcp",
  "args": []
}
```

## デファクトスタンダード提案

### 1. ディレクトリ構造

```
project-root/
├── .claude/
│   ├── settings.local.json      # Claude Code プロジェクト設定
│   └── prompts/                 # カスタムプロンプト (オプション)
├── .codex/
│   └── config.toml              # Codex CLI プロジェクト設定
├── .gemini/
│   └── settings.json            # GEMINI プロジェクト設定
├── .vscode/
│   └── settings.json            # VSCode 共通設定
└── docs/
    ├── spec/                    # 仕様書
    └── prompts/                 # チーム共有プロンプト
```

### 2. 設定ファイルのスコープ

#### プロジェクト設定 (バージョン管理対象)
- `.vscode/settings.json`: VSCode基本設定
- `docs/prompts/`: チーム共有プロンプト
- `docs/spec/`: 仕様書・ガイドライン

#### ローカル設定 (バージョン管理対象外)
- `.claude/settings.local.json`: Claude Code 権限設定
- `.codex/config.toml`: Codex CLI 設定
- `.gemini/settings.json`: GEMINI 設定
- `.gitignore` に追加すべき項目:
  ```
  .claude/settings.local.json
  .codex/config.toml
  .gemini/settings.json
  ```

### 3. 共通設定パターン

#### A. 基本権限セット (Claude Code)

```json
{
  "permissions": {
    "allow": [
      "Bash(echo:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(git:*)",
      "Read(//home/vscode/**)",
      "mcp__filesystem__*",
      "WebSearch"
    ],
    "deny": [],
    "ask": [
      "Bash(rm:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

#### B. 拡張権限セット (開発用)

```json
{
  "permissions": {
    "allow": [
      "Bash(bash:*)",
      "Bash(python3:*)",
      "Bash(poetry:*)",
      "Bash(git:*)",
      "Read(//home/vscode/**)",
      "Read(//root/.local/**)",
      "mcp__serena__*",
      "mcp__filesystem__*",
      "mcp__github__*",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  }
}
```

#### C. MCP サーバー共通構成 (GEMINI)

```json
{
  "mcpServers": {
    "serena": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "/opt/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "ide-assistant",
        "--project",
        "${workspaceFolder}"
      ]
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${workspaceFolder}"
      ]
    }
  }
}
```

### 4. プロンプトテンプレート

#### システムプロンプト (docs/prompts/system.md)

```markdown
# システムプロンプト

あなたは、以下のプロジェクトで作業を行うAIアシスタントです：

## プロジェクト情報
- 名前: {{PROJECT_NAME}}
- 言語: {{LANGUAGE}}
- フレームワーク: {{FRAMEWORK}}

## コーディング規約
- インデント: {{INDENT_STYLE}}
- 命名規則: {{NAMING_CONVENTION}}
- コメント: 日本語/英語

## 作業方針
1. 既存のコードスタイルを尊重
2. テストを含めて実装
3. ドキュメントを更新
```

#### タスクプロンプト (docs/prompts/tasks/)

```markdown
# 機能追加プロンプト

## 目的
新しい機能を追加する際のチェックリスト

## 手順
1. 仕様の確認
2. 設計の検討
3. 実装
4. テストの作成
5. ドキュメントの更新

## 確認事項
- [ ] 既存機能への影響確認
- [ ] パフォーマンスへの影響確認
- [ ] セキュリティの考慮
```

## 実装ガイドライン

### 新規プロジェクトでのセットアップ

1. **基本ディレクトリ作成**
   ```bash
   mkdir -p .claude .codex .gemini docs/spec docs/prompts
   ```

2. **設定ファイル配置**
   - Claude Code: `.claude/settings.local.json` を作成
   - GEMINI: `.gemini/settings.json` を作成
   - Codex: `.codex/config.toml` を作成

3. **.gitignore 更新**
   ```
   .claude/settings.local.json
   .codex/config.toml
   .gemini/settings.json
   ```

4. **ドキュメント作成**
   - `docs/spec/`: 仕様書を配置
   - `docs/prompts/`: プロンプトテンプレートを配置

### 既存プロジェクトへの適用

1. **現行設定のバックアップ**
   ```bash
   cp .claude/settings.local.json .claude/settings.local.json.bak
   cp .gemini/settings.json .gemini/settings.json.bak
   ```

2. **段階的な移行**
   - 基本権限セットから開始
   - 動作確認後、拡張権限を追加

3. **チーム内での共有**
   - `docs/spec/` 配下のドキュメントをレビュー
   - プロンプトテンプレートを共有

## セキュリティ考慮事項

### 機密情報の管理

1. **APIキー・トークン**
   - 環境変数として管理
   - `.env` ファイルを `.gitignore` に追加
   - devcontainer の `remoteEnv` で注入

2. **権限の最小化**
   - 必要最小限の権限のみ許可
   - 破壊的操作は `ask` に配置
   - 定期的な権限レビュー

3. **設定ファイルの保護**
   - ローカル設定はバージョン管理対象外
   - サンプルファイル (.example) をコミット

## 運用・メンテナンス

### 定期的な見直し

1. **月次レビュー**
   - 権限設定の妥当性確認
   - 不要な権限の削除
   - 新規ツール・MCPサーバーの評価

2. **ドキュメント更新**
   - 設定変更の記録
   - チーム内フィードバックの反映

3. **ベストプラクティスの共有**
   - 効果的なプロンプトの収集
   - トラブルシューティング事例の蓄積

## 参考リンク

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Codex CLI Documentation](https://github.com/openai/codex-cli)
- [VSCode Extensions API](https://code.visualstudio.com/api)

## 改訂履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 1.0.0 | 2025-10-18 | 初版作成 |
