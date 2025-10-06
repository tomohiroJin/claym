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

### 2.1.1 v0.2.0 で追加されたライブラリ・ツール

#### 数値・表データ分析
- **Pandas**（Python）: データフレーム操作の定番
- **csvkit**（CLI + Python）: CSV操作用コマンドラインツール群
- **IPython / Jupyter**（Python）: 対話型実行環境とノートブック

#### ログ解析・テキスト解析
- **GoAccess**（CLI）: リアルタイムWebアクセスログ解析・可視化ツール
- **yq**（npm）: YAMLデータのコマンドライン処理
- **lnav**（CLI）: SQLクエリ可能な汎用ログビューワ

#### Webデータ取得・API連携
- **HTTPie**（CLI）: 人間に読みやすいHTTPクライアント
- **requests / httpx**（Python）: Web API用Pythonライブラリ
- **BeautifulSoup4・lxml**（Python）: HTMLスクレイピング用ライブラリ

#### 市場・金融データ分析
- **yfinance**（Python）: Yahoo! Finance APIラッパー
- **pandas_datareader**（Python）: 経済データ取得ライブラリ
- **qtrn**（npm）: 株価・オプション価格を表示する金融市場CLI

#### レポート・プレゼンテーション生成
- **Pandoc**（CLI）: マークダウンからPDF/HTML/Slidesへの変換
- **Landslide**（Python）: MarkdownからHTMLスライド生成
- **Jinja2**（Python）: Pythonテンプレートエンジン

#### 画像・動画処理
- **ImageMagick**（CLI）: 画像のリサイズ・変換・フィルタ処理
- **FFmpeg**（CLI）: 動画・音声の変換・抽出
- **libwebp**（CLI）: WebPエンコード・デコード

#### 現代的CLIツールと環境補完
- **git-extras**（CLI）: Git操作支援ツール
- **tig**（CLI）: Gitリポジトリブラウザ
- **gh CLI**（CLI）: GitHub公式コマンドラインツール
- **tmux**（CLI）: ターミナルマルチプレクサ（オプション）

### 2.1.2 v0.2.0 追加仕様で追加されたツール

#### Git/GitHub強化
- **gh**（CLI）: GitHub CLI（公式APTリポジトリから導入、自動認証対応）
- **git-delta**（CLI）: git diffを見やすく表示（シンタックスハイライト強化）

#### ネットワーク疎通・診断
- **iputils-ping**（CLI）: ICMP疎通確認
- **bind9-dnsutils**（CLI）: dig等のDNSツール
- **traceroute**（CLI）: 経路追跡
- **mtr-tiny**（CLI）: ping + tracerouteの連続計測
- **netcat-openbsd**（CLI）: ポート疎通・簡易サーバ
- **socat**（CLI）: ソケット多機能ツール（プロキシ・ポートフォワード等）
- **lsof**（CLI）: プロセスが開くファイル/ポート一覧
- **whois**（CLI）: ドメイン情報照会

#### 構造化データ/テキスト整形
- **miller**（CLI）: CSV/TSV/JSONLの整形・集計
- **moreutils**（CLI）: pee, ts, sponge等の小粒ツール群

#### セキュリティ/SSL
- **openssl**（CLI）: s_clientで証明書/ハンドシェイク確認（既存システムに含まれるが明示的に追加）

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

### 3.1 v0.2.0 追加仕様2で導入されたVS Code拡張

#### Git/GitHub 運用・レビュー
- **GitHub.vscode-github-actions**: GitHub Actions YAML補完・定義支援
- **waderyan.gitblame**: 行単位のblame表示（ステータスバー）

#### HTTP / API / OpenAPI
- **humao.rest-client**: エディタ内でHTTPリクエスト送信・レスポンス保存
- **42Crunch.vscode-openapi**: OpenAPI/Swaggerスキーマ検証・補完
- **redhat.vscode-yaml**: YAMLスキーマ検証（GitHub Actions、OpenAPI対応）

#### ログ・データ視覚支援
- **mechatroner.rainbow-csv**: CSV/TSVの列ごとの色分け・クイックフィルタ
- **emilast.LogFileHighlighter**: ログファイルのタイムスタンプ・レベル色付け

#### 文章作成・レポーティング
- **bierner.markdown-mermaid**: Mermaid図の記述補助

#### シェル / コンフィグ編集の品質
- **timonwong.shellcheck**: シェルスクリプトの静的解析
- **foxundermoon.shell-format**: sh/bashのフォーマッタ
- **tamasfe.even-better-toml**: TOML補完・検証

#### コンテナ・体裁
- **EditorConfig.EditorConfig**: 体裁統一（スペース/インデント/改行コード）

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
- **GitHub CLI 認証**: `GITHUB_TOKEN` が環境変数に設定されている場合、コンテナ作成時に自動的に `gh auth login` が実行されます。トークンが無い場合でもコンテナは正常に起動します。

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

### 5.1 v0.2.0 追加仕様2の運用Tips

#### REST Clientの活用
- `.http` ファイルを作成して HTTP リクエストを記述
- `{{baseUrl}}` 変数を使用すると `devcontainer.json` の設定値が反映されます
- 例：`GET {{baseUrl}}/api/users`

#### OpenAPIの活用
- `openapi.yaml` を配置すると自動的にスキーマ検証が効きます
- REST Client でテスト → Pandoc/Markdown でレポート作成の流れがスムーズ

#### CSVログの一次確認
- Rainbow CSV でカラム色分け → `jq`/`miller` で整形 → レポートへ
- CSV ファイルを開くと自動的に色分けされます

#### GitHub Actions YAML
- `.github/workflows/` 配下のファイルで自動補完・検証が効きます
- スキーマエラーがあればエディタ上で即座に確認できます

## 6. トラブルシューティング
- **CLI が見つからない**: `npm list -g --depth=0` や `pipx list` でインストール状況を確認。必要なら `npm install -g @anthropic-ai/claude-code` などを再実行
- **Playwright の起動失敗**: `npx playwright install chromium --with-deps` を再度実行し、コンテナ起動パラメータ（`--shm-size` など）を確認
- **Serena が起動しない**: `uv --version` / `/opt/serena` の存在を確認し、`uv run --directory /opt/serena serena start-mcp-server --project $PWD` を手動実行
- **GitHub / Firecrawl MCP が見当たらない**: 対応する API キーを環境変数に設定した後、`post-create-setup.sh` を再実行
- **権限エラー**: `sudo chown -R vscode:vscode ${containerWorkspaceFolder}` を手動で実行し、必要に応じてコンテナを再起動

## 7. 既知の制約と今後の展望
- Dockerfile は最新安定版を取得する構成（`@latest`）のため、上流更新で挙動が変わる可能性があります。安定運用が必要な場合はバージョン固定を検討してください
- Codex / Gemini CLI の MCP API は仕様変更が発生しやすいため、挙動に差異を感じたら `post-create-setup.sh` のコマンドを確認してください
- v0.2.0 で追加されたライブラリ・ツールは、ビジネス職のデータ分析や市場調査、レポート作成を支援する目的で選定されています。より高度な分析や特殊なツールが必要な場合は、Dockerfileに追記してリビルドしてください
- v0.2.0 追加仕様では、Ubuntu 24.04のAPTで入るものを優先し、保守性を重視しています。CLI×AI前提のワークフローを想定し、GitHub業務のCLI完結、Web/ログ解析の初動高速化、ネットワーク調査のCLI完結を実現します

## 8. 参考
- `post-create-setup.sh`: MCP 登録ロジックとヘルパー呼び出しの中心
- `.devcontainer/scripts/helpers/`: ログ出力と CLI 検出ヘルパ
- `.claude/` と `.serena/`: それぞれのクライアント設定・ログ（`.gitignore` 済み）

必要に応じて `bash /usr/local/bin/post-create-setup.sh` を再実行すると MCP 登録をリセットできます。コンテナ構成を変更した場合は **Dev Containers: Rebuild Container** を実行して設定を反映してください。
