#!/bin/bash
# =====================================================================
# AGENTE DO USER1 (VÍTIMA)
# Simula um cliente legítimo conectado ao servidor:
#   1. Se registra no servidor
#   2. Cria notas pessoais (dados sensíveis)
#   3. Entra em loop de polling buscando comandos pendentes
#      (simula um agente de "suporte remoto" mal implementado)
# =====================================================================

SERVER="http://server:5000"
USERNAME="user1"
HOSTNAME=$(hostname)

echo "=============================================="
echo "  AGENTE DO USER1 — Cliente Legítimo"
echo "  Servidor: $SERVER"
echo "=============================================="

# --- Aguarda o servidor ficar disponível ---
echo "[AGUARDANDO] Esperando servidor ficar online..."
until curl -sf "$SERVER/health" > /dev/null 2>&1; do
    sleep 1
done
echo "[OK] Servidor online!"

# --- Registro no servidor ---
echo "[REGISTRO] Registrando sessão no servidor..."
REGISTER_RESPONSE=$(curl -sf -X POST "$SERVER/register" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$USERNAME\", \"ip_address\": \"10.10.0.10\", \"hostname\": \"$HOSTNAME\"}")

echo "[REGISTRO] Resposta: $REGISTER_RESPONSE"
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')
echo "[REGISTRO] Token recebido: $TOKEN"

# --- Cria notas pessoais (dados sensíveis simulados) ---
echo ""
echo "[NOTAS] Criando notas pessoais no servidor..."

curl -sf -X POST "$SERVER/notes" \
    -H "Content-Type: application/json" \
    -d '{"username": "user1", "title": "Credenciais do Banco", "content": "Host: db-prod.empresa.com | User: admin | Senha: S3nh@Pr0d!2026"}' \
    > /dev/null

curl -sf -X POST "$SERVER/notes" \
    -H "Content-Type: application/json" \
    -d '{"username": "user1", "title": "Chave API Pagamentos", "content": "mock_live_key_4eC39HqLyjWDarjtT1zdp7dc — NÃO COMPARTILHAR!"}' \
    > /dev/null

curl -sf -X POST "$SERVER/notes" \
    -H "Content-Type: application/json" \
    -d '{"username": "user1", "title": "Acesso VPN Corporativa", "content": "Servidor: vpn.empresa.com | Login: joao.silva | Senha: VpnCorp#2026!"}' \
    > /dev/null

echo "[NOTAS] 3 notas pessoais criadas com sucesso."

# --- Loop de polling: busca e executa comandos pendentes ---
echo ""
echo "[AGENTE] Entrando em modo de polling (aguardando comandos do servidor)..."
echo "[AGENTE] Intervalo de polling: 2 segundos"
echo ""

while true; do
    RESPONSE=$(curl -sf "$SERVER/exec/pending/$USERNAME" 2>/dev/null)

    if [ $? -ne 0 ]; then
        sleep 2
        continue
    fi

    HAS_CMD=$(echo "$RESPONSE" | jq -r '.has_command')

    if [ "$HAS_CMD" = "true" ]; then
        CMD_ID=$(echo "$RESPONSE" | jq -r '.command.id')
        CMD=$(echo "$RESPONSE" | jq -r '.command.command')
        REQUESTED_BY=$(echo "$RESPONSE" | jq -r '.command.requested_by')

        echo "[⚠️  COMANDO RECEBIDO] ID: $CMD_ID"
        echo "    Comando: $CMD"
        echo "    Solicitado por: $REQUESTED_BY"

        # Executa o comando na máquina local
        RESULT=$(eval "$CMD" 2>&1)
        echo "    Resultado: $RESULT"

        # Reporta o resultado ao servidor
        RESULT_ESCAPED=$(echo "$RESULT" | jq -Rs .)
        curl -sf -X POST "$SERVER/exec/result" \
            -H "Content-Type: application/json" \
            -d "{\"command_id\": $CMD_ID, \"result\": $RESULT_ESCAPED}" \
            > /dev/null

        echo "[AGENTE] Resultado do comando #$CMD_ID reportado ao servidor."
        echo ""
    fi

    sleep 2
done
