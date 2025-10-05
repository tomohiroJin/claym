# TODO: Claym v0.2.0 追加仕様 - ネットワーク・Git・データ処理ツール

## 概要
v0.2.0の追加仕様として、Git/GitHub強化、HTTP/ネットワーク疎通、ログ/テキスト加工、SSL/証明書確認のツールを追加する。

## タスク一覧

### 1. Git / GitHub 強化
- [x] gh（GitHub CLI）を公式APTリポジトリから導入（既に導入済みだが、設定確認）
- [x] git-delta（git diff強化）をインストール
- [x] git-extras（便利コマンド集）をインストール（既に導入済み、確認）

### 2. HTTP / API クライアント
- [x] xh（Rust製HTTPクライアント）をインストール

### 3. ネットワーク疎通・診断
- [x] iputils-ping（ICMP疎通確認）をインストール
- [x] bind9-dnsutils（dig等のDNSツール）をインストール
- [x] traceroute（経路追跡）をインストール
- [x] mtr-tiny（ping+traceroute連続計測）をインストール
- [x] netcat-openbsd（ポート疎通）をインストール
- [x] socat（ソケット多機能）をインストール
- [x] lsof（プロセスが開くファイル/ポート一覧）をインストール
- [x] whois（ドメイン情報照会）をインストール
- [x] tcpdump（パケットキャプチャ、オプション）の追加を検討 → 必要時のみ追加（今回は除外）

### 4. 構造化データ / テキスト整形
- [x] yq（YAML/JSON/TOML変換）をインストール（既にnpmで導入済み、APT版と重複確認）
- [x] miller（CSV/TSV/JSONL整形）をインストール
- [x] moreutils（小粒ツール）をインストール

### 5. セキュリティ/SSL
- [x] openssl（証明書/ハンドシェイク確認）をインストール（既に導入済み、確認）

### 6. Dockerfile 更新
- [x] GitHub CLI公式APTリポジトリの設定を確認・整理
- [x] 新規ツールをDockerfileに追加
- [x] 重複ツールの確認と整理

### 7. devcontainer.json 更新
- [x] postCreateCommandにgh auth login設定を追加

### 8. README 更新
- [x] 追加仕様の変更内容をREADME.mdに追記
- [x] 新規追加ツールのリストを記載

### 9. 動作確認とコミット
- [ ] コンテナをリビルドして動作確認
- [ ] ヘルスチェックスクリプトを実行
- [ ] 変更をコミット

---

## 追加仕様2: VS Code拡張の追加

### 10. Git/GitHub 運用・レビュー拡張
- [x] GitHub.vscode-github-actionsを追加
- [x] waderyan.gitblameを追加
- [x] mhutchie.git-graph（オプション）の追加を検討 → 今回は除外（必要時のみ追加）

### 11. HTTP / API / OpenAPI拡張
- [x] humao.rest-clientを追加
- [x] 42Crunch.vscode-openapiを追加
- [x] redhat.vscode-yamlを追加

### 12. ログ・データ視覚支援拡張
- [x] mechatroner.rainbow-csvを追加
- [x] emilast.LogFileHighlighterを追加

### 13. 文章作成・レポーティング拡張
- [x] bierner.markdown-mermaidを追加
- [x] yzane.markdown-pdf（オプション）の追加を検討 → Pandoc併用のため除外

### 14. シェル / コンフィグ編集の品質拡張
- [x] timonwong.shellcheckを追加
- [x] foxundermoon.shell-formatを追加
- [x] tamasfe.even-better-tomlを追加
- [x] redhat.vscode-xml（オプション）の追加を検討 → 必要時のみ追加（今回は除外）

### 15. コンテナ・依存の可視化拡張（任意）
- [x] ms-azuretools.vscode-docker（オプション）の追加を検討 → 必要時のみ追加（今回は除外）
- [x] EditorConfig.EditorConfigを追加

### 16. devcontainer.json settings更新
- [x] REST Client設定を追加
- [x] YAML設定（GitHub Actions / OpenAPI スキーマ）を追加
- [x] Markdown設定を追加
- [x] Shell/品質設定を追加
- [x] CSV設定を追加

### 17. README更新
- [x] 追加した拡張の情報をREADME.mdに追記
- [x] 運用Tipsセクションを追加

### 18. 最終確認とコミット
- [x] 変更をコミット
