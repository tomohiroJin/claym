# Claym 開発コンテナ README

Claym プロジェクトでは、AI エージェント（Claude Code / Codex CLI / Gemini CLI）をすぐに利用できる VS Code Dev Container を提供しています。Ubuntu 24.04 をベースに、主要な MCP サーバーとモダンな CLI ツールをあらかじめセットアップ済みです。本書では現在のコンテナが備える機能と使い方をまとめます。

## 1. コンテナ概要
- ベース OS: Ubuntu 24.04 LTS（作業ディレクトリは `/workspaces/claym`）
- 既定ユーザー: `vscode`（sudo 権限あり） / シェル: Oh My Zsh
- 目的: AI 向け CLI と MCP サーバーを事前導入し、チャット開始までの初期設定を数分で完了させる
- 利用想定: VS Code Dev Containers 拡張での再現性ある開発、エージェント動作検証、MCP ベースの自動化

## 2. 含まれる主なコンポーネント
### 2.1 システムと言語環境
- Node.js 20 系（npm は最新化済み）
- Python 3 系（pip / venv / dev ヘッダ）
- uv（Python プロジェクトの高速ランタイム）
- Git / Git LFS / curl / wget / jq など基本ツール
- モダン CLI: ripgrep, fd, bat, fzf, zoxide, eza, tldr, tree
- フォントと X 関連ライブラリを追加し、Playwright/Chromium と ImageSorcery に対応

### 2.2 プリインストール済み AI CLI
| CLI | 起動コマンド | 主用途 | 備考 |
| --- | --- | --- | --- |
| Claude Code | `claude` | Anthropic の CLI クライアント | `claude` で対話開始 |
| Codex CLI | `codex` | OpenAI ベースの CLI | `codex` 単体で chat 開始 |
| Gemini CLI | `gemini` | Google Gemini 用 CLI | `gemini` で対話 |

### 2.3 バンドル済み MCP サーバー
`post-create-setup.sh` が利用可能な CLI すべてに対して MCP を冪等登録します。

| MCP 名 | 追加方法 | 登録対象 | 備考 |
| --- | --- | --- | --- |
| serena | `uv run --directory /opt/serena serena start-mcp-server --context ide-assistant --project $PWD` | Claude / Codex / Gemini | `/opt/serena` を git clone 済み |
| playwright | `npx @playwright/mcp@latest` | 同上 | Chromium を `npx playwright install` で事前取得 |
| markitdown | `markitdown-mcp` | 同上 | Markdown <-> HTML/URL 変換 |
| imagesorcery | `imagesorcery-mcp` | 同上 | 画像処理。`--post-install` 済み |
| filesystem | `npx -y @modelcontextprotocol/server-filesystem $PWD` | 同上 | ワークスペース限定アクセス |
| context7 (SSE) | `https://mcp.context7.com/sse` | Claude / Codex | SSE ベースの外部 MCP |
| mcp-github | `uvx mcp-github` | 同上 | `GITHUB_TOKEN` が必要 |
| firecrawl | `npx -y firecrawl-mcp` | 同上 | `FIRECRAWL_API_KEY` が必要 |

> `GITHUB_TOKEN` / `FIRECRAWL_API_KEY` が未設定の場合は登録をスキップし、警告だけ表示します。

## 3. Dev Container の自動処理と VS Code 設定
- Port forwarding: 24282 (Serena dashboard), 9323 (Playwright UI), 1455 (Codex OAuth 用)
- 追加権限: `--cap-add=SYS_ADMIN`, `--security-opt=seccomp=unconfined`, `--shm-size=1g`
- `remoteEnv`: ホスト側の `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY` / `GITHUB_TOKEN` / `FIRECRAWL_API_KEY` をコンテナへ伝搬
- `postCreateCommand`: ワークスペースを `git safe.directory` に登録した後、`/usr/local/bin/post-create-setup.sh` を実行して MCP を登録
- `postStartCommand`: ワークスペースと ImageSorcery ログの権限調整、Serena ディレクトリの所有者変更を実施
- VS Code 拡張: Claude Code, OpenAI, GitLens, Markdown ツール、Python LSP/formatter、Playwright 拡張などを自動導入

## 4. セットアップと利用手順
### 4.1 前提条件
- Docker（Desktop など）
- VS Code 本体 + Dev Containers 拡張
- 必要に応じて各種 API キー（Anthropic / OpenAI / Google / GitHub / Firecrawl）

### 4.2 初回起動
1. 本リポジトリを VS Code で開く
2. コマンドパレットから **Reopen in Container** を実行
3. ビルドと post-create 完了を待つ（Playwright のブラウザ取得で数分かかる場合あり）

### 4.3 動作確認
```bash
claude --version
codex --help
gemini --help
claude mcp list
```
必要に応じて `which` で CLI のパスを確認してください。

### 4.4 API キーの設定
- ホスト側で `export ANTHROPIC_API_KEY=...` のように環境変数を設定してからコンテナを再接続
- フォールバックとして VS Code Secrets でも設定可能
- `devcontainer.local.json` で Mount や `remoteEnv` を追加するとホスト固有設定を安全に共有できます（ `.gitignore` 済み）

### 4.5 環境ヘルスチェック
コンテナ起動直後やトラブルシューティング時は、ヘルスチェックを実施すると前提条件の崩れを素早く検知できます。

```bash
bash scripts/health/check-environment.sh         # フルチェック（既定）
bash scripts/health/check-environment.sh --quick # 主要項目のみ
bash scripts/health/check-environment.sh --json  # JSON サマリ出力
```

- クリティカルな検査失敗で終了コード 1、警告のみで 2、問題なしは 0 を返します。
- `--list-checks` で利用可能なチェック ID を表示し、`--skip <id>` で特定の検査を除外できます（例: `--skip serena-ready`）。
- チェック内容の詳細は `scripts/health/README.md` を参照してください。

## 5. カスタマイズのヒント
- Filesystem MCP のアクセス範囲は `post-create-setup.sh` 内の `$ROOT` を変更して調整
- Serena の `--context` や `--project` オプションも同スクリプトで変更可能
- `devcontainer.local.json` の `mounts` に SSH や Git 設定を追加して認証情報を共有
- 追加ツールが必要な場合は `Dockerfile` に追記し、Dev Container の Rebuild を実行

## 6. トラブルシューティング
- **CLI が見つからない**: `npm list -g --depth=0` や `pipx list` でインストール状況を確認。必要なら `npm install -g @anthropic-ai/claude-code` などを再実行
- **Playwright の起動失敗**: `npx playwright install chromium --with-deps` を再度実行し、コンテナ起動パラメータ（`--shm-size` など）を確認
- **Serena が起動しない**: `uv --version` / `/opt/serena` の存在を確認し、`uv run --directory /opt/serena serena start-mcp-server --project $PWD` を手動実行
- **GitHub / Firecrawl MCP が見当たらない**: 対応する API キーを環境変数に設定した後、`post-create-setup.sh` を再実行
- **権限エラー**: `sudo chown -R vscode:vscode ${containerWorkspaceFolder}` を手動で実行し、必要に応じてコンテナを再起動

## 7. 既知の制約と今後の展望
- Dockerfile は最新安定版を取得する構成（`@latest`）のため、上流更新で挙動が変わる可能性があります。安定運用が必要な場合はバージョン固定を検討してください
- 追加の Linux ツールやライブラリ（Step 2 以降のタスク）は未導入。用途に応じて拡張してください
- Codex / Gemini CLI の MCP API は仕様変更が発生しやすいため、挙動に差異を感じたら `post-create-setup.sh` のコマンドを確認してください

## 8. 参考
- `post-create-setup.sh`: MCP 登録ロジックとヘルパー呼び出しの中心
- `.devcontainer/scripts/helpers/`: ログ出力と CLI 検出ヘルパ
- `.claude/` と `.serena/`: それぞれのクライアント設定・ログ（`.gitignore` 済み）

必要に応じて `bash /usr/local/bin/post-create-setup.sh` を再実行すると MCP 登録をリセットできます。コンテナ構成を変更した場合は **Dev Containers: Rebuild Container** を実行して設定を反映してください。
