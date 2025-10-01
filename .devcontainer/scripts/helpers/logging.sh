#!/usr/bin/env bash
# logging.sh
# 共通のログ出力ユーティリティと存在確認ヘルパ。

info() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
}

err() {
  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"
}

have() {
  command -v "$1" >/dev/null 2>&1
}
