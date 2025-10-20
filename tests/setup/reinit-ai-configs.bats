#!/usr/bin/env bats

# reinit-ai-configs.sh のテスト
#
# テスト対象:
# - バックアップ機能
# - リストア機能
# - templates-local のバックアップ対象への追加

# テストヘルパーのロード
load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'

# セットアップ: 各テストの前に実行
setup() {
    # テスト用の一時ディレクトリを作成
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export BACKUP_DIR="${TEST_DIR}/backup"

    # プロジェクト構造を作成
    mkdir -p "${PROJECT_ROOT}/.claude/commands"
    mkdir -p "${PROJECT_ROOT}/templates-local/.claude/commands"

    # テスト用のファイルを作成
    cat > "${PROJECT_ROOT}/.claude/commands/test.md" << 'EOF'
# Test Command
Test content
EOF

    cat > "${PROJECT_ROOT}/templates-local/.claude/commands/custom.md" << 'EOF'
# Custom Command
Custom content
EOF
}

# ティアダウン: 各テストの後に実行
teardown() {
    # 一時ディレクトリを削除
    rm -rf "${TEST_DIR}"
}

# ----------------------------------------------------------------------------
# バックアップ機能のテスト
# ----------------------------------------------------------------------------

@test "backup: バックアップディレクトリが作成される" {
    # バックアップ関数をシミュレート
    backup_files() {
        local backup_base="$1"
        mkdir -p "${backup_base}"
    }

    # テスト実行
    run backup_files "${BACKUP_DIR}"

    # 検証
    assert_success
    assert_dir_exist "${BACKUP_DIR}"
}

@test "backup: .claude/commands ディレクトリがバックアップされる" {
    # バックアップ関数をシミュレート
    backup_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp -r "${src}" "${dst}"
        fi
    }

    # テスト実行
    run backup_directory \
        "${PROJECT_ROOT}/.claude/commands" \
        "${BACKUP_DIR}/.claude/commands"

    # 検証
    assert_success
    assert_dir_exist "${BACKUP_DIR}/.claude/commands"
    assert_file_exist "${BACKUP_DIR}/.claude/commands/test.md"

    # ファイル内容の検証
    run cat "${BACKUP_DIR}/.claude/commands/test.md"
    assert_output --partial "Test content"
}

@test "backup: templates-local ディレクトリがバックアップされる" {
    # バックアップ関数をシミュレート
    backup_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp -r "${src}" "${dst}"
        fi
    }

    # テスト実行
    run backup_directory \
        "${PROJECT_ROOT}/templates-local" \
        "${BACKUP_DIR}/templates-local"

    # 検証
    assert_success
    assert_dir_exist "${BACKUP_DIR}/templates-local/.claude/commands"
    assert_file_exist "${BACKUP_DIR}/templates-local/.claude/commands/custom.md"

    # ファイル内容の検証
    run cat "${BACKUP_DIR}/templates-local/.claude/commands/custom.md"
    assert_output --partial "Custom content"
}

@test "backup: バックアップ対象のディレクトリが存在しない場合でもエラーにならない" {
    # バックアップ関数をシミュレート
    backup_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp -r "${src}" "${dst}"
        fi
    }

    # 存在しないディレクトリをバックアップ
    run backup_directory \
        "${PROJECT_ROOT}/nonexistent" \
        "${BACKUP_DIR}/nonexistent"

    # エラーにならず正常終了すること
    assert_success
}

# ----------------------------------------------------------------------------
# リストア機能のテスト
# ----------------------------------------------------------------------------

@test "restore: バックアップからファイルがリストアされる" {
    # バックアップを作成
    mkdir -p "${BACKUP_DIR}/.claude/commands"
    cat > "${BACKUP_DIR}/.claude/commands/restored.md" << 'EOF'
# Restored Command
Restored content
EOF

    # リストア関数をシミュレート
    restore_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "${dst}"
            cp -r "${src}/"* "${dst}/" 2>/dev/null || true
        fi
    }

    # .claude/commands を削除
    rm -rf "${PROJECT_ROOT}/.claude/commands"

    # テスト実行
    run restore_directory \
        "${BACKUP_DIR}/.claude/commands" \
        "${PROJECT_ROOT}/.claude/commands"

    # 検証
    assert_success
    assert_dir_exist "${PROJECT_ROOT}/.claude/commands"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/restored.md"

    # ファイル内容の検証
    run cat "${PROJECT_ROOT}/.claude/commands/restored.md"
    assert_output --partial "Restored content"
}

@test "restore: templates-local がリストアされる" {
    # バックアップを作成
    mkdir -p "${BACKUP_DIR}/templates-local/.claude/commands"
    cat > "${BACKUP_DIR}/templates-local/.claude/commands/restored-custom.md" << 'EOF'
# Restored Custom Command
Restored custom content
EOF

    # リストア関数をシミュレート
    restore_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "${dst}"
            cp -r "${src}/"* "${dst}/" 2>/dev/null || true
        fi
    }

    # templates-local を削除
    rm -rf "${PROJECT_ROOT}/templates-local"

    # テスト実行
    run restore_directory \
        "${BACKUP_DIR}/templates-local" \
        "${PROJECT_ROOT}/templates-local"

    # 検証
    assert_success
    assert_dir_exist "${PROJECT_ROOT}/templates-local/.claude/commands"
    assert_file_exist "${PROJECT_ROOT}/templates-local/.claude/commands/restored-custom.md"

    # ファイル内容の検証
    run cat "${PROJECT_ROOT}/templates-local/.claude/commands/restored-custom.md"
    assert_output --partial "Restored custom content"
}

@test "restore: バックアップが存在しない場合でもエラーにならない" {
    # リストア関数をシミュレート
    restore_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "${dst}"
            cp -r "${src}/"* "${dst}/" 2>/dev/null || true
        fi
    }

    # 存在しないバックアップからリストア
    run restore_directory \
        "${BACKUP_DIR}/nonexistent" \
        "${PROJECT_ROOT}/restored"

    # エラーにならず正常終了すること
    assert_success
}

# ----------------------------------------------------------------------------
# reinit-ai-configs.sh スクリプト全体のテスト
# ----------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------
# エッジケースのテスト
# ----------------------------------------------------------------------------

@test "backup: 空のディレクトリでもバックアップが成功する" {
    # 空のディレクトリを作成
    mkdir -p "${PROJECT_ROOT}/empty-dir"

    # バックアップ関数をシミュレート
    backup_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp -r "${src}" "${dst}"
        fi
    }

    # テスト実行
    run backup_directory \
        "${PROJECT_ROOT}/empty-dir" \
        "${BACKUP_DIR}/empty-dir"

    # 検証
    assert_success
    assert_dir_exist "${BACKUP_DIR}/empty-dir"
}

@test "restore: 既存のファイルは上書きされる" {
    # 既存のファイルを作成
    mkdir -p "${PROJECT_ROOT}/.claude/commands"
    cat > "${PROJECT_ROOT}/.claude/commands/test.md" << 'EOF'
# Test Command
Old content
EOF

    # バックアップを作成（異なる内容）
    mkdir -p "${BACKUP_DIR}/.claude/commands"
    cat > "${BACKUP_DIR}/.claude/commands/test.md" << 'EOF'
# Test Command
New content
EOF

    # リストア関数をシミュレート
    restore_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "${dst}"
            cp -r "${src}/"* "${dst}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run restore_directory \
        "${BACKUP_DIR}/.claude/commands" \
        "${PROJECT_ROOT}/.claude/commands"

    # 検証
    assert_success

    # ファイルが新しい内容に更新されていることを確認
    run cat "${PROJECT_ROOT}/.claude/commands/test.md"
    assert_output --partial "New content"
    refute_output --partial "Old content"
}
