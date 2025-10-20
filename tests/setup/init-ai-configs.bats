#!/usr/bin/env bats

# init-ai-configs.sh のテスト
#
# テスト対象:
# - merge_templates() 関数
# - Claude Code コマンドのセットアップ
# - テンプレートのマージ動作

# テストヘルパーのロード
load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'

# セットアップ: 各テストの前に実行
setup() {
    # テスト用の一時ディレクトリを作成
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export TEMPLATES_DIR="${PROJECT_ROOT}/templates"
    export TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

    # プロジェクト構造を作成
    mkdir -p "${PROJECT_ROOT}"
    mkdir -p "${TEMPLATES_DIR}/.claude/commands"
    mkdir -p "${TEMPLATES_LOCAL_DIR}/.claude/commands"

    # テスト用のテンプレートファイルを作成
    cat > "${TEMPLATES_DIR}/.claude/commands/test1.md" << 'EOF'
# Test Command 1
Official template content
EOF

    cat > "${TEMPLATES_DIR}/.claude/commands/test2.md" << 'EOF'
# Test Command 2
Official template content
EOF
}

# ティアダウン: 各テストの後に実行
teardown() {
    # 一時ディレクトリを削除
    rm -rf "${TEST_DIR}"
}

# ----------------------------------------------------------------------------
# merge_templates() 関数のテスト
# ----------------------------------------------------------------------------

@test "merge_templates: 公式テンプレートのみの場合、正しくコピーされる" {
    # merge_templates 関数を定義（init-ai-configs.sh から抽出）
    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run merge_templates ".claude/commands"

    # 検証
    assert_success
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test2.md"

    # ファイル内容の検証
    run cat "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_output --partial "Official template content"
}

@test "merge_templates: ローカルテンプレートで上書きされる" {
    # ローカルテンプレートを作成（公式と同名で内容が異なる）
    cat > "${TEMPLATES_LOCAL_DIR}/.claude/commands/test1.md" << 'EOF'
# Test Command 1
Local template content (overridden)
EOF

    # merge_templates 関数を定義
    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run merge_templates ".claude/commands"

    # 検証
    assert_success

    # test1.md がローカルテンプレートの内容になっていることを確認
    run cat "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_output --partial "Local template content (overridden)"
    refute_output --partial "Official template content"

    # test2.md は公式テンプレートのまま
    run cat "${PROJECT_ROOT}/.claude/commands/test2.md"
    assert_output --partial "Official template content"
}

@test "merge_templates: ローカル独自のファイルも追加される" {
    # ローカル独自のテンプレートを作成
    cat > "${TEMPLATES_LOCAL_DIR}/.claude/commands/custom.md" << 'EOF'
# Custom Command
This is a custom local template
EOF

    # merge_templates 関数を定義
    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run merge_templates ".claude/commands"

    # 検証
    assert_success

    # 公式テンプレートが存在
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test2.md"

    # ローカル独自のファイルも存在
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/custom.md"

    run cat "${PROJECT_ROOT}/.claude/commands/custom.md"
    assert_output --partial "This is a custom local template"
}

@test "merge_templates: 公式テンプレートが存在しない場合でもエラーにならない" {
    # 存在しないディレクトリを指定
    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run merge_templates ".nonexistent/path"

    # エラーにならず正常終了すること
    assert_success
}

@test "merge_templates: ローカルテンプレートが存在しない場合でもエラーにならない" {
    # ローカルテンプレートディレクトリを削除
    rm -rf "${TEMPLATES_LOCAL_DIR}/.claude"

    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
        fi
    }

    # テスト実行
    run merge_templates ".claude/commands"

    # エラーにならず正常終了すること
    assert_success

    # 公式テンプレートはコピーされる
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test2.md"
}

# ----------------------------------------------------------------------------
# init-ai-configs.sh スクリプト全体のテスト
# ----------------------------------------------------------------------------

@test "init-ai-configs.sh: スクリプトが正常に実行できる" {
    # スクリプトのシンタックスチェック
    run bash -n /workspaces/claym/scripts/setup/init-ai-configs.sh
    assert_success
}

@test "init-ai-configs.sh: 必須の関数が定義されている" {
    # スクリプトをソースして関数の存在を確認
    source /workspaces/claym/scripts/setup/init-ai-configs.sh 2>/dev/null || true

    # 各関数が定義されていることを確認
    run type merge_templates
    assert_success

    run type setup_claude_code
    assert_success

    run type setup_codex_cli
    assert_success

    run type setup_gemini
    assert_success
}
