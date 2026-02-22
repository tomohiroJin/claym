#!/usr/bin/env bash
# =============================================================================
# template_test_helper.bash
# テンプレートテスト専用ヘルパー
# =============================================================================
#
# テンプレートファイルの静的検証に特化したヘルパー関数群。
# 既存の tests/setup/test_helper.bash とは関心事が異なるため分離。
#
# - tests/setup/test_helper.bash: 一時ディレクトリ + 関数シミュレーション
# - このファイル: 実ファイルの静的検証（存在・内容・構造）
#
# =============================================================================

# プロジェクトルートの自動検出
PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
readonly PROJECT_ROOT

# テンプレートディレクトリ
TEMPLATES_DIR="${PROJECT_ROOT}/templates"
readonly TEMPLATES_DIR

# 各ツールのディレクトリ
CLAUDE_AGENTS_DIR="${TEMPLATES_DIR}/.claude/agents"
CLAUDE_COMMANDS_DIR="${TEMPLATES_DIR}/.claude/commands"
CLAUDE_RULES_DIR="${TEMPLATES_DIR}/.claude/rules"
CODEX_PROMPTS_DIR="${TEMPLATES_DIR}/.codex/prompts"
GEMINI_COMMANDS_DIR="${TEMPLATES_DIR}/.gemini/commands"
readonly CLAUDE_AGENTS_DIR CLAUDE_COMMANDS_DIR CLAUDE_RULES_DIR
readonly CODEX_PROMPTS_DIR GEMINI_COMMANDS_DIR

# メイン設定ファイルパス
CLAUDE_MD="${TEMPLATES_DIR}/.claude/CLAUDE.md"
CODEX_MD="${TEMPLATES_DIR}/.codex/AGENTS.md"
GEMINI_MD="${TEMPLATES_DIR}/.gemini/GEMINI.md"
readonly CLAUDE_MD CODEX_MD GEMINI_MD

# init スクリプトパス
INIT_SCRIPT="${PROJECT_ROOT}/scripts/setup/init-ai-configs.sh"
readonly INIT_SCRIPT

# =============================================================================
# ヘルパー関数
# =============================================================================

# 配列内の全ファイルが指定ディレクトリに存在するか確認
#
# 引数:
#   $1: ベースディレクトリ
#   $2: ファイル拡張子（例: .yaml, .md）
#   $3..: ファイル名リスト（拡張子なし）
#
check_files_exist() {
    local base_dir="$1"
    local extension="$2"
    shift 2
    local files=("$@")
    local all_exist=true

    for file in "${files[@]}"; do
        local full_path="${base_dir}/${file}${extension}"
        if [[ ! -f "$full_path" ]]; then
            echo "# ファイルが見つかりません: ${full_path}" >&3
            all_exist=false
        fi
    done

    [[ "$all_exist" == "true" ]]
}

# 指定ディレクトリ配下の全ファイルが非空であるか確認
#
# 引数:
#   $1: ディレクトリパス
#   $2: ファイルパターン（例: *.yaml, *.md）
#
check_files_non_empty() {
    local dir="$1"
    local pattern="$2"
    local all_non_empty=true

    while IFS= read -r -d '' file; do
        if [[ ! -s "$file" ]]; then
            echo "# 空ファイル: ${file}" >&3
            all_non_empty=false
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -print0 2>/dev/null)

    [[ "$all_non_empty" == "true" ]]
}

# YAML ファイルに必須フィールドが存在するか確認
#
# 引数:
#   $1: YAML ファイルパス
#   $2..: 必須フィールド名リスト
#
check_yaml_required_fields() {
    local file="$1"
    shift
    local fields=("$@")
    local all_found=true

    for field in "${fields[@]}"; do
        if ! grep -q "^${field}:" "$file" 2>/dev/null; then
            echo "# 必須フィールド '${field}:' が見つかりません: ${file}" >&3
            all_found=false
        fi
    done

    [[ "$all_found" == "true" ]]
}

# Markdown ファイルに h1/h2 見出し構造があるか確認
#
# 引数:
#   $1: Markdown ファイルパス
#
check_markdown_has_headings() {
    local file="$1"

    if ! grep -q "^# " "$file" 2>/dev/null; then
        echo "# h1 見出しが見つかりません: ${file}" >&3
        return 1
    fi

    if ! grep -q "^## " "$file" 2>/dev/null; then
        echo "# h2 見出しが見つかりません: ${file}" >&3
        return 1
    fi

    return 0
}

# 「共通原則」セクションの内容を抽出する
#
# 引数:
#   $1: ファイルパス
#
# 出力: 共通原則セクションの箇条書き部分
#
extract_common_principles() {
    local file="$1"
    # 「### 共通原則」から次の「###」行（または EOF）までの箇条書きを抽出
    sed -n '/^### 共通原則$/,/^### /{/^### 共通原則$/d;/^### /d;/^$/d;p}' "$file"
}
