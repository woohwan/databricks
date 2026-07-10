# 변경 이력 (History)

이 문서는 `databricks` 리포지토리의 주요 변경 사항을 시간순으로 정리합니다.

## [Unreleased] - 작업 중 (미커밋)

### 변경 (Changed)
- **`terraform/aws_rds/terraform.tfvars.example`**, **`terraform/aws_s3/terraform.tfvars.example`**
  - `project_name` 예시 값을 `databricks-medallion` → `databricks-agent` 로 변경
- **`terraform/aws_s3/s3.tf`**
  - S3 버킷 이름 접미사 생성 방식을 `random_id` 리소스(랜덤 값)에서 `data.aws_caller_identity.current.account_id`의 md5 해시 앞 8자리로 변경
  - 목적: 계정 ID를 그대로 노출하지 않으면서도, 계정마다 고정되고 유일한(재현 가능한) 접미사 사용
- **`terraform/aws_s3/main.tf`**
  - 위 변경에 따라 더 이상 필요 없는 `hashicorp/random` provider 요구사항 제거
- **`terraform/aws_s3/.terraform.lock.hcl`**
  - `hashicorp/random` provider 잠금 항목 제거 (provider 요구사항 제거에 따른 자동 반영)

---

## 2026-07-10 - Merge remote-generated .gitignore (`910b3ad`)
- 원격에서 생성된 `.gitignore`를 병합 (충돌: `.gitignore`)

## 2026-07-10 - Add Terraform config for RDS medallion source and S3/Unity Catalog storage (`5b85c54`)
- **aws_rds**: Databricks 서버리스 egress IP로 접근을 제한한, medallion 소스 DB용 최소 구성 PostgreSQL RDS 추가
- **aws_s3**: bronze/silver/gold 프리픽스를 가진 S3 버킷 및 Unity Catalog storage credential용 IAM 역할 추가
- **generate_data.py / load_data.sh / test_query.sh**: 시드 데이터 생성 및 적재 헬퍼 스크립트 추가

## 2026-07-09 - Initial commit (`e6364ce`)
- 리포지토리 초기 커밋
