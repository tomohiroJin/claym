#!/usr/bin/env bash
# =============================================================================
# セットアップスクリプト共通ヘルパー関数
# =============================================================================
#
# このファイルは、セットアップスクリプト間で共有される共通機能を提供します。
#
# 使い方:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
#
# リファクタリング適用パターン:
# - Extract Function: 重複するログ関数とパス取得ロジックを抽出
# - Extract Variable: 色定数とプロジェクトパスを抽出
# - Single Responsibility: 各関数が単一の責任を持つ
#
# =============================================================================

# =============================================================================
# 定数定義
# =============================================================================

# 色付き出力の定義
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# プロジェクトパスの取得
# 注: この変数は各スクリプトから呼び出されることを想定
get_project_root() {
    local script_dir="$1"
    cd "${script_dir}/../.." && pwd
}

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
    echo -e "${RED}[ERROR]${NC} $*"
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
# ファイル操作ヘルパー
# =============================================================================

# ファイルが存在しない場合のみコピー
#
# 引数:
#   $1: コピー元ファイルパス
#   $2: コピー先ファイルパス
#   $3: (オプション) 説明メッセージ
#
# 戻り値:
#   0: 常に成功（警告のみで処理を継続）
#
copy_file_if_not_exists() {
    local src="$1"
    local dst="$2"
    local description="${3:-ファイル}"

    if [[ ! -f "${dst}" ]]; then
        if [[ -f "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp "${src}" "${dst}"
            log_success "${description}を作成しました: ${dst}"
        else
            log_warn "${description}のテンプレートが見つかりません: ${src}"
        fi
    else
        log_info "${description}は既に存在します（スキップ）: ${dst}"
    fi

    # 警告のみでスクリプトは継続（テンプレート欠損でセットアップ失敗を避ける）
    return 0
}

# 安全にディレクトリをコピー（dotglob対応）
#
# 引数:
#   $1: コピー元ディレクトリパス
#   $2: コピー先ディレクトリパス
#
# 戻り値:
#   0: コピー成功
#   1: コピー元が存在しない
#
copy_directory_safe() {
    local src="$1"
    local dst="$2"

    if [[ ! -d "${src}" ]]; then
        return 1
    fi

    mkdir -p "${dst}"

    # dotglob を一時的に有効化して隠しファイルもコピー
    shopt -s dotglob
    cp -r "${src}/"* "${dst}/" 2>/dev/null || true
    shopt -u dotglob

    return 0
}

# =============================================================================
# テンプレート操作ヘルパー
# =============================================================================

# 公式テンプレートとローカルテンプレートをマージ
#
# この関数は、公式テンプレートをまずコピーし、その後ローカルテンプレートで
# 上書きすることで、カスタマイズを保持しながらテンプレートを適用します。
#
# 引数:
#   $1: マージ対象のサブディレクトリ（例: .claude/commands）
#   $2: 公式テンプレートディレクトリ
#   $3: ローカルテンプレートディレクトリ
#   $4: コピー先ディレクトリ
#
# 戻り値:
#   0: 常に成功（警告のみで処理を継続）
#
merge_template_directories() {
    local target_subdir="$1"
    local official_template="$2/${target_subdir}"
    local local_template="$3/${target_subdir}"
    local destination="$4/${target_subdir}"

    log_debug "テンプレートをマージ中: ${target_subdir}"

    # 1. 公式テンプレートをコピー
    if copy_directory_safe "${official_template}" "${destination}"; then
        log_debug "公式テンプレートをコピーしました: ${official_template}"
    else
        log_debug "公式テンプレートが存在しません: ${official_template}"
    fi

    # 2. ローカルテンプレートで上書き（存在する場合）
    if copy_directory_safe "${local_template}" "${destination}"; then
        log_success "ローカルテンプレートを適用しました: ${local_template}"
    fi

    # 公式テンプレートが存在しない場合でもエラーにしない
    return 0
}

# =============================================================================
# 環境変数チェックヘルパー
# =============================================================================

# APIキーの存在確認（警告のみ）
#
# 引数:
#   $@: 確認する環境変数名のリスト
#
# 戻り値:
#   0: 常に成功（警告のみで処理を継続）
#
check_api_keys() {
    local missing_vars=()

    for var_name in "$@"; do
        if [[ -z "${!var_name:-}" ]]; then
            missing_vars+=("${var_name}")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_warn "以下の環境変数が設定されていません:"
        for var in "${missing_vars[@]}"; do
            log_warn "  - ${var}"
        done
        log_info "必要に応じて .env ファイルに設定してください"
    else
        log_success "必要な環境変数が設定されています"
    fi

    # 警告のみでスクリプトは継続（初期セットアップ時はAPIキー未設定が普通）
    return 0
}

# =============================================================================
# .gitignore 更新ヘルパー
# =============================================================================

# .gitignore にエントリを追加（重複チェック付き）
#
# 引数:
#   $1: .gitignore ファイルパス
#   $2: チェック用の文字列（コメントなど）
#   $@: 追加するエントリの配列（シフト後）
#
# 戻り値:
#   0: 追加成功または既に存在
#
update_gitignore_safe() {
    local gitignore="$1"
    local check_string="$2"
    shift 2
    local entries=("$@")

    # .gitignore が存在しない場合は作成
    if [[ ! -f "${gitignore}" ]]; then
        touch "${gitignore}"
    fi

    # 既に追加されているかチェック
    if ! grep -q "${check_string}" "${gitignore}"; then
        for entry in "${entries[@]}"; do
            echo "${entry}" >> "${gitignore}"
        done
        log_success ".gitignore を更新しました"
        return 0
    else
        log_info ".gitignore は既に更新されています（スキップ）"
        return 0
    fi
}

# =============================================================================
# ファイルパス置換ヘルパー
# =============================================================================

# ファイル内のプレースホルダーを置換
#
# 引数:
#   $1: 対象ファイルパス
#   $2: 置換前の文字列
#   $3: 置換後の文字列
#
# 戻り値:
#   0: 置換成功
#   1: ファイルが存在しない
#
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"

    if [[ ! -f "${file}" ]]; then
        log_error "ファイルが見つかりません: ${file}"
        return 1
    fi

    sed -i "s|${search}|${replace}|g" "${file}"
    log_debug "置換しました: ${search} -> ${replace}"
    return 0
}

# =============================================================================
# ディレクトリカウントヘルパー
# =============================================================================

# ディレクトリ内のファイル数をカウント
#
# 引数:
#   $1: ディレクトリパス
#   $2: (オプション) パターン（例: "*.md"）
#
# 出力:
#   ファイル数
#
count_files_in_directory() {
    local dir="$1"
    local pattern="${2:-*}"

    if [[ ! -d "${dir}" ]]; then
        echo "0"
        return 0
    fi

    find "${dir}" -name "${pattern}" -type f | wc -l
}

# =============================================================================
# ヘッダー/フッター表示ヘルパー
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
    local separator=$(printf '=%.0s' $(seq 1 $width))

    echo "${separator}"
    printf "  %s\n" "${title}"
    echo "${separator}"
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
    local separator=$(printf '=%.0s' $(seq 1 $width))

    echo ""
    echo "${separator}"
    echo -e "  ${message}"
    echo "${separator}"
    echo ""
}
