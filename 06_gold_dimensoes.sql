-- DIM_PRODUTO
CREATE OR REPLACE TABLE ruptura_rj.dim_produto
USING DELTA
COMMENT 'Dimensão produto com categorização de negócio'
AS
SELECT
    product_id                                        AS sk_produto,
    product_name,
    brand,
    manufacturer,
    product_type,
    retail_price,
    CASE
        WHEN retail_price < 500   THEN 'Ticket Baixo'
        WHEN retail_price < 1500  THEN 'Ticket Médio'
        ELSE 'Ticket Alto'
    END AS faixa_preco,
    TRIM(REGEXP_EXTRACT(product_type, '^(\\w+\\s+\\w+)', 1)) AS categoria
FROM ruptura_rj.bronze_parts;

-- DIM_FORNECEDOR (com score de confiabilidade)
CREATE OR REPLACE TABLE ruptura_rj.dim_fornecedor
USING DELTA
COMMENT 'Dimensão fornecedor com score de confiabilidade'
AS
WITH fornecedor_metricas AS (
    SELECT
        supplier_id,
        ROUND(AVG(delivery_delay_days), 2)                AS media_atraso,
        ROUND(SUM(CASE WHEN is_late_delivery THEN 1.0 ELSE 0 END)
              / COUNT(*) * 100, 1)                        AS pct_entregas_atrasadas
    FROM ruptura_rj.silver_itens
    GROUP BY supplier_id
)
SELECT
    s.supplier_id                                         AS sk_fornecedor,
    s.supplier_name,
    s.account_balance,
    COALESCE(m.media_atraso, 0)                          AS media_atraso_dias,
    COALESCE(m.pct_entregas_atrasadas, 0)                AS pct_entregas_atrasadas,
    CASE
        WHEN COALESCE(m.pct_entregas_atrasadas, 0) < 10  THEN 'Confiável'
        WHEN COALESCE(m.pct_entregas_atrasadas, 0) < 30  THEN 'Atenção'
        ELSE 'Crítico'
    END AS classificacao_fornecedor
FROM ruptura_rj.bronze_supplier s
LEFT JOIN fornecedor_metricas m ON s.supplier_id = m.supplier_id;

-- DIM_TEMPO (calendário gerado a partir das datas reais de envio)
CREATE OR REPLACE TABLE ruptura_rj.dim_tempo
USING DELTA
COMMENT 'Dimensão tempo gerada a partir das datas de envio'
AS
SELECT DISTINCT
    ship_date                                             AS sk_data,
    ship_year                                             AS ano,
    ship_month                                            AS mes,
    DAY(ship_date)                                        AS dia,
    QUARTER(ship_date)                                    AS trimestre,
    WEEKOFYEAR(ship_date)                                 AS semana_ano,
    DAYOFWEEK(ship_date)                                  AS dia_semana,
    DATE_FORMAT(ship_date, 'MMMM')                       AS nome_mes,
    CASE WHEN DAYOFWEEK(ship_date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_fim_de_semana
FROM ruptura_rj.silver_itens
WHERE ship_date IS NOT NULL;

SELECT 'dim_produto'    AS dim, COUNT(*) AS registros FROM ruptura_rj.dim_produto    UNION ALL
SELECT 'dim_fornecedor' AS dim, COUNT(*) AS registros FROM ruptura_rj.dim_fornecedor UNION ALL
SELECT 'dim_tempo'      AS dim, COUNT(*) AS registros FROM ruptura_rj.dim_tempo;
