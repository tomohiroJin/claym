# Poetry 環境復活計画 仕様書

## 1. 背景
- 現行の DevContainer はグローバル MCP 用に `/opt/mcp-venv` を用意し、Dockerfile で `ENV VIRTUAL_ENV=/opt/mcp-venv` を定義している。
- Poetry は `VIRTUAL_ENV` が設定済みの場合そのパスを優先して使用する仕様のため、プロジェクト固有の `.venv` を使おうとしても `/opt/mcp-venv` を参照し、権限エラーが発生する。
- 既存 README では pip+venv を推奨する暫定策を採用しているが、Poetry ベースの依存管理に戻したい。

## 2. 現状調査結果
- `.devcontainer/Dockerfile` で `ENV VIRTUAL_ENV=/opt/mcp-venv` / `PATH="${VIRTUAL_ENV}/bin:$PATH"` が設定されている。
- コンテナ起動後の `$VIRTUAL_ENV` は常に `/opt/mcp-venv` を指し、権限は root 所有。
- プロジェクト直下には `.venv/` ディレクトリが存在するが、Poetry はこれを使用していない。
- `.zshrc` では PATH を `/usr/bin:/usr/local/bin:$PATH` に調整しているが、`VIRTUAL_ENV` の解除処理はない。
- `scripts/health/checks/tooling.sh` など複数のスクリプトは `"${VIRTUAL_ENV:-/opt/mcp-venv}"` を参照しており、変数が未設定でも `/opt/mcp-venv` をフォールバックとして扱う。

## 2.1 追加調査（類似構成の有無）
- 全プロジェクト／スクリプトを `rg "VIRTUAL_ENV"` で調査した結果、`/opt/mcp-venv` 以外に同様の強制仮想環境は存在しなかった。
- そのため、Poetry 利用に支障をきたしているのは `/opt/mcp-venv` のみと判断できる。

## 3. 影響範囲
- Dockerfile はシステム MCP 用なので変更しない。（グローバル MCP CLI が壊れると困る）
- `~/.zshrc` などユーザーシェル設定、VS Code 側のターミナル設定。
- README / spec / todo など開発フローのドキュメント。
- `scripts/` 以下のテスト・ヘルスチェック（`VIRTUAL_ENV` が未設定でも動作するか確認）。
- `poetry.lock` の維持と `pyproject.toml` の整合性。

## 4. 対応方針
1. **Poetry 実行時に `VIRTUAL_ENV` を解除するラッパーを提供**
   - プロジェクト内に `scripts/run_poetry.sh` を用意し、Poetry コマンド実行前に `unset VIRTUAL_ENV` を行う。
   - ラッパーは `.venv/bin/poetry` を直接呼び出すことで、グローバルな poetry コマンドへの依存を排除。
   - ユーザーは `./scripts/run_poetry.sh env use /usr/bin/python3` や `./scripts/run_poetry.sh run pytest` のように利用し、常に `.venv` が使用される。
   - **実装完了**: 2025-10-15 に修正完了。`.venv/bin/poetry` を直接参照する方式に変更し、動作確認済み。

2. **Poetry への切り替え手順を復活**
   - README に `.venv` 作成→`poetry env use /usr/bin/python3`→`poetry install` の手順を記載。
   - `poetry.toml` / `poetry.lock` をプロジェクト管理に戻す。
   - pip+venv の暫定案はトラブルシュートとして残す（Poetry が使えない場合の fallback）。

3. **スクリプト／ドキュメントの整合性**
   - `scripts/health` への影響確認（`VIRTUAL_ENV` 未設定でも `/opt/mcp-venv` を参照するため、現行のロジックで動作）。
   - `scripts/test.sh` などは `.venv` を前提に実行できるか確認。必要なら `poetry run` を併記。

4. **検証手順の明確化**
   - `./scripts/run_poetry.sh env use /usr/bin/python3` → `./scripts/run_poetry.sh install --no-root` → `./scripts/run_poetry.sh run pytest` の確認。
   - `./scripts/run_poetry.sh env info --path` が `.venv` を指すことを確認。
   - VS Code 統合ターミナルでもラッパースクリプト経由で `.venv` が利用できるか確認。

## 5. 非対応範囲（Out of Scope）
- Dockerfile の ENV 定義を削除・変更すること（システム MCP 用のため）。
- `/opt/mcp-venv` の所有者変更やアンインストール。
- 他プロジェクトへの影響調査（tsumugi-report 内に限定）。

## 6. テスト計画
- ✅ `./scripts/run_poetry.sh env info --path` が `.../tsumugi-report/.venv` を指す。
- ✅ `./scripts/run_poetry.sh install` がエラーなく完了。
- ✅ `./scripts/run_poetry.sh run pytest` が成功（11 passed in 1.09s）。
- ✅ VS Code 統合ターミナルでラッパースクリプト経由で `.venv` を使用。
- ⏳ `scripts/health/checks/tooling.sh` 実行時もエラーが発生しない。（未検証）
- ⏳ `./scripts/run_poetry.sh lock` が最新の依存関係を保持し CI で利用可能。（未検証）

## 7. リスクと緩和策
- **Zsh フックが他ディレクトリでも誤作動**: 条件分岐でパス判定を厳密にし、`tsumugi-report` 配下のみで実行。ドキュメントで `source ~/.zshrc` の注意を記載。
- **VS Code の shell が `.zshrc` を読み込まないケース**: `devcontainer.json` の `"shell": "/bin/zsh"` 等を確認。必要なら `terminal.integrated.defaultProfile.linux` を設定。
- **Poetry キャッシュが残る**: `poetry env remove --all` をドキュメントに追記。
- **Grml.* rocks**:  Global CLI への影響がないか `claude --version` などを再確認。

## 8. 成果物
- ✅ `scripts/run_poetry.sh`: Poetry ラッパースクリプト（2025-10-15 実装完了）
- ✅ README / spec / todo の更新（2025-10-15 更新完了）
- ✅ 検証記録（`./scripts/run_poetry.sh env info` の結果など）
  - Path: `/workspaces/claym/local/projects/tsumugi-report/.venv`
  - Executable: `/workspaces/claym/local/projects/tsumugi-report/.venv/bin/python`
  - Poetry version: 2.2.1
  - Tests: 11 passed in 1.09s

## 9. 実装履歴
- 2025-10-15: 初回実装完了
  - `scripts/run_poetry.sh` をプロジェクトルートの `.venv/bin/poetry` を直接呼び出す方式に修正
  - `VIRTUAL_ENV` を解除し、`.venv` を正しく認識することを確認
  - 全テスト（11件）が成功することを確認
  - 親リポジトリ README とドキュメントを更新
