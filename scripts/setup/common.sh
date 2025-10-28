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
# - DRY: 色定義とログ関数を scripts/lib/logging.sh に統合
#
# =============================================================================

# =============================================================================
# 共通ライブラリの読み込み
# =============================================================================

# scripts/lib/logging.sh から色定義とログ関数を読み込み
SETUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SETUP_SCRIPT_DIR

SCRIPTS_ROOT="$(cd "${SETUP_SCRIPT_DIR}/.." && pwd)"
readonly SCRIPTS_ROOT

# ログ出力ライブラリを読み込む
if [[ ! -f "${SCRIPTS_ROOT}/lib/logging.sh" ]]; then
    echo "エラー: ログ出力ライブラリが見つかりません: ${SCRIPTS_ROOT}/lib/logging.sh" >&2
    exit 1
fi

# shellcheck source=../lib/logging.sh
source "${SCRIPTS_ROOT}/lib/logging.sh"

# =============================================================================
# セットアップスクリプト固有の関数
# =============================================================================

# プロジェクトパスの取得
# 注: この変数は各スクリプトから呼び出されることを想定
get_project_root() {
    local script_dir="$1"
    cd "${script_dir}/../.." && pwd
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

# 注: show_header と show_footer は scripts/lib/common.sh で定義されています
