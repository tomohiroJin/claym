#!/usr/bin/env bash
# imagesorcery.sh
# imagesorcery-mcp のログディレクトリを動的に解決するヘルパー。

imagesorcery_log_dirs() {
  local venv="/opt/pipx/venvs/imagesorcery-mcp"
  local python="$venv/bin/python"
  local output

  if [[ -x "$python" ]]; then
    if output="$($python - <<'PY2'
import pathlib
try:
    import imagesorcery_mcp
except Exception:
    raise SystemExit(0)
path = pathlib.Path(imagesorcery_mcp.__file__).parent / "logs"
print(path)
PY2
)"; then
      if [[ -n "$output" ]]; then
        printf '%s\n' "$output"
        return 0
      fi
    fi
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  python3 - <<'PY3'
from pathlib import Path
base = Path('/opt/pipx/venvs/imagesorcery-mcp')
lib = base / 'lib'
paths = []
if lib.is_dir():
    for candidate in sorted(lib.glob('python*/site-packages/imagesorcery_mcp/logs')):
        paths.append(candidate)
for path in paths:
    print(path)
PY3
}
