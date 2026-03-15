# v0.3.0 コードレビュー指摘事項と対応

## レビュー実施日: 2026-03-14

## 指摘事項一覧

### High

| # | 指摘 | 対象ファイル | 対応方針 |
|---|------|------------|---------|
| H1 | Ollama の `curl \| sh` パターンはサプライチェーン攻撃リスク | `.devcontainer/Dockerfile:390` | バージョン固定バイナリ（v0.18.0 tar.zst）に変更 |
| H2 | `@mermaid-js/mermaid-cli@latest` と `@modelcontextprotocol/server-sequential-thinking@latest` のバージョン未固定 | `.devcontainer/Dockerfile:201-204` | `@latest` を削除して他の npm パッケージと統一 |

### Medium

| # | 指摘 | 対象ファイル | 対応方針 |
|---|------|------------|---------|
| M1 | `OLLAMA_HOST` のデフォルト値が URL 形式 | `scripts/gpu/start-ollama.sh:101` | Ollama の `OLLAMA_HOST` とヘルスチェック用 URL を分離 |
| M2 | `detect_gpu` 関数がグローバル変数を暗黙的に設定 | `scripts/gpu/start-ollama.sh:35-46` | GPU 情報の取得をメイン処理に移動し、関数の副作用を排除 |
| M3 | `dot` (graphviz) のバージョン取得未対応 | `scripts/health/checks/cli-tools.sh:38-40` | `dot -V 2>&1` を使ったバージョン取得を追加 |
| M4 | `context7` が `optional` 分類のままだが意図確認が必要 | `scripts/health/checks/mcp.sh:16` | 意図的な分類（API キー依存）、コメントで理由を明記 |

### Low

| # | 指摘 | 対象ファイル | 対応方針 |
|---|------|------------|---------|
| L1 | Codex テンプレートのハードコードパス `/workspaces/YOUR_PROJECT_NAME` | `templates/.codex/config.toml.example` | 置換が必要な旨のコメントを強化 |
| L2 | gpu-setup.md の nvidia-container-toolkit セクションに公式ドキュメントリンクなし | `docs/gpu-setup.md` | NVIDIA 公式ドキュメントへのリンクを追加 |

### 2nd レビュー追加指摘（2026-03-14）

| # | 指摘 | 対象ファイル | 対応方針 |
|---|------|------------|---------|
| M5 | `OLLAMA_HOST` の値がドキュメント（URL 形式）とスクリプト（host:port 形式）で不整合 | `docs/gpu-setup.md`, `README.md` | ドキュメント側を host:port 形式に統一 |
| M6 | `devcontainer.local.json` による GPU 設定は VS Code Dev Container では自動マージされない | `devcontainer.json`, `docs/gpu-setup.md`, `README.md` | GPU/CPU 別の devcontainer 構成に分離（下記 M7 で対応） |
| M7 | `--gpus=all` をデフォルト有効にすると macOS / GPU なし環境でコンテナ起動不可 | `.devcontainer/` | GPU/CPU 別の devcontainer を用意し、VS Code の選択ダイアログで切り替え |

## M7: GPU/CPU 別 devcontainer 設計

### ディレクトリ構成

```
.devcontainer/
  Dockerfile              # 共通（変更なし）
  post-create-setup.sh    # 共通（変更なし）
  post-start.sh           # 共通（変更なし）
  scripts/                # 共通（変更なし）
  gpu/
    devcontainer.json     # GPU 版（--gpus=all あり）
  cpu/
    devcontainer.json     # CPU 版（--gpus=all なし）
```

### DRY 原則の維持

- **Dockerfile**: 1つで共通。gpu/cpu 両方から `../Dockerfile` を参照
- **スクリプト**: post-create-setup.sh / post-start.sh は絶対パスまたはワークスペースルートからの相対パスで参照しており変更不要
- **devcontainer.json の差分**: `name` と `runArgs` の `--gpus=all` 有無のみ
- **同期の担保**: 各ファイル先頭に「共通設定を変更する場合は gpu/cpu 両方を更新すること」とコメントで明記

### VS Code の動作

`.devcontainer/devcontainer.json`（ルート）を削除し、サブディレクトリのみにすることで、
VS Code が「Dev Container を開く」時に GPU/CPU を選択するダイアログを表示する。
