-- KPI 2: Fornecedores — Confiabilidade vs Receita (Matriz de Risco)
-- Pergunta: Em quais fornecedores estamos mais dependentes e quais são os menos confiáveis?
WITH fornecedor_analise AS (
    SELECT
        f.supplier_name,
        f.classificacao_fornecedor,
        f.media_atraso_dias,
        f.pct_entregas_atrasadas,
        COUNT(DISTINCT v.order_id)                             AS total_pedidos,
        ROUND(SUM(v.net_revenue), 2)                          AS receita_liquida,
        ROUND(SUM(v.net_revenue) / SUM(SUM(v.net_revenue))
              OVER () * 100, 2)                               AS pct_receita_total,
        COUNT(DISTINCT v.sk_produto)                          AS skus_atendidos,
        SUM(CASE WHEN v.is_late_delivery THEN 1 ELSE 0 END)  AS total_atrasos,
        SUM(CASE WHEN v.is_returned      THEN 1 ELSE 0 END)  AS total_devolvidos,
        ROUND(SUM(CASE WHEN v.is_returned THEN v.net_revenue ELSE 0 END), 2) AS receita_devolvida
    FROM ruptura_rj.dim_fornecedor f
    JOIN ruptura_rj.fato_vendas v ON f.sk_fornecedor = v.sk_fornecedor
    GROUP BY f.supplier_name, f.classificacao_fornecedor,
             f.media_atraso_dias, f.pct_entregas_atrasadas
),
quartis AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY receita_liquida DESC)        AS quartil_receita,
        NTILE(4) OVER (ORDER BY pct_entregas_atrasadas ASC)  AS quartil_confiabilidade
    FROM fornecedor_analise
)
SELECT
    supplier_name                         AS fornecedor,
    classificacao_fornecedor,
    CONCAT(pct_entregas_atrasadas, '%')   AS pct_atrasos,
    CONCAT(media_atraso_dias, ' dias')    AS atraso_medio,
    CONCAT('R$ ', FORMAT_NUMBER(receita_liquida, 2)) AS receita_liquida,
    CONCAT(pct_receita_total, '%')        AS pct_do_faturamento,
    skus_atendidos                        AS qtd_skus,
    total_devolvidos,
    CONCAT('R$ ', FORMAT_NUMBER(receita_devolvida, 2)) AS receita_devolvida,
    CASE
        WHEN quartil_receita = 1 AND quartil_confiabilidade = 1 THEN '🟢 Estratégico'
        WHEN quartil_receita = 1 AND quartil_confiabilidade > 2 THEN '🔴 Risco Crítico'
        WHEN quartil_receita > 2 AND quartil_confiabilidade = 1 THEN '🔵 Parceiro em Crescimento'
        ELSE '🟡 Monitorar'
    END AS quadrante_estrategico
FROM quartis
ORDER BY receita_liquida DESC
LIMIT 30;
