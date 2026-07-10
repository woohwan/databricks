output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "iam_role_arn" {
  description = "Databricks storage credential 생성 시 IAM Role ARN 입력란에 사용"
  value       = aws_iam_role.unity_catalog.arn
}

output "external_id_note" {
  value = "Databricks에서 위 iam_role_arn으로 storage credential을 만들면 실제 External ID가 발급됩니다. terraform.tfvars의 external_id를 그 값으로 교체 후 재적용하세요 (현재: ${var.external_id})."
}
