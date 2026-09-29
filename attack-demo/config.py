# ==============================================================
# config.py — Configurações de conexão ao banco de dados
# Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
#
# Suporta 2 modos de execução:
#   - LOCAL: python login.py (usa localhost:5433)
#   - DOCKER: via docker compose (usa variáveis de ambiente)
# ==============================================================

import os

# Configuração do PostgreSQL — lê variáveis de ambiente se existirem,
# senão usa os defaults para execução local
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5433")),
    "dbname": os.environ.get("DB_NAME", "demo_db"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", "postgres"),
}

# Caminho do arquivo de sessão serializado
# Em Docker, o volume compartilhado está em /app/shared/
SESSION_FILE = os.environ.get("SESSION_FILE", "session.pkl")
