# CLAYM v0.3.0 作業チェックリスト

## Phase 1: MCP 追加 + ENABLE_TOOL_SEARCH

- [ ] `.devcontainer/Dockerfile` — npm グローバルに `@modelcontextprotocol/server-sequential-thinking` を追加
- [ ] `.devcontainer/post-create-setup.sh` — 3 つの MCP 登録関数を追加（sequential-thinking, memory, git）
- [ ] `.devcontainer/post-create-setup.sh` — register 呼び出しリストに 3 関数を追加
- [ ] `.claude/settings.local.json` — `enableToolSearch: true` を追加
- [ ] `.claude/settings.local.json` — 3 MCP 定義を追加（sequential-thinking, memory, git）
- [ ] `.claude/settings.local.json` — permissions.allow に 3 MCP の権限を追加
- [ ] `.gemini/settings.json` — 3 MCP 定義を追加
- [ ] `templates/.codex/config.toml.example` — 3 MCP 定義を追加
- [ ] `templates/.claude/settings.local.json.example` — 上記と同期更新
- [ ] `templates/.gemini/settings.json.example` — 上記と同期更新
- [ ] `scripts/health/checks/mcp.sh` — required 配列に 3 MCP を追加
- [ ] `docs/container-tooling.md` — 「バンドル済み MCP サーバー」テーブルに 3 MCP を追加

## Phase 2: CLI ツール拡充

- [ ] `.devcontainer/Dockerfile` — APT ブロックに direnv, graphviz, chafa を追加
- [ ] `.devcontainer/Dockerfile` — バイナリ DL ブロックに just, difftastic, dust, sd, watchexec, duckdb, qsv を追加
- [ ] `.devcontainer/Dockerfile` — npm グローバルに @mermaid-js/mermaid-cli を追加
- [ ] `.devcontainer/Dockerfile` — zshrc に direnv フックを追加
- [ ] `scripts/health/checks/cli-tools.sh` — check_modern_cli_tools にツール追加
- [ ] `scripts/health/checks/cli-tools.sh` — check_modern_cli_versions にバージョンチェック追加
- [ ] `scripts/health/checks/cli-tools.sh` — check_shell_aliases に direnv hook 追加
- [ ] `docs/container-tooling.md` — 新ツールの情報を追加
- [ ] `README.md` — ツール一覧セクションを更新

## Phase 3: GPU 対応 — ローカル LLM

- [ ] `.devcontainer/Dockerfile` — Ollama CLI インストールを追加
- [ ] `.devcontainer/devcontainer.json` — remoteEnv に OLLAMA_HOST を追加
- [ ] `scripts/gpu/start-ollama.sh` — GPU 検出 + Ollama 起動スクリプトを新規作成
- [ ] `docs/gpu-setup.md` — OS 別 GPU セットアップガイドを新規作成
  - [ ] Linux セクション（nvidia-container-toolkit）
  - [ ] Windows (WSL2) セクション（WSL2 + Docker Desktop）
  - [ ] macOS セクション（CPU モード + ホスト Ollama 接続）
  - [ ] 共通セクション（Ollama の使い方、モデル一覧、トラブルシューティング）
- [ ] `scripts/health/checks/cli-tools.sh` — Ollama ヘルスチェックを追加
- [ ] `README.md` — GPU セクションを追加（docs/gpu-setup.md へのリンク）

## 横断タスク

- [ ] `.gitignore` — `local/memory-bank/` が除外されていることを確認（`local/` で既にカバー）
- [ ] 既存テスト通過確認 — `bash scripts/test/run-setup-tests.sh all` で 91 テスト通過
- [ ] README.md — バージョン表記を v0.3.0 に更新、最終更新日を更新
