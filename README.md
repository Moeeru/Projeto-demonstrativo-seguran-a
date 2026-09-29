# 🛡️ Projeto Demonstrativo de Segurança e Resiliência em Sistemas de Software

Laboratório prático desenvolvido para apresentações técnicas, defesas acadêmicas e demonstrações corporativas. O projeto aborda a segurança e a confiabilidade de ponta a ponta através de duas frentes interligadas:

1. **Segurança Ofensiva (Ataque):** Exploração prática de falhas de integridade na desserialização de dados (**OWASP A08:2021 — Software and Data Integrity Failures**) em um ambiente simulado de 3 máquinas em Docker.
2. **Engenharia Defensiva (Defesa):** Implementação de padrões de resiliência corporativa (**Atomicidade ACID**, **Idempotência por Chave Natural** e **Fail-Fast**) em uma API RESTful Spring Boot 3 integrada com PostgreSQL.

---

## 🎯 Objetivo do Laboratório

O objetivo central deste laboratório é **demonstrar empiricamente os perigos da perda de integridade de dados e as soluções de engenharia para construir sistemas corporativos resilientes e seguros**.

Ele responde na prática a duas perguntas críticas:
1. **Quão perigoso é confiar em dados serializados sem validação de integridade?**  
   Mostra como o uso ingênuo de `pickle` permite **Execução Remota de Código (RCE)**, exfiltração de dados confidenciais (LGPD) e destruição de bancos corporativos.
2. **Como garantir consistência em integrações e APIs sob falhas e retentativas?**  
   Mostra como falhas parciais criam **ordens órfãs** e como retentativas sem idempotência causam **duplicidades e cobranças indevidas**, demonstrando como **@Transactional**, **Idempotência** e **Fail-Fast** resolvem esses problemas.

---

## 📚 Assuntos Abordados

* **Segurança da Informação / AppSec:**
  * OWASP Top 10 (A08:2021 — Software and Data Integrity Failures)
  * Desserialização Insegura (Python Pickle e dunder method `__reduce__`)
  * Execução Remota de Código (RCE)
  * Integridade Criptográfica (Assinatura digital via HMAC-SHA256)
  * Pivotamento Interno e Privilege Hijacking (uso das credenciais legítimas da vítima pelo payload)
  * Princípio do Menor Privilégio no Banco de Dados (PoLP)
  * Vazamento de Dados e Conformidade (LGPD / GDPR)
* **Engenharia de Software & Arquitetura Backend:**
  * Princípios ACID e Atomicidade Transacional (`@Transactional` no Spring Boot)
  * Padrão de Idempotência em APIs e Webhooks (`Idempotency Keys`)
  * Padrão Fail-Fast com Bean Validation (`@Valid`, Hibernate Validator)
  * Isolamento de Infraestrutura e Sandbox em Containers (Docker & Docker Compose)

> 💡 **Nota sobre o ciclo de vida dos arquivos na demonstração:**  
> Na inicialização da demo, o volume compartilhado `/app/shared` está vazio. O arquivo `session.pkl` só é criado na **Etapa 1** (login legítimo da vítima) e só é infectado na **Etapa 2** (exploit do atacante).


---

## 🧭 Visão Geral das Duas Frentes

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             PROJETO DEMONSTRATIVO DE SEGURANÇA                              │
├──────────────────────────────────────────────┬──────────────────────────────────────────────┤
│    🔴 FRENTE 1: LABORATÓRIO DE ATAQUE        │     🟢 FRENTE 2: LABORATÓRIO DE DEFESA       │
│    Pickle Deserialization (OWASP A08)        │     Resiliência e Idempotência em APIs       │
│    3 Máquinas / Containers Docker            │     2 Containers Docker (API + BD)           │
│    - servidor_bd (Postgres 16)               │     - demo_spring_api (Spring Boot 3)        │
│    - maquina_vitima (login.py)               │     - demo_postgres (Postgres 16)            │
│    - maquina_atacante (exploit.py)           │                                              │
│    Técnicas: __reduce__, RCE, Exfiltração    │     Técnicas: @Transactional, Fail-Fast      │
│    Script: cd attack-demo; .\executar-ataque.ps1│  Script: .\executar-demo.ps1              │
└──────────────────────────────────────────────┴──────────────────────────────────────────────┘
```

---

## 🧰 Stack Tecnológica

- **Backend & Defesa:** Java 21 LTS, Spring Boot 3.3.4, Spring Data JPA, Hibernate, Bean Validation.
- **Ataque & Automação:** Python 3.11, Psycopg2, Pickle Protocol.
- **Banco de Dados:** PostgreSQL 16 Alpine.
- **Infraestrutura:** Docker & Docker Compose (Multi-stage build e redes bridge isoladas).
- **Scripts de Apresentação:** PowerShell interativo com controle de permissão por etapa, ASCII art e menus de auditoria em tempo real.

---

## 📁 Estrutura do Repositório

```
.
├── iniciar-apresentacao.ps1            # 🚀 Menu Mestre interativo para conduzir a apresentação
├── executar-demo.ps1                   # 🛡️ Script interativo da Frente de Defesa (Spring Boot)
├── ROTEIRO_APRESENTACAO.md             # 🎤 Roteiro completo com falas, técnicas e validações
├── docker-compose.yml                  # Orquestrador da API de Resiliência e PostgreSQL
├── Dockerfile                          # Build multi-stage da API Spring Boot
├── pom.xml                             # Dependências Maven da aplicação Java
├── demo-resiliencia.postman_collection.json # Coleção Postman para testes manuais da API
│
├── attack-demo/                        # 🔴 FRENTE DE ATAQUE (OWASP A08)
│   ├── docker-compose.yml              # Cluster das 3 máquinas (servidor_bd, vitima, atacante)
│   ├── Dockerfile                      # Imagem Python para as máquinas da vítima e do atacante
│   ├── executar-ataque.ps1             # Script interativo visual do ataque passo a passo
│   ├── login.py                        # Aplicação cliente da vítima (usa pickle vulnerável)
│   ├── exploit.py                      # Exploit do atacante com classe __reduce__
│   ├── config.py                       # Configurações de conexão e paths
│   ├── README.md                       # Documentação técnica específica do ataque
│   ├── init-db/
│   │   └── init.sql                    # Seed com dados sensíveis (usuários, salários, secrets)
│   └── comandos/
│       └── __init__.py                 # Payloads de exfiltração de dados e DROP TABLE
│
└── src/                                # 🟢 CÓDIGO-FONTE DA API RESILIENTE
    └── main/java/com/demo/resiliencia/
        ├── controller/
        │   ├── VulneravelController.java   # Rota do Caos (/api/vulneravel)
        │   ├── ProtegidoController.java     # Rota Resiliente (/api/protegido)
        │   └── DemoAuditoriaController.java # Endpoints de auditoria (/api/ordens)
        └── service/
            ├── VulneravelService.java       # Sem transação, sem idempotência
            └── ProtegidoService.java        # Com @Transactional e verificação de chave
```

---

## ⚡ Como Iniciar a Apresentação

Para abrir o painel central interativo:
```powershell
.\iniciar-apresentacao.ps1
```

O menu permite:
- Escolher a demonstração de ataque (3 máquinas)
- Escolher a demonstração de defesa (API)
- Acessar o guia de auditoria rápida
- Executar limpeza geral de containers e volumes

---

## 🎮 Controle Passo a Passo com Permissão no Terminal

Ambos os scripts (`executar-ataque.ps1` e `executar-demo.ps1`) foram construídos especificamente para apresentações:
- Antes de cada etapa, é exibido um **Card Visual** detalhando:
  - 📌 **O QUE É FEITO**
  - ⚙️ **COMO É FEITO**
  - ⚔️ **QUAIS TÉCNICAS SÃO UTILIZADAS**
  - 💥 **QUAIS CONSEQUÊNCIAS REAIS GERA**
  - 🔍 **COMO VALIDAR EM TEMPO REAL**
- O terminal aguarda a **autorização explícita do apresentador**:
  - `[ENTER]` -> Autoriza e executa a etapa
  - `[V]`     -> Abre o menu de validação ao vivo / auditoria
  - `[S]`     -> Pula a etapa (Skip)
  - `[Q]`     -> Encerra o script

---

## 🔍 Como Entrar nas Máquinas Simuladas em Tempo Real

Durante a apresentação, você pode abrir outros terminais e se conectar diretamente em qualquer máquina simulada para provar o funcionamento:

### 1. Máquina da Vítima
```bash
docker exec -it maquina_vitima bash
ls -la /app/shared
python -c "import pickle; print(pickle.load(open('/app/shared/session.pkl', 'rb')))"
```

### 2. Máquina do Atacante
```bash
docker exec -it maquina_atacante bash
cat /app/exploit.py
cat /app/comandos/__init__.py
```

### 3. Servidor de Banco de Dados Corporativo
```bash
docker exec -it servidor_bd psql -U postgres -d demo_db
# No psql:
\dt
SELECT * FROM usuarios;
SELECT * FROM clientes;
SELECT * FROM config_sistema;
```

### 4. API de Resiliência
```bash
docker logs -f demo_spring_api
docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT * FROM ordens_servico;"
```

---

## 📖 Roteiro Completo para Apresentações

Para o roteiro detalhado com sugestões de fala, cronometragem e aprofundamento teórico, consulte o arquivo:  
👉 **[`ROTEIRO_APRESENTACAO.md`](file:///c:/Users/roger/Documents/Projeto-demonstrativo-seguran-a/ROTEIRO_APRESENTACAO.md)**
