# TODO: Claym v0.2.0 追加仕様 - ネットワーク・Git・データ処理ツール

## 概要
v0.2.0の追加仕様として、Git/GitHub強化、HTTP/ネットワーク疎通、ログ/テキスト加工、SSL/証明書確認のツールを追加する。

## タスク一覧

### 1. Git / GitHub 強化
- [ ] gh（GitHub CLI）を公式APTリポジトリから導入（既に導入済みだが、設定確認）
- [ ] git-delta（git diff強化）をインストール
- [ ] git-extras（便利コマンド集）をインストール（既に導入済み、確認）

### 2. HTTP / API クライアント
- [ ] xh（Rust製HTTPクライアント）をインストール

### 3. ネットワーク疎通・診断
- [ ] iputils-ping（ICMP疎通確認）をインストール
- [ ] bind9-dnsutils（dig等のDNSツール）をインストール
- [ ] traceroute（経路追跡）をインストール
- [ ] mtr-tiny（ping+traceroute連続計測）をインストール
- [ ] netcat-openbsd（ポート疎通）をインストール
- [ ] socat（ソケット多機能）をインストール
- [ ] lsof（プロセスが開くファイル/ポート一覧）をインストール
- [ ] whois（ドメイン情報照会）をインストール
- [ ] tcpdump（パケットキャプチャ、オプション）の追加を検討

### 4. 構造化データ / テキスト整形
- [ ] yq（YAML/JSON/TOML変換）をインストール（既にnpmで導入済み、APT版と重複確認）
- [ ] miller（CSV/TSV/JSONL整形）をインストール
- [ ] moreutils（小粒ツール）をインストール

### 5. セキュリティ/SSL
- [ ] openssl（証明書/ハンドシェイク確認）をインストール（既に導入済み、確認）

### 6. Dockerfile 更新
- [ ] GitHub CLI公式APTリポジトリの設定を確認・整理
- [ ] 新規ツールをDockerfileに追加
- [ ] 重複ツールの確認と整理

### 7. devcontainer.json 更新
- [ ] postCreateCommandにgh auth login設定を追加

### 8. README 更新
- [ ] 追加仕様の変更内容をREADME.mdに追記
- [ ] 新規追加ツールのリストを記載

### 9. 動作確認とコミット
- [ ] コンテナをリビルドして動作確認
- [ ] ヘルスチェックスクリプトを実行
- [ ] 変更をコミット
