# 🎤 Roteiro de Apresentação Técnica: Demonstração de Ataque e Defesa

> **Público-alvo:** Bancas avaliadoras, lideranças técnicas e equipes de engenharia de software e segurança da informação.  
> **Tema Central:** Da Insegurança na Desserialização (OWASP A08:2021) aos Padrões de Resiliência Corporativa (Atomicidade, Idempotência e Fail-Fast).

---

## 🎯 1. Qual o Objetivo deste Laboratório?

O objetivo principal deste laboratório é **demonstrar na prática, de forma visual e comprovável em tempo real, a importância crítica da integridade dos dados e da resiliência de software em sistemas corporativos**.

Ele responde a duas perguntas essenciais de arquitetura e segurança:
1. **O que acontece quando confiamos cegamente em dados serializados ou manipuláveis?**  
   *(Frente Ofensiva / Ataque)*: Prova como uma falha aparentemente inofensiva de implementação (salvar sessões de usuário com `pickle` nativo sem validação criptográfica) permite que um invasor alcance **Execução Remota de Código (RCE)**, sequestre o contexto e credenciais da vítima e **exfiltre dados confidenciais (LGPD)** ou **destrua todo o banco corporativo (`DROP TABLE`)**.
2. **O que acontece quando uma API não é projetada para falhas e retentativas de rede?**  
   *(Frente Defensiva / Resiliência)*: Prova como integrações modernas (webhooks, gateways de pagamento, microsserviços) geram rombos contábeis e corrupção de estado quando não possuem controle transacional (gerando *ordens órfãs*) ou idempotência (gerando *cobrança duplicada*), e como padrões como **Atomicidade ACID (@Transactional)**, **Idempotência por Chave Natural** e **Fail-Fast (@Valid)** blindam o sistema.

---

## 📚 2. Quais Assuntos ele Aborda?

O laboratório conecta conceitos fundamentais de **Segurança da Informação (AppSec)** e **Engenharia de Software**:

### 🔴 Frente de Segurança Ofensiva (Ataque)
* **OWASP Top 10 — A08:2021 (Software and Data Integrity Failures):**
  * Riscos críticos de integridade decorrentes da desserialização de dados não confiáveis (*Insecure Deserialization*).
* **Execução Arbitrária de Código (RCE — Remote Code Execution):**
  * Exploração em baixo nível do protocolo `pickle` em Python através do método especial dunder `__reduce__()`.
* **Integridade Criptográfica (HMAC e Assinatura Digital):**
  * O contraste entre persistir dados binários sem proteção versus persistir dados assinados com chaves secretas (HMAC-SHA256).
* **Pivotamento Interno e Roubo de Contexto (Privilege Hijacking):**
  * Como um atacante que não tem a senha do banco força a aplicação legítima da vítima a exfiltrar tabelas e segredos de sistema (`JWT_SECRET`, credenciais de gateway de pagamento).
* **Princípio do Menor Privilégio (PoLP — Principle of Least Privilege):**
  * Por que a aplicação jamais deve ter permissões administrativas irrestritas no banco (ex.: revogar privilégio de `DROP TABLE`).
* **Impacto Regulatório e de Negócio (LGPD / GDPR):**
  * Exfiltração prática de CPFs de clientes, transações financeiras (PIX/TED) e folhas salariais.

### 🟢 Frente de Engenharia Defensiva (Resiliência de APIs)
* **Princípio ACID & Atomicidade Transacional:**
  * Uso de anotações `@Transactional` no Spring Boot para garantir o conceito do "Tudo ou Nada", evitando *Partial Commits* e dados corrompidos.
* **Padrão de Idempotência em Integrações:**
  * Uso de chaves de integração (*Idempotency Keys*) para lidar com retentativas de rede e webhooks repetidos sem duplicar pedidos ou cobranças.
* **Padrão Fail-Fast:**
  * Validação antecipada na borda do Controller (*Bean Validation*) para rejeitar requisições corrompidas antes de consumir conexões do banco de dados.
* **Infraestrutura em Containers e Isolamento (DevOps):**
  * Uso de Docker Compose, redes isoladas (*Bridge Networks*), *Healthchecks* e montagem de volumes para criar um laboratório reprodutível e seguro.

> 💡 **Nota sobre o ciclo de vida dos arquivos na demonstração:**  
> Na **Etapa 0**, o volume compartilhado `/app/shared` é inicializado vazio. O arquivo `session.pkl` só passa a existir a partir da **Etapa 1** (quando a vítima faz login pela primeira vez). Na **Etapa 2**, ele é substituído pelo payload do atacante.

---

## 🧭 Visão Geral do Laboratório Integrado

Este projeto reúne duas frentes complementares de segurança e engenharia de software para fins estritamente educativos:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             PROJETO DEMONSTRATIVO DE SEGURANÇA                              │
├──────────────────────────────────────────────┬──────────────────────────────────────────────┤
│    FRENTE 1: SEGURANÇA OFENSIVA (ATAQUE)     │     FRENTE 2: ENGENHARIA DEFENSIVA (DEFESA)  │
│    Pickle Deserialization (OWASP A08:2021)   │     Resiliência e Integridade em APIs        │
│    3 Containers: BD, Vítima e Atacante       │     2 Containers: Spring Boot 3 e PostgreSQL │
│    Foco: RCE, Exfiltração e Destruição       │     Foco: Fail-Fast, Rollback e Idempotência │
└──────────────────────────────────────────────┴──────────────────────────────────────────────┘
```


---

## 🖥️ Topologia das Máquinas Simuladas em Docker

O laboratório de ataque emula uma rede corporativa real com **3 máquinas virtuais isoladas**:

```
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                  REDE DOCKER ISOLADA (`rede-ataque`)                       │
 │                                                                            │
 │   [ 🖥️ MÁQUINA DA VÍTIMA ]                     [ 🦹 MÁQUINA DO ATACANTE ]  │
 │     Container: `maquina_vitima`                  Container: `maquina_atacante`│
 │     IP/Host: maquina-vitima                      IP/Host: maquina-atacante │
 │     Script: login.py                             Script: exploit.py        │
 │              \                                       /                     │
 │               \       📂 VOLUME COMPARTILHADO       /                      │
 │                \---> [ /app/shared/session.pkl ] <--/                      │
 │                                  │                                         │
 │                                  ▼ Conexão SQL Autenticada                 │
 │                     [ 🗄️ SERVIDOR DE BANCO DE DADOS ]                      │
 │                       Container: `servidor_bd`                             │
 │                       Serviço: PostgreSQL 16 Alpine (Porta 5433 host)       │
 │                       Dados: usuarios, salários, clientes, secrets...       │
 └────────────────────────────────────────────────────────────────────────────┘
```

---

# 🔴 PARTE 1: DEMONSTRAÇÃO DO ATAQUE (OWASP A08)

O script interativo guia toda a execução com pedidos de permissão a cada etapa:
```powershell
cd attack-demo
.\executar-ataque.ps1
```

---

### ETAPA 0: Subida e Isolamento da Infraestrutura

#### 📌 O que é feito:
Construção e inicialização em segundo plano dos 3 containers em uma rede bridge (`rede-ataque`), montando o volume de armazenamento compartilhado (`/app/shared/`) e aplicando o script de carga inicial SQL (`init.sql`) no PostgreSQL com dados fictícios confidenciais (CPFs, transações bancárias, salários e chaves de criptografia).

#### ⚙️ Como é feito:
- Execução do comando `docker compose up --build -d` a partir de `attack-demo/docker-compose.yml`.
- O healthcheck monitora o PostgreSQL com `pg_isready -U postgres -d demo_db`.
- O script PowerShell aguarda a prontidão do banco e limpa qualquer sessão residual anterior.

#### ⚔️ Quais técnicas são utilizadas:
- **Containerização e Segmentação de Rede:** Criação de sandbox controlada em Docker Bridge.
- **Armazenamento Compartilhado:** Simulação de um filesystem de rede vulnerável (ex: NFS, SMB, ou volume partilhado em nuvem/Kubernetes).
- **Database Seeding Automatizado:** Injeção de registros simulando dados reais em `docker-entrypoint-initdb.d`.

#### 💥 Quais consequências traz:
Cria um ambiente fidedigno de teste sem nenhum risco para a máquina hospedeira do apresentador, garantindo repetibilidade e isolamento estrito.

#### 🔍 Como validar e entrar nas máquinas em tempo real:
```powershell
# 1. Verificar se os 3 containers estão saudáveis:
docker compose ps

# 2. Entrar no Servidor de Banco de Dados e inspecionar os dados confidenciais:
docker exec -it servidor_bd psql -U postgres -d demo_db
# No prompt do psql:
\dt
SELECT id, nome, cargo, salario FROM usuarios;
SELECT chave, valor FROM config_sistema;
\q
```

---

### ETAPA 1: Login Legítimo e Criação de Sessão Serializada (Vítima)

#### 📌 O que é feito:
A vítima executa a aplicação cliente (`login.py`) dentro de seu container. Ela autentica no banco, exibe suas informações funcionais e salva o estado de sua sessão em disco para não precisar se reautenticar na próxima execução.

#### ⚙️ Como é feito:
- O script `login.py` conecta no PostgreSQL via biblioteca `psycopg2`.
- Realiza consultas para ler versão, usuário e tabelas.
- Serializa o dicionário Python de sessão usando `pickle.dump(session_data, f)` diretamente no arquivo `/app/shared/session.pkl`.

#### ⚔️ Quais técnicas são utilizadas:
- **Serialização de Objetos em Python:** Uso do protocolo nativo `pickle` para salvar instâncias de objetos em formato binário.
- **Persistência de Sessão sem Assinatura:** Gravação em disco sem assinatura criptográfica (sem HMAC) e sem checagem de integridade SHA-256.

#### 💥 Quais consequências traz:
- Cria uma **falha crítica de integridade de dados (OWASP A08)**. O arquivo `.pkl` gerado é estritamente confiado pela aplicação consumidora, permitindo que qualquer um com acesso de escrita a esse arquivo determine o fluxo de execução futuro da aplicação.

#### 🔍 Como validar e entrar na máquina em tempo real:
```powershell
# 1. Entrar na máquina da vítima:
docker exec -it maquina_vitima bash

# 2. Inspecionar o arquivo recém-gerado:
ls -la /app/shared/session.pkl

# 3. Ler o conteúdo legítimo da sessão via Python:
python -c "import pickle; print(pickle.load(open('/app/shared/session.pkl', 'rb')))"
# Saída esperada: dicionário legítimo com {'usuario': 'postgres', 'database': 'demo_db', ...}
exit
```

---

### 🌉 A PONTE ENTRE A ETAPA 1 E A ETAPA 2: COMO O ATACANTE LOCALIZA E INVADE NO MUNDO REAL

> **Pergunta frequente de bancas e audiências:**  
> *"Como o atacante encontrou esse arquivo? Como ele invadiu a máquina para conseguir alterá-lo? Por que há um volume compartilhado?"*

No laboratório, o **volume compartilhado `/app/shared`** é uma **abstração didática** para manter a apresentação focada no cerne da vulnerabilidade (OWASP A08 - Integridade e Desserialização) sem exigir 40 minutos prévios de força bruta em senhas ou exploração web.

No **mundo real**, o invasor utiliza uma das 4 cadeias de ataque (*Cyber Kill Chain*) abaixo para alcançar e localizar o arquivo `.pkl`:

#### 1. Vetor A: Storage de Rede ou Nuvem Mal Configurado (NFS, SMB, AWS S3 / EFS)
* Em arquiteturas distribuídas e microsserviços, é comum empresas compartilharem diretórios de cache e sessão entre instâncias via NFS, CIFS/SMB ou AWS EFS.
* Se esse compartilhamento possuir permissões excessivas na rede interna (ex: exportação NFS `no_root_squash` ou compartilhamento SMB sem autenticação), qualquer nó comprometido na rede interna consegue varrer e montar a pasta remotamente:
  ```bash
  # Varredura de storages compartilhados na rede interna:
  showmount -e 192.168.1.100
  smbclient -L //192.168.1.100 -N
  ```

#### 2. Vetor B: Acesso Inicial de Baixo Privilégio e Escalação de Privilégios (Privilege Escalation)
* O atacante invade um serviço web secundário na mesma máquina física ou cluster (ex: vulnerabilidade LFI — *Local File Inclusion*, plugin desatualizado do WordPress ou upload irrestrito de arquivos).
* Ele obtém uma shell de usuário restrito (ex.: `www-data` ou estagiário).
* A partir daí, o invasor executa **ferramentas de reconhecimento interno (Internal Reconnaissance)**:
  ```bash
  # Localizar arquivos serializados com permissão fraca:
  find / -name "*.pkl" -o -name "*.pickle" 2>/dev/null
  # Localizar onde o código usa desserializadores perigosos:
  grep -rnw "pickle.load" /app/ /var/www/ /opt/ 2>/dev/null
  # Checar permissões de escrita:
  ls -la /app/shared/session.pkl  # -> Permissão 777 ou mesmo grupo!
  ```
* **O golpe de mestre:** O atacante de baixo privilégio não tem acesso ao banco de dados. Porém, ao sobrescrever o `session.pkl`, ele sabe que o usuário legítimo (administrador com credenciais) executará o programa rotineiramente. Quando a vítima executa, o payload roda com os **privilégios e credenciais elevadas da vítima**!

#### 3. Vetor C: Ambientes Multitenant e Containers Compartilhados (Kubernetes / CI-CD)
* Em clusters Kubernetes ou runners compartilhados de CI/CD (GitLab, GitHub Actions, Jenkins), múltiplos pods frequentemente montam o mesmo *PersistentVolumeClaim* (PVC com modo `ReadWriteMany`).
* O comprometimento de um pod secundário dá acesso de leitura e escrita direto aos volumes dos pods principais.

#### 4. Vetor D: Interceptação em Trânsito (Man-in-the-Middle)
* Quando arquivos ou cookies serializados trafegam por redes internas, mensagerias (RabbitMQ, Redis) ou HTTP sem criptografia mTLS, o atacante intercepta o tráfego e substitui o payload binário em trânsito antes de chegar ao destino.

---

### ETAPA 2: Infecção do Arquivo .pkl via Exploit (Atacante)

#### 📌 O que é feito:
O atacante, operando de sua própria máquina (`maquina_atacante`), detecta o arquivo `session.pkl` no volume compartilhado, lê os metadados e o substitui por um artefato malicioso com payload de execução remota de código (RCE).

#### ⚙️ Como é feito:
- O atacante executa `exploit.py [1 ou 2]`.
- O script define a classe `MaliciousPayload` implementando o método mágico `__reduce__()`.
- O método `__reduce__` instrui o deserializador a chamar uma função Python arbitrária (ex: `comandos.exfiltrar_tabelas` ou `comandos.dropar_tabela`) passando as credenciais do banco corporativo.
- O atacante sobrescreve `/app/shared/session.pkl` com `pickle.dump(payload, f)`.

#### ⚔️ Quais técnicas são utilizadas:
- **Abuso de Dunder Method `__reduce__`:** O protocolo `pickle` permite que uma classe declare como deve ser desserializada. Se ela retornar uma tupla contendo um *callable* e seus *argumentos*, o Python executará esse *callable* automaticamente no momento em que `pickle.load()` for invocado!
- **Man-in-the-Middle em Storage:** Modificação de arquivos em repouso em diretórios compartilhados.
- **RCE (Remote Code Execution) Armado:** Preparação da carga útil para exfiltração de dados ou sabotagem.

#### 💥 Quais consequências traz:
- O arquivo binário passa a abrigar uma **carga explosiva lógica**. O atacante não precisou hackear a senha do banco: ele forjou uma instrução que será executada com os privilégios e permissões da vítima quando ela abrir o programa.

#### 🔍 Como validar e entrar na máquina em tempo real:
```powershell
# 1. Entrar na máquina do atacante:
docker exec -it maquina_atacante bash

# 2. Ver o código do payload de ataque:
cat /app/exploit.py
cat /app/comandos/__init__.py

# 3. Ver que o session.pkl mudou de tamanho e conteúdo:
ls -la /app/shared/session.pkl
python -c "print(open('/app/shared/session.pkl', 'rb').read())"
# Saída esperada: bytes contendo 'comandos' e 'exfiltrar_tabelas' ou 'dropar_tabela'
exit
```

---

### ETAPA 3: Login Infectado — Execução Automática do Ataque (Vítima)

#### 📌 O que é feito:
A vítima, sem desconfiar de nenhuma irregularidade, abre seu terminal e roda o comando rotineiro `login.py` para restaurar seu acesso anterior. No instante da leitura do arquivo, o ataque é desencadeado dentro de seu próprio processo.

#### ⚙️ Como é feito:
- O código da vítima executa: `pickle.load(open('/app/shared/session.pkl', 'rb'))`.
- A máquina virtual Python lê a instrução `__reduce__` injetada pelo atacante e executa imediatamente a função `comandos.exfiltrar_tabelas(...)`.
- O código do atacante abre uma conexão com o `servidor_bd` utilizando as credenciais da vítima e rouba todas as tabelas em tempo real, ou executa `DROP TABLE CASCADE`.

#### ⚔️ Quais técnicas são utilizadas:
- **Insecure Deserialization Exploitation:** Execução arbitrária de funções internas do interpretador sem validação prévia.
- **Privilege / Identity Hijacking:** O atacante utiliza a identidade e o socket de rede da vítima para dialogar com o banco interno.
- **Data Exfiltration / System Sabotage:** Varredura dinâmica de `information_schema.tables`, contagem de registros e extração de dados confidenciais diretamente no console.

#### 💥 Quais consequências traz:
- **Vazamento Catastrófico de Dados (LGPD/GDPR):** Exposição imediata de salários, nomes, CPFs, transações PIX/TED e chaves secretas do sistema (`JWT_SECRET`, `API_KEY_PAGAMENTO`, `SMTP_PASSWORD`).
- **Destruição Completa do Banco (se escolhido Payload 2):** Eliminação de todas as tabelas corporativas sem chance de recuperação simples.
- **Comprometimento de Sistemas Externos:** As chaves de API roubadas permitem que o atacante acesse contas de pagamento e emissores de e-mail externos.

#### 🔍 Como validar e entrar nas máquinas em tempo real:
```powershell
# 1. Observar a saída na tela da vítima: todos os dados confidenciais vazados linha a linha.

# 2. Se o Payload 2 (DROP TABLE) foi escolhido, comprove no servidor de BD:
docker exec -it servidor_bd psql -U postgres -d demo_db -c "\dt"
# Saída: "Did not find any relations." (Todas as tabelas foram apagadas!)

# 3. Se o Payload 1 foi escolhido, veja que os secrets do config_sistema foram expostos:
docker exec -it servidor_bd psql -U postgres -d demo_db -c "SELECT * FROM config_sistema;"
```

---

### ETAPA 4: Auditoria Forense e Como Mitigar na Prática

#### 📌 O que é feito:
Inspeção forense do estado dos containers e apresentação dos pilares de arquitetura de software para blindar o sistema contra essa categoria de vulnerabilidade.

#### 🛡️ Quais técnicas defensivas devem ser aplicadas:
1. **Banimento do `pickle` para dados externos:**
   - Usar formatos de dados neutros que transmitem apenas **estado** e nunca **comportamento executável** (ex: `JSON`, `MessagePack`, `Protocol Buffers`).
2. **Assinatura Criptográfica HMAC (Integrity Check):**
   - Caso seja mandatório serializar objetos binários, calcular o `hmac.new(secret_key, data, hashlib.sha256).digest()` e validar antes de qualquer chamada a desserializadores.
3. **`RestrictedUnpickler` (Whitelist estrita):**
   - Sobrescrever o método `find_class()` do unpickler para rejeitar qualquer módulo ou classe que não pertença a uma lista autorizada de tipos primitivos.
4. **Princípio do Menor Privilégio no Banco de Dados (PoLP):**
   - O usuário que a aplicação utiliza para operar o dia a dia não deve possuir permissões de `DROP TABLE`, nem acesso de leitura à tabela de segredos e chaves mestras.

---

# 🟢 PARTE 2: DEMONSTRAÇÃO DA DEFESA (RESILIÊNCIA EM APIS)

O laboratório de resiliência foca na integridade transacional de microsserviços e APIs corporativas sob condições adversas:
```powershell
.\executar-demo.ps1
```

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ARQUITETURA DA API RESILIENTE                            │
│                                                                             │
│   [ SCRIPT / POSTMAN ] ───(HTTP 8080)───> [ CONTAINER: demo_spring_api ]   │
│                                             - Web Servlet Layer             │
│                                             - Controller (@Valid / FailFast)│
│                                             - Service (@Transactional ACID) │
│                                             - Idempotency Filter (Key)      │
│                                                          │                  │
│                                                          ▼ JPA / Hibernate  │
│                                           [ CONTAINER: demo_postgres:5433 ] │
│                                             - ordens_servico, itens_ordem   │
│                                             - auditoria_transacional (PROVA)│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### CENÁRIO 1: Rota do Caos — Injeção de Falha & Partial Commit (Ordem Órfã)

- **📌 O que é feito (Regra de Negócio):** Envio de uma ordem de serviço com 2 itens, onde o 2º item possui propositalmente um valor monetário negativo (`-150.00`).
- **⚙️ Como é feito (Chamada HTTP):** Disparo de `POST /api/vulneravel/ordens`. A service salva a entidade pai primeiro, itera sobre os itens e lança uma exceção no meio do processamento.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** Falta intencional da anotação `@Transactional`. O driver JDBC opera sem proxy transacional do Spring. A ordem mestre já foi persistida e comitada no banco antes do processamento do 2º item falhar.
- **💥 Consequências Reais:** A API responde com erro HTTP 500, porém a ordem mestre **já ficou gravada no banco sem itens associados** (**Ordem Órfã**). No mundo real, isso gera cobranças de notas fiscais sem mercadoria associada, faturamento fantasma e quebra contábil severa perante auditorias externas.
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  # 1. Consultar endpoint de auditoria de ordens órfãs:
  curl http://localhost:8080/api/ordens/orfas
  
  # 2. Consultar o PostgreSQL diretamente provando a ausência de itens:
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT o.id, o.cliente, o.integration_id, o.status, count(i.id) as itens FROM ordens_servico o LEFT JOIN itens_ordem i ON i.ordem_id = o.id WHERE o.integration_id = 'CAOS-PARTIAL-001' GROUP BY o.id, o.cliente, o.integration_id, o.status;"
  
  # 3. Consultar a tabela forense de auditoria:
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT id, ip_origem, rota, tipo_cenario, status_execucao, codigo_http FROM auditoria_transacional WHERE integration_id = 'CAOS-PARTIAL-001';"
  ```

---

### CENÁRIO 2: Rota do Caos — Retry Attack sem Idempotência (Duplicidade)

- **📌 O que é feito (Regra de Negócio):** Simulação de um webhook ou gateway de pagamento reenviando o mesmo pedido 3 vezes consecutivas devido a oscilações de rede.
- **⚙️ Como é feito (Chamada HTTP):** 3 disparos consecutivos de `POST /api/vulneravel/ordens` repetindo a mesma chave `CAOS-DUP-999`.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** Ausência de controle de chave natural de integração (Idempotency Key). Cada requisição executa um novo `INSERT` cego na tabela `ordens_servico`.
- **💥 Consequências Reais:** São criadas 3 ordens idênticas para a mesma transação, cobrando o cliente 3 vezes (ex: R$ 1.350,00 em vez de R$ 450,00), duplicando reservas de estoque e emitindo notas fiscais em excesso.
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  # 1. Consultar ocorrências por chave:
  curl http://localhost:8080/api/ordens/por-integration-id/CAOS-DUP-999
  
  # 2. Consultar o PostgreSQL diretamente comprovando 3 IDs diferentes:
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT id, cliente, integration_id, status, criado_em FROM ordens_servico WHERE integration_id = 'CAOS-DUP-999';"
  ```

---

### CENÁRIO 3: Rota Resiliente — Proteção Fail-Fast na Borda da API (Bean Validation)

- **📌 O que é feito (Regra de Negócio):** Envio do mesmo payload defeituoso (com valor monetário negativo de -500.00) diretamente para a rota protegida.
- **⚙️ Como é feito (Chamada HTTP):** `POST /api/protegido/ordens`. O Spring intercepta a requisição na camada Web antes de abrir conexão com o banco ou chamar regras de negócio.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** Padrão **Fail-Fast** utilizando anotações declarativas do Bean Validation (`@Valid`, `@NotNull`, `@DecimalMin("0.00")`). O `DispatcherServlet` rejeita a requisição via `MethodArgumentNotValidException`. Nenhuma conexão com o pool do HikariCP/PostgreSQL é desperdiçada.
- **💥 Consequências Reais:** Economia massiva de recursos computacionais, prevenção contra sobrecarga de banco de dados e resposta imediata com `HTTP 400 Bad Request` detalhando o campo inconsistente.
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  # Retorno HTTP 400 imediato; conferir que ZERO registros foram salvos no PostgreSQL:
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT count(*) FROM ordens_servico WHERE integration_id = 'PROT-FAILFAST-001';"
  ```

---

### CENÁRIO 4: Rota Resiliente — Atomicidade Transacional & Rollback Total (@Transactional)

- **📌 O que é feito (Regra de Negócio):** Simulação de uma pane severa no meio da transação de persistência de itens (`?simularFalhaTransacao=true`).
- **⚙️ Como é feito (Chamada HTTP):** O método na `ProtegidoService` é anotado com `@Transactional(rollbackFor = Exception.class)`. Quando a exceção de falha é disparada, o framework comanda o `ROLLBACK` completo no banco.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** Princípio ACID (Atomicidade) gerenciado pelo Spring AOP e `PlatformTransactionManager`. Ao ocorrer erro não tratado em método transacional, a transação JDBC é abortada e todas as instruções SQL executadas desde o `BEGIN` são desfeitas.
- **💥 Consequências Reais:** **Tudo ou Nada**. Se qualquer item falhar, a ordem mestre também é revertida. Zero registros órfãos e integridade contábil inabalável.
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  # 1. Comprovar que NENHUMA ordem foi gravada no PostgreSQL (Rollback Total):
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT count(*) as total_gravado FROM ordens_servico WHERE integration_id = 'PROT-ROLLBACK-002';"
  # Retorna: 0 registros encontrados!
  
  # 2. Comprovar que o evento foi registrado na auditoria independente (REQUIRES_NEW):
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT id, ip_origem, status_execucao, codigo_http, detalhes_tecnicos FROM auditoria_transacional WHERE integration_id = 'PROT-ROLLBACK-002';"
  ```

---

### CENÁRIO 5: Rota Resiliente — Idempotência Ativa contra Retry Attacks

- **📌 O que é feito (Regra de Negócio):** Disparo repetido de 3 requisições consecutivas com a mesma chave `PROT-IDEMP-777`.
- **⚙️ Como é feito (Chamada HTTP):** A service consulta `ordemServicoRepository.findByIntegrationId(...)`. Na 1ª requisição a ordem é criada (`HTTP 201 Created`). Na 2ª e na 3ª, o sistema reconhece a chave existente e devolve `HTTP 200 OK` com os dados da ordem já existente, sem duplicar dados.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** **Padrão de Idempotência por Chave Natural** no Application Layer. A operação garante a propriedade matemática $f(f(x)) = f(x)$, tornando retransmissões inofensivas.
- **💥 Consequências Reais:** Resiliência total contra oscilações de rede, reenvios de filas (RabbitMQ, Kafka, AWS SQS) e retentativas duplicadas de gateways de pagamento.
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT id, cliente, integration_id, status FROM ordens_servico WHERE integration_id = 'PROT-IDEMP-777';"
  # Retorna: EXATAMENTE 1 registro no banco!
  ```

---

### CENÁRIO 6: Teste de Stress & Concorrência Simultânea (Race Condition)

- **📌 O que é feito (Regra de Negócio):** Envio de 5 requisições disparadas simultaneamente no mesmo milissegundo através de threads paralelas contra a rota vulnerável e depois contra a rota protegida.
- **⚙️ Como é feito (Chamada HTTP):** Disparo assíncrono multithread em paralelo via PowerShell Jobs com as chaves `CAOS-RACE-888` e `PROT-RACE-888`.
- **🔬 Mecanismo Interno / Deep Dive Técnico:** Demonstração do fenômeno de *Race Condition* sob alto tráfego. Enquanto o endpoint do Caos aceita múltiplos `INSERTs` concorrentes sem validação, a rota resiliente garante deduplicação de chaves.
- **💥 Consequências Reais:** Prova cabal de que sistemas sem blindagem de concorrência quebram sob picos de acesso (ex: Black Friday).
- **🔍 Como validar e comprovar em tempo real:**
  ```powershell
  # Comparar no PostgreSQL o número de registros criados para cada rota:
  docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT integration_id, count(*) FROM ordens_servico GROUP BY integration_id HAVING integration_id IN ('CAOS-RACE-888', 'PROT-RACE-888');"
  ```

---

### 📊 Placar de Auditoria & Indicadores de Resiliência

A qualquer momento da apresentação, consulte o placar estatístico consolidado:
```powershell
curl http://localhost:8080/api/ordens/placar
```
Ele retorna a comparação exata entre a quantidade de ordens órfãs geradas, bloqueios preventivos, rollbacks atômicos e o diagnóstico final de integridade de dados do banco.

---

# 🔍 PARTE 3: GUIA PRÁTICO — COMO ENTRAR EM CADA MÁQUINA EM TEMPO REAL

Para surpreender a audiência durante a apresentação técnica, abra terminais adicionais e conecte-se diretamente dentro dos containers em execução:

### 1. Entrar na Máquina da Vítima (`maquina_vitima`)
```bash
docker exec -it maquina_vitima bash
```
*Comandos úteis dentro do container:*
```bash
ls -la /app/shared                    # Ver se o session.pkl existe
cat /app/login.py                     # Ver o código-fonte da vítima
python -c "import pickle; print(pickle.load(open('/app/shared/session.pkl', 'rb')))"
```

### 2. Entrar na Máquina do Atacante (`maquina_atacante`)
```bash
docker exec -it maquina_atacante bash
```
*Comandos úteis dentro do container:*
```bash
cat /app/exploit.py                   # Inspecionar a classe com __reduce__
cat /app/comandos/__init__.py         # Ver as rotinas de roubo e destruição de dados
python -c "print(open('/app/shared/session.pkl', 'rb').read())" # Ver bytes maliciosos
```

### 3. Entrar no Servidor de Banco de Dados (`servidor_bd`)
```bash
docker exec -it servidor_bd psql -U postgres -d demo_db
```
*Comandos úteis dentro do prompt `psql`:*
```sql
\dt                                   -- Listar todas as tabelas
SELECT * FROM usuarios;               -- Ver usuários, salários e senhas com hash
SELECT * FROM clientes;               -- Ver clientes com CPFs cadastrados
SELECT * FROM transacoes;             -- Ver transações bancárias e valores
SELECT * FROM config_sistema;         -- Ver secrets, JWT_SECRET e chaves de API
\q                                    -- Sair do psql
```

### 4. Inspecionar a API Spring Boot (`demo_spring_api` e `demo_postgres`)
```bash
# Ver os logs ao vivo do Spring Boot conforme os disparos acontecem:
docker logs -f demo_spring_api

# Entrar no banco de ordens de serviço:
docker exec -it demo_postgres psql -U postgres -d demo_db
# No psql:
SELECT * FROM ordens_servico;
SELECT * FROM itens_ordem;
SELECT id, ip_origem, rota, tipo_cenario, status_execucao, codigo_http FROM auditoria_transacional ORDER BY id DESC;
```

---

## 🎯 Resumo Comparativo para o Fechamento da Apresentação

| Dimensão de Segurança | Abordagem Insegura / Caótica | Abordagem Resiliente / Protegida |
| :--- | :--- | :--- |
| **Serialização de Dados** | `pickle` sem validação -> **RCE e vazamento total de dados** | Formatos neutros (`JSON`) ou assinatura criptográfica (`HMAC`) |
| **Controle de Acesso ao BD** | Usuário da app com privilégios de `DROP TABLE` e leitura irrestrita | Princípio do Menor Privilégio (PoLP) |
| **Integridade de Negócio** | Falhas parciais geram **Ordens Órfãs** no banco | `@Transactional` garante **Rollback Total (Atomicidade ACID)** |
| **Tolerância a Retries** | Retentativas geram **Duplicidade em Massa** e cobrança tripla | Validação de chave de integração garante **Idempotência Ativa** |
| **Tratamento de Entrada** | Payloads malformados atingem regras de negócio | **Fail-Fast** bloqueia requisições corrompidas no Controller (`HTTP 400`) |

---

## 🚀 Como Iniciar a Apresentação

Na raiz do projeto, execute o script central:
```powershell
.\iniciar-apresentacao.ps1
```
Ou execute individualmente conforme a pauta da sua apresentação:
- Para o Ataque: `cd attack-demo; .\executar-ataque.ps1`
- Para a Defesa: `.\executar-demo.ps1`
