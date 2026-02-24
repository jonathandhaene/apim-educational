#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

find_python() {
  if [ -x "${REPO_ROOT}/.venv/Scripts/python.exe" ]; then
    echo "${REPO_ROOT}/.venv/Scripts/python.exe"
  elif [ -x "${REPO_ROOT}/.venv/bin/python" ]; then
    echo "${REPO_ROOT}/.venv/bin/python"
  elif command -v python3 >/dev/null 2>&1; then
    echo "python3"
  else
    echo "python"
  fi
}

run_cmd() {
  echo ""
  echo ">>> $*"
  echo ""
  output=""
  if output=$(cd "${REPO_ROOT}" && "$@" 2>&1); then
    if [ -n "$output" ]; then
      printf '%s\n' "$output"
    fi
    return 0
  else
    status=$?
    if [ -n "$output" ]; then
      printf '%s\n' "$output"
    else
      echo "No output was returned from the command."
    fi
    echo ""
    echo "Command exited with code $status"
    echo ""
    return $status
  fi
}

has_uv() {
  command -v uv >/dev/null 2>&1
}

ensure_uv_env() {
  if has_uv; then
    (cd "${REPO_ROOT}" && { [ -d .venv ] || uv venv; } && uv sync >/dev/null 2>&1 || true)
  fi
}

pyrun() {
  if has_uv; then
    uv run python "$@"
  else
    "$(find_python)" "$@"
  fi
}

while true; do
  echo ""
  echo "APIM Educational Developer CLI"
  echo "==============================="
  echo ""
  echo "Setup"
  echo "  1) Install / update Python dependencies"
  echo "  2) Azure CLI login"
  echo ""
  echo "Tests"
  echo "  3) Run pylint (migration tools)"
  echo "  4) Run pytest (migration tools)"
  echo "  5) Run full Python checks (lint + test)"
  echo ""
  echo "Infra"
  echo "  6) Validate Bicep templates"
  echo "  7) Validate Terraform configuration"
  echo ""
  echo "Misc"
  echo "  0) Exit"
  echo ""
  read -rp "Select an option: " choice
  case "$choice" in
    1)
      if has_uv; then
        run_cmd uv sync
      else
        echo "uv is not installed. Install it from https://docs.astral.sh/uv/ or run: pip install pyyaml pytest pylint pytest-cov coverage"
      fi
      ;;
    2)
      echo ""
      read -rp "Do you want to specify a tenant ID? (y/n): " use_tenant_id
      if [ "$use_tenant_id" = "y" ] || [ "$use_tenant_id" = "Y" ]; then
        read -rp "Enter tenant ID: " tenant_id
        if [ -n "$tenant_id" ]; then
          echo ""
          echo ">>> az login --tenant $tenant_id"
          echo ""
          exec az login --tenant "$tenant_id"
        else
          echo "Tenant ID is required."
        fi
      else
        echo ""
        echo ">>> az login"
        echo ""
        exec az login
      fi
      ;;
    3)
      ensure_uv_env
      run_cmd pyrun -m pylint --rcfile "${REPO_ROOT}/.pylintrc" "${REPO_ROOT}/tools/migration/openapi_utils.py"
      ;;
    4)
      ensure_uv_env
      run_cmd pyrun -m pytest "${REPO_ROOT}/tools/migration/tests/" -v --tb=short
      ;;
    5)
      ensure_uv_env
      echo ""
      echo "=== Pylint ==="
      run_cmd pyrun -m pylint --rcfile "${REPO_ROOT}/.pylintrc" "${REPO_ROOT}/tools/migration/openapi_utils.py"
      echo ""
      echo "=== Pytest ==="
      run_cmd pyrun -m pytest "${REPO_ROOT}/tools/migration/tests/" -v --tb=short \
        --cov="${REPO_ROOT}/tools/migration" --cov-report=term-missing
      ;;
    6)
      if command -v az >/dev/null 2>&1; then
        run_cmd az bicep build --file "${REPO_ROOT}/infra/bicep/main.bicep"
      else
        echo "Azure CLI is not installed. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli"
      fi
      ;;
    7)
      if command -v terraform >/dev/null 2>&1; then
        run_cmd terraform -chdir="${REPO_ROOT}/infra/terraform" validate
      else
        echo "Terraform is not installed. Install from: https://developer.hashicorp.com/terraform/install"
      fi
      ;;
    0)
      echo ""
      echo "Goodbye!"
      echo ""
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
