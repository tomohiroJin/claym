# CLI ツール拡張仕様書

## 概要

開発コンテナに追加のモダン CLI ツールを導入し、より快適な CLI 環境を提供します。

## 目的

- Debian 12 移行時に削除された zoxide, eza, tldr, git-delta を再導入
- 追加の便利な CLI ツール (procs, bottom, dust, hyperfine, sd, tokei) を導入
- イメージサイズの増加を最小限に抑えながら、開発者体験を向上

## 対象ツール

### 再導入するツール (以前 Ubuntu 版で提供)

| ツール名 | 説明 | インストール方法 |
|----------|------|------------------|
| **zoxide** | スマートなディレクトリ移動 (cd の強化版) | バイナリダウンロード |
| **eza** | ls の代替 (色付き、アイコン、Git 統合) | バイナリダウンロード |
| **tldr** | コマンドのクイックリファレンス | npm |
| **git-delta** | Git 差分の見やすい表示 | バイナリダウンロード |

### 新規追加ツール

| ツール名 | 説明 | インストール方法 |
|----------|------|------------------|
| **procs** | ps の代替 (カラフル、ツリー表示) | cargo |
| **bottom** (btm) | htop の代替 (システムモニタ) | cargo |
| **dust** | du の代替 (ディスク使用量の視覚化) | cargo |
| **hyperfine** | コマンドのベンチマーク | cargo |
| **sd** | sed の代替 (シンプルな構文) | cargo |
| **tokei** | コード行数カウンタ (cloc 代替) | cargo |

## 技術的アプローチ

### インストール方法の選択理由

#### npm 経由 (tldr)
- Node.js が既にインストール済み
- パッケージ管理が容易
- イメージサイズへの影響が最小

#### バイナリダウンロード (zoxide, eza, git-delta)
- ビルド時間なし
- 最小限のイメージサイズ増加
- 特定のバージョンを固定可能

#### cargo 経由 (Rust ツール)
- 最新版が利用可能
- すべてのツールを統一的に管理
- ビルド後に Rust ツールチェーンを削除してサイズ削減

### Dockerfile の構成

```dockerfile
# Rust ツールチェーンのインストール
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:$PATH"

# npm ツール
RUN npm install -g tldr

# バイナリダウンロード
RUN ARCH=$(dpkg --print-architecture) && \
    # zoxide
    curl -sLO "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.4/zoxide-0.9.4-${ARCH}-unknown-linux-musl.tar.gz" && \
    tar -xzf zoxide-*.tar.gz -C /usr/local/bin && \
    rm zoxide-*.tar.gz && \
    # eza
    curl -sLO "https://github.com/eza-community/eza/releases/download/v0.18.0/eza_${ARCH}.tar.gz" && \
    tar -xzf eza_*.tar.gz -C /usr/local/bin && \
    rm eza_*.tar.gz && \
    # git-delta
    curl -sLO "https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-${ARCH}-unknown-linux-musl.tar.gz" && \
    tar -xzf delta-*.tar.gz --strip-components=1 -C /usr/local/bin && \
    rm delta-*.tar.gz

# Rust ツール
RUN cargo install procs bottom dust hyperfine sd tokei

# Rust ツールチェーンの削除 (サイズ削減)
RUN rustup self uninstall -y
```

### .zshrc の設定

```bash
# Debian のコマンド実体名エイリアス
alias bat="batcat"
alias fd="fdfind"

# モダン CLI ツールのエイリアス
alias ll="eza -la --git"
alias ls="eza"
alias cat="bat"
alias find="fd"
alias ps="procs"
alias du="dust"
alias top="btm"

# zoxide の初期化
eval "$(zoxide init zsh)"
alias cd="z"

# Git delta の設定
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
```

## イメージサイズへの影響

### 見積もり

| 項目 | サイズ |
|------|--------|
| Rust ツールチェーン (一時) | ~400MB |
| バイナリツール (zoxide, eza, delta) | ~20MB |
| Rust ツール (6個) | ~80MB |
| npm ツール (tldr) | ~5MB |
| **合計 (ビルド後)** | **~105MB** |

### サイズ削減策

1. Rust ツールチェーンの minimal プロファイル使用
2. ビルド後に rustup をアンインストール
3. バイナリは musl ビルド (静的リンク) を優先
4. 不要な依存関係を含めない

## ヘルスチェック

`scripts/health/checks/cli-tools.sh` を追加:

```bash
check_modern_cli_tools() {
  local missing=()
  local tools=(zoxide eza tldr delta procs btm dust hyperfine sd tokei)

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    set_result "WARN" "Modern CLI tools missing: ${missing[*]}" "Rebuild container"
    return
  fi

  set_result "PASS" "All modern CLI tools installed" ""
}
```

## ドキュメント更新

### docs/container-tooling.md

モダン CLI セクションを更新:

```markdown
## モダン CLI ツール

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| ripgrep (rg) | 高速全文検索 | `rg "pattern" src/` |
| fd-find (fd) | find の代替 | `fd "*.py" scripts/` |
| bat | cat の代替 (シンタックスハイライト) | `bat README.md` |
| fzf | インタラクティブ検索 | `ls \| fzf` |
| zoxide (z) | スマートなディレクトリ移動 | `z docs` |
| eza | ls の代替 (色付き、Git 統合) | `eza -la --git` |
| tldr | コマンドクイックリファレンス | `tldr tar` |
| git-delta | Git 差分の美しい表示 | `git diff` (自動適用) |
| procs | ps の代替 | `procs` |
| bottom (btm) | システムモニタ | `btm` |
| dust | du の代替 | `dust` |
| hyperfine | ベンチマーク | `hyperfine 'command1' 'command2'` |
| sd | sed の代替 | `sd 'before' 'after' file.txt` |
| tokei | コード行数カウンタ | `tokei .` |
```

### README.md

トラブルシューティングセクションから削除:

> ~~git-delta は Debian ベースのイメージでは同梱していません。~~

モダン CLI セクションを更新:

```markdown
- モダン CLI: ripgrep, fd, bat, fzf, tree, zoxide, eza, tldr, git-delta, procs, bottom, dust, hyperfine, sd, tokei
```

## テスト計画

### 1. ビルドテスト
- コンテナが正常にビルドできること
- イメージサイズが予想範囲内 (現行 + ~150MB 以内)

### 2. 機能テスト
- 各ツールが正常に起動すること
  ```bash
  zoxide --version
  eza --version
  tldr --version
  delta --version
  procs --version
  btm --version
  dust --version
  hyperfine --version
  sd --version
  tokei --version
  ```

### 3. 統合テスト
- エイリアスが正常に動作すること
- zoxide の初期化が成功すること
- git-delta が Git に統合されていること

### 4. ヘルスチェックテスト
```bash
bash scripts/health/check-environment.sh
# 新しい CLI ツールチェックがパスすること
```

## リスクと緩和策

### リスク 1: イメージサイズの増加
- **緩和策**: Rust ツールチェーンの削除、musl バイナリの使用
- **許容範囲**: +150MB まで (現行 ~1.2GB → ~1.35GB)

### リスク 2: ビルド時間の増加
- **緩和策**: Docker レイヤーキャッシュの活用
- **許容範囲**: +5-10分程度

### リスク 3: バージョン互換性
- **緩和策**: 特定バージョンを明記、定期的な更新チェック
- **対応**: バージョン固定でトラブルを回避

## 成功基準

- [ ] すべてのツールがインストールされている
- [ ] ヘルスチェックがパスする
- [ ] イメージサイズ増加が +150MB 以内
- [ ] エイリアスが正常に動作する
- [ ] ドキュメントが更新されている
- [ ] PR レビューが承認される

## 実装スケジュール

1. **Dockerfile 修正** (1-2時間)
2. **.zshrc 更新** (30分)
3. **ヘルスチェック追加** (30分)
4. **ドキュメント更新** (30分)
5. **テスト・検証** (1時間)
6. **PR 作成・レビュー** (30分)

**合計見積もり**: 4-5時間
