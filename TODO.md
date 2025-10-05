# TODO: Claym v0.2.0 ライブラリ・ツール追加

## 概要
Claym v0.2.0 向けに、仕様書に基づいた各種ライブラリとツールを Dev Container に追加する。

## タスク一覧

### 1. 数値・表データ分析（CSV/スプレッドシート）
- [ ] Pandas（Python）をインストール
- [ ] csvkit（CLI）をインストール
- [ ] IPython / Jupyter（Python）をインストール

### 2. ログ解析・テキスト解析
- [ ] GoAccess（CLI）をインストール
- [ ] jq・yq（CLI）をインストール（jqは導入済み、yqを追加）
- [ ] ripgrep・grep・sed/awk（CLI）を確認（ripgrepは導入済み、grep/sed/awkは標準装備を確認）
- [ ] lnav（CLI）をインストール

### 3. Webデータ取得・API連携
- [ ] cURL / HTTPie（CLI）をインストール（cURLは導入済み、HTTPieを追加）
- [ ] requests / httpx（Python）をインストール
- [ ] BeautifulSoup4・lxml（Python）をインストール

### 4. 市場・金融データ分析
- [ ] yfinance（Python）をインストール
- [ ] pandas_datareader（Python）をインストール
- [ ] qtrn（CLI）をインストール

### 5. レポート・プレゼンテーション生成
- [ ] Pandoc（CLI）をインストール
- [ ] Landslide（Python）をインストール
- [ ] Jinja2（Python）をインストール

### 6. 画像・動画処理（基本）
- [ ] ImageMagick（CLI）をインストール
- [ ] FFmpeg（CLI）をインストール
- [ ] libwebp（CLI）をインストール

### 7. 現代的CLIツールと環境補完
- [ ] fzf・ripgrep・fd・bat・eza を確認（すべて導入済み）
- [ ] zsh + Oh My Zsh を確認（導入済み）
- [ ] yq を追加インストール
- [ ] tmux をインストール（オプション）
- [ ] git-extras・tig・gh CLI をインストール

### 8. Dockerfile 更新
- [ ] 新規ツールを Dockerfile に追加
- [ ] Python パッケージのインストールセクションを整理
- [ ] ビルドテストを実施

### 9. README 更新
- [ ] v0.2.0 の変更内容を README.md に追記
- [ ] 新規追加ツールのリストを記載

### 10. 動作確認とコミット
- [ ] コンテナをリビルドして動作確認
- [ ] ヘルスチェックスクリプトを実行
- [ ] 変更をコミット
