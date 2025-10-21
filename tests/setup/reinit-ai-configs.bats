#!/usr/bin/env bats
# reinit-ai-configs.sh のテスト
#
# テスト対象:
# - バックアップ機能
# - リストア機能
# - templates-local のバックアップ対象への追加
#
# リファクタリング適用パターン:
# - Extract Function: 共通ロジックをヘルパー関数に抽出
# - Introduce Parameter Object: バックアップディレクトリをパラメータ化
# - Replace Temp with Query: 一時的な関数定義をヘルパーに移動

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
    create_backup_test_directories
    create_backup_test_files
}

# ティアダウン: 各テストの後に実行
teardown() {
    cleanup_test_directory
}

# ==============================================================================
# バックアップ機能のテスト
# ==============================================================================

@test "backup: バックアップディレクトリが作成される" {
    # Arrange
    define_backup_files_function

    # Act
    run backup_files "${BACKUP_DIR}"

    # Assert
    assert_success
    assert_dir_exist "${BACKUP_DIR}"
}

@test "backup: .claude/commands ディレクトリがバックアップされる" {
    # Arrange
    define_backup_directory_function

    # Act
    run backup_directory \
        "${PROJECT_ROOT}/.claude/commands" \
        "${BACKUP_DIR}/.claude/commands"

    # Assert
    assert_success
    assert_dir_exist "${BACKUP_DIR}/.claude/commands"
    assert_file_exist "${BACKUP_DIR}/.claude/commands/test.md"

    run cat "${BACKUP_DIR}/.claude/commands/test.md"
    assert_output --partial "Test content"
}

@test "backup: templates-local ディレクトリがバックアップされる" {
    # Arrange
    define_backup_directory_function

    # Act
    run backup_directory \
        "${PROJECT_ROOT}/templates-local" \
        "${BACKUP_DIR}/templates-local"

    # Assert
    assert_success
    assert_dir_exist "${BACKUP_DIR}/templates-local/.claude/commands"
    assert_file_exist "${BACKUP_DIR}/templates-local/.claude/commands/custom.md"

    run cat "${BACKUP_DIR}/templates-local/.claude/commands/custom.md"
    assert_output --partial "Custom content"
}

@test "backup: バックアップ対象のディレクトリが存在しない場合でもエラーにならない" {
    # Arrange
    define_backup_directory_function

    # Act
    run backup_directory \
        "${PROJECT_ROOT}/nonexistent" \
        "${BACKUP_DIR}/nonexistent"

    # Assert
    assert_success
}

@test "backup: 空のディレクトリでもバックアップが成功する" {
    # Arrange
    mkdir -p "${PROJECT_ROOT}/empty-dir"
    define_backup_directory_function

    # Act
    run backup_directory \
        "${PROJECT_ROOT}/empty-dir" \
        "${BACKUP_DIR}/empty-dir"

    # Assert
    assert_success
    assert_dir_exist "${BACKUP_DIR}/empty-dir"
}

# ==============================================================================
# リストア機能のテスト
# ==============================================================================

@test "restore: バックアップからファイルがリストアされる" {
    # Arrange
    create_restore_backup_files "${BACKUP_DIR}"
    rm -rf "${PROJECT_ROOT}/.claude/commands"
    define_restore_directory_function

    # Act
    run restore_directory \
        "${BACKUP_DIR}/.claude/commands" \
        "${PROJECT_ROOT}/.claude/commands"

    # Assert
    assert_success
    assert_dir_exist "${PROJECT_ROOT}/.claude/commands"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/restored.md"

    run cat "${PROJECT_ROOT}/.claude/commands/restored.md"
    assert_output --partial "Restored content"
}

@test "restore: templates-local がリストアされる" {
    # Arrange
    create_restore_custom_backup_files "${BACKUP_DIR}"
    rm -rf "${PROJECT_ROOT}/templates-local"
    define_restore_directory_function

    # Act
    run restore_directory \
        "${BACKUP_DIR}/templates-local" \
        "${PROJECT_ROOT}/templates-local"

    # Assert
    assert_success
    assert_dir_exist "${PROJECT_ROOT}/templates-local/.claude/commands"
    assert_file_exist "${PROJECT_ROOT}/templates-local/.claude/commands/restored-custom.md"

    run cat "${PROJECT_ROOT}/templates-local/.claude/commands/restored-custom.md"
    assert_output --partial "Restored custom content"
}

@test "restore: バックアップが存在しない場合でもエラーにならない" {
    # Arrange
    define_restore_directory_function

    # Act
    run restore_directory \
        "${BACKUP_DIR}/nonexistent" \
        "${PROJECT_ROOT}/restored"

    # Assert
    assert_success
}

@test "restore: 既存のファイルは上書きされる" {
    # Arrange
    mkdir -p "${PROJECT_ROOT}/.claude/commands"
    cat > "${PROJECT_ROOT}/.claude/commands/test.md" <<'EOF'
# Test Command
Old content
EOF

    mkdir -p "${BACKUP_DIR}/.claude/commands"
    cat > "${BACKUP_DIR}/.claude/commands/test.md" <<'EOF'
# Test Command
New content
EOF

    define_restore_directory_function

    # Act
    run restore_directory \
        "${BACKUP_DIR}/.claude/commands" \
        "${PROJECT_ROOT}/.claude/commands"

    # Assert
    assert_success

    run cat "${PROJECT_ROOT}/.claude/commands/test.md"
    assert_output --partial "New content"
    refute_output --partial "Old content"
}

# ==============================================================================
# reinit-ai-configs.sh スクリプト全体のテスト
# ==============================================================================

@test "reinit-ai-configs.sh: スクリプトが正常に実行できる" {
    # スクリプトのシンタックスチェック
    run bash -n /workspaces/claym/scripts/setup/reinit-ai-configs.sh
    assert_success
}

@test "reinit-ai-configs.sh: templates-local がバックアップ対象に含まれている" {
    # スクリプトから backup_dir_targets の定義を抽出
    run grep -A 3 'backup_dir_targets=' /workspaces/claym/scripts/setup/reinit-ai-configs.sh

    # templates-local が含まれていることを確認
    assert_success
    assert_output --partial 'templates-local'
}

@test "reinit-ai-configs.sh: 必須の関数が定義されている" {
    # スクリプトから関数定義を検索
    run grep -E '^[[:space:]]*(backup_files|create_backup|restore_from_backup|main)\(\)' \
        /workspaces/claym/scripts/setup/reinit-ai-configs.sh

    # 関数が定義されていることを確認
    assert_success
}

@test "reinit-ai-configs.sh: --backup-only オプションが実装されている" {
    # --backup-only オプションの処理が含まれていることを確認
    run grep -i 'backup.*only' /workspaces/claym/scripts/setup/reinit-ai-configs.sh

    assert_success
}

@test "reinit-ai-configs.sh: --help オプションが実装されている" {
    # --help オプションの処理が含まれていることを確認
    run grep -E '(--help|-h)' /workspaces/claym/scripts/setup/reinit-ai-configs.sh

    assert_success
}
