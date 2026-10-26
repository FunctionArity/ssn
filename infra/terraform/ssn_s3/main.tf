# IAM user for the Rails app's Active Storage (avatars and PDFs) and database backups,
# limited to the S3 buckets in var.bucket_arns.
#
#   terraform init
#   terraform apply
#   terraform output -raw secret_access_key   # then store it with bin/rails credentials:edit
#
# The secret access key is kept in the Terraform state, so keep the state file private.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  description = "AWS region where the bucket lives"
  type        = string
  default     = "sa-east-1"
}

variable "bucket_arns" {
  description = "ARNs of the only buckets the user can access"
  type        = list(string)
  default = [
    "arn:aws:s3:::ssn-web-assets-849322452391-sa-east-1-an", # Active Storage (avatars, PDFs)
    "arn:aws:s3:::ssn-db-backups",                           # daily database backups (us-east-1)
  ]
}

provider "aws" {
  region = var.region
}

resource "aws_iam_user" "ssn_s3" {
  name = "ssn_s3"

  tags = {
    app     = "ssn"
    purpose = "active-storage"
  }
}

data "aws_iam_policy_document" "ssn_s3" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
    resources = var.bucket_arns
  }

  # Read, write and delete objects; multipart actions cover large uploads.
  statement {
    sid = "ManageObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [for arn in var.bucket_arns : "${arn}/*"]
  }
}

resource "aws_iam_user_policy" "ssn_s3" {
  name   = "ssn_s3_bucket_access"
  user   = aws_iam_user.ssn_s3.name
  policy = data.aws_iam_policy_document.ssn_s3.json
}

resource "aws_iam_access_key" "ssn_s3" {
  user = aws_iam_user.ssn_s3.name
}

output "access_key_id" {
  value = aws_iam_access_key.ssn_s3.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.ssn_s3.secret
  sensitive = true
}
