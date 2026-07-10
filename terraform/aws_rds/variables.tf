variable "aws_region" {
  description = "RDS를 생성할 AWS 리전 (Databricks workspace와 동일 리전 권장)"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "리소스 이름에 붙일 프로젝트/서비스 식별자"
  type        = string
  default     = "databricks-medallion"
}

variable "vpc_cidr" {
  description = "RDS 전용 최소 VPC의 CIDR 블록"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidrs" {
  description = "DB 서브넷 그룹용 서브넷 CIDR (서로 다른 AZ에 2개 생성)"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "db_name" {
  description = "RDS 인스턴스 생성 시 만들어질 초기 데이터베이스 이름"
  type        = string
  default     = "medallion_source"
}

variable "db_username" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "dbadmin"
}

variable "db_master_password" {
  description = "마스터 사용자 비밀번호 (terraform.tfvars 또는 TF_VAR_db_master_password 환경변수로 주입, 8자 이상)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "할당 스토리지 크기(GB)"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL 엔진 버전"
  type        = string
  default     = "16.14"
}

variable "publicly_accessible" {
  description = "RDS에 퍼블릭 IP를 부여할지 여부. Databricks 서버리스 컴퓨트는 공인 IP로 접속하므로 true 필요"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = <<-EOT
    VPC 내부 CIDR 외에 5432 포트 접근을 추가로 허용할 CIDR 목록.
    기본값은 Databricks 서버리스 컴퓨트의 us-west-2 리전 아웃바운드 공인 IP 대역(2026-07 기준).
    Databricks workspace 리전이 다르거나 IP가 변경된 경우
    https://www.databricks.com/networking/v1/ip-ranges.json 에서
    platform=aws, region=<workspace 리전>, type=outbound 항목으로 갱신할 것.
  EOT
  type        = list(string)
  default     = ["18.246.106.0/24", "3.42.138.0/25", "44.234.192.32/28", "52.27.216.188/32"]
}
