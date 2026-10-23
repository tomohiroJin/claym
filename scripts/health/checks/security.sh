# shellcheck shell=bash
# 脆弱性（未適用のセキュリティ更新・既知の脆弱性を持つ Python パッケージ）のチェック
#
# どちらもネットワークに出て最新のアドバイザリを取得するため、--quick では実行しない。
# 検出しても致命的とはせず WARN を返す（更新手順は scripts/health/README.md を参照）。
#
# テスト用の上書き:
#   SECURITY_DPKG_STATUS  apt の判定に使う dpkg status ファイル（既定: /var/lib/dpkg/status）
#   SECURITY_PYTHON_ENVS  監査する Python 環境のディレクトリ（空白区切り。既定は下記の一覧）

# 既知の例外（修正版が無い、またはこの環境では到達しない脆弱性）。
# 追加するときは、なぜ当たらないかを必ず書くこと。
#   PYSEC-2026-2475: fastmcp — Windows で `fastmcp install` に渡すサーバ名のコマンド注入。
#                    imagesorcery-mcp の都合で fastmcp<3 に固定しており、修正版 3.2.0 は入れられない
#   PYSEC-2026-2476: fastmcp — GitHub OAuthProxy の同意検証漏れ。この環境は stdio 起動で OAuthProxy を使わない
#   PYSEC-2026-2447: diskcache — キャッシュディレクトリに書き込める攻撃者による pickle 経由の実行。修正版なし
SECURITY_IGNORED_VULNS=(
  PYSEC-2026-2475
  PYSEC-2026-2476
  PYSEC-2026-2447
)

# 監査対象の Python 環境を列挙する（存在するものだけ）
security_python_envs() {
  if [[ -n "${SECURITY_PYTHON_ENVS:-}" ]]; then
    local -a overrides=()
    read -ra overrides <<<"$SECURITY_PYTHON_ENVS"
    printf '%s\n' "${overrides[@]}"
    return
  fi
  local -a candidates=(
    "${VIRTUAL_ENV:-/opt/mcp-venv}"
    /opt/serena/.venv
  )
  local tool_dir
  for tool_dir in "${HOME}/.local/share/uv/tools"/*/; do
    candidates+=("${tool_dir%/}")
  done
  local env
  for env in "${candidates[@]}"; do
    [[ -x "$env/bin/python" ]] && printf '%s\n' "$env"
  done
}

check_apt_security_updates() {
  if ! have apt-get; then
    set_result "WARN" "apt-get not found; cannot check security updates" "Run inside the Ubuntu dev container"
    return
  fi

  # イメージ作成時に /var/lib/apt/lists を消しているため、一覧は一時ディレクトリへ取得する。
  # sudo を使わずに済むよう、ロックと docker-clean の後処理を無効にする。
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/lists/partial" "$tmp/cache/archives/partial"
  local -a apt_opts=(
    -o "Dir::State::lists=$tmp/lists"
    -o "Dir::Cache=$tmp/cache"
    -o "Dir::State::status=${SECURITY_DPKG_STATUS:-/var/lib/dpkg/status}"
    -o "Debug::NoLocking=1"
    -o "APT::Sandbox::User=$(id -un)"
    -o "APT::Update::Post-Invoke::="
    -o "APT::Update::Post-Invoke-Success::="
  )

  if ! timeout 180 apt-get -qq "${apt_opts[@]}" update >/dev/null 2>&1 \
    || ! compgen -G "$tmp/lists/*_Packages*" >/dev/null; then
    rm -rf "$tmp"
    set_result "WARN" "Could not fetch apt package lists" "Check network access, then re-run this check"
    return
  fi

  local -a pending=()
  mapfile -t pending < <(apt-get -s "${apt_opts[@]}" upgrade 2>/dev/null \
    | awk '/^Inst / && /-security/ {print $2}')
  rm -rf "$tmp"

  if ((${#pending[@]})); then
    local preview="${pending[*]:0:8}"
    ((${#pending[@]} > 8)) && preview+=" ..."
    set_result "WARN" "${#pending[@]} security updates pending: ${preview}" \
      "sudo apt-get update && sudo apt-get upgrade -y (rebuilding the container also applies them)"
    return
  fi

  set_result "PASS" "No pending Ubuntu security updates" ""
}

check_python_vulnerabilities() {
  if ! have uv; then
    set_result "WARN" "uv not found; cannot run pip-audit" "Rebuild the dev container to restore uv"
    return
  fi

  local -a envs=()
  mapfile -t envs < <(security_python_envs)
  if ((${#envs[@]} == 0)); then
    set_result "WARN" "No Python environments found to audit" "Check VIRTUAL_ENV or SECURITY_PYTHON_ENVS"
    return
  fi

  local -a ignore_args=()
  local id
  for id in "${SECURITY_IGNORED_VULNS[@]}"; do
    ignore_args+=(--ignore-vuln "$id")
  done

  local tmp
  tmp=$(mktemp -d)
  local -a findings=() errors=()
  local env name
  for env in "${envs[@]}"; do
    name=$(basename "${env%/.venv}")
    # 編集可能インストールと直接 URL 指定は PyPI で照合できないので除く。
    # 同名パッケージが重複して出ることがある（nvidia-* 等）ため先勝ちで1つにする。
    uv pip freeze --python "$env/bin/python" 2>/dev/null \
      | grep -vE '^(-e |.* @ )' \
      | awk -F'==' '!seen[tolower($1)]++' >"$tmp/$name.txt"

    # pip-audit は脆弱性があると終了コード 1 を返すので、成否は JSON の有無で判断する
    uvx --quiet pip-audit -r "$tmp/$name.txt" --no-deps --disable-pip \
      --progress-spinner off "${ignore_args[@]}" -f json -o "$tmp/$name.json" >/dev/null 2>&1 || true
    if [[ ! -s "$tmp/$name.json" ]]; then
      errors+=("$name")
      continue
    fi

    local line
    while IFS= read -r line; do
      [[ -n "$line" ]] && findings+=("$name: $line")
    done < <(python3 - "$tmp/$name.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for dep in data.get("dependencies", []):
    vulns = dep.get("vulns") or []
    if not vulns:
        continue
    fixes = sorted({v for vuln in vulns for v in vuln.get("fix_versions", [])})
    fix = f" -> {fixes[-1]}" if fixes else " (no fix)"
    print(f"{dep['name']} {dep['version']} ({len(vulns)}){fix}")
PY
    )
  done
  rm -rf "$tmp"

  if ((${#findings[@]})); then
    local message
    message=$(printf '%s; ' "${findings[@]}")
    message=${message%; }
    set_result "WARN" "Vulnerable Python packages — ${message}" \
      "Upgrade to the fixed versions (see scripts/health/README.md); add accepted risks to SECURITY_IGNORED_VULNS with a reason"
    return
  fi
  if ((${#errors[@]})); then
    set_result "WARN" "pip-audit failed for: ${errors[*]}" "Check network access to PyPI / OSV, then re-run this check"
    return
  fi

  set_result "PASS" "No known vulnerabilities in ${#envs[@]} Python environments" ""
}

register_check "apt-security-updates" "Ubuntu security updates" false false check_apt_security_updates
register_check "python-vulnerabilities" "Python package vulnerabilities" false false check_python_vulnerabilities
