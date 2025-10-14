# TODO（Poetry 環境復活タスク）

各項目は振る舞いベースの確認観点です。作業に着手したら RED → GREEN → REFACTOR の順で進め、完了後チェックを入れてください。

- [ ] **環境変数リセット**
  - GIVEN: `tsumugi-report` 直下で新しいシェルを開く
  - WHEN: シェル初期化処理が実行される
  - THEN: `echo $VIRTUAL_ENV` が空になっている

- [ ] **Poetry 再初期化**
  - GIVEN: `VIRTUAL_ENV` を解除した状態
  - WHEN: `poetry env use /usr/bin/python3 && poetry install`
  - THEN: `.venv` 配下に Poetry 仮想環境が作成され、依存インストールが成功する

- [ ] **Poetry 実行確認**
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

- [ ] **類似環境変数の確認**
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
