terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bucket/key/region/locking are supplied via backend.hcl. This project's
  # own state lives in the very bucket it creates (see deploy.sh and
  # README.md for how the chicken-and-egg first run is handled).
  backend "s3" {}
}
