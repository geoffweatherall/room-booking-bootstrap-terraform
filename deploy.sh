#!/usr/bin/env bash
# Creates the S3 bucket used as shared Terraform remote state storage for all
# mootmaker-* projects, then migrates this project's own state into that
# same bucket so it isn't the one project left on local state.
# NOTE: `terraform apply -auto-approve` creates real AWS resources in whatever
# account/credentials are active. Run this deliberately, not from automation.
set -euo pipefail
cd "$(dirname "$0")"

echo "Setting up the shared Terraform remote state bucket..."

terraform_dir="deploy/terraform"
versions_file="${terraform_dir}/versions.tf"

# First run only: backend.hcl points at a bucket that doesn't exist yet, so
# the S3 backend can't initialize - it requires bucket/key/region to be
# resolvable even just to fail cleanly, and there's no way to satisfy that
# for a bucket that doesn't exist yet. Fall back to a genuinely local
# backend just for the apply that creates the bucket, by temporarily
# removing the (otherwise unconditional) `backend "s3" {}` block - restored
# immediately after, even if this script fails partway through.
bootstrapped_locally=false
if ! terraform -chdir="${terraform_dir}" init -backend-config=backend.hcl -migrate-state -force-copy -input=false 2>/dev/null; then
  echo "Remote state bucket doesn't exist yet — bootstrapping with a temporary local backend to create it."
  cp "${versions_file}" "${versions_file}.orig"
  trap 'mv -f "${versions_file}.orig" "${versions_file}" 2>/dev/null || true' EXIT
  sed -i '/backend "s3" {}/d' "${versions_file}"
  terraform -chdir="${terraform_dir}" init -input=false
  bootstrapped_locally=true
fi

terraform -chdir="${terraform_dir}" apply -auto-approve

if [ "${bootstrapped_locally}" = true ]; then
  mv -f "${versions_file}.orig" "${versions_file}"
  trap - EXIT
fi

# Now that the bucket exists, move this project's own state into it. A no-op
# on every run after the first, once state is already there.
terraform -chdir="${terraform_dir}" init -backend-config=backend.hcl -migrate-state -force-copy -input=false

bucket_name="$(terraform -chdir="${terraform_dir}" output -raw state_bucket_name)"

echo
echo "Remote state bucket ready: ${bucket_name}"
echo "Set this as the 'bucket' value in each project's deploy/terraform/backend.hcl."
