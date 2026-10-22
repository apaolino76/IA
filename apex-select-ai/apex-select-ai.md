# APEX + Select AI - Chatbot de IA (BGETRAB / RAIS)

Documento de contexto e ESTADO ATUAL do chatbot de IA construido sobre os paineis
APEX do projeto BGETRAB/RAIS. Mantido pelo copiloto (agente apex-select-ai) a partir
do que o usuario fornece. O copiloto NAO acessa o APEX diretamente (acesso web via
tunel de Bastion); ele gera SQL/PLSQL, descreve as telas e documenta aqui.

Ultima atualizacao: 2026-10-22 (copia do script de tunel/bastion para este projeto)

> Relacao com o bgetrab-agente: a infraestrutura OCI e o mapeamento dos paineis APEX
> estao documentados em ../bgetrab-agente (oci-bgetrab.md e apex-bgetrab.md). Este
> projeto foca especificamente na camada de IA: Select AI, OCI Generative AI, Web
> Credentials, Generative AI Service e o AI Agent (chatbot).

---

## 1. Objetivos

1. **Migracao para Resource Principal** - trocar a autenticacao do chatbot (hoje
   atrelada a um usuario OCI + chave) para a identidade do Autonomous Database
   (Resource Principal). Roteiro detalhado: `migracao-resource-principal.md`.

2. **Copiloto amplo (criar/evoluir o chatbot)** - ajudar a criar e evoluir o chatbot
   sobre os paineis APEX e, em especial, resolver o problema do **"chatbot funcional
   para qualquer login"**: hoje o chatbot so funciona quando o usuario que o
   configurou/associou faz login no APEX. Roteiro detalhado: `copiloto-chatbot.md`.

---

## 2. Como os dois .md da raiz se encaixam

Na raiz `C:\projetos\IA` existem dois arquivos de orientacao da Dataprev:

| Arquivo | Conteudo | Papel aqui |
|---|---|---|
| `Dataprev_Orientacao_Resource_Principal_APEX_Select_AI_v7.md` | Roteiro completo (9 etapas) de migracao para Resource Principal | Fonte base do `migracao-resource-principal.md` |
| `Dataprev_Orientacao_Resource_Principal_APEX_Select_AI_resumido.md` | Versao resumida (7 secoes) do mesmo roteiro | Checklist rapido da migracao |

Esses documentos assumem que o chatbot (AI Agent + Generative AI Service + profile
Select AI + package PL/SQL) **ja existe e funciona** com credenciais de um usuario OCI.
Eles cobrem apenas a TROCA de autenticacao, nao a criacao do chatbot.

A referencia de codigo citada por eles e a package **`PKG_SELECT_AI_V2.sql` (02/07/2026)**,
com `AUTHID CURRENT_USER` e parametro `p_profile_name`. O schema de instalacao e os
nomes efetivos devem ser confirmados no ambiente.

---

## 3. Ambiente (confirmado no bgetrab-agente)

| Item | Valor |
|---|---|
| ADW (data asset) | DA_ADW_BGETRAB_PROD |
| Versao APEX | 26.2 (confirmar versao exata do Autonomous) |
| Schema principal | BGETRAB_OAC |
| Regiao / Namespace | sa-saopaulo-1 / grmu0oy5wsd9 |
| Workspace APEX | WORKSPACE_BGETRAB_DEV (ID 9211902498453592) |
| Acesso APEX | https://localhost/ords/_/landing (tunel bastion, porta local 443) |

> Acesso automatizado ao tunel: `scripts\apex_tunnel.ps1` (copiado de
> ../bgetrab-agente/scripts em 2026-10-22). Valida a sessao OCI (perfil
> `bgetrab-session`), reutiliza/cria a sessao de Bastion (port-forwarding
> 443 -> 10.217.48.81:443) e abre o navegador no APEX. O login no APEX
> permanece MANUAL. Uso: `powershell -ExecutionPolicy Bypass -File .\scripts\apex_tunnel.ps1`
> (chave SSH via -PrivKey, env BGETRAB_SSH_PRIV_KEY ou autodescoberta em %USERPROFILE%\.ssh).

### Aplicacoes relevantes para o chatbot

| App ID | Nome | Observacao |
|---|---|---|
| 101 | PAINEL PUBLICO RAIS (dev) | Versao de desenvolvimento. Tem as paginas **11 "Chat (Modal Dialog)"** e **99 "Chat 02"** - onde vive o chatbot/prototipo. |
| 103 | PAINEL PUBLICO RAIS (enxuta) | Versao mais recente/limpa, SEM as paginas de teste/chat. |

As apps RAIS (101/103) consomem objetos RAIS: FT_RAIS_DECLARACOES_ANUARIO,
FT_RAIS_VINCULOS_ANUARIO, TAB_RAIS_VINCULOS_ANALITICA, FT_INDICE_GINI, varias DI_*/DW_*,
MV_VISAO_GERAL, MV_REMUNERACOES. (Detalhe completo em ../bgetrab-agente/apex-bgetrab.md.)
Esses sao os objetos que o Select AI precisa "conhecer" para responder perguntas sobre dados.

---

## 4. Componentes do chatbot (a confirmar no ambiente)

O chatbot APEX + Select AI tem tipicamente estas pecas. Preencher a coluna "Valor no
ambiente" conforme o usuario coletar (ver consultas na secao 6).

| Componente | O que e | Valor no ambiente |
|---|---|---|
| Parsing Schema | Schema de execucao da app APEX | **BGETRAB_OAC** (confirmado 2026-10-22 via SYS_CONTEXT: CURRENT_USER=CURRENT_SCHEMA=BGETRAB_OAC; SESSION_USER=ORDS_PLSQL_GATEWAY) |
| Schema executor do Select AI | Schema que roda o profile/DBMS_CLOUD_AI | **BGETRAB_OAC** (confirmado 2026-10-22) |
| Proprietario da package | Dono de PKG_SELECT_AI_V2 (se instalada) | **BGETRAB_OAC** (confirmado 2026-10-22; AUTHID=DEFINER) |
| Profile Select AI | Profile DBMS_CLOUD_AI usado (`provider=oci`) | **DATAPREV_BGETRAB** (confirmado 2026-10-22; unico profile visivel ao schema BGETRAB_OAC) |
| credential_name (atual) | Credencial usada hoje pelo profile | **DATAPREV_GENAI_BGETRAB** (confirmado 2026-10-22; alvo da migracao p/ Resource Principal) |
| Web Credential (APEX) | Credencial do Generative AI Service | **credentials_for_dev_bgetrab_generative_ai** (confirmado 2026-10-22; a substituir na migracao) |
| Generative AI Service | Servico APEX usado pelo AI Agent | **dev_DITM_BGETRAB_DEV** (Static ID dev_ditm_bgetrab_dev; Base URL https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com; "Used by App Builder"=OFF) |
| AI Model / Region / Endpoint | Modelo OCI GenAI, regiao, endpoint | **model=cohere.command-a-03-2025 / region=sa-saopaulo-1 / provider=oci / Base URL=inference.generativeai.sa-saopaulo-1** |
| AI Agent | O agente do chatbot (aponta pro servico) | *a confirmar* |

---

## 5. O problema "chatbot so funciona para o login configurado"

Sintoma relatado: o chatbot responde apenas quando o usuario que o configurou faz
login no APEX. Para outros logins, ele falha.

Hipoteses a investigar (detalhadas em `copiloto-chatbot.md`):
1. A **Web Credential / credencial OCI** esta atrelada a um usuario especifico, e as
   permissoes OCI (politica IAM) so valem para aquele usuario. -> A migracao para
   **Resource Principal** resolve isso, pois a identidade passa a ser o banco, nao a pessoa.
2. O **profile Select AI** pertence a um schema especifico e os demais logins APEX
   executam com outro parsing schema sem grant no profile/credencial.
3. Autorizacao da **pagina/componente Chat** no APEX restrita a um usuario ou grupo.
4. A credencial de banco usada pelo profile foi criada no schema de um usuario e nao
   e resolvida no contexto dos demais.

### Status do diagnostico (atualizado 2026-10-22)
- Hipotese 2: ENFRAQUECIDA/DESCARTADA. Parsing schema e BGETRAB_OAC para as apps 101 e 103
  (nao varia por login). Profile unico DATAPREV_BGETRAB visivel nesse schema.
- Hipoteses 1 e 4: CONFIRMADA a dependencia de identidade pessoal. A credencial de banco
  DATAPREV_GENAI_BGETRAB (usada pelo profile) autentica como um USUARIO OCI PESSOAL
  (ocid1.user.oc1..***). A migracao para Resource Principal remove esse acoplamento.
- Hipotese 3: A VERIFICAR (autorizacao das paginas Chat 11/99 da app 101).
- A VERIFICAR tambem: a Web Credential do Generative AI Service / AI Agent no APEX (camada
  do AI Agent, distinta do profile DBMS_CLOUD_AI) e a validade da chave de API do usuario OCI.

> Observacao importante: a migracao para Resource Principal (objetivo 1) e, muito
> provavelmente, parte da SOLUCAO do objetivo 2 - ao deixar de depender da chave
> pessoal de um usuario OCI, a autenticacao deixa de ser "de um login".

---

## 6. Consultas de levantamento (rodar no SQL Workshop / Database Actions)

O usuario executa no APEX (via tunel) e cola os resultados aqui para documentarmos.

```sql
-- Contexto de execucao atual
SELECT SYS_CONTEXT('USERENV','SESSION_USER')   AS session_user,
       SYS_CONTEXT('USERENV','CURRENT_USER')   AS current_user,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS current_schema
FROM dual;

-- Profiles Select AI visiveis ao schema conectado
SELECT profile_name
FROM   user_cloud_ai_profiles
ORDER  BY profile_name;

-- Atributos de um profile (trocar :p pelo nome real)
SELECT profile_name, attribute_name, attribute_value
FROM   user_cloud_ai_profile_attributes
WHERE  profile_name = :p
ORDER  BY attribute_name;

-- Credenciais de banco disponiveis
SELECT owner, credential_name
FROM   dba_credentials
ORDER  BY owner, credential_name;
```

(Para confirmar a package PKG_SELECT_AI_V2 e os schemas, ver as consultas da etapa 1
do migracao-resource-principal.md.)

---

## 7. Historico / descobertas

(A preencher conforme o uso: valores confirmados do ambiente, resultados de testes,
decisoes tomadas, correcoes. Cada entrada com data.)

- 2026-10-22: criacao da pasta apex-select-ai e dos documentos iniciais.
- 2026-10-22: copiado `scripts\apex_tunnel.ps1` de ../bgetrab-agente/scripts para este
  projeto; agora o tunel de Bastion + abertura do APEX pode ser disparado daqui. Script
  autocontido (OCIDs/IP fixos no proprio arquivo; chaves SSH via parametro/env/~/.ssh).
- 2026-10-22: diagnosticado "Permission denied (publickey)" na 1a execucao como corrida de
  timing (par de chaves e sessao de Bastion conferidos e corretos; o SSH disparou antes do
  endpoint estabilizar). Melhorado o `apex_tunnel.ps1`: espera de 15s apos a sessao ficar
  ACTIVE e retry automatico do SSH (ate 5x) com deteccao da porta local 443; o navegador so
  abre quando o tunel sobe. Sintaxe validada.
- 2026-10-22: Passo 1 do levantamento (report (10).csv): SESSION_USER=ORDS_PLSQL_GATEWAY,
  CURRENT_USER=BGETRAB_OAC, CURRENT_SCHEMA=BGETRAB_OAC. Schema efetivo de execucao =
  BGETRAB_OAC. Falta confirmar o parsing schema oficial das apps 101/103 (consulta
  apex_applications) e o profile/credential_name (Passos 2 e 3).
- 2026-10-22: Passo 1-b (report (11).csv): apps 101 e 103 tem parsing schema = BGETRAB_OAC
  (ambas). Confirma que o parsing schema NAO varia por login APEX -> enfraquece a hipotese 2
  (parsing schemas distintos). Aponta a causa do "so funciona para um login" para a camada
  OCI (Web Credential/credencial atrelada a usuario) ou autorizacao da pagina Chat.
  Nota: o CSV veio em Windows-1252 (acento de "PUBLICO"); ler com encoding 1252, nao UTF-8.
- 2026-10-22: Passo 2 e 3 (report 12 e 13.csv): profile unico = DATAPREV_BGETRAB. Atributos:
  credential_name=DATAPREV_GENAI_BGETRAB, provider=oci, region=sa-saopaulo-1,
  model=cohere.command-a-03-2025, comments=true, constraints=true, case_sensitive_values=false,
  oci_compartment_id=ocid1.compartment.oc1..aaaa...povpha (mascarado).
  ACHADO: object_list tem apenas BGETRAB_OAC.TAB_RAIS_VINCULOS_ANALITICA -> o chatbot so
  "conhece" essa tabela; ampliar o object_list e passo futuro para evoluir o chatbot.
  PROXIMO: verificar para qual usuario OCI a credencial DATAPREV_GENAI_BGETRAB aponta
  (user_credentials/dba_credentials) e a Web Credential do Generative AI Service no APEX.
- 2026-10-22: credencial DATAPREV_GENAI_BGETRAB confirmada como ENABLED=TRUE e com
  USERNAME = OCID de USUARIO OCI PESSOAL (ocid1.user.oc1..***, mascarado). CONCLUSAO: a
  autenticacao do chatbot depende da chave de API de um usuario OCI pessoal. Esta e a
  causa raiz do acoplamento a uma identidade -> a migracao para Resource Principal
  (OCI$RESOURCE_PRINCIPAL) remove esse ponto de falha. A verificar ainda, para o sintoma
  "so funciona para um login": (a) Web Credential do Generative AI Service / AI Agent no
  APEX (pode estar amarrada ao usuario que configurou); (b) autorizacao das paginas Chat
  (11/99 da app 101); (c) validade/revogacao da chave de API do usuario OCID.

- 2026-10-22: Etapa 1 da migracao, Bloco A (report (15).csv): PKG_SELECT_AI_V2 existe,
  OWNER=BGETRAB_OAC, AUTHID=DEFINER (os docs Dataprev assumem CURRENT_USER). Com DEFINER a
  package roda sempre no contexto de BGETRAB_OAC -> profile/credencial resolvidos sempre
  nesse schema (reforca que a execucao e centralizada, nao varia por login). Para a Etapa 4
  basta habilitar Resource Principal para BGETRAB_OAC (e parsing + executor + dono da package).
  PENDENTE da Etapa 1 (telas OCI/APEX): ADB_OCID, DB_VERSION, IAM_DOMAIN, AI_SERVICE_NAME,
  OLD_WEB_CREDENTIAL_NAME, APEX_GENAI_COMPARTMENT_OCID; e confirmar se servico/credencial/
  profile sao compartilhados com outras apps.

- 2026-10-22: DB_VERSION confirmada = Oracle AI Database 26ai EE, release 23.26.4.1.0
  (report (16).csv). Logo, na Etapa 4.2 da migracao e PERMITIDO criar o sinonimo
  BGETRAB_OAC.OCI$RESOURCE_PRINCIPAL -> ADMIN.OCI$RESOURCE_PRINCIPAL (a ressalva "em 19c
  nao criar" nao se aplica). ADB_OCID segue pendente (usuario sem acesso a console OCI;
  obter via DBA/infra ou SQL cloud_identity).

- 2026-10-22: tentativa de obter ADB_OCID por SQL. Primeira consulta (report (17).csv):
  CLOUD_SERVICE=DWCS (Autonomous Data Warehouse), DB_NAME=G572CE7AB0E1422_ADWNDEVBGETRAB
  (sufixo ADWNDEVBGETRAB coerente com ambiente DEV). Falta o cloud_identity (v$pdbs/
  v$containers) para extrair o OCID do banco.

- 2026-10-22: busca do ADB_OCID na pasta ../bgetrab-agente: NAO ha OCID de autonomous
  database documentado (so o nome DA_ADW_BGETRAB_PROD). Descoberto que o oci_compartment_id
  do profile (...rf5sfuq35slcn3nmbueowcfolzv53wrtnakif4573kemlupovpha) corresponde ao
  compartment DEV "RITM0117727_BGETRAB_DEV" (oci-bgetrab.md). Logo o profile aponta para o
  compartment de desenvolvimento, provavelmente onde o ADB e o GenAI residem.
  IMPORTANTE: `oci db autonomous-database list/get` esta BLOQUEADO neste ambiente por
  inspecao TLS (Kaspersky/Zscaler) - nao da para obter o OCID por essa CLI. Vias restantes:
  SQL dba_cloud_identity (a testar) ou pedir ao DBA/infra.

- 2026-10-22: esgotadas as vias de SQL para o ADB_OCID com o usuario da app:
  dba_cloud_identity -> ORA-00942 (sem privilegio); SYS_CONTEXT('USERENV','CLOUD_IDENTITY')
  -> ORA-02003 (atributo invalido). Conclusao: ADB_OCID so via ADMIN do banco
  (SELECT cloud_identity FROM v$pdbs) ou console OCI. Como o OCID so e usado na Etapa 2
  (Dynamic Group, tarefa do admin IAM), NAO trava a migracao - fica delegado ao admin.
  Proximo passo que o usuario consegue fazer: coletar dados do Generative AI Service no
  APEX (AI_SERVICE_NAME, OLD_WEB_CREDENTIAL_NAME, APEX_GENAI_COMPARTMENT_OCID, modelo,
  regiao, base URL, endpoint) e confirmar se o servico/credencial e compartilhado.

- 2026-10-22: criado `acoes-admin-migracao.md` - checklist para encaminhar ao admin IAM e
  ao DBA, com valores confirmados (schema BGETRAB_OAC, profile DATAPREV_BGETRAB, credencial
  DATAPREV_GENAI_BGETRAB, 26ai, compartment DEV) e comandos exatos das Etapas: pedido do
  ADB_OCID, ENABLE_RESOURCE_PRINCIPAL, sinonimo, Dynamic Group e politica IAM. Pendente do
  lado dev/APEX: coletar dados do Generative AI Service e checar compartilhamento com outras apps.
- 2026-10-22: coletados os dados do Generative AI Service (imagem generative_ai_apex.png):
  Name=dev_DITM_BGETRAB_DEV, Static ID=dev_ditm_bgetrab_dev, Compartment=...povpha (= DEV,
  mesmo do profile), Region=sa-saopaulo-1, Model=cohere.command-a-03-2025,
  Base URL=https://inference.generativeai.sa-saopaulo-1.oci.oraclecloud.com,
  Credential atual=credentials_for_dev_bgetrab_generative_ai, "Used by App Builder"=OFF.
  CONSEQUENCIA: servico APEX e profile usam o MESMO compartment -> politica IAM com UMA
  unica linha. OLD_WEB_CREDENTIAL_NAME (APEX) = credentials_for_dev_bgetrab_generative_ai
  (distinta da credencial de banco DATAPREV_GENAI_BGETRAB; sao duas camadas). Etapa 1 do
  lado do dev concluida, exceto confirmar compartilhamento do servico/credencial/profile
  com outras apps. acoes-admin-migracao.md e migracao-resource-principal.md atualizados.

- 2026-10-22: verificacao de compartilhamento - consulta por workspace='WORKSPACE_BGETRAB_DEV'
  (report (19).csv) retornou apenas app 100 "BGETRAB_teste" (parsing_schema BGETRAB_OAC) e
  NAO trouxe 101/103 -> provavel divergencia no valor/nome da coluna workspace. Descoberta
  nova: existe a app 100 no mesmo parsing schema (pode usar o profile DATAPREV_BGETRAB).
  Reconsultar por owner='BGETRAB_OAC' (sem filtro de workspace) para o quadro completo.
- 2026-10-22: CORRECAO - a leitura do report (20).csv pelo agente veio TRUNCADA (so a app 100)
  por LOCK do Excel sobre o arquivo (aberto no momento da leitura). O conteudo REAL, visto por
  imagem (report_20.png), lista 5 apps com parsing_schema BGETRAB_OAC no WORKSPACE_BGETRAB_DEV:
  100 BGETRAB_teste; 101 PAINEL PUBLICO RAIS (chatbot, pgs 11/99); 102 BGETRAB_teste (Working
  Copy); 103 PAINEL PUBLICO RAIS (enxuta); 104 BGCAGED Legado. CONCLUSAO: o profile
  DATAPREV_BGETRAB NAO e exclusivo da app 101 - todas as 5 apps compartilham o parsing schema
  e podem usar o profile. Logo, trocar o credential_name do profile para Resource Principal
  afeta TODAS elas (o que e desejado e consistente). NOTA OPERACIONAL: fechar o CSV no Excel
  antes de o agente ler, ou enviar por imagem (lock do Excel trunca a leitura do arquivo).
- 2026-10-22: PONTO ATUAL / PROXIMO PASSO. Etapa 1 do levantamento concluida (banco + GenAI
  Service + compartilhamento). Documentos atualizados: apex-select-ai.md (estado), migracao-
  resource-principal.md (valores preenchidos), acoes-admin-migracao.md (checklist admin/DBA).
  PENDENTES: (a) ADB_OCID (so via DBA/console - delegado ao admin, usado na Etapa 2);
  (b) IAM_DOMAIN; (c) refinamento em andamento: EXPORTAR as apps (101 primeiro; idealmente
  100/101/102/103/104) como SQL e buscar nos exports as strings DATAPREV_BGETRAB,
  dev_ditm_bgetrab_dev, credentials_for_dev_bgetrab_generative_ai, PKG_SELECT_AI_V2 e as
  paginas Chat 11/99, para confirmar QUAIS apps realmente invocam o profile/servico/credencial
  (uso real vs acesso potencial). Depois disso: encaminhar acoes-admin-migracao.md e executar
  Etapas 2-4 (admin IAM/DBA) e 5-9 (dev APEX), sempre pedindo confirmacao antes de acoes que
  alterem banco/config do chatbot.