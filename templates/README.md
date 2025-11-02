# VSCode AI拡張機能 設定テンプレート

このディレクトリには、Claude Code、Codex CLI、GEMINI などの VSCode AI 拡張機能の
標準的な設定テンプレートとプロンプトが含まれています。

## 📁 ディレクトリ構造

```
templates/
├── .claude/
│   ├── settings.local.json.example    # Claude Code 設定テンプレート
│   ├── CLAUDE.md                       # Claude Code カスタム指示（日本語設定）
│   ├── commands/                       # Claude Code カスタムコマンド
│   │   └── *.md                        # コマンド定義ファイル
│   └── agents/                         # Claude Code サブエージェント
│       ├── code-reviewer.yaml          # コードレビュー専門家
│       ├── test-generator.yaml         # テスト生成専門家
│       └── documentation-writer.yaml   # ドキュメント作成専門家
├── .codex/
│   ├── config.toml.example            # Codex CLI 設定テンプレート（使用環境緩和設定含む）
│   ├── AGENTS.md                      # Codex CLI エージェント指示（日本語設定）
│   └── prompts/                       # Codex CLI カスタムプロンプト（slash コマンド）
│       └── *.md                       # `/prompts:<name>` で呼び出せるテンプレート
├── .gemini/
│   ├── settings.json.example          # GEMINI 設定テンプレート
│   └── GEMINI.md                      # GEMINI カスタム指示（日本語設定）
├── docs/
│   └── prompts/
│       ├── system.md                  # システムプロンプトテンプレート
│       └── tasks/
│           ├── feature-add.md         # 機能追加プロンプト
│           ├── bug-fix.md             # バグ修正プロンプト
│           ├── refactor.md            # リファクタリングプロンプト
│           └── review.md              # コードレビュープロンプト
└── README.md                          # このファイル

scripts/
└── setup/
    └── init-ai-configs.sh              # 自動セットアップスクリプト
```

## 🚀 クイックスタート

### 自動セットアップ（推奨）

**コンテナ起動時に自動で実行されます！**

devcontainer のビルド・起動時に `scripts/setup/init-ai-configs.sh` が自動実行され、
以下が自動的に設定されます：

- Claude Code 設定ファイル (`settings.local.json`, `CLAUDE.md`, `commands/`, `agents/`) の作成
- Codex CLI 設定ファイル (`config.toml`, `AGENTS.md`) の作成（プロジェクトパス自動設定）
- GEMINI 設定ファイル (`settings.json`, `GEMINI.md`) の作成（プロジェクトパス自動設定）
- プロンプトテンプレートのコピー
- .gitignore の更新

### 手動セットアップ（既存プロジェクト向け）

既存のプロジェクトに適用する場合：

```bash
# セットアップスクリプトを実行
bash scripts/setup/init-ai-configs.sh
```

または、個別にセットアップする場合：

```bash
# プロジェクトルートで実行
cd /path/to/your/project

# 設定ディレクトリを作成
mkdir -p .claude .codex/prompts docs/prompts/tasks
mkdir -p ~/.codex/prompts

# テンプレートをコピー
cp templates/.claude/settings.local.json.example .claude/settings.local.json
cp templates/.claude/CLAUDE.md .claude/CLAUDE.md
cp templates/.codex/config.toml.example ~/.codex/config.toml
cp templates/.codex/AGENTS.md AGENTS.md
cp templates/.codex/prompts/*.md .codex/prompts/
cp templates/.codex/prompts/*.md ~/.codex/prompts/
cp templates/.gemini/settings.json.example .gemini/settings.json
cp templates/.gemini/GEMINI.md .gemini/GEMINI.md

# プロンプトテンプレートをコピー
cp -r templates/docs/prompts/* docs/prompts/

# .gitignore に追加
cat >> .gitignore <<EOF

# CLAUDE 設定（全体を個人設定として管理）
.claude/
!templates/.claude/

# Codex 設定（全体を個人設定として管理）
.codex/
!templates/.codex/

# GEMINI 設定（全体を個人設定として管理）
.gemini/
!templates/.gemini/
EOF
```

### 設定のカスタマイズ

#### 1. Claude Code (.claude/settings.local.json)

```bash
# ファイルを編集
nano .claude/settings.local.json
```

**カスタマイズポイント**:
- `permissions.allow`: プロジェクトに必要な権限を追加
- `permissions.ask`: 確認が必要な操作を設定
- プロジェクトパスの更新

#### 2. Claude Code カスタム指示 (.claude/CLAUDE.md)

```bash
# ファイルを編集
nano .claude/CLAUDE.md
```

**日本語でのやり取りを基本とする設定が含まれています**:
- すべての応答を日本語で行う
- コメント・ドキュメントは日本語
- 丁寧語（です・ます調）の使用

#### 3. Codex CLI (~/.codex/config.toml)

```bash
# ファイルを編集
nano ~/.codex/config.toml
```

**すでに使用環境緩和設定が含まれています**:
- `approval_policy = "auto"`: 基本的に自動承認
- `language = "ja"`: 日本語を基本言語として使用
- `bash_operations = "auto"`: Linuxコマンドを基本的に自動承認（危険なコマンドのみ確認）
- `web_operations = "auto"`: Web検索・フェッチ操作を自動承認
- タイムアウト設定の緩和（5分〜10分）
- 出力制限の緩和（1MB、10000行）
- サンドボックス無効化（コンテナ内のため）
- カスタムシステムプロンプト（日本語設定）

**危険なコマンドのブロックリスト**（確認が必要）:
- ファイル削除系: `rm -rf`, システムディレクトリへの `rm`
- 権限昇格系: `sudo`, `su`
- システム変更系: `chmod -R`, `chown -R`, `dd`, `mkfs`, `fdisk`
- ネットワーク系: `nc -l`, `iptables` ※curl/wgetは許可
- パッケージ管理系: `apt remove`, `apt autoremove` ※installは許可
- データベース操作系: `DROP DATABASE`, `TRUNCATE TABLE`
- コンテナ操作系: `docker rm -f` 全削除, `docker system prune -a`

**追加カスタマイズポイント**:
- `model`: 使用するモデルを指定（例: "gpt-4-turbo"）
- プロファイル設定を追加（development, production など）

注: プロジェクトパスは自動セットアップで設定済みです。

#### 4. Codex CLI カスタムプロンプト (.codex/prompts/*.md)

```bash
# プロジェクト共有用のプロンプトを編集
nano .codex/prompts/yfinance.md

# 個人設定を編集
nano ~/.codex/prompts/yfinance.md
```

**カスタマイズポイント**:
- 各 `.md` ファイルが `/prompts:<name>` で呼び出せるコマンドになる
- プレースホルダー（$1, $FILE など）や YAML フロントマターで slash ポップアップを強化できる
- templates-local/.codex/prompts/ 以下に同名ファイルを置くと、公式テンプレートを上書き可能

**運用メモ**:
- 自動セットアップ時は templates/.codex/prompts/ 内の Markdown が `.codex/prompts` と `~/.codex/prompts` にコピーされる
- 既存ディレクトリがある場合は上書きされないため、再生成する場合は `reinit-ai-configs.sh` を利用する

#### 5. Codex CLI エージェント指示 (AGENTS.md)

```bash
# ファイルを編集（プロジェクトルート）
nano AGENTS.md
```

**AGENTS.md の特徴**:
- プロジェクトルートに配置（チーム共有）
- エージェント向けの「README」として機能
- 階層的に読み込まれる（ホーム → リポジトリ → カレントディレクトリ）

**カスタマイズポイント**:
- プロジェクト固有のアーキテクチャ情報を追加
- コーディング規約を詳細化
- テスト手順を明確化
- PR ガイドラインを更新

**個人設定** (オプション):
```bash
# 個人的なカスタマイズは ~/.codex/AGENTS.md で
nano ~/.codex/AGENTS.md
```

#### 6. GEMINI カスタム指示 (.gemini/GEMINI.md)

```bash
# ファイルを編集
nano .gemini/GEMINI.md
```

**GEMINI 固有の機能**:
- `/memory show`: 現在のコンテキストを確認
- `/init`: プロジェクト用の GEMINI.md を生成
- サブディレクトリにも配置可能

#### 6. システムプロンプト (docs/prompts/system.md)

```bash
# ファイルを編集
nano docs/prompts/system.md
```

**カスタマイズポイント**:
- `{{PLACEHOLDER}}` を実際の値に置換
- プロジェクト情報を記入
- コーディング規約を記述
- ディレクトリ構造を更新

## 📚 ドキュメント

### プロンプトテンプレートの使い方

#### 機能追加プロンプト

```bash
# AIに機能追加を依頼する際
cat docs/prompts/tasks/feature-add.md
```

使用例：
```
以下のガイドラインに従って、ユーザー認証機能を追加してください：

[docs/prompts/tasks/feature-add.md の内容を貼り付け]

機能要件：
- メールアドレスとパスワードでログイン
- JWTトークンによる認証
- パスワードのハッシュ化
```

#### バグ修正プロンプト

```bash
# AIにバグ修正を依頼する際
cat docs/prompts/tasks/bug-fix.md
```

#### リファクタリングプロンプト

```bash
# AIにリファクタリングを依頼する際
cat docs/prompts/tasks/refactor.md
```

#### コードレビュープロンプト

```bash
# AIにコードレビューを依頼する際
cat docs/prompts/tasks/review.md
```

### Claude Code サブエージェント

サブエージェントは、特定のタスクに特化したAIエージェントです。YAML形式で定義され、専門化されたプロンプトとツール設定を持ちます。

#### 標準提供されるサブエージェント

`.claude/agents/` には以下の3つのサブエージェントが自動的にセットアップされます：

1. **code-reviewer.yaml** - コードレビュー専門家
   - コードの品質と可読性の評価
   - セキュリティ問題の検出
   - パフォーマンス改善提案
   - ベストプラクティスへの準拠チェック

2. **test-generator.yaml** - テスト生成専門家
   - ユニットテストの自動生成
   - 統合テストの生成
   - テストカバレッジの向上
   - 多言語対応（Python, JavaScript, Java, Go, Ruby, Bash など）

3. **documentation-writer.yaml** - ドキュメント作成専門家
   - API ドキュメントの生成
   - README の作成
   - チュートリアルの作成
   - コードコメントの自動生成

#### サブエージェントの使用例

```bash
# カスタムサブエージェントの作成
cp .claude/agents/code-reviewer.yaml .claude/agents/security-focused-reviewer.yaml

# セキュリティに特化したレビュアーにカスタマイズ
vim .claude/agents/security-focused-reviewer.yaml
```

#### YAML 設定例

```yaml
name: "custom-agent"
description: "カスタムエージェントの説明"
version: "1.0"

prompt: |
  エージェントのシステムプロンプト
  タスクの実行方法や注意点を記述

tools:
  - Read
  - Write
  - Bash
  - mcp__serena__find_symbol

mode: "thorough"
output_format: "markdown"

settings:
  max_files: 50
  include_patterns:
    - "**/*.py"
  exclude_patterns:
    - "**/node_modules/**"
```

**詳細**: サブエージェントの詳細については、[scripts/README.md](../scripts/README.md#claude-code-サブエージェント) を参照してください。

## 🔧 MCP サーバー設定

### 推奨MCPサーバー

| サーバー名 | 用途 | 優先度 |
|-----------|------|--------|
| serena | コードベース解析・編集 | 必須 |
| filesystem | ファイル操作 | 必須 |
| fetch | Web検索・ページ取得 | 推奨 |
| github | GitHub API 統合 | 推奨 |
| playwright | ブラウザ自動化 | 推奨 |
| context7 | ドキュメント検索 | 推奨 |
| markitdown | ドキュメント変換 | オプション |
| imagesorcery | 画像処理 | オプション |

### MCPサーバーのインストール

```bash
# Serena (Python)
uv tool install serena

# Fetch (Python)
uvx mcp-server-fetch

# Playwright (Node.js)
npm install -g @playwright/mcp

# GitHub (Python)
uvx mcp-github

# その他のNode.jsサーバー
npx @modelcontextprotocol/server-filesystem
npx @upstash/context7-mcp
```

## 🛡️ セキュリティ

### 機密情報の管理

設定ファイルには以下を含めないでください：

- APIキー・トークン
- パスワード
- 個人情報
- プライベートなURLやパス

これらは環境変数で管理してください：

```bash
# .env ファイル（.gitignore に追加）
ANTHROPIC_API_KEY=your_api_key
OPENAI_API_KEY=your_api_key
GEMINI_API_KEY=your_api_key
GITHUB_TOKEN=your_token
```

### .gitignore の推奨設定

```gitignore
# AI拡張機能のローカル設定
.claude/settings.local.json
.codex/config.toml
.gemini/settings.json

# 環境変数
.env
.env.local

# APIキー・トークン
*.key
*.token
credentials.json
```

## 💡 ベストプラクティス

### 1. 権限管理（Claude Code）

- **最小権限の原則**: 必要最小限の権限のみ許可
- **段階的許可**: 基本権限から始めて、必要に応じて拡張
- **破壊的操作は ask に**: rm, sudo などは確認を求める

### 2. MCPサーバー構成

- **プロジェクトパスの変数化**: `${workspaceFolder}` を活用
- **不要なサーバーは無効化**: パフォーマンスのため
- **バージョン固定**: 本番環境では特定バージョンを指定

### 3. プロンプトの活用

- **コンテキストを与える**: システムプロンプトでプロジェクト情報を共有
- **タスクテンプレートを参照**: 一貫した作業フロー
- **カスタマイズ**: プロジェクト固有のルールを追加

### 4. チーム開発

- **サンプルファイルを共有**: `.example` ファイルをコミット
- **ドキュメントを充実**: README, CONTRIBUTING を整備
- **定期的なレビュー**: 設定の見直しを定期的に実施

## 🔄 アップデート

### テンプレートの更新

```bash
# 最新のテンプレートを取得
cd /path/to/claym
git pull origin main

# 差分を確認
diff templates/.claude/settings.local.json.example .claude/settings.local.json

# 必要に応じてマージ
```

### バージョン管理

テンプレートのバージョンは `docs/spec/vscode-extensions-defaults.md` の
改訂履歴を参照してください。

## 🐛 トラブルシューティング

### Claude Code が起動しない

1. VSCode のバージョンを確認（1.98.0以上）
2. 設定ファイルのJSON構文をチェック
3. 権限設定を見直す

### MCPサーバーが動作しない

1. サーバーがインストールされているか確認
2. コマンドパスが正しいか確認
3. ログを確認（VSCode Developer Tools）

### 権限エラーが頻発

1. `.claude/settings.local.json` の `allow` に追加
2. ワイルドカードを活用（例: `Bash(git:*)`）

## 📞 サポート

- **Issue**: [GitHub Issues](https://github.com/tomohiroJin/claym/issues)
- **ドキュメント**: [docs/spec/](../docs/spec/)
- **FAQ**: [docs/guides/](../docs/guides/)

## 📄 ライセンス

このテンプレート集は、Claym プロジェクトの一部として提供されています。

## 🙏 貢献

改善提案や新しいテンプレートのアイデアがあれば、ぜひPRを送ってください！

---

**作成日**: 2025-10-18
**バージョン**: 1.0.0
**メンテナ**: Claude Code
