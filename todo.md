# TODO

- [x] 既存の `templates/.codex/CODEX.md` や関連ロジックを撤去し、slash コマンド向け設計に切り替える範囲を整理する
- [x] `templates/.codex/prompts/` および `templates-local/.codex/prompts/` のディレクトリ構造とサンプルプロンプトを用意する
- [x] `init-ai-configs.sh` を更新し、公式＋ローカルテンプレートから `.codex/prompts` と `~/.codex/prompts` にコピーする
- [x] `reinit-ai-configs.sh` を更新し、バックアップ／再生成対象を prompts ディレクトリに合わせる
- [x] `copy-template-to-local.sh` に Codex プロンプト用サブコマンドを実装する
- [x] `test-init-ai-configs.sh` を修正し、新しいプロンプト生成ロジックを検証する
- [x] `.gitignore`, README, templates/README などドキュメント類を slash コマンド前提に書き換える
- [x] 必要な動作確認（例: `bash scripts/setup/test-init-ai-configs.sh`）を実施する
- [x] 作業単位ごとにコミットを作成する
