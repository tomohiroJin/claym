# Claym 開発コンテナの VS Code 拡張一覧

Dev Container 立ち上げ時に自動インストールされる拡張機能を、カテゴリ別にまとめました。名称・概要・代表的な活用例を確認して、ワークフローに組み込んでください。

## AI アシスト

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Claude Code (`anthropic.claude-code`) | Claude ベースのコードアシスタント | コマンドパレットで `Claude: Start Chat` を実行|
| ChatGPT (`openai.chatgpt`) | OpenAI ChatGPT 連携拡張 | サイドバーから質問し、コード提案を取得 |

## Git / GitHub

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| GitLens (`eamodio.gitlens`) | コード変更履歴・ blame の可視化 | エディタ上で行履歴を確認 |
| GitHub Pull Requests (`github.vscode-pull-request-github`) | PR レビューと Issue 連携 | `GitHub` ビューから PR チェックアウト |
| GitHub Actions (`GitHub.vscode-github-actions`) | Actions ワークフローの編集支援 | `.github/workflows/` を開いてスキーマ補完を利用 |
| Git Blame (`waderyan.gitblame`) | ステータスバーで即座に blame 表示 | 現在行の最終コミッターを確認 |

## ドキュメント・Markdown

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Markdown All in One (`yzhang.markdown-all-in-one`) | Markdown 編集支援とショートカット集 | `Ctrl+Shift+V` でプレビュー |
| Markdown Preview Enhanced (`shd101wyy.markdown-preview-enhanced`) | LaTeX/Diagram 対応の拡張プレビュー | `Markdown: Open Preview (Enhanced)` |
| Mermaid Support (`bierner.markdown-mermaid`) | Mermaid 図の補完とプレビュー | コードブロックに `mermaid` を記述し表示 |
| Code Spell Checker (`streetsidesoftware.code-spell-checker`) | 英語スペルチェック | 波線の提案を Quick Fix で修正 |

## Python / JavaScript 品質

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Python (`ms-python.python`) | Python 全般の言語サポート | `.py` ファイルで IntelliSense を利用 |
| Pylint (`ms-python.pylint`) | Python 静的解析 | 保存時に linter 警告を確認 |
| Black Formatter (`ms-python.black-formatter`) | Black による整形 | `Format Document` で Black を実行 |
| ESLint (`dbaeumer.vscode-eslint`) | JavaScript/TypeScript Lint | `.js` で自動フィクスを実行 |
| Prettier (`esbenp.prettier-vscode`) | JS/Markdown 等の整形 | `Format Document With... Prettier` |

## テスト・自動化

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Playwright Test (`ms-playwright.playwright`) | Playwright の録画・テスト管理 | `Playwright: Install Browsers` で環境同期 |

## コラボレーション

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Live Share (`ms-vsliveshare.vsliveshare`) | リアルタイム共同編集 | `Live Share: Start Collaboration Session` |

## HTTP / OpenAPI / YAML

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| REST Client (`humao.rest-client`) | `.http` から HTTP リクエスト送信 | `Send Request` ボタンで API をテスト |
| OpenAPI (`42Crunch.vscode-openapi`) | OpenAPI/Swagger の検証・補完 | `openapi.yaml` を開きエラーを確認 |
| YAML (`redhat.vscode-yaml`) | スキーマ検証付き YAML 編集 | GitHub Actions workflow で schema 提示 |

## ログ・データ可視化

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| Rainbow CSV (`mechatroner.rainbow-csv`) | CSV/TSV の列を自動で色分け | CSV を開きクイックフィルタを実行 |
| Log File Highlighter (`emilast.LogFileHighlighter`) | ログのレベル別ハイライト | `.log` ファイルの強調表示 |

## シェル / 設定ファイル

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| ShellCheck (`timonwong.shellcheck`) | ShellScript 静的解析 | Bash スクリプトの警告を修正 |
| shell-format (`foxundermoon.shell-format`) | sh/bash フォーマッタ | `Format Document` で整形 |
| Even Better TOML (`tamasfe.even-better-toml`) | TOML の補完と検証 | `devcontainer.json` から `settings.json` を編集 |

## ワークスペース整形

| 拡張機能 (ID) | 概要 | 活用例 |
| --- | --- | --- |
| EditorConfig (`EditorConfig.EditorConfig`) | ファイルフォーマットルールの統一 | `.editorconfig` に従って自動整形 |

> いずれの拡張も Dev Container 再構築時に自動で揃います。必要に応じて `devcontainer.json` の `customizations.vscode.extensions` から追加・削除してください。
