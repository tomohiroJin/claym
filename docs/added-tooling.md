# 初期構成以降に追加されたソフト一覧

このドキュメントは、コンテナの初期定義（`.devcontainer/Dockerfile`）には**含まれていない**が、その後に追加導入されたソフトをまとめたものです。`docs/container-tooling.md`（初期構成のツール一覧）と対になります。

調査日: 2026-05-25 時点

## 導入先（環境）の使い分け

追加ソフトは用途に応じて **3 系統の環境** に分かれて導入されています。ソフトを探すときはこの区別が重要です。

| 環境 | パス | 性格 |
| --- | --- | --- |
| **共通 Python 環境** | `/opt/mcp-venv` | ASR・TTS・ML 基盤・ドキュメント解析など、複数プロジェクトで横断利用するもの |
| **プロジェクト専用 venv** | `local/<project>/.venv` 等 | 特定プロジェクトでのみ使うもの（例: **rembg** はここにある。`/opt/mcp-venv` には無い） |
| **`/opt` 配下のバイナリ／データ** | `/opt/voicevox` 等 | エンジン本体・モデルデータ |

> ⚠️ **重要**: `pip list`（`/opt/mcp-venv`）に出ないソフトでも、プロジェクト専用 venv に存在することがあります。「入っていない」と判断する前に `local/*/.venv` も確認してください。

---

## 音声合成・音声処理（`/opt/mcp-venv`）

「音声作成」用のツール群です。VOICEVOX がエンジン本体です。

| 名前 | バージョン | 概要 |
| --- | --- | --- |
| VOICEVOX (`voicevox_core`) | 0.16.4 | 音声合成エンジン。モデルデータは `/opt/voicevox/data`（`dict` / `models` / `vvms` / `onnxruntime`） |
| librosa | 0.11.0 | 音声解析（特徴量抽出・テンポ検出） |
| pydub | 0.25.1 | 音声の編集・結合・フォーマット変換 |
| pyworld | 0.3.5 | ピッチ・ボコーダー分析（音声加工） |
| torchaudio | 2.10.0 | PyTorch ベースの音声処理 |
| torchcodec | 0.10.0 | 音声／動画コーデック（PyTorch 連携） |
| SpeechRecognition | 3.15.1 | 各種音声認識バックエンドのラッパー |
| conformer | 0.3.2 | 音声系 Transformer モデル |
| wetext | 0.1.2 | TTS 前のテキスト正規化 |
| sentencepiece | 0.2.1 | サブワードトークナイザ |
| inflect | 7.5.0 | 数値・記号の読み下し（TTS 前処理） |
| HyperPyYAML | 1.2.3 | 音声モデル（CosyVoice 等）の設定記述 |

## 音声認識（ASR）（`/opt/mcp-venv`）

文字起こし用。詳細は `docs/container-tooling.md` の「音声認識（ASR）・文字起こし」セクションも参照してください。

| 名前 | バージョン | 概要 |
| --- | --- | --- |
| faster-whisper | 1.2.1 | Whisper の高速再実装（CTranslate2 バックエンド、GPU 対応） |
| openai-whisper | 20250625 | OpenAI 公式 Whisper（`whisper` CLI） |

## 機械学習・画像生成基盤（`/opt/mcp-venv`）

GPU（CUDA）を前提とした深層学習・画像生成・LoRA 学習のためのライブラリ群です。

| 名前 | バージョン | 概要 |
| --- | --- | --- |
| torch | 2.10.0+cu128 | 深層学習フレームワーク（CUDA 12.8 ビルド） |
| transformers | 4.57.6 | Hugging Face モデル実行 |
| diffusers | 0.37.0 | 拡散モデルによる画像生成（Stable Diffusion 等） |
| accelerate | 1.13.0 | 学習・推論の高速化／分散実行 |
| peft | 0.18.1 | LoRA 等のパラメータ効率ファインチューニング |
| bitsandbytes | 0.49.2 | 量子化（8bit/4bit） |
| lightning | 2.6.1 | PyTorch Lightning（学習ループ抽象化） |
| x-transformers | 2.17.7 | Transformer 実装集 |
| prodigyopt | 1.1.2 | Prodigy オプティマイザ（LoRA 学習向け） |
| realesrgan | 0.3.0 | 画像超解像（アップスケール） |
| onnx / onnxruntime | 1.20.1 / 1.24.4 | ONNX モデル形式・実行 |
| gguf | 0.18.0 | GGUF 量子化モデルの扱い |
| safetensors | 0.7.0 | 安全なモデル重み形式 |
| modelscope | 1.35.1 | モデルハブ（DL・管理） |
| hydra-core | 1.3.2 | 設定管理 |
| tensorboard | 2.20.0 | 学習の可視化 |
| opencv-python | 4.13.0.92 | 画像処理 |
| pillow / numpy / scipy | 12.1.1 / 2.4.3 / 1.17.1 | 画像・数値演算の基盤 |
| nvidia-cuda-* / cuda-toolkit | 13.0.x / 13.0.2 | CUDA ランタイム一式 |

## 画像処理・背景除去（プロジェクト専用 venv）

| 名前 | バージョン | 概要・所在 |
| --- | --- | --- |
| rembg | 2.0.75 | 画像の背景除去（切り出し）。**`/opt/mcp-venv` には無い**。利用するプロジェクトの `local/<project>/.venv` に個別導入する運用（使い捨ての `/tmp/bgvenv` を使う場合もある）。モデルは `~/.u2net/`（`u2net.onnx` / `isnet-general-use.onnx`） |

> `/tmp/bgvenv` は一時領域のためコンテナ再構築で消えます。恒久利用するプロジェクトでは各自の `.venv` に導入してください。

## ドキュメント解析・変換（`/opt/mcp-venv`）

`docs/container-tooling.md` の「レポート・ドキュメント生成」を補完する、解析・抽出系の拡張です。

| 名前 | バージョン | 概要 |
| --- | --- | --- |
| docling | 2.81.0 | 高度なドキュメント構造解析 |
| pdfplumber | 0.11.9 | PDF からのテキスト・表抽出 |
| mammoth | 1.11.0 | Word(.docx) → HTML 変換 |
| EbookLib | 0.20 | EPUB の読み書き |
| azure-ai-documentintelligence | 1.0.2 | Azure のドキュメント解析クライアント |
| azure-identity | 1.25.3 | Azure 認証 |
| semchunk | 3.2.5 | セマンティックなテキスト分割 |
| youtube-transcript-api | 1.0.3 | YouTube 字幕の取得 |

## コード解析・その他（`/opt/mcp-venv`）

| 名前 | バージョン | 概要 |
| --- | --- | --- |
| tree-sitter（＋ python/js/ts/c パーサ） | 0.25.2 | 構文解析（Serena 等が利用） |
| gdown | 5.2.1 | Google Drive からのダウンロード |
| lupa | 2.6 | Python から Lua を実行 |
| aiohttp | 3.13.3 | 非同期 HTTP |
| pytest | 9.0.2 | テストフレームワーク |
| keyring | 25.7.0 | 資格情報の保管 |

---

## 補足

- バージョンは調査時点（2026-05-25）のものです。`pip list` で最新を確認できます。
- このリストは主要な追加ソフトを対象とし、それらの推移的依存（多数）は省略しています。
- GPU 関連の前提・使い分けは `docs/gpu-setup.md` を参照してください。
