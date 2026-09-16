# 🛡️ Projeto Demonstrativo de Resiliência & Idempotência em APIs

Projeto prático desenvolvido para demonstração técnica e defesa de engenharia de software, ilustrando a transição de uma **Rota do Caos** (sem proteção, suscetível a *Partial Commits* e duplicidades) para uma **Rota Resiliente** (com atomicidade transacional via `@Transactional`, idempotência por chave externa e *Fail-Fast* com validação antecipada).

---

## 🧰 Stack Tecnológica

- **Linguagem & Framework:** Java 21 LTS + Spring Boot 3.3.4
- **Persistência:** Spring Data JPA + Hibernate + PostgreSQL 16
- **Validação:** Bean Validation (Hibernate Validator)
- **Infraestrutura:** Docker & Docker Compose (Multi-stage build)
- **Ferramental de Demonstração:** Postman Collection v2.1 + Script PowerShell interativo

---

## 📁 Estrutura do Projeto

```
.
├── docker-compose.yml              # Orquestração do PostgreSQL + Spring Boot API
├── Dockerfile                      # Multi-stage build (Maven + Eclipse Temurin 21 JRE)
├── pom.xml                         # Dependências do projeto Spring Boot
├── executar-demo.ps1               # Script PowerShell de demonstração visual completa
├── demo-resiliencia.postman_collection.json # Collection pronta para o Postman
├── ROTEIRO_APRESENTACAO.md         # Roteiro passo a passo com falas da apresentação
└── src
    └── main
        ├── java/com/demo/resiliencia
        │   ├── ResilienciaApplication.java
        │   ├── controller
        │   │   ├── VulneravelController.java      # Rota do Caos (/api/vulneravel)
        │   │   ├── ProtegidoController.java        # Rota Resiliente (/api/protegido)
        │   │   └── DemoAuditoriaController.java    # Monitoramento & Reset (/api/ordens)
        │   ├── dto
        │   │   ├── OrdemServicoRequest.java
        │   │   ├── ItemOrdemRequest.java
        │   │   ├── OrdemServicoResponse.java
        │   │   └── ItemOrdemResponse.java
        │   ├── exception
        │   │   ├── InjecaoDeFalhaException.java
        │   │   └── GlobalExceptionHandler.java
        │   ├── model
        │   │   ├── OrdemServico.java
        │   │   └── ItemOrdem.java
        │   ├── repository
        │   │   ├── OrdemServicoRepository.java
        │   │   └── ItemOrdemRepository.java
        │   └── service
        │       ├── VulneravelService.java          # Sem transação, sem idempotência
        │       └── ProtegidoService.java           # @Transactional, checagem idempotente
        └── resources
            └── application.yml                     # Configuração do DataSource e logs
```

---

## 🚀 Como Executar

### 1. Subir o ambiente com Docker Compose
Na raiz do projeto, execute:
```bash
docker compose up --build -d
```
Isso irá:
1. Baixar o PostgreSQL 16 e aguardar a inicialização com *healthcheck*.
2. Compilar a API no estágio Maven do Dockerfile.
3. Subir a API Spring Boot conectada ao banco na porta **8080**.

Verifique se ambos os containers estão ativos:
```bash
docker compose ps
```

### 2. Rodar a Demonstração Automatizada (PowerShell)
Execute no terminal:
```powershell
.\executar-demo.ps1
```

### 3. Testar via Postman
1. Abra o Postman e clique em **Import**.
2. Selecione o arquivo `demo-resiliencia.postman_collection.json`.
3. Siga a ordem das pastas (`0. Auditoria`, `1. Rota do Caos`, `2. Rota Resiliente`).

---

## 📊 Comparativo dos Cenários

| Funcionalidade | Rota do Caos (`/api/vulneravel`) | Rota Resiliente (`/api/protegido`) |
| :--- | :--- | :--- |
| **Atomicidade** | ❌ Não usa `@Transactional`. Se um item falhar, a Ordem fica **órfã** no banco. | ✅ Usa `@Transactional`. Rollback total se qualquer erro ocorrer. |
| **Idempotência** | ❌ Não checa `integrationId`. Múltiplos envios criam múltiplas ordens duplicadas. | ✅ Consulta `existsByIntegrationId`. Reenvios retornam `200 OK` sem duplicar. |
| **Fail-Fast** | ❌ Não usa `@Valid`. Payloads corrompidos atingem a regra de negócio e o banco. | ✅ Usa `@Valid` e `@DecimalMin`. Retorna `400 Bad Request` antes de processar. |
