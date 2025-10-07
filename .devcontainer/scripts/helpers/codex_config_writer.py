#!/usr/bin/env python3
"""Codex MCP の SSE 設定を config.toml に反映するためのユーティリティ。

対象の設定ファイルを安全に解析し、指定サーバーを SSE へ更新したうえで、
書き込みはアトミックに行うためエラー時に破損ファイルが残りません。
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from collections.abc import MutableMapping
from pathlib import Path
from typing import Any, Dict, List, Sequence

try:  # Python 3.11+
    import tomllib  # type: ignore[attr-defined]
except ModuleNotFoundError:  # pragma: no cover - 旧ランタイム向けフォールバック
    import tomli as tomllib  # type: ignore

_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+$")


class ConfigUpdateError(RuntimeError):
    """設定の解析・書き込みに失敗した際に送出する例外。"""


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update Codex MCP SSE server definition inside config.toml."
    )
    parser.add_argument(
        "--config",
        required=True,
        type=Path,
        help="Codex の config.toml へのパス",
    )
    parser.add_argument(
        "--name",
        required=True,
        help="mcp_servers テーブルで更新するサーバー名",
    )
    parser.add_argument(
        "--url",
        required=True,
        help="設定する SSE エンドポイントの URL",
    )
    return parser.parse_args(argv)


def load_config(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:  # pragma: no cover - 呼び出し側へエラーを伝播
        raise ConfigUpdateError(f"{path} の読み込みに失敗しました: {exc.strerror}") from exc

    if not text.strip():
        return {}

    try:
        return tomllib.loads(text)
    except (tomllib.TOMLDecodeError, ValueError) as exc:
        raise ConfigUpdateError(f"{path} の TOML 解析に失敗しました: {exc}") from exc


def update_servers(data: MutableMapping[str, Any], name: str, url: str) -> None:
    mcp_servers = data.setdefault("mcp_servers", {})
    if not isinstance(mcp_servers, MutableMapping):
        raise ConfigUpdateError("config.toml の mcp_servers はテーブルである必要があります")

    existing = mcp_servers.get(name, {})
    if isinstance(existing, MutableMapping):
        server: Dict[str, Any] = dict(existing)
    elif not existing:
        server = {}
    else:
        raise ConfigUpdateError(
            f"mcp_servers に既存の '{name}' エントリがありますがテーブルではありません"
        )

    for key in ("command", "args", "env"):
        server.pop(key, None)

    server["transport"] = "sse"
    server["url"] = url

    mcp_servers[name] = server


def format_key(key: str) -> str:
    if _KEY_RE.match(key):
        return key
    escaped = key.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def format_value(value: Any) -> str:
    if isinstance(value, str):
        escaped = value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        items = ", ".join(format_value(item) for item in value)
        return f"[{items}]"
    raise TypeError(f"未対応の値の型です: {type(value)!r}")


def is_array_of_tables(value: Any) -> bool:
    if not isinstance(value, list) or not value:
        return False
    return all(isinstance(item, dict) for item in value)


def emit_table(path: List[str], table: Dict[str, Any], out_lines: List[str]) -> None:
    out_lines.append(f"[{'.'.join(format_key(part) for part in path)}]")

    nested: List[tuple[str, Dict[str, Any]]] = []
    array_tables: List[tuple[str, List[Dict[str, Any]]]] = []

    for key, value in table.items():
        if isinstance(value, dict):
            nested.append((key, value))
        elif is_array_of_tables(value):
            array_tables.append((key, value))
        else:
            out_lines.append(f"{format_key(str(key))} = {format_value(value)}")

    for key, value in nested:
        if out_lines and out_lines[-1] != "":
            out_lines.append("")
        emit_table(path + [key], value, out_lines)

    for key, items in array_tables:
        for item in items:
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            emit_array_table(path + [key], item, out_lines)


def emit_array_table(
    path: List[str], table: Dict[str, Any], out_lines: List[str]
) -> None:
    out_lines.append(f"[[{'.'.join(format_key(part) for part in path)}]]")

    nested: List[tuple[str, Dict[str, Any]]] = []
    array_tables: List[tuple[str, List[Dict[str, Any]]]] = []

    for key, value in table.items():
        if isinstance(value, dict):
            nested.append((key, value))
        elif is_array_of_tables(value):
            array_tables.append((key, value))
        else:
            out_lines.append(f"{format_key(str(key))} = {format_value(value)}")

    for key, value in nested:
        if out_lines and out_lines[-1] != "":
            out_lines.append("")
        emit_table(path + [key], value, out_lines)

    for key, items in array_tables:
        for item in items:
            if out_lines and out_lines[-1] != "":
                out_lines.append("")
            emit_array_table(path + [key], item, out_lines)


def dump_toml(data: Dict[str, Any]) -> str:
    lines: List[str] = []
    for key, value in data.items():
        if isinstance(value, dict):
            if lines and lines[-1] != "":
                lines.append("")
            emit_table([key], value, lines)
        elif is_array_of_tables(value):
            for item in value:
                if lines and lines[-1] != "":
                    lines.append("")
                emit_array_table([key], item, lines)
        else:
            lines.append(f"{format_key(str(key))} = {format_value(value)}")

    return "\n".join(lines).rstrip() + "\n"


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


def update_codex_config(config_path: Path, name: str, url: str) -> None:
    data = load_config(config_path)
    update_servers(data, name, url)
    body = dump_toml(data)
    atomic_write(config_path, body)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        update_codex_config(args.config, args.name, args.url)
    except (ConfigUpdateError, TypeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


__all__ = [
    "update_codex_config",
    "load_config",
    "dump_toml",
    "parse_args",
]


if __name__ == "__main__":  # pragma: no cover - CLI エントリポイント
    sys.exit(main())
