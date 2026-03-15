# Codex CLI カスタムプロンプト

このディレクトリには、Codex CLI で利用できるカスタムプロンプトのテンプレートを保存します。

## 概要

- プロンプトは Markdown ファイルとして定義します。
- `/prompts:<プロンプト名> 引数` の形式で呼び出せます。
- 公式テンプレート（`templates/.codex/prompts/`）をベースに、`templates-local/.codex/prompts/` で上書きできます。

## 提供プロンプト

### 基本コマンド

#### `/prompts:plan` — 実装計画

- 要件を分析し、影響範囲の特定・タスク分解を含む実装計画を作成します。
- 詳細: [plan.md](./plan.md)

#### `/prompts:build-fix` — ビルドエラー修正

- ビルドエラーや型エラーを解析し、原因特定から修正までを実行します。
- 詳細: [build-fix.md](./build-fix.md)

#### `/prompts:review` — コードレビュー

- セキュリティ、パフォーマンス、コード品質の観点でレビューを実施します。
- 詳細: [review.md](./review.md)

#### `/prompts:refactor` — リファクタリング

- コードの複雑度を分析し、SOLID 原則に基づいた改善を実行します。
- 詳細: [refactor.md](./refactor.md)

#### `/prompts:test` — テスト生成

- テスト対象を分析し、AAA パターンでテストを生成します。
- 詳細: [test.md](./test.md)

#### `/prompts:code-gen` — コード自動生成

- プロジェクトのパターンに合わせてコードを自動生成します。
- 詳細: [code-gen.md](./code-gen.md)

#### `/prompts:docs` — ドキュメント生成

- コードベースから README、API ドキュメント等を自動生成します。
- 詳細: [docs.md](./docs.md)

#### `/prompts:checkpoint` — WIP コミット作成

- 現在の作業状態を確認し、WIP コミットを作成します。
- 詳細: [checkpoint.md](./checkpoint.md)

#### `/prompts:tdd` — TDD サイクル

- Red → Green → Refactor の対話的 TDD サイクルを実行します。
- 詳細: [tdd.md](./tdd.md)

#### `/prompts:test-coverage` — カバレッジ分析

- テストカバレッジを分析し、優先的にテストを追加すべき箇所を提案します。
- 詳細: [test-coverage.md](./test-coverage.md)

#### `/prompts:yfinance` — 株価情報の取得

- yfinance を利用して米国株の最新情報を取得・要約します。
- 詳細: [yfinance.md](./yfinance.md)

### エージェントプロンプト

#### `/prompts:agent-architect` — 設計・アーキテクチャレビュー

- ソフトウェアアーキテクトとして設計をレビュー・提案します。
- 詳細: [agent-architect.md](./agent-architect.md)

#### `/prompts:agent-docs-writer` — ドキュメント作成専門家

- 技術ドキュメント作成の専門家としてドキュメントを生成します。
- 詳細: [agent-docs-writer.md](./agent-docs-writer.md)

#### `/prompts:agent-security` — セキュリティレビュー

- OWASP Top 10 を基準にセキュリティ脆弱性を検出・修正提案します。
- 詳細: [agent-security.md](./agent-security.md)

#### `/prompts:agent-test-gen` — テスト生成専門家

- テスト自動化の専門家としてテストコードを生成します。
- 詳細: [agent-test-gen.md](./agent-test-gen.md)

### スキル統合

#### `/prompts:skill` — 汎用スキル呼び出し

- `.agents/skills/` のスキル定義を読み込んで手順に従います。
- 詳細: [skill.md](./skill.md)

## カスタマイズ方法

### 1. ローカルテンプレートを作成

```bash
bash scripts/setup/copy-template-to-local.sh codex-prompt plan.md
```

### 2. コンテンツを編集

`templates-local/.codex/prompts/<プロンプト名>.md` を編集して、プロジェクトルールに合わせて調整します。

### 3. 設定を再生成

```bash
bash scripts/setup/reinit-ai-configs.sh
```

- 公式テンプレート → ローカルテンプレートの順にコピーされるため、同名ファイルはローカル版で上書きされます。
- 新規プロンプトを追加した場合も自動で取り込まれます。

## ベストプラクティス

- 手順を番号付きで記述し、Codex がステップバイステップで処理できるようにする
- 出力フォーマットを具体的に指示する
- `$1` でユーザー引数を受け取れるようにする

## 関連ドキュメント

- [templates/README.md](../../README.md) — テンプレート全体のガイド
- [scripts/setup/copy-template-to-local.sh](../../../scripts/setup/copy-template-to-local.sh) — ローカルテンプレートへのコピー
- [scripts/setup/reinit-ai-configs.sh](../../../scripts/setup/reinit-ai-configs.sh) — 設定再生成スクリプト
