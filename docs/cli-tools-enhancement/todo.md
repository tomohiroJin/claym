# CLI ツール拡張 TODO リスト

## フェーズ 1: 準備 ✅
- [x] ブランチ `feature/enhance-cli-tools` 作成
- [x] `spec.md` 作成
- [x] `todo.md` 作成

## フェーズ 2: Dockerfile 修正 🔄
- [ ] Rust ツールチェーンのインストールを追加
- [ ] npm ツール (tldr) のインストールを追加
- [ ] バイナリダウンロード (zoxide, eza, git-delta) を追加
- [ ] cargo でのツールインストール (procs, bottom, dust, hyperfine, sd, tokei) を追加
- [ ] Rust ツールチェーンのアンインストールを追加
- [ ] ビルドテスト実行

## フェーズ 3: .zshrc 更新 ⏳
- [ ] Debian コマンド実体名のエイリアス追加 (bat, fd)
- [ ] モダン CLI ツールのエイリアス追加 (ll, ls, cat, find, ps, du, top)
- [ ] zoxide の初期化追加
- [ ] Git delta の設定追加

## フェーズ 4: ヘルスチェック追加 ⏳
- [ ] `scripts/health/checks/cli-tools.sh` ファイル作成
- [ ] `check_modern_cli_tools()` 関数実装
- [ ] `register_check` 呼び出し追加
- [ ] ヘルスチェック実行テスト

## フェーズ 5: ドキュメント更新 ⏳
- [ ] `docs/container-tooling.md` のモダン CLI セクション更新
- [ ] `README.md` のコンテナ概要セクション更新
- [ ] `README.md` のトラブルシューティングセクション更新

## フェーズ 6: テスト・検証 ⏳
- [ ] コンテナのリビルド実行
- [ ] 各ツールのバージョン確認
  - [ ] zoxide --version
  - [ ] eza --version
  - [ ] tldr --version
  - [ ] delta --version
  - [ ] procs --version
  - [ ] btm --version
  - [ ] dust --version
  - [ ] hyperfine --version
  - [ ] sd --version
  - [ ] tokei --version
- [ ] エイリアスの動作確認
- [ ] zoxide 初期化の動作確認
- [ ] git-delta の Git 統合確認
- [ ] ヘルスチェック全体の実行とパス確認
- [ ] イメージサイズの確認 (許容範囲内か)

## フェーズ 7: PR 作成 ⏳
- [ ] コミットメッセージの作成
- [ ] 変更内容のレビュー
- [ ] PR の作成
- [ ] PR 本文の記述
  - [ ] 概要
  - [ ] 主な変更内容
  - [ ] 追加ツール一覧
  - [ ] イメージサイズの変化
  - [ ] テスト結果
  - [ ] 検証結果

## 注意事項

### イメージサイズ
- 目標: +150MB 以内
- Rust ツールチェーンは必ずアンインストールすること

### バージョン固定
以下のバージョンを使用:
- zoxide: v0.9.4
- eza: v0.18.0
- git-delta: v0.17.0
- tldr: latest (npm)
- Rust ツール: latest (cargo)

### テストコマンド
```bash
# コンテナのリビルド
Dev Containers: Rebuild Container

# ツールの確認
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

# エイリアスの確認
ll
z --help

# ヘルスチェック
bash scripts/health/check-environment.sh

# イメージサイズ確認
docker images | grep claym
```

## 完了条件
- [ ] すべてのツールが正常にインストールされている
- [ ] ヘルスチェックがパスしている
- [ ] イメージサイズが許容範囲内
- [ ] ドキュメントが更新されている
- [ ] PR が作成され、レビュー待ち状態
