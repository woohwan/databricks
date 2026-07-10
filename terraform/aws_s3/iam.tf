locals {
  role_name = "${var.project_name}-uc-s3-role"
  role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
}

locals {
  # AWS IAM은 role 생성 시점에 자기 자신의 ARN을 Principal로 참조할 수 없다
  # (아직 존재하지 않는 엔티티라 "Invalid principal in policy" 에러 발생).
  # 그래서 self-assume statement는 role이 먼저 생성된 뒤, var.enable_self_assume=true로
  # 재적용할 때만 추가한다.
  trust_principals = var.enable_self_assume ? [
    var.databricks_master_role_arn,
    local.role_arn,
    ] : [
    var.databricks_master_role_arn,
  ]
}

resource "aws_iam_role" "unity_catalog" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.trust_principals
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = {
    Name = local.role_name
  }
}

resource "aws_iam_policy" "unity_catalog_s3" {
  name = "${var.project_name}-uc-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
        ]
        Resource = [
          "${aws_s3_bucket.this.arn}/*",
          aws_s3_bucket.this.arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = [local.role_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "unity_catalog_s3" {
  role       = aws_iam_role.unity_catalog.name
  policy_arn = aws_iam_policy.unity_catalog_s3.arn
}
