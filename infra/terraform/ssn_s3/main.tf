# IAM user for the Rails app's Active Storage (avatars and PDFs) and database backups,
# plus the prd/dev Active Storage buckets, whose CORS rules let browsers upload to and
# read from them directly. The user can only reach the buckets listed in local.bucket_arns.
#
#   terraform init
#   AWS_PROFILE=terraform-ssn terraform apply
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
  description = "AWS region where the buckets live"
  type        = string
  default     = "sa-east-1"
}

variable "existing_bucket_arns" {
  description = "ARNs of buckets created outside Terraform that the user can access"
  type        = list(string)
  default = [
    "arn:aws:s3:::ssn-web-assets-849322452391-sa-east-1-an", # current Active Storage bucket
    "arn:aws:s3:::ssn-db-backups",                           # daily database backups (us-east-1)
  ]
}

# Active Storage buckets created here, keyed by environment, with the only site allowed
# to upload and read files from a browser. Bucket names can't contain underscores.
variable "assets_buckets" {
  description = "Active Storage buckets to create and the browser origin allowed on each"
  type = map(object({
    name   = string
    origin = string
  }))
  default = {
    prd = { name = "ssn-prd-web-assets", origin = "https://serviciosacerdotalnocturno.org" }
    dev = { name = "ssn-dev-web-assets", origin = "http://localhost:3000" }
  }
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

resource "aws_s3_bucket" "assets" {
  for_each = var.assets_buckets

  bucket = each.value.name

  tags = {
    app         = "ssn"
    environment = each.key
  }

  depends_on = [aws_iam_user.ssn_s3]
}

# Private buckets: files are only reachable through presigned URLs from the app.
resource "aws_s3_bucket_public_access_block" "assets" {
  for_each = aws_s3_bucket.assets

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "assets" {
  for_each = aws_s3_bucket.assets

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  for_each = aws_s3_bucket.assets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "assets_tls_only" {
  for_each = aws_s3_bucket.assets

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  for_each = aws_s3_bucket.assets

  bucket = each.value.id
  policy = data.aws_iam_policy_document.assets_tls_only[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.assets]
}

# Direct uploads PUT the file to a presigned URL; GET lets the page fetch files back.
resource "aws_s3_bucket_cors_configuration" "assets" {
  for_each = aws_s3_bucket.assets

  bucket = each.value.id

  cors_rule {
    allowed_origins = [var.assets_buckets[each.key].origin]
    allowed_methods = ["GET", "PUT"]
    allowed_headers = ["Content-Type", "Content-MD5", "Content-Disposition"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

locals {
  bucket_arns = concat(var.existing_bucket_arns, [for bucket in aws_s3_bucket.assets : bucket.arn])
}

data "aws_iam_policy_document" "ssn_s3" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
    resources = local.bucket_arns
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
    resources = [for arn in local.bucket_arns : "${arn}/*"]
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

output "assets_buckets" {
  description = "Active Storage bucket name per environment"
  value       = { for env, bucket in aws_s3_bucket.assets : env => bucket.id }
}
