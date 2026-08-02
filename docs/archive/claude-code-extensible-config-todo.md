# Claude Code 拡張可能設定 TODO リスト

**作成日**: 2025-10-20
**プロジェクト**: claym
**ブランチ**: feature/claude-code-extensible-config

---

## 凡例

- ✅ 完了
- 🔄 作業中
- ⏸️ 保留
- ❌ ブロック
- 📋 未着手

---

## Phase 1: 基本設計とドキュメント

### 1.1 プロジェクト準備

- [x] ✅ 新しいブランチ `feature/claude-code-extensible-config` を作成
- [x] ✅ spec.md の作成
- [ ] 🔄 todo.md の作成

---

## Phase 2: テンプレートディレクトリの作成

### 2.1 commands ディレクトリ

- [ ] 📋 `templates/.claude/commands/` ディレクトリを作成
- [ ] 📋 `templates/.claude/commands/README.md` を作成
  - コマンドの概要説明
  - 使用方法
  - カスタマイズ方法
  - トラブルシューティング

### 2.2 agents ディレクトリ（Phase 3 で実施）

- [ ] ⏸️ `templates/.claude/agents/` ディレクトリを作成
- [ ] ⏸️ `templates/.claude/agents/README.md` を作成
- [ ] ⏸️ `templates/.claude/agents/agents.json.example` を作成

---

## Phase 3: 基本コマンドテンプレートの作成

### 3.1 code-gen.md - コード生成コマンド

- [ ] 📋 ファイル作成: `templates/.claude/commands/code-gen.md`
- [ ] 📋 プロンプトの設計
  - コード生成の目的と範囲
  - 生成パターンの指定方法
  - 命名規則の遵守
  - エラーハンドリング
- [ ] 📋 使用例の記述
  - CRUD 操作の自動生成
  - API エンドポイントの生成
  - モデル・スキーマの生成

**推定作業時間**: 30分

### 3.2 review.md - コードレビューコマンド

- [ ] 📋 ファイル作成: `templates/.claude/commands/review.md`
- [ ] 📋 プロンプトの設計
  - レビュー観点の明確化
  - セキュリティチェック
  - パフォーマンスチェック
  - コーディング規約チェック
- [ ] 📋 使用例の記述
  - プルリクエストのレビュー
  - コミット前のチェック
  - レガシーコードの評価

**推定作業時間**: 30分

### 3.3 docs.md - ドキュメント生成コマンド

- [ ] 📋 ファイル作成: `templates/.claude/commands/docs.md`
- [ ] 📋 プロンプトの設計
  - ドキュメントの種類（README、API ドキュメントなど）
  - 自動抽出する情報
  - フォーマットの指定
- [ ] 📋 使用例の記述
  - README.md の自動生成
  - API ドキュメントの生成
  - JSDoc/docstring の生成

**推定作業時間**: 30分

### 3.4 test.md - テスト関連コマンド

- [ ] 📋 ファイル作成: `templates/.claude/commands/test.md`
- [ ] 📋 プロンプトの設計
  - テストケースの生成方針
  - カバレッジの目標
  - テストフレームワークの指定
- [ ] 📋 使用例の記述
  - ユニットテストの自動生成
  - 統合テストの自動生成
  - テストカバレッジの分析

**推定作業時間**: 30分

---

## Phase 4: スクリプトの拡張

### 4.1 init-ai-configs.sh の拡張

- [ ] 📋 `scripts/setup/init-ai-configs.sh` を開く
- [ ] 📋 commands ディレクトリのコピー処理を追加
  ```bash
  # templates/.claude/commands/ → .claude/commands/
  if [[ -d "${TEMPLATES_DIR}/.claude/commands" ]]; then
      log_info "カスタムコマンドをコピー中..."
      mkdir -p "${PROJECT_ROOT}/.claude/commands"
      cp -r "${TEMPLATES_DIR}/.claude/commands/"* "${PROJECT_ROOT}/.claude/commands/"
      log_success "カスタムコマンドのコピーが完了しました"
  fi
  ```
- [ ] 📋 agents ディレクトリのコピー処理を追加（将来拡張）
- [ ] 📋 完了メッセージの更新

**推定作業時間**: 20分

### 4.2 reinit-ai-configs.sh の拡張

#### 4.2.1 バックアップ機能の拡張

- [ ] 📋 `backup_targets` 配列にディレクトリを追加
  ```bash
  local -a backup_dir_targets=(
      "${PROJECT_ROOT}/.claude/commands"
      "${PROJECT_ROOT}/.claude/agents"
  )
  ```

- [ ] 📋 `create_backup()` 関数を拡張
  - ディレクトリバックアップのサポート
  - ディレクトリ構造の保持
  - manifest への記録

**サンプルコード**:
```bash
# ディレクトリのバックアップ処理
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
```

**推定作業時間**: 40分

#### 4.2.2 復元機能の拡張

- [ ] 📋 `restore_backup()` 関数を拡張
  - ディレクトリ復元のサポート
  - manifest の `<path>/` 形式の判定
  - ディレクトリ構造の再現

**推定作業時間**: 30分

#### 4.2.3 再生成機能の拡張

- [ ] 📋 `regenerate_configs()` 関数を拡張
  - commands ディレクトリの削除処理を追加
  - agents ディレクトリの削除処理を追加

**推定作業時間**: 15分

---

## Phase 5: ドキュメント作成

### 5.1 commands/README.md

- [ ] 📋 概要セクション
  - カスタムコマンドとは
  - 基本的な使い方
- [ ] 📋 提供されるコマンド一覧
  - 各コマンドの説明
  - 使用例
- [ ] 📋 カスタマイズ方法
  - 既存コマンドの編集
  - 新規コマンドの追加
  - コマンドの削除
- [ ] 📋 トラブルシューティング
  - よくある問題と解決策

**推定作業時間**: 45分

### 5.2 agents/README.md（将来拡張）

- [ ] ⏸️ 概要セクション
- [ ] ⏸️ エージェント設定の説明
- [ ] ⏸️ カスタマイズ方法

**推定作業時間**: 30分

### 5.3 メインドキュメントの更新

- [ ] 📋 `templates/README.md` の更新
  - commands セクションの追加
  - agents セクションの追加（将来拡張として）
- [ ] 📋 `docs/scripts-setup-tools.md` の更新
  - 新機能の説明
  - 使用例の追加

**推定作業時間**: 30分

---

## Phase 6: テストと検証

### 6.1 ユニットテスト

- [ ] 📋 テストスクリプトの作成: `scripts/setup/test-claude-code-config.sh`
- [ ] 📋 バックアップ機能のテスト
  - ファイルバックアップ
  - ディレクトリバックアップ
  - manifest の正確性
- [ ] 📋 復元機能のテスト
  - ファイル復元
  - ディレクトリ復元
  - 構造の再現性
- [ ] 📋 コピー機能のテスト
  - テンプレートから実際の設定へのコピー
  - ディレクトリ構造の保持

**推定作業時間**: 60分

### 6.2 統合テスト

- [ ] 📋 初回セットアップのテスト
  ```bash
  # クリーンな状態から
  rm -rf .claude/commands .claude/agents
  bash scripts/setup/init-ai-configs.sh
  ```

- [ ] 📋 再設定のテスト
  ```bash
  # カスタマイズ後の再設定
  echo "# Custom" >> .claude/commands/code-gen.md
  bash scripts/setup/reinit-ai-configs.sh -y
  ```

- [ ] 📋 バックアップと復元のサイクルテスト
  ```bash
  # バックアップ
  bash scripts/setup/reinit-ai-configs.sh --backup-only
  # 変更を加える
  rm .claude/commands/test.md
  # 復元
  bash scripts/setup/reinit-ai-configs.sh --restore <TIMESTAMP>
  ```

**推定作業時間**: 45分

### 6.3 カスタムコマンドの動作確認

- [ ] 📋 `/code-gen` コマンドの動作確認
- [ ] 📋 `/review` コマンドの動作確認
- [ ] 📋 `/docs` コマンドの動作確認
- [ ] 📋 `/test` コマンドの動作確認

**推定作業時間**: 30分

---

## Phase 7: 最終化

### 7.1 コードレビュー

- [ ] 📋 ShellCheck によるスクリプトチェック
  ```bash
  shellcheck scripts/setup/init-ai-configs.sh
  shellcheck scripts/setup/reinit-ai-configs.sh
  ```

- [ ] 📋 コードの可読性チェック
- [ ] 📋 エラーハンドリングの確認

**推定作業時間**: 20分

### 7.2 ドキュメントの最終確認

- [ ] 📋 誤字脱字のチェック
- [ ] 📋 リンクの確認
- [ ] 📋 サンプルコードの動作確認

**推定作業時間**: 15分

### 7.3 コミットとプルリクエスト

- [ ] 📋 変更内容をコミット
  ```bash
  git add .
  git commit -m "feat: Add extensible Claude Code config system

  - Add custom commands template (code-gen, review, docs, test)
  - Extend init-ai-configs.sh to support commands directory
  - Extend reinit-ai-configs.sh to backup/restore directories
  - Add comprehensive documentation and examples
  - Add test suite for config management
  "
  ```

- [ ] 📋 プルリクエストの作成
- [ ] 📋 レビュー依頼

**推定作業時間**: 20分

---

## Phase 8: 将来拡張（オプショナル）

### 8.1 エージェント機能の実装

- [ ] ⏸️ agents.json の設計
- [ ] ⏸️ エージェント管理スクリプトの作成
- [ ] ⏸️ エージェントテンプレートの作成

**推定作業時間**: 120分

### 8.2 高度なカスタマイズ機能

- [ ] ⏸️ コマンドのパラメータ化
- [ ] ⏸️ コマンドの依存関係管理
- [ ] ⏸️ コマンドのバージョン管理

**推定作業時間**: 180分

---

## 総推定作業時間

| Phase | 作業時間 |
|-------|---------|
| Phase 1 | 10分 |
| Phase 2 | 15分 |
| Phase 3 | 120分 |
| Phase 4 | 105分 |
| Phase 5 | 105分 |
| Phase 6 | 135分 |
| Phase 7 | 55分 |
| **合計** | **約545分（9時間）** |

---

## ブロッカー

現在ブロッカーはありません。

---

## 依存関係

```
Phase 1 (設計)
    ↓
Phase 2 (ディレクトリ作成)
    ↓
Phase 3 (テンプレート作成) ←→ Phase 5 (ドキュメント作成)
    ↓
Phase 4 (スクリプト拡張)
    ↓
Phase 6 (テスト)
    ↓
Phase 7 (最終化)
```

---

## 優先順位

1. **High**: Phase 1-4（コア機能の実装）
2. **Medium**: Phase 5-6（ドキュメントとテスト）
3. **Low**: Phase 7（最終化）
4. **Optional**: Phase 8（将来拡張）

---

## 注意事項

### セキュリティ

- [ ] 📋 バックアップディレクトリの権限確認（`700`）
- [ ] 📋 秘密情報が含まれないことを確認
- [ ] 📋 スクリプトの実行権限の適切性

### 互換性

- [ ] 📋 既存の設定との互換性確認
- [ ] 📋 既存のワークフローへの影響確認
- [ ] 📋 他の AI CLI（codex、gemini）との干渉チェック

---

## 進捗状況

**開始日**: 2025-10-20
**現在のフェーズ**: Phase 1
**全体進捗**: 2/50 タスク完了（4%）

---

**Last Updated**: 2025-10-20
