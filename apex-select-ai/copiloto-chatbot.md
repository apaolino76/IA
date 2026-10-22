# Copiloto do chatbot - criar, evoluir e liberar para qualquer login

Guia de aprendizado e trabalho para o objetivo 2: entender, criar e evoluir o chatbot
de IA (APEX + Select AI + OCI Generative AI) sobre os paineis RAIS, e resolver o
problema do **"chatbot funcional para qualquer login"**.

> O copiloto NAO acessa o APEX. Ele explica a arquitetura, gera o SQL/PLSQL, descreve
> as telas e analisa o que voce coletar. Voce executa no APEX via tunel e cola os resultados.

---

## Parte A - Como o chatbot funciona (arquitetura)

Entender as 5 pecas e o que cada uma faz e o pre-requisito para configurar e depurar.

```
Usuario (login APEX)
   -> Pagina Chat (APEX, app 101: pgs 11 e 99)
      -> AI Agent (APEX) ---- aponta para ----> Generative AI Service (APEX)
                                                   |  usa
                                                   v
                                             Web Credential (APEX)  --> autentica no OCI
      -> (opcional) tool/PL-SQL que chama Select AI no banco
            -> DBMS_CLOUD_AI + Profile Select AI
                 |  usa credential_name
                 v
            Credencial de banco (chave do usuario OCI  OU  OCI$RESOURCE_PRINCIPAL)
                 -> OCI Generative AI (modelo, ex. Cohere/Llama) na regiao
```

Dois "caminhos" chamam o OCI Generative AI:
1. **APEX direto**: AI Agent -> Generative AI Service -> Web Credential.
2. **Select AI no banco**: profile DBMS_CLOUD_AI -> credential_name.

Cada caminho tem a SUA credencial. Para "qualquer login" funcionar, nenhum dos dois
pode depender de uma permissao pessoal de um usuario especifico.

Conceitos-chave do Select AI (DBMS_CLOUD_AI):
- **Profile**: objeto que guarda provider (oci), modelo, regiao, credential_name,
  compartimento, e a LISTA DE OBJETOS (tabelas/views) que a IA pode consultar.
- **credential_name**: como o banco se autentica no OCI GenAI. E o ponto central do
  problema de login (ver Parte C).
- **action**: `chat` (conversa), `showsql` (gera SQL sem rodar), `runsql`, `narrate`.

---

## Parte B - Criar ou evoluir o chatbot (passo a passo)

Se o chatbot ja existe (paginas Chat da app 101), os passos abaixo servem para
evoluir/conferir. Se for criar do zero numa app, seguir na ordem.

### B1. Pre-requisitos no OCI
- Acesso ao OCI Generative AI na regiao (sa-saopaulo-1 ou a regiao do modelo).
- Autenticacao: por **Resource Principal** (recomendado, ver migracao-resource-principal.md)
  ou por usuario OCI + chave. Resource Principal e o caminho que resolve o login.

### B2. Credencial de banco (Select AI)
Com Resource Principal, a credencial e `OCI$RESOURCE_PRINCIPAL` (gerenciada pelo banco).
Sem ele, cria-se com DBMS_CLOUD.CREATE_CREDENTIAL (chave de um usuario - NAO recomendado
para multiusuario).

### B3. Criar/ajustar o Profile Select AI
Exemplo de criacao (ajustar objetos, modelo, regiao, compartimento):

```sql
BEGIN
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'RAIS_GENAI',
    attributes   => '{
      "provider": "oci",
      "credential_name": "OCI$RESOURCE_PRINCIPAL",
      "oci_compartment_id": "[COMPARTMENT_OCID]",
      "region": "sa-saopaulo-1",
      "model": "[MODELO_OCI_GENAI]",
      "object_list": [
        {"owner": "BGETRAB_OAC", "name": "FT_RAIS_DECLARACOES_ANUARIO"},
        {"owner": "BGETRAB_OAC", "name": "FT_RAIS_VINCULOS_ANUARIO"},
        {"owner": "BGETRAB_OAC", "name": "TAB_RAIS_VINCULOS_ANALITICA"},
        {"owner": "BGETRAB_OAC", "name": "FT_INDICE_GINI"}
      ]
    }'
  );
END;
/
```

> A `object_list` define o que a IA "enxerga". Para boas respostas, inclua as
> tabelas/views dos paineis (ver ../bgetrab-agente/apex-bgetrab.md) e use COMMENTS
> nas colunas para dar contexto semantico ao modelo.

Testar:

```sql
BEGIN DBMS_CLOUD_AI.SET_PROFILE('RAIS_GENAI'); END;
/
SELECT DBMS_CLOUD_AI.GENERATE(
  prompt => 'Quantos vinculos ativos existem por UF?',
  profile_name => 'RAIS_GENAI', action => 'showsql') AS sql_gerado
FROM dual;
```

### B4. Generative AI Service no APEX
App Builder -> Workspace Utilities -> Generative AI -> Create:
- Provider: OCI
- Credential: a Web Credential (Resource Principal recomendada)
- Compartment, Region, AI Model, Endpoint conforme o OCI
- Test Connection -> salvar.

### B5. AI Agent + pagina Chat
No App Builder, criar/editar o AI Agent apontando para o Generative AI Service, e a
pagina do tipo Chat (as apps modernas do APEX 26.2 tem componente nativo). A app 101
ja tem as paginas 11 "Chat (Modal Dialog)" e 99 "Chat 02" como base.

### B6. Evolucoes uteis
- Melhorar prompts/instrucoes do profile e COMMENTS nas colunas.
- Restringir/ampliar a object_list conforme o painel.
- Usar views/MV ja existentes (MV_VISAO_GERAL, MV_REMUNERACOES) para respostas rapidas.
- Mascarar colunas com dados pessoais (LGPD) antes de expor a IA.

---

## Parte C - "Chatbot funcional para qualquer login" (o problema central)

Sintoma: o chatbot so responde quando o usuario que o configurou faz login no APEX.
Para outros logins, falha (tipicamente erro de autenticacao/autorizacao OCI, ou a
credencial/profile nao resolvem).

### Causa mais provavel
A autenticacao no OCI GenAI esta amarrada a uma **identidade pessoal**:
- A Web Credential (APEX) e/ou o credential_name (profile) usam a **chave de UM usuario
  OCI**, e a **politica IAM** so concede acesso aquele usuario.
- Quando outro login APEX dispara a chamada, ou a credencial nao esta disponivel no
  contexto dele, ou a permissao OCI nao se aplica.

### Solucao recomendada: Resource Principal
Migrar os dois caminhos para `OCI$RESOURCE_PRINCIPAL` (ver migracao-resource-principal.md).
A identidade passa a ser **o Autonomous Database**, nao a pessoa. Assim, qualquer login
APEX que use a mesma app/servico/profile autentica igual. Esse e o passo que, na maioria
dos casos, resolve o "qualquer login".

### Checklist de diagnostico (do APEX para fora)

Rode e cole os resultados; o copiloto interpreta.

1. **Contexto de execucao por login** - a app roda sempre no mesmo parsing schema?
```sql
SELECT SYS_CONTEXT('USERENV','SESSION_USER')   AS session_user,
       SYS_CONTEXT('USERENV','CURRENT_USER')   AS current_user,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS current_schema
FROM dual;
```
Se o parsing schema for o mesmo para todos os logins (tipico em APEX), o problema NAO
e "schema diferente por usuario" - aponta para credencial/IAM pessoal.

2. **Credencial do profile** - e pessoal ou Resource Principal?
```sql
SELECT profile_name, attribute_name, attribute_value
FROM   user_cloud_ai_profile_attributes
WHERE  attribute_name = 'credential_name';
```
Se `credential_name` NAO for `OCI$RESOURCE_PRINCIPAL`, e uma credencial de usuario ->
forte candidata a causa. Migrar.

3. **Web Credential do servico APEX** - OCI Native Auth com chave pessoal?
   Conferir na tela Generative AI Service -> Credential. Se for a chave de uma pessoa,
   trocar pela Web Credential de Resource Principal.

4. **Autorizacao da pagina/componente Chat no APEX** - Authorization Scheme restrito?
   Editar a pagina Chat (app 101, pgs 11/99) -> Security -> Authorization Scheme.
   Se estiver restrita a um usuario/role especifico, ajustar para o publico desejado.
   Esta e a causa quando o erro e de ACESSO A PAGINA, nao de IA.

5. **Permissao de rede (ACL)** - apos migrar, erro ORA-24247 indica ACL de rede faltando
   no parsing schema para o endpoint do OCI GenAI. O DBA ajusta com DBMS_NETWORK_ACL_ADMIN.

### Arvore de decisao rapida

- Erro ao ABRIR a pagina Chat (sem chegar na IA) -> causa 4 (Authorization Scheme APEX).
- Erro de autenticacao/autorizacao do OCI GenAI com outro login -> causa 1/2/3 ->
  migrar para Resource Principal.
- Funciona para todos apos migrar, mas falha intermitente -> cache de token (ate 2h) ou
  ACL de rede (causa 5).

---

## Parte D - O que registrar no apex-select-ai.md

Conforme for descobrindo, peca ao copiloto para atualizar o apex-select-ai.md com:
- Nome real do profile, credential_name atual, Web Credential e Generative AI Service.
- Parsing schema confirmado e se e o mesmo para todos os logins.
- Resultado do teste "com outro login" antes e depois da migracao.
- Authorization Scheme das paginas Chat.
