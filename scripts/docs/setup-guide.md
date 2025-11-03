# セットアップスクリプト利用ガイド

Claym プロジェクトには、AI CLI（Claude Code、Codex CLI、Gemini CLI）の設定を管理するための便利なスクリプトが用意されています。

## 📁 スクリプト一覧

| スクリプト | 用途 | タイミング |
|-----------|------|-----------|
| `init-ai-configs.sh` | 初回セットアップ | コンテナ起動時に自動実行 |
| `reinit-ai-configs.sh` | 設定の再生成・バックアップ | テンプレート更新後、設定リセット時 |

## 🚀 クイックスタート

### 初回セットアップ（自動）

devcontainer のビルド・起動時に `init-ai-configs.sh` が自動実行されます。手動実行する場合：

```bash
bash scripts/setup/init-ai-configs.sh
```

### 設定の再生成

テンプレートが更新された場合や、設定をリセットしたい場合：

```bash
# 対話モードで実行（確認プロンプトあり）
bash scripts/setup/reinit-ai-configs.sh

# 自動実行（確認なし）
bash scripts/setup/reinit-ai-configs.sh -y
```

## 📖 reinit-ai-configs.sh 詳細ガイド

### 基本機能

`reinit-ai-configs.sh` は以下の3つの主要機能を提供します：

1. **バックアップ + 再生成**（デフォルト）
2. **バックアップのみ**（`--backup-only`）
3. **バックアップから復元**（`--restore`）

### オプション一覧

| オプション | 短縮形 | 説明 |
|-----------|--------|------|
| `--yes` | `-y` | 確認プロンプトをスキップ（自動実行） |
| `--backup-only` | - | バックアップのみ実行（再生成しない） |
| `--restore TIMESTAMP` | - | 指定したバックアップから復元 |
| `--list-backups` | - | 利用可能なバックアップ一覧を表示 |
| `--dry-run` | - | 実際には変更せず、実行内容を表示 |
| `--verbose` | `-v` | 詳細ログを出力 |
| `--help` | `-h` | ヘルプを表示 |

### バックアップ対象ファイル

以下のファイルが自動的にバックアップされます：

- `.claude/settings.local.json` - Claude Code MCP サーバー設定と権限
- `.claude/CLAUDE.md` - Claude Code カスタム指示
- `~/.codex/config.toml` - Codex CLI 設定（ホームディレクトリ）
- `AGENTS.md` - Codex CLI エージェント指示（プロジェクトルート）
- `.gemini/settings.json` - Gemini CLI 設定
- `.gemini/GEMINI.md` - Gemini CLI カスタム指示
- `.gemini/commands/*.md` - Gemini CLI カスタムコマンド

### バックアップの保存場所

```
~/.config/claym-backups/
├── 20251019_153000/          # タイムスタンプ付きディレクトリ
│   ├── backup-manifest.txt   # バックアップファイル一覧
│   ├── .claude/
│   │   ├── settings.local.json
│   │   └── CLAUDE.md
│   ├── .codex/
│   │   └── config.toml
│   ├── .gemini/
│   │   ├── settings.json
│   │   ├── GEMINI.md
│   │   └── commands/
│   │       └── yfinance.md
│   └── AGENTS.md
├── 20251019_163000/
└── 20251019_173000/
```

## 💡 使用例とシナリオ

### シナリオ1: テンプレートが更新されたので最新版に更新したい

```bash
# 1. バックアップ一覧を確認（念のため）
bash scripts/setup/reinit-ai-configs.sh --list-backups

# 2. 対話モードで再生成（推奨）
bash scripts/setup/reinit-ai-configs.sh

# または自動実行
bash scripts/setup/reinit-ai-configs.sh -y
```

**何が起こるか**:
1. 現在の設定が日付付きでバックアップされる
2. 既存の設定ファイルが削除される
3. テンプレートから最新の設定が生成される

### シナリオ2: カスタマイズした設定を保持したまま一部だけ更新したい

```bash
# 1. まずバックアップだけ取る
bash scripts/setup/reinit-ai-configs.sh --backup-only

# 2. テンプレートから新しい設定を生成
bash scripts/setup/reinit-ai-configs.sh -y

# 3. バックアップと新しい設定を比較
diff ~/.config/claym-backups/20251019_153000/.claude/settings.local.json \
     .claude/settings.local.json

# 4. 必要な部分だけ手動でマージ
nano .claude/settings.local.json
```

### シナリオ3: 設定を間違えたので元に戻したい

```bash
# 1. 利用可能なバックアップを確認
bash scripts/setup/reinit-ai-configs.sh --list-backups

# 出力例:
# タイムスタンプ         ファイル数      パス
# -------------------   --------------  ----
# 20251019_173000       6               ~/.config/claym-backups/20251019_173000
# 20251019_163000       6               ~/.config/claym-backups/20251019_163000
# 20251019_153000       5               ~/.config/claym-backups/20251019_153000

# 2. 指定したバックアップから復元
bash scripts/setup/reinit-ai-configs.sh --restore 20251019_163000
```

**何が起こるか**:
1. 現在の設定が新しいタイムスタンプでバックアップされる（安全のため）
2. 指定したバックアップから設定が復元される

### シナリオ4: dry-run で確認してから実行したい

```bash
# dry-run モードで実行（実際には変更しない）
bash scripts/setup/reinit-ai-configs.sh --dry-run -v

# 問題なければ本番実行
bash scripts/setup/reinit-ai-configs.sh -y
```

### シナリオ5: 定期的にバックアップを取りたい

```bash
# バックアップのみ実行
bash scripts/setup/reinit-ai-configs.sh --backup-only

# cron で定期実行する場合（例: 毎週日曜日 3:00）
# 0 3 * * 0 /workspaces/claym/scripts/setup/reinit-ai-configs.sh --backup-only
```

## 🔧 各AI CLIの設定詳細

### Claude Code

**設定ファイル**:
- `.claude/settings.local.json` - MCP サーバー設定と権限
- `.claude/CLAUDE.md` - カスタム指示（日本語設定など）
- `.claude/commands/` - カスタムコマンド
- `.claude/agents/` - サブエージェント（タスク特化型AIエージェント）

**主な設定項目**:
```json
{
  "mcpServers": {
    "serena": { ... },
    "filesystem": { ... },
    "fetch": { ... }  // ← 今回追加
  },
  "permissions": {
    "allow": [ ... ],
    "deny": [ ... ],
    "ask": [ ... ]
  }
}
```

**カスタマイズポイント**:
- `mcpServers`: プロジェクトに必要なMCPサーバーを選択
- `permissions.allow`: 自動承認する操作を追加
- `permissions.ask`: 確認が必要な操作を追加

**サブエージェント**:

Claude Code のサブエージェント機能により、タスクごとに専門化されたAIエージェントを利用できます。

標準提供されるサブエージェント：
1. **code-reviewer** - コードレビュー専門家
   - コード品質、セキュリティ、パフォーマンスを評価

2. **test-generator** - テスト生成専門家
   - ユニットテスト、統合テストを自動生成

3. **documentation-writer** - ドキュメント作成専門家
   - API仕様書、README、チュートリアルを作成

詳細は [サブエージェント利用ガイド](./subagents-guide.md) を参照してください。

### Codex CLI

**設定ファイル**:
- `~/.codex/config.toml` - グローバル設定（ホームディレクトリ）
- `AGENTS.md` - エージェント指示（プロジェクトルート）

**主な設定項目**:
```toml
# モデル設定
model = "gpt-4-turbo"

# MCP サーバー
[mcp_servers.fetch]
command = "uvx"
args = ["mcp-server-fetch"]

# 承認ポリシー
approval_policy = "auto"
language = "ja"
```

**カスタマイズポイント**:
- `model`: 使用するモデルを選択
- `approval_policy`: 承認ポリシーを調整
- `[tool_approval]`: ツールごとの承認設定

### Gemini CLI

**設定ファイル**:
- `.gemini/settings.json` - MCP サーバー設定
- `.gemini/GEMINI.md` - カスタム指示
- `.gemini/commands/*.md` - カスタムコマンド

**主な設定項目**:
```json
{
  "mcpServers": {
    "serena": { ... },
    "fetch": { ... }
  }
}
```

**カスタマイズポイント**:
- `mcpServers`: 必要なMCPサーバーを選択
- `GEMINI.md`: プロジェクト固有の指示を追加

## 🛡️ 安全機能

### 1. 自動バックアップ

すべての操作の前に、現在の設定が自動的にバックアップされます：

```bash
# 通常の再生成でもバックアップが取られる
bash scripts/setup/reinit-ai-configs.sh -y

# バックアップ場所が表示される
# [INFO] バックアップディレクトリ: ~/.config/claym-backups/20251019_153000
```

### 2. 復元前の保護

バックアップから復元する際も、現在の設定がバックアップされます：

```bash
# 復元前に現在の設定もバックアップされる
bash scripts/setup/reinit-ai-configs.sh --restore 20251019_153000

# [INFO] 復元前に現在の設定をバックアップします...
# [INFO] バックアップディレクトリ: ~/.config/claym-backups/20251019_180000
```

### 3. Dry-run モード

実際に変更する前に、何が起こるかを確認できます：

```bash
bash scripts/setup/reinit-ai-configs.sh --dry-run -v

# [DRY-RUN] バックアップディレクトリ: ~/.config/claym-backups/20251019_153000
# [DRY-RUN] .claude/settings.local.json
# [DRY-RUN] 6 個のファイルをバックアップします
```

### 4. マニフェストファイル

各バックアップには、含まれるファイルのリストが記録されます：

```bash
cat ~/.config/claym-backups/20251019_153000/backup-manifest.txt

# # AI拡張機能 設定バックアップ
# # 作成日時: 2025-10-19 15:30:00
# # プロジェクト: /workspaces/claym
#
# .claude/settings.local.json
# .claude/CLAUDE.md
# .codex/config.toml
# AGENTS.md
# .gemini/settings.json
# .gemini/GEMINI.md
# .gemini/commands/yfinance.md
```

## 🐛 トラブルシューティング

### 問題1: スクリプトが実行できない

```bash
# 実行権限を確認
ls -la scripts/setup/reinit-ai-configs.sh

# 権限がない場合は付与
chmod +x scripts/setup/reinit-ai-configs.sh
```

### 問題2: バックアップディレクトリにアクセスできない

```bash
# ディレクトリの存在確認
ls -la ~/.config/claym-backups/

# 権限を確認
stat ~/.config/claym-backups/

# 必要に応じて修正
chmod 755 ~/.config/claym-backups/
```

### 問題3: 復元が失敗する

```bash
# マニフェストファイルの確認
cat ~/.config/claym-backups/20251019_153000/backup-manifest.txt

# バックアップファイルの存在確認
find ~/.config/claym-backups/20251019_153000/ -type f

# 詳細ログで実行
bash scripts/setup/reinit-ai-configs.sh --restore 20251019_153000 -v
```

### 問題4: テンプレートが見つからない

```bash
# テンプレートディレクトリの確認
ls -la templates/.claude/
ls -la templates/.codex/
ls -la templates/.gemini/

# プロジェクトルートから実行していることを確認
pwd
# /workspaces/claym であること
```

### 問題5: 一部のファイルだけ復元したい

```bash
# バックアップディレクトリから手動でコピー
cp ~/.config/claym-backups/20251019_153000/.claude/settings.local.json \
   .claude/settings.local.json

# または特定のファイルだけ復元
cp ~/.config/claym-backups/20251019_153000/.codex/config.toml \
   ~/.codex/config.toml
```

## 📊 バックアップの管理

### バックアップ一覧の表示

```bash
bash scripts/setup/reinit-ai-configs.sh --list-backups

# タイムスタンプ         ファイル数      パス
# -------------------   --------------  ----
# 20251019_180000       6               ~/.config/claym-backups/20251019_180000
# 20251019_173000       6               ~/.config/claym-backups/20251019_173000
# 20251019_163000       6               ~/.config/claym-backups/20251019_163000
```

### 古いバックアップの削除

```bash
# 30日以上前のバックアップを削除
find ~/.config/claym-backups/ -type d -name "????????_??????" -mtime +30 -exec rm -rf {} +

# 特定のバックアップを削除
rm -rf ~/.config/claym-backups/20251019_153000
```

### バックアップのサイズ確認

```bash
# 各バックアップのサイズを表示
du -sh ~/.config/claym-backups/*

# 合計サイズ
du -sh ~/.config/claym-backups/
```

## 🔄 CI/CDでの利用

### GitHub Actions での例

```yaml
name: Update AI Configs

on:
  push:
    paths:
      - 'templates/**'

jobs:
  update-configs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Backup current configs
        run: |
          bash scripts/setup/reinit-ai-configs.sh --backup-only

      - name: Regenerate configs
        run: |
          bash scripts/setup/reinit-ai-configs.sh -y

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .claude/ .gemini/ AGENTS.md
          git commit -m "chore: regenerate AI configs from templates"
          git push
```

## 📚 関連ドキュメント

- [Scripts README](../README.md) - スクリプト全体の概要
- [テストリファクタリングレポート](./test-refactoring-report.md) - リファクタリングの詳細
- [テンプレート README](../../templates/README.md) - テンプレートの詳細説明
- [コンテナツール一覧](../../docs/container-tooling.md) - プリインストール済みツール
- [VSCode拡張機能](../../docs/vscode-extensions.md) - AI拡張機能の概要

## 💬 サポート

質問や問題がある場合：

- **Issue**: [GitHub Issues](https://github.com/tomohiroJin/claym/issues)
- **ドキュメント**: `docs/` ディレクトリ内の各種ガイド

## 📝 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-10-19 | 1.0.0 | 初版リリース |

---

**作成日**: 2025-10-19
**メンテナ**: Claude Code
