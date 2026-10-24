# shellcheck shell=bash
# 脆弱性（未適用のセキュリティ更新・既知の脆弱性を持つ Python パッケージ）のチェック
#
# どちらもネットワークに出て最新のアドバイザリを取得するため、--quick では実行しない。
# 検出しても致命的とはせず WARN を返す（更新手順は scripts/health/README.md を参照）。
# 検査そのものが失敗したときも PASS にはせず WARN を返す。
#
# テスト用の上書き:
#   SECURITY_DPKG_STATUS    apt の判定に使う dpkg status ファイル（既定: /var/lib/dpkg/status）
#   SECURITY_PYTHON_ENVS    監査する Python 環境のディレクトリ（空白区切り。既定は下記の一覧）
#   SECURITY_PREVIEW_LIMIT  メッセージに並べるパッケージ名の上限（既定: 8）

# pip-audit の版を固定する（実行のたびに最新を取得して挙動が変わるのを避ける）
readonly SECURITY_PIP_AUDIT="pip-audit==2.10.1"

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

# 一覧の先頭だけをメッセージ用に整形する
security_preview() {
  local limit="${SECURITY_PREVIEW_LIMIT:-8}"
  local -a items=("$@")
  local preview="${items[*]:0:$limit}"
  ((${#items[@]} > limit)) && preview+=" ..."
  printf '%s' "$preview"
}

# 監査対象の Python 環境を列挙する（python を持つものだけ・重複なし）
security_python_envs() {
  local -a candidates=()
  if [[ -n "${SECURITY_PYTHON_ENVS:-}" ]]; then
    read -ra candidates <<<"$SECURITY_PYTHON_ENVS"
  else
    # 別の venv を有効にしていても MCP 用の venv は必ず監査する
    candidates=(/opt/mcp-venv "${VIRTUAL_ENV:-}" /opt/serena/.venv)
    local tool_dir
    for tool_dir in "${HOME}/.local/share/uv/tools"/*/; do
      candidates+=("${tool_dir%/}")
    done
  fi
  local env
  for env in "${candidates[@]}"; do
    [[ -n "$env" && -x "$env/bin/python" ]] && printf '%s\n' "$env"
  done | awk '!seen[$0]++'
}

check_apt_security_updates() {
  if ! have apt-get; then
    set_result "WARN" "apt-get not found; cannot check security updates" "Run inside the Ubuntu dev container"
    return
  fi

  # イメージ作成時に /var/lib/apt/lists を消しているため、一覧は一時ディレクトリへ取得する。
  # sudo を使わずに済むようロックを無効にする（docker-clean の後処理は権限不足で失敗するが無害）。
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/lists/partial" "$tmp/cache/archives/partial"
  local -a apt_opts=(
    -o "Dir::State::lists=$tmp/lists"
    -o "Dir::Cache=$tmp/cache"
    -o "Dir::State::status=${SECURITY_DPKG_STATUS:-/var/lib/dpkg/status}"
    -o "Debug::NoLocking=1"
    -o "APT::Sandbox::User=$(id -un)"
  )

  if ! timeout 180 apt-get -qq "${apt_opts[@]}" update >/dev/null 2>&1 \
    || ! compgen -G "$tmp/lists/*_Packages*" >/dev/null; then
    rm -rf "$tmp"
    set_result "WARN" "Could not fetch apt package lists" "Check network access, then re-run this check"
    return
  fi

  # 更新できるパッケージと入っている版を集める。dist-upgrade にするのは、
  # 新しい依存を伴う更新（upgrade では kept back になる）も数えるため。
  local sim
  if ! sim=$(apt-get -s "${apt_opts[@]}" dist-upgrade 2>&1); then
    rm -rf "$tmp"
    set_result "WARN" "apt upgrade simulation failed: $(grep -m1 '^E:' <<<"$sim")" \
      "Run 'sudo apt-get -f install' to repair broken dependencies, then re-run this check"
    return
  fi
  local -A installed=()
  local pkg version
  while read -r pkg version; do
    installed["$pkg"]="$version"
  done < <(awk '/^Inst / && $3 ~ /^\[/ {gsub(/[][]/, "", $3); print $2, $3}' <<<"$sim")

  # Inst 行の出所は候補版の 1 つしか表示されず、-updates と -security の両方にある
  # 更新を見逃す。入っている版より新しい版が -security にあるかを madison で確かめる。
  local -a pending=()
  if ((${#installed[@]})); then
    local name madison_version origin
    while IFS='|' read -r name madison_version origin; do
      name=${name// /}
      madison_version=${madison_version// /}
      [[ "$origin" == *-security* ]] || continue
      [[ -n "${installed[$name]:-}" ]] || continue
      if dpkg --compare-versions "$madison_version" gt "${installed[$name]}"; then
        pending+=("$name")
        unset 'installed[$name]'
      fi
    done < <(apt-cache "${apt_opts[@]}" madison "${!installed[@]}" 2>/dev/null || true)
  fi
  rm -rf "$tmp"

  if ((${#pending[@]})); then
    set_result "WARN" "${#pending[@]} security updates pending: $(security_preview "${pending[@]}")" \
      "sudo apt-get update && sudo apt-get upgrade -y (or rebuild the container without cache)"
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
  local env name file
  for env in "${envs[@]}"; do
    name=$(basename "${env%/.venv}")
    # 結果ファイル名はパス全体から作る（basename だけだと別の環境と衝突する）
    file="$tmp/$(tr '/' '_' <<<"$env")"
    # 編集可能インストールと直接 URL 指定は PyPI で照合できないので除く。
    # 同名パッケージが重複して出ることがある（nvidia-* 等）ため先勝ちで1つにする。
    # 空の venv では grep が 1 を返すが、errexit で検査全体を落とさないよう失敗を許す。
    { uv pip freeze --python "$env/bin/python" 2>/dev/null || true; } \
      | { grep -vE '^(-e |.* @ )' || true; } \
      | awk -F'==' '!seen[tolower($1)]++' >"$file.txt"
    if [[ ! -s "$file.txt" ]]; then
      continue
    fi

    # pip-audit は脆弱性があると終了コード 1 を返すので、成否は JSON の有無で判断する
    uvx --quiet "$SECURITY_PIP_AUDIT" -r "$file.txt" --no-deps --disable-pip \
      --progress-spinner off "${ignore_args[@]}" -f json -o "$file.json" >/dev/null 2>&1 || true
    if [[ ! -s "$file.json" ]]; then
      errors+=("$name")
      continue
    fi

    local line
    while IFS= read -r line; do
      [[ -n "$line" ]] && findings+=("$name: $line")
    done < <(python3 - "$file.json" <<'PY' || true
import json, sys
data = json.load(open(sys.argv[1]))
for dep in data.get("dependencies", []):
    vulns = dep.get("vulns") or []
    if not vulns:
        continue
    # pip-audit は同じ脆弱性を重複して返すことがあるので ID で数える
    ids = {vuln["id"] for vuln in vulns}
    fixes = sorted({v for vuln in vulns for v in vuln.get("fix_versions", [])})
    fix = f" -> {fixes[-1]}" if fixes else " (no fix)"
    print(f"{dep['name']} {dep['version']} ({len(ids)}){fix}")
PY
    )
  done
  rm -rf "$tmp"

  local -a parts=()
  if ((${#findings[@]})); then
    local joined
    joined=$(printf '%s; ' "${findings[@]}")
    parts+=("Vulnerable Python packages — ${joined%; }")
  fi
  if ((${#errors[@]})); then
    parts+=("pip-audit failed for: ${errors[*]}")
  fi
  if ((${#parts[@]})); then
    local message
    message=$(printf '%s / ' "${parts[@]}")
    set_result "WARN" "${message% / }" \
      "Upgrade to the fixed versions (see scripts/health/README.md); add accepted risks to SECURITY_IGNORED_VULNS with a reason"
    return
  fi

  set_result "PASS" "No known vulnerabilities in ${#envs[@]} Python environments" ""
}

register_check "apt-security-updates" "Ubuntu security updates" false false check_apt_security_updates
register_check "python-vulnerabilities" "Python package vulnerabilities" false false check_python_vulnerabilities
