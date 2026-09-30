/*=============================================================
  Supply Chain Ontology — Step 4: Generate Inventory Snapshots
  Weekly snapshots for 6 plants x 12 parts x 80 weeks = 5,760 rows
  =============================================================*/

USE DATABASE SUPPLY_CHAIN_ONTOLOGY;
USE SCHEMA CORE;

-- Generate weekly inventory snapshot data using a cross-join approach
INSERT INTO INVENTORY_SNAPSHOTS
WITH weeks AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS week_num,
           DATEADD('week', ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, '2024-01-01'::DATE) AS snapshot_date
    FROM TABLE(GENERATOR(ROWCOUNT => 80))
),
plant_parts AS (
    SELECT p.PLANT_ID, pt.PART_ID
    FROM PLANTS p
    CROSS JOIN PARTS pt
),
raw_data AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY pp.PLANT_ID, pp.PART_ID, w.snapshot_date) AS snapshot_id,
        pp.PLANT_ID,
        pp.PART_ID,
        w.snapshot_date,
        -- Randomized but deterministic inventory levels using HASH
        ABS(MOD(HASH(pp.PLANT_ID * 1000 + pp.PART_ID * 10 + w.week_num), 4800)) + 100 AS quantity_on_hand,
        ABS(MOD(HASH(pp.PLANT_ID * 1000 + pp.PART_ID * 10 + w.week_num + 7777), 500)) AS quantity_reserved,
        ABS(MOD(HASH(pp.PLANT_ID * 1000 + pp.PART_ID * 10 + w.week_num + 3333), 200)) + 10.00 AS daily_consumption_rate,
        ABS(MOD(HASH(pp.PLANT_ID * 1000 + pp.PART_ID * 10 + w.week_num + 9999), 900)) + 50 AS reorder_point
    FROM plant_parts pp
    CROSS JOIN weeks w
)
SELECT
    snapshot_id,
    PLANT_ID,
    PART_ID,
    snapshot_date,
    quantity_on_hand,
    quantity_reserved,
    GREATEST(quantity_on_hand - quantity_reserved, 0) AS quantity_available,
    daily_consumption_rate,
    reorder_point
FROM raw_data;
