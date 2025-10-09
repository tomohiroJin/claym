#!/usr/bin/env python3
"""
fastmcp 2.3.4 では ServerSettings.dependencies に default と default_factory が同時定義されており、
pydantic>=2.11 環境では import 時に例外が発生します。上流の修正が取り込まれるまでの暫定対応として、
インストール済みモジュールへパッチを適用し、Docker ビルドを継続できるようにします。
"""
from __future__ import annotations
import sysconfig
from pathlib import Path

settings_path = Path(sysconfig.get_path("purelib")) / "fastmcp" / "settings.py"
text = settings_path.read_text()
needle = "    ] = []"
if needle in text:
    settings_path.write_text(text.replace(needle, "    ]", 1))
    print("fastmcp の設定ファイルをパッチしました")
else:
    print("fastmcp の設定パッチをスキップしました（既に修正済みです）")
