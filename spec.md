# Codex カスタムプロンプト展開仕様

## 背景
- `scripts/setup/init-ai-configs.sh` では `.claude` 配下のテンプレートを templates-local を含めてコピーする仕組みがあるが、Codex CLI については `config.toml` と `AGENTS.md` のみをコピーしている。
- ユーザーは Codex CLI 用のカスタムプロンプトを公式テンプレートから自動コピーし、`templates-local/.codex` に独自ファイルがある場合はそれを優先する仕組みを求めている。
- 前回実装済みの `.claude` 向けマージロジック（公式テンプレート + templates-local 上書き）を参考に Codex 版を整備する。

## 目的
1. Codex CLI 用カスタムプロンプトのテンプレートを追加する。
2. Dev Container 起動時に `init-ai-configs.sh` がテンプレートをコピーするよう拡張する。
3. `templates-local/.codex` に同名ファイルがある場合はそちらで上書きできるようにする。
4. `reinit-ai-configs.sh` やバックアップ処理、テスト、ドキュメントを Codex プロンプト対応に追従させる。

## 対象範囲
- `templates/.codex/` 以下に新たなプロンプトテンプレート（`CODEX.md`）を追加
- `templates-local/.codex/` からのコピーを許容するためのヘルパー処理
- `scripts/setup/init-ai-configs.sh`
- `scripts/setup/reinit-ai-configs.sh`
- `scripts/setup/copy-template-to-local.sh`
- `scripts/setup/test-init-ai-configs.sh`
- テンプレート README など必要に応じたドキュメント

## 実装方針
1. **テンプレート構造**
   - `templates/.codex/CODEX.md` を新設し、Codex CLI 用カスタムプロンプト本文を格納。
   - コピー先はプロジェクトルートの `.codex/CODEX.md`（共有設定）と `~/.codex/CODEX.md`（個人設定）。

2. **コピー／マージ戦略**
   - 単一ファイル用のコピー関数を用意し、`templates-local/.codex/CODEX.md` が存在すればそちらを優先。
   - コピー先はプロジェクトルートとホームディレクトリの両方。既存ファイルがある場合は上書きせず、初期セットアップ時のみ生成。

3. **補助ファイルの取り扱い**
   - `copy_template_to_local.sh` に Codex 用オプション（例: `codex`）を追加し、ローカルテンプレートへのコピー操作を簡素化。
   - `reinit-ai-configs.sh` のバックアップ／削除対象に `.codex/CODEX.md`（およびホーム側の対応ファイル）を追加。

4. **テスト／検証**
   - `scripts/setup/test-init-ai-configs.sh` に Codex プロンプト生成の検証を追加。
   - 必要であれば簡易スモークテストを追加し、テンプレートがコピーされているか確認する。

5. **ドキュメント更新**
   - `templates/README.md` や関連ドキュメントに Codex プロンプトの使い方・配置先を追記する。

## 想定される課題
- Codex CLI が外部ファイルのプロンプトを参照する標準的な仕組みがあるか要確認。存在しない場合、`config.toml` から読み込むワークフローを併記する。
- `HOME` 配下へのコピーは `init-ai-configs.sh` が root / devcontainer ユーザで動くことを前提にしているため、権限問題に注意。
- 既にユーザーがカスタムプロンプトを設置済みの場合に上書きしないよう、`.claude` 同様「存在しなければコピー」ポリシーを維持する。

## オープンな確認事項
- 現時点で追加の確認事項はありません。
