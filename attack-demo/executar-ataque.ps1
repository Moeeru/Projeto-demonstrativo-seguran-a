# =====================================================================
# executar-ataque.ps1 — Script de demonstração do ataque completo
# Projeto: Pickle Deserialization Attack (OWASP A08:2021)
#
# Executa os 3 passos do ataque nos containers Docker:
#   1. Login legítimo (maquina_vitima)
#   2. Infecção do .pkl (maquina_atacante)
#   3. Login infectado (maquina_vitima)
# =====================================================================

$ErrorActionPreference = "Continue"

function Escrever-Titulo {
    param([string]$texto)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

function Escrever-Status {
    param([string]$etapa, [string]$detalhe, [string]$cor = "White")
    Write-Host "[$etapa] " -NoNewline -ForegroundColor Cyan
    Write-Host $detalhe -ForegroundColor $cor
}

function Pausar {
    param([string]$mensagem = "Pressione ENTER para continuar...")
    Write-Host ""
    Write-Host "  >> $mensagem" -ForegroundColor DarkYellow
    Read-Host
}

# ─────────────────────────────────────────────────────────
# ETAPA 0: Verificar e subir os containers
# ─────────────────────────────────────────────────────────
Escrever-Titulo "ETAPA 0: SUBINDO A INFRAESTRUTURA (3 CONTAINERS)"

Write-Host "  Containers que serao criados:" -ForegroundColor White
Write-Host "    1. servidor_bd        - PostgreSQL 16 (Banco de Dados)" -ForegroundColor Green
Write-Host "    2. maquina_vitima     - Python (executa login.py)" -ForegroundColor Green
Write-Host "    3. maquina_atacante   - Python (executa exploit.py)" -ForegroundColor Red
Write-Host ""

Escrever-Status "DOCKER" "Construindo e iniciando containers..." "Yellow"
docker compose up --build -d 2>&1 | Out-Null

# Verificar se os containers subiram
Start-Sleep -Seconds 3
$containers = docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>&1
Write-Host ""
Write-Host $containers
Write-Host ""

# Verificar se o banco está pronto
$maxRetries = 15
$retry = 0
do {
    $retry++
    $healthCheck = docker exec servidor_bd pg_isready -U postgres -d demo_db 2>&1
    if ($LASTEXITCODE -eq 0) {
        Escrever-Status "BD" "PostgreSQL pronto e aceitando conexoes!" "Green"
        break
    }
    Write-Host "  Aguardando PostgreSQL iniciar... ($retry/$maxRetries)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
} while ($retry -lt $maxRetries)

if ($retry -ge $maxRetries) {
    Escrever-Status "ERRO" "PostgreSQL nao iniciou a tempo!" "Red"
    exit 1
}

# Verificar se o seed foi aplicado
$tabelaCheck = docker exec servidor_bd psql -U postgres -d demo_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
$tabelaCount = ($tabelaCheck -replace '\s','')
Escrever-Status "BD" "Tabelas no schema publico: $tabelaCount" "Green"

Pausar "Infraestrutura pronta. Pressione ENTER para iniciar a demonstracao..."

# ─────────────────────────────────────────────────────────
# ETAPA 1: Login Legítimo (Máquina da Vítima)
# ─────────────────────────────────────────────────────────
Escrever-Titulo "ETAPA 1: LOGIN LEGITIMO (Maquina da Vitima)"

Write-Host "  Cenario: O usuario executa o login.py normalmente." -ForegroundColor White
Write-Host "  O sistema conecta no banco, exibe os dados e salva a" -ForegroundColor White
Write-Host "  sessao em um arquivo session.pkl (serializado com pickle)." -ForegroundColor White
Write-Host ""
Write-Host "  Executando: docker exec maquina_vitima python login.py" -ForegroundColor DarkGray
Write-Host ""

docker exec maquina_vitima python login.py

Write-Host ""
Escrever-Status "INFO" "O arquivo session.pkl foi criado com dados legitimos." "Green"
Write-Host ""

# Mostrar que o arquivo existe
Write-Host "  Verificando session.pkl no volume compartilhado:" -ForegroundColor Cyan
docker exec maquina_vitima ls -la /app/shared/session.pkl 2>&1
Write-Host ""

Pausar "Login OK. Pressione ENTER para simular o ATAQUE..."

# ─────────────────────────────────────────────────────────
# ETAPA 2: Infecção do .pkl (Máquina do Atacante)
# ─────────────────────────────────────────────────────────
Escrever-Titulo "ETAPA 2: INFECCAO DO ARQUIVO .PKL (Maquina do Atacante)"

Write-Host "  Cenario: O atacante ganhou acesso ao filesystem da vitima" -ForegroundColor White
Write-Host "  (via volume compartilhado na demo, ou via exploit real)." -ForegroundColor White
Write-Host "  Ele substitui o session.pkl por um payload malicioso" -ForegroundColor White
Write-Host "  que explora o metodo __reduce__ do protocolo pickle." -ForegroundColor White
Write-Host ""
Write-Host "  Executando: docker exec maquina_atacante python exploit.py" -ForegroundColor DarkGray
Write-Host ""

docker exec maquina_atacante python exploit.py

Write-Host ""
Escrever-Status "ALERTA" "O arquivo session.pkl agora contem codigo malicioso!" "Red"
Write-Host ""

Pausar "Arquivo infectado! Pressione ENTER para ver o que acontece quando a vitima faz login novamente..."

# ─────────────────────────────────────────────────────────
# ETAPA 3: Login Infectado (Máquina da Vítima)
# ─────────────────────────────────────────────────────────
Escrever-Titulo "ETAPA 3: LOGIN INFECTADO — O ATAQUE E EXECUTADO!"

Write-Host "  Cenario: A vitima, sem saber da infeccao, executa o" -ForegroundColor White
Write-Host "  login.py novamente. O pickle.load() desserializa o" -ForegroundColor White
Write-Host "  arquivo .pkl infectado e executa automaticamente" -ForegroundColor White
Write-Host "  o payload malicioso: EXFILTRACAO DE DADOS DO SERVIDOR!" -ForegroundColor White
Write-Host ""
Write-Host "  Executando: docker exec maquina_vitima python login.py" -ForegroundColor DarkGray
Write-Host ""

docker exec maquina_vitima python login.py

Write-Host ""

# ─────────────────────────────────────────────────────────
# ENCERRAMENTO
# ─────────────────────────────────────────────────────────
Escrever-Titulo "DEMONSTRACAO CONCLUIDA"

Write-Host "  Resumo do ataque demonstrado:" -ForegroundColor White
Write-Host ""
Write-Host "    1. A vitima fez login legítimo e salvou session.pkl" -ForegroundColor Green
Write-Host "    2. O atacante infectou o .pkl com __reduce__ malicioso" -ForegroundColor Red
Write-Host "    3. Ao fazer login novamente, pickle.load() executou" -ForegroundColor Red
Write-Host "       o payload que EXFILTROU dados do servidor BD!" -ForegroundColor Red
Write-Host ""
Write-Host "  Vulnerabilidade: OWASP A08:2021 — Software and Data Integrity Failures" -ForegroundColor Yellow
Write-Host "  Vetor: Python Pickle Deserialization (metodo __reduce__)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Mitigacoes:" -ForegroundColor Cyan
Write-Host "    - Nao usar pickle com dados nao confiaveis" -ForegroundColor White
Write-Host "    - Usar JSON/msgpack em vez de pickle" -ForegroundColor White
Write-Host "    - Assinar arquivos serializados com HMAC" -ForegroundColor White
Write-Host "    - Implementar RestrictedUnpickler" -ForegroundColor White
Write-Host ""

$cleanup = Read-Host "Deseja derrubar os containers? (S/N)"
if ($cleanup -eq "S" -or $cleanup -eq "s") {
    Escrever-Status "CLEANUP" "Derrubando containers e removendo volumes..." "Yellow"
    docker compose down -v 2>&1 | Out-Null
    Escrever-Status "CLEANUP" "Containers removidos com sucesso!" "Green"
}

Write-Host ""
Write-Host "Demonstracao encerrada!" -ForegroundColor Green
Write-Host ""
