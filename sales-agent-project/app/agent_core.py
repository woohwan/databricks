"""아주 단순한 tool-use 에이전트: 판매 데이터 조회 + LLM 답변 생성."""

import os
from databricks import sql as dbsql
from databricks.sdk.core import Config
from openai import OpenAI

MODEL_NAME = "databricks-meta-llama-3-3-70b-instruct"
TABLE_NAME = "richard_dev.sales_agent.sales_summary"

SYSTEM_PROMPT = (
    "너는 회사 내부 판매 데이터를 설명해주는 분석 어시스턴트야. "
    "아래에 제공되는 표 형태의 데이터를 근거로만 답변하고, "
    "데이터에 없는 내용은 추측하지 말고 모른다고 말해."
)

# Databricks SDK Config: 로컬/배포 환경 모두에서 자동으로 인증정보를 찾아줌
cfg = Config()

from databricks.sdk import WorkspaceClient

def _get_llm_client() -> OpenAI:
    print("STEP 1: LLM 클라이언트 생성 시작", flush=True)

    w = WorkspaceClient()
    token = w.config.oauth_token().access_token
    host = w.config.host.rstrip("/")
    print(f"STEP 1a: host={host}, token 발급됨={bool(token)}", flush=True)

    client = OpenAI(
        api_key=token,
        base_url=f"{host}/serving-endpoints",
        timeout=60.0,
    )
    print("STEP 1 완료: LLM 클라이언트 생성됨", flush=True)
    return client


def _query_sales_data() -> str:
    warehouse_id = os.environ["DATABRICKS_HTTP_PATH"]
    http_path = f"/sql/1.0/warehouses/{warehouse_id}"

    print(f"STEP 2: SQL 웨어하우스 연결 시도 (http_path={http_path})", flush=True)
    print(f"STEP 2a: cfg.host={cfg.host}, auth_type={cfg.auth_type}", flush=True)

    with dbsql.connect(
        server_hostname=cfg.host.replace("https://", ""),
        http_path=http_path,
        credentials_provider=lambda: cfg.authenticate,
        _socket_timeout=60,
    ) as conn:
        print("STEP 2b: 연결 성공", flush=True)
        with conn.cursor() as cursor:
            cursor.execute(f"SELECT * FROM {TABLE_NAME} LIMIT 200")
            rows = cursor.fetchall()
            columns = [c[0] for c in cursor.description]
            print(f"STEP 2c: {len(rows)}건 조회됨", flush=True)

    lines = [", ".join(columns)]
    for row in rows:
        lines.append(", ".join(str(v) for v in row))
    return "\n".join(lines)


def answer_question(user_question: str) -> str:
    print(f"STEP 0: 질문 받음 - {user_question}", flush=True)
    data_context = _query_sales_data()

    client = _get_llm_client()
    print("STEP 3: LLM 호출 시작", flush=True)
    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"다음은 판매 요약 데이터(CSV 형식)야:\n\n{data_context}\n\n질문: {user_question}"},
        ],
        max_tokens=500,
        temperature=0.2,
    )
    print("STEP 3 완료: LLM 응답 받음", flush=True)
    return response.choices[0].message.content