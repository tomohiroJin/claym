# GPU セットアップガイド（Ollama + ローカル LLM）

## 概要

Claym DevContainer には [Ollama](https://ollama.com/) CLI がプリインストールされており、ローカル LLM をコンテナ内で実行できます。

- **GPU モード**: NVIDIA GPU を持つ Linux / Windows (WSL2) 環境で、高速な推論が可能です
- **CPU モード**: すべての OS で利用可能です（推論速度は低下します）
- **ホスト接続モード**: macOS など GPU パススルーが利用できない環境では、ホスト側で Ollama を実行し、コンテナから接続できます

### OS 別サポート状況

| 項目 | Linux | Windows (WSL2) | macOS |
|------|-------|---------------|-------|
| GPU パススルー | nvidia-container-toolkit で対応 | WSL2 経由で NVIDIA GPU 対応 | Docker Desktop では非対応 |
| 対応 GPU | NVIDIA（CUDA 対応） | NVIDIA（CUDA 対応） | なし（Apple Silicon 含む） |
| 推奨モード | GPU モード | GPU モード（WSL2 経由） | ホスト接続モード |

## OS 別セットアップ

### Linux

#### 前提条件

- NVIDIA GPU（CUDA 対応）
- NVIDIA ドライバ（バージョン 525 以上推奨）
- nvidia-container-toolkit

#### nvidia-container-toolkit のインストール

> 公式ドキュメント: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

```bash
# NVIDIA Container Toolkit リポジトリの追加
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# インストール
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Docker ランタイムの設定
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

#### devcontainer.local.json の設定

プロジェクトルートに `.devcontainer/devcontainer.local.json` を作成します：

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

#### 動作確認

```bash
# コンテナ内で GPU が認識されていることを確認
nvidia-smi

# Ollama サーバを起動
bash scripts/gpu/start-ollama.sh

# モデルをダウンロードして実行
ollama pull qwen2.5:0.5b
ollama run qwen2.5:0.5b "Hello"
```

### Windows (WSL2)

#### 前提条件

- Windows 10/11（バージョン 21H2 以上）
- WSL2 が有効化済み
- Docker Desktop（WSL2 バックエンド）
- NVIDIA Game Ready / Studio Driver（WSL2 対応版、バージョン 525 以上推奨）

#### WSL2 での NVIDIA GPU サポートの確認

```powershell
# PowerShell で WSL2 内の nvidia-smi を確認
wsl nvidia-smi
```

GPU 情報が表示されれば、WSL2 から GPU にアクセスできています。

#### Docker Desktop の GPU 設定

1. Docker Desktop の Settings を開く
2. **Resources > WSL Integration** で使用する WSL ディストリビューションを有効化
3. Docker Desktop を再起動

#### devcontainer.local.json の設定

Linux と同じ設定を使用します：

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

#### 動作確認

Linux と同じ手順で確認できます。

#### 制約事項

- GPU メモリは WSL2 とホスト Windows で共有されます
- ホスト側で GPU を多用するアプリケーション（ゲームなど）が動作中は、推論速度が低下する場合があります
- WSL2 のメモリ制限（`.wslconfig` で設定可能）に注意してください

### macOS

#### 現状の制約

- Docker Desktop for Mac では GPU パススルーに対応していません
- Apple Silicon (M1/M2/M3/M4) チップを搭載していても、Docker コンテナ内から GPU を利用することはできません
- コンテナ内で CPU モードとして Ollama を実行することは可能ですが、推論速度は低速です

#### 推奨: ホスト側 Ollama に接続

macOS では、ホスト側で Ollama を直接実行し、コンテナからネットワーク経由で接続する方式を推奨します。

**ホスト側での準備:**

```bash
# Homebrew で Ollama をインストール
brew install ollama

# Ollama サーバを起動（Apple Silicon の GPU が自動的に使用されます）
ollama serve
```

**devcontainer.local.json の設定:**

```json
{
  "remoteEnv": {
    "OLLAMA_HOST": "http://host.docker.internal:11434"
  }
}
```

**動作確認:**

```bash
# コンテナ内からホスト側の Ollama に接続できることを確認
ollama list
ollama run qwen2.5:0.5b "Hello"
```

## Ollama の使い方（共通）

### 起動スクリプト

```bash
# GPU 検出 + サーバ起動
bash scripts/gpu/start-ollama.sh

# CPU モードで強制起動
bash scripts/gpu/start-ollama.sh --cpu

# GPU 検出のみ（サーバは起動しない）
bash scripts/gpu/start-ollama.sh --check
```

### モデルのダウンロードと実行

```bash
# モデルのダウンロード
ollama pull <モデル名>

# モデルの実行（対話モード）
ollama run <モデル名>

# モデルの実行（ワンショット）
ollama run <モデル名> "質問内容"

# ダウンロード済みモデルの一覧
ollama list

# モデルの削除
ollama rm <モデル名>
```

### よく使うモデル一覧

| モデル | サイズ | 用途 | コマンド |
|--------|--------|------|----------|
| qwen2.5:0.5b | ~400MB | テスト・動作確認用（軽量） | `ollama pull qwen2.5:0.5b` |
| qwen2.5:3b | ~2GB | 軽量な日本語タスク | `ollama pull qwen2.5:3b` |
| qwen2.5:7b | ~4.5GB | バランスの取れた汎用モデル | `ollama pull qwen2.5:7b` |
| codellama:7b | ~3.8GB | コード生成・補完 | `ollama pull codellama:7b` |
| llama3.2:3b | ~2GB | 英語タスク（軽量） | `ollama pull llama3.2:3b` |

> **注意**: モデルのダウンロードにはストレージ容量とネットワーク帯域が必要です。コンテナのディスク容量に余裕があることを確認してください。

## devcontainer.local.json のサンプル

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

### GPU なし / macOS（ホスト Ollama 接続）

```json
{
  "remoteEnv": {
    "OLLAMA_HOST": "http://host.docker.internal:11434"
  }
}
```

## トラブルシューティング

### GPU が検出されない

1. **ホスト側でドライバを確認**: `nvidia-smi` がホスト側で動作するか確認してください
2. **nvidia-container-toolkit の確認**: `nvidia-ctk --version` で存在を確認してください
3. **devcontainer.local.json の確認**: `--gpus=all` が `runArgs` に含まれているか確認してください
4. **コンテナの再ビルド**: 設定変更後は **Dev Containers: Rebuild Container** を実行してください

### Ollama サーバが起動しない

```bash
# ログを確認
cat /tmp/ollama.log

# ポートの競合を確認
lsof -i :11434

# 手動で起動を試みる
ollama serve
```

### メモリ不足

- より小さなモデルを使用してください（例: `qwen2.5:0.5b`）
- コンテナの `--shm-size` を増やしてください（例: `--shm-size=2g`）
- WSL2 の場合は `.wslconfig` でメモリ制限を調整してください

### WSL2 固有の問題

```powershell
# WSL2 のバージョン確認
wsl --version

# WSL2 の再起動
wsl --shutdown
```

- NVIDIA ドライバが WSL2 対応版であることを確認してください
- Docker Desktop の WSL Integration が有効になっていることを確認してください
