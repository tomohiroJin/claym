#!/usr/bin/env bats
# =============================================================================
# template-genericity.bats
# テンプレートの汎用性チェック（技術スタック非依存の検証）
# =============================================================================
#
# テンプレートが特定の技術スタックに依存しすぎず、
# 汎用的に使える構成になっているかを検証。
#
# テスト数: 8

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'template_test_helper'

# ==============================================================================
# メイン設定の条件付き記述（TypeScript 言及時）
# ==============================================================================

@test "CLAUDE.md: TypeScript 言及時に条件付き表現がある" {
    # TypeScript への言及がなければ問題なし
    if grep -q "TypeScript" "${CLAUDE_MD}" 2>/dev/null; then
        grep -q "該当プロジェクトの場合" "${CLAUDE_MD}"
    fi
}

@test "AGENTS.md: TypeScript 言及時に条件付き表現がある" {
    if grep -q "TypeScript" "${CODEX_MD}" 2>/dev/null; then
        grep -q "該当プロジェクトの場合" "${CODEX_MD}"
    fi
}

@test "GEMINI.md: TypeScript 言及時に条件付き表現がある" {
    if grep -q "TypeScript" "${GEMINI_MD}" 2>/dev/null; then
        grep -q "該当プロジェクトの場合" "${GEMINI_MD}"
    fi
}

# ==============================================================================
# ルールファイルの条件付き表現
# ==============================================================================

@test "coding-style.md に条件付き表現が含まれる" {
    local file="${CLAUDE_RULES_DIR}/coding-style.md"
    grep -q "に応じて\|該当プロジェクトの場合" "$file"
}

@test "testing.md に条件付き表現が含まれる" {
    local file="${CLAUDE_RULES_DIR}/testing.md"
    grep -q "に応じて\|該当プロジェクトの場合" "$file"
}

# ==============================================================================
# コード例の言語非依存
# ==============================================================================

@test "CLAUDE.md で typescript コードブロックが使われていない" {
    ! grep -q '```typescript' "${CLAUDE_MD}"
}

@test "AGENTS.md で typescript コードブロックが使われていない" {
    ! grep -q '```typescript' "${CODEX_MD}"
}

@test "GEMINI.md で typescript コードブロックが使われていない" {
    ! grep -q '```typescript' "${GEMINI_MD}"
}
