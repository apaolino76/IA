# Acoes para Admin IAM e DBA - Migracao do chatbot para Resource Principal (BGETRAB/RAIS)

Documento para encaminhar aos responsaveis. Objetivo: trocar a autenticacao do chatbot
APEX + Select AI de "usuario OCI + chave pessoal" para **Resource Principal** (identidade
do proprio Autonomous Database). Isso remove a dependencia da chave de um usuario especifico
e e parte da solucao do problema "o chatbot so funciona para o login que o configurou".

Roteiro tecnico completo: `migracao-resource-principal.md`. Estado atual: `apex-select-ai.md`.

Data: 2026-10-22

---

## Valores ja confirmados (nao precisam ser levantados de novo)

| Item | Valor |
|---|---|
| Ambiente | ADW DA_ADW_BGETRAB_PROD (DB_NAME interno G572CE7AB0E1422_ADWNDEVBGETRAB) |
| Versao do banco | Oracle AI Database **26ai** (release 23.26.4.1.0) |
| Regiao | sa-saopaulo-1 |
| Parsing schema / Schema executor / Dono da package | **BGETRAB_OAC** (os tres sao o mesmo schema) |
| Package | PKG_SELECT_AI_V2 (AUTHID DEFINER) |
| Profile Select AI | **DATAPREV_BGETRAB** |
| Credencial atual do profile (a substituir) | **DATAPREV_GENAI_BGETRAB** (aponta para um usuario OCI pessoal) |
| Modelo / Provider | cohere.command-a-03-2025 / oci |
| Compartment do profile (SELECTAI_GENAI_COMPARTMENT) | RITM0117727_BGETRAB_DEV = ocid1.compartment.oc1..aaaaaaaarf5sfuq35slcn3nmbueowcfolzv53wrtnakif4573kemlupovpha |
| Generative AI Service (APEX) | dev_DITM_BGETRAB_DEV (Static ID dev_ditm_bgetrab_dev); Base URL inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com |
| Web Credential atual do servico (a substituir) | credentials_for_dev_bgetrab_generative_ai |
| Compartment do servico APEX | O MESMO do profile (ocid1.compartment.oc1..aaaa...povpha) -> politica IAM precisa de UM unico compartment |

---

## Pendencias que dependem de voces

### Para o DBA / admin do banco

1. **ADB_OCID** - o usuario da app (BGETRAB_OAC) nao consegue obter (sem privilegio em
   v$pdbs/v$containers; e `oci db autonomous-database` esta bloqueado por inspecao TLS
   no ambiente). Favor fornecer o OCID do Autonomous DA_ADW_BGETRAB_PROD, via:

   ```sql
   SELECT cloud_identity FROM v$pdbs;   -- o JSON traz DATABASE_OCID
   ```
   ou copiar da console OCI (Autonomous Database -> OCID).

2. **Habilitar Resource Principal** (ADMIN do banco). Como parsing schema, schema executor
   e dono da package sao todos BGETRAB_OAC, basta:

   ```sql
   BEGIN DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(); END;
   /
   BEGIN DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'BGETRAB_OAC'); END;
   /
   ```
   Se vier "resource principal is already enabled", conferir grants e seguir (nao
   desabilitar/reabilitar uma identidade possivelmente usada por outras apps).

3. **Conferir/criar sinonimo** (26ai permite). So se nao houver credencial local nem sinonimo:

   ```sql
   SELECT owner, object_name FROM dba_objects
   WHERE owner='BGETRAB_OAC' AND object_name='OCI$RESOURCE_PRINCIPAL';

   SELECT owner, synonym_name FROM dba_synonyms
   WHERE owner IN ('BGETRAB_OAC','PUBLIC') AND synonym_name='OCI$RESOURCE_PRINCIPAL';

   -- se nenhum existir:
   CREATE SYNONYM BGETRAB_OAC.OCI$RESOURCE_PRINCIPAL FOR ADMIN.OCI$RESOURCE_PRINCIPAL;
   ```

### Para o admin IAM

4. **Dynamic Group** (OCI -> Identity -> Domains -> [dominio] -> Dynamic Groups -> Create):
   - Name: `dg-rais-adb-genai` (sugerido)
   - Matching rule: `resource.id = '<ADB_OCID>'`  (usar o OCID do item 1; so este banco)

5. **Politica IAM** (OCI -> Identity -> Policies -> Create):
   ```text
   Allow dynamic-group '<DOMINIO>/dg-rais-adb-genai' to use generative-ai-chat in compartment id ocid1.compartment.oc1..aaaaaaaarf5sfuq35slcn3nmbueowcfolzv53wrtnakif4573kemlupovpha
   ```
   Como o Generative AI Service do APEX (dev_DITM_BGETRAB_DEV) usa o MESMO compartment do
   profile, basta esta UNICA linha. Autoriza a API Chat.

6. **IAM_DOMAIN** - informar o nome do dominio de identidade usado (provavel `Default`).

---

## O que sera feito do lado APEX (dev, apos 1-6 prontos)

7. Criar Web Credential de Resource Principal (OCI Native Authentication + Use Database
   Credential = OCI$RESOURCE_PRINCIPAL, scope Schema).
8. Trocar `credential_name` do profile DATAPREV_BGETRAB para `OCI$RESOURCE_PRINCIPAL` (reversivel).
9. No servico dev_DITM_BGETRAB_DEV, trocar a Credential de
   `credentials_for_dev_bgetrab_generative_ai` para a nova Web Credential RP; Test Connection.
10. Testar: GENERATE direto, chatbot com login proprio e **com OUTRO login** (valida o objetivo).

Rollback disponivel: voltar o profile para DATAPREV_GENAI_BGETRAB e a Web Credential
para credentials_for_dev_bgetrab_generative_ai. Manter a chave pessoal atual valida ate o aceite.

---

## Dados do Generative AI Service (coletados 2026-10-22)

- Name: dev_DITM_BGETRAB_DEV | Static ID: dev_ditm_bgetrab_dev
- Compartment: ocid1.compartment.oc1..aaaa...povpha (= DEV, mesmo do profile)
- Region: sa-saopaulo-1 | Model: cohere.command-a-03-2025
- Base URL: https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com
- Credential atual: credentials_for_dev_bgetrab_generative_ai
- "Used by App Builder": OFF (a app referencia o servico pelo Static ID)
- Compartilhamento do profile DATAPREV_BGETRAB: 5 apps compartilham o parsing schema
  BGETRAB_OAC (100 BGETRAB_teste, 101/103 PAINEL PUBLICO RAIS, 102 Working Copy,
  104 BGCAGED Legado). A troca do credential_name do profile afeta TODAS (desejado).
  Confirmar ainda, por export das apps, QUAIS de fato invocam o servico GenAI
  dev_DITM_BGETRAB_DEV / a Web Credential (uso real, nao apenas acesso potencial).
