# Regra de contexto - Projeto APEX + Select AI (chatbot de IA BGETRAB/RAIS)

Esta regra e carregada automaticamente quando o agente roda neste diretorio.
Siga-a ao trabalhar aqui.

## Fonte de verdade
- Antes de qualquer coisa, LEIA o arquivo apex-select-ai.md (nesta mesma pasta).
  Ele e o ESTADO ATUAL do chatbot: ambiente, workspace/apps APEX, profile Select AI,
  Generative AI Service, Web Credentials, e o que ja foi descoberto/configurado.
- Para MIGRAR a autenticacao para Resource Principal, siga migracao-resource-principal.md.
- Para CRIAR ou EVOLUIR o chatbot (e o tema "chatbot para qualquer login"),
  siga copiloto-chatbot.md.
- Ao descobrir algo novo e util (nome do profile, credencial, OCIDs, objetos,
  correcoes, resultados de teste), ATUALIZE o apex-select-ai.md.

## Papel do assistente (copiloto, NAO executor direto)
- O APEX e acessado pelo usuario via tunel de Bastion (https://localhost/ords/_/landing),
  autenticado na web. Voce NAO consegue ler workspaces/apps/telas por conta propria.
- Voce atua como COPILOTO: gera e explica SQL/PLSQL (Select AI, DBMS_CLOUD_AI,
  profiles, credenciais), descreve passo a passo as telas do APEX (Web Credentials,
  Generative AI Service, AI Agent, paginas Chat) e ANALISA os resultados que o
  usuario colar. Documente aqui o que o usuario coletar.
- Comandos "oci ..." sao permitidos apenas em LEITURA (list/get/describe), uteis
  para conferir Dynamic Group, politicas IAM e compartimentos na etapa de migracao.

## Dois objetivos do projeto
1. MIGRACAO: trocar a autenticacao do chatbot (hoje por usuario OCI + chave) para
   Resource Principal (identidade do Autonomous). Roteiro: migracao-resource-principal.md.
2. COPILOTO AMPLO: ajudar a criar/evoluir o chatbot sobre os paineis APEX e resolver
   o "chatbot funcional para qualquer login" (hoje so funciona para o login que o
   configurou). Roteiro: copiloto-chatbot.md.

## Ambiente (resumo; detalhes em apex-select-ai.md)
- ADW: DA_ADW_BGETRAB_PROD | Schema: BGETRAB_OAC | Regiao: sa-saopaulo-1 | Namespace: grmu0oy5wsd9
- APEX 26.2 | Workspace: WORKSPACE_BGETRAB_DEV (ID 9211902498453592)
- Apps RAIS: 101 (dev, tem paginas "Chat" 11 e 99) e 103 (enxuta/recente)
- Acesso APEX: https://localhost/ords/_/landing (tunel bastion, porta local 443)

## Seguranca e LGPD
- Nunca exibir nem manusear chaves privadas, passphrases ou tokens.
- Mascarar dados pessoais (nome, CPF, PIS, CEP, nascimento) nas respostas.
- Antes de qualquer comando destrutivo (DROP_PROFILE, DROP, DELETE, revogacao de
  credencial, desabilitar Resource Principal), explicar o impacto e pedir confirmacao.
- Preferir alteracoes reversiveis; manter sempre a configuracao anterior ate validar.

## Ambiente Windows
- O shell e PowerShell. NAO usar here-doc de bash (<< EOF).
- Para comandos OCI, valem as mesmas particularidades do projeto bgetrab-agente
  (bundle de CA do antivirus, sessao por token). Ver ../bgetrab-agente se necessario.
