#!/usr/bin/env python3
"""
fastmcp 2.3.4 ships a ServerSettings.dependencies field that defines both
default and default_factory, which pydantic>=2.11 rejects on import. Patch the
installed module so the Docker build can succeed until the upstream package
is fixed.
"""
from __future__ import annotations
import sysconfig
from pathlib import Path

settings_path = Path(sysconfig.get_path("purelib")) / "fastmcp" / "settings.py"
text = settings_path.read_text()
needle = "    ] = []"
if needle in text:
    settings_path.write_text(text.replace(needle, "    ]", 1))
    print("fastmcp settings patched successfully")
else:
    print("Skipping fastmcp settings patch; snippet already updated.")
