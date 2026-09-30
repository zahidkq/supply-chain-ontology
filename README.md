# Supply Chain Ontology — Snowflake Cortex Agent

An end-to-end **governed supply chain analytics** solution built on Snowflake, featuring a **Cortex Agent** that provides consistent, canonical metrics across planning, procurement, logistics, and sales domains.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Streamlit Chat UI                        │
│              (streamlit_app/streamlit_app.py)             │
└──────────────────┬───────────────────────────────────────┘
                   │ SNOWFLAKE.CORTEX.INVOKE_AGENT()
┌──────────────────▼───────────────────────────────────────┐
│              SUPPLY_CHAIN_AGENT                           │
│           (Cortex Agent — orchestration)                  │
├──────────────┬───────────────────────────────────────────┤
│  Cortex      │  Cortex Search Services                   │
│  Analyst     │  ┌─────────────┐ ┌──────────────┐        │
│  (Text→SQL)  │  │ SUPPLIERS   │ │ PARTS        │        │
│              │  │ _SEARCH     │ │ _SEARCH      │        │
│              │  └─────────────┘ └──────────────┘        │
│              │  ┌─────────────┐ ┌──────────────┐        │
│              │  │ CUSTOMERS   │ │ PLANTS       │        │
│              │  │ _SEARCH     │ │ _SEARCH      │        │
│              │  └─────────────┘ └──────────────┘        │
└──────┬───────┴───────────────────────────────────────────┘
       │
┌──────▼───────────────────────────────────────────────────┐
│         SUPPLY_CHAIN_ANALYTICS (Semantic View)           │
│  Canonical Metrics: OTD, Fill Rate, DOI, Landed Cost     │
│  8 Tables • 8 Relationships • 14 Facts • 24 Dimensions  │
│  9 Metrics • 8 Verified Queries                          │
└──────────────────────────────────────────────────────────┘
       │
┌──────▼───────────────────────────────────────────────────┐
│  SUPPLY_CHAIN_ONTOLOGY.CORE (Governed Tables)            │
│  CUSTOMERS │ SUPPLIERS │ PARTS │ PLANTS │ SUPPLIER_PARTS │
│  ORDERS │ SHIPMENTS │ INVENTORY_SNAPSHOTS                │
│  All CERTIFIED + tagged: DATA_DOMAIN, ONTOLOGY_ENTITY,   │
│  SENSITIVITY                                              │
└──────────────────────────────────────────────────────────┘
```

## Key Features

- **Governed Metrics**: Four canonical KPIs (OTD, Fill Rate, DOI, Landed Cost) defined once in a Semantic View — every persona gets the same answer
- **Cortex Agent**: Natural language interface that routes to the right tool (Cortex Analyst for analytics, Cortex Search for entity lookups)
- **Data Governance**: All tables certified with classification tags (Data Domain, Ontology Entity, Sensitivity)
- **Verified Queries**: 8 pre-validated SQL queries for common questions
- **Semantic Search**: Four Cortex Search Services for entity lookup across suppliers, parts, customers, and plants

## Setup Instructions

### Prerequisites

- Snowflake account with **Cortex Agent**, **Cortex Analyst**, and **Cortex Search** enabled
- `ACCOUNTADMIN` role (or equivalent) for initial setup
- A warehouse (e.g., `COMPUTE_WH`)

### Step-by-step deployment

Run the SQL scripts in order:

```bash
# 1. Create database, schema, and governance tags
snowsql -f sql/01_setup_database.sql

# 2. Create all 8 tables with certification tags
snowsql -f sql/02_create_tables.sql

# 3. Load seed data (customers, suppliers, parts, plants, orders, shipments)
snowsql -f sql/03_load_seed_data.sql

# 4. Generate inventory snapshot data (5,760 rows)
snowsql -f sql/04_generate_inventory.sql

# 5. Create the Semantic View with metrics and verified queries
snowsql -f sql/05_create_semantic_view.sql

# 6. Create Cortex Search Services for entity lookup
snowsql -f sql/06_create_cortex_search.sql

# 7. Create the Cortex Agent
snowsql -f sql/07_create_agent.sql
```

### Deploy the Streamlit prototype

1. In Snowsight, go to **Projects > Workspaces**
2. Create a new Workspace and upload the `streamlit_app/` folder contents
3. Click **Run** to launch the app
4. Share the app URL as your deployed prototype link

## Data Model

| Table | Type | Rows | Description |
|-------|------|------|-------------|
| `CUSTOMERS` | Master Data | 10 | Customers across 5 segments and 4 regions |
| `SUPPLIERS` | Master Data | 12 | Suppliers with reliability scores and lead times |
| `PARTS` | Master Data | 12 | Parts catalog with criticality flags |
| `PLANTS` | Operations | 6 | Manufacturing facilities across 5 countries |
| `SUPPLIER_PARTS` | Bridge | 15 | Supplier-part pricing contracts |
| `ORDERS` | Transaction | 200 | Customer orders (SHIPPED/PENDING) |
| `SHIPMENTS` | Transaction | 155 | Shipment tracking with landed cost components |
| `INVENTORY_SNAPSHOTS` | Time Series | 5,760 | Weekly inventory for all plant-part combinations |

## Canonical Metrics

| Metric | Formula | Benchmark |
|--------|---------|-----------|
| **On-Time Delivery (OTD)** | `COUNT_IF(actual <= expected) / COUNT(*) * 100` | 90–95% |
| **Fill Rate** | `SUM(qty_shipped) / SUM(qty_ordered) * 100` | 95–98% |
| **Days of Inventory (DOI)** | `AVG(on_hand) / AVG(daily_consumption)` | 30–60 days |
| **Landed Cost** | `SUM(shipping + customs + handling)` | — |

## Example Questions

- "What is the on-time delivery rate?"
- "What are the days of inventory by plant?"
- "Which suppliers have the best reliability?"
- "What is the total revenue by customer segment?"
- "Find electronics suppliers in Asia"
- "What is the total landed cost by carrier?"
- "Show me critical parts"
- "Look up plants in Europe"

## Technology Stack

- **Snowflake Cortex Agent** — orchestrates tool routing
- **Cortex Analyst** — text-to-SQL via Semantic View
- **Cortex Search** — entity lookup with Arctic embeddings
- **Semantic View** — governed metric definitions
- **Streamlit in Snowflake** — chat-based prototype UI
- **Data Governance** — certification tags, ontology classification

## Project Structure

```
supply-chain-ontology/
├── README.md
├── sql/
│   ├── 01_setup_database.sql        # Database, schema, tags
│   ├── 02_create_tables.sql         # 8 certified tables
│   ├── 03_load_seed_data.sql        # Seed data for all tables
│   ├── 04_generate_inventory.sql    # Inventory snapshot generator
│   ├── 05_create_semantic_view.sql  # Semantic view with metrics
│   ├── 06_create_cortex_search.sql  # 4 search services
│   └── 07_create_agent.sql          # Cortex Agent definition
└── streamlit_app/
    ├── .streamlit/config.toml
    ├── snowflake.yml
    ├── pyproject.toml
    └── streamlit_app.py             # Chat UI prototype
```

## License

MIT
