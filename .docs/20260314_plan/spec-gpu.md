# Phase 3: GPU 対応 — ローカル LLM 詳細仕様

## 設計方針

- **構造変更最小**: docker-compose.yml は導入しない
- **Ollama CLI のみ Dockerfile に追加**: `curl -fsSL https://ollama.com/install.sh | sh`
- **GPU 利用時**: ユーザーが `devcontainer.local.json` で `--gpus all` を `runArgs` に追加
- **起動スクリプト**: `scripts/gpu/start-ollama.sh` で GPU 検出 → `ollama serve` を起動
- **接続先**: `OLLAMA_HOST` 環境変数で制御（デフォルト: `http://localhost:11434`）

## OS 別の GPU 対応状況

| 項目 | Linux | Windows (WSL2) | macOS |
|------|-------|---------------|-------|
| GPU パススルー | nvidia-container-toolkit で直接対応 | WSL2 経由で NVIDIA GPU 対応 | Docker Desktop では GPU パススルー非対応 |
| 対応 GPU | NVIDIA（CUDA 対応） | NVIDIA（CUDA 対応） | なし（Apple Silicon 含む） |
| 必要なドライバ | NVIDIA ドライバ + nvidia-container-toolkit | NVIDIA Game Ready / Studio Driver（WSL2 対応版） | — |
| Docker 設定 | `--gpus=all` | Docker Desktop の WSL2 バックエンド + `--gpus=all` | — |
| 実行モード | GPU モード | GPU モード（WSL2 経由） | CPU モードのみ |
| 制約 | ネイティブ性能 | WSL2 の GPU メモリ共有制約あり | CPU 推論のみ（低速） |

## 変更対象ファイルと変更内容

### 1. `.devcontainer/Dockerfile`

**変更箇所**: bats テストフレームワークの後、補助スクリプトの配置の前に追加

```dockerfile
# ----------------------------------------------------------------------------
# v0.3.0: Ollama CLI のインストール（ローカル LLM 用）
#
# GPU ホストでローカル LLM を実行するための Ollama CLI を導入します。
# GPU を使用する場合は devcontainer.local.json に "--gpus=all" を追加してください。
# 詳細は docs/gpu-setup.md を参照してください。
RUN curl -fsSL https://ollama.com/install.sh | sh
```

### 2. `.devcontainer/devcontainer.json`

**変更箇所**: `remoteEnv` に `OLLAMA_HOST` を追加

```json
"OLLAMA_HOST": "${localEnv:OLLAMA_HOST}"
```

### 3. `scripts/gpu/start-ollama.sh`（新規）

GPU 検出と Ollama サーバ起動を行うスクリプト。

機能:
- Ollama CLI の存在確認
- `nvidia-smi` による GPU 検出
- GPU あり: GPU モードで起動、GPU 名を表示
- GPU なし: CPU モードで起動可能であることを案内
- Ollama サーバをバックグラウンドで起動
- 使い方の案内メッセージを表示

### 4. `docs/gpu-setup.md`（新規）

OS 別の GPU セットアップガイド。以下の構成で作成する:

```
# GPU セットアップガイド（Ollama + ローカル LLM）

## 概要
  - Ollama とは何か、Claym での位置づけ
  - CPU モードは全 OS で利用可能

## OS 別セットアップ

### Linux
  - 前提条件: NVIDIA ドライバ, nvidia-container-toolkit
  - nvidia-container-toolkit のインストール手順
  - devcontainer.local.json の設定
  - 動作確認

### Windows (WSL2)
  - 前提条件: WSL2, Docker Desktop (WSL2 バックエンド), NVIDIA Game Ready / Studio Driver
  - WSL2 での NVIDIA GPU サポートの確認方法（wsl 内で nvidia-smi）
  - Docker Desktop の GPU 設定
  - devcontainer.local.json の設定
  - 動作確認
  - 制約事項（GPU メモリ共有、パフォーマンス）

### macOS
  - 現状の制約: Docker Desktop では GPU パススルー非対応
  - Apple Silicon (M1/M2/M3/M4) でも Docker 内 GPU は使えない
  - CPU モードでの利用方法
  - 代替案: ホスト側で Ollama を直接実行し OLLAMA_HOST で接続

## Ollama の使い方（共通）
  - モデルのダウンロード
  - モデルの実行
  - 起動スクリプトの使い方
  - よく使うモデル一覧

## devcontainer.local.json のサンプル
  - GPU あり（Linux / Windows）
  - GPU なし / macOS（ホスト Ollama 接続）

## トラブルシューティング
  - GPU が検出されない
  - Ollama サーバが起動しない
  - メモリ不足
  - WSL2 固有の問題
```

### 5. `README.md`

- セクション 2 に GPU / Ollama 関連の記述を追加
- セクション 3.3 に `OLLAMA_HOST` を追加
- セクション 5 に GPU 設定のカスタマイズ方法を追加（`docs/gpu-setup.md` へのリンク）
- セクション 7.2 の展望を更新

### 6. `scripts/health/checks/cli-tools.sh`

Ollama のヘルスチェック関数を追加:

```bash
check_ollama_installed() {
  if ! have ollama; then
    set_result "WARN" "Ollama CLI not found" "Rebuild container to install Ollama"
    return
  fi
  local version
  version=$(ollama --version 2>/dev/null | head -n1 || true)
  set_result "PASS" "Ollama CLI installed ($version)" ""
}

register_check "ollama-installed" "Ollama CLI" false false check_ollama_installed
```

## devcontainer.local.json サンプル

### GPU あり（Linux / Windows WSL2）

```json
{
  "runArgs": [
    "--cap-add=SYS_ADMIN",
    "--security-opt=seccomp=unconfined",
    "--shm-size=1g",
    "--gpus=all"
  ],
  "remoteEnv": {
    "OLLAMA_HOST": "http://localhost:11434"
  }
}
```

### macOS / GPU なし（ホスト側 Ollama に接続）

macOS ではコンテナ内で GPU を利用できないため、ホスト側で Ollama を直接実行し、コンテナからホストに接続する方式を推奨。

```json
{
  "remoteEnv": {
    "OLLAMA_HOST": "http://host.docker.internal:11434"
  }
}
```

ホスト側で事前に `ollama serve` を起動しておく必要がある。

## 検証方法

### 全 OS 共通
1. `ollama --version` でコマンド存在確認

### Linux（GPU あり）
1. `bash scripts/gpu/start-ollama.sh` で GPU 検出 + サーバ起動
2. `nvidia-smi` で GPU 認識を確認
3. `ollama pull qwen2.5:0.5b` → `ollama run qwen2.5:0.5b "hello"` で応答確認

### Windows (WSL2 + GPU)
1. WSL2 内で `nvidia-smi` が動作することを確認
2. `bash scripts/gpu/start-ollama.sh` で GPU 検出 + サーバ起動
3. モデル実行テスト

### macOS
1. ホスト側で `brew install ollama && ollama serve` を実行
2. コンテナ内で `OLLAMA_HOST=http://host.docker.internal:11434 ollama list` が応答することを確認
3. モデル実行テスト
