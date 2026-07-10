variable "aws_region" {
  description = "S3 버킷을 생성할 AWS 리전 (Databricks workspace와 동일 리전 권장)"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "리소스 이름에 붙일 프로젝트/서비스 식별자"
  type        = string
  default     = "databricks-medallion"
}

variable "bucket_name" {
  description = "S3 버킷 이름. 비워두면 project_name 기반으로 랜덤 접미사를 붙여 자동 생성 (버킷 이름은 전역 유일해야 함)"
  type        = string
  default     = ""
}

variable "databricks_master_role_arn" {
  description = "Databricks Unity Catalog가 storage credential에서 사용하는 고정 마스터 role ARN (Databricks 공식 문서 값, 보통 변경 불필요)"
  type        = string
  default     = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
}

variable "external_id" {
  description = <<-EOT
    Unity Catalog storage credential의 External ID.
    최초 apply 시에는 placeholder "0000"으로 role을 생성하고,
    Databricks에서 이 IAM Role ARN(output: iam_role_arn)으로 storage credential을 생성한 뒤
    발급된 실제 External ID로 이 값을 교체해서 재적용해야 함.
  EOT
  type        = string
  default     = "0000"
}

variable "enable_self_assume" {
  description = <<-EOT
    Databricks가 요구하는 self-assume(role이 자기 자신을 trust)을 trust policy에 추가할지 여부.
    role이 아직 존재하지 않는 최초 apply 시점에는 false로 두어야 하며(AWS가 존재하지 않는
    role ARN을 principal로 거부함), role 생성 후 external_id를 실제 값으로 교체하는
    재적용 시점에 true로 바꿔야 함.
  EOT
  type        = bool
  default     = false
}
