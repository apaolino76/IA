# Configuração de Agente Kiro CLI com acesso à Oracle Cloud Infrastructure (OCI)

Registro completo da sessão de configuração — passo a passo, erros encontrados e soluções.

Data: 2026-10-07
Usuário Windows de trabalho: `dataprev\angelo.paolino` (conta de admin `dataprev\sup233340` apareceu em alguns momentos e causou conflitos de perfil)

---

## Objetivo

Criar um agente customizado no Kiro CLI capaz de acessar e operar a conta OCI do usuário, de forma conservadora (leitura auto-aprovada; criação/alteração sob confirmação; `delete`/`terminate`/`remove` bloqueados).

## Visão geral da abordagem

O Kiro CLI **não possui conector nativo para OCI** (diferente da AWS). A estratégia adotada:

1. Instalar e autenticar o **OCI CLI** oficial na máquina (credenciais ficam em `~/.oci/config`).
2. Criar um agente Kiro que executa comandos `oci ...` via ferramenta `shell`.
3. Definir permissões: comandos de leitura auto-aprovados; ações destrutivas bloqueadas.

A autenticação fica na máquina do usuário; o agente apenas invoca o CLI já autenticado.

---

## Passo 1 — Criação do agente customizado

Arquivo criado em: `C:\Users\angelo.paolino\.kiro\agents\oci.json`

```json
{
  "name": "oci",
  "description": "Agente para operar a Oracle Cloud Infrastructure (OCI) via OCI CLI",
  "prompt": "Você é um assistente especializado em Oracle Cloud Infrastructure (OCI). Você opera a conta do usuário exclusivamente através do OCI CLI, invocando comandos 'oci ...' pela ferramenta shell. Sempre prefira comandos de leitura (list, get, describe) e peça confirmação antes de qualquer ação que crie, modifique ou apague recursos. Nunca exiba ou manuseie chaves privadas. Use '--output table' quando ajudar na legibilidade. Antes de operações destrutivas, explique o impacto e aguarde confirmação explícita.",
  "tools": [
    "read",
    "shell",
    "grep",
    "glob"
  ],
  "allowedTools": [
    "read",
    "grep",
    "glob"
  ],
  "toolsSettings": {
    "shell": {
      "allowedCommands": [
        "^oci .* list.*",
        "^oci .* get.*",
        "^oci .* describe.*",
        "^oci iam region list.*",
        "^oci --version$",
        "^oci setup .*"
      ],
      "deniedCommands": [
        "^oci .* delete.*",
        "^oci .* terminate.*",
        "^oci .* remove.*"
      ],
      "autoAllowReadonly": true,
      "denyByDefault": false
    }
  },
  "hooks": {
    "agentSpawn": [
      {
        "command": "oci --version"
      }
    ]
  },
  "welcomeMessage": "Agente OCI pronto. Comandos de leitura são auto-aprovados; ações de criação/alteração/remoção pedem confirmação."
}
```

Validação executada com sucesso:

```powershell
kiro-cli agent validate --path "C:\Users\angelo.paolino\.kiro\agents\oci.json"   # exit 0
kiro-cli agent list   # mostra "oci  Global  Agente para operar a Oracle Cloud Infrastructure (OCI) via OCI CLI"
```

---

## Passo 2 — Instalação do OCI CLI

### Tentativa 1 (script oficial em linha única) — FALHOU

Comando:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1'))"
```

Erro (erro.png): `New-ObjectSystem.Net.WebClient` não reconhecido.

**Causa:** ao copiar/colar, o espaço entre `New-Object` e `System.Net.WebClient` foi perdido.

### Tentativa 2 (script em 3 linhas) — FALHOU por outro motivo

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

Erro (erro2.png): o instalador rodou, mas falhou ao detectar o Python:
```
Ignoring Python registry entry because the Python executable could not be run:
C:\Program Files\WindowsApps\PythonSoftwareFoundation.Python.3.13...\python3.13.exe
Join-Path : Não existe uma unidade com o nome 'https'.
```

**Causa:** o Python padrão era o da **Microsoft Store** (3.13), que o instalador não consegue executar. Havia também um Python 3.12 "normal" (python.org) instalado.

### Solução adotada — instalação via pip no Python 3.12

Caminho do Python 3.12: `C:\Users\angelo.paolino\AppData\Local\Programs\Python\Python312\python.exe`

Observação: `py -3.12` falhava com "No suitable Python runtime found" no PowerShell do usuário, então usamos o executável pelo caminho completo:

```powershell
& "C:\Users\angelo.paolino\AppData\Local\Programs\Python\Python312\python.exe" -m pip install --upgrade pip
& "C:\Users\angelo.paolino\AppData\Local\Programs\Python\Python312\python.exe" -m pip install oci-cli
```

**Erro comum encontrado:** `No module named oci.__main__; 'oci' is a package and cannot be directly executed`
- Causa: `-m oci` tenta executar o *pacote*, não o programa.
- Correto: usar o executável `oci.exe`:
  ```powershell
  & "C:\Users\angelo.paolino\AppData\Local\Programs\Python\Python312\Scripts\oci.exe" --version
  ```
  Retornou a versão → instalação OK.

### Adicionar a pasta Scripts ao PATH

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Users\angelo.paolino\AppData\Local\Programs\Python\Python312\Scripts", "User")
```

Após fechar/reabrir o PowerShell, `oci --version` passou a funcionar diretamente.

---

## Passo 3 — Autenticação (oci setup config)

```powershell
oci setup config
```

Dados coletados no Console da OCI (https://cloud.oracle.com):
- User OCID (`ocid1.user.oc1..`)
- Tenancy OCID (`ocid1.tenancy.oc1..`)
- Region: `sa-saopaulo-1`
- Geração de par de chaves RSA (Y)

Conteúdo final do `config` (`C:\Users\angelo.paolino\.oci\config`):
```
[DEFAULT]
user=ocid1.user.oc1..aaaa... (ofuscado)
fingerprint=4b:54:...:65
key_file=C:\Users\angelo.paolino\.oci\oci_api_key.pem
tenancy=ocid1.tenancy.oc1..aaaa... (ofuscado)
region=sa-saopaulo-1
```

Chave pública registrada no Console: **My profile → API Keys → Add API Key → Paste a public key**.

---

## Passo 4 — Problemas de permissão / conta cruzada

### Sintoma: não era possível abrir/ler os arquivos .pem e config

- Notepad++ (erro4.png): "Você não tem permissão para abrir o arquivo".
- `Get-Content` e `icacls` também davam "Acesso negado" para `oci_api_key_public.pem`.

### Diagnóstico

A ACL dos arquivos em `.oci` estava **cruzada entre duas contas Windows**:
- `dataprev\angelo.paolino` — conta de trabalho / onde está o `.oci`.
- `dataprev\sup233340` — conta de admin/suporte.

`icacls` do `config` mostrava permissão apenas para `SISTEMA`, `Administradores` e `sup233340`. O `whoami` em `C:\WINDOWS\system32` retornava `dataprev\sup233340`, indicando que vários comandos rodaram sob a conta errada.

Isso explicou toda a cadeia de problemas da sessão:
- Python 3.12 que "sumia" (perfis diferentes).
- `.pem` com permissão negada.
- Chave que não assinava: `The provided key is not a private key, or the provided passphrase is incorrect`.
- `ERROR: Could not find config file at C:\Users\angelo.paolino\.oci\config` ao rodar sem `--config-file`.

### Confirmações úteis

- `OCI_CLI_CONFIG_FILE` estava vazia em todos os escopos (não era a causa).
- O conteúdo do `config` estava correto.
- `oci iam region list --config-file "...\config"` chegou a retornar as regiões (JSON).

### Solução recomendada (raiz)

Operar tudo sob **uma única conta** (a de uso diário). Passos:

```powershell
# Garantir sessão na conta correta
whoami
echo $env:USERPROFILE

# (Se necessário) abrir PowerShell como a conta de trabalho
runas /user:dataprev\angelo.paolino powershell

# Limpar e refazer o setup como dono legítimo
Remove-Item "C:\Users\angelo.paolino\.oci\*" -Force
oci setup config

# Registrar a nova chave pública no Console (API Keys → Add API Key)

# Corrigir permissões (recomendado pelo próprio CLI)
oci setup repair-file-permissions --file "C:\Users\angelo.paolino\.oci\config"
oci setup repair-file-permissions --file "C:\Users\angelo.paolino\.oci\oci_api_key.pem"
```

Comandos úteis relacionados:
- Suprimir aviso de permissões abertas:
  `$Env:OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING="True"`

---

## Passo 5 — Validação final (SUCESSO)

```powershell
oci iam compartment list --output table
```

Retornou a tabela de compartments reais da tenancy (com `defined-tags`, `time-created`, `CreatedBy=rodrigo.filgueira@dataprev.gov.br`, etc.). Como esse comando exige assinatura autenticada, confirma que config + chave privada + chave pública registrada estão corretos e casados.

---

## Como usar o agente no dia a dia

Trocar para o agente dentro do chat:
```
/agent swap oci
```

Ou iniciar o Kiro já nele:
```
kiro-cli chat --agent oci
```

Exemplos de pedidos em linguagem natural:
- "liste meus compartments"
- "mostre as instâncias de compute na região sa-saopaulo-1"
- "quais buckets de object storage existem no compartment X"

### Comportamento das permissões (config conservadora)
- Leitura (`list`, `get`, `describe`) → auto-aprovada.
- Criação/alteração → pede confirmação.
- `delete` / `terminate` / `remove` → sempre bloqueados.

### Ressalva de contexto de usuário
O `.oci/config` fica atrelado ao perfil do usuário Windows. Rode o Kiro CLI sob a **mesma conta** onde o `.oci/config` funcional está. Em caso de "Could not find config file", rode na conta correta ou passe explicitamente:
```
--config-file "C:\Users\angelo.paolino\.oci\config"
```

---

## Lições aprendidas

1. Comandos em linha única com `New-Object` quebram ao perder espaços no copiar/colar — prefira `Invoke-WebRequest` em múltiplas linhas.
2. O instalador oficial do OCI CLI não funciona com Python da Microsoft Store — use um Python do python.org (aqui, 3.12) ou `pip install oci-cli`.
3. `-m oci` não executa o CLI; o executável é `oci.exe` na pasta `Scripts`.
4. Misturar duas contas Windows (`angelo.paolino` e `sup233340`) foi a causa raiz dos erros de permissão e de assinatura — manter uma única conta resolve de forma definitiva.
