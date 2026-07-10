#!/usr/bin/env bash
# aws_rds 하위 terraform output에서 접속 정보를 읽어
# test_queries.sql의 sanity check 쿼리를 RDS PostgreSQL에서 실행한다.
#
# 사용법:
#   PGPASSWORD=<db_master_password> ./test_query.sh [PGUSER]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/aws_rds"
SQL_FILE="${SCRIPT_DIR}/test_queries.sql"
PGUSER="${1:-dbadmin}"

if [[ -z "${PGPASSWORD:-}" ]]; then
  echo "PGPASSWORD 환경변수로 db_master_password를 지정하세요." >&2
  exit 1
fi

PGHOST="$(terraform -chdir="${TF_DIR}" output -raw db_instance_address)"
PGPORT="$(terraform -chdir="${TF_DIR}" output -raw db_instance_port)"
PGDATABASE="$(terraform -chdir="${TF_DIR}" output -raw db_name)"

export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

echo "Querying ${PGUSER}@${PGHOST}:${PGPORT}/${PGDATABASE} ..."
psql -v ON_ERROR_STOP=1 -f "${SQL_FILE}"
