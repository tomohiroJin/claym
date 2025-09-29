# Claym 開発コンテナ README（エージェント向け）

このリポジトリは **Ubuntu 24.04 LTS** をベースに、次の目的で構成された VS Code Dev Container を提供します。

* **Step 1**（本リポジトリの範囲）
  Claude Code / Codex CLI / Gemini CLI をプリインストールし、**起動→認証→チャット開始** まで即実行。
* **Step 2**（将来拡張）
  よく使う **Linux CLI/ライブラリ** を追加し、AI が CLI 経由で作業しやすい環境を整備。
* **Step 3**（将来拡張）
  **MCP**（Model Context Protocol）サーバを導入し、ローカル資産や Web を AI から安全に利用。

---

## 1. 主要ファイル

* `Dockerfile`
  Ubuntu 24.04 LTS + Node.js 20 + Python、AI CLI（Claude / Codex / Gemini）と MCP 群（Playwright / Filesystem / MarkItDown / ImageSorcery / GitHub / Firecrawl / Serena）を導入。開発用 CLI（zsh / fzf / zoxide / ripgrep / bat / fd / eza / tldr）も含みます。
* `devcontainer.json`
  VS Code 用の Dev Container 設定。ポート転送、追加権限（Playwright 用）、拡張機能の自動導入、環境変数の受け渡し、**postCreateCommand** と **postStartCommand** を定義。serena MCP の自動起動にも対応。
* `post-create-setup.sh`
  コンテナ作成後に実行。**Claude Code** に各 MCP を**冪等に登録**します（存在する場合のみ、API キーがある場合のみ等）。
* `start-serena.sh`
  serena MCP サーバーを起動するためのヘルパースクリプト。postStartCommand から自動実行されます。
* `.claude/`
  Claude Code の設定ファイルディレクトリ。MCP サーバーの設定と許可された実行コマンドを管理。
* `.serena/`
  serena MCP サーバーの設定ディレクトリ。プロジェクト設定とログファイルを含む。
* `.gitignore`
  開発環境で生成される一時ファイル、ログ、設定ファイルを除外。Claude Code の local 設定も含む。

---

## 2. 前提条件（人/エージェント共通）

* Docker 実行環境（Docker Desktop 等）
* VS Code と **Dev Containers 拡張**（ホスト側）
* （任意）Web へのアクセス権（GitHub/Firecrawl/Context7 を使う場合）

---

## 3. 起動手順（最短）

1. このリポジトリを **VS Code** で開く
2. コマンドパレット → **“Reopen in Container”**
3. コンテナ起動後、自動で `post-create-setup.sh` が走り、MCP 登録を実施

> 初回は Playwright のブラウザ取得などで数分かかることがあります。

---

## 4. 認証（環境変数）

`devcontainer.json` は **ホストの環境変数をコンテナに伝搬** します。必要に応じ、ホスト側で以下を設定してください（VS Code Secrets でも可）。

* `ANTHROPIC_API_KEY`（Claude）
* `OPENAI_API_KEY`（OpenAI / Codex）
* `GEMINI_API_KEY`（Gemini）
* `GITHUB_TOKEN`（GitHub MCP を使う場合）
* `FIRECRAWL_API_KEY`（Firecrawl MCP を使う場合）

**反映手順（例）**
ホストのシェルで `export ANTHROPIC_API_KEY=...` 等 → VS Code を **Reopen in Container**。

### 4.1 devcontainer.local.json での Git 認証設定

共有の `devcontainer.json` では `mounts` を空にし、ホスト固有の Git 設定や資格情報は `devcontainer.local.json` で上書きします。このファイルは `.gitignore` 済みなのでマシンごとに自由に調整してください。

### 4.2 Claude Code 設定ファイル

`.claude/settings.local.json` は個別環境用の Claude Code 設定ファイルで、セキュリティ上の理由から `.gitignore` で除外されています。このファイルには MCP サーバーの許可設定や実行コマンドの権限設定が含まれます。

`devcontainer.local.json` のサンプル（SSH エージェント + HTTPS 資格情報）:

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,readonly",
    "source=${localEnv:HOME}/.git-credentials,target=/home/vscode/.git-credentials,type=bind,readonly",
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind",
    "source=${localEnv:SSH_AUTH_SOCK},target=/ssh-agent,type=bind"
  ],
  "remoteEnv": {
    "SSH_AUTH_SOCK": "/ssh-agent"
  },
  "postStartCommand": "sudo chown -R vscode:vscode ${containerWorkspaceFolder} || true; chmod 600 /home/vscode/.ssh/id_* 2>/dev/null || true"
}
```

> `remoteEnv` や `postStartCommand` はベース設定にマージされますが、配列（`mounts` など）は完全に置き換わります。追加で `runArgs` を編集する場合はベースの値もコピーしてから追記してください。設定後は VS Code で **Dev Containers: Rebuild Container** を実行すると反映されます。

---

## 5. 動作確認コマンド

### 5.1 AI CLI

```bash
claude --version
codex --help
gemini --help
```

チャット開始（例）:

```bash
claude chat
codex
gemini chat
```

### 5.2 MCP（Claude）

```bash
claude mcp list          # 登録済み MCP の確認
claude mcp remove <name> # 解除（必要時）
```

`post-create-setup.sh` は以下を追加します（API キーや依存があるものは条件付き）:

* `serena`（uv 経由で /opt/serena を起動、`--project $PWD`）
* `playwright`（`npx @playwright/mcp@latest`）
* `markitdown`（`markitdown-mcp`）
* `imagesorcery`（`imagesorcery-mcp`、post-install 済）
* `filesystem`（`npx @modelcontextprotocol/server-filesystem $PWD`、**ワークスペース限定**）
* `context7`（SSE: `https://mcp.context7.com/sse`）
* `github`（`GITHUB_TOKEN` がある場合のみ `uvx mcp-github`）
* `firecrawl`（`FIRECRAWL_API_KEY` がある場合のみ `npx firecrawl-mcp`）

---

## 6. エージェント向けチェックリスト

1. **Node / Python の確認**

   * `node -v`（期待値: v20 系）
   * `python3 --version`（3.10+）
2. **AI CLI の存在確認**

   * `which claude codex gemini`
3. **MCP の登録確認**

   * `claude mcp list` に上記 MCP が表示されるか
4. **ポート**

   * 24282（Serena ダッシュボード）: 転送済み（自動では開かない）
   * 9323（Playwright UI）: アクセス時にブラウザが開く設定
5. **権限**

   * コンテナが `--cap-add=SYS_ADMIN --security-opt=seccomp=unconfined --shm-size=1g` で起動しているか（`devcontainer.json` 参照）
6. **API キー**

   * 必要なキーが `echo $ENV_NAME` で参照できるか（未設定ならスキップ運用）

---

## 7. トラブルシューティング

* **`claude mcp add` で失敗/重複**
  冪等設計のため重複エラーは警告のみ。必要に応じ `claude mcp remove <name>` → `post-create-setup.sh` 再実行。
* **Playwright 関連エラー（ブラウザ/依存）**
  `npx playwright install chromium --with-deps` を再実行。コンテナ起動引数（shm/権限）も確認。
* **ImageSorcery でモデル未取得**
  `imagesorcery-mcp --post-install` を再実行。
* **Serena が起動しない / uv が無い**
  `uv` の存在を確認（`uv --version`）。必要なら再インストール。`/opt/serena` が存在するか確認。
* **キー未設定で GitHub/Firecrawl が使えない**
  ホスト側で環境変数を設定 → Dev Container を再接続。
* **ネットワーク/プロキシ**
  企業ネットワーク等では HTTP(S)\_PROXY の設定が必要な場合があります。

---

## 8. 代表的な運用タスク（エージェントが自動化しやすい形）

* **MCP 再登録**
  `bash /usr/local/bin/post-create-setup.sh`
* **MCP の一時停止/解除**
  `claude mcp remove <name>`
* **Filesystem MCP のアクセス範囲変更**
  `post-create-setup.sh` 内の `"$ROOT"` を別ディレクトリへ（例: `$ROOT/app`）
* **バージョン固定**
  `Dockerfile` の `@latest` を固定値へ置換 → 再ビルド
* **ログ収集**
  各コマンドを `--verbose`（あれば）で実行し、出力を保存

---

## 9. 今後の拡張ヒント

* **Step 2**: CLI/ライブラリの追加（`ffmpeg` / `imagemagick` / `git-lfs` の高度利用等）。
* **Step 3**: MCP の拡充・設定の最適化（自動承認ポリシー、参照パス制限、外部アクセス制御）。
* **他クライアント対応**: Codex / Gemini 側の MCP 登録仕様が安定したら、自動登録を `post-create-setup.sh` に追加。

---

## 10. ファイル管理とgitignore設定

プロジェクトには包括的な `.gitignore` ファイルが設定されており、以下のファイル・ディレクトリが自動的に除外されます：

* **Claude Code 設定**: `.claude/settings.local.json`（個人設定）
* **開発言語関連**: Node.js、Python の依存関係・ビルドファイル・仮想環境
* **IDE/エディタ**: VSCode、IntelliJ IDEA、vim/emacs の設定・一時ファイル
* **OS 自動生成**: macOS、Windows、Linux の各種システムファイル
* **ログファイル**: 各種 `*.log` ファイル、serena MCP ログディレクトリ
* **MCP サーバーデータ**: `.serena/data/`、`.serena/cache/` 等
* **環境変数・設定**: 各種 `.env` ファイル、データベースファイル

これにより、個人設定や実行時生成ファイルが誤ってコミットされることを防ぎます。

---

## 11. 連絡事項

* 重要な変更（キーや権限など）がある場合は **Docker 再ビルド** または **Reopen in Container** を実施してください。
* 既知の制約: Ubuntu 24.04 LTS での各パッケージは更新により挙動が変わることがあります。安定運用にはバージョン固定をご検討ください。
