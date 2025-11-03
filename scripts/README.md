# Scripts ディレクトリ

このディレクトリには、claymプロジェクトで使用される各種スクリプトが含まれています。

## ディレクトリ構成

```
scripts/
├── docs/                # スクリプト関連ドキュメント
│   ├── setup-guide.md   # セットアップガイド（詳細な使い方）
│   └── test-refactoring-report.md  # テストリファクタリングレポート
├── health/              # ヘルスチェック関連スクリプト
│   ├── checks/          # 各種チェック実装
│   ├── lib/             # ヘルスチェック共通ライブラリ
│   └── README.md        # ヘルスチェックの詳細ドキュメント
├── setup/               # セットアップ関連スクリプト
│   ├── common.sh        # セットアップスクリプト共通ライブラリ
│   ├── init-ai-configs.sh
│   ├── reinit-ai-configs.sh
│   └── copy-template-to-local.sh
└── test/                # テスト実行スクリプト
    └── run-setup-tests.sh
```

## セットアップスクリプト (`setup/`)

AI拡張機能の設定ファイルを管理するスクリプト群です。

### `init-ai-configs.sh`

AI拡張機能の設定ファイルを初期セットアップします。

**用途**:
- コンテナ初回起動時の自動実行
- 各AIツール（Claude Code, Codex CLI, GEMINI）の設定ファイル作成

**実行方法**:
```bash
bash scripts/setup/init-ai-configs.sh
```

**セットアップ内容**:
- Claude Code 設定（`.claude/settings.local.json`, `CLAUDE.md`, `commands/`, `agents/`）
- Codex CLI 設定（`~/.codex/config.toml`, `AGENTS.md`）
- GEMINI 設定（`.gemini/settings.json`, `GEMINI.md`）
- プロンプトテンプレート（`docs/prompts/`）
- `.gitignore` 更新

**特徴**:
- 既存ファイルは上書きしない（スキップ）
- テンプレートマージ機能（公式 + ローカル）
- 環境変数チェック（警告のみ）

### `reinit-ai-configs.sh`

既存の設定ファイルをバックアップして再生成します。

**用途**:
- テンプレート更新後の設定再生成
- 設定ファイルの初期化

**実行方法**:
```bash
# 対話モード
bash scripts/setup/reinit-ai-configs.sh

# 自動実行（確認なし）
bash scripts/setup/reinit-ai-configs.sh -y

# バックアップのみ
bash scripts/setup/reinit-ai-configs.sh --backup-only

# ドライラン（実際には変更しない）
bash scripts/setup/reinit-ai-configs.sh --dry-run

# ヘルプ表示
bash scripts/setup/reinit-ai-configs.sh --help
```

**主な機能**:
- バックアップ作成（タイムスタンプ付き）
- 既存設定の削除
- 新しい設定の生成
- バックアップからの復元機能

**バックアップ対象**:
- `.claude/commands/`
- `.claude/agents/`
- `.claude/CLAUDE.md`
- `templates-local/`

**バックアップ先**: `.backup-YYYYMMDD-HHMMSS/`

### `copy-template-to-local.sh`

公式テンプレートをローカルテンプレート（`templates-local/`）にコピーします。

**用途**:
- テンプレートのカスタマイズ準備
- 公式テンプレートをベースにしたローカル編集

**実行方法**:
```bash
# 単一のコマンドファイルをコピー
bash scripts/setup/copy-template-to-local.sh command review.md

# すべてのコマンドをコピー
bash scripts/setup/copy-template-to-local.sh command

# 単一のエージェントファイルをコピー
bash scripts/setup/copy-template-to-local.sh agent code-reviewer.yaml

# すべてのエージェントをコピー
bash scripts/setup/copy-template-to-local.sh agent

# CLAUDE.md をコピー
bash scripts/setup/copy-template-to-local.sh claude-md

# settings.local.json.example をコピー
bash scripts/setup/copy-template-to-local.sh settings

# Codex CLI テンプレートをコピー (.codex/ 配下のファイル)
bash scripts/setup/copy-template-to-local.sh codex

# Codex CLI プロンプトのみコピー (従来の shorthand と互換)
bash scripts/setup/copy-template-to-local.sh codex review.md

# Codex CLI プロンプトを相対パスで指定してコピー
bash scripts/setup/copy-template-to-local.sh codex prompts/review.md

# Codex CLI の AGENTS.md をコピー
bash scripts/setup/copy-template-to-local.sh codex AGENTS.md

# すべてをコピー
bash scripts/setup/copy-template-to-local.sh all

# ヘルプ表示
bash scripts/setup/copy-template-to-local.sh --help
```

**ワークフロー**:
1. このスクリプトで公式テンプレートを `templates-local/` にコピー
2. `templates-local/` 内のファイルを編集
3. `reinit-ai-configs.sh` で設定を再生成（ローカルテンプレートが優先される）

### `common.sh`

セットアップスクリプト群で共有される共通ライブラリです。

**提供機能**:
- **ログ関数**: `log_info`, `log_success`, `log_warn`, `log_error`, `log_debug`
- **ファイル操作**: `copy_file_if_not_exists`, `copy_directory_safe`
- **テンプレート操作**: `merge_template_directories`
- **環境変数チェック**: `check_api_keys`
- **gitignore更新**: `update_gitignore_safe`
- **パス操作**: `get_project_root`, `replace_in_file`
- **UI表示**: `show_header`, `show_footer`, `count_files_in_directory`

**設計方針**:
- 単一責任の原則（各関数が1つの責任のみ）
- エラーハンドリング（警告のみで処理継続）
- `set -euo pipefail` 環境下で安全に動作

**使用例**:
```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

readonly PROJECT_ROOT="$(get_project_root "${SCRIPT_DIR}")"

log_info "処理を開始します..."
copy_file_if_not_exists "${src}" "${dst}" "設定ファイル"
log_success "完了しました"
```

## テストスクリプト (`test/`)

### `run-setup-tests.sh`

セットアップスクリプトの自動テストを実行します。

**前提条件**:
- bats-core がインストール済み
- bats ヘルパーライブラリが利用可能

**実行方法**:
```bash
# すべてのテストを実行
bash scripts/test/run-setup-tests.sh all

# init-ai-configs.sh のテストのみ
bash scripts/test/run-setup-tests.sh init

# reinit-ai-configs.sh のテストのみ
bash scripts/test/run-setup-tests.sh reinit

# copy-template-to-local.sh のテストのみ
bash scripts/test/run-setup-tests.sh copy

# ヘルプ表示
bash scripts/test/run-setup-tests.sh --help
```

**テストファイル**: `tests/setup/*.bats`

**テスト内容**:
- 関数の動作確認（34テストケース）
- エッジケースの検証
- エラーハンドリングの確認

**実行結果**:
```
✅ init-ai-configs.sh:       7/7 テスト成功
✅ reinit-ai-configs.sh:    14/14 テスト成功
✅ copy-template-to-local:  13/13 テスト成功
✅ 合計:                    34/34 テスト成功
```

## ヘルスチェックスクリプト (`health/`)

開発環境の状態を診断するスクリプト群です。

詳細は [`health/README.md`](./health/README.md) を参照してください。

### 主なスクリプト

- **`check-environment.sh`**: 環境全体のヘルスチェック
- **`test-container-basics.sh`**: コンテナ基本機能のテスト
- **`test-health-checks.sh`**: ヘルスチェック機能自体のテスト

## Claude Code サブエージェント

Claude Code のサブエージェント機能を使用すると、特定のタスクに特化したエージェントを定義できます。

### サブエージェントとは

サブエージェントは、YAML形式で定義された専門的なAIエージェントです。各エージェントは特定のタスク（コードレビュー、テスト生成、ドキュメント作成など）に最適化されたプロンプトと設定を持ちます。

### 標準提供されるサブエージェント

`templates/.claude/agents/` には以下の3つのサブエージェントが標準で用意されています：

1. **code-reviewer.yaml** - コードレビュー専門家
   - コードの品質と可読性の評価
   - セキュリティ問題の検出
   - パフォーマンス改善提案
   - ベストプラクティスへの準拠チェック

2. **test-generator.yaml** - テスト生成専門家
   - ユニットテストの自動生成
   - 統合テストの生成
   - テストカバレッジの向上
   - テストフレームワーク対応（pytest, Jest, JUnit, RSpec, bats など）

3. **documentation-writer.yaml** - ドキュメント作成専門家
   - API ドキュメントの生成
   - README の作成
   - チュートリアルの作成
   - コードコメントの自動生成

### サブエージェントの使用方法

1. `init-ai-configs.sh` を実行すると、`.claude/agents/` にサブエージェントが自動的にコピーされます
2. Claude Code から特定のタスクを実行する際に、適切なサブエージェントを選択できます
3. 各サブエージェントは専門化されたプロンプトとツール設定を持っています

### サブエージェントのカスタマイズ

サブエージェントは `.claude/agents/` に配置されるため、プロジェクト固有のカスタマイズが可能です：

```bash
# カスタムサブエージェントの作成
cp templates/.claude/agents/code-reviewer.yaml .claude/agents/my-custom-reviewer.yaml

# YAML ファイルを編集してカスタマイズ
vim .claude/agents/my-custom-reviewer.yaml
```

**注意**: `.claude/agents/` は `.gitignore` に含まれているため、個人の設定としてカスタマイズできます。

### YAML 形式

サブエージェント定義の構造：

```yaml
name: "agent-name"
description: "エージェントの説明"
version: "1.0"

prompt: |
  エージェントのシステムプロンプト
  （複数行可）

tools:
  - Read
  - Write
  - Bash

mode: "thorough"  # または "balanced", "comprehensive"
output_format: "markdown"

settings:
  max_files: 50
  include_patterns:
    - "**/*.py"
  exclude_patterns:
    - "**/node_modules/**"
```

## テンプレートシステム

セットアップスクリプトは、以下の優先順位でテンプレートをマージします：

1. **公式テンプレート** (`templates/`)
   - リポジトリに含まれる標準テンプレート
   - バージョン管理対象

2. **ローカルテンプレート** (`templates-local/`)
   - ユーザー固有のカスタマイズ
   - `.gitignore` で除外（個人設定を保護）

### マージ処理

```
templates/.claude/commands/review.md          # 公式テンプレート
      ↓ コピー
.claude/commands/review.md
      ↓ 上書き（存在する場合）
templates-local/.claude/commands/review.md    # ローカルテンプレート
      ↓ 最終的な設定
.claude/commands/review.md                    # カスタマイズ版
```

### カスタマイズ手順

1. テンプレートをローカルにコピー:
   ```bash
   bash scripts/setup/copy-template-to-local.sh command review.md
   ```

2. ローカルテンプレートを編集:
   ```bash
   vim templates-local/.claude/commands/review.md
   ```

3. 設定を再生成:
   ```bash
   bash scripts/setup/reinit-ai-configs.sh
   ```

## リファクタリングパターン

これらのスクリプトは、マーチン・ファウラーのリファクタリングパターンを適用しています：

- **Extract Function**: 共通ロジックを `common.sh` に抽出
- **Replace Duplication**: 重複コードの排除
- **Single Responsibility**: 各関数が単一の責任を持つ
- **Self-Documenting Code**: 関数名から目的が明確
- **Compose Method**: 複雑な関数を小さな関数に分解

詳細は [`docs/test-refactoring-report.md`](./docs/test-refactoring-report.md) を参照してください。

## エラーハンドリング

すべてのスクリプトは `set -euo pipefail` で実行されますが、以下の関数は警告のみで処理を継続します：

- `check_api_keys`: APIキー未設定時（初期セットアップ時は正常）
- `copy_file_if_not_exists`: テンプレートファイル欠損時
- `merge_template_directories`: 公式テンプレートディレクトリ未存在時

これにより、部分的な問題があっても可能な限りセットアップを完了できます。

## トラブルシューティング

### テンプレートが見つからない

```bash
[WARN] Claude Code 設定ファイルのテンプレートが見つかりません: templates/.claude/settings.local.json.example
```

**原因**: テンプレートファイルが削除または移動されている

**対処法**:
1. Gitで復元: `git checkout templates/`
2. または警告を無視（他のファイルは正常にセットアップされます）

### APIキーが設定されていない

```bash
[WARN] 以下の環境変数が設定されていません:
[WARN]   - ANTHROPIC_API_KEY
```

**原因**: 環境変数が未設定（初期状態では正常）

**対処法**:
1. `.env` ファイルに設定
2. または後で設定（セットアップは完了します）

### バックアップから復元したい

```bash
# バックアップディレクトリを確認
ls -la .backup-*/

# 手動で復元
cp -r .backup-20250122-143000/.claude .
cp -r .backup-20250122-143000/templates-local .
```

## 開発者向け情報

### 新しいセットアップ処理の追加

1. `common.sh` に共通関数を追加
2. メインスクリプトで関数を呼び出し
3. テストケースを `tests/setup/` に追加
4. `run-setup-tests.sh` でテスト実行

### テストの追加

```bash
# tests/setup/init-ai-configs.bats に追加
@test "新機能: 説明" {
    # Arrange
    setup_test_environment

    # Act
    run new_function

    # Assert
    assert_success
}
```

### コーディング規約

- シェルスクリプトは `shellcheck` でチェック済み
- 関数にはコメントで引数・戻り値を明記
- ログ関数を使用（`echo` は使わない）
- エラーハンドリングを適切に実装

## 関連ドキュメント

- [セットアップガイド](./docs/setup-guide.md) - 詳細な使い方とユースケース
- [テストリファクタリングレポート](./docs/test-refactoring-report.md) - リファクタリングの詳細
- [ヘルスチェック](./health/README.md) - 環境診断ツール
- [テンプレートシステム](../templates/README.md) - テンプレートの詳細

## ライセンス

このプロジェクトのライセンスに従います。
