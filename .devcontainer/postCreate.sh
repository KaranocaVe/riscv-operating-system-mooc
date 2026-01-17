#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

echo "[devcontainer] Shell setup (zsh)"
home_dir="${HOME:-}"
if [[ -z "${home_dir}" || "${home_dir}" == "/" ]]; then
  home_dir="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)"
fi

if [[ -z "${home_dir}" || ! -d "${home_dir}" ]]; then
  echo "[devcontainer] WARN: Could not determine HOME; skip zsh dotfile setup"
else
  if [[ -r /etc/skel/.zshrc ]]; then
    if [[ ! -f "${home_dir}/.zshrc" ]] || grep -q "Minimal, non-interactive-safe zsh init for devcontainer" "${home_dir}/.zshrc"; then
      cp /etc/skel/.zshrc "${home_dir}/.zshrc" || true
    fi
  fi
  for f in .zshenv .zprofile; do
    if [[ -r "/etc/skel/${f}" ]] && [[ ! -f "${home_dir}/${f}" ]]; then
      cp "/etc/skel/${f}" "${home_dir}/${f}" || true
    fi
  done
fi

echo "[devcontainer] Tool versions"
riscv64-unknown-elf-gcc --version | head -n 1
qemu-system-riscv32 --version | head -n 1
gdb-multiarch --version | head -n 1

echo "[devcontainer] Build: code/os/01-helloRVOS"
make -C code/os/01-helloRVOS

echo "[devcontainer] Smoke run: qemu-system-riscv32 (wait up to 10s for UART output)"
log_file="$(mktemp -t rvos-qemu.XXXXXX)"
qemu_pid=""

cleanup() {
  if [[ -n "${qemu_pid}" ]] && kill -0 "${qemu_pid}" 2>/dev/null; then
    kill "${qemu_pid}" 2>/dev/null || true
    sleep 0.2
    kill -9 "${qemu_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

qemu-system-riscv32 -nographic -smp 1 -machine virt -bios none \
  -kernel code/os/01-helloRVOS/out/os.elf \
  >"${log_file}" 2>&1 &
qemu_pid="$!"

found=0
for _ in $(seq 1 100); do
  if grep -q "Hello, RVOS!" "${log_file}"; then
    found=1
    break
  fi
  if ! kill -0 "${qemu_pid}" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ "${found}" -ne 1 ]]; then
  echo "[devcontainer] ERROR: QEMU did not print expected output in time."
  echo "[devcontainer] QEMU log: ${log_file}"
  tail -n 50 "${log_file}" || true
  exit 1
fi

echo "[devcontainer] OK: QEMU printed: Hello, RVOS!"
rm -f "${log_file}"

echo "[devcontainer] clangd: generate compile_commands.json (bear)"
bash .devcontainer/gen_compile_commands.sh || true
