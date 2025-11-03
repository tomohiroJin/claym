# Gemini CLI カスタムコマンド

このディレクトリには、Gemini CLI で利用できるカスタムコマンドのテンプレートを保存します。

## 概要

- コマンドは Markdown ファイルとして定義します。
- `/prompts:<コマンド名> 引数` の形式で呼び出せます。
- 公式テンプレート（`templates/.gemini/commands/`）をベースに、`templates-local/.gemini/commands/` で上書きできます。

## 提供コマンド

### `/prompts:yfinance` — 株価情報の取得

- yfinance を利用して米国株の最新情報を取得・要約します。
- 詳細手順は [yfinance.md](./yfinance.md) を参照してください。

## カスタマイズ方法

### 1. ローカルテンプレートを作成

```bash
bash scripts/setup/copy-template-to-local.sh gemini-command yfinance.md
```

### 2. コンテンツを編集

`templates-local/.gemini/commands/<コマンド名>.md` を編集して、プロジェクトルールに合わせて調整します。

### 3. 設定を再生成

```bash
bash scripts/setup/reinit-ai-configs.sh
```

- 公式テンプレート → ローカルテンプレートの順にコピーされるため、同名ファイルはローカル版で上書きされます。
- 新規コマンドを追加した場合も自動で取り込まれます。

## ベストプラクティス

- 手順を番号付きで記述し、Gemini がステップバイステップで処理できるようにする
- 必要なツール（Web 検索や API 呼び出しなど）を明示する
- 情報源の明示や注意書きなど、出力フォーマットを具体的に指示する

## 関連ドキュメント

- [templates/README.md](../../README.md) — テンプレート全体のガイド
- [scripts/setup/copy-template-to-local.sh](../../../scripts/setup/copy-template-to-local.sh) — ローカルテンプレートへのコピー
- [scripts/setup/reinit-ai-configs.sh](../../../scripts/setup/reinit-ai-configs.sh) — 設定再生成スクリプト
