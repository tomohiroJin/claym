# Codex CLI エージェント指示

このファイルは Codex CLI エージェントに対する永続的な指示を提供します。

## 言語設定

**日本語を基本言語として使用してください。**

- すべての応答は日本語で行う
- コメントは日本語で記述
- ドキュメントは日本語で作成
- エラーメッセージの説明は日本語で
- コードそのもの（変数名、関数名など）は英語でも可

## コミュニケーションスタイル

- 丁寧語を使用（「です・ます」調）
- 技術用語は適切に日本語訳するか、英語のままカタカナ表記
- 不明点は必ず質問する
- 段階的に説明し、理解を確認しながら進める

## 作業原則

### 変更前の確認
- コードを変更する前に、必ず既存の実装を読んで理解する
- 影響範囲を事前に提示し、承認を得てから作業する
- 既存のコードパターン・規約を尊重し、一貫性を保つ

### 安全な作業
- 破壊的変更を行う前に必ず確認する
- 一度に大きな変更をせず、小さなステップで進める
- 変更後は関連するテストを実行して動作確認する

### 情報の正確性
- 不確かな情報は推測であることを明示する
- ライブラリのバージョンやAPIの仕様は最新ドキュメントで確認する
- エラーの原因が不明な場合は、複数の可能性を提示する

## 作業パターン

### TDD サイクル
1. 失敗するテストを書く（Red）
2. テストを通す最小限の実装（Green）
3. リファクタリング（Refactor）

### テスト実行コマンド

```bash
# JavaScript / TypeScript
npm test
npm test -- --watch
npm test -- --coverage

# Python
poetry run pytest tests/
poetry run pytest --cov=src tests/
poetry run pytest tests/test_example.py -v
```

## コード品質基準

### 共通原則
- マジックナンバーは定数化する
- 関数は単一責任の原則に従う（1関数1目的）
- 早期リターンで条件分岐のネストを浅く保つ
- 命名で意図を表現する（コメントに頼らない）
- 関数は30行以内を目安（超える場合は分割を検討）
- パラメータは3個以内（超える場合はオブジェクトにまとめる）

### TypeScript / JavaScript（該当プロジェクトの場合）
- `any` 型の使用禁止 → `unknown` + 型ガードを使用
- `null` より `undefined` を優先（API 境界を除く）
- `const` を優先、`let` は必要な場合のみ、`var` は禁止

## コーディング規約

### 命名規則
- 変数名・関数名: `camelCase` (JS/TS) / `snake_case` (Python)
- クラス名: `PascalCase`
- 定数: `UPPER_SNAKE_CASE`
- ブール値: `is_`, `has_`, `can_` などの接頭辞

### コメント
- 複雑なロジックには必ずコメントを追加（日本語）
- TODO: `# TODO(日付): 説明`

## Git ワークフロー

### コミットメッセージ
Conventional Commits 準拠:
```
<type>: <日本語での説明>

- 詳細1
- 詳細2
```

**type**: `feat` / `fix` / `docs` / `refactor` / `test` / `style` / `chore` / `perf`

### ブランチ命名
- `feature/<機能名>` / `fix/<バグ名>` / `refactor/<対象>`

## テスト

### テスト規約
- AAA パターン（Arrange / Act / Assert）で記述
- 振る舞いベース（内部実装ではなく外部振る舞いをテスト）
- テストは独立・冪等に保つ
- カバレッジ目標: 新規コードは80%以上

## セキュリティ

- API キーや認証情報は環境変数で管理
- `.env` ファイルは `.gitignore` に含める
- 外部入力は必ずバリデーション
- ユーザー入力をクエリ文字列に直接連結しない

## ルール参照

作業開始時に以下のルールファイルを読んでください：

- `.codex/instructions/coding-style.md` — コーディングスタイル規約
- `.codex/instructions/git-workflow.md` — Git ワークフロー規約
- `.codex/instructions/security.md` — セキュリティ規約
- `.codex/instructions/testing.md` — テスト規約

## MCP ツール活用指針

### serena（シンボリック操作）
- コードの構造理解には `get_symbols_overview` → `find_symbol` の順で使用
- シンボル単位の編集には `replace_symbol_body` を優先
- 参照の追跡には `find_referencing_symbols` を使用

### context7（ドキュメント参照）
- ライブラリの使い方が不明な場合に `resolve-library-id` → `query-docs` で確認
- 公式ドキュメントの最新情報を取得

### filesystem（ファイル操作）
- 非コードファイル（設定、ドキュメント等）の読み書きに使用
- ディレクトリ構造の確認に使用

### playwright（ブラウザ操作）
- Web アプリケーションのテスト・デバッグに使用
- スクリーンショットの取得やフォーム操作に活用

## Agent Skills

`.agents/skills/` に共通スキル定義があります。`/prompts:skill <スキル名>` で呼び出せます。

| スキル名 | 説明 |
|---------|------|
| `api-design` | REST API の設計ベストプラクティスに従って API を設計・実装 |
| `code-review` | 構造化されたコードレビューを実施 |
| `debug-systematically` | 体系的なデバッグ手法で問題を特定・解決 |
| `documentation-first` | ドキュメント駆動開発で仕様を先に作成 |
| `git-workflow` | Git のベストプラクティスに従った操作 |
| `refactor-safely` | テストで保護された安全なリファクタリング |
| `search-first` | コードを書く前に既存パターンを調査 |
| `security-review` | OWASP Top 10 を中心としたセキュリティレビュー |
| `tdd-workflow` | TDD の Red-Green-Refactor サイクルで実装 |
| `verification-loop` | ビルド・テスト・lint の検証サイクルを実行 |

## カスタムプロンプト一覧

`.codex/prompts/` に以下のプロンプトが利用可能です：

### 基本コマンド
| プロンプト | 説明 |
|-----------|------|
| `plan` | 実装計画の作成 |
| `build-fix` | ビルドエラーの修正 |
| `review` | コードレビューの実施 |
| `refactor` | リファクタリングの実施 |
| `test` | テストの生成 |
| `code-gen` | コードの自動生成 |
| `docs` | ドキュメントの生成 |
| `checkpoint` | WIP コミットの作成 |
| `tdd` | TDD サイクルの実行 |
| `test-coverage` | テストカバレッジの分析 |
| `yfinance` | 株価情報の取得 |

### エージェントプロンプト
| プロンプト | 説明 |
|-----------|------|
| `agent-architect` | 設計・アーキテクチャレビュー |
| `agent-docs-writer` | ドキュメント作成 |
| `agent-security` | セキュリティレビュー |
| `agent-test-gen` | テスト生成 |

### スキル統合
| プロンプト | 説明 |
|-----------|------|
| `skill` | 汎用スキル呼び出し |

## 参考資料

<!-- プロジェクトに応じて適宜変更してください -->
- プロジェクトドキュメント: `docs/`
- ルールファイル: `.codex/instructions/`
- スキル定義: `.agents/skills/`
