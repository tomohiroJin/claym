# Claym 開発コンテナ README

Claym プロジェクトでは、AI エージェント（Claude Code / Codex CLI / Gemini CLI）をすぐに利用できる VS Code Dev Container を提供しています。Debian 12 (bookworm) をベースに、主要な MCP サーバーとモダンな CLI ツールをあらかじめセットアップ済みです。本書では現在のコンテナが備える機能と使い方をまとめます。

## 目次

1. [コンテナ概要](#1-コンテナ概要)
2. [含まれる主なコンポーネント](#2-含まれる主なコンポーネント)
3. [Dev Container の自動処理](#3-dev-container-の自動処理と-vs-code-設定)
4. [セットアップと利用手順](#4-セットアップと利用手順)
5. [カスタマイズのヒント](#5-カスタマイズのヒント)
6. [トラブルシューティング](#6-トラブルシューティング)
7. [既知の制約と今後の展望](#7-既知の制約と今後の展望)
8. [参考](#8-参考)

## 1. コンテナ概要

- **ベース OS**: Debian 12 (bookworm)（作業ディレクトリは `/workspaces/claym`）
- **既定ユーザー**: `root`（sudo 権限あり） / シェル: Oh My Zsh
- **目的**: AI 向け CLI と MCP サーバーを事前導入し、チャット開始までの初期設定を数分で完了させる
- **利用想定**: VS Code Dev Containers 拡張での再現性ある開発、エージェント動作検証、MCP ベースの自動化

## 2. 含まれる主なコンポーネント

### 2.1 システムと言語環境

- Node.js 20 系（npm は最新化済み）
- Python 3 系（pip / venv / dev ヘッダ）
- uv（Python プロジェクトの高速ランタイム）
- Git / Git LFS / curl / wget / jq など基本ツール
- **モダン CLI**: ripgrep, fd, bat, fzf, tree, zoxide, eza, tldr, git-delta, btop, hyperfine, ncdu, cloc
- フォントと X 関連ライブラリを追加し、Playwright/Chromium と ImageSorcery に対応

### 2.1.1 インストール済みツールの概要

コンテナにはデータ分析・ログ解析・ネットワーク診断など、業務でよく使う CLI とライブラリがまとまって導入されています。詳細な一覧は [docs/container-tooling.md](docs/container-tooling.md) にカテゴリ別の表としてまとめています。ここでは代表的なカテゴリのみ挙げます。

- **データ分析**: pandas / csvkit / Jupyter
- **ログ解析**: GoAccess / lnav / yq
- **Web・API 連携**: HTTPie / requests / BeautifulSoup4
- **画像・動画処理**: ImageMagick / FFmpeg / libwebp
- **ネットワーク診断**: ping / dig / traceroute / mtr
- **Git/GitHub 補助**: gh / git-extras / tig

### 2.2 プリインストール済み AI CLI

Claude Code / Codex CLI / Gemini CLI の 3 種類を最初から利用できます。詳細な説明と代表コマンドは [docs/container-tooling.md](docs/container-tooling.md#プリインストール済み-ai-cli) を参照してください。

| CLI | インストール場所 | コマンド例 |
|-----|-----------------|-----------|
| Claude Code | `/usr/bin/claude` | `claude --version` |
| Codex CLI | `/usr/bin/codex` | `codex --help` |
| Gemini CLI | `/usr/bin/gemini` | `gemini --help` |

### 2.3 バンドル済み MCP サーバー

Serena・Playwright・markitdown など主要な MCP サーバーを `post-create-setup.sh` で自動登録します。対応 CLI や起動例は [docs/container-tooling.md](docs/container-tooling.md#バンドル済み-mcp-サーバー) にまとめています。

**主要MCPサーバー一覧**:
- **Serena**: コードベース解析・編集 (uv経由)
- **Filesystem**: ファイル操作 (npx経由)
- **Playwright**: ブラウザ自動化 (npx経由)
- **Context7**: ドキュメント検索 (npm global)
- **markitdown**: ドキュメント変換 (pip経由)
- **imagesorcery**: 画像処理 (pip経由)
- **GitHub**: GitHub API統合 (uvx経由、`GITHUB_TOKEN`必須)
- **Firecrawl**: Webスクレイピング (npm global、`FIRECRAWL_API_KEY`必須)

> `GITHUB_TOKEN` / `FIRECRAWL_API_KEY` が未設定の場合は登録をスキップし、警告だけ表示します。

## 3. Dev Container の自動処理と VS Code 設定

### 3.1 ポート転送

| ポート | 用途 | 動作 |
|-------|------|------|
| 24282 | Serena MCP dashboard | silent |
| 9323 | Playwright MCP UI | 自動でブラウザを開く |
| 1455 | codex-oauth | HTTP |

### 3.2 コンテナ起動パラメータ

- 追加権限: `--cap-add=SYS_ADMIN`, `--security-opt=seccomp=unconfined`, `--shm-size=1g`
- これらはPlaywrightのブラウザ自動化に必要な設定です

### 3.3 環境変数の伝搬

ホスト側の以下の環境変数がコンテナへ自動的に伝搬されます（`remoteEnv`設定）:

- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `GEMINI_API_KEY`
- `GITHUB_TOKEN`
- `FIRECRAWL_API_KEY`

### 3.4 自動実行コマンド

#### postCreateCommand（初回作成時のみ）

1. `GITHUB_TOKEN`が設定されている場合、`gh auth login`を実行
2. ワークスペースを `git safe.directory` に登録
3. `/usr/local/bin/post-create-setup.sh` を実行してMCP登録
4. `scripts/setup/init-ai-configs.sh` を実行してAI設定を初期化

#### postStartCommand（起動毎）

- `.devcontainer/post-start.sh` を実行
- ワークスペースや imagesorcery ログの権限設定
- Serena 用ディレクトリの所有者変更

### 3.5 VS Code 拡張機能

v0.2.0 で大幅に拡充された拡張機能セット。詳細は [docs/vscode-extensions.md](docs/vscode-extensions.md) を参照してください。

**主なカテゴリ**:
- AI アシスト: Claude Code, ChatGPT
- Git/GitHub: GitLens, Pull Request, GitHub Actions, Git Blame
- Markdown: All in One, Preview Enhanced, Mermaid
- 品質・整形: Code Spell Checker, ESLint, Prettier, Python, Pylint, Black
- HTTP/API: REST Client, OpenAPI
- データ視覚: Rainbow CSV, Log File Highlighter
- コンフィグ: ShellCheck, Shell Format, Even Better TOML

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
# AI CLIのバージョン確認
claude --version
codex --help
gemini --help

# MCP登録状況の確認
claude mcp list

# 環境ヘルスチェック
bash scripts/health/check-environment.sh
```

必要に応じて `which` で CLI のパスを確認してください。

### 4.4 API キーの設定

#### 方法1: ホスト側の環境変数（推奨）

```bash
# ホスト側で設定
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="..."
export GITHUB_TOKEN="ghp_..."
export FIRECRAWL_API_KEY="fc-..."
```

設定後、コンテナを再接続すると自動的に伝搬されます。

#### 方法2: devcontainer.local.json

```json
{
  "remoteEnv": {
    "ANTHROPIC_API_KEY": "sk-ant-...",
    "OPENAI_API_KEY": "sk-..."
  }
}
```

`devcontainer.local.json` は `.gitignore` に含まれているため、安全です。

#### 方法3: VS Code Secrets

VS Code の Secrets 機能でも設定可能です（フォールバック）。

### 4.5 GitHub CLI 認証

`GITHUB_TOKEN` が環境変数に設定されている場合、コンテナ作成時に自動的に `gh auth login` が実行されます。トークンが無い場合でもコンテナは正常に起動します。

### 4.6 環境ヘルスチェック

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

### 5.1 MCPサーバーの調整

- **Filesystem MCP のアクセス範囲**: `post-create-setup.sh` 内の `$ROOT` を変更
- **Serena の設定**: `--context` や `--project` オプションを同スクリプトで変更可能
- **追加のMCPサーバー**: `post-create-setup.sh` にコマンドを追記

### 5.2 AI設定の自動セットアップ

コンテナには AI CLI（Claude Code / Codex CLI / Gemini CLI）向けの設定を自動生成するスクリプトが含まれています。

```bash
# AI設定の自動セットアップ（手動実行の場合）
bash scripts/setup/init-ai-configs.sh
```

このスクリプトは以下を実行します：
- `.claude/`, `~/.codex/`, `.gemini/` ディレクトリの作成
- 各 AI CLI 向けの設定ファイルテンプレートの生成
- `.gitignore` への自動追加（ローカル設定ファイルをバージョン管理から除外）

**生成される設定ファイル**:

| AI CLI | 設定ファイル | 場所 | 説明 |
|--------|------------|------|------|
| Claude Code | `settings.local.json` | `.claude/` | 権限設定 |
| Claude Code | `CLAUDE.md` | `.claude/` | カスタム指示（日本語設定含む） |
| Codex CLI | `config.toml` | `~/.codex/` | モデル設定・MCP登録 |
| GEMINI | `settings.json` | `.gemini/` | UI設定・MCP登録 |
| GEMINI | `GEMINI.md` | `.gemini/` | カスタム指示（日本語設定含む） |

**注意**: これらの設定ファイルはローカル環境専用です。`.gitignore` で除外されているため、個人の API キーや権限設定が誤ってコミットされる心配はありません。

**カスタマイズ方法**:
- Claude Code の権限調整: `.claude/settings.local.json` を編集
- Claude Code の日本語対応: `.claude/CLAUDE.md` を編集
- Codex CLI のモデル選択: `~/.codex/config.toml` を編集
- GEMINI の設定調整: `.gemini/settings.json` を編集
- GEMINI の日本語対応: `.gemini/GEMINI.md` を編集
- GEMINI のコンテキスト確認: `/memory show` コマンドを実行

**テンプレートの確認**:
設定テンプレートは `templates/` ディレクトリに格納されています。詳細は `templates/README.md` を参照してください。

### 5.3 devcontainer.local.json の活用

個人固有の設定は `devcontainer.local.json` で管理します（`.gitignore`済み）。

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,consistency=cached"
  ],
  "remoteEnv": {
    "MY_SECRET_KEY": "${localEnv:MY_SECRET_KEY}"
  }
}
```

### 5.4 追加ツールのインストール

`Dockerfile` に追記して、Dev Container の **Rebuild Container** を実行してください。

### 5.5 local ディレクトリの活用

`local/` ディレクトリは、個人的な開発環境や実験的なコンテンツを保存するための専用スペースです。このディレクトリはメインリポジトリから除外されており、別の Git リポジトリとして独立して管理できます。

#### 用途
- 個人的な設定ファイルやスクリプト
- 実験的なコード・プロトタイプ
- プロジェクト固有のメモやドキュメント
- ローカル環境でのみ必要なツールやユーティリティ

#### セットアップ
```bash
cd local
git init
git remote add origin <your-remote-url>
git add .
git commit -m "Initial commit for local development"
git push -u origin main
```

詳細な使用方法については `local/README.md` を参照してください。

### 5.6 v0.2.0 追加仕様の運用Tips

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

### 6.1 CLI が見つからない

```bash
# npmパッケージの確認
npm list -g --depth=0

# Pythonパッケージの確認
${VIRTUAL_ENV:-/opt/mcp-venv}/bin/pip list

# 再インストール（例）
npm install -g @anthropic-ai/claude-code
${VIRTUAL_ENV:-/opt/mcp-venv}/bin/pip install markitdown-mcp
```

### 6.2 Playwright の起動失敗

```bash
# ブラウザの再インストール
npx playwright install chromium --with-deps

# コンテナ起動パラメータの確認（--shm-size など）
```

### 6.3 Serena が起動しない

```bash
# uvのバージョン確認
uv --version

# /opt/serenaの存在確認
ls -la /opt/serena

# 手動起動テスト
uv run --directory /opt/serena serena start-mcp-server --project $PWD
```

### 6.4 GitHub / Firecrawl MCP が見当たらない

対応する API キーを環境変数に設定した後、`post-create-setup.sh` を再実行してください。

```bash
export GITHUB_TOKEN="ghp_..."
export FIRECRAWL_API_KEY="fc-..."
bash /usr/local/bin/post-create-setup.sh
```

### 6.5 権限エラー

```bash
# ワークスペースの所有者変更
sudo chown -R vscode:vscode ${containerWorkspaceFolder}

# コンテナの再起動
```

### 6.6 AI設定が生成されない

```bash
# 手動で再実行
bash /workspaces/claym/scripts/setup/init-ai-configs.sh

# テンプレートの存在確認
ls -la /workspaces/claym/templates/
```

## 7. 既知の制約と今後の展望

### 7.1 既知の制約

- Dockerfile は最新安定版を取得する構成（`@latest`）のため、上流更新で挙動が変わる可能性があります。安定運用が必要な場合はバージョン固定を検討してください
- Codex / Gemini CLI の MCP API は仕様変更が発生しやすいため、挙動に差異を感じたら `post-create-setup.sh` のコマンドを確認してください
- v0.2.0 で追加されたライブラリ・ツールは、ビジネス職のデータ分析や市場調査、レポート作成を支援する目的で選定されています。より高度な分析や特殊なツールが必要な場合は、Dockerfileに追記してリビルドしてください

### 7.2 今後の展望

- AI設定テンプレートの充実
- プロンプトライブラリの拡張
- MCPサーバーの追加と最適化
- ドキュメントの多言語対応

## 8. 参考

### 8.1 スクリプト

- `post-create-setup.sh`: MCP 登録ロジックとヘルパー呼び出しの中心
- `scripts/setup/init-ai-configs.sh`: AI設定の自動セットアップ
- `.devcontainer/scripts/helpers/`: ログ出力と CLI 検出ヘルパ

### 8.2 設定ディレクトリ

- `.claude/`: Claude Code の設定とログ（`.gitignore` 済み）
- `~/.codex/`: Codex CLI の設定（`.gitignore` 済み）
- `.gemini/`: GEMINI の設定（`.gitignore` 済み）
- `.serena/`: Serena のログ（`.gitignore` 済み）

### 8.3 ドキュメント

- `docs/container-tooling.md`: インストール済みツールの詳細
- `docs/vscode-extensions.md`: VS Code拡張機能の詳細
- `templates/README.md`: AI設定テンプレートの詳細
- `scripts/health/README.md`: ヘルスチェックの詳細

### 8.4 再セットアップ

必要に応じて以下のコマンドで各種設定をリセットできます：

```bash
# MCP登録のリセット
bash /usr/local/bin/post-create-setup.sh

# AI設定のリセット
bash /workspaces/claym/scripts/setup/init-ai-configs.sh
```

コンテナ構成を変更した場合は **Dev Containers: Rebuild Container** を実行して設定を反映してください。

---

**バージョン**: v0.2.0+
**最終更新**: 2025-10-19
**ブランチ**: feature/vscode-extensions-defaults
