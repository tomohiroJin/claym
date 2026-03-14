# CLAYM v0.3.0 作業チェックリスト

## Phase 1: MCP 追加 + ENABLE_TOOL_SEARCH

- [x] `.devcontainer/Dockerfile` — npm グローバルに `@modelcontextprotocol/server-sequential-thinking` を追加
- [x] `.devcontainer/post-create-setup.sh` — 3 つの MCP 登録関数を追加（sequential-thinking, memory, git）
- [x] `.devcontainer/post-create-setup.sh` — register 呼び出しリストに 3 関数を追加
- [x] `.claude/settings.local.json` — `enableToolSearch: true` を追加
- [x] `.claude/settings.local.json` — 3 MCP 定義を追加（sequential-thinking, memory, git）
- [x] `.claude/settings.local.json` — permissions.allow に 3 MCP の権限を追加
- [x] `.gemini/settings.json` — 3 MCP 定義を追加
- [x] `templates/.codex/config.toml.example` — 3 MCP 定義を追加
- [x] `templates/.claude/settings.local.json.example` — 上記と同期更新
- [x] `templates/.gemini/settings.json.example` — 上記と同期更新
- [x] `scripts/health/checks/mcp.sh` — required 配列に 3 MCP を追加
- [x] `docs/container-tooling.md` — 「バンドル済み MCP サーバー」テーブルに 3 MCP を追加

## Phase 2: CLI ツール拡充

- [x] `.devcontainer/Dockerfile` — APT ブロックに direnv, graphviz, chafa を追加
- [x] `.devcontainer/Dockerfile` — バイナリ DL ブロックに just, difftastic, dust, sd, watchexec, duckdb, qsv を追加
- [x] `.devcontainer/Dockerfile` — npm グローバルに @mermaid-js/mermaid-cli を追加
- [x] `.devcontainer/Dockerfile` — zshrc に direnv フックを追加
- [x] `scripts/health/checks/cli-tools.sh` — check_modern_cli_tools にツール追加
- [x] `scripts/health/checks/cli-tools.sh` — check_modern_cli_versions にバージョンチェック追加
- [x] `scripts/health/checks/cli-tools.sh` — check_shell_aliases に direnv hook 追加
- [x] `docs/container-tooling.md` — 新ツールの情報を追加
- [x] `README.md` — ツール一覧セクションを更新

## Phase 3: GPU 対応 — ローカル LLM

- [x] `.devcontainer/Dockerfile` — Ollama CLI インストールを追加
- [x] `.devcontainer/devcontainer.json` — remoteEnv に OLLAMA_HOST を追加
- [x] `scripts/gpu/start-ollama.sh` — GPU 検出 + Ollama 起動スクリプトを新規作成
- [x] `docs/gpu-setup.md` — OS 別 GPU セットアップガイドを新規作成
  - [x] Linux セクション（nvidia-container-toolkit）
  - [x] Windows (WSL2) セクション（WSL2 + Docker Desktop）
  - [x] macOS セクション（CPU モード + ホスト Ollama 接続）
  - [x] 共通セクション（Ollama の使い方、モデル一覧、トラブルシューティング）
- [x] `scripts/health/checks/cli-tools.sh` — Ollama ヘルスチェックを追加
- [x] `README.md` — GPU セクションを追加（docs/gpu-setup.md へのリンク）

## 横断タスク

- [x] `.gitignore` — `local/memory-bank/` が除外されていることを確認（`local/` で既にカバー）
- [x] 既存テスト通過確認 — `bash scripts/test/run-setup-tests.sh all` で 108 テスト通過
- [x] README.md — バージョン表記を v0.3.0 に更新、最終更新日を更新
