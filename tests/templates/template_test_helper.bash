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
CODEX_INSTRUCTIONS_DIR="${TEMPLATES_DIR}/.codex/instructions"
GEMINI_COMMANDS_DIR="${TEMPLATES_DIR}/.gemini/commands"
GEMINI_RULES_DIR="${TEMPLATES_DIR}/.gemini/rules"
SKILLS_DIR="${TEMPLATES_DIR}/skills"
readonly CLAUDE_AGENTS_DIR CLAUDE_COMMANDS_DIR CLAUDE_RULES_DIR
readonly CODEX_PROMPTS_DIR CODEX_INSTRUCTIONS_DIR
readonly GEMINI_COMMANDS_DIR GEMINI_RULES_DIR SKILLS_DIR

# メイン設定ファイルパス
CLAUDE_MD="${TEMPLATES_DIR}/.claude/CLAUDE.md"
CODEX_MD="${TEMPLATES_DIR}/.codex/AGENTS.md"
GEMINI_MD="${TEMPLATES_DIR}/.gemini/GEMINI.md"
readonly CLAUDE_MD CODEX_MD GEMINI_MD

# 3 CLI に同期配置される共通ルール
# 2層構造への再構成により、コーディング規約はメイン設定ファイルから
# 各 CLI の rules/ 配下へ分離された（ADR-0001）
CLAUDE_CODING_STYLE="${CLAUDE_RULES_DIR}/coding-style.md"
CODEX_CODING_STYLE="${CODEX_INSTRUCTIONS_DIR}/coding-style.md"
GEMINI_CODING_STYLE="${GEMINI_RULES_DIR}/coding-style.md"
readonly CLAUDE_CODING_STYLE CODEX_CODING_STYLE GEMINI_CODING_STYLE

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

# ルールファイルから frontmatter を除いた本文を抽出する
#
# Claude 用ルールのみ frontmatter（description / alwaysApply / paths）を持つため、
# 3 CLI 間で本文を比較するには除去が必要。
#
# 引数:
#   $1: ファイルパス
#
# 出力: frontmatter と直後の空行を除いた本文
#
extract_rule_body() {
    local file="$1"
    awk '
        NR == 1 && /^---$/       { in_fm = 1; next }
        in_fm == 1               { if (/^---$/) { in_fm = 0; after_fm = 1 } next }
        after_fm == 1 && /^$/    { after_fm = 0; next }
                                 { after_fm = 0; print }
    ' "$file"
}

# ルールファイル本文の箇条書き項目数を数える
#
# 引数:
#   $1: ファイルパス
#
count_rule_bullets() {
    local file="$1"
    extract_rule_body "$file" | grep -c '^- ' || true
}
