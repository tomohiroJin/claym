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
- [x] `scripts/health/checks/cli-tools.sh` — check_modern_cli_versions にバージョンチェック追加（※ dot は標準エラー出力のため対応不可、コメントで記載）
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

## Phase 4: ベースイメージ移行 — debian:bookworm-slim → ubuntu:24.04

詳細仕様: [spec-ubuntu-migration.md](spec-ubuntu-migration.md)

### P0: ビルド直結
- [x] `.devcontainer/Dockerfile` — `FROM debian:bookworm-slim` → `FROM ubuntu:24.04` に変更

### P1: 動作不良リスク
- [x] `.devcontainer/Dockerfile` — Python パス `python3.11` → `python3.12` に変更（imagesorcery ログディレクトリ）
- [x] `.devcontainer/Dockerfile` — `libasound2` パッケージ名の確認・修正（`libasound2t64` の可能性）
- [x] `.devcontainer/Dockerfile` — `bat`/`fd-find` パッケージ名とエイリアス設定の確認・修正

### P2: ドキュメント更新
- [x] `README.md` — ベース OS 記述を「Ubuntu 24.04 LTS」に更新
- [x] `docs/container-tooling.md` — `batcat`/`fdfind` エイリアス説明の確認・更新

### 検証
- [x] コンテナビルド成功確認
- [x] `qsv --version` 動作確認
- [x] `bat`/`fd` 動作確認
- [x] Python 3.12 + imagesorcery-mcp 動作確認
- [x] 全ヘルスチェック通過（`bash scripts/health/checks/cli-tools.sh`）
- [x] 全テスト通過（`bash scripts/test/run-setup-tests.sh all`）

## レビュー指摘事項の対応（[review-findings.md](review-findings.md)）

- [x] H1: Dockerfile — Ollama インストールをバージョン固定バイナリ（v0.18.0）に変更
- [x] H2: Dockerfile — npm パッケージの `@latest` タグを削除
- [x] M1: start-ollama.sh — `OLLAMA_HOST` とヘルスチェック URL を分離
- [x] M2: start-ollama.sh — `detect_gpu` 関数の副作用を排除
- [x] M3: cli-tools.sh — `dot -V 2>&1` によるバージョン取得を追加
- [x] M4: mcp.sh — `context7` が `optional` である理由をコメントで明記
- [x] L1: config.toml.example — プレースホルダー置換の注意コメントを強化
- [x] L2: gpu-setup.md — nvidia-container-toolkit 公式ドキュメントリンクを追加
- [x] M5: gpu-setup.md / README.md — `OLLAMA_HOST` の値を host:port 形式に統一
- [x] M6: devcontainer.local.json による GPU 設定が機能しない問題を特定
- [x] M7: GPU/CPU 別 devcontainer 構成に分離（gpu/ と cpu/ サブディレクトリ）
  - [x] `.devcontainer/gpu/devcontainer.json` を作成（--gpus=all あり）
  - [x] `.devcontainer/cpu/devcontainer.json` を作成（--gpus=all なし）
  - [x] `.devcontainer/devcontainer.json`（ルート）を削除
  - [x] docs/gpu-setup.md を GPU/CPU 選択方式に更新
  - [x] README.md を更新
