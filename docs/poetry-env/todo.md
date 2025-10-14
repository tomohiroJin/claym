# TODO（Poetry 環境復活タスク）

各項目は振る舞いベースの確認観点です。作業に着手したら RED → GREEN → REFACTOR の順で進め、完了後チェックを入れてください。

- [x] **Poetry ラッパースクリプトの作成**
  - GIVEN: Python CLI が `/opt/mcp-venv` を指している
  - WHEN: `./scripts/run_poetry.sh <command>` を実行
  - THEN: `VIRTUAL_ENV` が解除された状態で Poetry が `.venv` を利用する

- [x] **Poetry 再初期化**
  - GIVEN: ラッパースクリプト経由で実行
  - WHEN: `./scripts/run_poetry.sh env use /usr/bin/python3 && ./scripts/run_poetry.sh install --no-root`
  - THEN: `.venv` 配下に Poetry 仮想環境が作成され、必要な依存をインストールできる（ネットワーク制約がある場合は `poetry install` が失敗する旨を README に記載）

- [x] **Poetry 実行確認**
  - GIVEN: `.venv` が有効な状態
  - WHEN: `poetry run pytest`
  - THEN: 既存のユニットテスト（11件）がすべて PASS する

- [ ] **VS Code ターミナル確認**
  - GIVEN: VS Code 統合ターミナルを開く
  - WHEN: `poetry env info --path` を実行
  - THEN: `.venv` のパスが表示され `/opt/mcp-venv` が使われていない

- [ ] **ヘルスチェック整合性**
  - GIVEN: `scripts/health/check-environment.sh` を実行
  - WHEN: MCP Python 環境のチェックが走る
  - THEN: `VIRTUAL_ENV` を解除していても `PASS` または既存と同等のステータスになる

- [x] **類似環境変数の確認**
  - GIVEN: Workspace 全体を検索
  - WHEN: `rg "VIRTUAL_ENV"` を実行
  - THEN: `/opt/mcp-venv` 以外に同等の仕組みが存在しないことを確認

- [ ] **ドキュメント更新**
  - GIVEN: README / spec / todo (本体) が現状に追随していない
  - WHEN: Poetry 手順を再度記載し、pip+venv はトラブルシュートとして移す
  - THEN: 開発フローの記述が Poerty を標準とした形に統一される

- [ ] **バックワード確認**
  - GIVEN: `/opt/mcp-venv` を用いるグローバル MCP CLI
  - WHEN: `claude --version` などを実行
  - THEN: 既存 CLI が影響を受けず動作する

- [ ] **コミット & PR 準備**
  - GIVEN: 上記の動作確認が完了
  - WHEN: Git で差分を確認しテストログを添付
  - THEN: `feature/poetry-env` ブランチへコミットし、レビュー用の PR が準備できている
