# TODO: Claym v0.2.0 ライブラリ・ツール追加

## 概要
Claym v0.2.0 向けに、仕様書に基づいた各種ライブラリとツールを Dev Container に追加する。

## タスク一覧

### 1. 数値・表データ分析（CSV/スプレッドシート）
- [x] Pandas（Python）をインストール
- [x] csvkit（CLI）をインストール
- [x] IPython / Jupyter（Python）をインストール

### 2. ログ解析・テキスト解析
- [x] GoAccess（CLI）をインストール
- [x] jq・yq（CLI）をインストール（jqは導入済み、yqを追加）
- [x] ripgrep・grep・sed/awk（CLI）を確認（ripgrepは導入済み、grep/sed/awkは標準装備を確認）
- [x] lnav（CLI）をインストール

### 3. Webデータ取得・API連携
- [x] cURL / HTTPie（CLI）をインストール（cURLは導入済み、HTTPieを追加）
- [x] requests / httpx（Python）をインストール
- [x] BeautifulSoup4・lxml（Python）をインストール

### 4. 市場・金融データ分析
- [x] yfinance（Python）をインストール
- [x] pandas_datareader（Python）をインストール
- [x] qtrn（CLI）をインストール

### 5. レポート・プレゼンテーション生成
- [x] Pandoc（CLI）をインストール
- [x] Landslide（Python）をインストール
- [x] Jinja2（Python）をインストール

### 6. 画像・動画処理（基本）
- [x] ImageMagick（CLI）をインストール
- [x] FFmpeg（CLI）をインストール
- [x] libwebp（CLI）をインストール

### 7. 現代的CLIツールと環境補完
- [x] fzf・ripgrep・fd・bat・eza を確認（すべて導入済み）
- [x] zsh + Oh My Zsh を確認（導入済み）
- [x] yq を追加インストール
- [x] tmux をインストール（オプション）
- [x] git-extras・tig・gh CLI をインストール

### 8. Dockerfile 更新
- [x] 新規ツールを Dockerfile に追加
- [x] Python パッケージのインストールセクションを整理
- [ ] ビルドテストを実施

### 9. README 更新
- [x] v0.2.0 の変更内容を README.md に追記
- [x] 新規追加ツールのリストを記載

### 10. 動作確認とコミット
- [ ] コンテナをリビルドして動作確認
- [ ] ヘルスチェックスクリプトを実行
- [ ] 変更をコミット
