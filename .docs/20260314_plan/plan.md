# CLAYM v0.3.0 ブラッシュアップ計画（要約）

## 目的

v0.2.0 で拡充した MCP サーバ群・データ分析ツール・モダン CLI に加え、以下の 3 軸で DevContainer 環境をさらに強化する。

## 3 つの Phase

### Phase 1: MCP 追加 + ENABLE_TOOL_SEARCH（優先度: 高）

- **Sequential Thinking MCP** — 段階的思考プロセスをサポート（npm）
- **Memory MCP** — ナレッジグラフをワークスペース内に永続化（npm）
- **Git MCP** — Git リポジトリ操作を MCP 経由で提供（Python/uvx）
- **enableToolSearch** — トークン削減設定を Claude に追加

### Phase 2: CLI ツール拡充（優先度: 中〜高）

**Tier 1（強く推奨）**: direnv, just, difftastic, graphviz, duckdb
**Tier 2（推奨）**: dust, sd, watchexec, qsv, chafa, mermaid-cli

計 11 ツールを追加。APT / バイナリ DL / npm の 3 方式でインストール。

### Phase 3: GPU 対応 — ローカル LLM（優先度: 中）

- Ollama CLI を Dockerfile に追加
- GPU 利用は `devcontainer.local.json` で `--gpus=all` を指定
- 起動スクリプト `scripts/gpu/start-ollama.sh` で GPU 検出 + サーバ起動
- **OS 別ガイド** `docs/gpu-setup.md` を新規作成
  - Linux: nvidia-container-toolkit で直接 GPU パススルー
  - Windows: WSL2 経由で NVIDIA GPU 対応
  - macOS: GPU パススルー非対応、CPU モードまたはホスト側 Ollama に接続

## 設計方針

- docker-compose.yml は導入しない（構造変更最小）
- Memory MCP はワークスペース内 `local/memory-bank/` に保存（永続化）
- 既存の 91 テストが通過すること

## 変更対象ファイル一覧

| Phase | ファイル | 変更種別 |
|-------|---------|---------|
| 1 | `.devcontainer/Dockerfile` | 変更 |
| 1 | `.devcontainer/post-create-setup.sh` | 変更 |
| 1 | `.claude/settings.local.json` | 変更 |
| 1 | `.gemini/settings.json` | 変更 |
| 1 | `templates/.codex/config.toml.example` | 変更 |
| 1 | `templates/.claude/settings.local.json.example` | 変更 |
| 1 | `templates/.gemini/settings.json.example` | 変更 |
| 1 | `scripts/health/checks/mcp.sh` | 変更 |
| 1 | `docs/container-tooling.md` | 変更 |
| 2 | `.devcontainer/Dockerfile` | 変更 |
| 2 | `scripts/health/checks/cli-tools.sh` | 変更 |
| 2 | `docs/container-tooling.md` | 変更 |
| 2 | `README.md` | 変更 |
| 3 | `.devcontainer/Dockerfile` | 変更 |
| 3 | `.devcontainer/devcontainer.json` | 変更 |
| 3 | `scripts/gpu/start-ollama.sh` | 新規 |
| 3 | `scripts/health/checks/cli-tools.sh` | 変更 |
| 3 | `docs/gpu-setup.md` | 新規 |
| 3 | `README.md` | 変更 |

## 詳細仕様

- [spec-mcp.md](spec-mcp.md) — Phase 1 の詳細
- [spec-cli-tools.md](spec-cli-tools.md) — Phase 2 の詳細
- [spec-gpu.md](spec-gpu.md) — Phase 3 の詳細
- [tasks.md](tasks.md) — 作業チェックリスト
