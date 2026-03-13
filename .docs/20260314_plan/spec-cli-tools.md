# Phase 2: CLI ツール拡充 詳細仕様

## 追加ツール一覧

### Tier 1（強く推奨 — AI 開発に直結）

| ツール | 用途 | インストール方法 | コマンド名 |
|--------|------|-----------------|-----------|
| direnv | 環境変数の自動切替 | APT | `direnv` |
| just | タスクランナー（Makefile 代替） | バイナリ DL | `just` |
| difftastic | 構文認識 diff | バイナリ DL | `difft` |
| graphviz | グラフ描画（dot 言語） | APT | `dot` |
| duckdb | 組み込み SQL 分析 | バイナリ DL | `duckdb` |

### Tier 2（推奨 — 便利だが代替あり）

| ツール | 用途 | インストール方法 | コマンド名 | 備考 |
|--------|------|-----------------|-----------|------|
| dust | ディスク使用量可視化 | バイナリ DL | `dust` | ncdu の補完 |
| sd | sed 代替（直感的置換） | バイナリ DL | `sd` | |
| watchexec | ファイル監視 + コマンド実行 | バイナリ DL | `watchexec` | |
| qsv | CSV 高速処理 | バイナリ DL | `qsv` | csvkit 補完 |
| chafa | ターミナル画像表示 | APT | `chafa` | |
| mermaid-cli | ダイアグラム生成 | npm | `mmdc` | Playwright の Chromium を再利用 |

## 変更対象ファイルと変更内容

### 1. `.devcontainer/Dockerfile`

#### APT ブロックへの追加

既存の `cloc;` の後、セミコロンの前に追加:

```dockerfile
    # v0.3.0: 追加CLIツール
    direnv \
    graphviz \
    chafa \
```

注意: 既存の `cloc;` のセミコロンを `cloc \` に変更し、`chafa;` で終了する。

#### npm グローバルへの追加

既存の `tldr` の後に追加:

```dockerfile
    # v0.3.0: ダイアグラム生成（Playwright の Chromium を再利用）
    @mermaid-js/mermaid-cli@latest \
```

注意: `tldr` の後にバックスラッシュを追加する。Phase 1 で `@modelcontextprotocol/server-sequential-thinking` も同じ npm ブロックに追加されるため、実装時は両方を含めた最終的な行順序と末尾バックスラッシュを調整すること（最終行のみバックスラッシュなし）。

#### バイナリ DL ブロックの拡張

既存の `rm delta-*.tar.gz` の後に追加:

```dockerfile
    # v0.3.0: just (タスクランナー)
    curl -sLO "https://github.com/casey/just/releases/download/1.36.0/just-1.36.0-x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf just-*.tar.gz -C /usr/local/bin just; \
    rm just-*.tar.gz; \
    # v0.3.0: difftastic (構文認識diff)
    curl -sLO "https://github.com/Wilfred/difftastic/releases/download/0.62.0/difft-x86_64-unknown-linux-gnu.tar.gz"; \
    tar -xzf difft-*.tar.gz -C /usr/local/bin; \
    rm difft-*.tar.gz; \
    # v0.3.0: dust (ディスク使用量可視化)
    curl -sLO "https://github.com/bootandy/dust/releases/download/v1.1.1/dust-v1.1.1-x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf dust-*.tar.gz --strip-components=1 -C /usr/local/bin dust-v1.1.1-x86_64-unknown-linux-musl/dust; \
    rm dust-*.tar.gz; \
    # v0.3.0: sd (sed代替)
    curl -sLO "https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf sd-*.tar.gz -C /usr/local/bin sd; \
    rm sd-*.tar.gz; \
    # v0.3.0: watchexec (ファイル監視)
    curl -sLO "https://github.com/watchexec/watchexec/releases/download/v2.2.0/watchexec-2.2.0-x86_64-unknown-linux-musl.tar.xz"; \
    tar -xJf watchexec-*.tar.xz --strip-components=1 -C /usr/local/bin watchexec-2.2.0-x86_64-unknown-linux-musl/watchexec; \
    rm watchexec-*.tar.xz; \
    # v0.3.0: duckdb (組み込みSQL分析)
    curl -sLO "https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip"; \
    unzip -o duckdb_cli-linux-amd64.zip -d /usr/local/bin; \
    rm duckdb_cli-linux-amd64.zip; \
    # v0.3.0: qsv (CSV高速処理)
    curl -sLO "https://github.com/jqnatividad/qsv/releases/download/0.135.0/qsv-0.135.0-x86_64-unknown-linux-gnu.zip"; \
    unzip -o qsv-*.zip -d /tmp/qsv-extract; \
    cp /tmp/qsv-extract/qsv /usr/local/bin/qsv; \
    chmod +x /usr/local/bin/qsv; \
    rm -rf qsv-*.zip /tmp/qsv-extract
```

注意: 既存の `rm delta-*.tar.gz` の末尾にセミコロン + バックスラッシュを追加して継続する。

#### zshrc への追加

Oh My Zsh 設定ブロックで、`alias cd="z"` の行の後に追加:

```dockerfile
    && echo '# v0.3.0: direnv フック（.envrc の自動読み込み）' >> /home/vscode/.zshrc \
    && echo 'eval "$(direnv hook zsh)"' >> /home/vscode/.zshrc \
```

### 2. `scripts/health/checks/cli-tools.sh`

#### check_modern_cli_tools の更新

```bash
# 変更前
local tools=(zoxide eza tldr delta)

# 変更後
local tools=(zoxide eza tldr delta direnv just difft dust sd watchexec duckdb qsv chafa mmdc dot)
```

#### check_modern_cli_versions の更新

`commands` 配列に以下を追加:

```bash
    "direnv --version"
    "just --version"
    "difft --version"
    "dust --version"
    "sd --version"
    "watchexec --version"
    "duckdb --version"
    "qsv --version"
    "chafa --version"
    "mmdc --version"
```

#### check_shell_aliases の更新

`required_aliases` 配列に追加:

```bash
    "direnv hook"
```

### 3. `docs/container-tooling.md`

以下のセクションを追加・更新:

- 「モダン CLI ツール」テーブルに Tier 1 + Tier 2 のツールを追加
- エイリアス一覧の更新（direnv hook）
- 新セクション「タスクランナー・ビルドツール」または既存セクション内に統合

### 4. `README.md`

- セクション 2.1 のモダン CLI 一覧に新ツールを追記
- セクション 2.1.1 のカテゴリ概要にタスクランナー・データ分析を追記
- バージョン表記を v0.3.0 に更新

## バージョン選定の根拠

各バイナリは x86_64 Linux 向けの musl 静的リンク版を優先選択。
バージョンは 2025 年前半時点の最新安定版を採用（実装時に GitHub Releases で最新を確認すること）。

| ツール | 選定バージョン | 確認日 |
|--------|--------------|--------|
| just | 1.36.0 | 実装時確認 |
| difftastic | 0.62.0 | 実装時確認 |
| dust | 1.1.1 | 実装時確認 |
| sd | 1.0.0 | 実装時確認 |
| watchexec | 2.2.0 | 実装時確認 |
| duckdb | 1.1.3 | 実装時確認 |
| qsv | 0.135.0 | 実装時確認 |

## 見送りツール

| ツール | 見送り理由 |
|--------|-----------|
| tealdeer | tldr が npm で既にインストール済み |
| timg | chafa と機能重複 |
| PlantUML | Java 依存でイメージ肥大化。Mermaid で代替可 |
| workmux | ニッチすぎる、安定性不明 |
| Claude Squad | 外部ツールで不安定、コンテナ内運用が複雑 |
| yq | npm 版が既にインストール済み |
