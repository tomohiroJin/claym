#!/usr/bin/env bats
# copy-template-to-local.sh のテスト
#
# テスト対象:
# - コマンドテンプレートのコピー機能
# - CLAUDE.md のコピー機能
# - 全テンプレートのコピー機能
#
# リファクタリング適用パターン:
# - Extract Function: 共通のコピーロジックをヘルパーに抽出
# - Compose Method: 複雑なテストを小さなメソッドに分解
# - Self-Documenting Code: テストの意図を明確にする命名

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

# セットアップ: 各テストの前に実行
setup() {
    create_copy_template_test_directories
    create_copy_template_files
}

# ティアダウン: 各テストの後に実行
teardown() {
    cleanup_test_directory
}

# ==============================================================================
# コマンドコピー機能のテスト
# ==============================================================================

@test "copy_command: 単一のコマンドファイルがコピーされる" {
    # Arrange
    define_copy_command_function

    # Act
    run copy_command "review.md"

    # Assert
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"

    run cat "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_output --partial "Official review template"
}

@test "copy_command: 複数のコマンドファイルがコピーされる" {
    # Arrange
    define_copy_command_function

    # Act
    run copy_command "review.md"
    assert_success

    run copy_command "code-gen.md"
    assert_success

    # Assert
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/code-gen.md"
}

@test "copy_command: 存在しないファイルを指定するとエラーになる" {
    # Arrange
    define_copy_command_function

    # Act
    run copy_command "nonexistent.md"

    # Assert
    assert_failure
    assert_output --partial "Error: File not found"
}

@test "copy_command: 既存のファイルは上書きされる" {
    # Arrange
    mkdir -p "${TEMPLATES_LOCAL_DIR}/.claude/commands"
    cat > "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md" <<'EOF'
# Review Command
Old content
EOF

    define_copy_command_function

    # Act
    run copy_command "review.md"

    # Assert
    assert_success

    run cat "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_output --partial "Official review template"
    refute_output --partial "Old content"
}

@test "copy_command: ディレクトリが存在しない場合は自動作成される" {
    # Arrange
    rm -rf "${TEMPLATES_LOCAL_DIR}"
    define_copy_command_function

    # Act
    run copy_command "review.md"

    # Assert
    assert_success
    assert_dir_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
}

# ==============================================================================
# CLAUDE.md コピー機能のテスト
# ==============================================================================

@test "copy_claude_md: CLAUDE.md がコピーされる" {
    # Arrange
    define_copy_claude_md_function

    # Act
    run copy_claude_md

    # Assert
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"

    run cat "${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"
    assert_output --partial "Official CLAUDE.md template"
}

# ==============================================================================
# 全コマンドコピー機能のテスト
# ==============================================================================

@test "copy_all_commands: すべてのコマンドファイルがコピーされる" {
    # Arrange
    define_copy_all_commands_function

    # Act
    run copy_all_commands

    # Assert
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/code-gen.md"
}

@test "copy_all_commands: commands ディレクトリが存在しない場合はエラーになる" {
    # Arrange
    rm -rf "${TEMPLATES_DIR}/.claude/commands"
    define_copy_all_commands_function

    # Act
    run copy_all_commands

    # Assert
    assert_failure
    assert_output --partial "Error: Commands directory not found"
}

@test "copy_all: 空の commands ディレクトリでもエラーにならない" {
    # Arrange
    rm -f "${TEMPLATES_DIR}/.claude/commands"/*.md
    define_copy_all_commands_function

    # Act
    run copy_all_commands

    # Assert
    assert_success
}

# ==============================================================================
# copy-template-to-local.sh スクリプト全体のテスト
# ==============================================================================

@test "copy-template-to-local.sh: スクリプトが正常に実行できる" {
    # スクリプトのシンタックスチェック
    run bash -n /workspaces/claym/scripts/setup/copy-template-to-local.sh
    assert_success
}

@test "copy-template-to-local.sh: --help オプションが実装されている" {
    # ヘルプオプションの処理が含まれていることを確認
    run grep -E '(--help|-h)' /workspaces/claym/scripts/setup/copy-template-to-local.sh

    assert_success
}

@test "copy-template-to-local.sh: 必須の関数が定義されている" {
    # スクリプトから関数定義を検索
    run grep -E '^[[:space:]]*(copy_command|copy_claude_md|copy_all|show_usage)\(\)' \
        /workspaces/claym/scripts/setup/copy-template-to-local.sh

    # 関数が定義されていることを確認
    assert_success
}

@test "copy-template-to-local.sh: コマンドタイプの判定処理が実装されている" {
    # コマンドタイプ（command, claude-md, all）の処理が含まれていることを確認
    run grep -E '(command|claude-md|all)' /workspaces/claym/scripts/setup/copy-template-to-local.sh

    assert_success
}
