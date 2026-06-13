#!/usr/bin/env bash
#
# Pre-PR Terraform validation loop for this repo.
# Runs the fmt -> init -> validate -> plan gate described in SKILL.md.
#
# Usage:
#   ./validate.sh [stack_dir]
#
#   stack_dir   Directory containing the Terraform stack to validate.
#               Defaults to the current directory.
#
# Environment:
#   TF_PLAN_OUT   Path to write the binary plan (default: tfplan).
#   SKIP_PLAN=1   Run fmt/validate only; skip `terraform plan` (no backend/creds).
#   WITH_BACKEND=1  Initialize with the real backend instead of -backend=false.
#
# The script is intentionally read-only: it never runs `apply` or `destroy`.

set -euo pipefail

STACK_DIR="${1:-.}"
TF_PLAN_OUT="${TF_PLAN_OUT:-tfplan}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

if ! command -v terraform >/dev/null 2>&1; then
  echo "error: terraform is not installed or not on PATH" >&2
  exit 127
fi

cd "$STACK_DIR"

bold "==> terraform fmt (recursive, check)"
# Format the whole tree; -check fails if anything is unformatted.
terraform fmt -recursive -check -diff

if [[ "${WITH_BACKEND:-0}" == "1" ]]; then
  bold "==> terraform init (with backend)"
  terraform init -input=false
else
  bold "==> terraform init (-backend=false)"
  terraform init -input=false -backend=false
fi

bold "==> terraform validate"
terraform validate

if [[ "${SKIP_PLAN:-0}" == "1" ]]; then
  bold "==> skipping terraform plan (SKIP_PLAN=1)"
  exit 0
fi

bold "==> terraform plan"
# -lock=false keeps this safe to run repeatedly; surface the plan for review.
terraform plan -input=false -lock=false -out="$TF_PLAN_OUT"

bold "==> plan written to ${TF_PLAN_OUT} — review before any apply"
