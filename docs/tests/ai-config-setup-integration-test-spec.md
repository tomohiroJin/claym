# AI拡張設定統合試験仕様書

- 対象ブランチ: `feature/claude-code-extensible-config`
- 作成日: 2025-10-25
- 作成者: Codex CLI エージェント

## 1. 目的
AI拡張設定スクリプト群（`init-ai-configs.sh`、`reinit-ai-configs.sh`、`copy-template-to-local.sh`、`run-setup-tests.sh`）の統合的な動作を手動試験で確認する。特に、テンプレートのマージ処理、バックアップ・リストア機能、追加ドキュメントや `.gitignore` 更新が期待通り機能することを検証する。

## 2. 試験範囲
- `scripts/setup/init-ai-configs.sh`
- `scripts/setup/reinit-ai-configs.sh`
- `scripts/setup/copy-template-to-local.sh`
- `scripts/test/run-setup-tests.sh`
- 付随するテンプレートおよびドキュメント (`templates/.claude`, `.codex`, `.gemini`, `docs/`)

## 3. 前提条件
1. Dev Container または同等の Linux 環境上で実行する。
2. リポジトリ直下にいること。
3. 重要なローカル設定（`~/.codex` など）がある場合は事前にバックアップしておくこと。
4. テスト実行前に `git status` がクリーンであること（テストで生成されるファイルは `.gitignore` 対象のためコミットされない想定）。

## 4. テスト観点
- 初期セットアップが公式テンプレート＋ローカルテンプレートを正しく配置するか。
- `.claude/commands` および `.claude/agents` のマージ結果。
- `.gitignore` 更新処理の冪等性。
- バックアップ／リストア時にプロジェクトルートと `~/.codex` の両方の `AGENTS.md` が扱われるか。
- `templates-local/` ディレクトリがバックアップ対象に含まれるか。
- `copy-template-to-local.sh` の個別／一括コピー機能。
- `run-setup-tests.sh` による Bats テストの実行可否。
- ログ出力共通化によるメッセージ表示の確認。

## 5. 試験環境準備手順
1. 既存設定の退避（任意）
   ```bash
   mv ~/.codex ~/.codex.backup.$(date +%s)
   mv ~/.anthropic ~/.anthropic.backup.$(date +%s)  # 必要に応じて
   ```
2. プロジェクトのクリーンアップ（必要に応じて）
   ```bash
   rm -rf .claude .gemini templates-local ~/.codex 2>/dev/null || true
   ```
3. 依存ツール確認
   ```bash
   which bats
   bats --version
   ```
   ※ Dev Container の `.devcontainer/Dockerfile` でインストール済みの想定。

## 6. 試験ケース一覧

### INIT-001: 初期セットアップの基本動作
- [x] **前提条件**: 5章の準備が完了している
- [x] **手順1**: `bash scripts/setup/init-ai-configs.sh` を実行
- [x] **手順2**: 終了メッセージとログを確認
- [x] **期待結果**: スクリプトがエラーなく終了
- [x] **期待結果**: `show_header`/`show_footer` を含む整ったログが表示される

### INIT-002: 設定ファイル生成内容
- [x] **前提条件**: INIT-001 実施直後
- [x] **手順1**: `ls -R .claude`
- [x] **手順2**: `ls ~/.codex`
- [x] **手順3**: `ls .gemini`
- [x] **期待結果**: `.claude/settings.local.json`, `.claude/CLAUDE.md`, `.claude/commands/*.md`, `.claude/agents/*.yaml` が存在
- [x] **期待結果**: `AGENTS.md` がリポジトリ直下と `~/.codex/` に存在
- [x] **期待結果**: `.gemini/settings.json`, `.gemini/GEMINI.md`, `.gemini/commands/*.md` が存在

### INIT-003: `.gitignore` 更新の冪等性
- [x] **前提条件**: INIT-001 実施直後
- [x] **手順1**: `.gitignore` に `templates-local/`, `.claude/agents/` が追記されているか確認
- [x] **手順2**: `bash scripts/setup/init-ai-configs.sh` を再実行
- [x] **期待結果**: `.gitignore` に重複行が追加されない
- [x] **期待結果**: 2回目もエラーなく完了する

### COPY-001: 単一コマンドコピー
- [x] **前提条件**: INIT-001 実施後
- [x] **手順1**: `rm -rf templates-local`
- [x] **手順2**: `bash scripts/setup/copy-template-to-local.sh command review.md`
- [x] **手順3**: `cat templates-local/.claude/commands/review.md`
- [x] **期待結果**: `templates-local/.claude/commands/review.md` が作成され、テンプレート内容がコピーされる

### COPY-002: GEMINI コマンドコピー
- [x] **前提条件**: INIT-001 実施後
- [x] **手順1**: `rm -rf templates-local`
- [x] **手順2**: `bash scripts/setup/copy-template-to-local.sh gemini-command yfinance.md`
- [x] **手順3**: `cat templates-local/.gemini/commands/yfinance.md`
- [x] **期待結果**: `templates-local/.gemini/commands/yfinance.md` が作成され、テンプレート内容がコピーされる

### COPY-003: 一括コピー動作
- [x] **前提条件**: COPY-001 実施後
- [x] **手順1**: `bash scripts/setup/copy-template-to-local.sh all`
- [x] **期待結果**: `templates-local/.claude/commands/` に全コマンドが揃う
- [x] **期待結果**: `CLAUDE.md`, `settings.local.json.example` もコピーされる

### REINIT-001: バックアップ生成
- [x] **前提条件**: INIT-001 実施直後
- [x] **手順1**: `bash scripts/setup/reinit-ai-configs.sh --backup-only`
- [x] **手順2**: `ls -R .backups/ai-configs`
- [x] **期待結果**: 最新バックアップ配下に `backup-manifest.txt` が生成
- [x] **期待結果**: マニフェストに `AGENTS.md`（リポジトリ直下＆ `~/.codex`）、`templates-local/` などが記録されている

### REINIT-002: 再初期化フロー
- [x] **前提条件**: REINIT-001 実施後
- [x] **手順1**: `.claude/CLAUDE.md` にカスタム行を追加
- [x] **手順2**: `bash scripts/setup/reinit-ai-configs.sh --dry-run` を実行して削除対象を確認
- [x] **手順3**: `bash scripts/setup/reinit-ai-configs.sh` を実行
- [x] **期待結果**: dry-run 時に削除予定ファイルとディレクトリがログに出力される
- [x] **期待結果**: 本実行で再度 `init-ai-configs.sh` が呼ばれ、設定が再生成される

### REINIT-003: バックアップからの復元
- [x] **前提条件**: REINIT-002 実施後
- [x] **手順1**: `.claude/CLAUDE.md` に一意の文字列を追加
- [x] **手順2**: 直近バックアップIDを確認（`ls .backups/ai-configs`）
- [x] **手順3**: `bash scripts/setup/reinit-ai-configs.sh --restore <ID>` を実行
- [x] **期待結果**: バックアップ時の `.claude/CLAUDE.md` 内容に戻る
- [x] **期待結果**: `AGENTS.md`（両方）も復元される

### TEST-001: 自動テストランナー
- [x] **前提条件**: INIT-001 実施後
- [x] **手順1**: `bash scripts/test/run-setup-tests.sh all`
- [x] **期待結果**: bats のバージョン表示後、全テストが PASS する

### HEALTH-001: ヘルスチェック補助スクリプト
- [x] **前提条件**: INIT-001 実施後
- [x] **手順1**: `bash scripts/health/test-container-basics.sh`
- [x] **手順2**: `bash scripts/health/test-health-checks.sh`
- [x] **期待結果**: 共通ログ形式でテスト結果が表示され、失敗がない

## 7. 試験結果記録

| ID | 実施日 | 実施者 | 結果 | 備考 |
|----|--------|--------|------|------|
| INIT-001 | 2025-10-25 | 神 | PASS | エラーなく終了、整ったログ表示を確認 |
| INIT-002 | 2025-10-25 | 神 | PASS | 全設定ファイルの生成を確認 |
| INIT-003 | 2025-10-25 | 神 | PASS | .gitignore更新の冪等性を確認 |
| COPY-001 | 2025-10-25 | 神 | PASS | 単一コマンドコピー動作確認 |
| COPY-002 | 2025-10-25 | 神 | PASS | GEMINI コマンドコピー動作確認 |
| COPY-003 | 2025-10-25 | 神 | PASS | 一括コピー動作確認 |
| REINIT-001 | 2025-10-25 | 神 | PASS | バックアップ生成とマニフェスト記録を確認 |
| REINIT-002 | 2025-10-25 | 神 | PASS | 再初期化フロー動作確認 |
| REINIT-003 | 2025-10-25 | 神 | PASS | バックアップからの復元動作確認 |
| TEST-001 | 2025-10-25 | 神 | PASS | batsテスト 39/39 成功 |
| HEALTH-001 | 2025-10-25 | 神 | PASS | test-container-basics: 33/33, test-health-checks: 15/15 成功 |

## 8. フォローアップ
- 失敗ケースがある場合は、ログ (`.backups/ai-configs/<ID>/backup-manifest.txt` など) を添付。
- `.gitignore` やテンプレートに差異があれば `diff` を取得して分析する。
- 復元オプションを使用した場合は、テスト終了後に必要に応じて元の `~/.codex` バックアップを戻すこと。
