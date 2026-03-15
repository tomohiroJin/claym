# Phase 4: ベースイメージ移行仕様 — debian:bookworm-slim → ubuntu:24.04

## 背景

### 問題

- Dockerfile のコメント（4行目）は「Ubuntu 24.04 LTS」と記載されているが、実際のベースイメージ（11行目）は `debian:bookworm-slim`
- Debian bookworm の glibc は **2.36** であり、qsv 17.0.0 が要求する **glibc 2.38/2.39** を満たせない
- Ubuntu 24.04 は **glibc 2.39** を搭載しており、移行で qsv が正常動作する

### 現在の glibc バージョン比較

| OS | glibc | qsv 17.0.0 |
|----|-------|------------|
| debian:bookworm-slim | 2.36 | 動作不可（GLIBC_2.38/2.39 not found） |
| ubuntu:24.04 | 2.39 | 動作可能 |

## 影響分析

### P0: ビルド直結（必須対応）

| # | 対象ファイル | 行 | 変更内容 |
|---|------------|-----|---------|
| 1 | `.devcontainer/Dockerfile` | 11 | `FROM debian:bookworm-slim` → `FROM ubuntu:24.04` |
| 2 | `.devcontainer/Dockerfile` | 4 | コメントと実装が整合（変更不要になる） |

### P1: 動作不良リスク（要対応）

| # | 対象ファイル | 行 | 変更内容 | 詳細 |
|---|------------|-----|---------|------|
| 3 | `.devcontainer/Dockerfile` | 240 | `python3.11` → `python3.12` | Ubuntu 24.04 のデフォルト Python は 3.12。imagesorcery ログディレクトリの chown パスが変わる |
| 4 | `.devcontainer/Dockerfile` | 68 | `libasound2` の名称確認 | Ubuntu 24.04 の 64bit time_t 移行で `libasound2t64` に変更されている可能性 |
| 5 | `.devcontainer/Dockerfile` | 44-45, 385-390 | `bat`/`fd-find` パッケージ名とエイリアス | Ubuntu 24.04 でも Debian 同様に `batcat`/`fdfind` のままか要検証 |

### P2: ドキュメント更新

| # | 対象ファイル | 変更内容 |
|---|------------|---------|
| 6 | `README.md` | 「Debian 12 (bookworm)」→「Ubuntu 24.04 LTS」に更新 |
| 7 | `docs/container-tooling.md` | `batcat`/`fdfind` エイリアスの説明を確認・更新 |
| 8 | `docs/gpu-setup.md` | OS 記述の確認（影響軽微） |

### 影響なし（確認済み）

以下は OS 非依存であり、移行による影響はない。

- `.devcontainer/gpu/devcontainer.json` / `cpu/devcontainer.json` — Dockerfile 参照のみ
- `.devcontainer/post-create-setup.sh` — MCP 登録のみ、OS 固有処理なし
- `.devcontainer/post-start.sh` — 絶対パス使用、OS 非依存
- `scripts/` 配下 — ベースイメージ固有の処理なし
- NodeSource の Node.js 22 インストール — Debian/Ubuntu 両対応
- GitHub CLI インストール — Debian/Ubuntu 両対応

## 検証手順

移行後にコンテナ内で以下を確認すること。

```bash
# 1. glibc バージョン
ldd --version | head -1
# 期待: ldd (Ubuntu GLIBC 2.39-...) 2.39

# 2. qsv の動作確認（移行の主目的）
qsv --version

# 3. Python バージョン
python3 --version
ls /opt/mcp-venv/lib/
# 期待: python3.12

# 4. bat / fd の動作確認
batcat --version   # または bat --version
fdfind --version   # または fd --version

# 5. libasound2 パッケージ
dpkg -l | grep libasound

# 6. 全ヘルスチェック
bash scripts/health/checks/cli-tools.sh

# 7. 全テスト
bash scripts/test/run-setup-tests.sh all
```

## 注意事項

- Ubuntu 24.04 の `bat` パッケージは実体が `bat` になっている可能性がある（Debian では `batcat`）。エイリアス設定を要確認
- `fd-find` も同様に Ubuntu では `fd` になっている可能性がある
- Python 3.11 → 3.12 でライブラリの互換性問題は通常発生しないが、imagesorcery-mcp のパス参照のみ修正が必要
- `libasound2` は Ubuntu 24.04 の t64 移行でパッケージ名が変わっている場合、`libasound2t64` または仮想パッケージとして提供されている可能性がある
