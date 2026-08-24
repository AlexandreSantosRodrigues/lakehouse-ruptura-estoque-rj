CREATE OR REPLACE TABLE ruptura_rj.silver_itens
USING DELTA
COMMENT 'Silver: itens limpos com receita líquida calculada e flags de qualidade'
AS
WITH dedup_itens AS (
    -- Remove duplicatas estruturais (order_id + product_id + line_number)
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, product_id, line_number
               ORDER BY ingestion_ts DESC
           ) AS rn
    FROM ruptura_rj.bronze_lineitem
),
itens_validos AS (
    SELECT
        order_id,
        product_id,
        supplier_id,
        line_number,
        quantity,
        gross_revenue,
        discount_pct,
        tax_pct,
        return_flag,
        line_status,
        ship_date,
        commit_date,
        receipt_date,
        ship_mode,
        -- Receita líquida real
        ROUND(gross_revenue * (1 - discount_pct) * (1 + tax_pct), 2) AS net_revenue,
        -- Dias de atraso na entrega (simula ruptura logística)
        DATEDIFF(receipt_date, commit_date)                           AS delivery_delay_days,
        -- Flag de devolução
        CASE WHEN return_flag = 'R' THEN TRUE ELSE FALSE END          AS is_returned,
        -- Flag de entrega atrasada (proxy de ruptura logística)
        CASE
            WHEN DATEDIFF(receipt_date, commit_date) > 0 THEN TRUE
            ELSE FALSE
        END AS is_late_delivery,
        -- Extrai ano e mês para particionamento analítico
        YEAR(ship_date)  AS ship_year,
        MONTH(ship_date) AS ship_month
    FROM dedup_itens
    WHERE rn = 1
      AND quantity       IS NOT NULL AND quantity > 0
      AND gross_revenue  IS NOT NULL AND gross_revenue > 0
      AND ship_date      IS NOT NULL
      AND product_id     IS NOT NULL
      AND supplier_id    IS NOT NULL
)
SELECT * FROM itens_validos;

-- Relatório de qualidade pós-limpeza
SELECT
    COUNT(*)                                           AS total_registros,
    SUM(CASE WHEN is_returned      THEN 1 ELSE 0 END) AS total_devolvidos,
    SUM(CASE WHEN is_late_delivery THEN 1 ELSE 0 END) AS total_atrasados,
    ROUND(AVG(delivery_delay_days), 1)                AS media_atraso_dias,
    ROUND(SUM(net_revenue), 2)                        AS receita_liquida_total
FROM ruptura_rj.silver_itens;
