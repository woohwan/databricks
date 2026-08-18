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


def _get_llm_client() -> OpenAI:
    host = cfg.host.rstrip("/")
    token = cfg.token
    return OpenAI(api_key=token, base_url=f"{host}/serving-endpoints")


def _query_sales_data() -> str:
    """SQL 웨어하우스에서 요약 테이블 전체를 가져와 텍스트로 변환 (tool)."""
    with dbsql.connect(
        server_hostname=cfg.host.replace("https://", ""),
        http_path=os.environ["DATABRICKS_HTTP_PATH"],
        credentials_provider=lambda: cfg.authenticate,
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute(f"SELECT * FROM {TABLE_NAME} LIMIT 200")
            rows = cursor.fetchall()
            columns = [c[0] for c in cursor.description]

    lines = [", ".join(columns)]
    for row in rows:
        lines.append(", ".join(str(v) for v in row))
    return "\n".join(lines)


def answer_question(user_question: str) -> str:
    """사용자 질문에 대해 데이터 조회 → LLM 답변 생성까지 한 번에 처리."""
    data_context = _query_sales_data()

    client = _get_llm_client()
    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"다음은 판매 요약 데이터(CSV 형식)야:\n\n{data_context}\n\n"
                    f"질문: {user_question}"
                ),
            },
        ],
        max_tokens=500,
        temperature=0.2,
    )
    return response.choices[0].message.content