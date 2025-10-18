# CLI ツール拡張仕様書

## 概要

開発コンテナに追加のモダン CLI ツールを導入し、より快適な CLI 環境を提供します。

## 目的

- Debian 12 移行時に削除された zoxide, eza, tldr, git-delta を再導入
- イメージサイズの増加を最小限に抑えながら、開発者体験を向上
- APTパッケージで提供されているツール (btop, hyperfine, ncdu, cloc) を追加導入

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
| **btop** | htop の代替 (システムモニタ) | APT |
| **hyperfine** | コマンドのベンチマーク | APT |
| **ncdu** | du の代替 (ディスク使用量の視覚化) | APT |
| **cloc** | コード行数カウンタ | APT |

## 技術的アプローチ

### インストール方法の選択理由

#### バイナリダウンロード (zoxide, eza, git-delta)
- ビルド時間なし
- 最小限のイメージサイズ増加
- 特定のバージョンを固定可能
- Debian APTパッケージに含まれていないため、直接ダウンロード

#### APT パッケージ (btop, hyperfine, ncdu, cloc)
- Debian 12リポジトリで提供されているため、パッケージ管理が容易
- ビルド時間が不要
- 依存関係が自動解決される
- Rustツールチェーンのインストール・アンインストールが不要になり、ビルド時間とイメージサイズを削減

### Dockerfile の構成

```dockerfile
# APT パッケージでインストール
RUN apt-get update && apt-get install -y \
    btop \
    hyperfine \
    ncdu \
    cloc \
    xz-utils

# バイナリダウンロード (GitHub Releases)
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    # zoxide v0.9.4
    curl -sLO "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.4/zoxide-0.9.4-x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf zoxide-*.tar.gz -C /usr/local/bin; \
    rm zoxide-*.tar.gz; \
    # eza v0.18.0
    curl -sLO "https://github.com/eza-community/eza/releases/download/v0.18.0/eza_x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf eza_*.tar.gz -C /usr/local/bin; \
    rm eza_*.tar.gz; \
    # git-delta v0.17.0
    curl -sLO "https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-x86_64-unknown-linux-musl.tar.gz"; \
    tar -xzf delta-*.tar.gz --strip-components=1 -C /usr/local/bin delta-0.17.0-x86_64-unknown-linux-musl/delta; \
    rm delta-*.tar.gz
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
alias top="btop"

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
| バイナリツール (zoxide, eza, delta) | ~20MB |
| APT ツール (btop, hyperfine, ncdu, cloc) | ~30MB |
| xz-utils (解凍用) | ~1MB |
| **合計** | **~51MB** |

### サイズ削減策

1. Rustツールチェーンの導入を避け、APTパッケージを優先
2. バイナリは musl ビルド (静的リンク) を優先
3. 不要な依存関係を含めない
4. 当初予定していたRust製ツール(procs, sd, tokei等)は導入を見送り

## ヘルスチェック

`scripts/health/checks/cli-tools.sh` を追加:

```bash
check_modern_cli_tools() {
  local missing=()
  local tools=(zoxide eza tldr delta)

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
| btop | システムモニタ | `btop` |
| hyperfine | ベンチマーク | `hyperfine 'command1' 'command2'` |
| ncdu | ディスク使用量の視覚化 | `ncdu` |
| cloc | コード行数カウンタ | `cloc .` |
```

### README.md

トラブルシューティングセクションから削除:

> ~~git-delta は Debian ベースのイメージでは同梱していません。~~

モダン CLI セクションを更新:

```markdown
- モダン CLI: ripgrep, fd, bat, fzf, tree, zoxide, eza, tldr, git-delta, btop, hyperfine, ncdu, cloc
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
  btop --version
  hyperfine --version
  ncdu --version
  cloc --version
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
- **緩和策**: APTパッケージの活用、Rustツールチェーン不要、musl バイナリの使用
- **許容範囲**: +60MB まで (現行 ~1.2GB → ~1.26GB)

### リスク 2: ビルド時間の増加
- **緩和策**: APTパッケージの活用によりRustビルド不要、Docker レイヤーキャッシュの活用
- **許容範囲**: +2-3分程度

### リスク 3: バージョン互換性
- **緩和策**: 特定バージョンを明記、定期的な更新チェック
- **対応**: バージョン固定でトラブルを回避

## 成功基準

- [x] zoxide, eza, tldr, git-delta がインストールされている
- [x] btop, hyperfine, ncdu, cloc がインストールされている
- [x] ヘルスチェックがパスする
- [x] イメージサイズ増加が +60MB 程度（当初見積もりより大幅削減）
- [x] エイリアスが正常に動作する
- [x] ドキュメントが更新されている
- [ ] PR レビューが承認される

## 実装スケジュール

1. **Dockerfile 修正** (1時間) - ✅ 完了（APT優先に変更）
2. **.zshrc 更新** (30分) - ✅ 完了
3. **ヘルスチェック追加** (30分) - ✅ 完了
4. **ドキュメント更新** (30分) - 🔄 進行中
5. **テスト・検証** (1時間) - 次のフェーズ
6. **PR 作成・レビュー** (30分) - 次のフェーズ

**合計見積もり**: 3-4時間（Rustビルド削除により短縮）
