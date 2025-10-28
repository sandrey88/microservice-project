#!/usr/bin/env bash
set -euo pipefail

# This script installs Docker Engine, Docker Compose v2 (plugin), Python >= 3.9, and Django on Ubuntu/Debian.
# It is idempotent: it checks existing installations and skips already-installed tools.

# FIX: Redirect log and warn to stderr (1>&2) so command substitution ($(function)) only captures the final result (like VENV_DIR).
log() { echo -e "[INFO] $*" 1>&2; }
warn() { echo -e "[WARN] $*" 1>&2; }
err() { echo -e "[ERROR] $*" 1>&2; }

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    err "This script supports Ubuntu/Debian (needs apt-get)."
    exit 1
  fi
}

ensure_sudo() {
  if [ "${EUID}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      export SUDO=sudo
    else
      err "Please run as root or install sudo."
      exit 1
    fi
  else
    export SUDO=""
  fi
}

update_apt_cache_once() {
  if [ "${APT_UPDATED:-0}" -eq 0 ]; then
    log "Updating apt package index..."
    ${SUDO} apt-get update -y
    export APT_UPDATED=1
  fi
}

install_packages() {
  update_apt_cache_once
  ${SUDO} apt-get install -y "$@"
}

check_python_version() {
  if command -v python3 >/dev/null 2>&1; then
    local ver
    ver=$(python3 -c 'import sys; print("%d.%d"%sys.version_info[:2])')
    # Compare versions: needs >= 3.9
    if python3 - <<'PY'
import sys
req=(3,9)
cur=sys.version_info[:2]
raise SystemExit(0 if cur>=req else 1)
PY
    then
      echo "$ver"
      return 0
    fi
  fi
  return 1
}

install_python() {
  if check_python_version >/dev/null; then
    log "Python3 already satisfies version requirement (>= 3.9). Version: $(python3 -V 2>&1)"
  else
    log "Installing Python3 and pip (trying distro packages)..."
    # Try common packages that provide modern Python on Ubuntu/Debian.
    # On Ubuntu 22.04+, python3 is 3.10+. On Debian 12, it's 3.11.
    install_packages python3 python3-pip python3-venv
    if ! check_python_version >/dev/null; then
      warn "Distro python3 is < 3.9. Consider enabling a newer repo (e.g. deadsnakes for Ubuntu) or upgrading OS."
      warn "Proceeding, but Django may require newer Python on some versions."
    fi
  fi

  if command -v pip3 >/dev/null 2>&1; then
    log "pip3 already installed: $(pip3 --version)"
  else
    log "Installing pip3..."
    install_packages python3-pip
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return
  fi
  log "Installing Docker Engine..."
  require_apt
  update_apt_cache_once
  install_packages ca-certificates curl gnupg lsb-release apt-transport-https

  # Add Docker's official GPG key
  install_dir=/etc/apt/keyrings
  ${SUDO} mkdir -p "$install_dir"
  if [ ! -f "$install_dir/docker.gpg" ]; then
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | ${SUDO} gpg --dearmor -o "$install_dir/docker.gpg"
  fi

  # Add Docker repository
  codename=$(. /etc/os-release; echo "$VERSION_CODENAME")
  if [ -z "${codename}" ]; then codename="stable"; fi
  repo_line="deb [arch=$(dpkg --print-architecture) signed-by=$install_dir/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo $ID) $codename stable"
  if ! grep -q "download.docker.com/linux" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "$repo_line" | ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  ${SUDO} apt-get update -y
  install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Enable and start
  if command -v systemctl >/dev/null 2>&1; then
    ${SUDO} systemctl enable --now docker || true
  fi

  log "Docker installed: $(docker --version)"
}

install_docker_compose() {
  # Docker Compose v2 is installed as docker-compose-plugin above.
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose v2 already installed: $(docker compose version | head -n1)"
    return
  fi
  log "Installing Docker Compose plugin..."
  install_packages docker-compose-plugin
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose installed: $(docker compose version | head -n1)"
  else
    warn "Failed to verify docker compose."
  fi
}

ensure_devtools_venv() {
  # Create a reusable virtual environment for dev tools installs to comply with PEP 668.
  VENV_DIR="${HOME}/.venvs/devtools"
  mkdir -p "${HOME}/.venvs"
  # Determine python major.minor once for this function
  PY_MAJ_MIN=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
  
  # Always ensure venv packages are available (covers cases where venv exists but lacks ensurepip)
  # FIX: Redirect install_packages output to /dev/null to prevent polluting stdout
  log "Ensuring venv packages are installed (python3-venv, python${PY_MAJ_MIN}-venv)..."
  install_packages python3-venv "python${PY_MAJ_MIN}-venv" >/dev/null 2>&1 || true
  
  if [ ! -d "${VENV_DIR}" ]; then
    log "Creating Python virtual environment at ${VENV_DIR}..."
    if ! python3 -m venv "${VENV_DIR}" 2>/dev/null; then
      warn "Initial venv creation failed. Retrying after reinstalling venv packages..."
      # FIX: Redirect install_packages output to /dev/null
      install_packages python3-venv "python${PY_MAJ_MIN}-venv" >/dev/null 2>&1 || true
      if ! python3 -m venv "${VENV_DIR}"; then
        err "Failed to create venv. Please ensure python${PY_MAJ_MIN}-venv is available and try again."
        exit 1
      fi
    fi
  fi
  # Ensure venv has python and pip
  if [ ! -x "${VENV_DIR}/bin/python" ]; then
    warn "Venv python missing, recreating venv at ${VENV_DIR}..."
    rm -rf "${VENV_DIR}"
    python3 -m venv "${VENV_DIR}" || true
  fi

  if [ ! -x "${VENV_DIR}/bin/pip" ]; then
    log "Bootstrapping pip in venv using ensurepip..."
    if "${VENV_DIR}/bin/python" -m ensurepip --upgrade >/dev/null 2>&1; then
      :
    else
      warn "ensurepip not available. Reinstalling venv prerequisites and retrying..."
      # FIX: Redirect install_packages output to /dev/null
      install_packages python3-venv "python${PY_MAJ_MIN}-venv" >/dev/null 2>&1 || true
      if ! "${VENV_DIR}/bin/python" -m ensurepip --upgrade >/dev/null 2>&1; then
        warn "ensurepip still unavailable. Installing python3-full and recreating venv..."
        # FIX: Redirect install_packages output to /dev/null
        install_packages python3-full >/dev/null 2>&1 || true
        rm -rf "${VENV_DIR}"
        python3 -m venv "${VENV_DIR}" || true
        "${VENV_DIR}/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || true
      fi
    fi
  fi

  if [ ! -x "${VENV_DIR}/bin/pip" ]; then
    warn "pip still not found in venv. Recreating venv and retrying ensurepip..."
    rm -rf "${VENV_DIR}"
    python3 -m venv "${VENV_DIR}" || true
    if [ -x "${VENV_DIR}/bin/python" ]; then
      "${VENV_DIR}/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || true
    fi
  fi

  if [ ! -x "${VENV_DIR}/bin/pip" ]; then
    warn "pip still missing after ensurepip. Installing virtualenv and recreating venv..."
    # FIX: Redirect install_packages output to /dev/null
    install_packages virtualenv >/dev/null 2>&1 || true
    rm -rf "${VENV_DIR}"
    if command -v virtualenv >/dev/null 2>&1; then
      virtualenv -p python3 "${VENV_DIR}" || true
    fi
  fi

  if [ ! -x "${VENV_DIR}/bin/pip" ]; then
    warn "pip still missing. Bootstrapping via get-pip.py..."
    # FIX: Redirect install_packages output to /dev/null
    install_packages curl ca-certificates >/dev/null 2>&1 || true
    TMP_GETPIP=$(mktemp)
    if curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "${TMP_GETPIP}"; then
      "${VENV_DIR}/bin/python" "${TMP_GETPIP}" || true
      rm -f "${TMP_GETPIP}"
    else
      warn "Failed to download get-pip.py"
    fi
  fi

  if [ ! -x "${VENV_DIR}/bin/pip" ]; then
    err "pip not found in venv (${VENV_DIR}) after all recovery steps (ensurepip, virtualenv, get-pip.py). Please ensure network access and venv packages."
    exit 1
  fi
  
  # Only echo the VENV path to stdout
  echo "${VENV_DIR}"
}

install_django() {
  # Install Django inside a dedicated venv to avoid PEP 668 externally-managed-environment issues.
  if command -v python3 >/dev/null 2>&1 && python3 - <<'PY'
import importlib.util
spec = importlib.util.find_spec('django')
raise SystemExit(0 if spec else 1)
PY
  then
    log "Django already available in current Python environment: $(python3 -m django --version 2>/dev/null || echo present)"
    return
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    err "python3 not found."
    exit 1
  fi

  # Ensure venv exists
  # VENV_DIR now captures ONLY the path, as logs are redirected to stderr
  VENV_DIR=$(ensure_devtools_venv)
  PIP_BIN="${VENV_DIR}/bin/pip"
  PY_BIN="${VENV_DIR}/bin/python"

  log "Installing/Upgrading pip in venv..."
  "${PY_BIN}" -m pip install --upgrade pip >/dev/null 2>&1 || true

  # Check if Django is already in the venv
  if "${PY_BIN}" -m django --version >/dev/null 2>&1; then
    log "Django already installed in venv: $(${PY_BIN} -m django --version)"
  else
    log "Installing Django in venv at ${VENV_DIR}..."
    "${PIP_BIN}" install Django
    log "Django installed in venv: $(${PY_BIN} -m django --version)"
  fi

  # Ensure a convenient shim exists on PATH for django-admin
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${VENV_DIR}/bin/django-admin" "${HOME}/.local/bin/django-admin"
  if ! echo ":$PATH:" | grep -q ":${HOME}/.local/bin:"; then
    # Changed WARN to INFO as this is an informational message about user shell environment
    log "To use 'django-admin' immediately, run: export PATH=\"${HOME}/.local/bin:\$PATH\""
  fi
}

main() {
  require_apt
  ensure_sudo
  install_python
  install_docker
  install_docker_compose
  install_django
  log "All tools are installed or already present."
}

main "$@"
