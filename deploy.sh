#!/usr/bin/env bash
# Creates the S3 bucket used as shared Terraform remote state storage for all
# room-booking-* projects, then migrates this project's own state into that
# same bucket so it isn't the one project left on local state.
# NOTE: `terraform apply -auto-approve` creates real AWS resources in whatever
# account/credentials are active. Run this deliberately, not from automation.
set -euo pipefail
cd "$(dirname "$0")"

echo "Setting up the shared Terraform remote state bucket..."

terraform_dir="deploy/terraform"

# First run only: backend.hcl points at a bucket that doesn't exist yet, so
# the S3 backend can't initialize. Fall back to local state just for the
# apply that creates the bucket.
if ! terraform -chdir="${terraform_dir}" init -backend-config=backend.hcl -migrate-state -force-copy -input=false 2>/dev/null; then
  echo "Remote state bucket doesn't exist yet — initializing with local state to create it."
  terraform -chdir="${terraform_dir}" init -input=false
fi

terraform -chdir="${terraform_dir}" apply -auto-approve

# Now that the bucket exists, move this project's own state into it. A no-op
# on every run after the first, once state is already there.
terraform -chdir="${terraform_dir}" init -backend-config=backend.hcl -migrate-state -force-copy -input=false

bucket_name="$(terraform -chdir="${terraform_dir}" output -raw state_bucket_name)"

echo
echo "Remote state bucket ready: ${bucket_name}"
echo "Set this as the 'bucket' value in each project's deploy/terraform/backend.hcl."
