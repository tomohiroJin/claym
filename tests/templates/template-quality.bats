#!/usr/bin/env bats
# =============================================================================
# template-quality.bats
# AI CLI テンプレートの品質検証テスト
# =============================================================================
#
# テンプレートファイルの品質を検証:
# - 非空チェック（全ファイル）
# - YAML 必須フィールド（エージェント）
# - Markdown 構造（コマンド・ルール）
# - 共通ルールの一貫性（3 CLI の rules/ 配下）
#
# テスト数: 21

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'template_test_helper'

# ==============================================================================
# 非空チェック
# ==============================================================================

@test "Claude エージェント（YAML）が非空である" {
    check_files_non_empty "${CLAUDE_AGENTS_DIR}" "*.yaml"
}

@test "Claude コマンド（MD）が非空である" {
    check_files_non_empty "${CLAUDE_COMMANDS_DIR}" "*.md"
}

@test "Claude ルール（MD）が非空である" {
    check_files_non_empty "${CLAUDE_RULES_DIR}" "*.md"
}

@test "Codex プロンプト（MD）が非空である" {
    check_files_non_empty "${CODEX_PROMPTS_DIR}" "*.md"
}

@test "Codex インストラクション（MD）が非空である" {
    check_files_non_empty "${CODEX_INSTRUCTIONS_DIR}" "*.md"
}

@test "Gemini コマンド（MD）が非空である" {
    check_files_non_empty "${GEMINI_COMMANDS_DIR}" "*.md"
}

@test "Gemini ルール（MD）が非空である" {
    check_files_non_empty "${GEMINI_RULES_DIR}" "*.md"
}

@test "メイン設定ファイルが非空である" {
    [[ -s "${CLAUDE_MD}" ]]
    [[ -s "${CODEX_MD}" ]]
    [[ -s "${GEMINI_MD}" ]]
}

# ==============================================================================
# YAML 必須フィールド
# ==============================================================================

@test "architect.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/architect.yaml" "name" "prompt"
}

@test "planner.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/planner.yaml" "name" "prompt"
}

@test "build-error-resolver.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/build-error-resolver.yaml" "name" "prompt"
}

@test "security-reviewer.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/security-reviewer.yaml" "name" "prompt"
}

# ==============================================================================
# Markdown 見出し構造
# ==============================================================================

@test "Claude コマンドが正しい Markdown 構造を持つ" {
    local commands=("plan" "build-fix" "refactor" "checkpoint" "tdd" "test-coverage")
    local all_valid=true

    for cmd in "${commands[@]}"; do
        local file="${CLAUDE_COMMANDS_DIR}/${cmd}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "Claude ルールが正しい Markdown 構造を持つ" {
    local rules=("coding-style" "git-workflow" "testing" "security")
    local all_valid=true

    for rule in "${rules[@]}"; do
        local file="${CLAUDE_RULES_DIR}/${rule}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "Codex インストラクションが正しい Markdown 構造を持つ" {
    local instructions=("coding-style" "git-workflow" "testing" "security")
    local all_valid=true

    for instr in "${instructions[@]}"; do
        local file="${CODEX_INSTRUCTIONS_DIR}/${instr}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "Gemini ルールが正しい Markdown 構造を持つ" {
    local rules=("coding-style" "git-workflow" "testing" "security")
    local all_valid=true

    for rule in "${rules[@]}"; do
        local file="${GEMINI_RULES_DIR}/${rule}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "メイン設定ファイルが正しい Markdown 構造を持つ" {
    local all_valid=true
    local files=("${CLAUDE_MD}" "${CODEX_MD}" "${GEMINI_MD}")

    for file in "${files[@]}"; do
        if ! check_markdown_has_headings "$file"; then
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

# ==============================================================================
# 共通ルールの一貫性
#
# 2層構造への再構成（ADR-0001）により、コーディング規約はメイン設定ファイルの
# 「### 共通原則」から各 CLI の rules/ 配下へ分離された。
# 分離後も 3 CLI 間で内容が同期していることを検証する。
# ==============================================================================

@test "共通ルール coding-style.md が 3 CLI すべてに存在する" {
    local all_exist=true
    local file

    for file in "${CLAUDE_CODING_STYLE}" "${CODEX_CODING_STYLE}" "${GEMINI_CODING_STYLE}"; do
        if [[ ! -s "$file" ]]; then
            echo "# 共通ルールが存在しないか空です: ${file}" >&3
            all_exist=false
        fi
    done

    [[ "$all_exist" == "true" ]]
}

@test "Claude の共通ルールのみ frontmatter を持つ" {
    # Claude Code は frontmatter の paths で条件ロードするため必須。
    # Codex / Gemini は frontmatter を解釈しないため付けない。
    if ! head -n 1 "${CLAUDE_CODING_STYLE}" | grep -q '^---$'; then
        echo "# Claude ルールに frontmatter がありません: ${CLAUDE_CODING_STYLE}" >&3
        false
    fi

    local file
    for file in "${CODEX_CODING_STYLE}" "${GEMINI_CODING_STYLE}"; do
        if head -n 1 "$file" | grep -q '^---$'; then
            echo "# frontmatter は Claude 用のみに付与してください: ${file}" >&3
            false
        fi
    done
}

@test "共通ルールの箇条書きが 3 CLI で同数である" {
    local claude_count codex_count gemini_count

    claude_count=$(count_rule_bullets "${CLAUDE_CODING_STYLE}")
    codex_count=$(count_rule_bullets "${CODEX_CODING_STYLE}")
    gemini_count=$(count_rule_bullets "${GEMINI_CODING_STYLE}")

    if [[ "$claude_count" -eq 0 ]]; then
        echo "# Claude の共通ルールに箇条書きがありません" >&3
        false
    fi
    if [[ "$codex_count" -ne "$claude_count" ]]; then
        echo "# Codex の箇条書き: ${codex_count}項目（期待: ${claude_count}）" >&3
        false
    fi
    if [[ "$gemini_count" -ne "$claude_count" ]]; then
        echo "# Gemini の箇条書き: ${gemini_count}項目（期待: ${claude_count}）" >&3
        false
    fi
}

@test "3 CLI の共通ルールが同一内容である（frontmatter を除く）" {
    local claude_content codex_content gemini_content

    claude_content=$(extract_rule_body "${CLAUDE_CODING_STYLE}")
    codex_content=$(extract_rule_body "${CODEX_CODING_STYLE}")
    gemini_content=$(extract_rule_body "${GEMINI_CODING_STYLE}")

    if [[ -z "$claude_content" ]]; then
        echo "# Claude の共通ルール本文が空です: ${CLAUDE_CODING_STYLE}" >&3
        false
    fi
    if [[ "$claude_content" != "$codex_content" ]]; then
        echo "# Claude と Codex の共通ルールが一致しません" >&3
        false
    fi
    if [[ "$claude_content" != "$gemini_content" ]]; then
        echo "# Claude と Gemini の共通ルールが一致しません" >&3
        false
    fi
}
