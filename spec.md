# Codex カスタムプロンプト（slash コマンド）対応仕様

## 背景
- Codex CLI には `~/.codex/prompts/` 配下に Markdown を置くことで `/prompts:<name>` から呼び出せる「カスタムプロンプト」機能がある。
- 現行実装では Codex 用テンプレートとして `CODEX.md`（共有用メモ）が生成されるが、slash コマンドには対応していない。
- 公式テンプレート／templates-local の内容を、プロジェクト共有用 `.codex/prompts/` と個人用 `~/.codex/prompts/` に展開できるよう改善し、不要になった `CODEX.md` 系の処理を整理する。

## 目的
1. Codex CLI のカスタムプロンプトテンプレートを `templates/.codex/prompts/*.md` として管理し、公式＋ローカルテンプレートをコピー可能にする。
2. `init-ai-configs.sh` で初期セットアップ時にプロジェクト共有用（`.codex/prompts`）と個人用（`~/.codex/prompts`）へ slash コマンドテンプレートを展開する。
3. `reinit-ai-configs.sh` / `copy-template-to-local.sh` / テスト類を新しいテンプレート構成に合わせて更新し、旧 `CODEX.md` 系処理を撤去する。
4. ドキュメントを slash コマンド前提の構成へ修正し、CLI 使用者が `/prompts:<name>` で実行できることを明示する。

## 対象範囲
- `templates/.codex/prompts/`（新規ディレクトリ）および関連テンプレートの整備
- `templates-local/.codex/prompts/` からの上書き対応
- `scripts/setup/init-ai-configs.sh`
- `scripts/setup/reinit-ai-configs.sh`
- `scripts/setup/copy-template-to-local.sh`
- `scripts/setup/test-init-ai-configs.sh`
- `.gitignore`, `README.md`, `templates/README.md` 等の関連ドキュメント

## 実装方針
1. **テンプレート構造の再構成**
   - 共有テンプレート: `templates/.codex/prompts/<prompt>.md`
   - ローカルテンプレート: `templates-local/.codex/prompts/<prompt>.md`
   - 旧 `templates/.codex/CODEX.md` など slash コマンド非対応ファイルは削除

2. **初期化スクリプト**
   - `init-ai-configs.sh` で `merge_template_directories` を利用し `.codex/prompts` と `~/.codex/prompts` を作成
   - 既存の `resolve_template_source` 等、単一ファイル向けロジックは不要になれば削除

3. **再初期化／バックアップ**
   - `reinit-ai-configs.sh` のバックアップ対象に `.codex/prompts`（プロジェクト／ホーム両方）を追加し、`CODEX.md` を対象から外す
   - 再生成時は prompts ディレクトリを削除後に `init-ai-configs.sh` を実行

4. **テンプレートコピー CLI**
   - `copy-template-to-local.sh` に Codex 用サブコマンドを定義（例: `codex-prompts`）し、`templates-local/.codex/prompts` へコピーできるようにする

5. **テストとドキュメント**
   - `test-init-ai-configs.sh` で prompts ディレクトリ生成とローカル適用を検証
   - README 類を `/prompts:<name>` 手順に合わせて更新

## 想定される課題
- 既存ユーザーの `~/.codex/prompts/` に同名ファイルがある場合は「存在すれば上書きしない」戦略を維持する。
- テンプレート削除に伴うドキュメントの参照先更新漏れに注意する。
- 既存ブランチに生成済み `CODEX.md` が残っている場合、クリーンアップ手順を周知する必要がある。
