"""Codex MCP 用設定スクリプトのテスト。"""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

try:  # Python 3.11+
    import tomllib  # type: ignore[attr-defined]
except ModuleNotFoundError:  # pragma: no cover - 旧ランタイム向けフォールバック
    import tomli as tomllib  # type: ignore

MODULE_PATH = Path(__file__).resolve().parents[1] / "helpers" / "codex_config_writer.py"
spec = importlib.util.spec_from_file_location("codex_config_writer", MODULE_PATH)
if spec is None or spec.loader is None:  # pragma: no cover - 読み込み不能時は即エラー
    raise ImportError(f"{MODULE_PATH} から codex_config_writer を読み込めませんでした")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CodexConfigWriterTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmpdir.cleanup)
        self.config_path = Path(self._tmpdir.name) / "config.toml"

    def _read(self) -> dict:
        return tomllib.loads(self.config_path.read_text(encoding="utf-8"))

    def test_creates_new_config(self) -> None:
        module.update_codex_config(
            self.config_path,
            name="sample-server",
            url="https://example.com/stream",
        )

        data = self._read()
        self.assertIn("mcp_servers", data)
        server = data["mcp_servers"]["sample-server"]
        self.assertEqual(server["transport"], "sse")
        self.assertEqual(server["url"], "https://example.com/stream")

    def test_replaces_command_args_env(self) -> None:
        self.config_path.write_text(
            """
[mcp_servers]
  [mcp_servers."sample-server"]
  command = "run"
  args = ["--foo"]
  env = { KEY = "VALUE" }
  transport = "ipc"
  url = "ipc://socket"
""".strip()
            + "\n",
            encoding="utf-8",
        )

        module.update_codex_config(
            self.config_path,
            name="sample-server",
            url="https://example.com/stream",
        )

        data = self._read()
        server = data["mcp_servers"]["sample-server"]
        self.assertNotIn("command", server)
        self.assertNotIn("args", server)
        self.assertNotIn("env", server)
        self.assertEqual(server["transport"], "sse")
        self.assertEqual(server["url"], "https://example.com/stream")

    def test_preserves_other_top_level_entries(self) -> None:
        self.config_path.write_text(
            """
log_level = "debug"

[mcp_servers]
  [mcp_servers.other]
  transport = "sse"
  url = "https://other.example"
""".strip()
            + "\n",
            encoding="utf-8",
        )

        module.update_codex_config(
            self.config_path,
            name="sample-server",
            url="https://example.com/stream",
        )

        data = self._read()
        self.assertEqual(data["log_level"], "debug")
        self.assertIn("other", data["mcp_servers"])
        self.assertIn("sample-server", data["mcp_servers"])


if __name__ == "__main__":  # pragma: no cover - allow direct invocation
    unittest.main()
