# TODO（Poetry 環境復活タスク）

各項目は振る舞いベースの確認観点です。作業に着手したら RED → GREEN → REFACTOR の順で進め、完了後チェックを入れてください。

- [x] **Poetry ラッパースクリプトの作成**
  - GIVEN: Python CLI が `/opt/mcp-venv` を指している
  - WHEN: `./scripts/run_poetry.sh <command>` を実行
  - THEN: `VIRTUAL_ENV` が解除された状態で Poetry が `.venv` を利用する
  - [x] 2025-10-15: スクリプト修正完了。`.venv/bin/poetry` を直接呼び出すように変更

- [x] **Poetry 再初期化**
  - GIVEN: ラッパースクリプト経由で実行
  - WHEN: `./scripts/run_poetry.sh env use /usr/bin/python3 && ./scripts/run_poetry.sh install --no-root`
  - THEN: `.venv` 配下に Poetry 仮想環境が作成され、必要な依存をインストールできる（ネットワーク制約がある場合は `poetry install` が失敗する旨を README に記載）

- [x] **Poetry 実行確認**
  - GIVEN: `.venv` が有効な状態
  - WHEN: `./scripts/run_poetry.sh run pytest`
  - THEN: 既存のユニットテスト（11件）がすべて PASS する
  - [x] 2025-10-15: ラッパースクリプト経由で全テスト成功を確認（11 passed in 1.09s）

- [x] **VS Code ターミナル確認**
  - GIVEN: VS Code 統合ターミナルを開く
  - WHEN: `./scripts/run_poetry.sh env info --path` を実行
  - THEN: `.venv` のパスが表示され `/opt/mcp-venv` が使われていない
  - [x] 2024-12-29: `.venv/bin/poetry` で `.venv` を指せることを確認
  - [x] 2025-10-15: ラッパースクリプトで `/workspaces/claym/local/projects/tsumugi-report/.venv` を正しく認識

- [x] **ヘルスチェック整合性**
  - GIVEN: `scripts/health/check-environment.sh` を実行
  - WHEN: MCP Python 環境のチェックが走る
  - THEN: Poetry ラッパーは独立して動作し、ヘルスチェックには影響しない
  - [x] 2024-12-29: `VIRTUAL_ENV` 未設定 + `check_mcp_python_environment` 実行で `imagesorcery-mcp` Import が権限エラーになることを確認
  - [x] 2025-10-15: Poetry ラッパーは `/opt/mcp-venv` に依存せず `.venv` を使用するため、ヘルスチェックとは独立して動作することを確認
  - 📝 Note: `/opt/mcp-venv` の書き込み権限問題は別タスクとして対応予定（Poetry 環境には影響なし）

- [x] **類似環境変数の確認**
  - GIVEN: Workspace 全体を検索
  - WHEN: `rg "VIRTUAL_ENV"` を実行
  - THEN: `/opt/mcp-venv` 以外に同等の仕組みが存在しないことを確認

- [x] **ドキュメント更新**
  - GIVEN: README / spec / todo (本体) が現状に追随していない
  - WHEN: Poetry 手順を再度記載し、実装状況を反映
  - THEN: 開発フローの記述が Poetry を標準とした形に統一される
  - [x] 2024-12-29: ルート README / `local/projects/tsumugi-report/README.md` / spec.md を更新し、PATH 整備と既知の課題を追記
  - [x] 2025-10-15: 実装完了に伴い spec.md と todo.md を最新状態に更新

- [x] **バックワード確認**
  - GIVEN: `/opt/mcp-venv` を用いるグローバル MCP CLI
  - WHEN: `claude --version` などを実行
  - THEN: 既存 CLI が影響を受けず動作する
  - [x] 2024-12-29: `claude --version` / `codex --version` / `gemini --version` を確認（いずれも成功）

- [x] **コミット & PR 準備**
  - GIVEN: 上記の動作確認が完了
  - WHEN: Git で差分を確認しテストログを添付
  - THEN: `feature/poetry-env` ブランチへコミットし、レビュー用の PR が準備できている
  - [x] 2024-12-29: 初回コミット完了
  - [x] 2025-10-15: ラッパースクリプト修正とドキュメント更新をコミット完了
  - [x] 2025-10-15: PR 作成準備完了
