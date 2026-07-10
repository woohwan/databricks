#!/usr/bin/env bash
# aws_rds 하위 terraform output에서 접속 정보를 읽어
# data/sql/seed_data.sql을 RDS PostgreSQL에 적재한다.
#
# 사용법:
#   PGPASSWORD=<db_master_password> ./load_data.sh [PGUSER]
#
# 사전조건:
#   - aws_rds 디렉토리에서 terraform apply가 완료되어 있어야 함
#   - data/sql/seed_data.sql이 생성되어 있어야 함 (없으면 .venv/bin/python generate_data.py 먼저 실행)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/aws_rds"
SQL_FILE="${SCRIPT_DIR}/data/sql/seed_data.sql"
PGUSER="${1:-dbadmin}"

if [[ -z "${PGPASSWORD:-}" ]]; then
  echo "PGPASSWORD 환경변수로 db_master_password를 지정하세요." >&2
  exit 1
fi

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "먼저 데이터를 생성하세요: .venv/bin/python generate_data.py" >&2
  exit 1
fi

PGHOST="$(terraform -chdir="${TF_DIR}" output -raw db_instance_address)"
PGPORT="$(terraform -chdir="${TF_DIR}" output -raw db_instance_port)"
PGDATABASE="$(terraform -chdir="${TF_DIR}" output -raw db_name)"

export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

echo "Loading ${SQL_FILE} into ${PGUSER}@${PGHOST}:${PGPORT}/${PGDATABASE} ..."
psql -v ON_ERROR_STOP=1 -f "${SQL_FILE}"
echo "완료."
