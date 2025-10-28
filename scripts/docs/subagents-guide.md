# Claude Code サブエージェント 利用ガイド

Claude Code のサブエージェント機能を使用すると、特定のタスクに特化した専門的なAIエージェントを定義できます。

## 📚 目次

- [サブエージェントとは](#サブエージェントとは)
- [標準提供されるサブエージェント](#標準提供されるサブエージェント)
- [セットアップ方法](#セットアップ方法)
- [使用方法](#使用方法)
- [カスタムエージェントの作成](#カスタムエージェントの作成)
- [YAML設定リファレンス](#yaml設定リファレンス)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

## サブエージェントとは

サブエージェントは、YAML形式で定義された専門的なAIエージェントです。各エージェントは以下を持ちます：

- **専門化されたプロンプト**: タスクに最適化された指示
- **ツール設定**: 必要なツールのみを利用
- **動作モード**: タスクに応じた処理方式
- **カスタム設定**: エージェント固有のパラメータ

### メリット

1. **タスクの専門性**: 各タスクに特化した高品質な出力
2. **一貫性**: 同じタスクに対して一貫した動作
3. **再利用性**: 定義を保存して繰り返し使用可能
4. **カスタマイズ性**: プロジェクト固有の要件に対応

## 標準提供されるサブエージェント

### 1. code-reviewer (コードレビュー専門家)

**用途**: コードの品質、セキュリティ、パフォーマンスを評価

**特徴**:
- コードの品質と可読性の評価
- セキュリティ脆弱性の検出
- パフォーマンス改善提案
- ベストプラクティスへの準拠チェック

**対応言語**:
- Python, JavaScript, TypeScript, Java, Go, Ruby, Rust, Bash

**出力形式**:
```markdown
# コードレビュー結果

## 概要
[ファイル名とレビュー対象の簡単な説明]

## 重要度：高
[重大な問題や必須の修正事項]

## 重要度：中
[改善を推奨する事項]

## 重要度：低
[軽微な改善提案]

## 良い点
[優れている実装や参考になる箇所]

## 総合評価
[全体的な評価とまとめ]
```

**使用例**:
```bash
# Claude Code でコードレビューを実行
# 1. code-reviewer エージェントを選択
# 2. レビュー対象のファイルを指定
# 3. 詳細なレビュー結果を受け取る
```

### 2. test-generator (テスト生成専門家)

**用途**: ユニットテスト、統合テストの自動生成

**特徴**:
- ユニットテストの自動生成
- 統合テストの生成
- テストカバレッジの向上
- Arrange-Act-Assert パターンの使用
- モック/スタブの自動生成

**対応テストフレームワーク**:
- Python: pytest
- JavaScript: Jest, Vitest
- TypeScript: Jest, Vitest
- Java: JUnit
- Go: testing
- Ruby: RSpec
- Bash: bats-core

**テストカバレッジ目標**: 80%

**使用例**:
```bash
# テスト生成の実行
# 1. test-generator エージェントを選択
# 2. テスト対象のファイルを指定
# 3. 生成されたテストコードをレビュー
# 4. テストを実行して検証
```

### 3. documentation-writer (ドキュメント作成専門家)

**用途**: 技術ドキュメント、API仕様書、README等の作成

**特徴**:
- API ドキュメントの生成
- README の作成
- チュートリアルの作成
- コードコメントの自動生成
- 多言語対応（日本語/英語）

**生成可能なドキュメント**:
- README.md
- API 仕様書
- 関数/クラス ドキュメント
- チュートリアル
- ユーザーガイド

**docstring スタイル対応**:
- Python: Google, NumPy, Sphinx
- JavaScript: JSDoc
- TypeScript: TSDoc
- Java: Javadoc
- Go: godoc
- Ruby: YARD

**使用例**:
```bash
# ドキュメント生成の実行
# 1. documentation-writer エージェントを選択
# 2. ドキュメント化対象のコードを指定
# 3. ドキュメントタイプを選択（README/API/チュートリアル等）
# 4. 生成されたドキュメントをレビュー
```

## セットアップ方法

### 自動セットアップ（推奨）

`init-ai-configs.sh` を実行すると、サブエージェントが自動的にセットアップされます：

```bash
bash scripts/setup/init-ai-configs.sh
```

**セットアップ内容**:
- `templates/.claude/agents/` から `.claude/agents/` にコピー
- 3つの標準エージェント（code-reviewer, test-generator, documentation-writer）が配置
- エージェント数が表示される

### 手動セットアップ

個別にセットアップする場合：

```bash
# ディレクトリ作成
mkdir -p .claude/agents

# エージェントをコピー
cp templates/.claude/agents/*.yaml .claude/agents/
```

### セットアップの確認

```bash
# エージェントファイルを確認
ls -la .claude/agents/

# 出力例:
# -rw-r--r-- 1 user user 2934 Oct 24 22:28 code-reviewer.yaml
# -rw-r--r-- 1 user user 4643 Oct 24 22:28 documentation-writer.yaml
# -rw-r--r-- 1 user user 3633 Oct 24 22:28 test-generator.yaml
```

## 使用方法

### Claude Code でのサブエージェント利用

1. **Claude Code を起動**
   ```bash
   code .
   ```

2. **サブエージェントを選択**
   - Claude Code のインターフェースからエージェントを選択
   - または、チャットで明示的に指定

3. **タスクを実行**
   - エージェントにタスクを依頼
   - 専門化されたプロンプトで高品質な出力を取得

### タスク別の使用例

#### コードレビューの実行

```bash
# Claude Code で実行
"code-reviewer エージェントを使用して、
src/services/user_service.py をレビューしてください"
```

#### テスト生成の実行

```bash
# Claude Code で実行
"test-generator エージェントを使用して、
src/utils/validator.py のユニットテストを生成してください"
```

#### ドキュメント作成の実行

```bash
# Claude Code で実行
"documentation-writer エージェントを使用して、
src/api/endpoints.py の API ドキュメントを作成してください"
```

## カスタムエージェントの作成

### 基本的な手順

1. **テンプレートをコピー**
   ```bash
   cp .claude/agents/code-reviewer.yaml .claude/agents/my-custom-agent.yaml
   ```

2. **YAML ファイルを編集**
   ```bash
   vim .claude/agents/my-custom-agent.yaml
   ```

3. **エージェント定義をカスタマイズ**
   - name: エージェント名を変更
   - description: 説明を記述
   - prompt: カスタムプロンプトを記述
   - tools: 必要なツールを選択
   - settings: エージェント固有の設定を追加

### カスタムエージェントの例

#### セキュリティ専門レビュアー

```yaml
name: "security-reviewer"
description: "セキュリティに特化したコードレビュー専門家"
version: "1.0"

prompt: |
  あなたはセキュリティの専門家です。

  以下のセキュリティ観点でコードをレビューしてください：

  ## セキュリティチェック項目

  ### 1. 認証・認可
  - 認証処理の実装
  - 権限チェックの適切性
  - セッション管理

  ### 2. 入力検証
  - SQLインジェクション対策
  - XSS対策
  - パストラバーサル対策

  ### 3. 機密情報
  - パスワードの扱い
  - APIキーの管理
  - 個人情報の保護

  ### 4. 暗号化
  - データの暗号化
  - 通信の暗号化
  - 鍵管理

tools:
  - Read
  - Grep
  - Glob
  - mcp__serena__find_symbol
  - mcp__serena__search_for_pattern

mode: "thorough"
output_format: "markdown"

settings:
  security_focus: true
  include_patterns:
    - "**/*.py"
    - "**/*.js"
    - "**/*.java"
  exclude_patterns:
    - "**/test_*.py"
```

#### パフォーマンスチューナー

```yaml
name: "performance-tuner"
description: "パフォーマンス最適化の専門家"
version: "1.0"

prompt: |
  あなたはパフォーマンス最適化の専門家です。

  以下の観点でコードを分析してください：

  ## パフォーマンス分析項目

  ### 1. アルゴリズム効率
  - 時間計算量の評価
  - 空間計算量の評価
  - より効率的なアルゴリズムの提案

  ### 2. データ構造
  - 適切なデータ構造の選択
  - メモリ使用量の最適化

  ### 3. データベース
  - クエリの最適化
  - インデックスの活用
  - N+1問題の検出

  ### 4. キャッシング
  - キャッシュ戦略
  - メモ化の活用

  ## 出力形式

  各問題に対して：
  - 現在の実装
  - パフォーマンス上の問題
  - 改善案
  - 期待される効果

tools:
  - Read
  - Bash
  - mcp__serena__find_symbol
  - mcp__serena__find_referencing_symbols

mode: "balanced"
output_format: "markdown"

settings:
  performance_focus: true
  benchmark_suggestions: true
```

## YAML設定リファレンス

### 必須フィールド

#### name (string)

エージェントの一意な識別子。

```yaml
name: "my-agent"
```

#### description (string)

エージェントの簡潔な説明（1-2行）。

```yaml
description: "タスクの専門家エージェント"
```

#### version (string)

エージェント定義のバージョン。

```yaml
version: "1.0"
```

#### prompt (string, multiline)

エージェントのシステムプロンプト。タスクの実行方法を詳細に記述。

```yaml
prompt: |
  あなたは〇〇の専門家です。

  以下の方針で作業してください：
  - ...
  - ...
```

### オプションフィールド

#### tools (array)

エージェントが利用可能なツールのリスト。

**利用可能なツール**:
- `Read` - ファイル読み込み
- `Write` - ファイル書き込み
- `Edit` - ファイル編集
- `Bash` - コマンド実行
- `Grep` - コード検索
- `Glob` - ファイル検索
- `mcp__serena__get_symbols_overview` - シンボル概要取得
- `mcp__serena__find_symbol` - シンボル検索
- `mcp__serena__search_for_pattern` - パターン検索
- `mcp__serena__find_referencing_symbols` - 参照検索

```yaml
tools:
  - Read
  - Write
  - Bash
  - mcp__serena__find_symbol
```

#### mode (string)

エージェントの動作モード。

**利用可能なモード**:
- `thorough` - 徹底的な分析（高品質、低速）
- `balanced` - バランス重視（標準）
- `comprehensive` - 包括的な処理（広範囲）

```yaml
mode: "thorough"
```

#### output_format (string)

出力フォーマット。

```yaml
output_format: "markdown"
```

#### settings (object)

エージェント固有の設定。

**よく使用される設定**:

```yaml
settings:
  # 処理する最大ファイル数
  max_files: 50

  # 対象ファイルパターン
  include_patterns:
    - "**/*.py"
    - "**/*.js"

  # 除外パターン
  exclude_patterns:
    - "**/node_modules/**"
    - "**/.venv/**"

  # 詳細度
  detail_level: "detailed"  # "brief", "normal", "detailed"

  # 特定機能の有効化
  security_focus: true
  performance_focus: true
```

### 完全な例

```yaml
name: "example-agent"
description: "サンプルエージェントの説明"
version: "1.0"

prompt: |
  あなたは〇〇の専門家です。

  ## 作業方針

  ### 1. 第一の原則
  [詳細な説明]

  ### 2. 第二の原則
  [詳細な説明]

  ## 出力形式

  ```markdown
  # タイトル

  ## セクション1
  [内容]

  ## セクション2
  [内容]
  ```

tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - mcp__serena__find_symbol
  - mcp__serena__search_for_pattern

mode: "balanced"
output_format: "markdown"

settings:
  max_files: 50
  include_patterns:
    - "**/*.py"
    - "**/*.js"
    - "**/*.ts"
  exclude_patterns:
    - "**/node_modules/**"
    - "**/.venv/**"
    - "**/dist/**"
  detail_level: "detailed"
  custom_option: true
```

## ベストプラクティス

### 1. プロンプト設計

**明確な指示**:
```yaml
prompt: |
  あなたは〇〇の専門家です。

  # 明確な作業手順を記述
  1. 最初に〇〇を行う
  2. 次に〇〇を確認する
  3. 最後に〇〇をまとめる
```

**期待する出力形式を示す**:
```yaml
prompt: |
  ## 出力形式

  以下の形式で出力してください：

  ```markdown
  # タイトル
  [内容]
  ```
```

**具体的な例を含める**:
```yaml
prompt: |
  ## 例

  入力: [サンプル入力]
  出力: [サンプル出力]
```

### 2. ツール選択

**必要最小限のツールを選択**:
```yaml
# 読み取り専用タスクの場合
tools:
  - Read
  - Grep
  - Glob

# 書き込みが必要な場合
tools:
  - Read
  - Write
  - Edit
```

**タスクに応じたツールセット**:
```yaml
# コードレビュー
tools:
  - Read
  - Grep
  - mcp__serena__find_symbol

# テスト生成
tools:
  - Read
  - Write
  - mcp__serena__find_symbol

# ドキュメント作成
tools:
  - Read
  - Write
  - Edit
  - mcp__serena__get_symbols_overview
```

### 3. 設定の最適化

**対象ファイルを絞り込む**:
```yaml
settings:
  include_patterns:
    - "src/**/*.py"  # src 配下のみ
    - "!src/legacy/**"  # legacy は除外
```

**パフォーマンスの調整**:
```yaml
settings:
  max_files: 20  # 大規模プロジェクトでは制限
  detail_level: "normal"  # 速度重視の場合
```

### 4. バージョン管理

**エージェントをバージョン管理**:
```yaml
version: "1.0"  # 初版
version: "1.1"  # マイナーアップデート
version: "2.0"  # メジャーアップデート
```

**変更履歴をコメントで記録**:
```yaml
# 変更履歴:
# v1.0 (2025-10-24): 初版
# v1.1 (2025-10-25): セキュリティチェック追加
# v2.0 (2025-10-26): プロンプト全面改訂
```

## トラブルシューティング

### 問題1: エージェントが期待通りに動作しない

**症状**: 出力が期待と異なる

**原因と対処法**:

1. **プロンプトが不明確**
   ```yaml
   # 悪い例
   prompt: "コードをレビューしてください"

   # 良い例
   prompt: |
     あなたはコードレビューの専門家です。

     以下の観点でレビューしてください：
     1. コードの品質
     2. セキュリティ
     3. パフォーマンス
   ```

2. **必要なツールが不足**
   ```yaml
   # ファイルを読めない場合
   tools:
     - Read  # 追加
     - Grep
   ```

### 問題2: エージェントファイルが見つからない

**症状**: エージェントを選択できない

**確認事項**:

```bash
# ファイルの存在確認
ls -la .claude/agents/

# なければセットアップ実行
bash scripts/setup/init-ai-configs.sh

# または手動コピー
cp templates/.claude/agents/*.yaml .claude/agents/
```

### 問題3: YAML構文エラー

**症状**: エージェントの読み込みエラー

**対処法**:

```bash
# YAML構文チェック（Python使用）
python3 -c "import yaml; yaml.safe_load(open('.claude/agents/my-agent.yaml'))"

# または yq 使用
yq eval '.claude/agents/my-agent.yaml'
```

**よくあるYAMLエラー**:

```yaml
# エラー: インデントが不正
name: "agent"
 description: "desc"  # インデントが深すぎる

# 正しい例
name: "agent"
description: "desc"

# エラー: 複数行文字列の記法ミス
prompt:
  あなたは専門家です  # | が必要

# 正しい例
prompt: |
  あなたは専門家です
```

### 問題4: パフォーマンスが遅い

**症状**: エージェントの処理に時間がかかる

**対処法**:

```yaml
# 処理範囲を制限
settings:
  max_files: 20  # デフォルト50から削減
  include_patterns:
    - "src/**/*.py"  # 対象を絞る

# モードを変更
mode: "balanced"  # thorough から変更
```

### 問題5: カスタムエージェントが反映されない

**症状**: 作成したエージェントが表示されない

**確認事項**:

```bash
# ファイル名の確認（.yaml 拡張子）
ls -la .claude/agents/*.yaml

# ファイルの権限確認
chmod 644 .claude/agents/my-agent.yaml

# Claude Code の再起動
# VS Code を再起動
```

## 関連ドキュメント

- [Scripts README](../README.md) - スクリプト全体の概要
- [セットアップガイド](./setup-guide.md) - AI拡張機能のセットアップ
- [テンプレート README](../../templates/README.md) - テンプレートの詳細
- [テストリファクタリングレポート](./test-refactoring-report.md) - テスト実装の詳細

## サポート

質問や問題がある場合：

- **Issue**: [GitHub Issues](https://github.com/tomohiroJin/claym/issues)
- **ドキュメント**: `docs/` ディレクトリ内の各種ガイド

---

**作成日**: 2025-10-24
**更新日**: 2025-10-24
**バージョン**: 1.0
**メンテナ**: Claude Code
