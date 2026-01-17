#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

if ! command -v bear >/dev/null 2>&1; then
  echo "[devcontainer] WARN: bear not found; skip compile_commands.json generation"
  exit 0
fi

out="${repo_root}/compile_commands.json"
force=0
mode="os"
for arg in "$@"; do
  case "${arg}" in
    --all) mode="all" ;;
    --force) force=1 ;;
    *) ;;
  esac
done

if [[ "${force}" -ne 1 ]] && [[ -f "${out}" ]]; then
  if command -v jq >/dev/null 2>&1; then
    existing_len="$(jq 'length' "${out}" 2>/dev/null || echo 0)"
    if [[ "${existing_len}" =~ ^[0-9]+$ ]] && [[ "${existing_len}" -gt 0 ]]; then
      echo "[devcontainer] compile_commands.json already exists; skip (use --force to regenerate)"
      exit 0
    fi
  else
    if [[ -s "${out}" ]]; then
      echo "[devcontainer] compile_commands.json already exists; skip (use --force to regenerate)"
      exit 0
    fi
  fi
fi

targets=()
if [[ "${mode}" == "all" ]]; then
  targets=(all)
else
  targets=(-C code/os all)
fi

tmp="$(mktemp -t compile_commands.XXXXXX.json)"

echo "[devcontainer] Generating compilation database with bear -> ${out}"
echo "[devcontainer] Tip: re-run with: bash .devcontainer/gen_compile_commands.sh --all --force"

make_cmd=(make "${targets[@]}")
if ! bear --output "${tmp}" -- "${make_cmd[@]}"; then
  echo "[devcontainer] WARN: bear/make failed; clangd may use fallback flags only"
  rm -f "${tmp}" || true
  exit 0
fi

tmp_len=0
if command -v jq >/dev/null 2>&1; then
  tmp_len="$(jq 'length' "${tmp}" 2>/dev/null || echo 0)"
fi

if [[ ! -s "${tmp}" ]] || [[ "${tmp_len}" == "0" ]]; then
  rm -f "${tmp}" || true
  tmp="$(mktemp -t compile_commands.XXXXXX.json)"
  echo "[devcontainer] No compile commands captured (incremental build?) -> retry with make -B"
  make_cmd=(make -B "${targets[@]}")
  if ! bear --output "${tmp}" -- "${make_cmd[@]}"; then
    echo "[devcontainer] WARN: bear/make -B failed; clangd may use fallback flags only"
    rm -f "${tmp}" || true
    exit 0
  fi
fi

tmp_len=0
if command -v jq >/dev/null 2>&1; then
  tmp_len="$(jq 'length' "${tmp}" 2>/dev/null || echo 0)"
fi

if [[ ! -s "${tmp}" ]] || [[ "${tmp_len}" == "0" ]]; then
  echo "[devcontainer] WARN: bear produced an empty compilation database"
  rm -f "${tmp}" || true
  exit 0
fi

mv "${tmp}" "${out}"
echo "[devcontainer] OK: wrote ${out}"
