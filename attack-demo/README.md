# 🦠 Attack Demo — Pickle Deserialization (OWASP A08:2021)

Demonstração prática de **Software and Data Integrity Failures** usando um ataque de desserialização Python Pickle.

---

## 📋 O que é demonstrado

| Etapa | Script | O que acontece |
|:------|:-------|:---------------|
| **1. Login legítimo** | `login.py` | Conecta no BD, exibe dados, salva sessão em `session.pkl` |
| **2. Infecção** | `exploit.py` | Substitui o `session.pkl` por um payload malicioso com `__reduce__` |
| **3. Login infectado** | `login.py` | `pickle.load()` executa o payload → exfiltra dados do servidor |

---

## 🚀 Como executar

### Pré-requisitos
1. Docker rodando com os containers do projeto principal:
   ```bash
   docker compose up -d
   ```
2. Python 3.8+ instalado

### Setup
```bash
cd attack-demo
pip install -r requirements.txt
```

### Demonstração em 3 passos

**Passo 1 — Login legítimo** (tudo funciona normalmente):
```bash
python login.py
```
> ✅ Conecta no banco, exibe informações e salva `session.pkl`

**Passo 2 — Infecção do .pkl** (o atacante age):
```bash
python exploit.py
```
> 🦠 Substitui o `session.pkl` por um payload malicioso

**Passo 3 — Login infectado** (a vítima executa novamente):
```bash
python login.py
```
> 🔥 O `pickle.load()` executa automaticamente o payload que exfiltra dados do servidor!

---

## 🔍 Como funciona o ataque

O ataque explora o método `__reduce__` do protocolo `pickle` do Python:

```python
class MaliciousPayload:
    def __reduce__(self):
        return (funcao_maliciosa, (arg1, arg2))
```

Quando `pickle.load()` encontra esse objeto, ele executa:
```python
funcao_maliciosa(arg1, arg2)
```

Isso permite **execução arbitrária de código** — no nosso caso, conectar no banco de dados e exfiltrar todas as tabelas.

---

## 🛡️ Como se proteger (mensagem educacional)

| Prática | Descrição |
|:--------|:----------|
| **Não usar `pickle` com dados não confiáveis** | Prefira `json`, `msgpack` ou `protobuf` |
| **Assinar arquivos serializados** | Use `hmac` para verificar integridade antes de carregar |
| **`RestrictedUnpickler`** | Subclasse de `pickle.Unpickler` que bloqueia classes perigosas |
| **Validação de input** | Nunca confie em arquivos que possam ter sido modificados |

---

## 📁 Estrutura

```
attack-demo/
├── config.py          # Configurações de conexão ao BD
├── login.py           # Script da vítima (salva/carrega .pkl)
├── exploit.py         # Script do atacante (infecta o .pkl)
├── requirements.txt   # Dependência: psycopg2-binary
├── session.pkl        # (gerado em runtime — não comitar!)
└── comandos/
    └── __init__.py    # Payloads de ataque (exfiltração, etc.)
```
