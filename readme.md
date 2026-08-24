# 🏪📉 Lakehouse: Detecção de Ruptura de Estoque no Varejo

[![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=for-the-badge&logo=databricks&logoColor=white)](https://community.cloud.databricks.com)
[![Delta Lake](https://img.shields.io/badge/Delta%20Lake-00ADD8?style=for-the-badge&logo=delta&logoColor=white)](https://delta.io)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?style=for-the-badge&logo=apachespark&logoColor=white)](https://spark.apache.org)
[![SQL Only](https://img.shields.io/badge/100%25-SQL%20Only-blue?style=for-the-badge&logo=databricks)](https://docs.databricks.com/sql/index.html)
[![Licença MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-green?style=for-the-badge)](LICENSE)
[![Custo](https://img.shields.io/badge/Custo-%240-success?style=for-the-badge)](https://community.cloud.databricks.com)

> **Pipeline Lakehouse de ponta a ponta, 100% em Databricks SQL, que detecta, quantifica e prioriza rupturas de estoque em operações de varejo — transformando dados fragmentados em decisões estratégicas de alto impacto.**

---

## 📋 Visão Geral do Projeto

Este projeto implementa uma **arquitetura Medallion completa (Bronze → Silver → Gold)** sobre dados de operações de varejo para detectar, mensurar e priorizar rupturas de estoque antes que elas se tornem perda de caixa. A solução consome dados nativos do catálogo `samples.tpch` do Databricks, modelados em um **Star Schema** pronto para consumo analítico, e entrega KPIs estratégicos via **Databricks SQL Serverless** — sem nenhuma linha de Python, sem infraestrutura externa e com custo **zero**.

A principal inovação é o **Score de Risco de Ruptura**, um índice composto que combina cobertura de estoque, taxa de atraso logístico e dependência de fornecedor em um único número acionável — permitindo que a operação atue preventivamente, não reativamente.

---

## 🔥 O Desafio — O Problema de Negócio

A transformação digital acelerada deixou grande parte do varejo brasileiro com **sistemas profundamente fragmentados**: o ERP que gerencia o backoffice raramente conversa em tempo real com o PDV (ponto de venda) ou com a plataforma de e-commerce. O resultado direto é a **ruptura de estoque** — o produto existe em algum ponto da cadeia, mas está indisponível para o cliente no momento da compra.

Cada ruptura é um sangramento triplo no caixa:

| Impacto | Efeito Direto | Consequência no Longo Prazo |
|---|---|---|
| 💸 **Venda Perdida** | Receita que simplesmente não entra | Metas de GMV comprometidas |
| 😠 **Cliente Insatisfeito** | Experiência negativa no ponto de contato | Aumento de churn e redução de LTV |
| 📦 **Capital Imobilizado** | Estoque parado no lugar errado da cadeia | Custo financeiro e redução de giro |

Sem visibilidade consolidada e sem um sistema de priorização inteligente, os gestores **não sabem qual SKU endereçar primeiro**, **qual fornecedor está causando mais dano** e **em que mês do ano o problema é mais severo**. Esse projeto foi construído para eliminar exatamente essa cegueira operacional.

---

## ⚙️ A Solução Técnica e Diferenciais

A solução mapeia toda a cadeia de abastecimento — do contrato com o fornecedor até a entrega final ao cliente — e processa os dados em três camadas progressivas de refinamento:

### Pipeline de Dados

```
samples.tpch (fonte nativa Databricks)
       │
       ▼
🥉 BRONZE  ──►  Ingestão bruta em Delta (orders, lineitem, parts, partsupp, supplier, customer)
       │
       ▼
🥈 SILVER  ──►  Limpeza, deduplicação, receita líquida calculada, score de risco de ruptura por SKU
       │
       ▼
🥇 GOLD    ──►  Star Schema (dim_produto, dim_fornecedor, dim_tempo | fato_vendas, fato_ruptura)
                + 3 Views KPI prontas para dashboard executivo
```

### Funcionalidades Desenvolvidas

- ✅ **Ingestão Delta automatizada** de 6 entidades distintas com timestamp de auditoria
- ✅ **Deduplicação via Window Function** (`ROW_NUMBER`) garantindo integridade dos itens de pedido
- ✅ **Score de Risco de Ruptura** (0–100) composto por 4 dimensões: cobertura de estoque, média de atraso, taxa de atraso histórica e dependência de fornecedor único
- ✅ **Classificação automática de risco** em 4 níveis: `BAIXO`, `MEDIO`, `ALTO`, `CRITICO`
- ✅ **Matriz Fornecedor** com quadrantes estratégicos (Estratégico / Risco Crítico / Crescimento / Monitorar)
- ✅ **Análise de Pareto** — receita em risco acumulada para priorização dos 20 SKUs mais críticos
- ✅ **Tendência mensal com média móvel de 3 meses** e variação MoM (mês a mês) do percentual de atrasos
- ✅ **Star Schema dimensional** com `dim_produto`, `dim_fornecedor` e `dim_tempo` alimentando `fato_vendas` e `fato_ruptura`

---

## 🛠️ Stack Técnica

| Categoria | Tecnologia | Função no Projeto |
|---|---|---|
| **Processamento** | Apache Spark SQL 3.5 | Engine de processamento de todas as transformações |
| **Armazenamento** | Delta Lake | Formato transacional ACID para todas as camadas |
| **Plataforma** | Databricks Serverless SQL | Execução sem gerenciamento de infraestrutura |
| **Modelagem** | Star Schema (Kimball) | Estrutura dimensional Gold: Fatos + Dimensões |
| **Fonte de Dados** | `samples.tpch` (nativo) | Dataset TPCH mapeado como domínio de varejo |
| **Visualização** | Databricks Dashboards | Dashboard executivo nativo, sem ferramentas externas |
| **Controle** | `QUALIFY` + CTEs aninhadas | Lógica analítica avançada sem subqueries correlacionadas |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

| Requisito | Detalhe |
|---|---|
| Conta Databricks | [Community Edition gratuita](https://community.cloud.databricks.com) — custo $0 |
| Databricks Runtime | 15.x LTS ou superior (Spark 3.5+) |
| Catálogo disponível | `samples.tpch` (pré-carregado em toda conta Databricks) |
| Conhecimento necessário | SQL básico para acompanhamento |

> ⚠️ **Nenhuma instalação local é necessária.** Todo o projeto roda 100% no navegador via Databricks Serverless SQL.

---

### Passo 1 — Criar a Conta Databricks

Acesse [community.cloud.databricks.com](https://community.cloud.databricks.com) → clique em **"Sign up"** → selecione **"Get started with Community Edition"**.

---

### Passo 2 — Criar o Notebook

1. No menu lateral → **"Espaço de trabalho"** → **"+ Novo"** → **"Pasta"** → nomeie `portfolio-lakehouse`
2. Dentro da pasta → **"+ Criar"** → **"Notebook"**
3. Configure:

| Campo | Valor |
|---|---|
| Nome | `lakehouse_ruptura_estoque` |
| Linguagem padrão | **SQL** |
| Computação | Serverless (selecionado automaticamente) |

---

### Passo 3 — Validar o Ambiente

Cole na **Célula 1** e execute com `Shift + Enter`:

```sql
-- Sanity check: valida acesso aos dados nativos
SELECT current_catalog(), current_database(), current_timestamp();
```

```sql
-- Confirma disponibilidade do dataset TPCH
SHOW TABLES IN samples.tpch;
```

**Resultado esperado:** 8 tabelas listadas (`customer`, `lineitem`, `nation`, `orders`, `part`, `partsupp`, `region`, `supplier`).

---

### Passo 4 — Clonar ou Importar o Notebook

**Opção A — Importar via URL do repositório GitHub:**

No Databricks: **"Arquivo"** → **"Importar"** → cole a URL raw do notebook `.sql` deste repositório.

**Opção B — Executar manualmente célula a célula:**

Clone este repositório e copie cada bloco SQL em células sequenciais do notebook:

```bash
git clone https://github.com/seu-usuario/lakehouse-ruptura-estoque-rj.git
cd lakehouse-ruptura-estoque-rj
```

Os scripts estão organizados na pasta `/notebooks/` na seguinte ordem de execução:

```
notebooks/
├── 00_setup.sql              # Cria o database ruptura_rj
├── 01_bronze_orders.sql      # Camada Bronze: pedidos
├── 02_bronze_lineitem.sql    # Camada Bronze: itens
├── 03_bronze_dimensoes.sql   # Camada Bronze: produtos, fornecedores, clientes
├── 04_silver_itens.sql       # Camada Silver: limpeza e métricas de qualidade
├── 05_silver_risco.sql       # Camada Silver: score de risco de ruptura
├── 06_gold_dimensoes.sql     # Camada Gold: Star Schema - Dimensões
├── 07_gold_fatos.sql         # Camada Gold: Star Schema - Fatos
├── 08_gold_views_kpi.sql     # Camada Gold: Views para dashboard
├── 09_kpi_pareto_skus.sql    # KPI 1: Top 20 SKUs críticos (Pareto)
├── 10_kpi_matriz_fornecedor.sql  # KPI 2: Matriz de risco de fornecedores
└── 11_kpi_tendencia_mensal.sql   # KPI 3: Tendência e sazonalidade de rupturas
```

---

### Passo 5 — Executar o Pipeline Completo

Execute as células na ordem numérica. Ao final do script `08`, o banco `ruptura_rj` estará completo com:

```sql
-- Verificação final: lista todas as tabelas e views criadas
SHOW TABLES IN ruptura_rj;
```

**Output esperado:**

| database | tableName | isTemporary |
|---|---|---|
| ruptura_rj | bronze_customer | false |
| ruptura_rj | bronze_lineitem | false |
| ruptura_rj | bronze_orders | false |
| ruptura_rj | bronze_partsupp | false |
| ruptura_rj | bronze_parts | false |
| ruptura_rj | bronze_supplier | false |
| ruptura_rj | dim_fornecedor | false |
| ruptura_rj | dim_produto | false |
| ruptura_rj | dim_tempo | false |
| ruptura_rj | fato_ruptura | false |
| ruptura_rj | fato_vendas | false |
| ruptura_rj | silver_itens | false |
| ruptura_rj | silver_risco_ruptura | false |
| ruptura_rj | vw_kpi_fornecedor | false |
| ruptura_rj | vw_kpi_receita_em_risco | false |
| ruptura_rj | vw_kpi_tendencia_mensal | false |

---

## 📊 Demonstração — KPIs Gerados

### KPI 1 — Top SKUs com Maior Receita em Risco (Pareto)

```sql
SELECT ranking, product_name, nivel_risco,
       receita_em_risco, perda_acumulada_pareto
FROM   ruptura_rj.kpi_pareto_skus
WHERE  ranking <= 5
ORDER  BY ranking;
```

| ranking | product_name | nivel_risco | receita_em_risco | perda_acumulada_pareto |
|---|---|---|---|---|
| 1 | coral antique misty... | CRITICO | R\$ 9.842.310,00 | R\$ 9.842.310,00 |
| 2 | bisque dim slate... | ALTO | R\$ 8.127.450,00 | R\$ 17.969.760,00 |
| 3 | khaki maroon cream... | CRITICO | R\$ 7.903.220,00 | R\$ 25.872.980,00 |

---

### KPI 2 — Fornecedores por Quadrante Estratégico

```sql
SELECT fornecedor, quadrante_estrategico, pct_atrasos, receita_liquida
FROM   ruptura_rj.kpi_matriz_fornecedor
ORDER  BY receita_liquida DESC
LIMIT  10;
```

| fornecedor | quadrante_estrategico | pct_atrasos | receita_liquida |
|---|---|---|---|
| Supplier#000000001 | 🟢 Estratégico | 8.3% | R\$ 48.291.000,00 |
| Supplier#000000042 | 🔴 Risco Crítico | 51.7% | R\$ 45.830.000,00 |
| Supplier#000000017 | 🟡 Monitorar | 22.1% | R\$ 31.220.000,00 |

---

### KPI 3 — Tendência Mensal de Rupturas

```sql
SELECT ano, nome_mes, pct_entregas_atrasadas,
       tendencia_atraso_3m, variacao_mom_receita, alerta
FROM   ruptura_rj.kpi_tendencia_mensal
ORDER  BY ano, mes;
```

---

## 🏗️ Construindo o Dashboard Nativo

Após executar todos os scripts, construa o painel executivo direto no Databricks:

1. Menu lateral → **"Painéis"** → **"Criar painel"**
2. Nomeie: `Dashboard — Ruptura de Estoque Varejo RJ`
3. Adicione os widgets:

| Widget | Fonte | Tipo de Visualização |
|---|---|---|
| 💰 Receita Total em Risco | `vw_kpi_receita_em_risco` | Counter (Big Number) |
| 🔴 SKUs em Nível CRÍTICO | `fato_ruptura` | Counter com filtro |
| 📦 Top 20 SKUs (Pareto) | `kpi_pareto_skus` | Bar Chart horizontal |
| 🏭 Matriz Fornecedor | `kpi_matriz_fornecedor` | Scatter Plot |
| 📈 Tendência Mensal | `kpi_tendencia_mensal` | Line Chart (duplo eixo) |

---

## 🤝 Como Contribuir

Contribuições são bem-vindas e encorajadas. Para propor melhorias:

```bash
# 1. Faça um fork do repositório
# 2. Crie sua branch de feature
git checkout -b feature/nova-analise-kpi

# 3. Commit suas mudanças
git commit -m "feat: adiciona KPI de giro de estoque por categoria"

# 4. Abra um Pull Request detalhando o que foi adicionado e por quê
```

**Áreas abertas para contribuição:**
- [ ] Adicionar análise de sazonalidade com `PIVOT` SQL nativo
- [ ] Implementar detecção de anomalias via Z-Score em SQL puro
- [ ] Criar camada de alertas automatizados com Databricks SQL Alerts

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja o arquivo [`LICENSE`](LICENSE) para detalhes completos.

---

<div align="center">

**Desenvolvido como projeto de portfólio técnico avançado em Engenharia de Dados.**

*"Dados sem pipeline são ruído. Pipeline sem negócio é desperdício."*

</div>
