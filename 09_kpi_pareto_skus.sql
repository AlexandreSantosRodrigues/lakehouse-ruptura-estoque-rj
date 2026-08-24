-- KPI 1: Top 20 SKUs que mais corroem o caixa (análise de Pareto)
-- Pergunta: Quais produtos, se entrarem em ruptura amanhã, causam o maior impacto na receita?
WITH fornecedor_critico_por_produto AS (
    -- Pré-computa o fornecedor mais crítico por produto (sem subquery correlacionada)
    SELECT
        ps.product_id,
        FIRST_VALUE(f.supplier_name) OVER (
            PARTITION BY ps.product_id
            ORDER BY f.pct_entregas_atrasadas DESC
        ) AS fornecedor_mais_critico
    FROM ruptura_rj.bronze_partsupp ps
    JOIN ruptura_rj.dim_fornecedor f ON ps.supplier_id = f.sk_fornecedor
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ps.product_id
        ORDER BY f.pct_entregas_atrasadas DESC
    ) = 1
),
base AS (
    SELECT
        r.sk_produto,
        r.product_name,
        r.brand,
        r.nivel_risco,
        r.score_risco_ruptura,
        r.receita_total,
        r.receita_em_risco,
        r.cobertura_estoque_dias,
        r.media_atraso_entrega,
        r.num_fornecedores,
        fc.fornecedor_mais_critico
    FROM ruptura_rj.fato_ruptura r
    LEFT JOIN fornecedor_critico_por_produto fc ON r.sk_produto = fc.product_id
    WHERE r.receita_em_risco > 0
),
ranking_impacto AS (
    SELECT
        *,
        ROUND(receita_total / SUM(receita_total) OVER () * 100, 2) AS pct_receita_total,
        ROUND(SUM(receita_em_risco) OVER (
            ORDER BY receita_em_risco DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2) AS receita_em_risco_acumulada,
        ROW_NUMBER() OVER (ORDER BY receita_em_risco DESC) AS ranking
    FROM base
)
SELECT
    ranking,
    product_name,
    brand,
    nivel_risco,
    score_risco_ruptura,
    CONCAT('R$ ', FORMAT_NUMBER(receita_total, 2))              AS receita_historica,
    CONCAT('R$ ', FORMAT_NUMBER(receita_em_risco, 2))           AS receita_em_risco,
    CONCAT(pct_receita_total, '%')                              AS pct_do_total,
    CONCAT(cobertura_estoque_dias, ' dias')                     AS cobertura_estoque,
    CONCAT(media_atraso_entrega, ' dias')                       AS atraso_medio_entrega,
    num_fornecedores,
    fornecedor_mais_critico,
    CONCAT('R$ ', FORMAT_NUMBER(receita_em_risco_acumulada, 2)) AS perda_acumulada_pareto
FROM ranking_impacto
WHERE ranking <= 20
ORDER BY ranking;
