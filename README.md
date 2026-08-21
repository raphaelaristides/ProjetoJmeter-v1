# Projeto JMeter - POC de Testes de Performance com Jenkins

Este projeto é uma **POC (Proof of Concept)** criada para demonstrar uma forma simples de estruturar e automatizar testes de performance utilizando **Apache JMeter + Jenkins**.

A ideia não é apresentar uma solução pronta para produção, mas demonstrar uma arquitetura que pode servir como ponto de partida para ambientes profissionais, adaptando cenários, volumes de carga, critérios de aceite e infraestrutura conforme a necessidade de cada projeto.

## Objetivo

O objetivo da POC foi construir um fluxo onde os testes de performance não dependessem apenas da execução manual pelo JMeter.

O projeto permite:

* executar diferentes cenários de carga;
* parametrizar usuários, ramp-up e duração;
* utilizar massa de dados externa;
* simular um fluxo completo de usuário;
* gerar resultados em `.jtl`;
* gerar o dashboard HTML do JMeter;
* integrar a execução com Jenkins;
* validar automaticamente indicadores de performance;
* aprovar ou reprovar a pipeline de acordo com critérios definidos.

Dessa forma, o teste de performance passa a fazer parte de um processo automatizado de validação.

---

## Tecnologias utilizadas

* Apache JMeter 5.6.3
* Jenkins
* PowerShell
* Batch Script
* Git / GitHub
* CSV/TXT para massa de dados

---

## Aplicação utilizada

Para a POC foi utilizada a aplicação pública:

**Automation Exercise**

O fluxo desenvolvido simula algumas das principais ações de um usuário em um e-commerce.

---

## Fluxo do teste

O cenário foi dividido utilizando **Transaction Controllers**, permitindo analisar o tempo das principais etapas do fluxo separadamente.

### TR01 - Login

Responsável pela autenticação do usuário.

Durante o fluxo também é realizada a captura dinâmica do `csrfmiddlewaretoken`, utilizado posteriormente no processo de autenticação.

As credenciais são obtidas através de uma massa externa localizada em:

```text
Massa/usuarios.txt
```

### TR02 - Navegação do Produto

Simula a navegação pela área de produtos e categorias da aplicação.

### TR03 - Carrinho

Realiza as ações relacionadas à inclusão e visualização de produtos no carrinho.

### TR04 - Checkout

Executa o fluxo de checkout da aplicação.

### TR05 - Pagamento

Executa o processo de pagamento e finalização do pedido.

Essa separação permite analisar não apenas o tempo total do teste, mas principalmente o comportamento de cada etapa importante da jornada.

---

## Parametrização do JMeter

O Thread Group utiliza propriedades do JMeter para receber os valores de execução:

```text
users
rampup
duration
```

Exemplo:

```bash
-Jusers=10
-Jrampup=60
-Jduration=300
```

Isso permite utilizar o mesmo arquivo `ProjetoCSV.jmx` para diferentes níveis de carga, sem precisar manter vários arquivos JMX.

---

## Cenários disponíveis

A pipeline do Jenkins possui atualmente quatro cenários:

| Cenário    | Usuários | Ramp-up | Duração |
| ---------- | -------: | ------: | ------: |
| baseline-3 |        3 |     30s |    180s |
| load-10    |       10 |     60s |    300s |
| load-20    |       20 |     60s |    300s |
| load-50    |       50 |    120s |    600s |

O cenário pode ser escolhido diretamente no momento da execução da pipeline.

---

## Execução local

Também foram adicionados scripts `.bat` para facilitar execuções locais:

```text
scripts/
├── baseline.bat
├── load-10.bat
├── load-20.bat
└── load-50.bat
```

Exemplo de execução equivalente:

```bash
jmeter -n ^
-t ProjetoCSV.jmx ^
-Jusers=10 ^
-Jrampup=60 ^
-Jduration=300 ^
-l results/load-10.jtl ^
-e ^
-o reports/load-10
```

O parâmetro `-n` executa o JMeter em modo **non-GUI**, mais adequado para execuções automatizadas e testes de carga.

---

# Integração com Jenkins

O projeto possui um `Jenkinsfile` responsável pela automação do processo.

O fluxo implementado atualmente é:

```text
GitHub
   ↓
Jenkins
   ↓
Seleção do cenário
   ↓
Configuração da carga
   ↓
Validação do JMeter
   ↓
Preparação dos diretórios
   ↓
Execução do JMeter
   ↓
Geração do JTL
   ↓
Geração do Dashboard HTML
   ↓
Validação das evidências
   ↓
Análise dos indicadores
   ↓
Quality Gate
   ↓
PASS / FAIL
```

---

## Etapas da Pipeline

### 1. Configurar cenário

O Jenkins recebe o parâmetro `SCENARIO` e configura automaticamente:

```text
USERS
RAMPUP
DURATION
```

Também é criado um nome de execução utilizando o cenário e o número do build, facilitando o histórico das evidências.

---

### 2. Validar JMeter

Antes do teste, a pipeline verifica se o JMeter está disponível no agente Jenkins.

---

### 3. Preparar diretórios

São preparados os diretórios:

```text
results/
reports/
```

Arquivos de execuções conflitantes também são removidos antes do novo teste.

---

### 4. Executar JMeter

O Jenkins executa o JMeter através da linha de comando utilizando os parâmetros definidos para o cenário escolhido.

Como resultado são gerados:

```text
results/<cenario>-<build>.jtl

reports/<cenario>-<build>/
```

---

### 5. Validar evidências

Após a execução, a pipeline verifica se foram realmente gerados:

* arquivo `.jtl`;
* `index.html` do relatório JMeter.

Caso alguma evidência não exista, o build é considerado inválido.

---

# Performance Quality Gate

Um dos principais pontos desta POC é o script:

```text
scripts/Indicadores.ps1
```

Ele lê o arquivo JTL gerado pelo JMeter e aplica critérios automáticos de performance.

Ou seja, não é necessário abrir o dashboard manualmente para decidir se determinado teste passou ou falhou.

---

## Error Rate

O script analisa as Transaction Controllers:

```text
TR01
TR02
TR03
TR04
TR05
```

e calcula a porcentagem de transações com falha.

Na configuração atual da POC:

```text
Error Rate < 1%
```

Caso a taxa seja igual ou superior ao limite, o Quality Gate é reprovado.

---

## Percentil 95 - P95

Também é calculado o **P95** das principais transações.

O P95 representa o tempo abaixo do qual aproximadamente 95% das execuções daquela transação foram concluídas.

Atualmente foram definidos critérios para:

```text
TR02 - Navegação
TR03 - Carrinho
TR04 - Checkout
TR05 - Pagamento
```

Os limites utilizados nesta POC são apenas critérios de demonstração e devem ser ajustados de acordo com os requisitos não funcionais ou SLAs de cada aplicação.

---

## Resultado do Quality Gate

Quando todos os critérios são atendidos:

```text
QUALITY GATE: PASSED
```

Caso algum indicador fique fora do limite:

```text
QUALITY GATE: FAILED
```

O script retorna um código diferente de zero e o Jenkins marca a execução como falha.

Também é gerado um arquivo:

```text
<cenario>-<build>-quality-gate.txt
```

contendo o resumo da validação.

---

# Evidências

Ao final da execução são armazenados pelo Jenkins:

```text
results/**/*.jtl
results/**/*.txt
reports/**/*
```

Isso permite manter no próprio build:

* resultados brutos;
* resultado do Quality Gate;
* dashboard HTML;
* histórico das execuções.

---

# Execução automática

O Jenkinsfile também possui verificação periódica do SCM.

Dessa forma, alterações no repositório podem iniciar automaticamente uma nova execução da pipeline.

Em um ambiente profissional, essa estratégia poderia ser substituída ou complementada por Webhooks, pipelines de Pull Request ou integração com o fluxo de CI/CD da aplicação.

---

# Estrutura do projeto

```text
ProjetoJmeter-v1/
│
├── Massa/
│   └── usuarios.txt
│
├── scripts/
│   ├── Indicadores.ps1
│   ├── baseline.bat
│   ├── load-10.bat
│   ├── load-20.bat
│   └── load-50.bat
│
├── Jenkinsfile
├── ProjetoCSV.jmx
├── .gitignore
└── README.md
```

---

# Utilização em ambientes profissionais

Este projeto foi desenvolvido como uma **POC**, mas a ideia utilizada pode ser evoluída para ambientes reais.

Algumas possibilidades seriam:

* executar testes após deploy em ambiente de performance;
* integrar testes com pipelines de CI/CD;
* utilizar thresholds definidos através de requisitos não funcionais;
* comparar resultados entre versões da aplicação;
* impedir a promoção de uma versão quando houver regressão de performance;
* integrar métricas com Grafana, Prometheus ou InfluxDB;
* executar testes distribuídos com múltiplos agentes JMeter;
* armazenar histórico de performance;
* executar cenários diferentes dependendo do tipo de mudança;
* enviar notificações em caso de degradação.

Em um projeto real, os valores utilizados nesta POC devem ser substituídos por métricas definidas de acordo com a arquitetura, infraestrutura, SLAs/SLOs e comportamento esperado da aplicação.

---

# Ponto principal da POC

Mais do que simplesmente executar testes de carga, a proposta deste projeto foi experimentar uma abordagem onde **performance também pode funcionar como um critério automatizado de qualidade dentro do pipeline**.

```text
Executar → Medir → Comparar → Aprovar/Reprovar
```

Esse conceito pode ser aplicado como base para estratégias de **Continuous Performance Testing**, permitindo identificar regressões antes que elas cheguem aos ambientes produtivos.

---

## Repositório

https://github.com/raphaelaristides/ProjetoJmeter-v1
