#!/usr/bin/env bash
# Ollama サーバ起動スクリプト
#
# GPU を検出し、Ollama サーバをバックグラウンドで起動します。
# GPU がない場合は CPU モードで起動可能であることを案内します。
#
# 使い方:
#   bash scripts/gpu/start-ollama.sh          # GPU 検出 + サーバ起動
#   bash scripts/gpu/start-ollama.sh --cpu    # CPU モードで強制起動
#   bash scripts/gpu/start-ollama.sh --check  # GPU 検出のみ（起動しない）

set -euo pipefail

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Ollama CLI の存在確認 ---
if ! command -v ollama &>/dev/null; then
  error "Ollama CLI が見つかりません。コンテナを再ビルドしてください。"
  exit 1
fi

OLLAMA_VERSION=$(ollama --version 2>/dev/null | head -n1 || echo "不明")
info "Ollama CLI: ${OLLAMA_VERSION}"

# --- GPU 検出 ---
detect_gpu() {
  if command -v nvidia-smi &>/dev/null; then
    if nvidia-smi &>/dev/null; then
      GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 || echo "不明")
      GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -n1 || echo "不明")
      echo "detected"
      return 0
    fi
  fi
  echo "not_detected"
  return 0
}

# --- オプション解析 ---
MODE="auto"
case "${1:-}" in
  --cpu)   MODE="cpu" ;;
  --check) MODE="check" ;;
  --help|-h)
    echo "使い方: bash scripts/gpu/start-ollama.sh [--cpu|--check|--help]"
    echo ""
    echo "オプション:"
    echo "  --cpu    CPU モードで強制起動"
    echo "  --check  GPU 検出のみ（サーバは起動しない）"
    echo "  --help   このヘルプを表示"
    exit 0
    ;;
esac

# --- GPU 検出結果の表示 ---
GPU_STATUS=$(detect_gpu)

if [[ "$GPU_STATUS" == "detected" ]]; then
  info "GPU を検出しました: ${GPU_NAME:-不明} (${GPU_MEMORY:-不明})"
  RUN_MODE="gpu"
else
  warn "GPU が検出されませんでした。"
  if [[ "$MODE" == "auto" ]]; then
    warn "CPU モードで起動します。GPU を使用する場合は以下を確認してください:"
    echo -e "  ${CYAN}1. ホスト側に NVIDIA ドライバがインストールされていること${NC}"
    echo -e "  ${CYAN}2. devcontainer.local.json に \"--gpus=all\" が設定されていること${NC}"
    echo -e "  ${CYAN}詳細: docs/gpu-setup.md${NC}"
  fi
  RUN_MODE="cpu"
fi

# --check モードの場合はここで終了
if [[ "$MODE" == "check" ]]; then
  if [[ "$GPU_STATUS" == "detected" ]]; then
    info "GPU チェック完了: GPU が利用可能です"
  else
    warn "GPU チェック完了: GPU は利用できません（CPU モードで動作可能）"
  fi
  exit 0
fi

# --- 既に起動中かチェック ---
if pgrep -x "ollama" &>/dev/null; then
  warn "Ollama サーバは既に起動中です。"
  info "停止する場合: kill \$(pgrep -x ollama)"
  exit 0
fi

# --- Ollama サーバの起動 ---
info "Ollama サーバを ${RUN_MODE} モードでバックグラウンド起動します..."

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
export OLLAMA_HOST

nohup ollama serve > /tmp/ollama.log 2>&1 &
OLLAMA_PID=$!

# 起動待ち（最大10秒）
for i in $(seq 1 10); do
  if curl -s "${OLLAMA_HOST}/api/tags" &>/dev/null; then
    info "Ollama サーバが起動しました (PID: ${OLLAMA_PID})"
    break
  fi
  if ! kill -0 "$OLLAMA_PID" 2>/dev/null; then
    error "Ollama サーバの起動に失敗しました。ログを確認してください: /tmp/ollama.log"
    exit 1
  fi
  sleep 1
done

# --- 使い方の案内 ---
echo ""
info "=== Ollama の使い方 ==="
echo -e "  ${CYAN}モデルのダウンロード:${NC}  ollama pull qwen2.5:0.5b"
echo -e "  ${CYAN}モデルの実行:${NC}          ollama run qwen2.5:0.5b \"こんにちは\""
echo -e "  ${CYAN}モデル一覧:${NC}            ollama list"
echo -e "  ${CYAN}サーバの停止:${NC}          kill ${OLLAMA_PID}"
echo -e "  ${CYAN}ログの確認:${NC}            cat /tmp/ollama.log"
echo ""
info "OLLAMA_HOST=${OLLAMA_HOST}"
