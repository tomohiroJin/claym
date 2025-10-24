#!/usr/bin/env bash
# =============================================================================
# Scripts 共通ライブラリ
# =============================================================================
#
# このファイルは、scripts/ 配下のすべてのシェルスクリプトで共有される
# 共通機能（色付き出力、ログ関数）を提供します。
#
# 使い方:
#   SCRIPTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
#   source "${SCRIPTS_ROOT}/lib/common.sh"
#
# DRY原則:
#   このライブラリを作成することで、各スクリプトでの色定義とログ関数の
#   重複を排除します。
#
# =============================================================================

# =============================================================================
# 色定義（ANSI エスケープシーケンス）
# =============================================================================

# 色の有効化フラグ（環境変数で制御可能）
: "${USE_COLOR:=true}"

# 色定義
if [[ "${USE_COLOR}" == "true" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'  # No Color
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# =============================================================================
# ログ関数
# =============================================================================

# 情報ログを出力
#
# 引数:
#   $@: ログメッセージ
#
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# 成功ログを出力
#
# 引数:
#   $@: ログメッセージ
#
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# 警告ログを出力
#
# 引数:
#   $@: ログメッセージ
#
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# エラーログを出力
#
# 引数:
#   $@: ログメッセージ
#
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# デバッグログを出力（VERBOSE=true の場合のみ）
#
# 引数:
#   $@: ログメッセージ
#
# グローバル変数:
#   VERBOSE: trueの場合のみデバッグログを出力
#
log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*"
    fi
}

# ステップログを出力（セクション区切り）
#
# 引数:
#   $@: ステップメッセージ
#
log_step() {
    echo ""
    echo -e "${BOLD}${BLUE}>>> $*${NC}"
}

# =============================================================================
# セクション表示ヘルパー
# =============================================================================

# セクションヘッダーを表示
#
# 引数:
#   $1: タイトル
#   $2: (オプション) 幅（デフォルト: 40）
#
show_header() {
    local title="$1"
    local width="${2:-40}"
    local separator
    separator=$(printf '=%.0s' $(seq 1 "$width"))

    echo "$separator"
    printf "  %s\\n" "$title"
    echo "$separator"
    echo ""
}

# セクションフッターを表示
#
# 引数:
#   $1: メッセージ
#   $2: (オプション) 幅（デフォルト: 40）
#
show_footer() {
    local message="$1"
    local width="${2:-40}"
    local separator
    separator=$(printf '=%.0s' $(seq 1 "$width"))

    echo ""
    echo "$separator"
    echo -e "  ${message}"
    echo "$separator"
    echo ""
}

# =============================================================================
# ライブラリロード確認
# =============================================================================

# このライブラリがロードされたことを示すフラグ
readonly SCRIPTS_COMMON_LIB_LOADED=true
