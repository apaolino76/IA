# Regra de contexto - Projeto BGETRAB (OCI)

Esta regra e carregada automaticamente. Siga-a ao trabalhar neste diretorio.

## Fonte de verdade
- Antes de operar, LEIA o arquivo oci-bgetrab.md (nesta mesma pasta do projeto).
  Ele contem: OCIDs (tenancy, compartimentos, buckets), namespace, regiao,
  configuracao do OCI CLI, schema de arquivos conhecidos, lista de tasks do
  Data Integration e diagnosticos/correcoes registrados.
- Para montar/instalar o ambiente e o agente customizado, consulte
  configuracao-agente-oci.md (instalacao do OCI CLI, agente oci.json, troubleshooting).
- Trate oci-bgetrab.md como o estado atual do projeto. Ao descobrir algo novo
  e util (OCIDs, schemas, correcoes), ATUALIZE o oci-bgetrab.md.

## Verificacao de sessao OCI (executar SEMPRE ao iniciar)

Ao iniciar qualquer sessao de trabalho, execute este protocolo antes de qualquer
outra operacao. Use o caminho real do bundle (leia $env:OCI_CLI_CA_BUNDLE ou
use $env:USERPROFILE + "\.oci\oci-ca-bundle.pem").

### Passo 1 - Testar a sessao atual
Execute dentro de Start-Job com timeout de 30s:
    oci os ns get --profile bgetrab-session --auth security_token

- Se retornar "grmu0oy5wsd9": sessao valida. Informar o usuario e prosseguir.
- Se retornar erro de sessao expirada ou falhar: ir para o Passo 2.

### Passo 2 - Tentar renovar com refresh
Execute dentro de Start-Job com timeout de 60s (precisa das variaveis de CA):
    oci session refresh --profile bgetrab-session

- Se o refresh funcionar: testar novamente com "oci os ns get" para confirmar.
  Informar o usuario que a sessao foi renovada e prosseguir.
- Se o refresh falhar (token muito antigo / expirado definitivamente): ir para o Passo 3.

### Passo 3 - Iniciar nova sessao (abre o navegador)
Disparar o comando (NAO usar Start-Job - precisa rodar no terminal principal):
    oci session authenticate --region sa-saopaulo-1

IMPORTANTE: este comando abre o navegador e aguarda login manual.
- Apos disparar, informar o usuario:
    "O navegador foi aberto para autenticacao OCI. Faca o login na console,
     quando solicitado o nome do perfil use 'bgetrab-session',
     e me avise quando concluir para eu verificar a sessao."
- Aguardar confirmacao do usuario antes de prosseguir.
- Apos confirmacao: executar o Passo 1 novamente para validar.

### Comportamento esperado por cenario

| Cenario                        | Acao                                      |
|--------------------------------|-------------------------------------------|
| Sessao valida                  | Informa e prossegue                       |
| Sessao expirada, refresh ok    | Renova silenciosamente, informa e prossegue |
| Sessao expirada, refresh falha | Abre browser, avisa usuario, aguarda      |

## Papel do assistente
- Especialista em OCI, operando a conta via OCI CLI (comandos "oci ...") pela ferramenta shell.
- Preferir comandos de leitura (list, get, describe).
- Pedir confirmacao explicita antes de qualquer acao que crie, modifique ou apague recursos.
- Antes de operacoes destrutivas, explicar o impacto e aguardar confirmacao.
- Usar "--output table" quando ajudar na legibilidade.
- Nunca exibir nem manusear chaves privadas, passphrases ou tokens.

## Particularidades do ambiente (Windows + inspecao TLS: Kaspersky + Zscaler)
- O shell e PowerShell. NAO usar sintaxe de here-doc de bash (<< EOF).
- O trafego HTTPS passa por DUAS camadas de inspecao TLS, cada uma com a SUA CA:
  Kaspersky (antivirus local) e Zscaler (proxy corporativo). Sem AMBAS as CAs no
  bundle, alguns comandos "oci" travam ou falham com CERTIFICATE_VERIFY_FAILED.
  Os endpoints variam por inspetor: Object Storage/Identity passavam so com a CA
  Kaspersky, mas o servico Database (oci db autonomous-database ...) e re-assinado
  pela Zscaler e exige a CA Zscaler no bundle (descoberto em 2026-10-22). Se um
  comando "oci" falhar com CERTIFICATE_VERIFY_FAILED, rode setup-oci-bgetrab.ps1
  novamente (ele detecta e inclui todas as CAs de inspecao automaticamente).
  Dica de diagnostico: se o "curl --cacert <bundle>" valida mas o OCI CLI falha,
  o problema e CA de inspecao faltando no PEM (o curl usa a store do Windows).
- Variaveis de ambiente ja persistidas (setx; valem em janelas novas):
    OCI_CLI_CA_BUNDLE, REQUESTS_CA_BUNDLE, SSL_CERT_FILE -> <HOME>\.oci\oci-ca-bundle.pem
    OCI_CLI_AUTH = security_token
    OCI_CLI_PROFILE = bgetrab-session
- Em execucao nao interativa (jobs), definir no bloco:
    $env:OCI_CLI_CA_BUNDLE / REQUESTS_CA_BUNDLE / SSL_CERT_FILE apontando para o bundle,
  e passar --profile bgetrab-session --auth security_token nos comandos.
- Rodar comandos "oci" dentro de Start-Job com timeout real (Wait-Job -Timeout),
  pois podem travar; nunca deixar pendurado indefinidamente.
- ATENCAO: $env:USERPROFILE aponta para C:\Users\angel (nao angelo.paolino).
  Sempre usar $env:USERPROFILE ou $env:OCI_CLI_CA_BUNDLE para montar caminhos;
  nunca hardcodar o nome do usuario.

## Autenticacao
- A chave API tem passphrase (execucao interativa travaria). Usar a sessao por token:
    perfil bgetrab-session, --auth security_token.
- Renovacao: ver protocolo "Verificacao de sessao OCI" acima.

## Dados sensiveis (LGPD)
- Arquivos do CAGED/RAIS contem dados pessoais (nome, CPF, PIS, CEP, nascimento).
- Mascarar valores desses campos nas respostas. Nao exfiltrar dados.

## Object Storage - arquivos grandes
- Buckets tem arquivos de varios GB. Para inspecionar, usar download por range
  ("--range bytes=inicio-fim") em vez de baixar o objeto inteiro.
- Namespace: grmu0oy5wsd9. Regiao: sa-saopaulo-1.

## Higiene
- Remover arquivos temporarios criados para inspecao ao final.