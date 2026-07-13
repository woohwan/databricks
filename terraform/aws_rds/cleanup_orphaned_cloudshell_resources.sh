#!/usr/bin/env bash
#
# Cloud Shell에서 terraform apply를 실행한 뒤 작업 디렉터리(및 .terraform state)가
# 통째로 삭제되어 terraform destroy로 정리할 수 없게 된 고아(orphan) 리소스를
# 수동으로 삭제하기 위한 스크립트.
#
# 2026-07-13 기준 AWS CLI로 조회해서 확인한 리소스 목록 (region: us-west-2):
#
#   RDS 인스턴스        : databricks-agent-pg        (db.t3.micro, postgres 16.14, available)
#   DB 서브넷 그룹      : databricks-agent-db-subnet-group
#   보안 그룹           : sg-0dc8a611098f467fa        (databricks-agent-rds-sg)
#   라우트 테이블       : rtb-031671778c910ca8d       (databricks-agent-rt, non-main)
#   인터넷 게이트웨이   : igw-009b15c19e9fbf4b3       (databricks-agent-igw)
#   서브넷              : subnet-0646f6f66342f549a    (databricks-agent-db-0, us-west-2a)
#                         subnet-04446fc373921aeea    (databricks-agent-db-1, us-west-2b)
#   VPC                 : vpc-077b83975929f0707       (databricks-agent-vpc, 10.20.0.0/16)
#
# 삭제 순서: RDS 인스턴스 -> DB 서브넷 그룹 -> 보안 그룹 -> 라우트 테이블 연결/라우트 테이블
#           -> IGW(detach 후 삭제) -> 서브넷 -> VPC
# (default 보안 그룹과 default 라우트 테이블/ACL은 VPC를 지우면 함께 정리되므로 직접 지우지 않는다.)
#
# 사용법:
#   ./cleanup_orphaned_cloudshell_resources.sh            # 확인 프롬프트 후 실행
#   ./cleanup_orphaned_cloudshell_resources.sh --yes       # 확인 없이 바로 실행
#
# 주의: RDS 인스턴스는 --skip-final-snapshot 으로 즉시 삭제한다(스냅샷 미생성).
#       DB 안의 데이터가 필요 없다는 것을 확인한 뒤 실행할 것.

set -euo pipefail

REGION="us-west-2"
DB_INSTANCE_ID="databricks-agent-pg"
DB_SUBNET_GROUP="databricks-agent-db-subnet-group"
SECURITY_GROUP_ID="sg-0dc8a611098f467fa"
ROUTE_TABLE_ID="rtb-031671778c910ca8d"
IGW_ID="igw-009b15c19e9fbf4b3"
SUBNET_IDS=(subnet-0646f6f66342f549a subnet-04446fc373921aeea)
VPC_ID="vpc-077b83975929f0707"

if [[ "${1:-}" != "--yes" ]]; then
  echo "다음 리소스를 영구 삭제합니다 (region: $REGION):"
  echo "  RDS 인스턴스       : $DB_INSTANCE_ID (스냅샷 없이 삭제)"
  echo "  DB 서브넷 그룹     : $DB_SUBNET_GROUP"
  echo "  보안 그룹          : $SECURITY_GROUP_ID"
  echo "  라우트 테이블      : $ROUTE_TABLE_ID"
  echo "  인터넷 게이트웨이  : $IGW_ID"
  echo "  서브넷             : ${SUBNET_IDS[*]}"
  echo "  VPC                : $VPC_ID"
  read -r -p "계속하시겠습니까? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "취소했습니다."; exit 1; }
fi

echo "==> RDS 인스턴스 삭제 요청: $DB_INSTANCE_ID"
aws rds delete-db-instance \
  --region "$REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --skip-final-snapshot

echo "==> RDS 인스턴스 삭제 완료 대기 (수 분 소요될 수 있음)..."
aws rds wait db-instance-deleted \
  --region "$REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID"

echo "==> DB 서브넷 그룹 삭제: $DB_SUBNET_GROUP"
aws rds delete-db-subnet-group \
  --region "$REGION" \
  --db-subnet-group-name "$DB_SUBNET_GROUP"

echo "==> 보안 그룹 삭제: $SECURITY_GROUP_ID"
aws ec2 delete-security-group \
  --region "$REGION" \
  --group-id "$SECURITY_GROUP_ID"

echo "==> 라우트 테이블 연결 해제 및 라우트 테이블 삭제: $ROUTE_TABLE_ID"
for assoc_id in $(aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$ROUTE_TABLE_ID" \
    --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
    --output text); do
  aws ec2 disassociate-route-table --region "$REGION" --association-id "$assoc_id"
done
aws ec2 delete-route-table --region "$REGION" --route-table-id "$ROUTE_TABLE_ID"

echo "==> 인터넷 게이트웨이 분리 및 삭제: $IGW_ID"
aws ec2 detach-internet-gateway --region "$REGION" --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
aws ec2 delete-internet-gateway --region "$REGION" --internet-gateway-id "$IGW_ID"

echo "==> 서브넷 삭제: ${SUBNET_IDS[*]}"
for subnet_id in "${SUBNET_IDS[@]}"; do
  aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet_id"
done

echo "==> VPC 삭제: $VPC_ID"
aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC_ID"

echo "==> 완료. 아래 명령으로 잔여 리소스가 없는지 확인하세요:"
echo "    aws ec2 describe-vpcs --region $REGION --vpc-ids $VPC_ID"
