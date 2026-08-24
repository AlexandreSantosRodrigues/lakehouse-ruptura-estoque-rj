-- FATO_VENDAS (tabela central do Star Schema)
CREATE OR REPLACE TABLE ruptura_rj.fato_vendas
USING DELTA
COMMENT 'Fato: vendas com chaves para todas as dimensões'
AS
SELECT
    i.order_id,
    i.product_id       AS sk_produto,
    i.supplier_id      AS sk_fornecedor,
    o.customer_id      AS sk_cliente,
    i.ship_date        AS sk_data,
    i.ship_year,
    i.ship_month,
    i.quantity         AS qtd_vendida,
    i.gross_revenue,
    i.net_revenue,
    i.discount_pct,
    i.delivery_delay_days,
    i.is_late_delivery,
    i.is_returned,
    i.ship_mode
FROM ruptura_rj.silver_itens i
JOIN ruptura_rj.bronze_orders o ON i.order_id = o.order_id;

-- FATO_RUPTURA (tabela analítica de risco)
CREATE OR REPLACE TABLE ruptura_rj.fato_ruptura
USING DELTA
COMMENT 'Fato: produtos em risco de ruptura com receita em perigo'
AS
SELECT
    r.product_id       AS sk_produto,
    r.product_name,
    r.brand,
    r.product_type,
    r.nivel_risco,
    r.score_risco_ruptura,
    r.demanda_total_qty,
    r.estoque_total_disponivel,
    r.cobertura_estoque_dias,
    r.receita_total,
    r.receita_em_risco,
    r.media_atraso_entrega,
    r.qtd_entregas_atrasadas,
    r.num_fornecedores,
    r.ultima_venda
FROM ruptura_rj.silver_risco_ruptura r;

SELECT 'fato_vendas'  AS fato, COUNT(*) AS registros FROM ruptura_rj.fato_vendas  UNION ALL
SELECT 'fato_ruptura' AS fato, COUNT(*) AS registros FROM ruptura_rj.fato_ruptura;
