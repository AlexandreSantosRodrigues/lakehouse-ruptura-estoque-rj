CREATE OR REPLACE TABLE ruptura_rj.silver_risco_ruptura
USING DELTA
COMMENT 'Silver: análise de risco de ruptura por produto e fornecedor'
AS
WITH demanda_por_produto AS (
    SELECT
        product_id,
        COUNT(DISTINCT order_id)           AS total_pedidos,
        SUM(quantity)                      AS demanda_total_qty,
        ROUND(SUM(net_revenue), 2)         AS receita_total,
        ROUND(AVG(delivery_delay_days), 2) AS media_atraso_entrega,
        SUM(CASE WHEN is_late_delivery THEN 1 ELSE 0 END) AS qtd_entregas_atrasadas,
        SUM(CASE WHEN is_returned      THEN 1 ELSE 0 END) AS qtd_devolvidos,
        MAX(ship_date)                     AS ultima_venda
    FROM ruptura_rj.silver_itens
    GROUP BY product_id
),
estoque_disponivel AS (
    SELECT
        product_id,
        SUM(available_qty)          AS estoque_total_disponivel,
        MIN(supply_cost)            AS menor_custo_reposicao,
        COUNT(DISTINCT supplier_id) AS num_fornecedores
    FROM ruptura_rj.bronze_partsupp
    GROUP BY product_id
),
analise_ruptura AS (
    SELECT
        d.product_id,
        p.product_name,
        p.brand,
        p.product_type,
        p.retail_price,
        d.total_pedidos,
        d.demanda_total_qty,
        d.receita_total,
        d.media_atraso_entrega,
        d.qtd_entregas_atrasadas,
        d.qtd_devolvidos,
        d.ultima_venda,
        e.estoque_total_disponivel,
        e.menor_custo_reposicao,
        e.num_fornecedores,
        -- Cobertura de estoque em dias
        ROUND(
            e.estoque_total_disponivel / NULLIF((d.demanda_total_qty / 365.0), 0),
        1) AS cobertura_estoque_dias,
        -- Receita em risco
        CASE
            WHEN e.estoque_total_disponivel < d.demanda_total_qty
            THEN ROUND((d.demanda_total_qty - e.estoque_total_disponivel)
                       * (d.receita_total / NULLIF(d.demanda_total_qty, 0)), 2)
            ELSE 0
        END AS receita_em_risco,
        -- Score de risco composto (0 a 100)
        ROUND(
            LEAST(100,
                (CASE WHEN e.estoque_total_disponivel < d.demanda_total_qty THEN 40 ELSE 0 END)
              + (LEAST(30, d.media_atraso_entrega * 3))
              + (LEAST(20, (d.qtd_entregas_atrasadas * 100.0 / NULLIF(d.total_pedidos, 0))))
              + (CASE WHEN e.num_fornecedores = 1 THEN 10 ELSE 0 END)
            ), 1
        ) AS score_risco_ruptura,
        -- Classificação de risco
        CASE
            WHEN e.estoque_total_disponivel < d.demanda_total_qty
              OR d.media_atraso_entrega > 5  THEN 'CRITICO'
            WHEN d.media_atraso_entrega > 2
              OR (d.qtd_entregas_atrasadas * 100.0 / NULLIF(d.total_pedidos, 0)) > 30 THEN 'ALTO'
            WHEN (d.qtd_entregas_atrasadas * 100.0 / NULLIF(d.total_pedidos, 0)) > 10 THEN 'MEDIO'
            ELSE 'BAIXO'
        END AS nivel_risco
    FROM demanda_por_produto d
    JOIN estoque_disponivel  e ON d.product_id = e.product_id
    JOIN ruptura_rj.bronze_parts p ON d.product_id = p.product_id
)
SELECT * FROM analise_ruptura;

-- Resumo de risco
SELECT nivel_risco,
       COUNT(*) AS produtos,
       ROUND(SUM(receita_em_risco), 2) AS receita_total_em_risco
FROM ruptura_rj.silver_risco_ruptura
GROUP BY nivel_risco
ORDER BY receita_total_em_risco DESC;
