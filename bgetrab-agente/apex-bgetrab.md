# APEX - Projeto BGETRAB (ADW BGETRAB_OAC)

Documentacao dedicada ao APEX/ORDS do ambiente de desenvolvimento (ADW DA_ADW_BGETRAB_PROD,
schema BGETRAB_OAC). Complementa o oci-bgetrab.md (infraestrutura OCI). Mantido pelo assistente
a partir do que o usuario fornece (o assistente NAO acessa o APEX diretamente - ver nota).

> Nota de acesso: o APEX e acessado pelo usuario via tunel de Bastion (ver oci-bgetrab.md,
> secao "ACESSO AO APEX ... VIA BASTION"). URL: https://localhost/ords/_/landing. O assistente
> ajuda como copiloto (SQL/PLSQL, procedimentos, analise) e DOCUMENTA aqui o que o usuario coleta;
> nao consegue ler workspaces/apps por conta propria (acesso web autenticado, fora do OCI CLI).

Ultima atualizacao: 2026-10-21

## Ambiente

| Item | Valor |
|------|-------|
| ADW (data asset)   | DA_ADW_BGETRAB_PROD |
| Schema principal   | BGETRAB_OAC |
| Acesso APEX        | https://localhost/ords/_/landing (via tunel de bastion, porta local 443) |
| Regiao / Namespace | sa-saopaulo-1 / grmu0oy5wsd9 |

## Workspaces

Coletado em 2026-10-21 (SELECT em apex_workspaces). 1 workspace:

| Workspace | Workspace ID | Schema(s) associados | Observacoes |
|-----------|--------------|----------------------|-------------|
| WORKSPACE_BGETRAB_DEV | 9211902498453592 | BGETRAB_OAC | Workspace de desenvolvimento; schema confirmado (apex_workspace_schemas, 2026-10-21) |

## Aplicacoes

Coletado em 2026-10-21 (SELECT em apex_applications). 5 aplicacoes (todas no WORKSPACE_BGETRAB_DEV, owner BGETRAB_OAC):

| App ID | Nome da aplicacao | Alias | Paginas | Ultima atualizacao |
|--------|-------------------|-------|---------|--------------------|
| 100 | BGETRAB_teste | BGETRAB-TESTE | 6 | 2026-04-16 |
| 101 | PAINEL PUBLICO RAIS | PAINEL-PUBLICO-RAIS101 | 16 | 2026-09-16 |
| 102 | BGETRAB_teste (Working Copy: BGETRAB) | BGETRAB-TESTE102 | 6 | 2026-04-16 |
| 103 | PAINEL PUBLICO RAIS | PAINEL-PUBLICO-RAIS | 9 | 2026-10-16 |
| 104 | BGCAGED Legado | BGCAGED-LEGADO | 3 | 2026-09-17 |

Observacoes:
  - 101 e 103 tem o mesmo nome (PAINEL PUBLICO RAIS); 103 e mais recente (16/10, 9 paginas),
    101 e de 16/09 (16 paginas) - provavel versao nova vs antiga (confirmar com o usuario).
  - 102 e "Working Copy" (copia de trabalho) da 100 (BGETRAB_teste).
  - 104 (BGCAGED Legado) e a mais relacionada ao CAGED tratado neste projeto.

Nota de leitura: o export CSV do SQL Commands do APEX vem em Windows-1252 (nao UTF-8). Ler com
encoding 1252; se a exibicao truncar apos acentos, normalizar e reler via arquivo UTF-8.
(Na 1a leitura eu exibi so 1 app por truncamento de exibicao; o arquivo sempre teve as 5.)

## Consultas de mapeamento (rodar no SQL Workshop / Database Actions)

-- Workspaces visiveis:
    SELECT workspace, workspace_id
    FROM   apex_workspaces
    ORDER  BY workspace;

-- Aplicacoes (por workspace):
    SELECT workspace, application_id, application_name, alias,
           pages, last_updated_on, owner
    FROM   apex_applications
    ORDER  BY workspace, application_id;

-- Schemas associados a cada workspace:
    SELECT workspace_name, schema
    FROM   apex_workspace_schemas
    ORDER  BY workspace_name, schema;

Observacao: dependendo da versao/privilegios, algumas views APEX_* exigem estar no workspace
correto ou papel de admin do workspace. Se alguma retornar vazio/sem permissao, registrar aqui.

## Paginas por aplicacao

Coletado em 2026-10-21 (apex_application_pages). 40 paginas no total.

### App 100 - BGETRAB_teste (teste/prototipo)
  1 Home | 2 Relatorio BGETRAB | 3 Dashboard | 4 Grade Interativa | (0 Global, 9999 Login)

### App 101 - PAINEL PUBLICO RAIS (versao de desenvolvimento - tem paginas de teste e chat)
  1 Pagina Inicial | 2 Consulta Estabelecimentos | 3 Visao dos Vinculos |
  4 Teste - Visao dos Vinculos | 5 Consulta Vinculos | 6 Visao Geral |
  7 Visao das Remuneracoes | 8 Indice de Gini | 9 Teste - Consulta Vinculos |
  11 Chat (Modal Dialog) | 99 Chat 02 | 103 Visao dos Vinculos - MV |
  106 Visao Geral - MV | 107 Visao das Remuneracoes - MV | (0 Global, 9999 Login)

### App 102 - BGETRAB_teste (Working Copy) - identica a 100
  1 Home | 2 Relatorio BGETRAB | 3 Dashboard | 4 Grade Interativa | (0 Global, 9999 Login)

### App 103 - PAINEL PUBLICO RAIS (versao mais recente/enxuta - sem teste/chat)
  1 Pagina Inicial | 2 Consulta Estabelecimentos | 5 Consulta Vinculos | 8 Indice de Gini |
  103 Visao dos Vinculos - MV | 106 Visao Geral - MV | 107 Visao das Remuneracoes - MV |
  (0 Global, 9999 Login)

### App 104 - BGCAGED Legado (foco CAGED)
  2 Trabalhador Ajustado | (0 Global, 9999 Login)

Analise:
  - 101 (dev) vs 103 (mais recente/limpa): 103 e a versao enxuta do PAINEL PUBLICO RAIS, sem as
    paginas "Teste -" e Chat. As paginas "- MV" (103/106/107) sugerem uso de Materialized Views.
  - 102 e copia de trabalho da 100.
  - 104 "Trabalhador Ajustado" e a provavel consumidora de V1_FATOS_CAGED_TRABS_AJUSTADO
    (relevante para validar o impacto do truncamento DT_COMPETENCIA_MOVIMENTACAO no front).
  - A confirmar com fontes de dados (apex_application_page_regions) quais tabelas/views cada app usa.


## Regioes / fontes de dados por aplicacao

Coletado em 2026-10-21 (apex_application_page_regions). 184 regioes. As fontes de DADOS sao as
regioes com query_type = SQL Query (ou Table); as Static Content/Header/Breadcrumb sao layout.
Esta consulta NAO traz o SQL em si (quais tabelas/views) - so o tipo. Para os objetos exatos,
coletar region_source (proximo passo).

Resumo por app:
  - 100 / 102 (BGETRAB_teste e Working Copy): protótipos. Dados: IR "Relatorio BGETRAB" (SQL Query),
    4 Charts (Dashboard), 1 Interactive Grid (Table).
  - 101 PAINEL PUBLICO RAIS (dev): a mais rica. Muitas regioes SQL Query: "Painel Estabelecimentos" (IR),
    "Painel Vinculos" (IR), dashboards kpi/cardsloop/linhas (SQL Query), bloco Indice de Gini
    (DETALHAMENTO POR MUNICIPIO, GINI POR SEXO, Menores/Maiores Desigualdades), versoes "- MV".
  - 103 PAINEL PUBLICO RAIS (limpa/recente): mesma estrutura enxuta - Painel Estabelecimentos,
    Painel Vinculos, bloco Gini, e "- MV" (103/106/107).
  - 104 BGCAGED Legado: UMA regiao de dados -> "Painel Trabalhador Ajustado" (Interactive Report, SQL Query).

DESTAQUE p/ o projeto (CAGED): o painel RAIS (101/103) trata RAIS/vinculos. Quem consome o CAGED/
fato ajustado e a app 104 (BGCAGED Legado), regiao "Painel Trabalhador Ajustado". E a candidata a
usar V1_FATOS_CAGED_TRABS_AJUSTADO -> alvo para validar o impacto do truncamento DT_COMPETENCIA_MOVIMENTACAO.

Proximo passo sugerido: coletar region_source (SQL) das regioes SQL Query para mapear as tabelas/views
reais - prioridade para a regiao "Painel Trabalhador Ajustado" (app 104).


## App 104 (BGCAGED Legado) - regiao "Painel Trabalhador Ajustado" (pg 2)

Coletado em 2026-10-21 (region_source, truncado em 1000 chars). Interactive Report, SQL Query.

CONFIRMADO: esta regiao consome o fato CAGED e EXPOE DT_COMPETENCIA_MOVIMENTACAO ao usuario final.
Inicio do SQL:
  select to_char(DT_COMPETENCIA) as DT_COMPETENCIA,
         DT_COMPETENCIA_MOVIMENTACAO as DT_COMPETENCIA_MOVIMENTACAO,
         CS_TIPO_ACERTO, CS_TIPO_DOC_IDENT_ESTAB, DT_ADMISSAO, IN_APRENDIZ, IN_DEFICIENCIA,
         IN_FORA_PRAZO, IN_INFORMADO_COMPETENCIA, IN_VERSAO_CNAE, NU_DOC_IDENT_ESTAB,
         NU_TEMPO_EMPREGO, QT_HORAS_CONTRATUAIS_SEMANA, NU_COD_ETNIA, NM_ETNIA,
         NU_COD_TAMANHO_EMPRESA, NM_TAMANHO_EMPRESA, ID_ATIV_ECO, TE_ATIV_ECO,
         V1_MV_DW_CBO_94.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO_94,
         V1_MV_DW_CBO_94.NM_OCUPACAO as NM_OCUPACAO_94,
         V1_MV_DW_CBO.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO, V1_... (cortado em 1000 chars)

Observacoes:
  - Usa Materialized Views: V1_MV_DW_CBO_94 e V1_MV_DW_CBO (CBO/ocupacoes). Prefixo V1_MV_* = MV.
  - A tabela-base do fato (provavel V1_FATOS_CAGED_TRABS_AJUSTADO) deve estar no FROM apos os
    1000 chars - coletar o SQL completo para confirmar FROM/JOINs/WHERE.

IMPACTO (ligacao com o truncamento): como a regiao mostra DT_COMPETENCIA_MOVIMENTACAO direto, os
anos afetados nao recarregados (1996,2000,2001,2002,2003,2011) aparecem com competencia de
movimentacao TRUNCADA nesta tela ate a recarga corrigida.

SQL COMPLETO (3728 chars, coletado integro em 2026-10-21):

```sql
select to_char(DT_COMPETENCIA) as DT_COMPETENCIA,
    DT_COMPETENCIA_MOVIMENTACAO as DT_COMPETENCIA_MOVIMENTACAO,
    CS_TIPO_ACERTO, CS_TIPO_DOC_IDENT_ESTAB, DT_ADMISSAO, IN_APRENDIZ, IN_DEFICIENCIA,
    IN_FORA_PRAZO, IN_INFORMADO_COMPETENCIA, IN_VERSAO_CNAE, NU_DOC_IDENT_ESTAB,
    NU_TEMPO_EMPREGO, QT_HORAS_CONTRATUAIS_SEMANA, NU_COD_ETNIA, NM_ETNIA,
    NU_COD_TAMANHO_EMPRESA, NM_TAMANHO_EMPRESA, ID_ATIV_ECO, TE_ATIV_ECO,
    V1_MV_DW_CBO_94.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO_94, V1_MV_DW_CBO_94.NM_OCUPACAO as NM_OCUPACAO_94,
    V1_MV_DW_CBO.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO, V1_MV_DW_CBO.NM_OCUPACAO as NM_OCUPACAO,
    NU_MUNI_IBGE, NM_MUNI, NU_COD_ESCOLARIDADE, NM_ESCOLARIDADE, NU_TIPO_ESTAB, NM_TIPO_ESTAB,
    ID_CNAE_2_0, TE_CNAE_2_0, CS_SEXO, NM_SEXO, NU_SUBATIV_CNAE_80, TE_SUBATIV_CNAE_80,
    NU_TIPO_DEFICIENCIA, NM_DEFICIENCIA, NU_FAIXA_TEMPO_EMPREGO, NM_FAIXA_TEMPO_EMPREGO,
    ID_TIPO_MOVIMENTACAO, IN_TRAB_INTERMITENTE, IN_TRAB_PARCIAL, IN_TRAB_TELETRABALHO
 from V1_DIM_FAIXAS_TEMPO_EMPREGO, V1_DIM_TIPOS_DEFICIENCIA, V1_DIM_CNAE_80,
    V1_MV_DW_SEXOS, V1_MV_DW_CNAE_2_0, V1_DW_TIPOS_ESTAB_MTE, V1_DW_ESCOLARIDADE_MTE,
    V1_MV_DW_LOCALIZACOES_GEOGRAFICAS, V1_MV_DW_CBO, V1_MV_DW_CBO_94, V1_MV_DW_CNAE_2003,
    V1_DW_TAMANHO_EMPRESAS_MTE, V1_DW_ETNIAS_MTE, V1_FATOS_CAGED_TRABS_AJUSTADO
 where <joins fato->dimensao por ID_SEQ_* / ID_* (etnia, tamanho_empresa, cnae_2003, cbo_94,
       cbo, geografica, escolaridade, tipo_estab, cnae_2_0, sexo, cnae_80, tipo_deficiencia,
       faixa_tempo_emprego)>
```

DEPENDENCIAS (star schema; 1 fato + 13 dimensoes/MVs):
  - Fato     : V1_FATOS_CAGED_TRABS_AJUSTADO (expoe DT_COMPETENCIA_MOVIMENTACAO cru, 1a coluna)
  - MVs      : V1_MV_DW_CBO, V1_MV_DW_CBO_94, V1_MV_DW_CNAE_2003, V1_MV_DW_CNAE_2_0,
               V1_MV_DW_SEXOS, V1_MV_DW_LOCALIZACOES_GEOGRAFICAS
  - DIM      : V1_DIM_FAIXAS_TEMPO_EMPREGO, V1_DIM_TIPOS_DEFICIENCIA, V1_DIM_CNAE_80
  - DW       : V1_DW_TIPOS_ESTAB_MTE, V1_DW_ESCOLARIDADE_MTE, V1_DW_TAMANHO_EMPRESAS_MTE, V1_DW_ETNIAS_MTE

Notas:
  - JOINs INNER (sintaxe antiga com virgula no FROM + WHERE): se uma chave ID_SEQ_* do fato nao
    casar na dimensao, a linha some do relatorio.
  - DT_COMPETENCIA sai com to_char; DT_COMPETENCIA_MOVIMENTACAO sai crua (numerica) -> o
    truncamento fica visivel nesta tela ate a recarga dos anos afetados.

IMPACTO: enquanto os anos afetados (1996,2000,2001,2002,2003,2011) nao forem recarregados
corrigidos, esta tela mostra DT_COMPETENCIA_MOVIMENTACAO truncada.

## Regioes / fontes de dados por aplicacao

Coletado em 2026-10-21 (apex_application_page_regions). 184 regioes. As fontes de DADOS sao as
regioes com query_type = SQL Query (ou Table); as Static Content/Header/Breadcrumb sao layout.
Esta consulta NAO traz o SQL em si (quais tabelas/views) - so o tipo. Para os objetos exatos,
coletar region_source (proximo passo).

Resumo por app:
  - 100 / 102 (BGETRAB_teste e Working Copy): protótipos. Dados: IR "Relatorio BGETRAB" (SQL Query),
    4 Charts (Dashboard), 1 Interactive Grid (Table).
  - 101 PAINEL PUBLICO RAIS (dev): a mais rica. Muitas regioes SQL Query: "Painel Estabelecimentos" (IR),
    "Painel Vinculos" (IR), dashboards kpi/cardsloop/linhas (SQL Query), bloco Indice de Gini
    (DETALHAMENTO POR MUNICIPIO, GINI POR SEXO, Menores/Maiores Desigualdades), versoes "- MV".
  - 103 PAINEL PUBLICO RAIS (limpa/recente): mesma estrutura enxuta - Painel Estabelecimentos,
    Painel Vinculos, bloco Gini, e "- MV" (103/106/107).
  - 104 BGCAGED Legado: UMA regiao de dados -> "Painel Trabalhador Ajustado" (Interactive Report, SQL Query).

DESTAQUE p/ o projeto (CAGED): o painel RAIS (101/103) trata RAIS/vinculos. Quem consome o CAGED/
fato ajustado e a app 104 (BGCAGED Legado), regiao "Painel Trabalhador Ajustado". E a candidata a
usar V1_FATOS_CAGED_TRABS_AJUSTADO -> alvo para validar o impacto do truncamento DT_COMPETENCIA_MOVIMENTACAO.

Proximo passo sugerido: coletar region_source (SQL) das regioes SQL Query para mapear as tabelas/views
reais - prioridade para a regiao "Painel Trabalhador Ajustado" (app 104).


## App 104 (BGCAGED Legado) - regiao "Painel Trabalhador Ajustado" (pg 2)

Coletado em 2026-10-21 (region_source, truncado em 1000 chars). Interactive Report, SQL Query.

CONFIRMADO: esta regiao consome o fato CAGED e EXPOE DT_COMPETENCIA_MOVIMENTACAO ao usuario final.
Inicio do SQL:
  select to_char(DT_COMPETENCIA) as DT_COMPETENCIA,
         DT_COMPETENCIA_MOVIMENTACAO as DT_COMPETENCIA_MOVIMENTACAO,
         CS_TIPO_ACERTO, CS_TIPO_DOC_IDENT_ESTAB, DT_ADMISSAO, IN_APRENDIZ, IN_DEFICIENCIA,
         IN_FORA_PRAZO, IN_INFORMADO_COMPETENCIA, IN_VERSAO_CNAE, NU_DOC_IDENT_ESTAB,
         NU_TEMPO_EMPREGO, QT_HORAS_CONTRATUAIS_SEMANA, NU_COD_ETNIA, NM_ETNIA,
         NU_COD_TAMANHO_EMPRESA, NM_TAMANHO_EMPRESA, ID_ATIV_ECO, TE_ATIV_ECO,
         V1_MV_DW_CBO_94.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO_94,
         V1_MV_DW_CBO_94.NM_OCUPACAO as NM_OCUPACAO_94,
         V1_MV_DW_CBO.NU_CODIGO_OCUPACAO as NU_CODIGO_OCUPACAO, V1_... (cortado em 1000 chars)

Observacoes:
  - Usa Materialized Views: V1_MV_DW_CBO_94 e V1_MV_DW_CBO (CBO/ocupacoes). Prefixo V1_MV_* = MV.
  - A tabela-base do fato (provavel V1_FATOS_CAGED_TRABS_AJUSTADO) deve estar no FROM apos os
    1000 chars - coletar o SQL completo para confirmar FROM/JOINs/WHERE.

IMPACTO (ligacao com o truncamento): como a regiao mostra DT_COMPETENCIA_MOVIMENTACAO direto, os
anos afetados nao recarregados (1996,2000,2001,2002,2003,2011) aparecem com competencia de
movimentacao TRUNCADA nesta tela ate a recarga corrigida.

Para o SQL completo: no APEX, abrir a regiao (App 104 > Pagina 2 > Painel Trabalhador Ajustado)
e copiar o SQL do atributo Source; ou SELECT region_source sem SUBSTR (pode exceder o limite da
coluna no export - preferir copiar direto do Designer).


## Apps RAIS (101 e 103) - dependencias de dados

Coletado em 2026-10-21 (region_source das regioes SQL Query, apps 101 e 103). 34 regioes com SQL.
As apps RAIS usam objetos RAIS - NENHUMA referencia a V1_* (CAGED). Confirma separacao total do
CAGED: o truncamento de DT_COMPETENCIA_MOVIMENTACAO NAO afeta o painel RAIS (so a app 104).

Objetos usados (FROM/JOIN):
  Fatos RAIS:
    - FT_RAIS_DECLARACOES_ANUARIO (estabelecimentos/declaracoes)
    - FT_RAIS_VINCULOS_ANUARIO (vinculos)
    - TAB_RAIS_VINCULOS_ANALITICA (analitica de vinculos)
    - FT_INDICE_GINI + TP_FT_INDICE_GINI_SEXO (indice de Gini)
  Dimensoes (DI_*/DW_*):
    - DI_CNAE_80, DI_FLAGS_RAIS_ESTAB, DI_FLAGS_RAIS_ESTAB_DECLARACAO, DI_NATUREZA_JURIDICA,
      DI_REGIAO_GEOGRAFICA, DI_TAMANHO_EMPRESAS_MTE, DI_TIPOS_ESTAB_MTE, DW_CNAE_2_0
  Materialized views (paginas "- MV" 106/107):
    - MV_VISAO_GERAL, MV_REMUNERACOES
  Outros: GINI_BRASIL, salarios (view/alias), DUAL, PARAM (ruido de parsing/aliases).

Mapa por regiao (resumo):
  - pg2 Painel Estabelecimentos -> FT_RAIS_DECLARACOES_ANUARIO + varias DI_*/DW_CNAE_2_0
  - pg5 Painel Vinculos -> TAB_RAIS_VINCULOS_ANALITICA
  - pg6 (101) / dashboards -> FT_RAIS_DECLARACOES_ANUARIO, FT_RAIS_VINCULOS_ANUARIO, DI_REGIAO_GEOGRAFICA
  - pg7 remuneracoes -> TAB_RAIS_VINCULOS_ANALITICA, FT_RAIS_VINCULOS_ANUARIO, salarios
  - pg8 Indice de Gini -> FT_INDICE_GINI, TP_FT_INDICE_GINI_SEXO, GINI_BRASIL
  - pg106 "Visao Geral - MV" -> MV_VISAO_GERAL (+ FT_RAIS_VINCULOS_ANUARIO)
  - pg107 "Remuneracoes - MV" -> MV_REMUNERACOES (+ FT_RAIS_VINCULOS_ANUARIO)

101 vs 103: dependencias de dados praticamente identicas; 101 tem apenas regioes a mais
(paginas de teste e chat, sem SQL de dados relevante). 103 = versao enxuta/oficial da 101.


## Procedimentos / notas

(A preencher conforme o uso: SQLs uteis, processos, objetos de banco por app, correcoes.)
