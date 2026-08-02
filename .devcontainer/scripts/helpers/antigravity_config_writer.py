#!/usr/bin/env python3
"""Antigravity CLI の MCP 設定 (mcp_config.json) を更新するためのユーティリティ。

Antigravity CLI には `mcp add` に相当するサブコマンドが存在せず、MCP サーバは
JSON 設定ファイルを直接編集して登録する仕様です（対話 UI の /mcp か手編集）。
そのため本スクリプトで冪等なマージ書き込みを行います。

設定ファイルの既定パス:
  - グローバル : ~/.gemini/config/mcp_config.json
  - ワークスペース: <workspace>/.agents/mcp_config.json

スキーマ:
  {
    "mcpServers": {
      "<name>": {
        "command": "...",          # stdio 起動時
        "args": ["..."],
        "env": {"KEY": "VALUE"},
        "serverUrl": "https://...", # リモート接続時（command と排他）
        "headers": {"Authorization": "..."}
      }
    }
  }

書き込みはアトミックに行うため、エラー時に破損したファイルが残りません。
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, Sequence


class ConfigUpdateError(RuntimeError):
    """設定の解析・書き込みに失敗した際に送出する例外。"""


def default_config_path() -> Path:
    """既定のグローバル設定パスを返す。環境変数で上書き可能。"""
    override = os.environ.get("ANTIGRAVITY_MCP_CONFIG")
    if override:
        return Path(override)
    return Path.home() / ".gemini" / "config" / "mcp_config.json"


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Register an MCP server into Antigravity CLI's mcp_config.json."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="mcp_config.json へのパス（既定: ~/.gemini/config/mcp_config.json）",
    )
    parser.add_argument(
        "--name",
        required=True,
        help="mcpServers に登録するサーバー名",
    )
    parser.add_argument(
        "--url",
        default=None,
        help="リモート MCP の URL（指定時は serverUrl として登録し command は使わない）",
    )
    parser.add_argument(
        "--env",
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="MCP サーバへ渡す環境変数（複数指定可）",
    )
    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="stdio 起動コマンドと引数（--url 未指定なら必須）",
    )
    return parser.parse_args(argv)


def parse_env_pairs(pairs: Sequence[str]) -> Dict[str, str]:
    env: Dict[str, str] = {}
    for pair in pairs:
        key, sep, value = pair.partition("=")
        if not sep or not key:
            raise ConfigUpdateError(f"環境変数は KEY=VALUE 形式で指定してください: {pair}")
        env[key] = value
    return env


def load_config(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ConfigUpdateError(f"{path} の読み込みに失敗しました: {exc.strerror}") from exc

    if not text.strip():
        return {}

    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ConfigUpdateError(f"{path} の JSON 解析に失敗しました: {exc}") from exc

    if not isinstance(data, dict):
        raise ConfigUpdateError(f"{path} のトップレベルはオブジェクトである必要があります")
    return data


def build_server_entry(
    argv_command: Sequence[str], url: str | None, env: Dict[str, str]
) -> Dict[str, Any]:
    server: Dict[str, Any] = {}

    if url:
        server["serverUrl"] = url
    else:
        if not argv_command:
            raise ConfigUpdateError("--url を指定しない場合は起動コマンドが必要です")
        server["command"] = argv_command[0]
        if len(argv_command) > 1:
            server["args"] = list(argv_command[1:])

    if env:
        server["env"] = env
    return server


def update_servers(data: Dict[str, Any], name: str, server: Dict[str, Any]) -> None:
    mcp_servers = data.setdefault("mcpServers", {})
    if not isinstance(mcp_servers, dict):
        raise ConfigUpdateError("mcpServers はオブジェクトである必要があります")
    # 既存エントリは丸ごと置き換える（command/serverUrl の混在を防ぐため）
    mcp_servers[name] = server


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    fd, tmp_path = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
    except Exception as exc:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise ConfigUpdateError(f"{path} の書き込みに失敗しました: {exc}") from exc


def update_antigravity_config(
    config_path: Path,
    name: str,
    argv_command: Sequence[str],
    url: str | None = None,
    env: Dict[str, str] | None = None,
) -> None:
    data = load_config(config_path)
    server = build_server_entry(argv_command, url, env or {})
    update_servers(data, name, server)
    atomic_write(config_path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    # argparse.REMAINDER は先頭の "--" を残すため取り除く
    command = list(args.command)
    if command and command[0] == "--":
        command = command[1:]

    try:
        update_antigravity_config(
            args.config or default_config_path(),
            args.name,
            command,
            args.url,
            parse_env_pairs(args.env),
        )
    except ConfigUpdateError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


__all__ = [
    "update_antigravity_config",
    "default_config_path",
    "load_config",
    "parse_args",
]


if __name__ == "__main__":  # pragma: no cover - CLI エントリポイント
    sys.exit(main())
