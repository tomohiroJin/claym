#!/usr/bin/env bats
# link-ai-configs.sh のテスト
#
# テスト対象:
# - シンボリックリンク作成
# - 既存ディレクトリがある場合のスキップ

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'test_helper'

# ==============================================================================
# セットアップ/ティアダウン
# ==============================================================================

setup() {
    TEST_DIR="$(mktemp -d)"
    SOURCE_ROOT="${TEST_DIR}/source-root"
    TARGET_ROOT="${TEST_DIR}/target-root"

    mkdir -p "${SOURCE_ROOT}/.claude"
    mkdir -p "${SOURCE_ROOT}/.codex"
    mkdir -p "${SOURCE_ROOT}/.gemini"
    touch "${SOURCE_ROOT}/AGENTS.md"

    mkdir -p "${TARGET_ROOT}"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# テストケース
# ==============================================================================

@test "link-ai-configs.sh: 4項目のリンクが作成される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash /workspaces/claym/scripts/setup/link-ai-configs.sh "${TARGET_ROOT}"
    assert_success

    assert_file_exist "${TARGET_ROOT}/AGENTS.md"
    assert_dir_exist "${TARGET_ROOT}/.claude"
    assert_dir_exist "${TARGET_ROOT}/.codex"
    assert_dir_exist "${TARGET_ROOT}/.gemini"

    run readlink "${TARGET_ROOT}/.claude"
    assert_success
    assert_output "${SOURCE_ROOT}/.claude"

    run readlink "${TARGET_ROOT}/.codex"
    assert_success
    assert_output "${SOURCE_ROOT}/.codex"

    run readlink "${TARGET_ROOT}/.gemini"
    assert_success
    assert_output "${SOURCE_ROOT}/.gemini"

    run readlink "${TARGET_ROOT}/AGENTS.md"
    assert_success
    assert_output "${SOURCE_ROOT}/AGENTS.md"
}

@test "link-ai-configs.sh: 既存ディレクトリはスキップされる" {
    mkdir -p "${TARGET_ROOT}/.claude"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash /workspaces/claym/scripts/setup/link-ai-configs.sh "${TARGET_ROOT}"
    assert_success
    assert_output --partial "既に存在するためスキップしました"

    if [[ -L "${TARGET_ROOT}/.claude" ]]; then
        false
    fi
}
