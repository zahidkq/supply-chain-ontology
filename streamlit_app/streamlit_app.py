"""
Supply Chain Insights Agent — Streamlit Prototype
Chat interface for the SUPPLY_CHAIN_AGENT Cortex Agent
"""

import os
import json
import streamlit as st

st.set_page_config(
    page_title="Supply Chain Insights Agent",
    page_icon=":material/local_shipping:",
    layout="wide",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))
session = conn.session()


# ── KPI sidebar ──────────────────────────────────────────────
@st.cache_data(ttl=300)
def load_kpis():
    otd = session.sql("""
        SELECT ROUND(COUNT_IF(ACTUAL_DELIVERY_DATE <= EXPECTED_DELIVERY_DATE)
               / NULLIF(COUNT(*), 0) * 100, 1) AS otd
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS
    """).collect()[0]["OTD"]

    fill = session.sql("""
        SELECT ROUND(SUM(QUANTITY_SHIPPED) / NULLIF(SUM(QUANTITY_ORDERED), 0) * 100, 1) AS fill
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDERS
    """).collect()[0]["FILL"]

    doi = session.sql("""
        SELECT ROUND(AVG(QUANTITY_ON_HAND) / NULLIF(AVG(DAILY_CONSUMPTION_RATE), 0), 1) AS doi
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.INVENTORY_SNAPSHOTS
    """).collect()[0]["DOI"]

    landed = session.sql("""
        SELECT ROUND(SUM(SHIPPING_COST + CUSTOMS_DUTY + HANDLING_FEE), 0) AS landed
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS
    """).collect()[0]["LANDED"]

    return otd, fill, doi, landed


with st.sidebar:
    st.title(":material/local_shipping: Supply Chain Insights")
    st.caption("Governed metrics from the Supply Chain Ontology")

    otd, fill, doi, landed = load_kpis()

    st.metric("On-Time Delivery", f"{otd}%", help="Benchmark: 90-95%")
    st.metric("Fill Rate", f"{fill}%", help="Benchmark: 95-98%")
    st.metric("Days of Inventory", f"{doi}", help="Benchmark: 30-60 days")
    st.metric("Total Landed Cost", f"${landed:,.0f}")

    st.divider()
    st.caption("Powered by Snowflake Cortex Agent + Semantic View")
    if st.button("Clear chat"):
        st.session_state.messages = []
        st.rerun()


# ── Agent call ───────────────────────────────────────────────
AGENT_FQN = "SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLY_CHAIN_AGENT"


def call_agent(question: str) -> str:
    """Call the Cortex Agent and return the text response."""
    request_obj = {
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": question}]
            }
        ]
    }
    # Pass JSON string directly as a SQL string literal (escaped single quotes)
    request_str = json.dumps(request_obj).replace("'", "''")

    sql = f"""
        SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            '{AGENT_FQN}',
            '{request_str}',
            TRUE
        ) AS response
    """
    result = session.sql(sql).collect()
    raw = result[0]["RESPONSE"]

    if isinstance(raw, str):
        parsed = json.loads(raw)
    else:
        parsed = raw

    if not isinstance(parsed, dict):
        return str(raw)

    content_list = parsed.get("content", [])
    if isinstance(content_list, list):
        texts = [
            item["text"].strip()
            for item in content_list
            if isinstance(item, dict) and item.get("type") == "text" and item.get("text", "").strip()
        ]
        if texts:
            return "\n\n".join(texts)

    return str(raw)


# ── Chat UI ──────────────────────────────────────────────────
st.title("Supply Chain Insights Agent")
st.caption("Ask questions about orders, shipments, suppliers, inventory, plants, and customers")

if "messages" not in st.session_state:
    st.session_state.messages = []

SUGGESTIONS = {
    ":blue[:material/query_stats:] On-time delivery rate": "What is the on-time delivery rate?",
    ":green[:material/inventory:] Days of inventory by plant": "What are the days of inventory by plant?",
    ":orange[:material/local_shipping:] Landed cost by carrier": "What is the total landed cost by carrier?",
    ":violet[:material/star:] Best suppliers": "Which suppliers have the best reliability?",
}

if not st.session_state.messages:
    selected = st.pills("Try asking:", list(SUGGESTIONS.keys()), label_visibility="collapsed")
    if selected:
        st.session_state.messages.append({"role": "user", "content": SUGGESTIONS[selected]})
        st.rerun()

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

# Check if last message is user (needs agent response) — handles both pills and chat_input
needs_response = (
    st.session_state.messages
    and st.session_state.messages[-1]["role"] == "user"
)

if needs_response:
    with st.chat_message("assistant"):
        with st.spinner("Querying the Supply Chain Agent..."):
            try:
                question = st.session_state.messages[-1]["content"]
                response = call_agent(question)
            except Exception as e:
                response = f"Error calling agent: {e}"
        st.markdown(response)
    st.session_state.messages.append({"role": "assistant", "content": response})

if prompt := st.chat_input("Ask about your supply chain..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    st.rerun()
