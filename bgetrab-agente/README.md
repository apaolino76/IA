# Projeto BGETRAB (OCI) - Guia de Onboarding

Este repositorio contem o CONTEXTO e os PROCEDIMENTOS para operar os recursos
OCI do projeto BGETRAB com o assistente (Kiro CLI) via OCI CLI.

> IMPORTANTE (seguranca): este repositorio NAO contem credenciais. Cada membro
> usa o SEU proprio usuario OCI, a SUA chave API e a SUA passphrase. Nunca
> compartilhe chaves privadas, passphrases ou tokens. Nunca os versione.

## Conteudo do repositorio
- oci-bgetrab.md ............... Fonte de verdade do projeto (OCIDs, buckets, schema, tasks, diagnosticos).
- configuracao-agente-oci.md .. Como montar o ambiente: instalar OCI CLI, criar o agente oci.json, troubleshooting.
- .amazonq/rules/bgetrab.md .... Regra carregada automaticamente pelo agente neste diretorio.
- setup-oci-bgetrab.ps1 ........ Script que configura o bundle de CA (Kaspersky) e as variaveis de ambiente.
- .gitignore .................. Protege contra commit acidental de segredos.
- agents/oci.json ............. Modelo versionado do agente OCI (mesmo arquivo para todas as maquinas).
- install-agent.ps1 ........... Copia o agents/oci.json para a pasta de agentes do seu perfil (%USERPROFILE%\.kiro\agents).

## Pre-requisitos
1. OCI CLI instalado (ver configuracao-agente-oci.md para o passo a passo no Windows).
2. Usuario na tenancy OCI com permissao (politica IAM) no compartimento do projeto BGETRAB.
3. Windows com PowerShell.

## Passo a passo (cada membro, na sua maquina)

### 0. Instalar o agente customizado do Kiro CLI (portatil entre maquinas)
O modelo do agente fica versionado em agents/oci.json. Como ele NAO contem
caminhos com nome de usuario, o MESMO arquivo serve em casa e no trabalho.
Em cada maquina, instale-o no seu perfil com:

    powershell -ExecutionPolicy Bypass -File .\install-agent.ps1

O script copia agents/oci.json para %USERPROFILE%\.kiro\agents\oci.json
(resolve automaticamente C:\Users\angel OU C:\Users\angelo.paolino) e valida.

Fluxo para manter sincronizado nas duas maquinas:
1. Editar o agente SOMENTE em agents/oci.json neste repositorio.
2. git commit + git push na maquina onde editou.
3. git pull na outra maquina e rodar install-agent.ps1 novamente.

Validar manualmente (opcional): kiro-cli agent validate --path "%USERPROFILE%\.kiro\agents\oci.json"
Usar: kiro-cli chat --agent oci

Obs.: o oci.json deve ser salvo em UTF-8 SEM BOM; o validador do Kiro rejeita
arquivos com BOM. O install-agent.ps1 preserva o arquivo como esta no repo.

### 1. Gerar a propria chave API e configurar o perfil
    oci setup config
- Informe tenancy OCID, user OCID, regiao (sa-saopaulo-1) e deixe gerar as chaves.
- Registre a chave PUBLICA no seu usuario (Console OCI > User Settings > API Keys).
- Se a sua chave tiver passphrase, lembre-se dela (NAO a coloque em arquivos versionados).

### 2. Resolver a intercepcao TLS do antivirus (se usar Kaspersky ou similar)
    powershell -ExecutionPolicy Bypass -File .\setup-oci-bgetrab.ps1
Abra uma JANELA NOVA do terminal depois, para as variaveis valerem.
Obs.: se voce NAO usa antivirus com inspecao TLS, o script detecta a ausencia da CA e avisa.

### 3. Autenticar por sessao (evita digitar passphrase a cada comando)
    oci session authenticate --region sa-saopaulo-1
- Faca login no navegador. Quando pedir o nome do perfil, use: bgetrab-session
- Para renovar: oci session refresh --profile bgetrab-session

### 4. Validar
    oci os ns get
Esperado: "grmu0oy5wsd9".

## Usando o assistente
- Abra o agente neste diretorio. A regra .amazonq/rules/bgetrab.md e carregada
  automaticamente e instrui o assistente a ler o oci-bgetrab.md.
- Alternativa manual: peca "Leia oci-bgetrab.md e use como contexto".

## Dados sensiveis (LGPD)
- Arquivos CAGED/RAIS contem dados pessoais (nome, CPF, PIS, CEP, nascimento).
- Nao versionar CSVs (ja bloqueado no .gitignore). Mascarar dados em relatorios.

## Dados de referencia (nao sao segredo, mas sao internos)
- Regiao: sa-saopaulo-1 | Namespace: grmu0oy5wsd9
- Demais OCIDs e detalhes: ver oci-bgetrab.md
