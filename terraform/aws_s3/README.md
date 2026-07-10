# aws_s3

Databricks Unity Catalog가 medallion(bronze/silver/gold) 데이터를 저장할 S3 버킷과, Databricks가 그 버킷에 접근할 때 assume하는 IAM Role/Policy를 생성한다.

## 파일 구성

| 파일 | 내용 |
|---|---|
| `main.tf` | AWS/random provider, terraform 블록, caller identity 조회 |
| `variables.tf` | 리전, 프로젝트명, 버킷명, Databricks 마스터 role ARN, external_id, enable_self_assume |
| `s3.tf` | S3 버킷(랜덤 접미사), 퍼블릭 접근 차단, 기본 암호화(SSE-S3), bronze/silver/gold prefix |
| `iam.tf` | Unity Catalog storage credential용 IAM Role/Policy |
| `outputs.tf` | 버킷명/ARN, IAM Role ARN, 다음 단계 안내 메시지 |
| `terraform.tfvars.example` | tfvars 작성 예시 및 3단계 절차 안내 |

## 왜 2단계로 나눠서 apply하는가

AWS IAM은 role을 생성하는 시점에 **그 role 자신의 ARN을 trust policy의 Principal로 참조할 수 없다** (아직 존재하지 않는 엔티티라 `Invalid principal in policy` 에러 발생). Databricks가 요구하는 "self-assume" 조건은 role이 이미 존재해야 추가할 수 있다. 그래서 아래처럼 role을 먼저 만들고, 이후 재적용으로 self-assume을 켜는 2단계 구조로 되어 있다.

## 1단계 — IAM Role 생성 (placeholder external_id)

```bash
cd aws_s3
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform apply   # external_id="0000", enable_self_assume=false (기본값)

terraform output iam_role_arn
```

## 2단계 — Databricks에서 Storage Credential 생성

Unity Catalog metastore에 연결된 workspace, metastore admin 권한 필요.

1. 왼쪽 사이드바 **Catalog** 아이콘 클릭
2. **Connect > Credentials** 이동
3. **Create credential** 클릭
4. 유형 **AWS IAM Role** 선택, 이름 입력
5. **IAM Role ARN**에 1단계 `iam_role_arn` 출력값 붙여넣기
6. **Create** 클릭 → **Credential created** 대화상자에서 **External ID** 복사

## 3단계 — 실제 External ID 반영 후 재적용

```bash
# terraform.tfvars에 추가
external_id        = "<복사한 External ID>"
enable_self_assume  = true
```

```bash
terraform apply
```

IAM Role의 trust policy가 실제 external_id + self-assume 조건으로 갱신된다.

## 4단계 — External Location 생성 (Databricks)

storage credential이 준비되면 Catalog Explorer에서 `s3://<bucket_name>/bronze/`, `/silver/`, `/gold/` 각각을 external location으로 등록해 medallion 스키마와 연결한다.

> `bucket_name` / `bucket_arn`은 `terraform output`으로 확인할 수 있다.

## 정리 (destroy)

```bash
terraform destroy
```

> 버킷은 `force_destroy = true`로 구성되어 있어 안에 데이터가 있어도 그대로 삭제된다. 이미 Databricks에 이 Role ARN으로 storage credential/external location을 만들어 뒀다면, destroy 후 해당 연결이 끊어지므로 Databricks 쪽도 함께 정리해야 한다.
