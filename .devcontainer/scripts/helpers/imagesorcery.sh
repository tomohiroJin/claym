#!/usr/bin/env bash
# imagesorcery.sh
# imagesorcery-mcp のログディレクトリを動的に解決するヘルパー。

imagesorcery_log_dirs() {
  local -a bases=()
  local -A seen=()
  local -a results=()
  local base python output

  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    bases+=("${VIRTUAL_ENV}")
  fi
  bases+=("/opt/pipx/venvs/imagesorcery-mcp" "/opt/mcp-venv")

  for base in "${bases[@]}"; do
    [[ -z "$base" ]] && continue
    python="$base/bin/python"
    if [[ ! -x "$python" ]]; then
      continue
    fi
    if output="$($python - <<'PY2'
import pathlib
import sys
try:
    import imagesorcery_mcp
except Exception:
    raise SystemExit(1)
path = pathlib.Path(imagesorcery_mcp.__file__).parent / "logs"
print(path)
PY2
)"; then
      if [[ -n "$output" && -z "${seen[$output]:-}" ]]; then
        results+=("$output")
        seen[$output]=1
      fi
    fi
  done

  if ((${#results[@]} > 0)); then
    printf '%s\n' "${results[@]}"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  printf '%s\n' "${bases[@]}" | python3 - <<'PY3'
from pathlib import Path
import sys

bases = []
seen = set()
for line in sys.stdin:
    raw = line.strip()
    if not raw:
        continue
    path = Path(raw)
    if path in seen:
        continue
    seen.add(path)
    bases.append(path)

paths = []
for base in bases:
    lib = base / 'lib'
    if not lib.is_dir():
        continue
    for candidate in sorted(lib.glob('python*/site-packages/imagesorcery_mcp/logs')):
        path_str = str(candidate)
        if path_str not in paths:
            paths.append(path_str)

for path in paths:
    print(path)
PY3
}
