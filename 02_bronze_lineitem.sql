CREATE OR REPLACE TABLE ruptura_rj.bronze_lineitem
USING DELTA
COMMENT 'Bronze: itens de pedido brutos - fonte samples.tpch'
AS
SELECT
    l_orderkey        AS order_id,
    l_partkey         AS product_id,
    l_suppkey         AS supplier_id,
    l_linenumber      AS line_number,
    l_quantity        AS quantity,
    l_extendedprice   AS gross_revenue,
    l_discount        AS discount_pct,
    l_tax             AS tax_pct,
    l_returnflag      AS return_flag,
    l_linestatus      AS line_status,
    l_shipdate        AS ship_date,
    l_commitdate      AS commit_date,
    l_receiptdate     AS receipt_date,
    l_shipmode        AS ship_mode,
    l_comment         AS raw_comment,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.lineitem;

SELECT COUNT(*) AS total_itens FROM ruptura_rj.bronze_lineitem;
