/*=============================================================
  Supply Chain Ontology — Step 7: Cortex Agent
  =============================================================*/

USE DATABASE SUPPLY_CHAIN_ONTOLOGY;
USE SCHEMA CORE;

CREATE OR REPLACE AGENT SUPPLY_CHAIN_AGENT
  COMMENT = 'Supply Chain Ontology Agent using SUPPLY_CHAIN_ONTOLOGY.CORE. Queries governed metrics (On-Time Delivery, Fill Rate, Days of Inventory, Landed Cost) via the SUPPLY_CHAIN_ANALYTICS semantic view through the supply_chain_analyst tool, covering orders, shipments, suppliers, inventory, customers, parts, and plants. Searches for specific suppliers by name, category, or region (SUPPLIERS_SEARCH), parts by name, category, or criticality (PARTS_SEARCH), customers by name, segment, or region (CUSTOMERS_SEARCH), and plants by location or type (PLANTS_SEARCH). Handles analytical questions about revenue, order counts, supplier reliability, lead times, and plant capacity, as well as entity lookups across the supply chain. Does not handle procurement workflows or external logistics tracking.'
  PROFILE = '{"display_name": "Supply Chain Insights Agent"}'
FROM SPECIFICATION
$$
models:
  orchestration: "auto"
instructions:
  response: |
    You are the Supply Chain Insights Agent, providing governed, consistent
    analytics across planning, procurement, logistics, and sales domains.

    CRITICAL RULES:
    1. Always use the canonical metric definitions from the semantic view - never approximate.
    2. The four canonical metrics are:
       - On-Time Delivery (OTD): percentage of shipments delivered on or before expected date
       - Fill Rate: percentage of ordered quantity that was actually shipped
       - Days of Inventory (DOI): how many days current stock lasts at current consumption
       - Landed Cost: total cost including freight, customs duty, and handling
    3. When asked the same question by different personas (planning, procurement, logistics),
       you MUST return the exact same metric value - this is the core governance guarantee.
    4. Present numbers clearly with appropriate formatting (percentages to 1 decimal, costs in USD).
    5. When relevant, compare results to industry benchmarks (OTD: 90-95%, Fill Rate: 95-98%, DOI: 30-60 days).
  orchestration: |
    TOOL ROUTING RULES (follow strictly in this priority order):

    1. SEARCH TOOLS — use these FIRST when the user wants to find, look up, list, or browse specific entities:
       - suppliers_search: find suppliers by name, category, country, or region
       - parts_search: find parts by name, category, or criticality
       - customers_search: find customers by name, segment, country, or region
       - plants_search: find plants by name, city, country, region, or type

    2. SUPPLY_CHAIN_ANALYST — use for analytical questions that require calculations, aggregations, metrics, or comparisons:
       - Metric calculations: OTD rate, fill rate, DOI, landed cost, revenue, order counts
       - Aggregations: totals, averages, sums, counts, rankings
       - Time-based analysis: trends by quarter, date-filtered queries
       - Cross-entity joins: revenue by segment, OTD by carrier, DOI by plant

    3. ROUTING DECISION GUIDE:
       - 'Find me X suppliers' or 'Look up customer Y' → SEARCH tool
       - 'What is the X metric?' or 'How many X?' or 'Total X by Y?' → supply_chain_analyst
       - 'What is the reliability of supplier X?' → suppliers_search first, then supply_chain_analyst for metric
       - If unsure, prefer search tools for entity lookups and supply_chain_analyst for calculations.
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "supply_chain_analyst"
      description: |
        Answers analytical questions about the supply chain using the governed ontology.
        Use for calculations, aggregations, metrics, and cross-entity analysis.
        Covers canonical metrics: On-Time Delivery (OTD), Fill Rate, Days of Inventory (DOI), Landed Cost.
        Also supports: total revenue, order counts, supplier reliability rankings, lead time averages, plant capacity comparisons.
  - tool_spec:
      type: "cortex_search"
      name: "suppliers_search"
      description: "Search for suppliers by name, category, country, or region."
  - tool_spec:
      type: "cortex_search"
      name: "parts_search"
      description: "Search for parts by name, category, or criticality."
  - tool_spec:
      type: "cortex_search"
      name: "customers_search"
      description: "Search for customers by name, segment, country, or region."
  - tool_spec:
      type: "cortex_search"
      name: "plants_search"
      description: "Search for plants by name, city, country, region, or type."
tool_resources:
  supply_chain_analyst:
    semantic_view: "SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLY_CHAIN_ANALYTICS"
    execution_environment:
      type: "warehouse"
      warehouse: "COMPUTE_WH"
  suppliers_search:
    search_service: "SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIERS_SEARCH"
    max_results: 5
  parts_search:
    search_service: "SUPPLY_CHAIN_ONTOLOGY.CORE.PARTS_SEARCH"
    max_results: 5
  customers_search:
    search_service: "SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMERS_SEARCH"
    max_results: 5
  plants_search:
    search_service: "SUPPLY_CHAIN_ONTOLOGY.CORE.PLANTS_SEARCH"
    max_results: 5
$$;
