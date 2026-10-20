# Projeto OCI - BGETRAB

Arquivo de referencia com as informacoes do projeto BGETRAB na Oracle Cloud Infrastructure (OCI).
Uso: contexto para operar os recursos via OCI CLI.

> Observacao de seguranca: este arquivo contem apenas nomes e identificadores publicos (OCID, namespace, regiao). NAO armazenar chaves privadas, senhas, passphrases ou tokens.

Ultima atualizacao: 2026-10-17

## Tenancy

| Campo | Valor |
|-------|-------|
| OCID da Tenancy | ocid1.tenancy.oc1..aaaaaaaagtvmqgv42wqgqvzmzswuvcler4q7odlrqorcnhrob26q4ngkoanq |

## Regiao e Object Storage

| Campo | Valor |
|-------|-------|
| Regiao | sa-saopaulo-1 (Sao Paulo) |
| Namespace Object Storage | grmu0oy5wsd9 |

## Compartimentos

### Compartimento Pai

| Nome | OCID |
|------|------|
| RITM0117727_BGETRAB | ocid1.compartment.oc1..aaaaaaaaev4a5t43pzs7e6ftmkwuwqihqeu36karaqify6f7ljyfrdphjysa |

### Compartimentos Filhos

| Nome | Ambiente | OCID |
|------|----------|------|
| RITM0117727_BGETRAB_DEV | Desenvolvimento | ocid1.compartment.oc1..aaaaaaaarf5sfuq35slcn3nmbueowcfolzv53wrtnakif4573kemlupovpha |
| RITM0117727_BGETRAB_NETWORK | Rede | ocid1.compartment.oc1..aaaaaaaaezvo3zjwdaxaqrdr25r4wnax6vqoiocn5itkwgwuuc4efadlm52q |
| RITM0117727_BGETRAB_PROD | Producao | ocid1.compartment.oc1..aaaaaaaavo4ngdch3sixwt52ypziscvfxdsx3l2jwpkcrd3yxqd3ctx4silq |

## Buckets (Object Storage)

| Nome do Bucket | Compartimento | Ambiente | OCID |
|----------------|---------------|----------|------|
| bucket-bgetrab-dev | RITM0117727_BGETRAB_DEV | Desenvolvimento | ocid1.bucket.oc1.sa-saopaulo-1.aaaaaaaawvo43mxkeusjovwchylcknzftn4iu34lejeqspasply2wkzjkzxa |
| bucket-bgetrab-prod | RITM0117727_BGETRAB_PROD | Producao | ocid1.bucket.oc1.sa-saopaulo-1.aaaaaaaactmqak75cyq24ta5vkha3w3opvpqrepv5y3swillgshfkpk3vxgq |

## Ambiente / Configuracao do OCI CLI

| Item | Valor |
|------|-------|
| OCI CLI | versao 3.94.2 |
| Perfil chave API | DEFAULT |
| Perfil de sessao (token) | bgetrab-session |
| Arquivo de config | C:\Users\angelo.paolino\.oci\config |
| Chave privada | C:\Users\angelo.paolino\.oci\oci_api_key.pem (CRIPTOGRAFADA - exige passphrase) |

### Variaveis de ambiente persistidas (setx - valem em janelas novas)

| Variavel | Valor | Finalidade |
|----------|-------|------------|
| OCI_CLI_CA_BUNDLE | C:\Users\angelo.paolino\.oci\oci-ca-bundle.pem | Bundle de CA para comandos de servico (Kaspersky) |
| REQUESTS_CA_BUNDLE | C:\Users\angelo.paolino\.oci\oci-ca-bundle.pem | Bundle de CA para chamadas requests (session refresh/authenticate) |
| SSL_CERT_FILE | C:\Users\angelo.paolino\.oci\oci-ca-bundle.pem | Bundle de CA para camada ssl do Python |
| OCI_CLI_AUTH | security_token | Usa autenticacao por token de sessao por padrao |
| OCI_CLI_PROFILE | bgetrab-session | Usa o perfil de sessao por padrao |

### Observacoes importantes de ambiente

1. Interceptacao TLS do Kaspersky: o antivirus faz inspecao HTTPS e re-assina os
   certificados. O OCI CLI (Python/certifi) nao confia na CA do Kaspersky por padrao,
   o que fazia os comandos travarem ou falharem com CERTIFICATE_VERIFY_FAILED.
   Solucao: bundle de CA combinado + 3 variaveis apontando para ele.
   - CA Kaspersky exportada: C:\Users\angelo.paolino\.oci\kaspersky-ca.pem
   - Bundle combinado (certifi + Kaspersky): C:\Users\angelo.paolino\.oci\oci-ca-bundle.pem
   - Thumbprint da CA Kaspersky: 8481199B42DFEF3EBB86733E33E5CAA8337BD850
   - IMPORTANTE: os comandos "oci session refresh/authenticate" acessam
     auth.sa-saopaulo-1.oraclecloud.com e NAO respeitam OCI_CLI_CA_BUNDLE.
     Por isso definimos REQUESTS_CA_BUNDLE e SSL_CERT_FILE, que cobrem esse caso.

2. Autenticacao por sessao (token): evita digitar a passphrase a cada comando.
   O perfil bgetrab-session usa token de sessao (security_token_file no config).
   - Criar/renovar login (abre o navegador):
         oci session authenticate --region sa-saopaulo-1
   - Renovar o token enquanto valido:
         oci session refresh --profile bgetrab-session
   - O token EXPIRA; ao expirar, rodar o authenticate novamente.
   - Apos aplicar setx, abrir uma JANELA NOVA do terminal para as variaveis valerem.

## Comandos uteis de referencia (OCI CLI)

Com as variaveis persistidas (janela nova), nao e preciso passar --auth/--profile/--cert-bundle.
Em janela atual (antes do setx fazer efeito) ou para ser explicito, use:
    --profile bgetrab-session --auth security_token

Confirmar namespace de Object Storage:
    oci os ns get

Listar compartimentos do projeto:
    oci iam compartment list --compartment-id-in-subtree true --all --query "data[?contains(name, 'BGETRAB')].{Nome:name, OCID:id}" --output table

Listar buckets de um compartimento:
    oci os bucket list --namespace grmu0oy5wsd9 --compartment-id <OCID_DO_COMPARTIMENTO> --output table

Listar TODOS os objetos de um bucket (com paginacao automatica):
    oci os object list --namespace grmu0oy5wsd9 --bucket-name bucket-bgetrab-prod --all --output table

Obter detalhes de um bucket:
    oci os bucket get --namespace grmu0oy5wsd9 --bucket-name bucket-bgetrab-prod --output table

Ler apenas o inicio de um objeto grande (ex.: cabecalho), via range de bytes:
    oci os object get --namespace grmu0oy5wsd9 --bucket-name bucket-bgetrab-prod --name "FATOS_CAGED_TRABS_AJUSTADO_2002.csv" --file inicio.csv --range "bytes=0-131071"

## Schemas de arquivos conhecidos

### FATOS_CAGED_TRABS_AJUSTADO_2002.csv (bucket-bgetrab-prod)

- Separador: ponto-e-virgula (;)
- Total de campos: 50
- Contem dados pessoais sensiveis: NM_TRABALHADOR, NU_CPF_TRABALHADOR,
  NU_PIS_TRABALHADOR, NU_CEP, DT_NASCIMENTO. Tratar com cuidado (LGPD).

Campos (na ordem):
 1. ID_SEQ_FATOS_CAGED_TRAB_AJUS
 2. DT_COMPETENCIA
 3. DT_COMPETENCIA_MOVIMENTACAO
 4. CS_SITUACAO_CBO
 5. CS_TIPO_ACERTO
 6. CS_TIPO_DOC_IDENT_ESTAB
 7. DT_ADMISSAO
 8. DT_DIA_MOVIMENTACAO
 9. DT_NASCIMENTO
10. IN_APRENDIZ
11. IN_DEFICIENCIA
12. IN_FORA_PRAZO
13. IN_INFORMADO_COMPETENCIA
14. IN_VERSAO_CNAE
15. NM_TRABALHADOR
16. NU_CEP
17. NU_CPF_TRABALHADOR
18. NU_DOC_IDENT_ESTAB
19. NU_IDADE_TRABALHADOR
20. NU_PIS_TRABALHADOR
21. NU_TEMPO_EMPREGO
22. QT_HORAS_CONTRATUAIS_SEMANA
23. VL_SALARIO_MENSAL_CONTRATUAL
24. VL_SALARIO_MENSAL_CONTR_SM
25. VL_SALARIO_MENSAL_DECLARADO
26. VL_SALDO_MOVIMENTACAO
27. ID_SEQ_ETNIA
28. ID_SEQ_CNAE_2003
29. ID_SEQ_CBO_94
30. ID_SEQ_CBO
31. ID_SEQ_GEOGRAFICA
32. ID_SEQ_ESCOLARIDADE
33. ID_SEQ_TIPO_ESTAB
34. ID_SEQ_CNAE_2_0
35. ID_SEQ_SEXO
36. ID_SEQ_CEP
37. ID_SEQ_ESTABELECIMENTO
38. ID_SEQ_TIPO_ESTAB_NOVO
39. ID_SEQ_CNAE_80
40. ID_REG_ADM_DF
41. ID_TIPO_DEFICIENCIA
42. ID_FAIXA_TEMPO_EMPREGO
43. ID_TIPO_MOVIMENTACAO
44. ID_SEQ_TAMANHO_EMPRESA_JAN
45. ID_DIVISAO_MUNICIPAL_DISTRITO
46. ID_SEQ_TAMANHO_EMPR_PRIM_DIA
47. ID_DIVISAO_MUNICIPAL_BAIRRO
48. IN_TRAB_INTERMITENTE
49. IN_TRAB_PARCIAL
50. IN_TRAB_TELETRABALHO

## Data Integration - Producao (coletado em 2026-10-08)

### Workspace

| Campo | Valor |
|-------|-------|
| Nome | Workspace_BGETRAB_PROD |
| OCID | ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq |
| Estado | ACTIVE |

### Application

| Campo | Valor |
|-------|-------|
| Nome | APL_BGETRAB_2 |
| OCID | ocid1.disapplication.oc1.sa-saopaulo-1.amaaaaaa2n4fqhiabudgqwm7ovyz74lj65byrup2pp4ekrqiefmn6zk2t7ka |
| Key | dbd6181d-c908-43c0-824e-6f78ee385750 |
| Estado | ACTIVE |
| Versao da aplicacao | 58 |

### Resumo por tipo

| Tipo | Quantidade |
|------|------------|
| INTEGRATION_TASK | 66 |
| PIPELINE_TASK | 4 |
| SQL_TASK | 5 |
| TOTAL | 75 |

### Tasks publicadas (nome / tipo / caminho / acao / versao)

| Nome | Tipo | Caminho | Acao | Versao |
|------|------|---------|------|--------|
| TASK_DF_AFAST_ESOCIAL_CSV | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DF_AFAST_ESOCIAL_CSV | UPDATED | 1 |
| TASK_DF_DI_ANO_RAIS_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DF_DI_ANO_RAIS_DEV | UPDATED | 11 |
| TASK_DF_DI_FLAGS_RAIS_ESTAB_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DF_DI_FLAGS_RAIS_ESTAB_DEV | CREATED | 1 |
| TASK_DF_DIM_CNAE_80 | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DIM_CNAE_80 | UPDATED | 2 |
| TASK_DF_DIM_DIVISOES_MUNICIPAIS | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DIM_DIVISOES_MUNICIPAIS | CREATED | 1 |
| TASK_DF_DIM_FAIXAS_TEMPO_EMPREGO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DIM_FAIXAS_TEMPO_EMPREGO | UPDATED | 1 |
| TASK_DF_DIM_REGIS_ADM_DF | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DIM_REGIS_ADM_DF | CREATED | 1 |
| TASK_DF_DIM_TIPOS_DEFICIENCIA | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DIM_TIPOS_DEFICIENCIA | CREATED | 1 |
| TASK_DF_DW_CBO_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DF_DW_CBO_DEV | UPDATED | 6 |
| TASK_DF_DW_ESCOLARIDADE_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DW_ESCOLARIDADE_MTE | CREATED | 1 |
| TASK_DF_DW_ESTABELECIMENTOS_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DW_ESTABELECIMENTOS_MTE | UPDATED | 2 |
| TASK_DF_DW_ETNIAS_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DW_ETNIAS_MTE | CREATED | 1 |
| TASK_DF_DW_TIPOS_ESTAB_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_DW_TIPOS_ESTAB_MTE | CREATED | 1 |
| TASK_DF_FT_RAIS_DECL_ANUARIO | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DF_FT_RAIS_DECL_ANUARIO | UPDATED | 18 |
| TASK_DF_MV_DW_CNAE_2003 | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_MV_DW_CNAE_2003 | UPDATED | 2 |
| TASK_DF_MV_DW_SEXOS | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DF_MV_DW_SEXOS | UPDATED | 2 |
| TASK_DI_CATEGORIAS_TRABALHO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_CATEGORIAS_TRABALHO | CREATED | 1 |
| TASK_DI_CAUSAS_AFASTAMENTOS | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_CAUSAS_AFASTAMENTOS | CREATED | 2 |
| TASK_DI_CNAE_2_0_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_CNAE_2_0_DEV | UPDATED | 9 |
| TASK_DI_CNAE_80_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_CNAE_80_DEV | UPDATED | 7 |
| TASK_DI_ESCOLARIDADE_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_ESCOLARIDADE_DEV | CREATED | 1 |
| TASK_DI_ESCOLARIDADE_DEV_Task 20260408_162816 | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_ESCOLARIDADE_DEV_Task+20260408_162816 | UPDATED | 6 |
| TASK_DI_ETNIAS_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_ETNIAS_MTE | CREATED | 1 |
| TASK_DI_FAIXAS_ETARIAS_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FAIXAS_ETARIAS_DEV | UPDATED | 6 |
| TASK_DI_FAIXAS_ETARIAS_MTE_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_FAIXAS_ETARIAS_MTE_DEV | CREATED | 1 |
| TASK_DI_FAIXAS_HORA_CONTRATUAL | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FAIXAS_HORA_CONTRATUAL | CREATED | 3 |
| TASK_DI_FAIXAS_SALARIAIS_MTE_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FAIXAS_SALARIAIS_MTE_DEV | UPDATED | 3 |
| TASK_DI_FAIXAS_TEMPO_EMPREGO | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FAIXAS_TEMPO_EMPREGO | CREATED | 2 |
| TASK_DI_FLAGS_RAIS_ESTAB_DECLARACAO | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FLAGS_RAIS_ESTAB_DECLARACAO | CREATED | 1 |
| TASK_DI_FLAGS_REGIME_TRABALHO_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FLAGS_REGIME_TRABALHO_DEV | UPDATED | 2 |
| TASK_DI_FLAGS_VINCULOS | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_FLAGS_VINCULOS | UPDATED | 2 |
| TASK_DI_INDICADORES_DEFICIENCIA | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_INDICADORES_DEFICIENCIA | CREATED | 1 |
| TASK_DI_MESES | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_MESES | CREATED | 1 |
| TASK_DI_MOTIVO_AFASTAMENTO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_MOTIVO_AFASTAMENTO | UPDATED | 4 |
| TASK_DI_MOTIVOS_DESLIGAMENTO_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_MOTIVOS_DESLIGAMENTO_DEV | UPDATED | 5 |
| TASK_DI_NATUREZA_JURIDICA_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_NATUREZA_JURIDICA_DEV | CREATED | 1 |
| TASK_DI_NATUREZA_JURIDICA_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_NATUREZA_JURIDICA_DEV | UPDATED | 3 |
| TASK_DI_PAISES_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_PAISES_DEV | UPDATED | 2 |
| TASK_DI_PORTE_ESTABELECIMENTO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_PORTE_ESTABELECIMENTO | CREATED | 1 |
| TASK_DI_REGIAO_GEOGRAFICA_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_REGIAO_GEOGRAFICA_DEV | UPDATED | 13 |
| TASK_DI_REGIAO_GEOGRAFICA_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_REGIAO_GEOGRAFICA_DEV | CREATED | 1 |
| TASK_DI_SEXOS_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_SEXOS_DEV | UPDATED | 5 |
| TASK_DI_TAMANHO_EMPRESAS_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_TAMANHO_EMPRESAS_DEV | UPDATED | 4 |
| TASK_DI_TIPO_EMPREGADOR | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_TIPO_EMPREGADOR | CREATED | 1 |
| TASK_DI_TIPO_INSCRICAO_EMPREGADOR | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_TIPO_INSCRICAO_EMPREGADOR | CREATED | 1 |
| TASK_DI_TIPO_REGIME_TRABALHISTA | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DI_TIPO_REGIME_TRABALHISTA | CREATED | 1 |
| TASK_DI_TIPOS_ADMISSAO | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_TIPOS_ADMISSAO | UPDATED | 2 |
| TASK_DI_TIPOS_DEFICIENCIA_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_TIPOS_DEFICIENCIA_DEV | UPDATED | 7 |
| TASK_DI_TIPOS_ESTAB_MTE_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_TIPOS_ESTAB_MTE_DEV | UPDATED | 4 |
| TASK_DI_TIPOS_VINCULOS_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DI_TIPOS_VINCULOS_DEV | UPDATED | 6 |
| TASK_DIM_TIPOS_MOVIMENTACOES | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DIM_TIPOS_MOVIMENTACOES | CREATED | 1 |
| TASK_DW_CBO_94_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DW_CBO_94_DEV | UPDATED | 4 |
| TASK_DW_CNAE_2003 | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_DW_CNAE_2003 | UPDATED | 1 |
| TASK_DW_TAMANHO_EMPRESAS_MTE | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_DW_TAMANHO_EMPRESAS_MTE | CREATED | 1 |
| TASK_DW_TEMPO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_DW_TEMPO | CREATED | 1 |
| TASK_FATOS_CAGED_TRABS_AJUSTADO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_FATOS_CAGED_TRABS_AJUSTADO | UPDATED | 7 |
| TASK_FT_INDICE_GINI | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_FT_INDICE_GINI | UPDATED | 11 |
| TASK_FT_INDICE_GINI_SEXO | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_FT_INDICE_GINI_SEXO | UPDATED | 3 |
| TASK_FT_RAIS_DECL_ANUARIO_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_FT_RAIS_DECL_ANUARIO_DEV | UPDATED | 5 |
| TASK_FT_RAIS_VINCULOS_ANUARIO_DEV | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_FT_RAIS_VINCULOS_ANUARIO_DEV | UPDATED | 11 |
| TASK_MV_DW_CBO | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_MV_DW_CBO | UPDATED | 2 |
| TASK_MV_DW_CBO_94 | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_MV_DW_CBO_94 | CREATED | 1 |
| TASK_MV_DW_CEP | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_MV_DW_CEP | UPDATED | 2 |
| TASK_MV_DW_CNAE_2_0 | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_MV_DW_CNAE_2_0 | CREATED | 1 |
| TASK_MV_DW_LOCALIZACOES_GEOGRAFICAS | INTEGRATION_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_MV_DW_LOCALIZACOES_GEOGRAFICAS | CREATED | 1 |
| TASK_TAB_ANALITICA | INTEGRATION_TASK | /Project_BGETRAB_DEV/TASK_TAB_ANALITICA | UPDATED | 26 |
| PIPELINE_TASK_FT_TRABS_AJUST_0 | PIPELINE_TASK | /Project_BGETRAB_DEV/DWCAGED/PIPELINE_TASK_FT_TRABS_AJUST_0 | UPDATED | 3 |
| PipelineTask_Carga_FT_RAIS_VINCULOS_ANUARIO | PIPELINE_TASK | /Project_BGETRAB_DEV/PipelineTask_Carga_FT_RAIS_VINCULOS_ANUARIO | UPDATED | 3 |
| TASK_PIPELINE_CARGA_DIMENSOES | PIPELINE_TASK | /Project_BGETRAB_DEV/DWESOCIAL/TASK_PIPELINE_CARGA_DIMENSOES | CREATED | 1 |
| TASK_PIPELINE_CARGA_DIMENSOES | PIPELINE_TASK | /Project_BGETRAB_DEV/DWCAGED/TASK_PIPELINE_CARGA_DIMENSOES | CREATED | 1 |
| SQL_TASK_FT_RAIS_DECLARACOES_ANUARIO | SQL_TASK | /Project_BGETRAB_DEV/SQL_TASK_FT_RAIS_DECLARACOES_ANUARIO | CREATED | 1 |
| SQL_TASK_PRC_APAGA_DI_ANO_RAIS | SQL_TASK | /Project_BGETRAB_DEV/SQL_TASK_PRC_APAGA_DI_ANO_RAIS | CREATED | 1 |
| SQL_TASK_REFRESH_MV | SQL_TASK | /Project_BGETRAB_DEV/SQL_TASK_REFRESH_MV | CREATED | 1 |
| SQL_Task_TRUNCATE_FT_RAIS_VINCULOS_ANUARIO | SQL_TASK | /Project_BGETRAB_DEV/SQL_Task_TRUNCATE_FT_RAIS_VINCULOS_ANUARIO | CREATED | 1 |
| SQLTASK_APAGA_ANO_RAIS | SQL_TASK | /Project_BGETRAB_DEV/SQLTASK_APAGA_ANO_RAIS | CREATED | 1 |


## Incidente / Correcao - TASK_FATOS_CAGED_TRABS_AJUSTADO (ORA-01400)

Registrado em: 2026-10-08

### Contexto
- Task: TASK_FATOS_CAGED_TRABS_AJUSTADO (application APL_BGETRAB_2, producao)
- Data flow (design/DEV): DF_FATOS_CAGED_TRABS_AJUSTADO
  - Workspace DEV: ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yauzbm5cvf2woep5yral3xu5ynejocp4zuabclvfgt6lpa
  - Data flow key: b18f9c66-5751-4c0b-9ce5-2102f60095b7
- Arquivo de entrada: FATOS_CAGED_TRABS_AJUSTADO_2002.csv (bucket-bgetrab-prod)

### Erro observado (erro6.png)
    error processing column VL_SALARIO_MENSAL_DECLARADO in row 3601 for datafile...
    ORA-01400: cannot insert NULL into (VL_SALARIO_MENSAL_DECLARADO)

### Fatos verificados
- Valor na origem, linha 3601, campo VL_SALARIO_MENSAL_DECLARADO = 0.00 (nao vazio).
- Formato de leitura do data flow esta CORRETO:
      delimiter = ";"  | encoding = UTF-8 | has-header = true | quote-character = " | escape = \
- A mensagem "Terminated by ','/Enclosed by '\"'" do print e do control file do
  loader no ADW (SQL*Loader), NAO e a config de leitura do CSV. Logo, delimitador
  NAO e a causa.
- Expressao atual no campo derivado EXP_VL_SALARIO_MENSAL_DECLARADO:
      CAST(EXPRESSION_1.ARQ_FATOS_CAGED_TRABS_AJUSTADO.VL_SALARIO_MENSAL_DECLARADO AS NUMERIC(10,2))
- Mapeamento direto (DIRECT_NAMED_FIELD_MAP) para a coluna de destino NOT NULL no ADW.

### Causa raiz
O CAST(... AS NUMERIC(10,2)) retorna NULL (silenciosamente) para a celula da linha 3601,
provavelmente por caractere invisivel/residual (espaco, \r, BOM) junto do valor 0.00.
Como a coluna de destino no ADW e NOT NULL, dispara ORA-01400.
Obs.: salario declarado 0.00 e valor LEGITIMO no CAGED (ex.: certos tipos de movimentacao).

### Correcao recomendada
Na expressao do campo derivado EXP_VL_SALARIO_MENSAL_DECLARADO, trocar o CAST direto por:
      NVL(CAST(TRIM(EXPRESSION_1.ARQ_FATOS_CAGED_TRABS_AJUSTADO.VL_SALARIO_MENSAL_DECLARADO) AS NUMERIC(10,2)), 0)
- TRIM remove espacos/\r residuais (trata o caractere invisivel).
- NVL(..., 0) garante que nunca grava NULL no destino NOT NULL (0.00 e valido).
- Aplicar o mesmo padrao defensivo nas demais colunas VL_* para evitar o mesmo erro
  em outras linhas/anos.

### Passos de aplicacao
1. Editar o data flow DF_FATOS_CAGED_TRABS_AJUSTADO em DEV (Workspace_BGETRAB_DEV).
2. Ajustar a(s) expressao(oes) conforme acima.
3. Validar o data flow.
4. Re-publicar a aplicacao APL_BGETRAB_2 em producao.
5. Reexecutar a TASK_FATOS_CAGED_TRABS_AJUSTADO para o arquivo de 2002.

### Alternativa (menos recomendada)
Alterar a coluna no ADW para aceitar NULL ou DEFAULT 0 - somente se a regra de negocio
permitir e com validacao, pois mexe no schema de producao.

### ATUALIZACAO (varredura de dados) - causa confirmada

Varredura do arquivo FATOS_CAGED_TRABS_AJUSTADO_2002.csv confirmou a causa real:

- O campo VL_SALARIO_MENSAL_DECLARADO vem VAZIO ("") a partir da linha de dados 3601
  (linha 3602 do arquivo, contando o header). Transicao exata:
      linha-arquivo 3601: [0.00]   (ultima preenchida)
      linha-arquivo 3602: []       (vazio a partir daqui)
- So nos primeiros 16 MB foram encontradas ~33.000 linhas com esse campo vazio.
- O offset do loader bate: ADW "row 3601" = linha de dados 3601 = linha 3602 do arquivo.

Conclusao: NAO e caractere invisivel nem falha de CAST do valor 0.00.
E campo genuinamente VAZIO na origem -> CAST('' AS NUMERIC) = NULL -> coluna NOT NULL no ADW -> ORA-01400.
(A linha 3601 inspecionada antes, com 0.00, era a ultima linha boa antes do bloco vazio.)

Correcao confirmada:
    NVL(CAST(TRIM(... .VL_SALARIO_MENSAL_DECLARADO) AS NUMERIC(10,2)), 0)
  Resolve todas as linhas de uma vez.

DECISAO DE NEGOCIO (importante):
- Usar NVL(...,0) define que "salario declarado ausente" = 0.00.
- Se o correto for tratar como DESCONHECIDO (e nao zero), a solucao e permitir NULL
  na coluna do ADW (tornar NULLABLE), em vez de forcar 0. Decisao da area de negocio,
  pois altera o significado nos relatorios.

### CONFIRMACAO POR DADOS REAIS (OCI, bucket-bgetrab-prod) - 2026-10-13

Varredura via OCI CLI (download por range dos primeiros 2 MB) do objeto
FATOS_CAGED_TRABS_AJUSTADO_2002.csv (bucket-bgetrab-prod) confirmou in loco:
- VL_SALARIO_MENSAL_DECLARADO esta na posicao 25 (indice 24) - bate com o schema.
- Transicao preenchido -> vazio exatamente na linha de dados #3601:
    linha 3600: [0.00]  (ultima preenchida)
    linha 3601: []      (vazio a partir daqui)
- So no trecho de 2 MB (~9.400 linhas) ja ha 2.500 linhas com o campo vazio.
- Todas as linhas tem 50 campos: NAO e desalinhamento nem delimitador errado;
  o valor vem genuinamente VAZIO na origem.
- Casa com o loader do ADW ("row 3601"): CAST('' AS NUMERIC)=NULL -> NOT NULL -> ORA-01400.

### CORRECAO NA ORIGEM (SAP BODS) - recomendada (resolve todos os anos)

Job: J_BGE_ETL_001_ARQS_DWCAGED_v1 (pacote P_BGE_ETL_001_MIGRA_CAGED_V1.atl).
Data flows que GERAM o CSV: DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST e _0.
Query que alimenta o LOAD FILE do CSV: QRY_TRATAMENTO.

Causa de o nvl(...,0) atual NAO bastar: ele so troca NULL de banco; nao cobre
string vazia/espacos, e ao concatenar o decimal na linha de texto do CSV o valor
"indefinido" sai como campo vazio (;;). Correcao: normalizar como texto, validar e
forcar formato numerico na escrita.

Expressao para VL_SALARIO_MENSAL_DECLARADO (campo que causou o erro):
    ifthenelse( is_valid_decimal( ltrim_blanks(rtrim_blanks(cast(QRY_DADOS.VL_SALARIO_MENSAL_DECLARADO, 'varchar(20)'))), '#.##') = 1,
                to_decimal( ltrim_blanks(rtrim_blanks(cast(QRY_DADOS.VL_SALARIO_MENSAL_DECLARADO, 'varchar(20)'))), '.', '', 2),
                0)

Padroes para as demais colunas numericas (aplicar em todas, pois o destino ADW e
quase todo NOT NULL - blinda os outros anos 1996-2019):
- INTEIRO (default 0):
    ifthenelse( is_valid_int( ltrim_blanks(rtrim_blanks(cast(QRY_DADOS.<COL>, 'varchar(20)'))), '###') = 1,
                to_decimal( ltrim_blanks(rtrim_blanks(cast(QRY_DADOS.<COL>, 'varchar(20)'))), '.', '', 0), 0)
- DECIMAL 2 casas (default 0): usar '#.##' e to_decimal(..., 2).
- DECIMAL 1 casa (NU_TEMPO_EMPREGO): usar '#.#' e to_decimal(..., 1).
- Defaults especiais ja usados no job: CS_TIPO_ACERTO=9, CS_TIPO_DOC_IDENT_ESTAB=9,
  DT_ADMISSAO=11991101, DT_NASCIMENTO=1199 (mantendo substr(ano)||'0000').
- VARCHAR sensiveis: envolver com nvl (NM_TRABALHADOR->'NAO INFORMADO';
  NU_CPF/NU_PIS/NU_DOC_IDENT_ESTAB->'0').

Alternativa se is_valid_decimal nao existir na instalacao:
    to_decimal( nvl( ltrim_blanks(rtrim_blanks(cast(QRY_DADOS.VL_SALARIO_MENSAL_DECLARADO,'varchar(20)'))), '0'), '.', '', 2)

Reforco: no datastore de saida ARQ_FT_TRAB_AJUSTADO, garantir que nao ha "NULL
indicator" configurado como string vazia para colunas numericas.

Passos: editar QRY_TRATAMENTO nos dois data flows -> validar -> regerar CSV do ano
problematico (testar 2002, conferir 0.00 nas linhas ~3600-3610) -> subir ao bucket
-> reexecutar a TASK_FATOS_CAGED_TRABS_AJUSTADO. Com a origem corrigida, o NVL
defensivo no lado OCI deixa de ser necessario (embora manter os dois nao prejudique).

### COPIA CORRIGIDA DO ATL GERADA (rastreabilidade) - 2026-10-13

Arquivo gerado (original preservado):
  C:\projetos\bgetrab\pacotes\etl\P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl

Escopo: duas views que alimentam os CSVs do fato ajustado.
  - DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST   -> view QRY_TRATAMENTO   (origem QRY_DADOS)
  - DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST_0 -> view QRY_ANONIMIZACAO (origem QRY_TRATAMENTO; ultima antes do LOAD FILE)
  - DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST_ATESTA: NAO alterado (nao gera CSV).

O que foi alterado: 40 colunas numericas por view (INT, DECIMAL 2 casas, DECIMAL 1 casa),
substituidas em 2 pontos cada (definicao ui_mapping_text + SELECT) = 80 trocas por view.
Padroes aplicados:
  - INT:     ifthenelse( is_valid_int( ltrim_blanks(rtrim_blanks(cast(<PREFIXO>.<COL>, 'varchar(20)'))), '###') = 1,
                         to_decimal( ..., '.', '', 0), <default>)
             defaults do proprio job (0; CS_TIPO_ACERTO = 9).
  - DECIMAL: ifthenelse( is_valid_decimal( ..., '#.##'/'#.#') = 1, to_decimal( ..., casas), 0)
             inclui o campo critico VL_SALARIO_MENSAL_DECLARADO (2 casas).
No header (ui_mapping_text) as aspas internas vao escapadas (\'), no SELECT vao normais (') -
igual ao padrao do proprio arquivo.

Metodo (seguro): parsing estrutural do SELECT (divisao em expressoes top-level respeitando
parenteses/aspas, troca por POSICAO de coluna) - evita colisao de substrings tipo
ID_SEQ_CBO vs ID_SEQ_CBO_94. Validacoes OK: linhas 3139=3139, parenteses balanceados
(4856/4856), nenhuma coluna perdida, escapes conferidos. Scripts temporarios removidos.

Camadas intermediarias preservadas (QRY_TRATAMENTO_1 no DF1 e QRY_TRATAMENTO no DF2) -
o resultado final e reprocessado pela view defensiva.

Pendente (acao manual, alto impacto - NAO feito pelo assistente):
  1. Abrir o _corrigido.atl no BODS Designer e rodar Validate All.
     - Se is_valid_decimal nao existir na instalacao, usar a alternativa:
       to_decimal( nvl( ltrim_blanks(rtrim_blanks(cast(<PREFIXO>.<COL>,'varchar(20)'))), '0'), '.', '', 2)
  2. Reimportar -> validar -> testar ano 2002 (conferir 0.00 nas linhas ~3600-3610 do CSV).
  3. Republicar e regerar os CSVs; depois a TASK_FATOS_CAGED_TRABS_AJUSTADO carrega sem ORA-01400.

### REEXECUCAO DA TASK PARA 2002 (producao) - 2026-10-13

Apos a correcao na origem (BODS) e a regeracao do CSV, a TASK_FATOS_CAGED_TRABS_AJUSTADO
foi reexecutada em producao com o arquivo de 2002.

Verificacao previa (OCI CLI, leitura): o objeto FATOS_CAGED_TRABS_AJUSTADO_2002.csv foi
regerado (last-modified 2026-10-13 19:13; content-length ~4,82 GB, antes ~4,76 GB).
Amostra dos primeiros 2 MB: 0 campos vazios em VL_SALARIO_MENSAL_DECLARADO; faixa das
linhas 3598-3605 todas com 0.00 (antes a transicao vazio comecava na linha 3601).

Run disparada:
  - Nome: TASK_FATOS_CAGED_TRABS_AJUSTADO_1791920252260_15095754
  - Task-run key: eea3fe54-a028-4be7-bfac-83ebeec917ac
  - Status inicial: NOT_STARTED -> RUNNING (sem erro no inicio)
  - Parametro PARAMETER_ARQ -> FATOS_CAGED_TRABS_AJUSTADO_2002.csv (CSV ja corrigido)
  - Parametro PARAM_ANO     -> FATOS_CAGED_TRABS_AJUSTADO_199601.csv (default das runs)

Observacao: nenhuma das 188 runs historicas usou _2002.csv; todas usavam _2007.csv
(PARAMETER_ARQ) e _199601.csv (PARAM_ANO). A run de 2002 foi montada trocando o
entity.key do PARAMETER_ARQ.

### COMO REEXECUTAR A TASK VIA OCI CLI (reuso)

Identificadores:
  - workspace-id   : ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq
  - application-key: dbd6181d-c908-43c0-824e-6f78ee385750
  - aggregator-key da task (TASK_FATOS_CAGED_TRABS_AJUSTADO): 2a76bf00-06e4-4587-b8ff-357c40af75d5
  - dataref do bucket-bgetrab-prod: 1860a05b-a542-4124-bbdc-71b37e6653e7

Arquivos de parametro mantidos para reuso (NAO versionar se contiverem algo sensivel; aqui so ha OCIDs/keys):
  - C:\projetos\bgetrab-agente\cfg_provider_2002.json  (bindings PARAMETER_ARQ + PARAM_ANO)
  - C:\projetos\bgetrab-agente\reg_meta_2002.json      ({"aggregatorKey":"2a76bf00-06e4-4587-b8ff-357c40af75d5"})

Comando:
  oci data-integration task-run create ^
    --workspace-id <workspace-id> ^
    --application-key dbd6181d-c908-43c0-824e-6f78ee385750 ^
    --config-provider file://C:/projetos/bgetrab-agente/cfg_provider_2002.json ^
    --registry-metadata file://C:/projetos/bgetrab-agente/reg_meta_2002.json ^
    --name "TASK_FATOS_CAGED_TRABS_AJUSTADO" ^
    --profile bgetrab-session --auth security_token

Para outro ano: copiar o cfg_provider_2002.json para cfg_provider_<ANO>.json e trocar no
entity.key do PARAMETER_ARQ o "..._2002.csv" pelo ano desejado.

ARMADILHAS (lições aprendidas):
  - Os JSONs de --config-provider/--registry-metadata devem ser UTF-8 SEM BOM.
    Com BOM, o CLI falha com "Parameter 'config_provider' must be in JSON format."
    (Set-Content -Encoding UTF8 do PowerShell 5 grava COM BOM; usar
    [System.IO.File]::WriteAllText(path, texto, (New-Object System.Text.UTF8Encoding($false))).)
  - Preferir --config-provider via file:// (JSON inline no shell quebra em ; , " e \).
  - Rodar o "oci" dentro de Start-Job com Wait-Job -Timeout; evitar --query com aspas
    dentro do Start-Job (o PowerShell desmonta a string).

Status: consultar com
  oci data-integration task-run get --workspace-id <ws> --application-key <appkey> --task-run-key eea3fe54-a028-4be7-bfac-83ebeec917ac

### LGPD - PII do FATOS_CAGED_TRABS_AJUSTADO (constatacao 2026-10-13)

Analise da amostra do CSV 2002 em producao (sem exibir valores em claro), 1.153 linhas:
  - NM_TRABALHADOR      : MASCARADO  (formato X******X: 1a e ultima letra)
  - NU_CPF_TRABALHADOR  : MASCARADO  (ddd*******d: 3 primeiros + ultimo)
  - DT_NASCIMENTO       : GENERALIZADO (aaaa0000: so o ano)
  - NU_PIS_TRABALHADOR  : EM CLARO (11 digitos) <-- RISCO: identificador direto
  - NU_CEP              : EM CLARO (numerico)   <-- risco por cruzamento

Conclusao: o dataset NAO esta anonimizado; esta pseudonimizado/parcialmente mascarado.
O PIS em claro praticamente anula o mascaramento do CPF (reidentificacao trivial via PIS).

### Correcao de PII aplicada na copia corrigida do ATL (PIS)

No arquivo P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl, o NU_PIS_TRABALHADOR passou a ser
mascarado com o MESMO padrao do CPF, nas duas views que alimentam os CSVs:
  - DF1 QRY_TRATAMENTO  (prefixo QRY_DADOS)
  - DF2 QRY_ANONIMIZACAO (prefixo QRY_TRATAMENTO)
Expressao (exemplo DF1):
  substr(QRY_DADOS.NU_PIS_TRABALHADOR, 1, 3) || '*******' || substr(QRY_DADOS.NU_PIS_TRABALHADOR, length(QRY_DADOS.NU_PIS_TRABALHADOR), 1)
Aplicado em header (aspas escapadas \') e SELECT (aspas normais). Validado: sem duplicacao
(substr(substr=0), parenteses balanceados, sem BOM.

PENDENTE (decisao de negocio/privacidade, NAO aplicado):
  - NU_CEP continua em claro. Avaliar generalizar (ex.: 5 primeiros digitos ou faixa regional).
  - A copia corrigida ainda NAO foi reimportada/republicada no BODS; a mascara do PIS so
    tera efeito nos CSVs apos regerar os arquivos. Os CSVs ja em producao (incl. 2002) mantem
    o PIS em claro ate serem regerados.

### 2a CAUSA DO ERRO - NU_IDADE_TRABALHADOR NULL (run 2002) - 2026-10-13

A reexecucao de 2002 (run eea3fe54-...) terminou com ERROR, recordsWritten=0, apos ler o
arquivo inteiro (input ~4,82 GB; output ~6,94 GB). Metricas indicavam falha na GRAVACAO
no ADW, nao na leitura. Log (fornecido pelo usuario): ORA-01400 em NU_IDADE_TRABALHADOR
(cannot insert NULL). Ou seja: alem do salario, a coluna idade tambem vinha vazia em
parte das linhas e o destino e NOT NULL.

Correcao aplicada na copia P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl (DF1 QRY_TRATAMENTO
e DF2 QRY_ANONIMIZACAO), coluna NU_IDADE_TRABALHADOR, header + SELECT:

Regra (decidida com a area):
  1) se idade informada for int valido e estiver em 0..120 -> usa a idade informada;
  2) senao, calcula (ano_competencia - ano_nascimento) = substr(DT_COMPETENCIA,1,4) -
     substr(DT_NASCIMENTO,1,4); se o resultado estiver em 0..120 -> usa;
  3) senao -> 0 (fallback; nunca NULL).
Observacao: idade por DIFERENCA DE ANOS (aproximacao +/- 1 ano, pois mes/dia nao sao
confiaveis - o CAGED aqui zera mes/dia). Faixa de sanidade 0..120.

Nota importante: na origem (QRY_DADOS/QRY_TRATAMENTO) o DT_NASCIMENTO ainda tem aaaammdd
(a generalizacao aaaa0000 so e aplicada na saida), entao o ano de nascimento esta
disponivel para o calculo.

PENDENTE: reimportar/validar/republicar no BODS e regerar o CSV de 2002 (e demais anos)
antes de nova carga. A copia corrigida acumula: numericas defensivas + salario +
mascara de PIS + calculo de idade.

### NOVA REEXECUCAO DA TASK PARA 2002 (producao) - 2026-10-15

Contexto: o CSV FATOS_CAGED_TRABS_AJUSTADO_2002.csv foi regerado novamente
(last-modified 2026-10-15 13:20; content-length 4.816.490.601 bytes ~4,82 GB;
version-id fa1cddd5-45f2-45da-96ff-436c335cda39), mais recente que a regeracao
anterior (2026-10-13 19:13).

Verificacao previa (OCI CLI, leitura por range dos primeiros 3 MB, ~13.873 linhas):
  - VL_SALARIO_MENSAL_DECLARADO vazio : 0 ocorrencias (antes: milhares a partir da linha 3601).
  - NU_IDADE_TRABALHADOR vazio        : 0 ocorrencias; faixa de idades 12..85 (dentro de 0..120).
  - Todas as linhas com 50 campos (0 desalinhadas).
  - LGPD: NU_PIS_TRABALHADOR AINDA EM CLARO em 100% da amostra; NU_CEP AINDA EM CLARO.
    (A mascara de PIS do _corrigido.atl ainda nao chegou a este CSV.)

Run disparada (ok, status inicial NOT_STARTED):
  - Identifier  : TASK_FATOS_CAGED_TRABS_AJUSTADO_1792073078049_78264480
  - Task-run key: 1fcd2e02-08cb-4b4c-8e48-b2982f515f23
  - Parametro PARAMETER_ARQ -> FATOS_CAGED_TRABS_AJUSTADO_2002.csv (CSV regenerado 2026-10-15)
  - Parametro PARAM_ANO     -> FATOS_CAGED_TRABS_AJUSTADO_199601.csv (default historico, mantido)
  - Disparada por: Angelo Cesar Siciliano Paolino
  - time-created: 2026-10-15T14:04:38Z

Consultar status:
  oci data-integration task-run get ^
    --workspace-id ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq ^
    --application-key dbd6181d-c908-43c0-824e-6f78ee385750 ^
    --task-run-key 1fcd2e02-08cb-4b4c-8e48-b2982f515f23 ^
    --profile bgetrab-session --auth security_token

Desfecho esperado para "resolvido em definitivo": SUCCESS com records-written > 0.
Se ERROR com records-written=0, checar o log pela proxima coluna NOT NULL com valor vazio.

### DESFECHO DA RUN 2002 (1fcd2e02) + MUDANCA DO MODO DE FALHA - 2026-10-15

A run 1fcd2e02-08cb-4b4c-8e48-b2982f515f23 terminou com ERROR, records-written=0.
Metricas (dos outputs e do log Spark):
  - recordsRead  : 21.476.382 (leu o arquivo inteiro)
  - recordsWritten: 0
  - input  ~4,82 GB  | output ~6,94 GB
  - duracao ~499 s (~8,3 min)
  - NO_OF_INSERTS = 0

IMPORTANTE - o modo de falha MUDOU. NAO e mais ORA-01400 (NULL em NOT NULL).
Log da task-run (oci data-integration task-run-log list) mostrou:

  java.lang.RuntimeException: ... DICOM_CONNECTIVITY_0088 - Error :
  ORA-20003: Reject limit reached, query table "BGETRAB_OAC"."COPY\" for error details
  ORA-06512: at "C##CLOUD\.DBMS_CLOUD\", line 2618 / 14677
  Sql = BEGIN DBMS_CLOUD.COPY_DATA(FILE_URI_LIST=>:0,FORMAT=>:1,SCHEMA_NAME=>:2,
        TABLE_NAME=>:3,FIELD_LIST=>:4,OPERATION_ID=>:5); END;

Interpretacao:
  - A gravacao no ADW usa DBMS_CLOUD.COPY_DATA (COPY paralelo) com um REJECT LIMIT.
  - Linhas invalidas suficientes estouraram o limite -> ORA-20003 -> aborta a carga inteira
    (por isso recordsWritten=0, mesmo com salario/idade ja corrigidos na amostra).
  - As correcoes de VL_SALARIO_MENSAL_DECLARADO e NU_IDADE_TRABALHADOR provavelmente
    pegaram (amostra de 3 MB estava limpa), mas resta OUTRO motivo de rejeicao
    em linhas alem dos primeiros 3 MB (ou outra coluna/tipo).

Destino confirmado no log:
  - Data asset origem : DA_OS_BGETRAB_PROD (Object Storage) / bucket-bgetrab-prod
  - Data asset destino: DA_ADW_BGETRAB_PROD (ADW)
  - Schema destino    : BGETRAB_OAC
  - Tabela destino    : V1_FATOS_CAGED_TRABS_AJUSTADO
  - Data flow         : DF_FATOS_CAGED_TRABS_AJUSTADO

PROXIMO PASSO (fora do alcance do OCI CLI - exige SQL no ADW):
  Consultar a tabela de erros do COPY (dentro do ADW, schema BGETRAB_OAC) para
  descobrir a(s) coluna(s)/motivo exatos. Via SQL Developer Web / Database Actions:

    -- motivos agrupados
    SELECT error_message, COUNT(*) qtd
    FROM BGETRAB_OAC."COPY\"
    GROUP BY error_message ORDER BY qtd DESC;

    -- se a COPY\ nao existir mais (sufixo muda a cada COPY), achar a mais recente:
    SELECT table_name, created FROM user_tables
    WHERE table_name LIKE 'COPY\$%LOG' ORDER BY created DESC;

  ATENCAO LGPD: a COPY\$..._LOG guarda a LINHA BRUTA rejeitada (com PII:
  NM/CPF/PIS/CEP/DT_NASCIMENTO). Nao exportar/exibir valores em claro; interessa
  so o error_message (ex.: ORA-01400 coluna X, ORA-12899 value too large,
  ORA-01858/invalid number/invalid date, etc.).

Depois de identificado o motivo:
  - Se for mais uma coluna NOT NULL vindo vazia -> aplicar no ATL corrigido o mesmo
    padrao defensivo (ifthenelse/is_valid + default) ja usado em salario/idade.
  - Se for estouro de precisao/escala (ORA-12899/NUMERIC) -> ajustar CAST/escala.
  - Se for data invalida -> normalizar/validar a data.
  - Regenerar o CSV de 2002, re-subir ao bucket e reexecutar a task.

MONITOR: criado C:\projetos\bgetrab-agente\monitor_run_2002.ps1 (loop 10 min, grava
_monitor_2002.log, para em estado terminal). Para a run 1fcd2e02 ja nao se aplica
(terminal). Reusar na proxima run trocando o \.

### CAUSA REAL DO ERRO7 - DESALINHAMENTO (linha 293029, campo extra) - 2026-10-15

A imagem erro7.png (C:\projetos\erro7.png) mostra o LOG/BAD do COPY do ADW:
  - Field Definitions for table COPY\
  - Bad File: COPY\.bad / COPY\.bad
  - Log File: COPY\.log (aberto 10/15/26 14:12:42 -> bate com a run 1fcd2e02)
  - ORA-01400: cannot insert NULL into (NU_IDADE_TRABALHADOR)
  - error processing column NU_IDADE_TRABALHADOR in row 293029
  - Total Number of Files = 2 (os dois CSVs do fato)

INVESTIGACAO POR DADOS (OCI CLI, leitura por range) - CONCLUSAO DIFERENTE DA HIPOTESE:
  - Amostragem esparsa (8 blocos de 2 MB do inicio ate ~4,5 GB, ~74k linhas): 0 idades vazias,
    0 salarios vazios.
  - Bloco CONTIGUO dos primeiros 80 MB (369.721 linhas, cobre a linha 293029): 0 idades vazias.
  - Localizada a linha de dados 293029 exatamente:
        cols = 51  (as vizinhas tem 50)   <-- UM CAMPO/DELIMITADOR A MAIS
        valor que caiu em idx18 (NU_IDADE_TRABALHADOR) = '00418600016875' (14 digitos, parece PIS)
        linhas 293026-293028 e 293030-293033: 50 cols, idade normal (38,25,36,33,55,29,36)

CAUSA RAIZ (corrige a hipotese anterior):
  NAO e "idade vindo vazia no arquivo". E uma LINHA DESALINHADA: a linha 293029 tem um ';'
  a mais (51 campos), o que empurra os campos uma posicao e faz um valor invalido/vazio cair
  numa coluna NOT NULL -> ORA-01400 reportado como NU_IDADE_TRABALHADOR -> estoura o reject
  limit do DBMS_CLOUD.COPY_DATA (ORA-20003).
  Candidato ao ';' extra: campo texto com ';' nao protegido por aspas (ex.: NM_TRABALHADOR,
  NU_DOC_IDENT_ESTAB) ou concatenacao indevida na geracao do CSV.

Por que os NVL/defaults de salario e idade NAO resolvem isto:
  Sao correcoes de VALOR ausente; aqui o problema e ESTRUTURAL (contagem de campos da linha).

CORRECAO NA ORIGEM (BODS):
  1. Identificar o campo que injeta o ';' extra no registro da linha 293029.
  2. No LOAD FILE, delimitar campos texto com aspas (") e/ou escapar ';' interno; ou sanear
     (remover ';' de campos texto) na view de tratamento/anonimizacao.
  3. Verificar se ha OUTRAS linhas com !=50 campos (varredura completa - em andamento).

STATUS DA VARREDURA COMPLETA DE CAMPOS (!=50): ver proxima atualizacao.

### CAMPO CULPADO IDENTIFICADO - NM_TRABALHADOR com ';' embutido - 2026-10-15

Analise da linha 293029 crua (campo a campo, apos reautenticar a sessao OCI):
  - A linha tem 51 campos (vs 50 do schema). Campos [0]..[13] alinhados e corretos.
  - [14] NM_TRABALHADOR = {}  (vazio)
  - [15] NU_CEP = {******Z}   <-- fragmento de NOME mascarado (padrao X******X) vazou pra ca
  - [16]+ tudo deslizou 1 posicao: CPF com 8 digitos, idade=00418600016875 (= PIS real deslocado),
    PIS=32, etc. [50]=<EXTRA> vazio.

CONCLUSAO FINAL (causa raiz do erro7 / ORA-20003 na run 1fcd2e02):
  O campo NM_TRABALHADOR contem um ';' embutido NAO protegido por aspas. Na geracao do CSV
  (BODS), o ';' do nome foi tratado como separador -> a linha ganhou 1 campo -> desalinhamento
  -> o valor que caiu em NU_IDADE_TRABALHADOR nao era idade -> coluna NOT NULL -> ORA-01400
  -> estouro do reject limit do DBMS_CLOUD.COPY_DATA -> ORA-20003 -> run inteira ERROR,
  recordsWritten=0.

  NAO era idade ausente (as correcoes de salario/idade estao ok nos trechos varridos).
  NAO era valor NULL de origem. E um problema de FORMATACAO/QUOTING do campo texto.

CORRECAO NA ORIGEM (BODS) - a definitiva:
  No LOAD FILE / datastore de saida ARQ_FT_TRAB_AJUSTADO, garantir quoting dos campos texto:
    - Delimitar NM_TRABALHADOR (e demais varchar) com aspas duplas ("), com escape de aspas,
      OU
    - Sanear o valor removendo/substituindo ';' em NM_TRABALHADOR (e outros textos) antes de
      gravar: ex. replace_substr(QRY.NM_TRABALHADOR, ';', ' ').
  Observacao: como NM_TRABALHADOR e mascarado (X******X), o ';' esta no texto ORIGINAL antes
  do mascaramento; o saneamento deve ocorrer no mesmo ponto do mascaramento (QRY_ANONIMIZACAO).
  Aplicar o mesmo cuidado aos outros campos texto (NU_DOC_IDENT_ESTAB etc.) por seguranca.

PENDENTE:
  - Verificar se ha OUTRAS linhas com !=50 campos (varredura completa do CSV) - ainda nao feita.
  - Corrigir o quoting/saneamento no BODS, regerar o CSV de 2002, re-subir e reexecutar a task.
  - So entao os 3 erros (salario, idade, desalinhamento) estarao resolvidos em definitivo.

### CORRECAO APLICADA NO ATL - saneamento de ';' em NM_TRABALHADOR - 2026-10-15

Arquivo editado: C:\projetos\bgetrab\pacotes\etl\P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl
Backup: ..._corrigido.atl.bak_pre_quoting

Decisao: correcao CONCENTRADA na camada de saneamento comum do DF2
(DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST_0), view QRY_TRATAMENTO. Essa camada e por onde
TODAS as linhas passam antes do LOAD FILE (CSV) - inclui tanto o ramo das movimentacoes
normais (QRY_DADOS->QRY_TRATAMENTO->QRY_TRATAMENTO_1) quanto o ramo dos ACERTOS
(FATOS_CAGED_ACERTOS->QRY_DADOS_1->QRY_GERA_ID), que convergem no Merge() antes do DF2.
Logo, sanear aqui cobre os DOIS ramos de uma vez (requisito do usuario: tratamentos iguais).

Antes a camada ja removia aspas do nome:
  replace_substr_ext(replace_substr_ext(NM_TRABALHADOR, chr(39), '', 1, 0), chr(34), '', 1, 0)
  (chr(39)=aspa simples, chr(34)=aspa dupla) - mas NAO removia ';'. O CPF nessa mesma
  camada ja removia ';' (replace_substr(...,';','')); o NOME nao - era a lacuna que causou
  o desalinhamento da linha 293029.

Depois (header L2382 + SELECT L2423, os 2 pontos da view):
  replace_substr_ext(replace_substr_ext(replace_substr_ext(NM_TRABALHADOR, chr(39), '', 1, 0), chr(34), '', 1, 0), chr(59), '', 1, 0)
  (chr(59)=';' - adicionado o nivel externo que remove o ponto-e-virgula).

Validacoes OK: 1 ocorrencia no header + 1 no SELECT substituidas; parenteses balanceados
(5163/5163); arquivo sem BOM; chr(59) presente 2x.

Comparacao de ramos (constatada):
  - NU_DOC_IDENT_ESTAB e NU_PIS: ja removiam ';' nos dois ramos.
  - NU_CPF: camada QRY_TRATAMENTO (L2388) ja removia ';'.
  - NM_TRABALHADOR: era o unico texto sem remocao de ';' na camada comum -> corrigido.
  PIS (decisao B1): mantida a mascara na saida (QRY_ANONIMIZACAO) que ja cobre ambos os
  ramos; nao se mascarou nas views intermediarias (B2 nao escolhido).

PENDENTE (acao manual no BODS - fora do alcance do assistente):
  1. Abrir o _corrigido.atl no BODS Designer e rodar Validate All.
     (se replace_substr_ext/chr nao existirem na instalacao, usar alternativa com
      replace_substr e literal ';'.)
  2. Reimportar -> validar -> regerar o CSV de 2002 (conferir que a linha ~293029 passa a
     ter 50 campos; e varrer o arquivo por linhas !=50 campos).
  3. Re-subir ao bucket e reexecutar a TASK_FATOS_CAGED_TRABS_AJUSTADO.
  4. So entao os problemas (salario, idade, desalinhamento) estarao resolvidos em definitivo.

LEMBRETE LGPD: o CSV atualmente em producao (2002) ainda tem CPF e PIS EM CLARO (amostra:
0 mascarados em 9.250 linhas) - as mascaras do _corrigido.atl ainda nao foram aplicadas em
producao (job nao reimportado/republicado). So terao efeito apos regerar o CSV.

### ALINHAMENTO DEFENSIVO QRY_TRATAMENTO_1 (opcao 2) - 2026-10-15

Arquivo: ...\P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl
Backups: ..._corrigido.atl.bak_pre_quoting  e  ..._corrigido.atl.bak_pre_align_T1

Contexto: comparadas as views QRY_TRATAMENTO (ramo movimentacoes, origem QRY_DADOS) e
QRY_TRATAMENTO_1 (origem QRY_DADOS_1) do DF1 (DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST). Elas NAO
tinham tratamentos iguais: a T usa padrao defensivo (is_valid_int/is_valid_decimal +
ltrim/rtrim + to_decimal + default); a T1 usava formas antigas (nvl, cast varchar(100),
campo cru). Por decisao do usuario (opcao 2), alinhada a T1 ao padrao defensivo da T nos
campos numericos simples + idade.

Alterados na T1 (header L1956-2109 + SELECT, 15 campos, edicao RESTRITA a faixa da T1 para
nao afetar a view gemea QRY_GERA_ID do ramo de acertos):
  CS_SITUACAO_CBO, CS_TIPO_ACERTO(default 9), DT_DIA_MOVIMENTACAO, IN_APRENDIZ, IN_DEFICIENCIA,
  IN_FORA_PRAZO, IN_INFORMADO_COMPETENCIA, IN_VERSAO_CNAE, QT_HORAS_CONTRATUAIS_SEMANA,
  VL_SALARIO_MENSAL_CONTRATUAL(INT), VL_SALDO_MOVIMENTACAO(INT),
  VL_SALARIO_MENSAL_CONTR_SM(DEC 2), VL_SALARIO_MENSAL_DECLARADO(DEC 2),
  NU_TEMPO_EMPREGO(DEC 1), NU_IDADE_TRABALHADOR(regra completa: usa idade 0..120, senao
  competencia-nascimento, senao 0).

NAO alterados (preservada logica propria da T1 - decisao tecnica, confirmada):
  - Todos os ID_SEQ_*/ID_* com lookup_ext em dimensao (ETNIA, CBO, CBO_94, GEOGRAFICA, SEXO,
    CEP, CNAE_2_0, CNAE_2003, CNAE_80, ESCOLARIDADE, TIPO_ESTAB, TIPO_ESTAB_NOVO, REG_ADM_DF,
    FAIXA_TEMPO_EMPREGO, TIPO_MOVIMENTACAO, TAMANHO_EMPRESA_JAN, TAMANHO_EMPR_PRIM_DIA,
    DIVISAO_MUNICIPAL_*): mantem o enriquecimento por lookup e defaults de negocio (99/9999/-1).
    Alinhar quebraria integridade referencial.
  - ID_TIPO_DEFICIENCIA: tem nvl(..., lookup_ext DIM_TIPOS_DEFICIENCIA default 99) -> mantido.
  - NM_TRABALHADOR / NU_CPF / NU_PIS: tratamentos de PII proprios (mascara + nvl 'NAO INFORMADO'
    / '0'); PIS conforme decisao B1 -> nao mexidos aqui.
  - ID_SEQ_ESTABELECIMENTO: FICOU DE FORA (nao aparece nominalmente no SELECT da T1; nao editei
    as cegas). PENDENTE revisar manualmente se deve receber a defensiva.

Validacoes: cada substituicao casou exatamente 1x na faixa da T1 (15 header + 15 SELECT);
parenteses balanceados (5505/5505); sem BOM; view QRY_GERA_ID intacta (restam 4x varchar(100)
e 4x nvl(QRY_DADOS_1.) que sao dela/campos preservados).

Nota de abordagem: 1a tentativa por replace GLOBAL foi revertida (as expressoes nvl(QRY_DADOS_1
...,0) existem tambem na QRY_GERA_ID -> 2 ocorrencias). Refeito por FAIXA DE LINHAS da T1.

PENDENTE (manual, BODS): Validate All no Designer; revisar ID_SEQ_ESTABELECIMENTO; reimportar;
regerar CSV; recarregar.
### CONFERENCIA DO ATL v4 (commit 0646f495) - cobre os 2 ramos - 2026-10-15

Arquivo: ...\P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl
Historico recente (git): b4dadf12 (08:54 adequacao) -> 61b6c48b (14:04 v3) -> 0646f495 (14:29 v4).
hash atual == HEAD (490c9984...), sem mudancas pendentes. O v4 foi commitado por angelo.paolino
DEPOIS das edicoes do assistente e PRESERVOU/consolidou as correcoes (reescreveu idade em
multiline, etc.).

Cobertura confirmada por leitura do conteudo atual (NAO so pelo diff):

RAMO MOVIMENTACOES (QRY_DADOS -> QRY_TRATAMENTO -> QRY_TRATAMENTO_1):
  - Salario/idade/numericos: defensivas is_valid_* + ltrim/rtrim + to_decimal presentes (208x is_valid_).
  - Idade: regra completa (0..120, senao competencia-nascimento, senao 0).
  - Nome ';': saneamento chr(59) presente (2x) na camada QRY_TRATAMENTO do DF2.
  - PII: mascara de nome/CPF/PIS na QRY_ANONIMIZACAO (saida).

RAMO ACERTOS (FATOS_CAGED_ACERTOS -> QRY_DADOS_1 -> QRY_TRATAMENTO_1 -> QRY_GERA_ID -> Merge):
  - QRY_TRATAMENTO_1 (v4) MANTEVE o alinhamento defensivo (opcao 2): IN_APRENDIZ, NU_IDADE
    (regra completa), NU_TEMPO_EMPREGO (dec 1), VL_SALARIO_MENSAL_CONTR_SM e _DECLARADO (dec 2),
    todos com is_valid_* + trim e origem QRY_DADOS_1.
  - Desalinhamento ';': as linhas dos acertos, apos o Merge, passam pela camada QRY_TRATAMENTO
    do DF2 (chr(59)) e pela QRY_ANONIMIZACAO -> saneadas e mascaradas junto com as normais.
  - PII: QRY_GERA_ID ja mascara CPF e aplica replace_substr(';') em PIS/DOC; mascara final na saida.
  - Preservados os lookup_ext de dimensao nos ID_SEQ_* (integridade referencial) - correto.

CONCLUSAO: o JOB (ATL v4) cobre TODOS os problemas tratados (salario, idade, desalinhamento
';' no nome, mascara CPF/PIS) nos DOIS ramos.

RESSALVA (nao e problema do ATL): o CSV FATOS_CAGED_TRABS_AJUSTADO_2002.csv no bucket
(last-modified 2026-10-15 18:53 UTC / 15:53 local; version-id 3de8278d...; 4.816.490.601 bytes)
AINDA NAO reflete o ATL v4:
  - Varredura dos primeiros 80 MB (369.808 linhas): 1 linha com 51 campos (linha 297928) -
    mesmo padrao de desalinhamento por ';' no NM_TRABALHADOR (NU_CEP saiu '******Z', idade
    recebeu PIS deslocado) que a antiga 293029.
  - CPF e PIS 100% EM CLARO (0 mascarados) -> prova de que nao foi gerado pelo ATL v4.
  - A antiga linha 293029 agora tem 50 campos (fonte deslocada), mas o defeito migrou p/ 297928.

PENDENTE p/ fechar em definitivo:
  1. Reimportar o ATL v4 no BODS Designer -> Validate All (checar is_valid_decimal/replace_substr_ext/chr).
  2. Republicar o job e REGERAR o CSV de 2002 a partir do v4.
  3. Conferir no novo CSV: 0 linhas !=50 campos; CPF/PIS mascarados; salario/idade sem vazios.
  4. Reexecutar a TASK_FATOS_CAGED_TRABS_AJUSTADO (esperado SUCCESS, records-written>0).

### ANALISE DO ATL v4 (P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl) - 2026-10-16

Arquivo analisado: C:\projetos\bgetrab\pacotes\etl\P_BGE_ETL_001_MIGRA_CAGED_V1_corrigido.atl
Data de modificacao do arquivo: Fri Oct 16 12:49:52 2026 / 13:01:49 2026 (DF1 e DF2)

Dataflows relevantes para o fato ajustado:
  - DF1 (DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST)   : le FATOS_CAGED_TRABS_AJUSTADO e FATOS_CAGED_ACERTOS, gera CSV
  - DF2 (DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST_0) : le FATOS_CAGED_TRABS_AJUSTADO, gera CSV
  - DF_ATESTA                                 : nao gera CSV, nao relevante

#### Ramo principal - FATOS_CAGED_TRABS_AJUSTADO (DF1: QRY_DADOS -> QRY_TRATAMENTO)

| Problema                        | Camada onde e tratado | Expressao / Tecnica              | Status |
|---------------------------------|-----------------------|----------------------------------|--------|
| ';' em NM_TRABALHADOR           | QRY_DADOS             | replace_substr(...NM_TRABALHADOR, ';', '') | OK |
| VL_SALARIO_MENSAL_DECLARADO vazio | QRY_TRATAMENTO      | is_valid_decimal + to_decimal(...,2), else 0 | OK |
| NU_IDADE_TRABALHADOR vazio      | QRY_TRATAMENTO        | is_valid_int + faixa 0..120 + fallback competencia-nascimento + fallback 0 | OK |
| NU_PIS_TRABALHADOR em claro     | QRY_TRATAMENTO        | substr(1,3)||'*******'||substr(last,1) | OK |

#### Ramo de acertos - FATOS_CAGED_ACERTOS (DF1: QRY_DADOS_1 -> QRY_TRATAMENTO_1 -> QRY_GERA_ID)

| Problema                        | Camada onde e tratado | Expressao / Tecnica              | Status |
|---------------------------------|-----------------------|----------------------------------|--------|
| ';' em NM_TRABALHADOR           | QRY_DADOS_1           | replace_substr(...NM_TRABALHADOR, ';', '') | OK |
| VL_SALARIO_MENSAL_DECLARADO vazio | QRY_TRATAMENTO_1    | is_valid_decimal + to_decimal(...,2), else 0 | OK |
| NU_IDADE_TRABALHADOR vazio      | QRY_TRATAMENTO_1      | is_valid_int + faixa 0..120 + fallback competencia-nascimento + fallback 0 | OK |
| NU_PIS_TRABALHADOR em claro     | QRY_TRATAMENTO_1      | substr(1,3)||'*******'||substr(last,1) | OK |

#### Ramo DF2 - FATOS_CAGED_TRABS_AJUSTADO (QRY_DADOS -> QRY_TRATAMENTO -> QRY_ANONIMIZACAO)

| Problema                        | Camada onde e tratado  | Expressao / Tecnica              | Status |
|---------------------------------|------------------------|----------------------------------|--------|
| ';' em NM_TRABALHADOR           | QRY_DADOS              | replace_substr(...NM_TRABALHADOR, ';', '') | OK |
| VL_SALARIO_MENSAL_DECLARADO vazio | QRY_TRATAMENTO: nvl(...,0) + QRY_ANONIMIZACAO: is_valid_decimal completo | OK (defensiva completa na saida) |
| NU_IDADE_TRABALHADOR vazio      | QRY_ANONIMIZACAO       | is_valid_int + faixa 0..120 + fallback competencia-nascimento + fallback 0 | OK |
| NU_PIS_TRABALHADOR em claro     | QRY_ANONIMIZACAO       | substr(1,3)||'*******'||substr(last,1) | OK |

Nota DF2: QRY_TRATAMENTO passa salario e idade sem defensiva completa (so nvl/passthrough),
delegando para QRY_ANONIMIZACAO. Funciona, mas e um risco de manutencao futuro se
QRY_ANONIMIZACAO for removida ou reordenada.

#### Verificacao do CSV atual no bucket (2026-10-16)

Arquivo: FATOS_CAGED_TRABS_AJUSTADO_2002.csv (bucket-bgetrab-prod)
Last-modified: 2026-10-15 21:36 UTC | version-id: 5975fe2c-... | tamanho: ~4,82 GB
Amostra primeiros 2 MB (~9.244 linhas de dados):
  - VL_SALARIO_MENSAL_DECLARADO vazio : 0  (corrigido)
  - NU_IDADE_TRABALHADOR vazio        : 0; faixa 12..85 anos  (corrigido)
  - NU_CPF_TRABALHADOR mascarado      : 100% das linhas
  - NU_PIS_TRABALHADOR em claro       : 100% das linhas (mascara do ATL v4 ainda nao aplicada)
  - Linhas desalinhadas (!=50 campos) : 1 (linha 9245 da amostra - ';' ainda presente)
  Conclusao: este CSV foi gerado ANTES do ATL v4 ser reimportado/republicado no BODS.

#### Conclusao geral

O ATL v4 esta apto para importacao e publicacao. Todos os 3 problemas que causaram
erros nas runs anteriores estao cobertos nos dois ramos (movimentacoes e acertos).

PROXIMO PASSO para fechar em definitivo:
  1. Importar o ATL v4 no BODS Designer -> Validate All.
  2. Republicar o job e REGERAR o CSV de 2002.
  3. Conferir no novo CSV: 0 linhas !=50 campos; PIS mascarado; salario/idade sem vazios.
  4. Subir ao bucket e reexecutar TASK_FATOS_CAGED_TRABS_AJUSTADO (esperado: SUCCESS, records-written>0).

### ANALISE DO NOVO CSV 2002 (version-id 48de7d01) - 2026-10-16

Arquivo: FATOS_CAGED_TRABS_AJUSTADO_2002.csv (bucket-bgetrab-prod)
Last-modified : Fri, 16 Oct 2026 20:00:16 GMT
Version-id    : 48de7d01-df62-4341-96c0-57e10c0d3431
Content-length: 4.816.105.961 bytes (~4,82 GB)
ETag          : 357f320a-c4ca-4706-858d-d8557a2f5390

Arquivo NOVO em relacao ao registrado em 2026-10-16 (version-id 5975fe2c, last-modified 21:36 UTC
de 2026-10-15). Foi regerado e subido ao bucket apos as correcoes do ATL v4.

Varredura realizada em 4 blocos via OCI CLI (range download):
  - Bloco inicio   : bytes 0-2 MB       (~9.277 linhas de dados)
  - Bloco inicio+  : bytes 0-80 MB      (~370.967 linhas de dados)
  - Bloco meio     : ~2 GB offset        (~18.664 linhas internas)
  - Bloco final    : ~4.812 MB offset    (~18.407 linhas internas)
  Total amostrado  : ~417.000 linhas (~2% do arquivo de 21,5 mi de registros)

#### Resultado da analise

| Criterio                              | Status        | Detalhe |
|---------------------------------------|---------------|---------|
| Estrutura (50 campos por linha)       | OK (>=99,999%)| 0 linhas desalinhadas em todos os blocos internos; a unica linha com !=50 campos nos 80 MB era a linha cortada pelo limite do range (ultima linha incompleta - artefato do download, nao defeito do arquivo) |
| VL_SALARIO_MENSAL_DECLARADO vazio     | OK            | 0 ocorrencias em todos os blocos (correcao de NVL/is_valid_decimal efetiva) |
| NU_IDADE_TRABALHADOR vazio            | OK            | 0 ocorrencias em todos os blocos (correcao de fallback competencia-nascimento efetiva) |
| NU_CPF_TRABALHADOR mascarado          | OK (100%)     | 100% das linhas com '*' nos quatro blocos |
| NU_PIS_TRABALHADOR mascarado          | OK (100%)     | 100% das linhas com '*' - MUDANCA SIGNIFICATIVA: o ATL v4 ja esta em producao; versoes anteriores tinham PIS 100% em claro |

#### Comparacao com versoes anteriores

| Versao (version-id)  | Data geracao         | Desal. (80 MB) | Salario vazio | Idade vazia | PIS claro |
|----------------------|----------------------|----------------|---------------|-------------|-----------|
| original (sem id)    | antes 2026-10-13     | 0              | milhares       | 0           | 100%      |
| fa1cddd5 (2026-10-15)| 2026-10-15 13:20     | 1 (linha 293029)| 0             | 0           | 100%      |
| 3de8278d (2026-10-15)| 2026-10-15 18:53 UTC | 1 (linha 297928)| 0             | 0           | 100%      |
| 5975fe2c (2026-10-15)| 2026-10-15 21:36 UTC | 1              | 0             | 0           | 100%      |
| 48de7d01 (2026-10-16)| 2026-10-16 20:00 UTC | 0              | 0             | 0           | 0% (mascarado) |

#### Conclusao

O CSV da version-id 48de7d01 esta ADERENTE a todas as correcoes do ATL v4:
  1. Desalinhamento por ';' em NM_TRABALHADOR: CORRIGIDO (0 linhas desalinhadas nos ~417k amostrados).
  2. VL_SALARIO_MENSAL_DECLARADO vazio: CORRIGIDO (0 ocorrencias).
  3. NU_IDADE_TRABALHADOR vazio: CORRIGIDO (0 ocorrencias).
  4. NU_PIS_TRABALHADOR em claro: CORRIGIDO (mascarado em 100% das linhas).
  5. NU_CPF_TRABALHADOR: ja estava mascarado; continua OK.

PROXIMO PASSO: reexecutar a TASK_FATOS_CAGED_TRABS_AJUSTADO para o CSV de 2002
(este novo arquivo ja esta no bucket; basta disparar a task). Resultado esperado:
SUCCESS com records-written > 0 (sem ORA-01400 nem ORA-20003).

LEMBRETE LGPD: NU_CEP ainda em claro em 100% das linhas (decisao pendente de negocio).

### NOVA REEXECUCAO DA TASK PARA 2002 (producao) - 2026-10-16

Contexto: CSV FATOS_CAGED_TRABS_AJUSTADO_2002.csv regerado com o ATL v4 aplicado
(version-id 48de7d01-df62-4341-96c0-57e10c0d3431, last-modified 2026-10-16 20:00 UTC).
Analise previa confirmou: 0 desalinhamentos, 0 campos vazios criticos, CPF/PIS mascarados.

Run disparada:
  - Identifier  : TASK_FATOS_CAGED_TRABS_AJUSTADO_1792185931926_74824108
  - Task-run key: e71244d9-7854-4bbe-a8ec-68fc0bd4e196
  - Parametro PARAMETER_ARQ -> FATOS_CAGED_TRABS_AJUSTADO_2002.csv (CSV do ATL v4)
  - Parametro PARAM_ANO     -> FATOS_CAGED_TRABS_AJUSTADO_199601.csv (default historico)
  - time-created: 2026-10-16T21:25:32.714Z
  - Status inicial: NOT_STARTED -> RUNNING (confirmado 15s apos disparo, sem erro)

Consultar status:
  oci data-integration task-run get ^
    --workspace-id ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq ^
    --application-key dbd6181d-c908-43c0-824e-6f78ee385750 ^
    --task-run-key e71244d9-7854-4bbe-a8ec-68fc0bd4e196 ^
    --profile bgetrab-session --auth security_token

Desfecho esperado: SUCCESS com records-written > 0 (todas as correcoes do ATL v4 presentes no CSV).
Se ERROR: checar log da task-run e tabela COPY no ADW (schema BGETRAB_OAC) para nova coluna rejeitada.

### DESFECHO DA RUN 2002 (e71244d9) - SUCCESS - 2026-10-16

Run: TASK_FATOS_CAGED_TRABS_AJUSTADO_1792185931926_74824108
Task-run key: e71244d9-7854-4bbe-a8ec-68fc0bd4e196

  - Status         : SUCCESS
  - records-written: 21.476.380
  - bytes-processed: ~4,82 GB (arquivo inteiro)
  - Inicio         : 2026-10-16T21:25:31Z
  - Fim            : 2026-10-16T21:52:57Z
  - Duracao        : ~27 minutos
  - Erros          : nenhum

CONCLUSAO: os tres problemas que causaram falhas nas runs anteriores estao resolvidos
em definitivo com o ATL v4 + CSV regerado (version-id 48de7d01):
  1. Desalinhamento por ';' em NM_TRABALHADOR -> CORRIGIDO
  2. VL_SALARIO_MENSAL_DECLARADO vazio (ORA-01400) -> CORRIGIDO
  3. NU_IDADE_TRABALHADOR vazio (ORA-01400) -> CORRIGIDO

Os 21.476.380 registros do CAGED 2002 estao carregados na tabela
V1_FATOS_CAGED_TRABS_AJUSTADO (schema BGETRAB_OAC, ADW producao).

PENDENTE (nao bloqueante para 2002, mas relevante para os demais anos):
  - NU_CEP continua em claro (decisao de negocio pendente).
  - NU_PIS mascarado apenas no CSV de 2002 (ATL v4); demais anos ainda em claro
    ate regeracao dos CSVs restantes.
  - Aplicar a mesma correcao (ATL v4 + regerar + carregar) para os demais anos
    do CAGED (2000, 2001, 2003..2019) que ainda nao foram reprocessados.

### ANALISE DO CSV 2003 (version-id 8fa18a17) - 2026-10-16

Arquivo: FATOS_CAGED_TRABS_AJUSTADO_2003.csv (bucket-bgetrab-prod)
Last-modified : Fri, 16 Oct 2026 22:51:40 GMT
Version-id    : 8fa18a17-14f4-467a-94f9-fa5b023724a1
Content-length: 4.824.995.565 bytes (~4,83 GB)

Arquivo gerado apos o ATL v4 (timing: ~2h51min depois do CSV de 2002, indicando
que o BODS esta regerando os anos em sequencia com o ATL v4 aplicado).

Varredura em 3 blocos via OCI CLI (range download):
  - Bloco inicio : bytes 0-80 MB      (~370.863 linhas analisadas)
  - Bloco meio   : ~2.4 GB offset     (~18.975 linhas internas)
  - Bloco final  : ~4.8 GB offset     (~18.980 linhas internas)
  Total amostrado: ~408.000 linhas

Resultado:

| Criterio                              | Status | Detalhe |
|---------------------------------------|--------|---------|
| Estrutura (50 campos por linha)       | OK     | 0 desalinhamentos reais; linhas "!=50" nos blocos meio/final sao artefatos do corte do range (linha incompleta no limite do bloco) |
| VL_SALARIO_MENSAL_DECLARADO vazio     | OK     | 0 ocorrencias |
| NU_IDADE_TRABALHADOR vazio            | OK     | 0 ocorrencias |
| NU_CPF_TRABALHADOR mascarado          | OK     | 100% das linhas |
| NU_PIS_TRABALHADOR mascarado          | OK     | 100% das linhas (ATL v4 aplicado) |

Conclusao: CSV de 2003 ADERENTE a todas as correcoes do ATL v4. Apto para carga.


### CARGA DO ANO 2003 (producao) - 2026-10-16

CSV verificado (version-id 8fa18a17, last-modified 2026-10-16 22:51 UTC, ATL v4 aplicado).
Analise previa: 0 desalinhamentos, 0 campos vazios criticos, CPF/PIS 100% mascarados.

Run disparada:
  - Identifier  : TASK_FATOS_CAGED_TRABS_AJUSTADO_1792195644949_44330200
  - Task-run key: 83d55102-3d52-4f25-a3d4-f47e391fe707
  - Parametro PARAMETER_ARQ -> FATOS_CAGED_TRABS_AJUSTADO_2003.csv
  - Parametro PARAM_ANO     -> FATOS_CAGED_TRABS_AJUSTADO_199601.csv (default historico)
  - time-created: 2026-10-17T00:07:25.645Z
  - Status inicial: NOT_STARTED -> RUNNING (confirmado 15s apos disparo)

Consultar status:
  oci data-integration task-run get ^
    --workspace-id ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq ^
    --application-key dbd6181d-c908-43c0-824e-6f78ee385750 ^
    --task-run-key 83d55102-3d52-4f25-a3d4-f47e391fe707 ^
    --profile bgetrab-session --auth security_token

Desfecho esperado: SUCCESS com records-written > 0.


### DESFECHO DA RUN 2003 (83d55102) - SUCCESS - 2026-10-16

Run: TASK_FATOS_CAGED_TRABS_AJUSTADO_1792195644949_44330200
Task-run key: 83d55102-3d52-4f25-a3d4-f47e391fe707

  - Status         : SUCCESS
  - records-written: 21.767.606
  - bytes-processed: ~4,83 GB (arquivo inteiro)
  - Inicio         : 2026-10-17T00:07:24Z
  - Fim            : 2026-10-17T00:36:42Z
  - Duracao        : ~29 minutos
  - Erros          : nenhum

Os 21.767.606 registros do CAGED 2003 estao carregados na tabela
V1_FATOS_CAGED_TRABS_AJUSTADO (schema BGETRAB_OAC, ADW producao).


### ANALISE DOS CSVs 2004, 2005, 2006 (ATL v4) - 2026-10-17

Contexto: apos o sucesso do 2002 (run e71244d9, 2026-10-16) e do 2003 (run 83d55102,
2026-10-17 00:36), verificou-se que o BODS continuou regerando os demais anos em
sequencia com o ATL v4. Os CSVs de 2004, 2005 e 2006 foram encontrados no bucket
com last-modified de 2026-10-17 madrugada, indicando regeneracao recente.

Metadados dos arquivos no bucket-bgetrab-prod (coletados em 2026-10-17):

| Arquivo                              | Tamanho      | Last-modified (UTC)      | ETag                                 |
|--------------------------------------|--------------|--------------------------|--------------------------------------|
| FATOS_CAGED_TRABS_AJUSTADO_2004.csv  | 5.350.934.507 bytes (~5,35 GB) | 2026-10-17T04:04:07Z | d65efdcc-3b7f-453c-80c7-f04b5f0ef458 |
| FATOS_CAGED_TRABS_AJUSTADO_2005.csv  | 5.906.936.853 bytes (~5,91 GB) | 2026-10-17T04:06:17Z | 7db974e2-8913-4082-9d9e-0ddce471b967 |
| FATOS_CAGED_TRABS_AJUSTADO_2006.csv  | 6.293.003.715 bytes (~6,29 GB) | 2026-10-17T04:05:31Z | 772f3561-f52c-47b8-8e80-f2e9e91e5d4a |

Varredura via OCI CLI (range download, 3 blocos por arquivo: inicio 80 MB, meio ~4 MB, fim ~4 MB):

| Criterio                             | 2004          | 2005          | 2006          |
|--------------------------------------|---------------|---------------|---------------|
| Linhas amostradas (3 blocos)         | ~408.000      | ~409.000      | ~410.000      |
| Desalinhadas (!=50 campos)           | 0             | 0             | 0             |
| VL_SALARIO_MENSAL_DECLARADO vazio    | 0             | 0             | 0             |
| NU_IDADE_TRABALHADOR vazio           | 0             | 0             | 0             |
| NU_CPF_TRABALHADOR mascarado         | 100%          | 100%          | 100%          |
| NU_PIS_TRABALHADOR mascarado         | 100%          | 100%          | 100%          |

Conclusao: os tres CSVs estao ADERENTES a todas as correcoes do ATL v4. Aptos para carga.

### CARGA DOS ANOS 2004, 2005 E 2006 (producao) - 2026-10-17

CSVs verificados e aderentes ao ATL v4 (ver analise acima).
JSONs de parametro criados (UTF-8 sem BOM):
  - C:\projetos\bgetrab-agente\cfg_provider_2004.json
  - C:\projetos\bgetrab-agente\cfg_provider_2005.json
  - C:\projetos\bgetrab-agente\cfg_provider_2006.json
  - C:\projetos\bgetrab-agente\reg_meta_2004.json (igual ao de 2002/2003)
  - C:\projetos\bgetrab-agente\reg_meta_2005.json
  - C:\projetos\bgetrab-agente\reg_meta_2006.json

Runs disparadas (2026-10-17 ~19:39-19:41 UTC / 16:39-16:41 local):

| Ano  | Task-run key                         | Identifier                                          | time-created (UTC)       | Status inicial |
|------|--------------------------------------|-----------------------------------------------------|--------------------------|----------------|
| 2004 | 055c8ee1-fb28-4b61-9dec-d2cc68ec2fbf | TASK_FATOS_CAGED_TRABS_AJUSTADO_1792265947515_39302192 | 2026-10-17T19:39:07Z  | RUNNING        |
| 2005 | 3d379bda-f0f4-4d7a-baa0-07b1368480c0 | TASK_FATOS_CAGED_TRABS_AJUSTADO_1792266017753_08580853 | 2026-10-17T19:40:17Z  | RUNNING        |
| 2006 | 4cf58190-6bd2-4d6d-8864-d9aff0cab2b1 | TASK_FATOS_CAGED_TRABS_AJUSTADO_1792266085410_71002841 | 2026-10-17T19:41:25Z  | RUNNING        |

Parametros de cada run:
  - PARAMETER_ARQ -> FATOS_CAGED_TRABS_AJUSTADO_<ANO>.csv (CSV do ATL v4)
  - PARAM_ANO     -> FATOS_CAGED_TRABS_AJUSTADO_199601.csv (default historico)

Consultar status (substituir <KEY> pela task-run key do ano desejado):
  oci data-integration task-run get ^
    --workspace-id ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq ^
    --application-key dbd6181d-c908-43c0-824e-6f78ee385750 ^
    --task-run-key <KEY> ^
    --profile bgetrab-session --auth security_token

Desfecho esperado: SUCCESS com records-written > 0 para cada ano.
PENDENTE: confirmar desfecho final das tres runs na proxima sessao (sessao OCI expirou
antes de coletar o resultado terminal; runs estavam RUNNING ao encerrar a sessao).

### DESFECHO DAS RUNS 2004, 2005 E 2006 - SUCCESS - 2026-10-20

Confirmado nesta sessao (2026-10-20) via oci data-integration task-run get. As tres runs
disparadas em 2026-10-17 (que estavam RUNNING ao encerrar a sessao anterior) terminaram
com SUCCESS, sem error-message nem termination-errors:

| Ano  | Task-run key | Status  | records-written | Inicio -> Fim (UTC)        | Duracao |
|------|--------------|---------|-----------------|----------------------------|---------|
| 2004 | 055c8ee1-fb28-4b61-9dec-d2cc68ec2fbf | SUCCESS | 23.882.368 | 2026-10-17 19:39:07 -> 20:12:58 | ~34 min |
| 2005 | 3d379bda-f0f4-4d7a-baa0-07b1368480c0 | SUCCESS | 26.272.426 | 2026-10-17 19:40:17 -> 20:34:59 | ~55 min |
| 2006 | 4cf58190-6bd2-4d6d-8864-d9aff0cab2b1 | SUCCESS | 28.034.326 | 2026-10-17 19:41:25 -> 20:56:28 | ~75 min |

Os registros dos anos 2004, 2005 e 2006 estao carregados na tabela
V1_FATOS_CAGED_TRABS_AJUSTADO (schema BGETRAB_OAC, ADW producao).

Resumo acumulado de cargas concluidas com ATL v4 (SUCCESS): 2002, 2003, 2004, 2005, 2006.
Aptos aguardando carga: 1996, 1997, 1999. CSV vazio (pendente origem): 1998.
Observacao: estas cargas ocorreram ANTES do diagnostico do truncamento de
DT_COMPETENCIA_MOVIMENTACAO (2026-10-19). Avaliar reprocessamento dos anos afetados
(1996, 2000, 2001, 2003, 2011) apos a correcao da conversao VARCHAR2->INT no job DARDO.

### CARGAS MANUAIS 1996, 1997 E 1999 - SUCCESS - 2026-10-19 (confirmado 2026-10-20)

Verificado via oci data-integration task-run list/get. Os tres anos foram carregados
MANUALMENTE por Angelo Cesar Siciliano Paolino em 2026-10-19 (nao disparados pelo assistente).
Todos SUCCESS, sem error-message:

| Ano  | Task-run key | Status  | records-written | Inicio -> Fim (UTC)        | Duracao |
|------|--------------|---------|-----------------|----------------------------|---------|
| 1996 | 8f33155a-dcbe-4d11-afec-ffa8f16d4809 | SUCCESS | 19.157.840 | 2026-10-19 12:03:33 -> 12:29:26 | ~26 min |
| 1997 | 3fa9ebf1-fcba-4bbe-8d2e-7d0990d170c5 | SUCCESS | 18.876.702 | 2026-10-19 12:53:40 -> 13:17:31 | ~24 min |
| 1999 | b1b68433-4f63-4bdb-abae-fa4fcff39c39 | SUCCESS | 17.460.452 | 2026-10-19 13:39:19 -> 15:01:22 | ~82 min |

Nota: nessas runs o PARAM_ANO saiu vazio (nas runs anteriores vinha _199601.csv); como o
PARAMETER_ARQ (CSV do ano) e o que carrega os dados, todas gravaram normalmente.

Resumo acumulado de cargas concluidas (SUCCESS) na V1_FATOS_CAGED_TRABS_AJUSTADO:
  1996, 1997, 1999, 2002, 2003, 2004, 2005, 2006.
  Pendente origem (CSV vazio): 1998. Nao carregados ainda: 2000, 2001, 2007-2019.

ATENCAO (truncamento DT_COMPETENCIA_MOVIMENTACAO): a carga de 1996 (2026-10-19) ocorreu no
mesmo dia do diagnostico do truncamento e 1996 e o ano MAIS afetado (~64% na amostra). Logo,
os 19,1 mi de registros de 1996 ja estao no ADW com DT_COMPETENCIA_MOVIMENTACAO truncada e
PRECISAM ser recarregados apos a correcao da conversao VARCHAR2->INT no job DARDO. 1997 e 1999
estavam limpos na amostra, mas reconferir na varredura completa antes de considerar finalizados.
## Como retomar o trabalho em sessoes futuras

Lembrete: o assistente NAO tem memoria entre sessoes. O conhecimento vive nestes
arquivos e nas variaveis de ambiente ja configuradas no Windows.

### Carregamento automatico (recomendado)
- Existe a regra C:\projetos\.amazonq\rules\bgetrab.md, carregada automaticamente
  quando o agente roda neste diretorio. Ela instrui o assistente a ler este
  oci-bgetrab.md e a respeitar as particularidades do ambiente.
- Basta abrir o agente em C:\projetos e comecar.

### Atalho manual (alternativa)
- No inicio da sessao, peca:
    "Leia C:\projetos\oci-bgetrab.md e use como contexto. Vamos continuar no projeto BGETRAB."

### Checklist rapido de ambiente (janela nova de terminal)
1. As variaveis de ambiente ja estao persistidas (setx): OCI_CLI_CA_BUNDLE,
   REQUESTS_CA_BUNDLE, SSL_CERT_FILE, OCI_CLI_AUTH, OCI_CLI_PROFILE.
2. Testar: oci os ns get  (esperado: "grmu0oy5wsd9").
3. Se der erro de sessao expirada: oci session authenticate --region sa-saopaulo-1
   (ou oci session refresh --profile bgetrab-session).

### Manutencao
- Sempre que descobrir OCIDs, schemas ou correcoes novas, atualizar este arquivo.

### ANALISE DE ADERENCIA - CSVs 1996, 1997, 1998 e 1999 (ATL v4) - 2026-10-18

Analise realizada em 2026-10-18 via OCI CLI (range download + varredura PowerShell).
Contexto: verificar se os CSVs regerados pelo BODS na noite de 2026-10-17 estao
aderentes as correcoes do ATL v4 (mesmos criterios aplicados a 2002, 2003, 2004, 2005 e 2006).

#### Metadados (bucket-bgetrab-prod, coletados em 2026-10-18)

| Arquivo                             | Tamanho               | Last-modified (UTC)      | Version-id                           |
|-------------------------------------|-----------------------|--------------------------|--------------------------------------|
| FATOS_CAGED_TRABS_AJUSTADO_1996.csv | 4.313.695.524 bytes (~4,31 GB) | 2026-10-17T23:47:30Z | 4bbb3600-54f9-4a48-9c1b-b283b3f77dcb |
| FATOS_CAGED_TRABS_AJUSTADO_1997.csv | 4.272.857.022 bytes (~4,27 GB) | 2026-10-17T23:48:26Z | ce029c71-5ce4-413a-be85-a4f290eebd66 |
| FATOS_CAGED_TRABS_AJUSTADO_1998.csv | 966 bytes (VAZIO)     | 2026-10-17T23:46:20Z     | df9f2ce1-d9e3-4b3a-82d8-b39332fcdc67 |
| FATOS_CAGED_TRABS_AJUSTADO_1999.csv | 3.951.780.434 bytes (~3,95 GB) | 2026-10-17T23:49:12Z | 098eb2dd-efbf-4186-9e58-12591c168a44 |

Todos os quatro foram regerados pelo BODS na mesma noite (2026-10-17), em sequencia
com os demais anos que ja haviam sido verificados (2002-2006).

#### Varredura de qualidade - 1996, 1997 e 1999

Metodo: 3 blocos por arquivo via OCI CLI (inicio 0-80 MB, meio ~4 MB, fim ~4 MB).
Total amostrado: ~408.000 linhas por arquivo (~1,2 milhao de linhas nos 3 anos).
Linhas da primeira e ultima posicao de cada bloco descartadas (artefatos de corte de range).

| Criterio                              | 1996    | 1997    | 1999    |
|---------------------------------------|---------|---------|---------|
| Linhas amostradas (3 blocos)          | ~408.000| ~408.000| ~408.000|
| Desalinhadas (!=50 campos)            | 0 OK    | 0 OK    | 0 OK    |
| VL_SALARIO_MENSAL_DECLARADO vazio     | 0 OK    | 0 OK    | 0 OK    |
| NU_IDADE_TRABALHADOR vazio            | 0 OK    | 0 OK    | 0 OK    |
| NU_CPF_TRABALHADOR mascarado          | 100% OK | 100% OK | 100% OK |
| NU_PIS_TRABALHADOR mascarado          | 100% OK | 100% OK | 100% OK |

CONCLUSAO (1996, 1997, 1999): TOTALMENTE ADERENTES ao ATL v4.
Os tres problemas historicos (desalinhamento por ';' em NM_TRABALHADOR, VL_SALARIO_MENSAL_DECLARADO
vazio, NU_IDADE_TRABALHADOR vazio) estao corrigidos. CPF e PIS mascarados em 100% das linhas.
Aptos para carga via TASK_FATOS_CAGED_TRABS_AJUSTADO.

#### Situacao do 1998 - CSV VAZIO (problema critico)

O arquivo FATOS_CAGED_TRABS_AJUSTADO_1998.csv contem apenas o header (966 bytes, 1 linha).
Zero linhas de dado. O BODS gerou um CSV vazio para 1998 durante a regeracao de 2026-10-17.

Causas possiveis (a investigar no lado BODS/banco de origem):
  a) Ausencia dos dados de 1998 nas tabelas de origem (FATOS_CAGED_TRABS_AJUSTADO /
     FATOS_CAGED_ACERTOS) no momento em que o job rodou.
  b) Filtro ou parametro de ano no job que excluiu 1998 por configuracao especifica.
  c) Erro silencioso na query de origem (ex.: condicao de where que nao retorna 1998).

Impacto: a TASK_FATOS_CAGED_TRABS_AJUSTADO para 1998 rodaria com records-written=0
(nada a carregar). NAO disparar a task ate o CSV ser regerado corretamente.

PENDENTE (acao no BODS/equipe de origem):
  - Verificar por que o job gerou o CSV vazio para 1998.
  - Corrigir a origem e regerar o arquivo.
  - Apos upload do novo CSV ao bucket, analisar aderencia com o mesmo procedimento
    e entao disparar a task.

#### Proximo passo

  - 1996, 1997, 1999: aptos para carga. Disparar TASK_FATOS_CAGED_TRABS_AJUSTADO
    para cada um (seguir o mesmo padrao das runs de 2002/2003/2004/2005/2006).
  - 1998: aguardar regera cao do CSV com dados reais.
  - NU_CEP continua em claro em todos os anos (decisao de negocio pendente).

### DIAGNOSTICO - FORMATO DT_COMPETENCIA_MOVIMENTACAO (AAAAMM) - 2026-10-19

Pergunta: o campo DT_COMPETENCIA_MOVIMENTACAO da tabela V1_FATOS_CAGED_TRABS_AJUSTADO
(schema BGETRAB_OAC, ADW DA_ADW_BGETRAB_PROD) esta sendo carregado no formato AAAAMM?

RESPOSTA: SIM. Confirmado em tres camadas independentes (sem defeito de formato).

1) Origem (CSV no bucket-bgetrab-prod) - verificado por range download:
   - FATOS_CAGED_TRABS_AJUSTADO_2019.csv (separador ';', com header): coluna 3
     DT_COMPETENCIA_MOVIMENTACAO = 201811 (6 digitos AAAAMM); DT_COMPETENCIA = 201901.
     Os dois diferem (movimentacao retroativa - esperado no CAGED).
   - Prefixo V1_FATOS_CAGED_TRABS_AJUSTADO_.../part-00000-...c000.csv (separador ',',
     SEM header, campos entre aspas): colunas 2 e 3 = 201203 e 201203 (AAAAMM).

2) Transformacao (OCI Data Integration) - lido do objeto publicado da task:
   - Task      : TASK_FATOS_CAGED_TRABS_AJUSTADO (key 2a76bf00-06e4-4587-b8ff-357c40af75d5)
   - Data flow : DF_FATOS_CAGED_TRABS_AJUSTADO (application APL_BGETRAB_2, PROD)
   - Campo derivado: EXP_DT_COMPETENCIA_MOVIMENTACAO
       expr-string: CAST(EXPRESSION_1.ARQ_FATOS_CAGED_TRABS_AJUSTADO.DT_COMPETENCIA_MOVIMENTACAO AS NUMERIC)
       tipo de saida: NUMERIC com length=6, scale=0  -> NUMBER(6,0)
   - DT_COMPETENCIA tem tratamento identico (CAST AS NUMERIC, length 6, scale 0).
   - Como e NUMBER(6,0) (sem conversao para DATE), o inteiro AAAAMM e preservado
     exatamente (ex.: 201811 entra como o numero 201811). NAO ha perda de formato.

3) Carga (ADW) - historico de runs:
   - Cargas 2002-2006 (e 1996/1997/1999 aptas) terminaram SUCCESS, sem nenhum erro
     relacionado a esta coluna. Os incidentes anteriores foram em outras colunas
     (salario, idade, desalinhamento por ';' no nome).

CONCLUSAO: nao ha defeito no formato de DT_COMPETENCIA_MOVIMENTACAO; e carregado como
NUMBER(6,0) contendo o inteiro AAAAMM.

Observacoes:
  - Semantica (nao formato): em algumas linhas DT_COMPETENCIA e DT_COMPETENCIA_MOVIMENTACAO
    vem iguais (ex.: 201203/201203); em outras diferem (ex.: 201901/201811). Diferenca e
    esperada (movimentacao retroativa). Se a regra de negocio exigir sempre distintos e
    aparecerem iguais, e questao de conteudo da ORIGEM (BODS), nao da carga.

Verificacao definitiva (so via SQL no ADW - OCI CLI nao executa SQL):
    SELECT column_name, data_type, data_length, data_precision, data_scale
    FROM   all_tab_columns
    WHERE  owner='BGETRAB_OAC' AND table_name='V1_FATOS_CAGED_TRABS_AJUSTADO'
      AND  column_name='DT_COMPETENCIA_MOVIMENTACAO';
    -- esperado: data_type=NUMBER, data_precision=6, data_scale=0

    SELECT COUNT(*) AS fora_do_padrao
    FROM   BGETRAB_OAC.V1_FATOS_CAGED_TRABS_AJUSTADO
    WHERE  NOT REGEXP_LIKE(TO_CHAR(DT_COMPETENCIA_MOVIMENTACAO), '^[0-9]{4}(0[1-9]|1[0-2])$');
    -- esperado: 0

Comando usado para ler a transformacao (reuso):
    oci data-integration application list-published-objects --workspace-id <ws> --application-key dbd6181d-c908-43c0-824e-6f78ee385750 --all
    oci data-integration application get-published-object --workspace-id <ws> --application-key dbd6181d-c908-43c0-824e-6f78ee385750 --published-object-key 2a76bf00-06e4-4587-b8ff-357c40af75d5
  (NOTA: data flows nao aparecem em "data-flow list" no workspace de PROD, pois estao
   publicados na application; usar list-published-objects/get-published-object.)

### DIAGNOSTICO - DT_COMPETENCIA_MOVIMENTACAO TRUNCADO (perda de zero a esquerda) - 2026-10-19

Sequencia da pergunta anterior (formato AAAAMM): a CARGA grava correto (CAST AS NUMERIC(6,0)),
mas a ORIGEM (CSV gerado pelo BODS) entrega valores corrompidos em DT_COMPETENCIA_MOVIMENTACAO
para alguns anos. Hipotese (b) do usuario CONFIRMADA.

#### Sintoma (dados reais do bucket, amostragem por range download)

O campo DT_COMPETENCIA_MOVIMENTACAO (coluna 3 do CSV) sai com MENOS de 6 digitos em
varios anos - perdeu zero/digitos a esquerda. DT_COMPETENCIA (coluna 2) NAO apresenta o
defeito em nenhuma amostra.

Exemplos (C2 = DT_COMPETENCIA correta; C3 = DT_COMPETENCIA_MOVIMENTACAO defeituosa):
  1996: C2=199609 -> C3='9619' / '99601'   (deveria ser ~199601/199609)
  2000: C2=200002 -> C3='20'               (deveria ser ~200012/200002)
  2001: C2=200109 -> C3='120'              (deveria ser ~200112)

#### Escopo (amostra do inicio de cada arquivo - 30-60 MB)

| Ano  | % fora de AAAAMM | Situacao |
|------|------------------|----------|
| 1996 | 64,1%            | AFETADO  |
| 1997 | 0%               | ok       |
| 1998 | CSV vazio        | a parte (ver secao 1998) |
| 1999 | 0%               | ok       |
| 2000 | 50,2%            | AFETADO  |
| 2001 | 48,0%            | AFETADO  |
| 2002 | 0%               | ok       |
| 2003 | 0,1%             | AFETADO (marginal) |
| 2004-2010 | 0%          | ok       |
| 2011 | 47,9%            | AFETADO  |
| 2012-2019 | 0%          | ok       |

Ressalva: amostragem do inicio dos arquivos; para fechar 100% por ano, varrer o arquivo
inteiro. O padrao ja basta para orientar a correcao (que deve blindar TODOS os anos).

#### CAUSA RAIZ (confirmada no ATL original)

Arquivo analisado: C:\Projetos - Dataprev\bgetrab\pacotes\etl\P_BGE_ETL_001_MIGRA_CAGED_V1.atl
(474.797 bytes, modificado 2026-10-16 12:25).

A coluna DT_COMPETENCIA_MOVIMENTACAO e declarada e mapeada como INT em TODAS as camadas,
inclusive no datastore de saida do LOAD FILE (CSV):
  - Staging/tabelas: linhas 314 (INT NOT NULL), 697 (INT NULL), 876 (INT KEY NOT NULL).
  - Views que alimentam o CSV (QRY_DADOS, QRY_TRATAMENTO, QRY_TRATAMENTO_1, QRY_DADOS_1):
    DT_COMPETENCIA_MOVIMENTACAO INT SET("ui_mapping_text" = '....DT_COMPETENCIA_MOVIMENTACAO')
    e no SELECT o valor e passado CRU (sem is_valid_int/to_decimal/lpad), ao contrario das
    demais numericas que receberam tratamento defensivo.
  - Faz parte da PK FGTA_PK (linhas 764/924) e do PARTITION BY RANGE (linha 382) -> valor
    corrompido afeta unicidade/particionamento, nao so o dado.

Mecanismo: ao gravar um INT como texto no CSV, o BODS escreve a representacao decimal SEM
zero a esquerda. Como AAAAMM pode "comecar" de forma que o int suprime digitos (ex.:
199601 -> 99601 -> 9601 / 9619; 200012 -> 20; 200112 -> 120), o campo sai com 2-5 digitos.

Nota: DT_COMPETENCIA (tambem INT, tambem passada crua) nao deu defeito nas amostras, mas
tem a MESMA vulnerabilidade; a correcao deve cobrir as duas.

#### CORRECAO RECOMENDADA (na origem / BODS)

Forcar saida como TEXTO de 6 posicoes com zero a esquerda (AAAAMM). O passo DECISIVO e
mudar o tipo de saida da coluna no datastore do LOAD FILE de INT para varchar(6); senao o
lpad e reconvertido para int e perde o zero de novo.

Expressao (na camada comum QRY_TRATAMENTO do DF2, que cobre os dois ramos - mesma
estrategia usada para o saneamento do ';' no nome):
    ifthenelse( is_valid_int(ltrim_blanks(rtrim_blanks(cast(<PREFIXO>.DT_COMPETENCIA_MOVIMENTACAO,'varchar(20)'))), '######') = 1,
                lpad(ltrim_blanks(rtrim_blanks(cast(<PREFIXO>.DT_COMPETENCIA_MOVIMENTACAO,'varchar(20)'))), 6, '0'),
                <PREFIXO>.DT_COMPETENCIA_MOVIMENTACAO )

Checklist:
  - Mudar o tipo de saida da coluna (CSV) de INT para varchar(6) nas views/datastore de LOAD FILE.
  - Aplicar o mesmo em DT_COMPETENCIA por consistencia/seguranca.
  - Fazer na camada comum (QRY_TRATAMENTO do DF2) para cobrir movimentacoes + acertos.
  - Validar no BODS Designer (Validate All).
  - Regerar os CSVs (minimo: 1996, 2000, 2001, 2003, 2011; ideal: TODOS os anos).
  - Re-subir ao bucket e recarregar via TASK_FATOS_CAGED_TRABS_AJUSTADO.
  - Reconferir: 0 linhas com DT_COMPETENCIA_MOVIMENTACAO fora de ^\d{6}$ (mes 01-12).

OBS: a carga no ADW (CAST AS NUMERIC(6,0)) nao conserta o valor truncado - ela apenas grava
o que vier no CSV. Por isso a correcao TEM que ser na origem (BODS). O _corrigido.atl
anterior tratou salario/idade/desalinhamento/PII, mas NAO este truncamento.

### ANALISE DO ATL (origem BODS) + CORRECAO DT_COMPETENCIA_MOVIMENTACAO - 2026-10-19

Arquivo analisado (gera os CSVs): C:\Projetos - Dataprev\bgetrab\pacotes\etl\P_BGE_ETL_001_MIGRA_CAGED_V1.atl
(somente leitura; nada foi alterado). Restricao de negocio: o campo DEVE permanecer
numerico (INT/NUMBER) - NAO pode virar varchar(6) no modelo.

#### Resultado do teste de recuperabilidade (LPAD) - decisivo

Testou-se se o valor truncado no CSV poderia ser reconstruido so com padding de zero a esquerda:
  1996: C2=199609 C3='9619'  -> LPAD='009619'  (implausivel)
  2000: C2=200002 C3='20'    -> LPAD='000020'  (implausivel)
  2001: C2=200109 C3='120'   -> LPAD='000120'  (implausivel)
  2011: C2=201102 C3='1120'  -> LPAD='001120'  (implausivel)
100% dos defeituosos ficam IMPLAUSIVEIS com LPAD -> houve perda de DIGITOS SIGNIFICATIVOS,
nao so de zero a esquerda. CONCLUSAO: reparar na CARGA do ADW (COPY/LPAD/SQL) esta DESCARTADO -
o CSV atual e irrecuperavel para os anos afetados. A correcao tem de ser na ORIGEM + regerar.

#### Cadeia do campo no data flow que gera o CSV (DF_BGE_ETL_001_ARQ_FT_TRAB_AJUST)

  1. READ TABLE DWCAGED.DWCAGED.FATOS_CAGED_TRABS_AJUSTADO (linha ~1817) - origem.
  2. QRY_DADOS (~1827): DT_COMPETENCIA_MOVIMENTACAO INT, mapeamento direto, sem tratamento.
  3. QRY_TRATAMENTO (~1884): DT_COMPETENCIA_MOVIMENTACAO INT, PASSADO CRU
     ('QRY_DADOS.DT_COMPETENCIA_MOVIMENTACAO'), enquanto as demais numericas tem
     ifthenelse(is_valid_int(...), to_decimal(...), default). DT_COMPETENCIA idem (cru).
  4. LOAD FILE ARQ_FT_TRAB_AJUSTADO (linha 1340): CREATE FILE DATASTORE (Field1 VARCHAR(100)),
     column_delimiter ';', file_name $PG_ARQ_FATO. O destino do CSV e um datastore de
     arquivo GENERICO (Field1 VARCHAR(100)) - a saida do CSV ja e textual.
  (Mesma situacao no DF_0/QRY_ANONIMIZACAO e no ramo de acertos QRY_DADOS_1/QRY_TRATAMENTO_1.)

#### Esclarecimento: NAO e preciso mudar o tipo para varchar(6)

Duvida levantada: ao aplicar to_char(..., '000000') tenho de trocar o tipo para varchar(6)?
RESPOSTA: NAO. Motivos:
  - A tabela no ADW continua NUMBER (nao se mexe).
  - A coluna nas views do BODS continua INT no modelo; muda-se apenas a EXPRESSAO de mapeamento.
  - O destino do CSV e Field1 VARCHAR(100) generico (linha 1340): NAO existe "coluna INT de
    arquivo" para alterar. to_char(...) retorna string e vai direto ao texto do CSV.
  - Na volta, DBMS_CLOUD.COPY_DATA le o texto '199601' e grava como NUMBER(6) no ADW.
A mencao anterior a varchar(6) era de OUTRA proposta (ja descartada); nao se aplica ao ATL.
Observacao: a mudanca de tipo so importaria se a view final tivesse coluna de saida
declarada como INT que reconvertesse o to_char para inteiro - NAO e o caso aqui
(destino = VARCHAR(100) generico).

#### Correcao apontada (manter numerico)

Nas views de tratamento (QRY_TRATAMENTO do DF2 - camada comum aos dois ramos, mesma usada
para o saneamento do ';' no nome), trocar o mapeamento CRU por formatacao de 6 digitos:
    to_char(QRY_DADOS.DT_COMPETENCIA_MOVIMENTACAO, '000000')
Aplicar tambem em DT_COMPETENCIA por seguranca. Nao alterar o tipo do campo.

#### RESSALVA CRITICA - validar a ORIGEM antes (to_char nao recupera digito perdido)

Como o LPAD provou perda de digitos significativos, se o valor JA CHEGA truncado na tabela
DWCAGED.FATOS_CAGED_TRABS_AJUSTADO, o to_char('000000') vai formatar o valor ERRADO
(ex.: 200012 ja veio como 20 -> to_char gera '000020', nao '200012'). to_char conserta
PADDING, nao recupera digito.

TESTE DECISIVO (rodar na origem DWCAGED - SQL, nao e OCI CLI):
    SELECT DT_COMPETENCIA, DT_COMPETENCIA_MOVIMENTACAO,
           LENGTH(TO_CHAR(DT_COMPETENCIA_MOVIMENTACAO)) AS tam
    FROM   DWCAGED.FATOS_CAGED_TRABS_AJUSTADO
    WHERE  DT_COMPETENCIA BETWEEN 200001 AND 200012
    FETCH FIRST 20 ROWS ONLY;

Interpretacao:
  - tam = 6 em todos -> o dado na origem esta integro; o truncamento ocorre na leitura/
    escrita do BODS. Correcao: to_char('000000') na view + regerar os CSVs. Resolve.
  - tam = 2/3/4/5 -> o dado JA esta corrompido na tabela DWCAGED. Problema UPSTREAM (job que
    popula a DWCAGED). Nenhum ajuste neste ATL recupera o valor; corrigir a carga da DWCAGED.

#### Anos afetados (amostra do inicio dos CSVs) - para regerar apos corrigir

AFETADOS: 1996 (64%), 2000 (50%), 2001 (48%), 2011 (48%), 2003 (0,1%).
LIMPOS   : 1997, 1999, 2002, 2004-2010, 2012-2019.  1998: CSV vazio (problema a parte).
Ideal: blindar/regerar TODOS os anos, pois a vulnerabilidade (campo cru) e geral.

### RASTREAMENTO ATE A ORIGEM PRIMARIA - NU_COMPET_MOV - 2026-10-19

Confirmado por SQL (imagens do usuario) que o truncamento NAO esta no BODS que gera o CSV
nem na carga do ADW: o valor ja chega errado nas tabelas de origem.

#### Evidencia 1 - tabela TP_TRAB_AJUST_2019 (origem/staging)
Consulta do usuario:
    DT_COMPETENCIA=199610 | DT_COMPETENCIA_MOVIMENTACAO=99601 | tam=5
    DT_COMPETENCIA=199612 | DT_COMPETENCIA_MOVIMENTACAO=99621 | tam=5
-> valor com 5 digitos (perdeu o 1o digito do ano: 199601 -> 99601). JA corrompido na tabela.

#### Evidencia 2 - tipo das colunas em TP_TRAB_AJUST_2019 (all_tab_columns)
    DT_COMPETENCIA              NUMBER  precision=(null) scale=0
    DT_COMPETENCIA_MOVIMENTACAO NUMBER  precision=(null) scale=0
-> coluna de DESTINO e NUMBER sem precisao (cabe 6 digitos). O tipo da tabela NAO e a causa;
   o valor ja chega truncado de quem a popula.

#### Evidencia 3 - job que popula (P_BGE_ETL_001_DW_MIGRACAO_DARDO.atl)
Data flow DF_BGE_ETL_001_MIGRA_DARDO_TRAB:
  - READ TABLE DWCAGED.DWCAGED_SAPB.TP_CAGED_TRABALHADOR (tabela crua / staging SAPB).
  - QRY_DADOS (linha ~12529): primeiro mapeamento do campo:
        DT_COMPETENCIA              INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_DECLARADA   (nunca deu defeito)
        DT_COMPETENCIA_MOVIMENTACAO INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_MOV         (este trunca)
  - Ambos mapeados igual (direto, como INT). Como SO o NU_COMPET_MOV trunca, a corrupcao
    esta no VALOR/TIPO de NU_COMPET_MOV na tabela TP_CAGED_TRABALHADOR (origem primaria),
    nao no mapeamento INT do BODS.

#### Conclusao sobre a correcao

- to_char('000000') no job que gera o CSV NAO resolve: formatar 99601 daria '099601'
  (valor errado). to_char conserta padding, nao recupera digito perdido.
- A correcao tem de ser onde NU_COMPET_MOV e populado em TP_CAGED_TRABALHADOR (ingestao SAPB),
  ou mais acima (arquivo-fonte do CAGED/MTE). E preciso achar/validar essa carga.

#### TESTES PENDENTES NA ORIGEM (SQL - fora do OCI CLI)

1) Tipo e tamanho de NU_COMPET_MOV vs NU_COMPET_DECLARADA na tabela crua:
    SELECT column_name, data_type, data_precision, data_scale, char_length
    FROM   all_tab_columns
    WHERE  table_name = 'TP_CAGED_TRABALHADOR'
      AND  column_name IN ('NU_COMPET_MOV','NU_COMPET_DECLARADA');

2) Amostra de valores crus (ver se NU_COMPET_MOV ja vem com <6 digitos):
    SELECT NU_COMPET_DECLARADA, NU_COMPET_MOV,
           LENGTH(TO_CHAR(NU_COMPET_MOV)) AS tam_mov,
           LENGTH(TO_CHAR(NU_COMPET_DECLARADA)) AS tam_dec
    FROM   DWCAGED.DWCAGED_SAPB.TP_CAGED_TRABALHADOR
    FETCH FIRST 30 ROWS ONLY;

Interpretacao:
  - Se NU_COMPET_MOV ja vem com <6 digitos na TP_CAGED_TRABALHADOR -> corrigir a carga que
    popula essa tabela (ingestao do arquivo CAGED/MTE para a staging SAPB). E a causa raiz.
  - Se NU_COMPET_MOV estiver com 6 digitos corretos aqui -> o truncamento ocorre no proprio
    DF_BGE_ETL_001_MIGRA_DARDO_TRAB (improvavel, pois o mapeamento e identico ao de
    DT_COMPETENCIA que nao falha) -> investigar conversao especifica desse campo.

### CAUSA RAIZ CONFIRMADA - conversao VARCHAR2->INT trunca NU_COMPET_MOV - 2026-10-19

Virada no diagnostico: o dado na ORIGEM PRIMARIA esta CORRETO. A corrupcao e introduzida
pela CONVERSAO de tipo no BODS (texto -> inteiro), nao pela fonte.

#### Evidencias (SQL do usuario sobre DWCAGED.DWCAGED_SAPB.TP_CAGED_TRABALHADOR)

Tipo das colunas (all_tab_columns):
  NU_COMPET_DECLARADA  VARCHAR2(100)
  NU_COMPET_MOV        VARCHAR2(100)
  -> AMBAS sao TEXTO na origem crua.

Amostra de valores (30 linhas):
  NU_COMPET_DECLARADA='199601'  NU_COMPET_MOV='199601'  tam_mov=6  tam_dec=6
  -> na origem o valor esta INTEGRO: '199601', 6 digitos. NAO esta corrompido na fonte.

#### Onde o dado e destruido

Job: P_BGE_ETL_001_DW_MIGRACAO_DARDO.atl, data flow DF_BGE_ETL_001_MIGRA_DARDO_TRAB,
view QRY_DADOS (linha ~12529):
    DT_COMPETENCIA              INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_DECLARADA
    DT_COMPETENCIA_MOVIMENTACAO INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_MOV
A origem e VARCHAR2('199601') e o destino e declarado INT. A conversao implicita
texto->inteiro TRUNCA ('199601' -> 99601), provavelmente por inteiro de precisao
insuficiente no destino implicito do BODS. E AQUI que o 6o digito se perde.

Cadeia da corrupcao (de tras pra frente, agora completa):
  CSV corrompido  <-  TP_TRAB_AJUST (NUMBER, ja truncado)  <-  DF_MIGRA_DARDO_TRAB QRY_DADOS
  (conversao VARCHAR2->INT)  <-  TP_CAGED_TRABALHADOR.NU_COMPET_MOV (VARCHAR2 '199601', CORRETO)

#### BOA NOTICIA: dado recuperavel

Como a origem (TP_CAGED_TRABALHADOR) tem o valor correto em texto, NAO e preciso reprocessar
desde o arquivo-fonte do CAGED. Basta corrigir a conversao no job DARDO e reprocessar a cadeia.

#### CORRECAO RECOMENDADA (mantem numerico - respeita a regra da empresa)

No DF_BGE_ETL_001_MIGRA_DARDO_TRAB, view QRY_DADOS, trocar o mapeamento direto por conversao
numerica explicita a partir do texto (converte sem truncar; resultado continua numerico):
    to_decimal(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '.', '', 0)
  ou com validacao (padrao do proprio job):
    ifthenelse( is_valid_int(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '######') = 1,
                to_decimal(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '.', '', 0),
                0 )
Aplicar o mesmo em DT_COMPETENCIA (NU_COMPET_DECLARADA) por consistencia.
Verificar no BODS Designer o tipo/precisao de destino do campo em QRY_DADOS (se houver int de
5 posicoes, e ali que cai o 6o digito; o to_decimal forca a conversao correta de qualquer forma).

NAO e mais preciso o to_char('000000') no job que gera o CSV: com a origem (DARDO) corrigida,
o valor ja sai integro na TP_TRAB_AJUST e, consequentemente, no CSV.

#### Fluxo de correcao

  1. Corrigir conversao de NU_COMPET_MOV/NU_COMPET_DECLARADA no DF_BGE_ETL_001_MIGRA_DARDO_TRAB
     (P_BGE_ETL_001_DW_MIGRACAO_DARDO.atl) - to_decimal explicito. Validate All no BODS.
  2. Reprocessar o job DARDO -> regenera TP_TRAB_AJUST / FATOS_CAGED_TRABS_AJUSTADO com 6 digitos.
  3. Rodar o job que gera os CSVs (P_BGE_ETL_001_MIGRA_CAGED_V1) -> CSVs ja corretos.
  4. Re-subir ao bucket e recarregar via TASK_FATOS_CAGED_TRABS_AJUSTADO (anos afetados:
     1996, 2000, 2001, 2011, 2003; ideal: todos).
  5. Conferir: 0 linhas com DT_COMPETENCIA_MOVIMENTACAO fora de ^\d{6}$ (mes 01-12).

### VARREDURA COMPLETA DOS CSVs (DT_COMPETENCIA_MOVIMENTACAO) - estado - 2026-10-20

Objetivo: fechar a lista EXATA, por ano, de linhas com DT_COMPETENCIA_MOVIMENTACAO fora de
AAAAMM (a classificacao anterior "limpo/afetado" veio de AMOSTRAGEM do inicio dos CSVs, nao
de varredura completa). Lembrete: a causa raiz (conversao VARCHAR2->INT no job DARDO) e geral;
anos "limpos" na amostra podem ter linhas corrompidas em trechos nao amostrados.

#### Tamanho dos objetos (bucket-bgetrab-prod, coletado 2026-10-20)

Total ~160 GB em 23 arquivos (1998 vazio). Tamanhos (bytes):
  1996 4.313.695.524 | 1997 4.272.857.022 | 1998 966 (VAZIO) | 1999 3.951.780.434
  2000 4.416.825.897 | 2001 4.655.444.870 | 2002 4.816.105.961 | 2003 4.824.995.565
  2004 5.350.934.507 | 2005 5.906.936.853 | 2006 6.293.003.715 | 2007 6.914.800.940
  2008 8.086.967.892 | 2009 8.080.292.069 | 2010 9.292.764.336 | 2011 10.071.483.036
  2012 10.270.948.462 | 2013 10.514.378.355 | 2014 10.551.049.348 | 2015 9.137.159.316
  2016 7.697.730.150 | 2017 7.375.704.661 | 2018 7.703.611.656 | 2019 8.093.205.186

#### Metodo (streaming por blocos - nao baixa arquivo inteiro)

Script: C:\Users\angel\AppData\Local\Temp\scan_full.ps1 (temporario; pode nao persistir).
  - Para cada ano, baixa blocos sequenciais de 256 MB via --range "bytes=ini-fim".
  - Conta linhas e as com coluna 3 (DT_COMPETENCIA_MOVIMENTACAO) fora de ^\d{6}$ (sep ';').
  - Trata a FRONTEIRA entre blocos: guarda a ultima linha parcial (carry) e concatena no
    inicio do bloco seguinte, evitando contar linha cortada em dobro ou perder.
  - Pula o header (1a linha com 'DT_COMPETENCIA').
  - Remove cada bloco apos processar (nao acumula em disco).
  Parametros: -Ano <int> -Size <bytes>.

#### STATUS: NAO CONCLUIDA (interrompida)

A execucao da varredura completa de 1996 foi iniciada e CANCELADA pelo usuario antes de
terminar. Nenhum resultado de varredura completa foi coletado ainda. A sessao OCI expirou
2x durante o processo (reautenticada via oci session authenticate / perfil bgetrab-session).

PENDENTE:
  - Reautenticar a sessao (se necessario) e rodar scan_full.ps1 para os anos 1996-2019
    (pular 1998 vazio). Guardar total_linhas, fora_AAAAMM e pct por ano.
  - Alternativa mais leve, se a varredura completa for custosa: aceitar a lista por amostragem
    (afetados confirmados: 1996, 2000, 2001, 2003, 2011) e, como a vulnerabilidade e geral,
    corrigir o job DARDO + regerar TODOS os anos (nao depende da contagem exata).

#### Lista por AMOSTRAGEM (ja registrada antes - confirmada, nao exaustiva)

AFETADOS (certos): 1996 (~64%), 2000 (~50%), 2001 (~48%), 2011 (~48%), 2003 (~0,1%).
LIMPOS na amostra (nao garante arquivo inteiro): 1997,1999,2002,2004-2010,2012-2019.
1998: CSV vazio (so header) - problema a parte.

### VERIFICACAO DE ADERENCIA - CSVs 2000, 2001 E 2011 (regerados 2026-10-19) - 2026-10-20

Pedido: verificar se os CSVs de 2000, 2001 e 2011 no bucket-bgetrab-prod estao aderentes
a TODOS os problemas tratados. Os tres foram REGERADOS em 2026-10-19 (versoes novas, posteriores
ao diagnostico do truncamento), portanto reanalisados do zero (nao vale a classificacao antiga).

Metadados (coletados 2026-10-20):
| Ano  | Tamanho (bytes)   | Last-modified (UTC)      | Version-id                           |
|------|-------------------|--------------------------|--------------------------------------|
| 2000 | 4.416.825.897     | 2026-10-19 18:38:57Z     | 94c7c35f-841d-44e8-bb72-d6ffbcf64a58 |
| 2001 | 4.655.444.870     | 2026-10-19 18:38:03Z     | e8e9ae52-2cfa-444d-a3dc-b29bdc4fe99f |
| 2011 | 10.180.601.441    | 2026-10-19 21:38:19Z     | fc16eaf0-86af-4d0e-8103-0c1170a7c112 |
(2011 mudou de 10.071.483.036 para 10.180.601.441 bytes -> confirma regeracao.)

Varredura via OCI CLI (range: inicio 80 MB + meio 4 MB + fim 4 MB), ~410 mil linhas/ano:

| Criterio                              | 2000           | 2001           | 2011           |
|---------------------------------------|----------------|----------------|----------------|
| Estrutura (50 campos)                 | OK (0 desal.)  | OK (0)         | OK (0)         |
| VL_SALARIO_MENSAL_DECLARADO vazio     | OK (0)         | OK (0)         | OK (0)         |
| NU_IDADE_TRABALHADOR vazio            | OK (0)         | OK (0)         | OK (0)         |
| NU_CPF_TRABALHADOR mascarado          | OK (~100%)     | OK (~100%)     | OK (~100%)     |
| NU_PIS_TRABALHADOR mascarado          | OK (~100%)     | OK (~100%)     | OK (~100%)     |
| DT_COMPETENCIA_MOVIMENTACAO (AAAAMM)  | FALHA 61,71%   | FALHA 56,62%   | FALHA 32,74%   |

(A unica linha "nao mascarada" por ano e a LINHA DE CABECALHO - header tem NU_CPF/NU_PIS literais, sem '*' - nao PII em claro. Ver correcao do scan_menu.ps1 em 2026-10-20.)

CONCLUSAO: aderentes a 5 dos 6 problemas (desalinhamento, salario, idade, mascara CPF, mascara PIS).
NAO aderentes ao TRUNCAMENTO de DT_COMPETENCIA_MOVIMENTACAO - defeito presente e em larga escala
(2000 ~62%, 2001 ~57%, 2011 ~33% das linhas fora de AAAAMM). Esperado: a correcao desse problema
exige ajustar a conversao VARCHAR2->INT no job DARDO (P_BGE_ETL_001_DW_MIGRACAO_DARDO, view QRY_DADOS)
e reprocessar a cadeia - o que ainda NAO foi aplicado. O ATL v4 (refletido nesses CSVs) tratou
salario/idade/desalinhamento/PII, mas NAO o truncamento.

ACAO: NAO carregar 2000, 2001 e 2011 ainda (entrariam no ADW com DT_COMPETENCIA_MOVIMENTACAO
corrompida, como ja ocorreu com 1996). Corrigir o job DARDO, regerar os CSVs destes anos e so
entao disparar a TASK_FATOS_CAGED_TRABS_AJUSTADO.

### VARREDURA (AMOSTRAGEM) DE DT_COMPETENCIA_MOVIMENTACAO - TODOS OS ANOS - CONCLUIDA 2026-10-20

Executada via scripts/scan_menu.ps1 (menu interativo), modo Amostragem (inicio 80 MB + meio 4 MB
+ fim 4 MB), foco DT_COMPETENCIA_MOVIMENTACAO. ~400 mil linhas amostradas por ano. Rodada pelo
usuario em outro terminal; resultados consolidados aqui. Supera a classificacao anterior, que vinha
so do INICIO dos arquivos (e subestimava anos como 2002 e 2003).

| Ano  | Linhas amostradas | DT_COMPETENCIA_MOVIMENTACAO fora de AAAAMM | Situacao |
|------|-------------------|--------------------------------------------|----------|
| 1996 | 409.160 | 226.317 (55,31%) | AFETADO |
| 1997 | 407.654 | 1 (0,00%)        | limpo (amostra) |
| 1998 | - (CSV vazio)     | -                | SEM DADOS |
| 1999 | 407.584 | 1 (0,00%)        | limpo (amostra) |
| 2000 | 412.266 | 254.402 (61,71%) | AFETADO |
| 2001 | 411.143 | 232.804 (56,62%) | AFETADO |
| 2002 | 408.480 | 13.456 (3,29%)   | AFETADO |
| 2003 | 408.817 | 46.983 (11,49%)  | AFETADO |
| 2004 | 408.792 | 1 (0,00%)        | limpo (amostra) |
| 2005 | 409.669 | 1 (0,00%)        | limpo (amostra) |
| 2006 | 410.046 | 1 (0,00%)        | limpo (amostra) |
| 2007 | 416.142 | 1 (0,00%)        | limpo (amostra) |
| 2008 | 413.868 | 1 (0,00%)        | limpo (amostra) |
| 2009 | 414.101 | 1 (0,00%)        | limpo (amostra) |
| 2010 | 413.425 | 1 (0,00%)        | limpo (amostra) |
| 2011 | 410.638 | 134.450 (32,74%) | AFETADO |
| 2012 | 411.916 | 1 (0,00%)        | limpo (amostra) |
| 2013 | 415.818 | 1 (0,00%)        | limpo (amostra) |
| 2014 | 413.299 | 1 (0,00%)        | limpo (amostra) |
| 2015 | 411.774 | 1 (0,00%)        | limpo (amostra) |
| 2016 | 409.523 | 1 (0,00%)        | limpo (amostra) |
| 2017 | 409.090 | 1 (0,00%)        | limpo (amostra) |
| 2018 | 403.632 | 1 (0,00%)        | limpo (amostra) |
| 2019 | 403.990 | 1 (0,00%)        | limpo (amostra) |

Nota (CORRIGIDA 2026-10-20): em todos os anos a Estrutura (50 campos) deu 0 desalinhamentos.
O "1" fora de AAAAMM dos anos limpos NAO era artefato de fronteira de bloco - era a LINHA DE
CABECALHO. O header tem 50 campos e, na coluna 3, o texto literal "DT_COMPETENCIA_MOVIMENTACAO".
O filtro de descarte do header no scan_menu.ps1 estava com prefixo errado (DT_COMPETENCIA*), mas a
1a coluna do header e ID_SEQ_FATOS_CAGED_TRAB_AJUS, entao o header escapava e somava 1. CONCLUSAO:
nos anos limpos o valor REAL de linhas de dados fora de AAAAMM e 0 (o "1" era so o header); nos
AFETADOS o valor real e N-1 (diferenca desprezivel). Filtro corrigido: DT_COMPETENCIA* -> ID_SEQ_FATOS*.
A classificacao afetado/limpo NAO muda.

AFETADOS pelo truncamento (6 anos): 1996, 2000, 2001, 2002, 2003, 2011.
LIMPOS na amostra (16 anos): 1997, 1999, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
                             2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019.
SEM DADOS: 1998 (CSV vazio).

MUDANCA vs amostragem anterior (so inicio): 2002 e 2003 eram tidos como limpos/marginais e
revelaram-se AFETADOS (3,29% e 11,49%). Lista de afetados subiu de 5 para 6.

Cruzamento com o estado do ADW (V1_FATOS_CAGED_TRABS_AJUSTADO):
  - Carregados E AFETADOS (PRECISAM RECARGA apos corrigir DARDO): 1996, 2002, 2003.
  - Carregados e limpos na amostra: 1997, 1999, 2004, 2005, 2006.
  - AFETADOS e ainda NAO carregados: 2000, 2001, 2011 (NAO carregar antes da correcao).

Ressalva de metodo: amostragem nao cobre 100%. Para os "limpos" que ja estao no ADW (1997, 1999,
2004, 2005, 2006), convem confirmar com modo Completo + foco 1 antes de descarta-los da recarga
em definitivo - 2002/2003 mostraram que o inicio do arquivo enganava.

PROXIMO PASSO: corrigir a conversao VARCHAR2->INT de NU_COMPET_MOV/NU_COMPET_DECLARADA no job
DARDO (P_BGE_ETL_001_DW_MIGRACAO_DARDO, view QRY_DADOS), reprocessar a cadeia, regerar os CSVs
dos anos afetados e recarregar via TASK_FATOS_CAGED_TRABS_AJUSTADO.

### FERRAMENTA scripts/scan_menu.ps1 - varredura interativa dos CSVs - 2026-10-20

Criado nesta sessao para substituir o antigo scan_full.ps1 (temporario, nao persistia).
Menu interativo, roda no terminal do usuario (usa Read-Host). Le o token OCI do disco a cada
chamada, entao a reautenticacao (oci session authenticate, perfil bgetrab-session) vale tanto
para o terminal do usuario quanto para o assistente.

Localizacao: C:\projetos\IA\bgetrab-agente\scripts\scan_menu.ps1
Uso: powershell -ExecutionPolicy Bypass -File .\scripts\scan_menu.ps1

Capacidades:
  - Lista os anos dinamicamente do bucket-bgetrab-prod (prefixo FATOS_CAGED_TRABS_AJUSTADO_),
    com tamanho em GB; marca 1998 como [VAZIO]. Escolha: um ano, ou T (todos), ou Q (sair).
  - Modo: [A]mostragem (inicio 80 MB + meio 4 MB + fim 4 MB, ~1 min/ano) ou [C]ompleto
    (streaming de blocos de 256 MB, le o arquivo inteiro, com progresso % e sem acumular disco;
    trata a linha de fronteira entre blocos via carry).
  - CRITERIOS com SELECAO MULTIPLA (separados por virgula) ou A para todos:
      [1] DT_COMPETENCIA_MOVIMENTACAO (AAAAMM)  [2] Estrutura (50 campos)
      [3] VL_SALARIO_MENSAL_DECLARADO vazio     [4] NU_IDADE_TRABALHADOR vazio
      [5] NU_CPF mascarado                      [6] NU_PIS mascarado
    Ex.: "1" | "1,4" | "3,5,6" | "A". So conta/exibe os criterios escolhidos (mais rapido).
    A Estrutura (contagem de 50 campos) e sempre calculada internamente (os demais dependem dela),
    mas so e exibida/gravada se [2] for escolhido.

Saida em arquivo (VERSIONADA - contem so contagens agregadas, SEM PII):
  - scripts/resultados/scan_resultados.csv  (colunas FIXAS, append; consolidacao previsivel)
      cabecalho: timestamp;ano;modo;criterios;linhas;desalinhadas;dtcmov_fora;dtcmov_pct;
                 sal_vazio;idade_vazio;cpf_masc;pis_masc;situacao;tempo_s
      (colunas de criterios nao escolhidos ficam vazias naquela linha)
  - scripts/resultados/scan_resultados.log  (bloco legivel, igual a tela, append)
  Ambos UTF-8 sem BOM. O .gitignore recebeu excecoes (!scripts/resultados/...) para versionar
  apenas esses dois arquivos, mantendo o bloqueio geral de *.csv/*.log (protege PII do CAGED).

Classificacao automatica (coluna situacao): avalia SO os criterios escolhidos. AFETADO se
estrutura/dtcmov/salario/idade tiverem problema; ATENCAO se CPF/PIS nao 100% mascarado; senao limpo.

CORRECAO IMPORTANTE (mesma sessao): o filtro de descarte do cabecalho estava errado
('DT_COMPETENCIA*'); a 1a coluna do header e ID_SEQ_FATOS_CAGED_TRAB_AJUS. Por isso o header
escapava e somava 1 em DTCMOV fora de AAAAMM (e 1 em CPF/PIS nao-mascarado) nos anos LIMPOS.
Corrigido para 'ID_SEQ_FATOS*'. A partir daqui, anos limpos mostram 0 (sem o 1 fantasma do header).
A classificacao afetado/limpo ja registrada NAO muda (ver secao da varredura por amostragem).

Armadilhas respeitadas (ja conhecidas do projeto): oci dentro de Start-Job com Wait-Job -Timeout;
CA bundle propagado ao job (OCI_CLI_CA_BUNDLE/REQUESTS_CA_BUNDLE/SSL_CERT_FILE); arquivos gravados
em UTF-8 sem BOM; nada de --query com aspas dentro do Start-Job.

### PROPOSTA DE CORRECAO DO JOB DARDO (entregue p/ aplicacao manual no BODS) - 2026-10-20

Status: PROPOSTA formalizada e entregue ao usuario para aplicacao MANUAL no BODS Designer.
O assistente NAO altera o BODS. Esta secao e a referencia da correcao a aplicar.

Problema: truncamento de DT_COMPETENCIA_MOVIMENTACAO (perde o 1o digito do ano, ex.: 199601 -> 99601).
Causa raiz confirmada: conversao implicita VARCHAR2->INT no job DARDO (a origem textual esta integra).

ONDE APLICAR:
  - Job/arquivo : P_BGE_ETL_001_DW_MIGRACAO_DARDO.atl
  - Data flow   : DF_BGE_ETL_001_MIGRA_DARDO_TRAB
  - View (Query): QRY_DADOS (aprox. linha 12529 no .atl)
  - Origem lida : DWCAGED.DWCAGED_SAPB.TP_CAGED_TRABALHADOR

MAPEAMENTO ATUAL (errado - conversao implicita texto->inteiro trunca):
  DT_COMPETENCIA              INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_DECLARADA
  DT_COMPETENCIA_MOVIMENTACAO INT  <- TP_CAGED_TRABALHADOR.NU_COMPET_MOV

CORRECAO - DT_COMPETENCIA_MOVIMENTACAO (campo que falhou):
  ifthenelse( is_valid_int(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '######') = 1,
              to_decimal(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '.', '', 0),
              0 )

CORRECAO - DT_COMPETENCIA (aplicar por consistencia, mesmo sem ter falhado):
  ifthenelse( is_valid_int(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_DECLARADA)), '######') = 1,
              to_decimal(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_DECLARADA)), '.', '', 0),
              0 )

VERSAO MINIMA (sem validacao), se preferir:
  to_decimal(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '.', '', 0)

ALTERNATIVA (se a instalacao NAO tiver is_valid_int):
  to_decimal( nvl(ltrim_blanks(rtrim_blanks(TP_CAGED_TRABALHADOR.NU_COMPET_MOV)), '0'), '.', '', 0)

POR QUE RESOLVE:
  - ltrim_blanks/rtrim_blanks tiram espacos/\r residuais do texto.
  - to_decimal(..., '.', '', 0) converte '199601' no numero 199601 de forma explicita e completa,
    sem a truncagem do INT implicito. Resultado continua NUMERICO (respeita a regra da empresa).
  - is_valid_int + ifthenelse(...,0) protege contra valor nao-numerico (grava 0, padrao do job).

PONTO CRITICO (conferir no Designer): o tipo/escala de DESTINO de DT_COMPETENCIA_MOVIMENTACAO (e
DT_COMPETENCIA) na saida da QRY_DADOS e nas camadas seguintes DEVE comportar 6 digitos
(ex.: decimal(6,0) ou maior, ou int de 32 bits). Se o destino for inteiro estreito (ex.: 5 posicoes),
o 6o digito volta a cair ali, independentemente da expressao. to_decimal(...,0) gera decimal sem casas;
o destino precisa aceitar 6 digitos inteiros. NAO precisa mudar o campo para varchar.

PASSOS NO BODS:
  1. Abrir P_BGE_ETL_001_DW_MIGRACAO_DARDO -> DF_BGE_ETL_001_MIGRA_DARDO_TRAB -> view QRY_DADOS.
  2. Substituir o mapeamento direto de DT_COMPETENCIA_MOVIMENTACAO e DT_COMPETENCIA pelas expressoes acima.
  3. Conferir/ajustar o tipo de saida dessas colunas (comportar 6 digitos).
  4. Validate All (checar is_valid_int/to_decimal/ltrim_blanks; se faltar, usar a alternativa com nvl).
  5. Reprocessar o job DARDO -> regenera TP_TRAB_AJUST / FATOS_CAGED_TRABS_AJUSTADO com 6 digitos.
  6. Rodar P_BGE_ETL_001_MIGRA_CAGED_V1 -> CSVs ja corretos.
  7. Re-subir ao bucket e recarregar via TASK_FATOS_CAGED_TRABS_AJUSTADO os anos AFETADOS:
     1996, 2000, 2001, 2002, 2003, 2011 (ideal: blindar/regerar todos).

VERIFICACAO POS-CORRECAO:
  - CSV: 0 linhas com DT_COMPETENCIA_MOVIMENTACAO fora de ^\d{6}$ (mes 01-12) - usar scan_menu.ps1.
  - ADW (SQL):
      SELECT COUNT(*) AS fora_do_padrao
      FROM   BGETRAB_OAC.V1_FATOS_CAGED_TRABS_AJUSTADO
      WHERE  NOT REGEXP_LIKE(TO_CHAR(DT_COMPETENCIA_MOVIMENTACAO), '^[0-9]{4}(0[1-9]|1[0-2])$');
      -- esperado: 0

LEMBRETE: a correcao do _corrigido.atl (P_BGE_ETL_001_MIGRA_CAGED_V1) tratou salario/idade/
desalinhamento/PII, mas NAO este truncamento. Este e no job DARDO (upstream), job diferente.

### MELHORIA scan_menu.ps1 - refresh proativo da sessao por TEMPO - 2026-10-20

Motivo: a sessao OCI expirava durante varreduras longas, interrompendo a analise.

Implementado: refresh PROATIVO baseado em tempo (nao a cada bloco literalmente).
  - Variavel $REFRESH_MIN = 5 (minutos; ajustavel no topo do script).
  - Marcador $script:LastRefresh.
  - Funcao Maybe-Refresh chamada ANTES de cada bloco (amostragem e completo): se passaram
    >= REFRESH_MIN minutos desde o ultimo refresh, roda oci session refresh --profile bgetrab-session
    (Start-Job, timeout 45s, CA bundle propagado) e reinicia o contador; senao, nao faz nada.
  - Funcao Refresh-Session: retorna false se a saida tiver SSLError/expired/Abort/Error.
  - Se o refresh falhar (token ja expirou de vez), o script AVISA para rodar oci session authenticate
    e CONTINUA (nao aborta); nao re-tenta a cada bloco (espera o proximo intervalo).

Por que funciona: o refresh e feito enquanto o token AINDA esta valido, renovando antes de expirar.
E o oposto do que falhou nesta sessao (tentar refresh so depois de expirado, que nao funciona).

Ressalva: cobre expiracao por tempo-de-vida curto/inatividade. Nao supera a JANELA MAXIMA absoluta
do token de sessao OCI - se esta estourar numa varredura muito longa, so o oci session authenticate
(novo login no navegador) resolve.

### DESCOBERTA + SOLUCAO DE SESSAO (Opcao B) no scan_menu.ps1 - 2026-10-20

DESCARTADA a abordagem de refresh por tempo (secao anterior): NAO funciona neste ambiente.

Descobertas (confirmadas por diagnostico nesta sessao):
  1. oci session refresh SEMPRE falha aqui com CERTIFICATE_VERIFY_FAILED. O endpoint
     auth.sa-saopaulo-1.oraclecloud.com e interceptado (folha re-assinada marca Zscaler,
     emissor/raiz = Kaspersky CA thumbprint 8481...). A raiz Kaspersky ESTA no bundle (144 certs)
     e NAO falta intermediario (cadeia tem so 2 niveis: folha + raiz), mas o requests/Python do
     refresh ainda nao valida. A folha muda de thumbprint a cada conexao (re-assinatura dinamica).
     Conclusao: refresh e beco sem saida; nao insistir.
  2. O token de sessao dura ~60 MINUTOS exatos (lido do claim exp do JWT: iat 16:35:49 -> exp
     17:35:49). A leitura de Object Storage (oci os ...) continua funcionando normalmente com o
     token valido - o problema e SO o endpoint de auth (refresh/authenticate).
  Efeito: varredura por amostragem (rapida) cabe em 1h; varredura COMPLETA de anos de 7-10 GB
  passa de 1h e estoura a janela -> sessao cai no meio.

SOLUCAO ADOTADA (Opcao B - aviso proativo de expiracao):
  - Removidos $REFRESH_MIN / Refresh-Session / Maybe-Refresh.
  - $SESSION_MARGIN_MIN = 3 (minutos de margem).
  - Get-TokenExpiry: le o security_token_file do perfil (via config) e decodifica o claim exp do
    JWT (base64url) para saber quando expira. NAO expoe o token. Testada: leu exp corretamente.
  - Ensure-SessionTime: chamada ANTES de cada bloco (amostragem e completo). Se faltar menos que
    SESSION_MARGIN_MIN para expirar, PAUSA, instrui o usuario a rodar
    "oci session authenticate --region sa-saopaulo-1" (perfil bgetrab-session) no outro terminal,
    aguarda ENTER, rele o exp e so continua quando houver folga. Loop ate a sessao ter folga.
  - Resultado: o script NUNCA perde a sessao (pausa antes), mantem os contadores na memoria (sem
    checkpoint em disco, sem reprocessar blocos). Custo: uma pausa manual de login a cada ~1h.

Observacao: como o token vale 60 min, uma varredura completa longa tera 1 pausa de login por hora.
Para rodar varios anos grandes no modo Completo, esperar as pausas ou dividir por ano/sessao.
