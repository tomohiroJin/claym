# CLI ツール拡張 TODO リスト

## フェーズ 1: 準備 ✅
- [x] ブランチ `feature/enhance-cli-tools` 作成
- [x] `spec.md` 作成
- [x] `todo.md` 作成

## フェーズ 2: Dockerfile 修正 ✅
- [x] ~~Rust ツールチェーンのインストールを追加~~ (方針変更: APT優先)
- [x] ~~npm ツール (tldr) のインストールを追加~~ (既存のnpmを利用、追加不要)
- [x] バイナリダウンロード (zoxide, eza, git-delta) を追加
- [x] ~~cargo でのツールインストール (procs, bottom, dust, hyperfine, sd, tokei) を追加~~ (方針変更: APTで代替)
- [x] APT パッケージ (btop, hyperfine, ncdu, cloc, xz-utils) のインストールを追加
- [x] ~~Rust ツールチェーンのアンインストールを追加~~ (方針変更: 不要)
- [x] ビルドテスト実行

## フェーズ 3: .zshrc 更新 ✅
- [x] Debian コマンド実体名のエイリアス追加 (bat, fd)
- [x] モダン CLI ツールのエイリアス追加 (ll, ls, cat, find, top)
  - ~~ps, du のエイリアスは削除~~ (procs, dust 未導入のため)
- [x] zoxide の初期化追加
- [x] Git delta の設定追加

## フェーズ 4: ヘルスチェック追加 ✅
- [x] `scripts/health/checks/cli-tools.sh` ファイル作成
- [x] `check_modern_cli_tools()` 関数実装
- [x] `register_check` 呼び出し追加
- [x] ヘルスチェック実行テスト
- [x] 削除されたツール (procs, btm, dust, sd, tokei) をチェックから除外

## フェーズ 5: ドキュメント更新 🔄
- [ ] `docs/container-tooling.md` のモダン CLI セクション更新
- [ ] `README.md` のコンテナ概要セクション更新
- [x] `spec.md` の実装方針を実際の内容に更新
- [x] `todo.md` の完了状況を更新

## フェーズ 6: テスト・検証 ✅
- [x] コンテナのリビルド実行
- [x] 各ツールのバージョン確認
  - [x] zoxide --version
  - [x] eza --version
  - [x] tldr --version (npm経由)
  - [x] delta --version
  - [x] ~~procs --version~~ (未導入)
  - [x] ~~btm --version~~ (btopで代替)
  - [x] btop --version (新規)
  - [x] ~~dust --version~~ (ncduで代替)
  - [x] ncdu --version (新規)
  - [x] hyperfine --version (APT経由)
  - [x] ~~sd --version~~ (未導入)
  - [x] ~~tokei --version~~ (clocで代替)
  - [x] cloc --version (新規)
- [x] エイリアスの動作確認
- [x] zoxide 初期化の動作確認
- [x] git-delta の Git 統合確認
- [x] ヘルスチェック全体の実行とパス確認
- [x] イメージサイズの確認 (許容範囲内か)

## フェーズ 7: PR 作成・更新 🔄
- [x] コミットメッセージの作成
- [x] 変更内容のレビュー
- [x] PR の作成
- [x] PR 本文の記述 (初回版)
  - [x] 概要
  - [x] 主な変更内容
  - [x] 追加ツール一覧
  - [x] イメージサイズの変化
  - [x] テスト結果
  - [x] 検証結果
- [ ] PR 本文の更新 (実装方針変更を反映)
  - [ ] Rust製ツールからAPTパッケージへの変更を説明
  - [ ] 削除されたツールの説明
  - [ ] イメージサイズとビルド時間の改善を記載

## 注意事項

### イメージサイズ
- 目標: +150MB 以内
- Rust ツールチェーンは必ずアンインストールすること

### バージョン固定
以下のバージョンを使用:
- zoxide: v0.9.4 (バイナリダウンロード)
- eza: v0.18.0 (バイナリダウンロード)
- git-delta: v0.17.0 (バイナリダウンロード)
- tldr: latest (npm、既存環境を利用)
- APT ツール: Debian 12 リポジトリ版 (btop, hyperfine, ncdu, cloc)

### テストコマンド
```bash
# コンテナのリビルド
Dev Containers: Rebuild Container

# ツールの確認
zoxide --version
eza --version
tldr --version
delta --version
btop --version
hyperfine --version
ncdu --version
cloc --version

# エイリアスの確認
ll
z --help
top  # btop が起動するか確認

# ヘルスチェック
bash scripts/health/check-environment.sh

# イメージサイズ確認
docker images | grep claym
```

## 完了条件
- [x] すべてのツール (zoxide, eza, tldr, delta, btop, hyperfine, ncdu, cloc) が正常にインストールされている
- [x] ヘルスチェックがパスしている
- [x] イメージサイズが許容範囲内 (~51MB増加、当初見積もりの半分)
- [ ] ドキュメントが更新されている (進行中)
- [x] PR が作成され、レビュー待ち状態
- [ ] PR の説明が実装内容と一致している (更新が必要)
