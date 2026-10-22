# Migracao para Resource Principal - guia operacional (BGETRAB/RAIS)

Guia de trabalho do copiloto para migrar a autenticacao do chatbot APEX + Select AI
de "usuario OCI + chave" para **Resource Principal** (identidade do Autonomous Database).

> Base: os dois .md da raiz (`Dataprev_Orientacao_Resource_Principal_APEX_Select_AI_v7.md`
> e `..._resumido.md`). Este arquivo e a versao aplicada ao ambiente BGETRAB, com os
> valores conhecidos ja preenchidos e os pendentes marcados como **[CONFIRMAR]**.
> A documentacao oficial Oracle prevalece em caso de divergencia.

## Por que migrar (ligacao com o "chatbot para qualquer login")

Hoje a autenticacao depende da chave de UM usuario OCI. Qualquer que seja o login
APEX, a chamada ao OCI Generative AI usa essa credencial pessoal - e as permissoes
IAM so existem para aquele usuario. Ao migrar para Resource Principal, quem se
autentica no OCI passa a ser **o proprio banco (Autonomous)**, nao a pessoa. Isso
remove a dependencia do login individual e e, provavelmente, parte da solucao do
problema "o chatbot so funciona para o login que o configurou" (ver copiloto-chatbot.md).

## Valores do ambiente (preencher com o usuario)

| Marcador | Onde obter | Valor |
|---|---|---|
| ADB_NAME | Autonomous que hospeda a app | DA_ADW_BGETRAB_PROD (confirmar nome do ADB) |
| ADB_OCID | Pagina do Autonomous na OCI -> OCID | **[CONFIRMAR]** (usuario sem acesso a console; v$pdbs/v$containers sem privilegio - ORA-00942. CLI: TLS resolvido em 2026-10-22 (CA Zscaler no bundle), mas `oci db autonomous-database list` da 403 Forbidden -> falta policy IAM `inspect autonomous-databases` no compartment DEV/PROD. Obter via: policy IAM + CLI, ou DBA (SELECT cloud_identity FROM v$pdbs), ou console OCI) |
| DB_VERSION | 19c, 23ai ou 26ai (confirmar com DBA) | **26ai** (confirmado 2026-10-22; release 23.26.4.1.0). Etapa 4.2: criar sinonimo e permitido. |
| IAM_DOMAIN | OCI -> Identity -> Domains (ex. Default) | **[CONFIRMAR]** |
| PARSING_SCHEMA | APEX -> Edit Application Definition -> Parsing Schema | **BGETRAB_OAC** (confirmado 2026-10-22; apps 101 e 103) |
| SELECTAI_SCHEMA | Schema executor do profile Select AI | **BGETRAB_OAC** (confirmado; profile visivel neste schema) |
| PACKAGE_OWNER | Dono de PKG_SELECT_AI_V2, se instalada | **BGETRAB_OAC** (confirmado 2026-10-22; AUTHID=DEFINER, nao CURRENT_USER como nos docs Dataprev) |
| WORKSPACE | Workspace APEX | WORKSPACE_BGETRAB_DEV |
| APP_ID | App do chatbot | **101** (paginas Chat 11/99; confirmado) |
| AI_SERVICE_NAME | Generative AI Service usado pelo agente | **dev_DITM_BGETRAB_DEV** (Static ID dev_ditm_bgetrab_dev; confirmado 2026-10-22) |
| OLD_WEB_CREDENTIAL_NAME | Web Credential atual do servico | **credentials_for_dev_bgetrab_generative_ai** (confirmado 2026-10-22) |
| AI_PROFILE | Profile Select AI efetivo | **DATAPREV_BGETRAB** (confirmado 2026-10-22) |
| OLD_DB_CREDENTIAL | credential_name atual do profile (consulta 1.2) | **DATAPREV_GENAI_BGETRAB** (confirmado; aponta p/ usuario OCI pessoal) |
| APEX_GENAI_COMPARTMENT_OCID | Compartment do servico APEX | **ocid1.compartment.oc1..aaaa...povpha** (= mesmo compartment DEV do profile; confirmado 2026-10-22) |
| SELECTAI_GENAI_COMPARTMENT_OCID | Compartment do profile | **ocid1.compartment.oc1..aaaa...povpha** (do atributo oci_compartment_id; valor completo no apex-select-ai.md) |
| DYNAMIC_GROUP_NAME | Nome a criar/reutilizar | dg-rais-adb-genai (sugerido) |
| POLICY_NAME | Nome a criar/reutilizar | pol-rais-adb-genai (sugerido) |
| RP_WEB_CREDENTIAL_NAME | Nova Web Credential | RAIS OCI Resource Principal (sugerido) |
| RP_WEB_CREDENTIAL_STATIC_ID | Novo Static ID | rais-oci-rp (sugerido) |
| TEST_QUESTION | Pergunta de consulta conhecida (sem `~`) | **[CONFIRMAR]** |

Quem executa: admin IAM (grupo/politica); ADMIN do banco (habilitacao); dono do
profile (alteracao); dev APEX (selecionar a credencial).

---

## Etapa 1 - Levantar os valores atuais

No APEX, abrir a app do chatbot -> Edit Application Definition -> conferir Parsing Schema.
Abrir a tool do AI Agent e conferir a chamada a package e o `p_profile_name`.

Conectado como SELECTAI_SCHEMA:

```sql
SELECT SYS_CONTEXT('USERENV','SESSION_USER')   AS session_user,
       SYS_CONTEXT('USERENV','CURRENT_USER')   AS current_user,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS current_schema
FROM dual;

-- Package (se instalada)
SELECT owner, object_name, authid
FROM   all_procedures
WHERE  object_name = 'PKG_SELECT_AI_V2'
  AND  procedure_name IS NULL;

-- Atributos do profile (preencher OLD_DB_CREDENTIAL com credential_name)
SELECT profile_name, attribute_name, attribute_value
FROM   user_cloud_ai_profile_attributes
WHERE  profile_name = '[AI_PROFILE]'
ORDER  BY attribute_name;
```

Confirmar `provider = oci`. Registrar modelo, regiao, compartimento, endpoint.
Rodar o chatbot com a TEST_QUESTION e guardar o resultado de referencia.
No APEX, anotar Credential, Provider API, Compartment ID, Serving Mode, Region,
Base URL, AI Model e Endpoint ID do Generative AI Service. A troca sera somente de Credential.

**Confirmar se o servico/credencial/profile sao usados por outras apps** antes de mexer.

---

## Etapa 2 - Dynamic Group (admin IAM)

OCI -> Identity & Security -> Domains -> IAM_DOMAIN -> Dynamic Groups -> Create.

| Campo | Valor |
|---|---|
| Name | DYNAMIC_GROUP_NAME |
| Matching rule | `resource.id = '[ADB_OCID]'` |

So inclui o banco informado. Nao usar regra de "todos os recursos do compartimento".

Conferir por leitura (opcional, via copiloto): `oci iam dynamic-group list ...`

---

## Etapa 3 - Politica IAM (admin IAM)

OCI -> Identity & Security -> Policies -> Create.

```text
Allow dynamic-group '[IAM_DOMAIN]/[DYNAMIC_GROUP_NAME]' to use generative-ai-chat in compartment id [APEX_GENAI_COMPARTMENT_OCID]
Allow dynamic-group '[IAM_DOMAIN]/[DYNAMIC_GROUP_NAME]' to use generative-ai-chat in compartment id [SELECTAI_GENAI_COMPARTMENT_OCID]
```

Se os dois OCIDs forem iguais, manter uma unica declaracao. Autoriza a API **Chat**;
embeddings/Responses exigem permissoes adicionais.

---

## Etapa 4 - Habilitar Resource Principal no banco (ADMIN)

```sql
BEGIN DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(); END;
/
BEGIN DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => '[PARSING_SCHEMA]'); END;
/
-- Se SELECTAI_SCHEMA != PARSING_SCHEMA:
BEGIN DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => '[SELECTAI_SCHEMA]'); END;
/
```

Se vier "resource principal is already enabled", conferir grants e seguir. Nao
desabilitar/reabilitar uma identidade ja usada por outras apps.

Conferir:

```sql
SELECT owner, credential_name FROM dba_credentials
WHERE credential_name = 'OCI$RESOURCE_PRINCIPAL';

SELECT grantee, table_schema, table_name, privilege
FROM   all_tab_privs
WHERE  grantee IN ('[PARSING_SCHEMA]','[SELECTAI_SCHEMA]')
  AND  table_schema = 'ADMIN'
  AND  table_name = 'OCI$RESOURCE_PRINCIPAL';
```

### 4.2 Resolucao para o APEX

```sql
SELECT owner, object_name, object_type FROM dba_objects
WHERE owner = '[PARSING_SCHEMA]' AND object_name = 'OCI$RESOURCE_PRINCIPAL';

SELECT owner, synonym_name, table_owner, table_name FROM dba_synonyms
WHERE owner IN ('[PARSING_SCHEMA]','PUBLIC') AND synonym_name = 'OCI$RESOURCE_PRINCIPAL';
```

**Somente 23ai/26ai**, se nao houver credencial local nem sinonimo:

```sql
CREATE SYNONYM [PARSING_SCHEMA].OCI$RESOURCE_PRINCIPAL FOR ADMIN.OCI$RESOURCE_PRINCIPAL;
```

**Em 19c:** NAO criar o sinonimo; confirmar a resolucao com o DBA antes da etapa 6.

---

## Etapa 5 - Web Credential de Resource Principal (dev APEX)

App Builder -> Workspace Utilities -> Web Credentials -> Create.

| Campo | Valor |
|---|---|
| Name | RP_WEB_CREDENTIAL_NAME |
| Static ID | RP_WEB_CREDENTIAL_STATIC_ID |
| Authentication Type | OCI Native Authentication |
| Use Database Credential | Habilitado |
| Database Credential Scope | Schema |
| Database Credential Name | OCI$RESOURCE_PRINCIPAL (sem prefixo ADMIN.) |

Manter a Web Credential anterior disponivel para retorno.

---

## Etapa 6 - Trocar credential_name no profile (dono do profile)

```sql
BEGIN
  DBMS_CLOUD_AI.SET_ATTRIBUTE(
    profile_name    => '[AI_PROFILE]',
    attribute_name  => 'credential_name',
    attribute_value => 'OCI$RESOURCE_PRINCIPAL'
  );
END;
/
```

Conferir e testar:

```sql
SELECT profile_name, attribute_name, attribute_value
FROM   user_cloud_ai_profile_attributes
WHERE  profile_name = '[AI_PROFILE]' AND attribute_name = 'credential_name';

SELECT DBMS_CLOUD_AI.GENERATE(
  prompt => 'Responda somente com a palavra OK.',
  profile_name => '[AI_PROFILE]', action => 'chat') AS resposta
FROM dual;

-- Se a package existir:
SELECT [PACKAGE_OWNER].PKG_SELECT_AI_V2.generate_sql(
  p_prompt => q'~[TEST_QUESTION]~', p_profile_name => '[AI_PROFILE]') AS sql_gerado
FROM dual;
```

NAO rodar CREATE_PROFILE/DROP_PROFILE. Nao trocar o nome do profile.

---

## Etapa 7 - Trocar a credencial no servico APEX (dev APEX)

1. App Builder -> Workspace Utilities -> Generative AI.
2. Abrir AI_SERVICE_NAME.
3. Credentials -> Credential -> selecionar RP_WEB_CREDENTIAL_NAME.
4. Conferir que modelo/regiao/API/compartimento/URL/endpoint seguem iguais.
5. Test Connection -> "Connection Succeeded!" -> salvar.
6. Abrir a app APEX e iniciar uma conversa nova no chatbot.
7. Testar pergunta simples e depois a TEST_QUESTION (aciona a tool de dados).

---

## Etapa 8 - Checklist final

- [ ] Dynamic Group inclui o Autonomous correto e politica cobre os compartimentos usados.
- [ ] Resource Principal acessivel ao parsing schema e ao schema executor.
- [ ] Profile retorna credential_name = OCI$RESOURCE_PRINCIPAL.
- [ ] GENERATE direto e teste pela package (se houver) funcionam.
- [ ] Servico APEX usa a Web Credential RP e Test Connection passa.
- [ ] Conversa nova no chatbot retorna os dados esperados.
- [ ] **Teste com OUTRO login APEX** (validacao do objetivo "qualquer login").

Notas: ORA-24247 indica ACL de rede no parsing schema (DBA verifica). Token Resource
Principal pode ficar em cache por ate 2h (aguardar antes de concluir que a politica falhou).

---

## Etapa 9 - Retorno (rollback), se necessario

**APEX:** no servico, voltar a Credential para OLD_WEB_CREDENTIAL_NAME, testar, salvar.

**Select AI:**

```sql
BEGIN
  DBMS_CLOUD_AI.SET_ATTRIBUTE(
    profile_name    => '[AI_PROFILE]',
    attribute_name  => 'credential_name',
    attribute_value => '[OLD_DB_CREDENTIAL]'
  );
END;
/
```

Nao desabilitar o Resource Principal do banco para reverter so a aplicacao. Manter a
chave pessoal anterior valida ate o aceite. Avaliar a retirada dela so depois, com cuidado.
