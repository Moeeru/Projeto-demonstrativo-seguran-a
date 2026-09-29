# 🦠 Laboratório de Ataque: Pickle Deserialization (OWASP A08:2021)

Demonstração prática de **Software and Data Integrity Failures** utilizando um ataque de injeção e desserialização em Python Pickle através de um cluster de **3 máquinas isoladas em containers Docker**.

---

## 🎯 Objetivo deste Laboratório
O objetivo deste laboratório é **demonstrar empiricamente como falhas de integridade na desserialização de dados (OWASP A08) podem comprometer completamente um ambiente corporativo**.

Ele ilustra como um invasor sem credenciais de banco de dados consegue, através da simples substituição de um arquivo de sessão serializado com `pickle`:
1. Executar código arbitrário dentro do processo da vítima (**RCE**);
2. Sequestrar a identidade e o socket de rede da vítima para dialogar com o banco de dados interno;
3. **Exfiltrar dados sensíveis** (violação da LGPD/GDPR: CPFs, salários, transações bancárias e chaves de API/JWT);
4. **Destruir o schema do banco** de dados via `DROP TABLE CASCADE`.

---

## 📚 Assuntos Abordados
* **OWASP Top 10 — A08:2021:** Software and Data Integrity Failures.
* **Desserialização Insegura (Insecure Deserialization):** Mecânica do protocolo Pickle e método dunder `__reduce__()`.
* **Execução Remota de Código (RCE):** Armamento e disparo de payload.
* **Integridade Criptográfica (HMAC-SHA256):** Defesa por assinatura digital de payloads.
* **Privilege Hijacking / Pivotamento Interno:** Uso indevido das permissões da vítima para acessar a rede interna.
* **Princípio do Menor Privilégio (PoLP):** Configuração de privilégios de banco para limitar o raio de impacto de um ataque.
* **Containerização e Segmentação de Redes:** Orquestração de 3 máquinas isoladas em Docker.

> 💡 **Nota sobre o arquivo session.pkl:**  
> Na inicialização dos containers, o diretório `/app/shared` está vazio. O arquivo `session.pkl` só é criado na **Etapa 1** (login legítimo da vítima) e só é infectado na **Etapa 2** (exploit do atacante).


---

## 🖥️ Topologia das Máquinas Simuladas

```
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                  REDE DOCKER ISOLADA (`rede-ataque`)                       │
 │                                                                            │
 │   [ 🖥️ MÁQUINA DA VÍTIMA ]                     [ 🦹 MÁQUINA DO ATACANTE ]  │
 │     Container: `maquina_vitima`                  Container: `maquina_atacante`│
 │     Executa: `login.py`                          Executa: `exploit.py`       │
 │              \                                       /                     │
 │               \       📂 VOLUME COMPARTILHADO       /                      │
 │                \---> [ /app/shared/session.pkl ] <--/                      │
 │                                  │                                         │
 │                                  ▼ Conexão SQL Autenticada                 │
 │                     [ 🗄️ SERVIDOR DE BANCO DE DADOS ]                      │
 │                       Container: `servidor_bd`                             │
 │                       PostgreSQL 16 (Porta host 5433 / rede 5432)          │
 │                       Tabelas: usuarios, clientes, transacoes, config      │
 └────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Detalhamento das Etapas do Ataque

### ETAPA 0: Subida da Infraestrutura e Isolamento
- **📌 O que é feito:** Compilação dos Dockerfiles e inicialização em background dos 3 containers interligados em uma rede bridge (`rede-ataque`), montando o volume `/app/shared` e aplicando o seed SQL com dados confidenciais.
- **⚙️ Como é feito:** `docker compose up --build -d` a partir de `docker-compose.yml`. O script aguarda `pg_isready` e limpa sessões antigas.
- **⚔️ Quais técnicas:** Isolamento de rede em Docker Bridge, persistência em storage compartilhado e database seeding automático.
- **💥 Quais consequências:** Criação de sandbox segura para execução de código ofensivo sem riscos ao host.
- **🔍 Como validar em tempo real:**
  ```bash
  docker compose ps
  docker exec -it servidor_bd psql -U postgres -d demo_db -c "\dt"
  ```

---

### ETAPA 1: Login Legítimo (Máquina da Vítima)
- **📌 O que é feito:** A vítima conecta ao banco corporativo com suas credenciais, exibe seus dados funcionais e salva o estado de sua sessão em disco.
- **⚙️ Como é feito:** Execução de `python login.py` no container `maquina_vitima`. O script usa `pickle.dump(session_data, f)` salvando em `/app/shared/session.pkl`.
- **⚔️ Quais técnicas:** Serialização binária nativa com o protocolo Python Pickle. Persistência de arquivo sem assinatura digital (sem HMAC) e sem checagem de integridade.
- **💥 Quais consequências:** Criação de vulnerabilidade crítica de integridade (OWASP A08). Qualquer processo que sobrescrever o arquivo controlará a execução futura do programa da vítima.
- **🔍 Como validar em tempo real:**
  ```bash
  docker exec -it maquina_vitima ls -lh /app/shared/session.pkl
  docker exec -it maquina_vitima python -c "import pickle; print(pickle.load(open('/app/shared/session.pkl', 'rb')))"
  ```

---

### 🌉 A PONTE ENTRE A ETAPA 1 E A ETAPA 2: COMO O ATACANTE LOCALIZA E INVADE NO MUNDO REAL

> **Dúvida comum:** *"Como o atacante encontrou esse arquivo? Como ele invadiu para poder alterá-lo?"*

Na demonstração prática, o **volume compartilhado `/app/shared`** é uma **abstração pedagógica** para permitir que o teste ocorra de forma rápida e focada na vulnerabilidade de integridade (OWASP A08).

No **mundo real**, o invasor utiliza um dos seguintes vetores da cadeia de invasão (*Cyber Kill Chain*) para localizar e sobrescrever o arquivo:

1. **Vetor 1: Storage de Rede Desprotegido (NFS, SMB, AWS S3 / EFS):**
   * Em arquiteturas com múltiplos servidores ou microsserviços, a pasta `/app/shared` costuma ser um ponto de montagem NFS ou SMB compartilhado na rede corporativa.
   * Se o compartilhamento tiver permissão permissiva sem autenticação, qualquer nó comprometido na rede varre e acessa a pasta com `showmount -e` ou `smbclient`.
2. **Vetor 2: Invasão Prévia com Baixo Privilégio & Escalação (Privilege Escalation):**
   * O atacante invade um serviço secundário (ex.: via falha LFI em uma aplicação web ou plugin vulnerável).
   * Ele obtém acesso como usuário restrito (`www-data`) e faz **Reconhecimento Interno**:
     ```bash
     find / -name "*.pkl" 2>/dev/null
     grep -rnw "pickle.load" /app/ 2>/dev/null
     ```
   * Ao encontrar um arquivo `session.pkl` com permissão de escrita permissiva (`777` ou mesmo grupo) executado pelo administrador, o atacante **o sobrescreve** para que, quando o admin rodar o programa, o ataque rode com os **privilégios de administrador** (Escalação de Privilégios)!
3. **Vetor 3: Containers Compartilhados em Kubernetes / CI-CD:**
   * Múltiplos containers dividindo o mesmo *PersistentVolumeClaim* (PVC `ReadWriteMany`).
4. **Vetor 4: Interceptação em Trânsito (Man-in-the-Middle):**
   * Sessões transmitidas sem TLS/mTLS em filas de mensageria (RabbitMQ/Redis) ou cookies HTTP.

---

### ETAPA 2: Infecção do Arquivo .pkl (Máquina do Atacante)
- **📌 O que é feito:** O atacante detecta o `session.pkl` no volume compartilhado e o substitui por um payload malicioso armado.
- **⚙️ Como é feito:** Execução de `python exploit.py [1 ou 2]` na `maquina_atacante`. O script serializa a classe `MaliciousPayload` que implementa o dunder method `__reduce__()`.
- **⚔️ Quais técnicas:**
  - **Injeção de bytecode / callable via `__reduce__`:** O protocolo pickle invoca automaticamente o callable retornado por `__reduce__()` no momento do `load()`.
  - **Man-in-the-Middle em volume compartilhado:** Adulteração silenciosa de arquivos em repouso.
  - **Armamento de RCE (Remote Code Execution):** Injeção de rotinas para roubo ou destruição de dados.
- **💥 Quais consequências:** Adulteração invisível da integridade da aplicação. O arquivo parece uma sessão legítima, mas executará código malicioso assim que for aberto.
- **🔍 Como validar em tempo real:**
  ```bash
  docker exec -it maquina_atacante ls -lh /app/shared/session.pkl
  # Ver bytes brutos contendo comandos maliciosos:
  docker exec -it maquina_atacante python -c "print(open('/app/shared/session.pkl', 'rb').read())"
  ```

---

### ETAPA 3: Login Infectado — Execução Automática do Ataque (Vítima)
- **📌 O que é feito:** A vítima executa `python login.py` novamente para restaurar seu login. No ato da leitura, o código do atacante toma conta do processo.
- **⚙️ Como é feito:** O comando `pickle.load()` aciona o método `__reduce__` injetado, que imediatamente executa `comandos.exfiltrar_tabelas` ou `comandos.dropar_tabela`.
- **⚔️ Quais técnicas:**
  - **Insecure Deserialization Exploitation:** Execução de código arbitrário sem sanitização.
  - **Roubo de contexto de privilégios:** O código roda com as credenciais e o acesso de rede legítimos da vítima.
  - **Exfiltração de dados / DROP TABLE:** Leitura de schemas, dumps de tabelas ou destruição de registros no PostgreSQL.
- **💥 Quais consequências:**
  - **Vazamento de dados sigilosos (LGPD/GDPR):** Exposição de usuários, senhas com hashes, CPFs de clientes, transações financeiras e segredos mestres (`JWT_SECRET`, `API_KEY_PAGAMENTO`).
  - **Destruição do banco de dados (se escolhido Payload 2):** Eliminação permanente de todas as tabelas via `DROP TABLE CASCADE`.
- **🔍 Como validar em tempo real:**
  ```bash
  # Ver na tela da vítima o dump dos dados vazados.
  # Se usou Payload 2, comprove a destruição no banco:
  docker exec -it servidor_bd psql -U postgres -d demo_db -c "\dt"
  ```

---

### ETAPA 4: Auditoria Forense e Mitigações
- **📌 O que é feito:** Análise dos danos causados e estudo de caso das arquiteturas defensivas.
- **🛡️ Técnicas de Defesa:**
  1. **Substituição por formatos neutros:** Utilizar `JSON`, `msgpack` ou `protobuf` para dados serializados (eles transferem apenas dados, nunca comportamento).
  2. **Assinatura HMAC-SHA256:** Verificar autenticidade e integridade criptográfica antes de qualquer desserialização.
  3. **`RestrictedUnpickler`:** Whitelist estrita de classes e módulos permitidos.
  4. **Menor Privilégio (PoLP):** Revogar privilégios destrutivos de usuários comuns no banco de dados.

---

## 🚀 Como Executar a Demonstração

No terminal do PowerShell (com permissão explícita antes de cada etapa):
```powershell
.\executar-ataque.ps1
```

Durante a execução:
- Pressione **ENTER** para autorizar e rodar cada etapa.
- Pressione **V** a qualquer momento para abrir o **Menu de Auditoria ao Vivo** e executar comandos dentro dos containers.
- Pressione **S** para pular ou **Q** para sair.

---

## 🔍 Como Entrar em Cada Máquina Simulada em Tempo Real

Abra uma janela de terminal paralela para demonstrar a auditoria ao vivo:

### Máquina da Vítima
```bash
docker exec -it maquina_vitima bash
# Ver arquivos:
ls -la /app/shared
# Ler conteúdo do pickle:
python -c "import pickle; print(pickle.load(open('/app/shared/session.pkl', 'rb')))"
```

### Máquina do Atacante
```bash
docker exec -it maquina_atacante bash
# Ver scripts de exploit:
cat /app/exploit.py
cat /app/comandos/__init__.py
```

### Servidor de Banco de Dados
```bash
docker exec -it servidor_bd psql -U postgres -d demo_db
# Consultar tabelas e dados:
\dt
SELECT * FROM usuarios;
SELECT * FROM clientes;
SELECT * FROM transacoes;
SELECT * FROM config_sistema;
```

---

## 📁 Estrutura de Arquivos

```
attack-demo/
├── docker-compose.yml     # Orquestração dos 3 containers (servidor_bd, maquina_vitima, maquina_atacante)
├── Dockerfile             # Imagem Python 3.11 para vítima e atacante
├── executar-ataque.ps1    # Script visual interativo com controle de permissão
├── login.py               # Script cliente da vítima (vulnerável a pickle.load)
├── exploit.py             # Script de ataque com o payload __reduce__
├── config.py              # Parâmetros de rede e banco de dados
├── requirements.txt       # Dependências (psycopg2-binary)
├── init-db/
│   └── init.sql           # Seed de dados confidenciais (usuários, salários, clientes, secrets)
└── comandos/
    └── __init__.py        # Rotinas maliciosas injetadas (exfiltração e DROP TABLE)
```
