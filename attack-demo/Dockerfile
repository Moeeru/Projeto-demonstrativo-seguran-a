# ==============================================================
# Dockerfile para as máquinas Python (Vítima e Atacante)
# Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
# ==============================================================

FROM python:3.11-slim

WORKDIR /app

# Instalar dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todo o código da demo
COPY config.py .
COPY login.py .
COPY exploit.py .
COPY comandos/ ./comandos/

# Criar diretório compartilhado para o session.pkl
RUN mkdir -p /app/shared

# Manter o container vivo para execução interativa
CMD ["tail", "-f", "/dev/null"]
