-- KPI 3: Tendência e Sazonalidade das Rupturas
-- Pergunta: O problema de ruptura está piorando ao longo do tempo? Há sazonalidade?
WITH tendencia AS (
    SELECT
        ano,
        mes,
        nome_mes,
        trimestre,
        receita_liquida,
        pct_atraso,
        entregas_atrasadas,
        receita_devolvida,
        -- Variação MoM (mês a mês)
        LAG(receita_liquida) OVER (ORDER BY ano, mes) AS receita_mes_anterior,
        LAG(pct_atraso)      OVER (ORDER BY ano, mes) AS pct_atraso_mes_anterior,
        -- Média móvel 3 meses
        ROUND(AVG(receita_liquida) OVER (
            ORDER BY ano, mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2) AS media_movel_3m_receita,
        ROUND(AVG(pct_atraso) OVER (
            ORDER BY ano, mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1) AS media_movel_3m_atraso,
        -- Rank do pior mês de atraso por ano
        RANK() OVER (PARTITION BY ano ORDER BY pct_atraso DESC) AS rank_pior_mes_ano
    FROM ruptura_rj.vw_kpi_tendencia_mensal
)
SELECT
    ano,
    mes,
    nome_mes,
    CONCAT('T', trimestre)                                         AS trimestre,
    CONCAT('R$ ', FORMAT_NUMBER(receita_liquida, 2))              AS receita_mes,
    CONCAT('R$ ', FORMAT_NUMBER(media_movel_3m_receita, 2))       AS media_movel_3m,
    CONCAT(pct_atraso, '%')                                        AS pct_entregas_atrasadas,
    CONCAT(media_movel_3m_atraso, '%')                            AS tendencia_atraso_3m,
    CASE
        WHEN receita_mes_anterior IS NOT NULL
        THEN CONCAT(
            ROUND((receita_liquida - receita_mes_anterior) / receita_mes_anterior * 100, 1),
            '%'
        )
        ELSE 'N/A'
    END AS variacao_mom_receita,
    CASE
        WHEN pct_atraso_mes_anterior IS NOT NULL
        THEN CONCAT(ROUND(pct_atraso - pct_atraso_mes_anterior, 1), 'pp')
        ELSE 'N/A'
    END AS variacao_mom_atraso,
    CONCAT('R$ ', FORMAT_NUMBER(receita_devolvida, 2))            AS receita_perdida_devolucao,
    CASE WHEN rank_pior_mes_ano = 1 THEN '⚠️ Pior mês do ano' ELSE '' END AS alerta
FROM tendencia
ORDER BY ano, mes;
