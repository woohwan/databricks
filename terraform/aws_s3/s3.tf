locals {
  # 계정 ID를 그대로 노출하지 않으면서, 계정마다 고정되고 유일한 접미사로 사용
  account_hash = substr(md5(data.aws_caller_identity.current.account_id), 0, 8)
  bucket_name  = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-medallion-${local.account_hash}"
  layers       = ["bronze", "silver", "gold"]
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "layers" {
  for_each = toset(local.layers)

  bucket  = aws_s3_bucket.this.id
  key     = "${each.value}/"
  content = ""
}
