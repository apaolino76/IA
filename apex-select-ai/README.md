# APEX + Select AI - Copiloto do chatbot de IA (BGETRAB / RAIS)

Esta pasta contem o CONTEXTO e os PROCEDIMENTOS para um agente Kiro CLI copiloto que
ajuda a **configurar, migrar e evoluir** o chatbot de IA construido sobre os paineis
APEX do projeto BGETRAB/RAIS (APEX 26.2 + Select AI + OCI Generative AI).

> O copiloto NAO acessa o APEX diretamente. O APEX e acessado por voce, via tunel de
> Bastion (https://localhost/ords/_/landing), autenticado na web. O agente atua como
> copiloto: explica a arquitetura, gera SQL/PLSQL, descreve as telas e documenta o que
> voce coletar. Ele tambem pode rodar comandos OCI de LEITURA (list/get/describe).

> Seguranca/LGPD: esta pasta NAO deve conter credenciais, chaves ou dados pessoais.
> Mascare CPF/PIS/nome/nascimento/CEP em qualquer registro.

## Dois objetivos cobertos

1. **Migracao para Resource Principal** - trocar a autenticacao do chatbot de "usuario
   OCI + chave" para a identidade do Autonomous Database. Ver `migracao-resource-principal.md`.
2. **Criar/evoluir o chatbot** e resolver o **"chatbot para qualquer login"** (hoje so
   funciona para o login que o configurou). Ver `copiloto-chatbot.md`.

## Conteudo da pasta

- README.md ........................ Este guia.
- apex-select-ai.md ............... ESTADO ATUAL do chatbot (ambiente, componentes, descobertas). Leia primeiro.
- migracao-resource-principal.md .. Guia operacional da migracao (adaptado dos 2 .md da raiz da Dataprev).
- copiloto-chatbot.md ............. Arquitetura, criar/evoluir o chatbot e diagnostico do "qualquer login".
- install-agent.ps1 ............... Instala o agente apex-select-ai.json no seu perfil Kiro CLI.
- agents/apex-select-ai.json ...... Modelo versionado do agente (copiloto APEX + Select AI).
- .amazonq/rules/apex-select-ai.md  Regra carregada automaticamente neste diretorio.

Relacionado (pasta irma): `../bgetrab-agente` tem a infraestrutura OCI (oci-bgetrab.md)
e o mapeamento dos paineis APEX (apex-bgetrab.md). Este projeto foca na camada de IA.

## Pre-requisitos

1. Kiro CLI instalado.
2. (Para a migracao) OCI CLI autenticado - mesmas instrucoes do bgetrab-agente
   (ver ../bgetrab-agente/configuracao-agente-oci.md e setup-oci-bgetrab.ps1).
3. Acesso ao APEX via tunel de Bastion (ver ../bgetrab-agente/oci-bgetrab.md).
4. Windows com PowerShell.

## Instalacao do agente

    powershell -ExecutionPolicy Bypass -File .\install-agent.ps1

Copia agents\apex-select-ai.json para %USERPROFILE%\.kiro\agents\apex-select-ai.json
e valida. Salve o JSON em UTF-8 SEM BOM (o validador do Kiro rejeita BOM).

Validar manualmente (opcional):

    kiro-cli agent validate --path "%USERPROFILE%\.kiro\agents\apex-select-ai.json"

## Como usar

Inicie o Kiro nesta pasta com o agente:

    kiro-cli chat --agent apex-select-ai

Ou dentro do chat: `/agent swap apex-select-ai`

A regra `.amazonq/rules/apex-select-ai.md` e carregada automaticamente e manda o agente
ler o `apex-select-ai.md` como estado atual. Exemplos de pedidos:

- "Quero migrar o chatbot para Resource Principal. Me guie pela etapa 1."
- "Explique como o chatbot funciona hoje e por que so funciona para o meu login."
- "Gere o SQL para conferir o credential_name do profile Select AI."
- "Quero criar/evoluir o profile Select AI com as tabelas RAIS."
- "Colei o resultado da consulta; interprete e atualize o apex-select-ai.md."

## Fluxo recomendado

1. Ler `apex-select-ai.md` e `copiloto-chatbot.md` (Parte A) para entender a arquitetura.
2. Rodar as consultas de levantamento (secao 6 do apex-select-ai.md) e colar os resultados.
3. Para o "qualquer login": seguir o diagnostico da Parte C do copiloto-chatbot.md.
4. Executar a migracao pelo `migracao-resource-principal.md` (resolve a maior parte).
5. Documentar cada descoberta/teste no apex-select-ai.md.
