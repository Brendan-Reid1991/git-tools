#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for script in git-superadd git-newbranch git-superpush; do
  if [[ ! -x "${ROOT_DIR}/bin/${script}" ]]; then
    echo "Missing executable bit: bin/${script}" >&2
    exit 1
  fi
done

TMP_PREFIX="$(mktemp -d)"
TMP_WORKDIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_PREFIX}" "${TMP_WORKDIR}"
}
trap cleanup EXIT

make -C "${ROOT_DIR}" PREFIX="${TMP_PREFIX}" install >/dev/null

for script in git-superadd git-newbranch git-superpush; do
  output="$(
    cd "${TMP_WORKDIR}" &&
      PATH="${TMP_PREFIX}/bin:${PATH}" "${script}" 2>&1 || true
  )"

  if [[ "${output}" == *"No such file or directory"* ]]; then
    echo "Installed ${script} failed to load dependencies:" >&2
    echo "${output}" >&2
    exit 1
  fi

  if [[ "${output}" != *"not inside a Git repository."* ]]; then
    echo "Unexpected output from installed ${script}:" >&2
    echo "${output}" >&2
    exit 1
  fi
done

make -C "${ROOT_DIR}" PREFIX="${TMP_PREFIX}" uninstall >/dev/null

echo "Smoke checks passed."
