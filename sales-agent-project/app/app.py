import streamlit as st
from agent_core import answer_question

st.set_page_config(page_title="Sales Agent", page_icon="📊")
st.title("📊 판매 데이터 에이전트")
st.caption("Delta 테이블 richard_dev.sales_agent.sales_summary에 자연어로 질문해보세요.")

if "messages" not in st.session_state:
    st.session_state.messages = []
    
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

user_input = st.chat_input("예: APAC지역에서 가장 매출이 높은 제품은?")

if user_input:
    st.session_state.messages.append({"role": "user", "content": user_input})
    with st.chat_message("user"):
        st.markdown(user_input)
    
    with st.chat_message("assistant"):
        with st.spinner("데이터 조회 및 분석 중..."):
            answer = answer_question(user_input)
            st.markdown(answer)
            
    st.session_state.messages.append({"role": "assistant", "content": answer})