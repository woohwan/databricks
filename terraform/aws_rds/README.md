# aws_rds

Databricks medallion 아키텍처의 원본 데이터 소스로 쓰는 최소 구성 PostgreSQL RDS. 전용 VPC, 서브넷 2개, 보안그룹, RDS 인스턴스 1개로 구성되어 있다.

## 사전 요구사항

- AWS 자격증명 설정 (`aws sts get-caller-identity`로 확인)
- Terraform >= 1.5.0
- `psql` 클라이언트 (데이터 적재/쿼리 테스트용) — `sudo apt-get install -y postgresql-client-14`

## 파일 구성

| 파일 | 내용 |
|---|---|
| `main.tf` | AWS provider, terraform 블록 |
| `variables.tf` | 리전, 프로젝트명, DB 계정/비밀번호, 네트워크 허용 범위 등 변수 |
| `vpc.tf` | 전용 VPC, 서브넷 2개(AZ 분산), IGW, 라우팅 |
| `security_group.tf` | 5432 포트 인바운드 규칙 (VPC 내부 + allowed_cidr_blocks) |
| `rds.tf` | DB 서브넷 그룹, RDS PostgreSQL 인스턴스 |
| `outputs.tf` | 엔드포인트, 포트, DB 이름 등 출력값 |
| `terraform.tfvars.example` | tfvars 작성 예시 |

## 1. 최초 실행 (apply)

```bash
cd aws_rds
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars에서 db_master_password 수정

terraform init
terraform apply
```

> **비밀번호 제약:** RDS 마스터 비밀번호는 출력 가능한 ASCII 문자만 허용하며 `/`, `@`, `"`, 공백은 사용할 수 없다.

apply가 끝나면 다음 출력값을 확인할 수 있다.

```bash
terraform output db_instance_address   # 엔드포인트 호스트
terraform output db_instance_port      # 5432
terraform output db_name               # medallion_source
```

## 2. 네트워크 / 보안

- `publicly_accessible = true` (기본값) — Databricks 서버리스 컴퓨트가 공인 IP로 접속하기 때문에 필요
- `allowed_cidr_blocks` 기본값은 Databricks 서버리스 컴퓨트의 **us-west-2** 리전 아웃바운드 공인 IP 대역이다. Databricks workspace 리전이 다르면 [ip-ranges.json](https://www.databricks.com/networking/v1/ip-ranges.json)에서 `platform=aws`, `region=<workspace 리전>`, `type=outbound` 항목으로 갱신해야 한다.
- 로컬 PC 등 다른 곳에서 직접 적재/쿼리하려면 본인 공인 IP(`/32`)를 `allowed_cidr_blocks`에 추가하고 `terraform apply`로 반영한 뒤, 작업이 끝나면 다시 제거해서 노출 범위를 최소화하는 것을 권장한다.
- **AWS CloudShell에서 적재 시 connection timeout이 발생하는 경우:** CloudShell의 아웃바운드 공인 IP도 `allowed_cidr_blocks`에 없으면 보안그룹에서 5432 포트 패킷이 조용히 드롭되어 (connection refused가 아닌) timeout이 발생한다. CloudShell 세션에서 다음과 같이 본인 IP를 확인해 추가하고 재적용한다.

  ```bash
  MY_IP=$(curl -s ifconfig.me)
  terraform apply -var="allowed_cidr_blocks=[\"18.246.106.0/24\",\"3.42.138.0/25\",\"44.234.192.32/28\",\"52.27.216.188/32\",\"${MY_IP}/32\"]"
  ```

  CloudShell의 공인 IP는 고정이 아니므로, 세션이 새로 시작되어 IP가 바뀌면 위 과정을 다시 반복해야 한다.

## 3. 데이터 생성 및 적재

생성/적재 스크립트는 상위 디렉토리(`terraform/`)에 있다.

```bash
cd ..
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python generate_data.py          # data/sql/seed_data.sql 생성

PGPASSWORD=<db_master_password> ./load_data.sh dbadmin   # 적재
PGPASSWORD=<db_master_password> ./test_query.sh dbadmin  # sanity check 쿼리
```

`load_data.sh` / `test_query.sh`는 `terraform -chdir=aws_rds output`으로 접속 정보(host/port/dbname)를 자동으로 읽어온다.

## 4. 정리 (destroy)

```bash
cd aws_rds
terraform destroy
```

> `skip_final_snapshot = true`로 구성되어 있어 destroy 시 **최종 스냅샷 없이 데이터가 영구 삭제**된다.

## 알려진 이슈

- `engine_version` 기본값은 `16.14`다. AWS가 특정 마이너 버전을 단종시키면 `InvalidParameterCombination: Cannot find version ... for postgres` 에러가 나므로, `aws rds describe-db-engine-versions --engine postgres --region <region>`로 사용 가능한 버전을 확인 후 `variables.tf`를 갱신한다.
