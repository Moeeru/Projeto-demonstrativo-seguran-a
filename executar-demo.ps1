# =====================================================================
# SCRIPT DE DEMONSTRACAO PRATICA: ROTA DO CAOS VS ROTA RESILIENTE
# Demonstracao de Atomicidade, Idempotencia e Fail-Fast em Integracoes
# =====================================================================

$baseUrl = "http://localhost:8080"

function Escrever-Titulo {
    param([string]$texto)
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Cyan
}

function Escrever-Status {
    param([string]$etapa, [string]$detalhe, [string]$cor = "White")
    Write-Host "[$etapa] " -NoNewline -ForegroundColor Cyan
    Write-Host $detalhe -ForegroundColor $cor
}

# 1. Testar conectividade com a API
Escrever-Titulo "VERIFICANDO SE A API ESTA ONLINE"
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET -TimeoutSec 5
    Escrever-Status "OK" "API conectada com sucesso na porta 8080!" "Green"
} catch {
    Escrever-Status "ERRO" "A API nao esta respondendo em $baseUrl." "Red"
    Write-Host "Certifique-se de ter iniciado os containers com: docker compose up -d" -ForegroundColor Yellow
    exit 1
}

# 2. Resetar o banco
Escrever-Titulo "PASSO 0: LIMPEZA INICIAL DO BANCO DE DADOS (RESET)"
$reset = Invoke-RestMethod -Uri "$baseUrl/api/ordens/reset" -Method DELETE
Escrever-Status "BANCO" "$($reset.mensagem)" "Green"

# 3. CENARIO 1: ROTA DO CAOS - PARTIAL COMMIT (ORDEM ORFA)
Escrever-Titulo "CENARIO 1: ROTA DO CAOS - INJECAO DE FALHA & PARTIAL COMMIT"
Write-Host "Objetivo: Enviar um payload com o 2o item com valor negativo (-150.00)."
Write-Host "Como a rota vulneravel NAO possui @Transactional, a ordem e persistida primeiro,"
Write-Host "o 2o item falha e a ordem fica ORFA no banco de dados."
Write-Host ""

$payloadCaos1 = '{"cliente":"Construtora Imperial","integrationId":"CAOS-PARTIAL-001","itens":[{"descricao":"Servico de Terraplanagem","valor":2500.00},{"descricao":"Item Defeituoso (Valor Negativo)","valor":-150.00}]}'

try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payloadCaos1 -ContentType "application/json"
} catch {
    Escrever-Status "FALHA 500" "A requisicao quebrou como esperado no meio do processamento!" "Yellow"
}

Write-Host ""
Write-Host "--> Consultando ordens orfas no banco de dados agora..." -ForegroundColor Cyan
$orfas = Invoke-RestMethod -Uri "$baseUrl/api/ordens/orfas" -Method GET
$qtdOrfas = $orfas.totalOrdensOrfas
if ($qtdOrfas -gt 0) {
    Escrever-Status "ALERTA" "ENCONTRADA(S) $qtdOrfas ORDEM(NS) ORFA(S) NO BANCO!" "Red"
    foreach ($item in $orfas.ordens) {
        $msgOrfa = "   -> Ordem ID: " + $item.id + " | Cliente: " + $item.cliente + " | integrationId: " + $item.integrationId + " | Qtd Itens Salvos: " + $item.quantidadeItens
        Write-Host $msgOrfa -ForegroundColor Red
    }
}

# 4. CENARIO 2: ROTA DO CAOS - DUPLICIDADE
Escrever-Titulo "CENARIO 2: ROTA DO CAOS - RETRY SEM IDEMPOTENCIA (DUPLICIDADE)"
Write-Host "Objetivo: Enviar o mesmo webhook 3 vezes com o integrationId 'CAOS-DUP-999'."
Write-Host "Sem validacao de chave de idempotencia, o sistema gera 3 ordens identicas."
Write-Host ""

$payloadCaos2 = '{"cliente":"Comercio de Pecas Silva","integrationId":"CAOS-DUP-999","itens":[{"descricao":"Kit de Filtros","valor":450.00}]}'

for ($i = 1; $i -le 3; $i++) {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payloadCaos2 -ContentType "application/json"
    $msgDup = "Ordem criada com ID=" + $r.id + " para integrationId=" + $r.integrationId
    Escrever-Status "DISPARO $i" $msgDup "Magenta"
}

$dups = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/CAOS-DUP-999" -Method GET
$totalDups = $dups.quantidadeRegistrosEncontrados
Escrever-Status "BANCO" "Total de ordens geradas para 'CAOS-DUP-999': $totalDups" "Red"
Write-Host "Resultado: Duplicidade descontrolada no banco de dados!" -ForegroundColor Red

# 5. CENARIO 3: ROTA PROTEGIDA - FAIL-FAST
Escrever-Titulo "CENARIO 3: ROTA RESILIENTE - PROTECAO FAIL-FAST (BEAN VALIDATION)"
Write-Host "Objetivo: Enviar payload com valor negativo para a rota protegida."
Write-Host "A anotacao @Valid no Controller bloqueia a requisicao antes de tocar no banco."
Write-Host ""

$payloadProt1 = '{"cliente":"Hospital Sao Lucas","integrationId":"PROT-FAILFAST-001","itens":[{"descricao":"Manutencao Preventiva","valor":-500.00}]}'

try {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payloadProt1 -ContentType "application/json"
} catch {
    Escrever-Status "HTTP 400" "Payload bloqueado pelo Fail-Fast antes de alcancar o banco!" "Green"
}

# 6. CENARIO 4: ROTA PROTEGIDA - ATOMICIDADE E ROLLBACK (@Transactional)
Escrever-Titulo "CENARIO 4: ROTA RESILIENTE - ATOMICIDADE E ROLLBACK (@Transactional)"
Write-Host "Objetivo: Simular um erro de negocio ou persistencia no meio da transacao."
Write-Host "Com @Transactional, o Spring reverte todas as insercoes e nada e salvo no banco."
Write-Host ""

$payloadProt2 = '{"cliente":"Logistica Expressa","integrationId":"PROT-ROLLBACK-002","itens":[{"descricao":"Rastreamento de Carga","valor":890.00}]}'

try {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens?simularFalhaTransacao=true" -Method POST -Body $payloadProt2 -ContentType "application/json"
} catch {
    Escrever-Status "FALHA 500" "Falha simulada durante o processamento." "Yellow"
}

$buscaRollback = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/PROT-ROLLBACK-002" -Method GET
if ($buscaRollback.quantidadeRegistrosEncontrados -eq 0) {
    Escrever-Status "ROLLBACK" "Sucesso total! Nenhuma ordem nem item foi gravado no banco de dados." "Green"
} else {
    Escrever-Status "ERRO" "A ordem foi gravada indevidamente!" "Red"
}

# 7. CENARIO 5: ROTA PROTEGIDA - RETRY ATTACK COM IDEMPOTENCIA
Escrever-Titulo "CENARIO 5: ROTA RESILIENTE - RETRY ATTACK COM IDEMPOTENCIA"
Write-Host "Objetivo: Disparar o mesmo payload 3 vezes consecutivas na rota protegida."
Write-Host "A 1a cria a ordem; a 2a e a 3a retornam HTTP 200 sem duplicar registros no banco."
Write-Host ""

$payloadProt3 = '{"cliente":"Fintech Inovadora","integrationId":"PROT-IDEMP-777","itens":[{"descricao":"Gateway de Pagamentos Mensal","valor":1200.00}]}'

for ($i = 1; $i -le 3; $i++) {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payloadProt3 -ContentType "application/json"
    $msgProt = "Status: " + $r.status + " | Mensagem: " + $r.mensagem
    Escrever-Status "DISPARO $i" $msgProt "Green"
}

$buscaIdemp = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/PROT-IDEMP-777" -Method GET
$totalIdemp = $buscaIdemp.quantidadeRegistrosEncontrados
Escrever-Status "BANCO" "Total de registros encontrados no banco para 'PROT-IDEMP-777': $totalIdemp" "Green"
if ($totalIdemp -eq 1) {
    Escrever-Status "IDEMPOTENCIA" "Idempotencia comprovada! Exatamente 1 registro persistido apos 3 disparos." "Green"
}

# 8. AUDITORIA FINAL
Escrever-Titulo "AUDITORIA FINAL DA BASE DE DADOS"
$todas = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET
$totalGeral = $todas.Count
Write-Host "Total de Ordens Registradas no Banco: $totalGeral" -ForegroundColor Yellow
Write-Host ""

$tabela = @()
foreach ($o in $todas) {
    $tabela += [PSCustomObject]@{
        ID = $o.id
        Cliente = $o.cliente
        IntegrationID = $o.integrationId
        Status = $o.status
        QtdItens = $o.quantidadeItens
    }
}
$tabela | Format-Table -AutoSize

Write-Host "Demonstracao concluida com sucesso!" -ForegroundColor Green
Write-Host ""
