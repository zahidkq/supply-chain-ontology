/*=============================================================
  Supply Chain Ontology — Step 5: Semantic View
  Governs canonical metrics across all supply chain domains
  =============================================================*/

USE DATABASE SUPPLY_CHAIN_ONTOLOGY;
USE SCHEMA CORE;

CREATE OR REPLACE SEMANTIC VIEW SUPPLY_CHAIN_ANALYTICS
  TABLES (
    SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMERS     PRIMARY KEY (CUSTOMER_ID) COMMENT = 'Master list of customers.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIERS     PRIMARY KEY (SUPPLIER_ID) COMMENT = 'Master list of suppliers.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.PARTS         PRIMARY KEY (PART_ID)     COMMENT = 'Parts catalog.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.PLANTS        PRIMARY KEY (PLANT_ID)    COMMENT = 'Manufacturing facilities.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER_PARTS PRIMARY KEY (SUPPLIER_ID, PART_ID) COMMENT = 'Supplier-Part pricing.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.ORDERS        PRIMARY KEY (ORDER_ID)    COMMENT = 'Customer orders.',
    SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS     PRIMARY KEY (SHIPMENT_ID) COMMENT = 'Shipment tracking.',
    INVENTORY AS SUPPLY_CHAIN_ONTOLOGY.CORE.INVENTORY_SNAPSHOTS PRIMARY KEY (SNAPSHOT_ID) COMMENT = 'Inventory snapshots.'
  )
  RELATIONSHIPS (
    SUPPLIER_PARTS_TO_PARTS      AS SUPPLIER_PARTS(PART_ID)     REFERENCES PARTS(PART_ID),
    SUPPLIER_PARTS_TO_SUPPLIERS  AS SUPPLIER_PARTS(SUPPLIER_ID) REFERENCES SUPPLIERS(SUPPLIER_ID),
    ORDERS_TO_CUSTOMERS          AS ORDERS(CUSTOMER_ID)         REFERENCES CUSTOMERS(CUSTOMER_ID),
    SHIPMENTS_TO_ORDERS          AS SHIPMENTS(ORDER_ID)         REFERENCES ORDERS(ORDER_ID),
    SHIPMENTS_TO_PLANTS          AS SHIPMENTS(PLANT_ID)         REFERENCES PLANTS(PLANT_ID),
    SHIPMENTS_TO_SUPPLIERS       AS SHIPMENTS(SUPPLIER_ID)      REFERENCES SUPPLIERS(SUPPLIER_ID),
    INVENTORY_TO_PARTS           AS INVENTORY(PART_ID)          REFERENCES PARTS(PART_ID),
    INVENTORY_TO_PLANTS          AS INVENTORY(PLANT_ID)         REFERENCES PLANTS(PLANT_ID)
  )
  FACTS (
    SUPPLIERS.LEAD_TIME_DAYS         AS LEAD_TIME_DAYS         WITH SYNONYMS = ('lead time')     COMMENT = 'Lead time days',
    SUPPLIERS.RELIABILITY_SCORE      AS RELIABILITY_SCORE      WITH SYNONYMS = ('reliability')   COMMENT = 'Reliability 0-1',
    PLANTS.PLANT_CAPACITY            AS CAPACITY_UNITS_PER_DAY WITH SYNONYMS = ('capacity')      COMMENT = 'Max units/day',
    SUPPLIER_PARTS.CONTRACTED_UNIT_COST AS UNIT_COST           WITH SYNONYMS = ('unit price')    COMMENT = 'Unit cost USD',
    ORDERS.QUANTITY_ORDERED          AS QUANTITY_ORDERED        COMMENT = 'Units ordered',
    ORDERS.QUANTITY_SHIPPED          AS QUANTITY_SHIPPED        COMMENT = 'Units shipped',
    ORDERS.ORDER_VALUE               AS TOTAL_VALUE            WITH SYNONYMS = ('order amount', 'revenue') COMMENT = 'Order value USD',
    SHIPMENTS.SHIPMENT_QUANTITY      AS QUANTITY_SHIPPED       WITH SYNONYMS = ('units shipped') COMMENT = 'Units in shipment',
    SHIPMENTS.SHIPPING_COST          AS SHIPPING_COST          COMMENT = 'Freight cost USD',
    SHIPMENTS.CUSTOMS_DUTY           AS CUSTOMS_DUTY           COMMENT = 'Import duty USD',
    SHIPMENTS.HANDLING_FEE           AS HANDLING_FEE           COMMENT = 'Handling fee USD',
    INVENTORY.INVENTORY_ON_HAND      AS QUANTITY_ON_HAND       WITH SYNONYMS = ('stock on hand')     COMMENT = 'Qty in plant',
    INVENTORY.INVENTORY_AVAILABLE    AS QUANTITY_AVAILABLE     WITH SYNONYMS = ('available stock')   COMMENT = 'Qty available',
    INVENTORY.DAILY_CONSUMPTION      AS DAILY_CONSUMPTION_RATE WITH SYNONYMS = ('usage rate', 'burn rate') COMMENT = 'Daily consumption'
  )
  DIMENSIONS (
    CUSTOMERS.CUSTOMER_NAME      AS CUSTOMER_NAME       WITH SYNONYMS = ('customer', 'buyer')        COMMENT = 'Customer name',
    CUSTOMERS.SEGMENT            AS SEGMENT             WITH SYNONYMS = ('market segment', 'industry') COMMENT = 'Market segment',
    CUSTOMERS.CUSTOMER_REGION    AS REGION              WITH SYNONYMS = ('customer region')           COMMENT = 'Customer region',
    CUSTOMERS.CUSTOMER_COUNTRY   AS COUNTRY             COMMENT = 'Customer country',
    SUPPLIERS.SUPPLIER_NAME      AS SUPPLIER_NAME       WITH SYNONYMS = ('vendor')                   COMMENT = 'Supplier name',
    SUPPLIERS.SUPPLIER_CATEGORY  AS CATEGORY            WITH SYNONYMS = ('supplier type')            COMMENT = 'Supplier category',
    SUPPLIERS.SUPPLIER_COUNTRY   AS COUNTRY             COMMENT = 'Supplier country',
    SUPPLIERS.SUPPLIER_REGION    AS REGION              COMMENT = 'Supplier region',
    PARTS.PART_NAME              AS PART_NAME           WITH SYNONYMS = ('component', 'material')    COMMENT = 'Part name',
    PARTS.PART_CATEGORY          AS PART_CATEGORY       WITH SYNONYMS = ('part type')                COMMENT = 'Part category',
    PARTS.IS_CRITICAL            AS IS_CRITICAL         COMMENT = 'Critical part flag',
    PLANTS.PLANT_NAME            AS PLANT_NAME          WITH SYNONYMS = ('facility', 'factory')      COMMENT = 'Plant name',
    PLANTS.PLANT_COUNTRY         AS COUNTRY             COMMENT = 'Plant country',
    PLANTS.PLANT_REGION          AS REGION              COMMENT = 'Plant region',
    PLANTS.PLANT_TYPE            AS PLANT_TYPE          COMMENT = 'Facility type',
    ORDERS.ORDER_DATE            AS ORDER_DATE          WITH SYNONYMS = ('purchase date')            COMMENT = 'Order date',
    ORDERS.REQUESTED_DELIVERY_DATE AS REQUESTED_DELIVERY_DATE COMMENT = 'Requested delivery',
    ORDERS.ORDER_STATUS          AS ORDER_STATUS        WITH SYNONYMS = ('status')                   COMMENT = 'SHIPPED or PENDING',
    ORDERS.ORDER_PRIORITY        AS PRIORITY            WITH SYNONYMS = ('urgency')                  COMMENT = 'Order priority',
    SHIPMENTS.SHIP_DATE          AS SHIP_DATE           COMMENT = 'Dispatch date',
    SHIPMENTS.EXPECTED_DELIVERY_DATE AS EXPECTED_DELIVERY_DATE COMMENT = 'Expected arrival',
    SHIPMENTS.ACTUAL_DELIVERY_DATE   AS ACTUAL_DELIVERY_DATE   COMMENT = 'Actual arrival',
    SHIPMENTS.CARRIER            AS CARRIER             WITH SYNONYMS = ('shipping company')         COMMENT = 'Carrier',
    INVENTORY.INVENTORY_DATE     AS SNAPSHOT_DATE       WITH SYNONYMS = ('inventory date')           COMMENT = 'Snapshot date'
  )
  METRICS (
    SHIPMENTS.ON_TIME_DELIVERY_RATE AS
      COUNT_IF(shipments.actual_delivery_date <= shipments.expected_delivery_date) /
      NULLIF(COUNT(shipments.shipment_id), 0) * 100
      WITH SYNONYMS = ('OTD', 'on time rate')
      COMMENT = 'On-time delivery pct. Benchmark 90-95%.',

    ORDERS.FILL_RATE AS
      SUM(orders.quantity_shipped) / NULLIF(SUM(orders.quantity_ordered), 0) * 100
      WITH SYNONYMS = ('order fill rate', 'fulfillment rate')
      COMMENT = 'Fill rate pct. Benchmark 95-98%.',

    INVENTORY.DAYS_OF_INVENTORY AS
      AVG(inventory.inventory_on_hand) / NULLIF(AVG(inventory.daily_consumption), 0)
      WITH SYNONYMS = ('DOI', 'inventory days', 'days of supply')
      COMMENT = 'Days of inventory. Benchmark 30-60.',

    SHIPMENTS.TOTAL_LANDED_COST AS
      SUM(shipments.shipping_cost + shipments.customs_duty + shipments.handling_fee)
      WITH SYNONYMS = ('landed cost')
      COMMENT = 'Total landed cost.',

    ORDERS.TOTAL_REVENUE AS
      SUM(orders.order_value)
      WITH SYNONYMS = ('revenue', 'sales')
      COMMENT = 'Total revenue USD',

    ORDERS.TOTAL_ORDERS AS
      COUNT(orders.order_id)
      WITH SYNONYMS = ('order count')
      COMMENT = 'Total orders',

    SHIPMENTS.TOTAL_SHIPMENTS AS
      COUNT(shipments.shipment_id)
      WITH SYNONYMS = ('shipment count')
      COMMENT = 'Total shipments',

    SUPPLIERS.AVG_LEAD_TIME AS
      AVG(suppliers.lead_time_days)
      WITH SYNONYMS = ('average lead time')
      COMMENT = 'Avg lead time',

    SUPPLIERS.AVG_SUPPLIER_RELIABILITY AS
      AVG(suppliers.reliability_score) * 100
      WITH SYNONYMS = ('avg reliability')
      COMMENT = 'Avg reliability pct'
  )
  COMMENT = 'Supply Chain Ontology: canonical metrics (OTD, Fill Rate, DOI, Landed Cost) for governed conversational analytics.'
  AI_SQL_GENERATION 'Use EXACT metric formulas: OTD=COUNT_IF(ACTUAL_DELIVERY_DATE<=EXPECTED_DELIVERY_DATE)/NULLIF(COUNT(*),0)*100. Fill Rate=SUM(QUANTITY_SHIPPED)/NULLIF(SUM(QUANTITY_ORDERED),0)*100. DOI=AVG(QUANTITY_ON_HAND)/NULLIF(AVG(DAILY_CONSUMPTION_RATE),0). Landed Cost=SUM(SHIPPING_COST+CUSTOMS_DUTY+HANDLING_FEE). Use ORDER_DATE for order time filters, SHIP_DATE for shipment time filters.'
  AI_QUESTION_CATEGORIZATION 'Domains: Planning(inventory,DOI,capacity), Procurement(suppliers,costs,reliability), Logistics(OTD,shipments,carriers,landed cost), Sales(orders,revenue,fill rate). Cross-domain queries supported.'
  AI_VERIFIED_QUERIES (
    OVERALL_OTD AS (
      QUESTION 'What is the on-time delivery rate?'
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT COUNT_IF(s.ACTUAL_DELIVERY_DATE <= s.EXPECTED_DELIVERY_DATE) / NULLIF(COUNT(*), 0) * 100 AS on_time_delivery_rate FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS s'
    ),
    OTD_BY_QUARTER AS (
      QUESTION 'What is the on-time delivery rate by quarter?'
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT DATE_TRUNC(''QUARTER'', s.SHIP_DATE) AS quarter, COUNT_IF(s.ACTUAL_DELIVERY_DATE <= s.EXPECTED_DELIVERY_DATE) / NULLIF(COUNT(*), 0) * 100 AS otd_rate FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS s GROUP BY quarter ORDER BY quarter'
    ),
    OVERALL_FILL_RATE AS (
      QUESTION 'What is the fill rate?'
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT SUM(QUANTITY_SHIPPED) / NULLIF(SUM(QUANTITY_ORDERED), 0) * 100 AS fill_rate FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDERS'
    ),
    DOI_BY_PLANT AS (
      QUESTION 'What are the days of inventory by plant?'
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT p.PLANT_NAME, AVG(i.QUANTITY_ON_HAND) / NULLIF(AVG(i.DAILY_CONSUMPTION_RATE), 0) AS days_of_inventory FROM SUPPLY_CHAIN_ONTOLOGY.CORE.INVENTORY_SNAPSHOTS i JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PLANTS p ON i.PLANT_ID = p.PLANT_ID GROUP BY p.PLANT_NAME ORDER BY days_of_inventory DESC'
    ),
    LANDED_COST_BY_CARRIER AS (
      QUESTION 'What is the total landed cost by carrier?'
      SQL 'SELECT CARRIER, SUM(SHIPPING_COST + CUSTOMS_DUTY + HANDLING_FEE) AS total_landed_cost FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS GROUP BY CARRIER ORDER BY total_landed_cost DESC'
    ),
    REVENUE_BY_SEGMENT AS (
      QUESTION 'What is the total revenue by customer segment?'
      SQL 'SELECT c.SEGMENT, SUM(o.TOTAL_VALUE) AS total_revenue, COUNT(*) AS order_count FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDERS o JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMERS c ON o.CUSTOMER_ID = c.CUSTOMER_ID GROUP BY c.SEGMENT ORDER BY total_revenue DESC'
    ),
    OTD_BY_CARRIER AS (
      QUESTION 'What is the on-time delivery rate by carrier?'
      SQL 'SELECT CARRIER, COUNT_IF(ACTUAL_DELIVERY_DATE <= EXPECTED_DELIVERY_DATE) / NULLIF(COUNT(*), 0) * 100 AS otd_rate, COUNT(*) AS total_shipments FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENTS GROUP BY CARRIER ORDER BY otd_rate DESC'
    ),
    BEST_SUPPLIERS AS (
      QUESTION 'Which suppliers have the best reliability?'
      SQL 'SELECT SUPPLIER_NAME, RELIABILITY_SCORE * 100 AS reliability_pct, LEAD_TIME_DAYS FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIERS ORDER BY RELIABILITY_SCORE DESC'
    )
  );
