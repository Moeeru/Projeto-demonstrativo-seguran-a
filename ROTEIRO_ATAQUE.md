# 🎤 Roteiro de Apresentação: Ataque Lateral via Servidor

Este roteiro acompanha o script `executar-ataque.ps1` e fornece falas sugeridas para cada etapa da demonstração de segurança.

---

## 🧭 Visão Geral

| Momento | Tópico | Efeito Visual |
|---------|--------|---------------|
| **Abertura (1-2 min)** | Cenário de ataque lateral | Diagrama dos 3 containers subindo |
| **Reconhecimento (2-3 min)** | Sessões expostas sem autenticação | Dados de IP, hostname e tokens vazados |
| **Roubo de Dados (2-3 min)** | Notas privadas acessadas sem autorização | Credenciais sensíveis expostas |
| **Execução Remota (3-4 min)** | Comandos executados na máquina da vítima | Arquivos lidos, processos listados, arquivo criado |
| **Conclusão (2-3 min)** | Vulnerabilidades e como prevenir | Resumo das falhas e boas práticas |

---

## 🛠️ Preparação Prévia

1. Certifique-se de que o **Docker Desktop** está rodando.
2. Abra o terminal PowerShell na pasta do projeto.
3. O script `executar-ataque.ps1` cuida de tudo automaticamente.

---

## 🎙️ Falas por Etapa

### Etapa 0: Preparação do Ambiente
> *"Vamos montar nosso laboratório. São 3 máquinas Docker em uma rede isolada:
> o User1 que é um usuário legítimo, o Server que oferece um serviço de notas
> com API, e o User2 que é um atacante disfarçado de usuário normal.
> Todos estão na mesma rede 10.10.0.0/24, como estaria numa rede corporativa."*

### Etapa 1: User1 Conectado — Uso Legítimo
> *"O User1 se conectou normalmente ao servidor e criou 3 notas pessoais
> contendo credenciais de banco de dados, chaves de API de pagamento e
> acesso VPN. Ele confia que o servidor protege seus dados. Vejam as notas
> que ele criou..."*

### Etapa 2: User2 Se Conecta
> *"Agora o User2 se conecta ao mesmo servidor. Até aqui, tudo parece normal
> — ele se registra como um usuário comum. Mas na verdade, ele é um atacante
> e vai explorar falhas de design na API."*

### Etapa 3: Reconhecimento — Sessões Expostas
> *"A primeira vulnerabilidade: o endpoint /admin/sessions está acessível
> sem nenhuma autenticação. Qualquer usuário que descubra essa rota consegue
> ver TODOS os usuários conectados, seus IPs, hostnames e até tokens de sessão.
> Isso é o que chamamos de Information Disclosure — vazamento de informações."*

### Etapa 4: Roubo de Dados — Notas Privadas
> *"Segunda vulnerabilidade: a rota de notas não valida autoria. O endpoint
> GET /notes/user1 retorna as notas de qualquer usuário sem verificar quem
> está pedindo. O User2 simplesmente trocou o username na URL e obteve
> credenciais de banco de dados, chaves de API de pagamentos e acessos VPN
> do User1. Isso é um IDOR — Insecure Direct Object Reference."*

### Etapa 5: Execução Remota de Comandos
> *"A falha mais crítica: o servidor tem um endpoint /exec que permite
> enviar comandos para serem executados no agente de qualquer usuário conectado.
> Isso simula uma funcionalidade de 'suporte remoto' mal implementada —
> sem validar QUEM está solicitando a execução. O User2 agora vai:
> 1. Ler arquivos pessoais do User1
> 2. Criar um arquivo de prova na máquina dele
> 3. Listar os processos em execução
> Tudo isso remotamente, usando o servidor como ponte."*

### Etapa 6: Verificação Final
> *"Para provar que o ataque funcionou, vamos acessar diretamente o container
> do User1 e verificar se o arquivo HACKED.txt existe. Vejam: o atacante
> conseguiu escrever na máquina da vítima sem ter acesso direto a ela."*

### Conclusão
> *"Resumindo: com apenas 3 requisições HTTP, o atacante conseguiu:
> reconhecer alvos, roubar dados sensíveis e executar comandos remotamente.
> As 3 vulnerabilidades exploradas foram:
> 1. Endpoint administrativo sem autenticação
> 2. Acesso a dados sem validação de autoria (IDOR)
> 3. Execução remota sem autorização
>
> Para prevenir: autenticação JWT/OAuth2 em todos os endpoints,
> autorização RBAC granular, princípio do menor privilégio,
> rate limiting, e logs de auditoria com alertas em tempo real."*

---

## ⚡ Execução Rápida

```powershell
.\executar-ataque.ps1
```

O script executa todas as etapas automaticamente, aguardando ENTER antes de cada uma para permitir que o apresentador explique o que está prestes a acontecer.

---

## 🧹 Limpeza do Ambiente

```powershell
docker compose -f docker-compose.ataque.yml down --remove-orphans
```
