# 🎤 Roteiro de Apresentação Técnica: Resiliência em Integrações de Software

Este roteiro foi estruturado para apresentações de alto nível, defesas de projeto final ou demonstrações técnicas para liderança/equipe. Ele cobre a narrativa desde a infraestrutura em containers até os padrões fundamentais de engenharia de software (Atomicidade, Idempotência e Fail-Fast).

---

## 🧭 Visão Geral e Narrativa do Pitch

| Momento | Tópico Abordado | Efeito Visual / Prático |
| :--- | :--- | :--- |
| **Abertura (1-2 min)** | O problema real em integrações (webhooks instáveis, retentativas de rede, falhas parciais) | Apresentação da arquitetura e dos containers subindo |
| **O Show de Horrores (3-4 min)** | A Rota do Caos (`/api/vulneravel`) | Disparos com quebra (ordem órfã) e duplicação em massa |
| **A Redenção (4-5 min)** | A Rota Resiliente (`/api/protegido`) | Fail-Fast bloqueando lixo, `@Transactional` garantindo Rollback e Idempotência contendo o Retry Attack |
| **Conclusão (1-2 min)** | Padrões de arquitetura corporativa e lições aprendidas | Tabela comparativa final no banco de dados |

---

## 🛠️ Preparação Prévia (Antes de Iniciar a Apresentação)

1. Certifique-se de que o Docker Desktop está rodando.
2. Abra o terminal na pasta do projeto e inicie os containers:
   ```bash
   docker compose up --build -d
   ```
3. Verifique se os containers estão saudáveis:
   ```bash
   docker compose ps
   ```
4. Abra o Postman (importando o arquivo `demo-resiliencia.postman_collection.json`) **OU** deixe a janela do PowerShell pronta para rodar `.\executar-demo.ps1`.

---

## 🎙️ Passo a Passo da Apresentação

### 1. Introdução & Contexto da Infraestrutura
> **Fala sugerida:**  
> *"Em ecossistemas modernos baseados em microsserviços, filas e webhooks, a rede nunca é 100% confiável. Falhas acontecem, sistemas de pagamentos reenviam requisições e payloads corrompidos chegam à nossa porta.  
> Para demonstrar como a engenharia de software lida com esse caos, orquestramos um ambiente isolado com Docker Compose contendo um banco relacional PostgreSQL 16 e uma API Spring Boot 3."*

**O que mostrar:**
- O arquivo `docker-compose.yml` e o `Dockerfile` multi-stage.
- O comando `docker compose ps` mostrando `demo_spring_api` e `demo_postgres` rodando em portas isoladas.

---

### 2. O Show de Horrores: A Rota do Caos (`/api/vulneravel`)

#### Cenário 2.1: Injeção de Falha & Partial Commit (Ordem Órfã)
> **Fala sugerida:**  
> *"Vejamos agora o que acontece quando uma rota é construída sem a disciplina de transações. Vamos enviar um pedido com 2 itens, sendo que o segundo possui um valor negativo.  
> No código sem `@Transactional`, a ordem mestre é persistida primeiro. Quando o loop de itens encontra o valor inválido e quebra com uma exceção, a requisição retorna erro 500, mas a ordem já ficou gravada no banco como órfã, sem itens!"*

**Ação:**
- Disparar `1.1 Partial Commit` no Postman (ou rodar a primeira etapa no script).
- Mostrar o erro 500 na tela.
- Fazer a consulta de auditoria: `GET http://localhost:8080/api/ordens/orfas`.
- **Destaque:** Apontar na tela que o banco possui um registro sem itens associados. Na vida real, isso gera notas fiscais sem produtos e rombos contábeis.

#### Cenário 2.2: O Ataque de Duplicidade (Retry sem Idempotência)
> **Fala sugerida:**  
> *"Agora imagine que um sistema emissor de webhooks não receba confirmação a tempo por oscilação de rede e reenvie a mesma requisição 3 vezes.  
> Na nossa rota vulnerável, não há controle de chave de integração (`integration_id`)."*

**Ação:**
- Disparar `1.2 Duplicidade` 3 vezes com o mesmo `integrationId`.
- Fazer a consulta: `GET http://localhost:8080/api/ordens/por-integration-id/CAOS-DUP-999`.
- **Destaque:** Mostrar que foram geradas 3 ordens idênticas, causando cobrança tripla ao cliente.

---

### 3. A Redenção: A Rota Resiliente (`/api/protegido`)

#### Cenário 3.1: Proteção Fail-Fast com Bean Validation
> **Fala sugerida:**  
> *"A primeira linha de defesa é nunca deixar dados visivelmente inválidos tocarem na camada de negócio ou no banco de dados.  
> Com anotações como `@Valid`, `@NotNull` e `@DecimalMin("0.00")`, payloads com valores negativos são rejeitados imediatamente na borda do Controller com HTTP 400 Bad Request."*

**Ação:**
- Disparar `2.1 Fail-Fast` no Postman.
- **Destaque:** Mostrar o HTTP 400 imediato detalhando o campo inválido sem gerar overhead no banco.

#### Cenário 3.2: Atomicidade Transacional (`@Transactional` e Rollback)
> **Fala sugerida:**  
> *"E se a falha ocorrer durante o processamento de regras complexas de negócio?  
> Na rota protegida, anotamos o método com `@Transactional`. Se uma exceção não tratada for lançada no meio da operação, o Spring executa o ROLLBACK completo. Ou tudo é salvo com perfeição, ou absolutamente nada é persistido (Princípio ACID - Atomicidade)."*

**Ação:**
- Disparar `2.2 Atomicidade e Rollback` (`?simularFalhaTransacao=true`).
- Mostrar a consulta `GET http://localhost:8080/api/ordens/por-integration-id/PROT-ROLLBACK-002`.
- **Destaque:** Zero registros gravados. Nenhuma ordem órfã é criada.

#### Cenário 3.3: Idempotência Ativa contra Retry Attacks
> **Fala sugerida:**  
> *"Por fim, a proteção definitiva contra retentativas de webhooks e redes instáveis: Idempotência.  
> Toda integração carrega um `integration_id`. Ao receber a requisição, consultamos `existsByIntegrationId`. Se já foi processada, retornamos HTTP 200 confirmando o sucesso da operação, mas sem duplicar nada no banco."*

**Ação:**
- Disparar `2.3 Idempotência` (Cria a ordem -> HTTP 201 Created).
- Disparar `2.4 Idempotência` (Mesmo payload -> HTTP 200 OK com aviso: `IDEMPOTÊNCIA ATIVA`).
- Disparar novamente.
- Consultar `GET http://localhost:8080/api/ordens/por-integration-id/PROT-IDEMPOTENCY-003`.
- **Destaque:** Apenas 1 registro gravado no banco de dados!

---

### 4. Conclusão & Encerramento
> **Fala sugerida:**  
> *"Com essa demonstração, provamos na prática que:
> 1. **Containers (Docker Compose)** eliminam o problema do 'na minha máquina funciona';
> 2. **Fail-Fast** poupa recursos de processamento e banco;
> 3. **@Transactional** garante a integridade dos dados (sem registros fantasmas);
> 4. **Idempotência** é o pilar obrigatório de qualquer arquitetura de integração confiável."*

---

## ⚡ Demonstração em 1 Clique (PowerShell)

Caso queira fazer a apresentação inteira em um terminal formatado:
```powershell
.\executar-demo.ps1
```
O script executa todos os cenários, exibe mensagens coloridas e imprime a tabela final com os registros do banco.
