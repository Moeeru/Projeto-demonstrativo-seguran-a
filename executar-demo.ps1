# =====================================================================
# executar-demo.ps1 -- Script Interativo de Resiliencia e Integridade em APIs
# Demonstracao: Rota do Caos vs Rota Resiliente
# Padroes: Atomicidade (@Transactional), Idempotencia e Fail-Fast
# =====================================================================

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:8080"

# ─────────────────────────────────────────────────────────
# FUNCOES VISUAIS E DE FORMATACAO
# ─────────────────────────────────────────────────────────

function Escrever-Cabecalho {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    LABORATORIO EDUCATIVO: RESILIENCIA E INTEGRIDADE DE DADOS EM APIS             " -ForegroundColor Yellow
    Write-Host "    Demonstracao Pratica: Rota do Caos vs Rota Resiliente (Spring Boot 3)         " -ForegroundColor Cyan
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Escrever-Topologia {
    Write-Host "  +-- ARQUITETURA DO AMBIENTE (CONTAINERS DOCKER) --------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |                                                                               |" -ForegroundColor DarkCyan
    Write-Host "  |   [ CLIENTE / SCRIPT ]                  [ API SPRING BOOT 3 ]                 |" -ForegroundColor White
    Write-Host "  |     HTTP / REST (Porta 8080)  ------->    container: demo_spring_api          |" -ForegroundColor DarkGray
    Write-Host "  |     - /api/vulneravel (Caos)              - Fail-Fast (@Valid)                |" -ForegroundColor DarkYellow
    Write-Host "  |     - /api/protegido (Resiliente)         - Atomicidade (@Transactional)      |" -ForegroundColor Green
    Write-Host "  |                                           - Idempotencia (integration_id)     |" -ForegroundColor Green
    Write-Host "  |                                                    |                          |" -ForegroundColor DarkCyan
    Write-Host "  |                                                    v JPA / Hibernate          |" -ForegroundColor DarkCyan
    Write-Host "  |                                       [ BANCO POSTGRESQL 16 ]                 |" -ForegroundColor Cyan
    Write-Host "  |                                         container: demo_postgres:5433        |" -ForegroundColor DarkCyan
    Write-Host "  |                                         tabelas: ordens_servico, itens...     |" -ForegroundColor DarkCyan
    Write-Host "  +-------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Escrever-CardCenario {
    param(
        [string]$Numero,
        [string]$Titulo,
        [string]$OQueEFeito,
        [string]$ComoEFeito,
        [string]$Tecnicas,
        [string]$Consequencias,
        [string]$ComoValidar
    )

    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host ("  CENARIO {0}: {1}" -f $Numero, $Titulo) -ForegroundColor Yellow
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host "  [*] O QUE E FEITO:" -ForegroundColor Cyan
    Write-Host ("      " + $OQueEFeito) -ForegroundColor White
    Write-Host ""
    Write-Host "  [*] COMO E FEITO:" -ForegroundColor Cyan
    Write-Host ("      " + $ComoEFeito) -ForegroundColor White
    Write-Host ""
    Write-Host "  [*] TECNICAS UTILIZADAS:" -ForegroundColor Cyan
    Write-Host ("      " + $Tecnicas) -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  [*] CONSEQUENCIAS REAIS:" -ForegroundColor Cyan
    Write-Host ("      " + $Consequencias) -ForegroundColor Red
    Write-Host ""
    Write-Host "  [*] COMO VALIDAR / AUDITAR EM TEMPO REAL:" -ForegroundColor Cyan
    Write-Host ("      " + $ComoValidar) -ForegroundColor Green
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Escrever-Status {
    param([string]$Badge, [string]$Mensagem, [string]$Cor = "White")
    Write-Host ("  [{0}] " -f $Badge) -NoNewline -ForegroundColor Cyan
    Write-Host $Mensagem -ForegroundColor $Cor
}

# ─────────────────────────────────────────────────────────
# MENU DE INSPECAO EM TEMPO REAL
# ─────────────────────────────────────────────────────────

function Menu-InspecaoApi {
    while ($true) {
        Write-Host ""
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    MENU DE AUDITORIA AO VIVO DA API E BANCO DE DADOS                             " -ForegroundColor Yellow
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    [1] Consultar ordens registradas no banco (GET /api/ordens)" -ForegroundColor Cyan
        Write-Host "    [2] Consultar ordens orfas (GET /api/ordens/orfas)" -ForegroundColor Yellow
        Write-Host "    [3] Executar query direta no container 'demo_postgres' via psql" -ForegroundColor Cyan
        Write-Host "    [4] Ver ultimos logs do container 'demo_spring_api'" -ForegroundColor Magenta
        Write-Host "    [0] Voltar para o roteiro da demonstracao" -ForegroundColor Green
        Write-Host ""
        $op = Read-Host "  Digite a opcao desejada [0-4]"

        switch ($op) {
            "1" {
                $resp = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET
                Write-Host "`n  Total de ordens cadastradas: $($resp.Count)" -ForegroundColor Yellow
                $resp | Format-Table id, cliente, integrationId, status, quantidadeItens -AutoSize
            }
            "2" {
                $orfas = Invoke-RestMethod -Uri "$baseUrl/api/ordens/orfas" -Method GET
                Write-Host "`n  Total de ordens orfas: $($orfas.totalOrdensOrfas)" -ForegroundColor Red
                $orfas.ordens | Format-Table id, cliente, integrationId, quantidadeItens -AutoSize
            }
            "3" {
                Write-Host "`n  --> [demo_postgres] SELECT * FROM ordens_servico:" -ForegroundColor Yellow
                docker exec demo_postgres psql -U postgres -d demo_db -c "SELECT id, cliente, integration_id, status, created_at FROM ordens_servico;"
                Write-Host "`n  --> [demo_postgres] SELECT * FROM itens_ordem:" -ForegroundColor Yellow
                docker exec demo_postgres psql -U postgres -d demo_db -c "SELECT id, ordem_servico_id, descricao, valor FROM itens_ordem;"
            }
            "4" {
                Write-Host "`n  --> [demo_spring_api] Ultimos 20 logs da aplicacao:" -ForegroundColor Yellow
                docker logs --tail 20 demo_spring_api
            }
            "0" { return }
            default { Write-Host "Opcao invalida." -ForegroundColor Red }
        }
    }
}

function Pedir-PermissaoCenario {
    param(
        [string]$Numero,
        [string]$Titulo,
        [string]$OQueEFeito,
        [string]$ComoEFeito,
        [string]$Tecnicas,
        [string]$Consequencias,
        [string]$ComoValidar
    )

    Escrever-CardCenario -Numero $Numero `
                         -Titulo $Titulo `
                         -OQueEFeito $OQueEFeito `
                         -ComoEFeito $ComoEFeito `
                         -Tecnicas $Tecnicas `
                         -Consequencias $Consequencias `
                         -ComoValidar $ComoValidar

    while ($true) {
        Write-Host "  +-- AUTORIZACAO NECESSARIA PARA EXECUTAR O CENARIO -----------------------------+" -ForegroundColor Yellow
        Write-Host "  | [ENTER]   -> Autorizar e disparar o Cenario $Numero agora                         |" -ForegroundColor White
        Write-Host "  | [V]       -> Abrir Menu de Validacao ao Vivo / Consultar Banco              |" -ForegroundColor Cyan
        Write-Host "  | [S]       -> Pular este cenario                                             |" -ForegroundColor DarkGray
        Write-Host "  | [Q]       -> Encerrar e sair da demonstracao                                |" -ForegroundColor Red
        Write-Host "  +-----------------------------------------------------------------------------+" -ForegroundColor Yellow
        $resp = Read-Host "  >> Pressione ENTER para prosseguir ou digite uma opcao [V/S/Q]"

        if ([string]::IsNullOrWhiteSpace($resp)) {
            Write-Host "`n  [+] Permissao CONCEDIDA pelo usuario. Executando Cenario $Numero...`n" -ForegroundColor Green
            return "EXECUTAR"
        }

        $respUpper = $resp.ToUpper()
        if ($respUpper -eq "V") {
            Menu-InspecaoApi
        } elseif ($respUpper -eq "S") {
            Write-Host "`n  [-] Cenario $Numero PULADO pelo usuario.`n" -ForegroundColor Yellow
            return "PULAR"
        } elseif ($respUpper -eq "Q") {
            Write-Host "`n  [X] Demonstracao CANCELADA pelo usuario.`n" -ForegroundColor Red
            exit 0
        } else {
            Write-Host "  Opcao nao reconhecida. Pressione ENTER para rodar ou 'Q' para sair." -ForegroundColor Red
        }
    }
}

# ═════════════════════════════════════════════════════════
# INICIO DA EXECUCAO
# ═════════════════════════════════════════════════════════

Escrever-Cabecalho
Escrever-Topologia

# ─────────────────────────────────────────────────────────
# TESTE DE CONECTIVIDADE COM A API
# ─────────────────────────────────────────────────────────
Escrever-Status "CONEXAO" "Verificando se a API esta online em $baseUrl..." "Yellow"
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET -TimeoutSec 5
    Escrever-Status "OK" "API conectada com sucesso na porta 8080!" "Green"
} catch {
    Escrever-Status "ERRO" "A API nao esta respondendo em $baseUrl." "Red"
    Write-Host "  Dica: Certifique-se de que os containers da raiz estao rodando:" -ForegroundColor Yellow
    Write-Host "  docker compose up -d" -ForegroundColor White
    exit 1
}

# ─────────────────────────────────────────────────────────
# RESET DO BANCO
# ─────────────────────────────────────────────────────────
Escrever-Status "RESET" "Limpando tabelas de ordens no banco de dados para iniciar o teste limpo..." "Cyan"
try {
    $reset = Invoke-RestMethod -Uri "$baseUrl/api/ordens/reset" -Method DELETE
    Escrever-Status "BANCO" "$($reset.mensagem)" "Green"
} catch {
    Escrever-Status "AVISO" "Nao foi possivel resetar o banco via endpoint." "DarkYellow"
}

# ─────────────────────────────────────────────────────────
# CENARIO 1: ROTA DO CAOS - PARTIAL COMMIT (ORDEM ORFA)
# ─────────────────────────────────────────────────────────
$paramsC1 = @{
    Numero = "1"
    Titulo = "ROTA DO CAOS -- INJECAO DE FALHA E PARTIAL COMMIT (ORDEM ORFA)"
    OQueEFeito = "Envio de pedido com 2 itens, onde o 2o item possui valor monetario negativo proposital (-150.00)."
    ComoEFeito = "POST em /api/vulneravel/ordens. O controller salva a ordem primeiro e itera os itens."
    Tecnicas = "Falta de anotacao @Transactional (violacao da Atomicidade ACID do banco de dados)."
    Consequencias = "A API falha com HTTP 500, mas a ordem mestre JA FICOU GRAVADA sem itens (Ordem Orfa)."
    ComoValidar = "GET /api/ordens/orfas ou docker exec -it demo_postgres psql -U postgres -d demo_db -c 'SELECT * FROM ordens_servico;'"
}
$c1 = Pedir-PermissaoCenario @paramsC1

if ($c1 -eq "EXECUTAR") {
    $payloadCaos1 = '{"cliente":"Construtora Imperial","integrationId":"CAOS-PARTIAL-001","itens":[{"descricao":"Servico de Terraplanagem","valor":2500.00},{"descricao":"Item Defeituoso (Valor Negativo)","valor":-150.00}]}'

    Write-Host "  Disparando requisicao defeituosa para a rota vulneravel..." -ForegroundColor Cyan
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payloadCaos1 -ContentType "application/json"
    } catch {
        Escrever-Status "FALHA 500" "A requisicao quebrou como esperado no meio do processamento!" "Yellow"
    }

    Write-Host ""
    Escrever-Status "AUDITORIA" "Consultando se ordens orfas foram criadas no banco de dados..." "Cyan"
    $orfas = Invoke-RestMethod -Uri "$baseUrl/api/ordens/orfas" -Method GET
    $qtdOrfas = $orfas.totalOrdensOrfas
    if ($qtdOrfas -gt 0) {
        Escrever-Status "ALERTA" "ENCONTRADA(S) $qtdOrfas ORDEM(NS) ORFA(S) NO BANCO DE DADOS!" "Red"
        foreach ($item in $orfas.ordens) {
            Write-Host ("     -> Ordem ID: {0} | Cliente: {1} | integrationId: {2} | Itens Salvos: {3}" -f $item.id, $item.cliente, $item.integrationId, $item.quantidadeItens) -ForegroundColor Red
        }
        Write-Host "     Impacto: Na vida real, isso gera cobrancas sem entrega e rombo contabil!" -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────────────────
# CENARIO 2: ROTA DO CAOS - RETRY ATTACK SEM IDEMPOTENCIA
# ─────────────────────────────────────────────────────────
$paramsC2 = @{
    Numero = "2"
    Titulo = "ROTA DO CAOS -- RETRY ATTACK SEM IDEMPOTENCIA (DUPLICIDADE)"
    OQueEFeito = "Disparo repetido de 3 requisicoes consecutivas com o mesmo integrationId."
    ComoEFeito = "POST em /api/vulneravel/ordens repetindo 'CAOS-DUP-999' sem verificar duplicidade."
    Tecnicas = "Ausencia de validacao de chave de idempotencia na recepcao de integracoes externas."
    Consequencias = "O sistema gera 3 ordens identicas, cobrando 3 vezes o cliente pelo mesmo produto!"
    ComoValidar = "GET /api/ordens/por-integration-id/CAOS-DUP-999 ou query direta no postgres."
}
$c2 = Pedir-PermissaoCenario @paramsC2

if ($c2 -eq "EXECUTAR") {
    $payloadCaos2 = '{"cliente":"Comercio de Pecas Silva","integrationId":"CAOS-DUP-999","itens":[{"descricao":"Kit de Filtros","valor":450.00}]}'

    for ($i = 1; $i -le 3; $i++) {
        $r = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payloadCaos2 -ContentType "application/json"
        Escrever-Status "DISPARO $i" ("Ordem criada com ID={0} para integrationId={1}" -f $r.id, $r.integrationId) "Magenta"
    }

    $dups = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/CAOS-DUP-999" -Method GET
    $totalDups = $dups.quantidadeRegistrosEncontrados
    Write-Host ""
    Escrever-Status "BANCO" "Total de ordens geradas para 'CAOS-DUP-999': $totalDups" "Red"
    Escrever-Status "RESULTADO" "Duplicidade descontrolada confirmada na Rota do Caos!" "Red"
}

# ─────────────────────────────────────────────────────────
# CENARIO 3: ROTA RESILIENTE - PROTECAO FAIL-FAST
# ─────────────────────────────────────────────────────────
$paramsC3 = @{
    Numero = "3"
    Titulo = "ROTA RESILIENTE -- PROTECAO FAIL-FAST (BEAN VALIDATION)"
    OQueEFeito = "Envio de payload com valor monetario negativo (-500.00) diretamente para a rota protegida."
    ComoEFeito = "POST em /api/protegido/ordens interceptado por @Valid e @DecimalMin na camada Web."
    Tecnicas = "Fail-Fast Pattern: validacao imediata na borda da aplicacao antes de consumir banco de dados."
    Consequencias = "Retorno HTTP 400 Bad Request instantaneo, poupando processamento e mantendo a integridade."
    ComoValidar = "O retorno e 400 no console e nenhum registro e inserido no PostgreSQL."
}
$c3 = Pedir-PermissaoCenario @paramsC3

if ($c3 -eq "EXECUTAR") {
    $payloadProt1 = '{"cliente":"Hospital Sao Lucas","integrationId":"PROT-FAILFAST-001","itens":[{"descricao":"Manutencao Preventiva","valor":-500.00}]}'

    try {
        $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payloadProt1 -ContentType "application/json"
    } catch {
        Escrever-Status "HTTP 400" "Payload corrompido BLOQUEADO pelo Fail-Fast antes de tocar no banco!" "Green"
    }
}

# ─────────────────────────────────────────────────────────
# CENARIO 4: ROTA RESILIENTE - ATOMICIDADE E ROLLBACK
# ─────────────────────────────────────────────────────────
$paramsC4 = @{
    Numero = "4"
    Titulo = "ROTA RESILIENTE -- ATOMICIDADE TRANSACIONAL E ROLLBACK (@Transactional)"
    OQueEFeito = "Simulacao de pane ou erro de negocio durante a persistencia dos itens do pedido."
    ComoEFeito = "POST em /api/protegido/ordens?simularFalhaTransacao=true com anotacao @Transactional."
    Tecnicas = "Principio ACID (Atomicidade): ou a transacao e 100% efetivada ou sofre Rollback completo."
    Consequencias = "Nenhuma ordem orfa ou estado parcial e registrado no banco de dados."
    ComoValidar = "GET /api/ordens/por-integration-id/PROT-ROLLBACK-002 retorna 0 registros encontrados."
}
$c4 = Pedir-PermissaoCenario @paramsC4

if ($c4 -eq "EXECUTAR") {
    $payloadProt2 = '{"cliente":"Logistica Expressa","integrationId":"PROT-ROLLBACK-002","itens":[{"descricao":"Rastreamento de Carga","valor":890.00}]}'

    try {
        $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens?simularFalhaTransacao=true" -Method POST -Body $payloadProt2 -ContentType "application/json"
    } catch {
        Escrever-Status "FALHA 500" "Falha forcada durante o processamento para testar o Rollback." "Yellow"
    }

    $buscaRollback = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/PROT-ROLLBACK-002" -Method GET
    if ($buscaRollback.quantidadeRegistrosEncontrados -eq 0) {
        Escrever-Status "ROLLBACK" "Sucesso total! Rollback executado: ZERO ordens orfas gravadas no banco." "Green"
    } else {
        Escrever-Status "ERRO" "A ordem foi gravada indevidamente!" "Red"
    }
}

# ─────────────────────────────────────────────────────────
# CENARIO 5: ROTA RESILIENTE - IDEMPOTENCIA ATIVA
# ─────────────────────────────────────────────────────────
$paramsC5 = @{
    Numero = "5"
    Titulo = "ROTA RESILIENTE -- RETRY ATTACK COM IDEMPOTENCIA ATIVA"
    OQueEFeito = "Disparo de 3 requisicoes consecutivas com a mesma chave 'PROT-IDEMP-777' na rota protegida."
    ComoEFeito = "A service verifica existsByIntegrationId: a 1a cria a ordem, a 2a e 3a retornam 200 OK sem duplicar."
    Tecnicas = "Chave de Idempotencia Natural (Natural Business Key) e Deduplicacao no Application Layer."
    Consequencias = "O sistema se torna imune a reenvios desordenados de rede ou disparos acidentais."
    ComoValidar = "GET /api/ordens/por-integration-id/PROT-IDEMP-777 comprova EXATAMENTE 1 registro no banco."
}
$c5 = Pedir-PermissaoCenario @paramsC5

if ($c5 -eq "EXECUTAR") {
    $payloadProt3 = '{"cliente":"Fintech Inovadora","integrationId":"PROT-IDEMP-777","itens":[{"descricao":"Gateway de Pagamentos Mensal","valor":1200.00}]}'

    for ($i = 1; $i -le 3; $i++) {
        $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payloadProt3 -ContentType "application/json"
        Escrever-Status "DISPARO $i" ("Status: {0} | Mensagem: {1}" -f $r.status, $r.mensagem) "Green"
    }

    $buscaIdemp = Invoke-RestMethod -Uri "$baseUrl/api/ordens/por-integration-id/PROT-IDEMP-777" -Method GET
    $totalIdemp = $buscaIdemp.quantidadeRegistrosEncontrados
    Write-Host ""
    Escrever-Status "BANCO" "Total de registros encontrados no banco para 'PROT-IDEMP-777': $totalIdemp" "Green"
    if ($totalIdemp -eq 1) {
        Escrever-Status "IDEMPOTENCIA" "Idempotencia comprovada com exito! Exatamente 1 registro salvo apos 3 disparos." "Green"
    }
}

# ─────────────────────────────────────────────────────────
# AUDITORIA FINAL E TABELA COMPARATIVA
# ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ================================================================================" -ForegroundColor Cyan
Write-Host "    AUDITORIA FINAL DA BASE DE DADOS (demo_postgres)                              " -ForegroundColor Yellow
Write-Host "  ================================================================================" -ForegroundColor Cyan

$todas = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET
Write-Host "  Total Geral de Ordens Persistidas no Banco: $($todas.Count)" -ForegroundColor Yellow
Write-Host ""

$tabela = @()
foreach ($o in $todas) {
    $tabela += [PSCustomObject]@{
        "ID"            = $o.id
        "Cliente"       = $o.cliente
        "IntegrationID" = $o.integrationId
        "Status"        = $o.status
        "Qtd Itens"     = $o.quantidadeItens
    }
}
$tabela | Format-Table -AutoSize

Write-Host "  Deseja abrir o Menu de Validacao ao Vivo para inspecionar os containers da API? (S/N)" -ForegroundColor Yellow
$validaFim = Read-Host "  Escolha [S/N]"
if ($validaFim -eq "S" -or $validaFim -eq "s") {
    Menu-InspecaoApi
}

Write-Host ""
Write-Host "  Demonstracao de Resiliencia concluida com sucesso!" -ForegroundColor Green
Write-Host ""
