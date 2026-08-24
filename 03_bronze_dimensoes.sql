-- Produtos (SKUs)
CREATE OR REPLACE TABLE ruptura_rj.bronze_parts
USING DELTA
COMMENT 'Bronze: catálogo de produtos - fonte samples.tpch'
AS
SELECT
    p_partkey     AS product_id,
    p_name        AS product_name,
    p_mfgr        AS manufacturer,
    p_brand       AS brand,
    p_type        AS product_type,
    p_size        AS size_info,
    p_container   AS container_type,
    p_retailprice AS retail_price,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.part;

-- Fornecedores
CREATE OR REPLACE TABLE ruptura_rj.bronze_supplier
USING DELTA
AS
SELECT
    s_suppkey   AS supplier_id,
    s_name      AS supplier_name,
    s_address   AS address,
    s_nationkey AS nation_id,
    s_phone     AS phone,
    s_acctbal   AS account_balance,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.supplier;

-- Contratos ERP: produto x fornecedor (lead time e custo)
CREATE OR REPLACE TABLE ruptura_rj.bronze_partsupp
USING DELTA
AS
SELECT
    ps_partkey    AS product_id,
    ps_suppkey    AS supplier_id,
    ps_availqty   AS available_qty,
    ps_supplycost AS supply_cost,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.partsupp;

-- Clientes
CREATE OR REPLACE TABLE ruptura_rj.bronze_customer
USING DELTA
AS
SELECT
    c_custkey    AS customer_id,
    c_name       AS customer_name,
    c_nationkey  AS nation_id,
    c_mktsegment AS market_segment,
    c_acctbal    AS account_balance,
    current_timestamp() AS ingestion_ts
FROM samples.tpch.customer;

SELECT 'bronze_parts'    AS tabela, COUNT(*) AS registros FROM ruptura_rj.bronze_parts    UNION ALL
SELECT 'bronze_supplier' AS tabela, COUNT(*) AS registros FROM ruptura_rj.bronze_supplier  UNION ALL
SELECT 'bronze_partsupp' AS tabela, COUNT(*) AS registros FROM ruptura_rj.bronze_partsupp  UNION ALL
SELECT 'bronze_customer' AS tabela, COUNT(*) AS registros FROM ruptura_rj.bronze_customer;
