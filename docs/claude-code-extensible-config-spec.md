# Claude Code 拡張可能設定 仕様書

**作成日**: 2025-10-20
**バージョン**: 1.0
**ステータス**: 設計中

---

## 1. 概要

### 1.1 目的

Claude Code のサブエージェント機能とカスタムコマンド機能を拡張可能な形でテンプレート化し、ユーザーが簡単にカスタマイズできる仕組みを提供する。

### 1.2 スコープ

- **対象範囲**:
  - `.claude/commands/` ディレクトリの設計とテンプレート作成
  - `.claude/agents/` ディレクトリの設計とテンプレート作成（将来的な拡張として）
  - `reinit-ai-configs.sh` の拡張
  - 基本的なコマンド・エージェントテンプレートの提供

- **対象外**:
  - 既存の `.claude/settings.local.json` の大幅な変更
  - MCP サーバーの設定変更
  - プラグイン機構の実装

### 1.3 前提条件

- Claude Code CLI がインストール済み
- プロジェクトに `.claude/` ディレクトリが存在
- `reinit-ai-configs.sh` が動作している

---

## 2. アーキテクチャ

### 2.1 ディレクトリ構成

```
/workspaces/claym/
├── templates/
│   └── .claude/
│       ├── settings.local.json.example      # 既存
│       ├── CLAUDE.md                         # 既存
│       ├── README.md                         # 既存
│       ├── commands/                         # 新規
│       │   ├── README.md                    # コマンドの使い方
│       │   ├── code-gen.md                  # コード生成コマンド
│       │   ├── review.md                    # コードレビューコマンド
│       │   ├── docs.md                      # ドキュメント生成コマンド
│       │   └── test.md                      # テスト関連コマンド
│       └── agents/                           # 新規（将来拡張）
│           ├── README.md                    # エージェントの使い方
│           └── agents.json.example          # エージェント設定例
│
├── .claude/                                  # 実際の設定（gitignore対象）
│   ├── settings.local.json
│   ├── CLAUDE.md
│   ├── commands/                             # テンプレートからコピー
│   │   ├── code-gen.md
│   │   ├── review.md
│   │   ├── docs.md
│   │   └── test.md
│   └── agents/                               # 将来的な拡張
│       └── agents.json
│
└── scripts/setup/
    ├── init-ai-configs.sh                    # 初期化スクリプト（拡張）
    └── reinit-ai-configs.sh                  # 再設定スクリプト（拡張）
```

### 2.2 コンポーネント関係図

```
┌─────────────────────────────────────────┐
│  templates/.claude/                     │
│  ┌─────────────┐  ┌──────────────┐     │
│  │ commands/   │  │  agents/     │     │
│  │  *.md       │  │  agents.json │     │
│  └─────────────┘  └──────────────┘     │
└──────────────┬──────────────────────────┘
               │
               │ コピー・同期
               ↓
┌─────────────────────────────────────────┐
│  .claude/                               │
│  ┌─────────────┐  ┌──────────────┐     │
│  │ commands/   │  │  agents/     │     │
│  │  *.md       │  │  agents.json │     │
│  └─────────────┘  └──────────────┘     │
└─────────────────────────────────────────┘
               ↑
               │ 使用
               │
┌─────────────────────────────────────────┐
│  Claude Code CLI                        │
│  - /code-gen                            │
│  - /review                              │
│  - /docs                                │
│  - /test                                │
└─────────────────────────────────────────┘
```

---

## 3. カスタムコマンド設計

### 3.1 コマンドの定義

カスタムコマンドは Markdown ファイルとして定義し、`.claude/commands/` ディレクトリに配置します。

#### ファイル命名規則

```
<command-name>.md
```

- `command-name`: スラッシュコマンドで呼び出す際の名前（例: `code-gen` → `/code-gen`）
- 小文字とハイフンのみ使用
- 拡張子は `.md`

#### ファイル構造

```markdown
# コマンドの説明

<!-- ここにコマンドの詳細な説明を記述 -->

## 使い方

<!-- 使用例を記述 -->

## プロンプト

<!-- Claude に渡される実際のプロンプトを記述 -->
```

### 3.2 基本コマンドテンプレート

#### 3.2.1 code-gen.md - コード生成

**目的**: 特定のパターンやテンプレートに基づいたコード生成

**ユースケース**:
- CRUD 操作の自動生成
- API エンドポイントの自動生成
- モデル・スキーマの自動生成

#### 3.2.2 review.md - コードレビュー

**目的**: コードの品質チェックとレビュー

**ユースケース**:
- セキュリティチェック
- パフォーマンスレビュー
- コーディング規約チェック

#### 3.2.3 docs.md - ドキュメント生成

**目的**: README や API ドキュメントの自動生成

**ユースケース**:
- README.md の自動生成
- API ドキュメントの生成
- JSDoc/docstring の生成

#### 3.2.4 test.md - テスト関連

**目的**: テストケースの生成と実行

**ユースケース**:
- ユニットテストの自動生成
- 統合テストの自動生成
- テストカバレッジの分析

### 3.3 コマンドのカスタマイズ方法

ユーザーは以下の方法でコマンドをカスタマイズできます：

1. **既存コマンドの編集**
   ```bash
   # .claude/commands/code-gen.md を編集
   vim .claude/commands/code-gen.md
   ```

2. **新規コマンドの追加**
   ```bash
   # 新しいコマンドを作成
   touch .claude/commands/custom-command.md
   # 内容を編集
   vim .claude/commands/custom-command.md
   ```

3. **不要なコマンドの削除**
   ```bash
   # 使わないコマンドを削除
   rm .claude/commands/test.md
   ```

---

## 4. エージェント設定設計（将来拡張）

### 4.1 エージェント設定ファイル

エージェントの設定は JSON 形式で管理します。

#### ファイル構造

```json
{
  "version": "1.0",
  "agents": [
    {
      "id": "code-generator",
      "name": "コード生成エージェント",
      "description": "特定パターンでのコード生成を支援",
      "prompt_template": "templates/prompts/code-gen.md",
      "enabled": true
    },
    {
      "id": "reviewer",
      "name": "レビューエージェント",
      "description": "コード品質のレビューを実施",
      "prompt_template": "templates/prompts/review.md",
      "enabled": true
    }
  ]
}
```

### 4.2 エージェント設定の管理

**注意**: この機能は現在の Claude Code では直接サポートされていない可能性があります。将来的な拡張として設計を準備しておきます。

---

## 5. スクリプト拡張設計

### 5.1 init-ai-configs.sh の拡張

#### 追加機能

1. **commands ディレクトリのコピー**
   ```bash
   # templates/.claude/commands/ → .claude/commands/
   if [[ -d "${TEMPLATES_DIR}/.claude/commands" ]]; then
       log_info "カスタムコマンドをコピー中..."
       cp -r "${TEMPLATES_DIR}/.claude/commands" "${PROJECT_ROOT}/.claude/"
   fi
   ```

2. **agents ディレクトリのコピー（将来拡張）**
   ```bash
   # templates/.claude/agents/ → .claude/agents/
   if [[ -d "${TEMPLATES_DIR}/.claude/agents" ]]; then
       log_info "エージェント設定をコピー中..."
       cp -r "${TEMPLATES_DIR}/.claude/agents" "${PROJECT_ROOT}/.claude/"
   fi
   ```

### 5.2 reinit-ai-configs.sh の拡張

#### バックアップ対象の追加

既存の `backup_targets` 配列に以下を追加：

```bash
local -a backup_targets=(
    # 既存
    "${PROJECT_ROOT}/.claude/settings.local.json"
    "${PROJECT_ROOT}/.claude/CLAUDE.md"
    "${HOME}/.codex/config.toml"
    "${PROJECT_ROOT}/AGENTS.md"
    "${PROJECT_ROOT}/.gemini/settings.json"
    "${PROJECT_ROOT}/.gemini/GEMINI.md"

    # 新規追加
    "${PROJECT_ROOT}/.claude/commands"      # ディレクトリ全体
    "${PROJECT_ROOT}/.claude/agents"        # ディレクトリ全体（将来）
)
```

#### ディレクトリバックアップのサポート

現在の `create_backup()` 関数はファイル単位でのバックアップのみサポートしています。
ディレクトリ全体のバックアップに対応するよう拡張します。

```bash
create_backup() {
    # ... 既存のコード ...

    # ディレクトリのバックアップ処理を追加
    local -a backup_dir_targets=(
        "${PROJECT_ROOT}/.claude/commands"
        "${PROJECT_ROOT}/.claude/agents"
    )

    for dir in "${backup_dir_targets[@]}"; do
        if [[ -d "${dir}" ]]; then
            local rel_path="${dir#${PROJECT_ROOT}/}"
            local backup_path="${BACKUP_DIR}/${rel_path}"

            log_debug "ディレクトリをバックアップ中: ${dir} -> ${backup_path}"

            if [[ "${DRY_RUN}" != "true" ]]; then
                mkdir -p "$(dirname "${backup_path}")"
                cp -r "${dir}" "${backup_path}"
                echo "${rel_path}/" >> "${manifest}"
                backed_up_count=$((backed_up_count + 1))
            fi
        fi
    done
}
```

---

## 6. 実装優先順位

### Phase 1: 基本実装（必須）

1. ✅ ブランチ作成
2. ✅ spec.md と todo.md の作成
3. 🔄 `templates/.claude/commands/` ディレクトリ作成
4. 🔄 基本コマンドテンプレート（4つ）の作成
5. 🔄 `reinit-ai-configs.sh` の拡張
6. 🔄 README.md の作成

### Phase 2: テストと検証

7. 🔄 統合テストの実施
8. 🔄 ドキュメントの整備

### Phase 3: 将来拡張（オプショナル）

9. ⏸️ `templates/.claude/agents/` ディレクトリ作成
10. ⏸️ エージェント設定の実装

---

## 7. 技術的制約

### 7.1 Claude Code の制約

- カスタムコマンドは `.claude/commands/` に配置した Markdown ファイルとして認識される
- コマンド名はファイル名から自動的に決定される（拡張子なし）
- エージェント設定機能は現時点で公式にサポートされていない可能性がある

### 7.2 バックアップの制約

- バックアップ先: `~/.config/claym-backups/YYYYMMDD_HHMMSS/`
- タイムスタンプ形式: `YYYYMMDD_HHMMSS`
- ディレクトリ構造を保持したバックアップ

---

## 8. セキュリティ考慮事項

### 8.1 ファイル権限

- テンプレートファイル: 読み取り専用（`444`）
- 実際の設定ファイル: ユーザー読み書き可能（`644`）
- スクリプトファイル: 実行可能（`755`）

### 8.2 バックアップのセキュリティ

- バックアップディレクトリは `~/.config/claym-backups/` に配置
- ユーザーのホームディレクトリ配下で管理
- 他のユーザーからはアクセス不可（権限 `700`）

---

## 9. エラーハンドリング

### 9.1 想定されるエラー

1. **テンプレートディレクトリが存在しない**
   - エラーメッセージ: "テンプレートディレクトリが見つかりません"
   - 対処: スクリプトを終了し、ユーザーに確認を促す

2. **バックアップ先の容量不足**
   - エラーメッセージ: "バックアップ先のディスク容量が不足しています"
   - 対処: 古いバックアップの削除を提案

3. **不正な JSON ファイル**（将来のエージェント設定）
   - エラーメッセージ: "agents.json の形式が不正です"
   - 対処: JSON バリデーションを実施し、詳細なエラー位置を表示

---

## 10. テスト計画

### 10.1 ユニットテスト

- [ ] `create_backup()` 関数のディレクトリバックアップ
- [ ] `restore_backup()` 関数のディレクトリ復元
- [ ] テンプレートコピー処理の検証

### 10.2 統合テスト

- [ ] 初回セットアップ（`init-ai-configs.sh`）
- [ ] 再設定（`reinit-ai-configs.sh`）
- [ ] バックアップと復元のサイクル
- [ ] カスタムコマンドの動作確認

### 10.3 ユーザビリティテスト

- [ ] コマンドのカスタマイズ手順の確認
- [ ] ドキュメントの分かりやすさ
- [ ] エラーメッセージの明確さ

---

## 11. 参考資料

- [Claude Code 公式ドキュメント](https://docs.claude.com/en/docs/claude-code)
- [既存の reinit-ai-configs.sh](/workspaces/claym/scripts/setup/reinit-ai-configs.sh)
- [templates/.claude/README.md](/workspaces/claym/templates/.claude/README.md)

---

## 12. 変更履歴

| 日付 | バージョン | 変更内容 | 作成者 |
|------|-----------|---------|--------|
| 2025-10-20 | 1.0 | 初版作成 | Claude Code |

---

## 13. 承認

この仕様書は以下の承認を受けています：

- [ ] 技術リード
- [ ] プロジェクトマネージャー
- [ ] ユーザー代表

---

**End of Specification**
