-- KPI 1: Receita em risco por nível de criticidade e categoria
CREATE OR REPLACE VIEW ruptura_rj.vw_kpi_receita_em_risco AS
SELECT
    r.nivel_risco,
    p.faixa_preco,
    p.categoria,
    COUNT(DISTINCT r.sk_produto)          AS qtd_produtos,
    ROUND(SUM(r.receita_em_risco), 2)     AS receita_em_risco_total,
    ROUND(AVG(r.score_risco_ruptura), 1)  AS score_medio,
    ROUND(AVG(r.cobertura_estoque_dias))  AS cobertura_media_dias
FROM ruptura_rj.fato_ruptura r
JOIN ruptura_rj.dim_produto p ON r.sk_produto = p.sk_produto
GROUP BY r.nivel_risco, p.faixa_preco, p.categoria;

-- KPI 2: Performance de fornecedores (confiabilidade vs receita gerada)
CREATE OR REPLACE VIEW ruptura_rj.vw_kpi_fornecedor AS
SELECT
    f.supplier_name,
    f.classificacao_fornecedor,
    f.media_atraso_dias,
    f.pct_entregas_atrasadas,
    COUNT(DISTINCT v.order_id)                         AS total_pedidos,
    SUM(v.qtd_vendida)                                 AS total_qty_entregue,
    ROUND(SUM(v.net_revenue), 2)                       AS receita_liquida_gerada,
    SUM(CASE WHEN v.is_returned THEN 1 ELSE 0 END)    AS total_devolvidos
FROM ruptura_rj.dim_fornecedor f
JOIN ruptura_rj.fato_vendas v ON f.sk_fornecedor = v.sk_fornecedor
GROUP BY f.supplier_name, f.classificacao_fornecedor,
         f.media_atraso_dias, f.pct_entregas_atrasadas;

-- KPI 3: Tendência mensal de entregas atrasadas vs receita
CREATE OR REPLACE VIEW ruptura_rj.vw_kpi_tendencia_mensal AS
SELECT
    t.ano,
    t.mes,
    t.nome_mes,
    t.trimestre,
    COUNT(DISTINCT v.order_id)                          AS total_pedidos,
    SUM(v.qtd_vendida)                                  AS total_qty,
    ROUND(SUM(v.net_revenue), 2)                        AS receita_liquida,
    SUM(CASE WHEN v.is_late_delivery THEN 1 ELSE 0 END) AS entregas_atrasadas,
    ROUND(
        SUM(CASE WHEN v.is_late_delivery THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                   AS pct_atraso,
    ROUND(
        SUM(CASE WHEN v.is_returned THEN v.net_revenue ELSE 0 END), 2
    )                                                   AS receita_devolvida
FROM ruptura_rj.fato_vendas v
JOIN ruptura_rj.dim_tempo t ON v.sk_data = t.sk_data
GROUP BY t.ano, t.mes, t.nome_mes, t.trimestre
ORDER BY t.ano, t.mes;

SELECT 'vw_kpi_receita_em_risco' AS view_name, 'OK' AS status UNION ALL
SELECT 'vw_kpi_fornecedor'       AS view_name, 'OK' AS status UNION ALL
SELECT 'vw_kpi_tendencia_mensal' AS view_name, 'OK' AS status;
