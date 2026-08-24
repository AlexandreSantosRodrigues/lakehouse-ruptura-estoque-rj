CREATE OR REPLACE TABLE ruptura_rj.bronze_orders
USING DELTA
COMMENT 'Bronze: pedidos de venda brutos - fonte samples.tpch'
AS
SELECT
    o_orderkey        AS order_id,
    o_custkey         AS customer_id,
    o_orderstatus     AS order_status,
    o_totalprice      AS total_price,
    o_orderdate       AS order_date,
    o_orderpriority   AS order_priority,
    o_shippriority    AS ship_priority,
    o_comment         AS raw_comment,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.orders;

-- Valida contagem
SELECT COUNT(*) AS total_pedidos FROM ruptura_rj.bronze_orders;
