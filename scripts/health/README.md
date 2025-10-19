# Claym ヘルスチェック スクリプト

このディレクトリには、Claym の開発コンテナをビルド直後や起動直後に検証するためのヘルスチェックがまとまっています。

ヘルスチェックはモジュール構成になっており、`lib/` に実行基盤と共通ヘルパー、`checks/` に個別の診断（システム、ツールチェーン、MCP など）を配置しています。新しいチェックを追加したい場合は、`checks/` にファイルを作成して `register_check` を呼び出すだけで組み込めます。

## check-environment.sh

ルート README で説明している前提条件を低コストで検証します。

- Debian 12 (bookworm) ベースとタイムゾーン設定の確認
- ワークスペースおよび ImageSorcery ログディレクトリがアクセス可能であることの確認
- 主要 CLI (`claude`, `codex`, `gemini`, `uv`, `npx`, `npm`, `rg` など) と Python MCP コマンド (`markitdown-mcp`, `imagesorcery-mcp`, `mcp-github`) の存在チェック
- モダン CLI ツール (`zoxide`, `eza`, `tldr`, `delta`) の存在とバージョン確認
- シェルエイリアス設定（ll, cat, find 等）の確認
- Git delta pager 設定の確認
- CLI バージョン取得によるドリフト検知
- Claude / Codex / Gemini に対する既定 MCP 登録の有無確認
- Serena・Playwright・Python 仮想環境（`/opt/mcp-venv` または `$VIRTUAL_ENV`）で管理される MCP 資産のスポットチェック
- コンテナにエクスポートされている API キー一覧の表示
- `safe.directory` 設定と ImageSorcery ログの参照可否の確認

### 使い方

```bash
# フルチェック（既定）
bash scripts/health/check-environment.sh

# 起動後の簡易チェック
bash scripts/health/check-environment.sh --quick

# JSON 形式のサマリ出力
bash scripts/health/check-environment.sh --json

# チェックID一覧を表示
bash scripts/health/check-environment.sh --list-checks

# 既知の失敗チェックをスキップ
bash scripts/health/check-environment.sh --skip serena-ready
```

終了コードの意味:

- `0`: クリティカルチェックがすべて成功
- `1`: クリティカルチェックに失敗あり
- `2`: 致命的ではない警告のみ

オプションは併用可能です（例: `--quick --json`）。CI や devcontainer フックに組み込むほか、手動診断にも利用できます。

## テストスクリプト

ヘルスチェックスクリプトとコンテナ環境の動作確認用テストスクリプトを提供しています。

### test-health-checks.sh

`check-environment.sh` の基本動作をテストします。

```bash
# テストを実行
bash scripts/health/test-health-checks.sh
```

**テスト内容:**
- スクリプトの基本動作（--help, --list-checks, --json, --quick, --skip オプション）
- 主要チェック項目の存在確認（system-basics, cli-paths, modern-cli-tools, mcp-python-env 等）
- 終了コードの検証

### test-container-basics.sh

コンテナに追加された基本機能をテストします。

```bash
# テストを実行
bash scripts/health/test-container-basics.sh
```

**テスト内容:**
- ベーシックエディタ・ページャ（vim, less, nano）
- システムユーティリティ（man, rsync, zip, net-tools 等）
- モダンCLIツール（zoxide, eza, tldr, delta, btop, hyperfine 等）
- シェル環境（.zshrc, エイリアス設定）
- Git設定（delta pager, safe.directory）
- Python MCP環境（仮想環境、MCP コマンド）
- AI CLIツール（claude, codex, gemini）

### scripts/setup/test-init-ai-configs.sh

AI設定自動セットアップスクリプト (`init-ai-configs.sh`) の動作をテストします。

```bash
# テストを実行
bash scripts/setup/test-init-ai-configs.sh
```

**テスト内容:**
- テンプレートファイルの存在確認
- 実際のプロジェクトでの設定ファイル生成確認
- パス置換機能の確認（Codex, GEMINI）
- .gitignore 更新の確認
