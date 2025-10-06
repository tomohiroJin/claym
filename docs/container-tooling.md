# Claym コンテナに含まれるツール一覧

Claym 開発コンテナには、AI エージェント運用を支えるランタイム・CLI・Python ライブラリが幅広くプリインストールされています。以下ではカテゴリーごとに、名称・概要・代表的な利用例を表形式でまとめています。

## ランタイムと言語環境

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| Node.js 20 | AI CLI や MCP サーバーで利用する JavaScript ランタイム | `node --version` |
| npm (最新) | Node.js パッケージマネージャー | `npm install <package>` |
| Python 3 系 | データ処理・MCP サーバーに利用する Python ランタイム | `python3 --version` |
| uv | Python 仮想環境と依存管理を高速化するツール | `uv help` |
| git / git-lfs | リポジトリ管理と大容量ファイル同期 | `git status`, `git lfs ls-files` |
| curl / wget / jq | HTTP/ダウンロードと JSON 整形に便利な基本 CLI | `curl https://example.com` |
| ripgrep (rg) | 高速全文検索ツール | `rg "pattern" src/` |
| fd-find (fd) | 使いやすい `find` 代替 | `fd "*.py" scripts/` |
| bat | シンタックスハイライト付き cat 互換 | `bat README.md` |
| fzf | インタラクティブなファジー検索 | `ls | fzf` |
| zoxide | 賢いディレクトリジャンプ (z + keyword) | `z repo` |
| eza | モダンな `ls` 代替 | `eza -lah` |
| tldr / tree | コマンド早見表とディレクトリ構造表示 | `tldr tar`, `tree -L 2` |

## データ分析・ノートブック

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| pandas | 表形式データ処理の定番ライブラリ | `python -c "import pandas as pd; print(pd.__version__)"` |
| csvkit | CSV を扱う CLI ツール群 | `csvstat data.csv` |
| IPython | 高機能な対話型シェル | `ipython` |
| Jupyter | ノートブック実行環境 | `jupyter notebook` |

## ログ解析・テキスト処理

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| GoAccess | Web アクセスログのリアルタイム解析 | `goaccess access.log -o report.html` |
| lnav | SQL で検索できるログビューア | `lnav /var/log/*.log` |
| yq (npm 版) | YAML/JSON/TOML の変換・抽出 | `yq '.services' docker-compose.yml` |
| miller (mlr) | CSV/TSV/JSONL の整形・集計 | `mlr --icsv --opprint stats1 -a mean data.csv` |
| moreutils | `sponge` などの便利ツール集 | `command | sponge file.txt` |

## Web/API クライアントとスクレイピング

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| HTTPie | 読みやすい HTTP クライアント | `http GET https://api.example.com/users` |
| requests | Python 向け HTTP ライブラリ | `python -c "import requests; print(requests.get('https://httpbin.org/ip').json())"` |
| httpx | 非同期対応の Python HTTP ライブラリ | `python -c "import httpx; print(httpx.get('https://example.com').status_code)"` |
| BeautifulSoup4 | HTML 解析ライブラリ | `python -c "from bs4 import BeautifulSoup; print(BeautifulSoup('<p>hi</p>', 'html.parser').text)"` |
| lxml | 高速な XML/HTML パーサー | `python -c "import lxml"` |

## 市場・金融データ

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| yfinance | Yahoo! Finance から株価取得 | `python -c "import yfinance as yf; print(yf.Ticker('AAPL').info['symbol'])"` |
| pandas-datareader | 経済指標など外部データ取得 | `python -c "import pandas_datareader as pdr; pdr.DataReader('DEXJPUS', 'fred')"` |
| qtrn | 金融市場データ表示 CLI | `qtrn quote AAPL` |

## レポート・ドキュメント生成

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| Pandoc | Markdown ↔ PDF/HTML/Slides 変換 | `pandoc README.md -o README.pdf` |
| Landslide | Markdown → HTML スライド化 | `landslide slides.md -d slides.html` |
| Jinja2 | テンプレートエンジン (Python) | `python -c "import jinja2"` |

## 画像・動画処理

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| ImageMagick | 画像の変換・リサイズ | `magick input.png -resize 50% output.png` |
| FFmpeg | 音声・動画の変換・抽出 | `ffmpeg -i input.mp4 -vn audio.mp3` |
| libwebp (cwebp) | WebP 形式の変換ツール | `cwebp input.png -o output.webp` |
| Tesseract OCR | OCR エンジン（ImageSorcery のテキスト抽出にも利用） | `tesseract input.png output` |

## Git / ネットワーク / セキュリティ

| 名前 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| gh CLI | GitHub 公式 CLI | `gh repo view` |
| git-extras | Git 補助コマンド集 | `git changelog` |
| git-delta | Git diff を見やすく彩色するビューア | `git diff | delta` |
| tig | 対話型 Git ビューア | `tig status` |
| tmux | 端末マルチプレクサ | `tmux new -s claym` |
| iputils-ping | ICMP 疎通確認 | `ping -c 3 example.com` |
| bind9-dnsutils (dig) | DNS 解析ツール | `dig claym.dev` |
| traceroute | 経路追跡 | `traceroute example.com` |
| mtr-tiny | ping + traceroute の連続計測 | `mtr example.com` |
| netcat-openbsd (nc) | ポート疎通・簡易サーバー | `nc -v example.com 80` |
| socat | 多機能ソケットツール | `socat TCP-LISTEN:9000,fork TCP:example.com:80` |
| lsof | プロセスが開くファイル/ポートを調査 | `lsof -i :3000` |
| whois | ドメイン情報照会 | `whois example.com` |
| openssl | SSL/TLS の検証 | `openssl s_client -connect example.com:443` |

## プリインストール済み AI CLI

| CLI | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| Claude Code | Anthropic 製 AI CLI | `claude` |
| Codex CLI | OpenAI ベースの CLI | `codex chat` |
| Gemini CLI | Google Gemini 用 CLI | `gemini chat` |

## バンドル済み MCP サーバー

| MCP 名 | 概要 | 代表的なコマンド例 |
| --- | --- | --- |
| serena | IDE アシスタント向けマルチツール MCP | `uv run --directory /opt/serena serena status` |
| playwright | ブラウザ自動化 MCP | `npx @playwright/mcp@latest --help` |
| markitdown | Markdown ↔ HTML/URL 変換 MCP | `markitdown-mcp --help` |
| imagesorcery | 画像処理 MCP (モデル取得済み) | `imagesorcery-mcp --list-tools` |
| filesystem | ワークスペースアクセス MCP | `npx -y @modelcontextprotocol/server-filesystem --help` |
| context7 (SSE) | 外部 SSE MCP エンドポイント | `curl https://mcp.context7.com/sse` |
| mcp-github | GitHub 操作用 MCP | `uvx mcp-github --help` |
| firecrawl | Web クローリング MCP | `npx -y firecrawl-mcp --help` |

> それぞれのツールはコンテナ内ですぐに利用できます。バージョン確認や詳細オプションは `--help` で確認してください。
