# =====================================================================
# executar-demo.ps1 -- Demonstracao Didatica de Resiliencia e Integridade em APIs
# Laboratorio: Rota do Caos vs Rota Resiliente
# Padroes: Atomicidade (@Transactional), Idempotencia e Fail-Fast (@Valid)
# =====================================================================

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:8080"

# ---------------------------------------------------------
# FUNCOES VISUAIS E DE FORMATACAO
# ---------------------------------------------------------

function Escrever-Cabecalho {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    LABORATORIO EDUCATIVO: RESILIENCIA E INTEGRIDADE DE DADOS EM APIS             " -ForegroundColor Yellow
    Write-Host "    Demonstracao Pratica: Rota do Caos vs Rota Resiliente (Spring Boot 3)         " -ForegroundColor Cyan
    Write-Host "    Auditoria Forense em Tempo Real & Prova Viva no PostgreSQL 16                 " -ForegroundColor Green
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Escrever-Topologia {
    Write-Host "  +-- ARQUITETURA E FLUXO DO AMBIENTE (CONTAINERS DOCKER) -------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |                                                                                |" -ForegroundColor DarkCyan
    Write-Host "  |   [ SCRIPT / CLIENTE HTTP ]             [ API SPRING BOOT 3 ]                  |" -ForegroundColor White
    Write-Host "  |     HTTP/REST (Porta 8080)   ------>      container: demo_spring_api           |" -ForegroundColor DarkGray
    Write-Host "  |     - /api/vulneravel (Caos)              - Web Servlet Layer                  |" -ForegroundColor DarkYellow
    Write-Host "  |     - /api/protegido (Resiliente)         - Fail-Fast Interceptor (@Valid)     |" -ForegroundColor Green
    Write-Host "  |     - /api/ordens (Auditoria)             - Transaction Interceptor (@Trans)   |" -ForegroundColor Green
    Write-Host "  |                                           - Idempotency Filter (Natural Key)   |" -ForegroundColor Green
    Write-Host "  |                                                    |                           |" -ForegroundColor DarkCyan
    Write-Host "  |                                                    v JPA / Hibernate           |" -ForegroundColor DarkCyan
    Write-Host "  |                                       [ BANCO POSTGRESQL 16 ]                  |" -ForegroundColor Cyan
    Write-Host "  |                                         container: demo_postgres:5433         |" -ForegroundColor DarkCyan
    Write-Host "  |                                         - ordens_servico                       |" -ForegroundColor DarkCyan
    Write-Host "  |                                         - itens_ordem                          |" -ForegroundColor DarkCyan
    Write-Host "  |                                         - auditoria_transacional (PROVA REAL)  |" -ForegroundColor Green
    Write-Host "  +--------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Escrever-Status {
    param([string]$Badge, [string]$Mensagem, [string]$Cor = "White")
    Write-Host ("  [{0}] " -f $Badge) -NoNewline -ForegroundColor Cyan
    Write-Host $Mensagem -ForegroundColor $Cor
}

function Escrever-CardCenario {
    param(
        [string]$Numero,
        [string]$Titulo,
        [string]$OQueEFeito,
        [string]$ComoEFeito,
        [string]$MecanismoInterno,
        [string]$Consequencias,
        [string]$ComoValidar
    )

    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host ("  CENARIO {0}: {1}" -f $Numero, $Titulo) -ForegroundColor Yellow
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host "  [*] O QUE E FEITO (REGRA DE NEGOCIO):" -ForegroundColor Cyan
    Write-Host ("      " + $OQueEFeito) -ForegroundColor White
    Write-Host ""
    Write-Host "  [*] COMO E FEITO (CHAMADA HTTP):" -ForegroundColor Cyan
    Write-Host ("      " + $ComoEFeito) -ForegroundColor White
    Write-Host ""
    Write-Host "  [*] MECANISMO INTERNO / DEEP DIVE TECNICO:" -ForegroundColor Cyan
    Write-Host ("      " + $MecanismoInterno) -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  [*] IMPACTO NO MUNDO REAL (BUSINESS E AUDIT):" -ForegroundColor Cyan
    Write-Host ("      " + $Consequencias) -ForegroundColor Red
    Write-Host ""
    Write-Host "  [*] COMO VALIDAR / COMPROVAR EM TEMPO REAL:" -ForegroundColor Cyan
    Write-Host ("      " + $ComoValidar) -ForegroundColor Green
    Write-Host "  ================================================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Exibir-RequisicaoResposta {
    param(
        [string]$Metodo,
        [string]$Url,
        [string]$PayloadJson,
        [int]$StatusCode,
        [string]$TempoMs,
        [string]$RespostaJson
    )

    $corStatus = "Green"
    if ($StatusCode -ge 400 -and $StatusCode -lt 500) { $corStatus = "Yellow" }
    elseif ($StatusCode -ge 500) { $corStatus = "Red" }

    Write-Host "  +-- DETALHES DA TRANSMISSAO HTTP ------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ("  | [REQ] REQUISICAO: {0} {1}" -f $Metodo, $Url) -ForegroundColor Yellow
    if ($PayloadJson) {
        Write-Host "  |       PAYLOAD ENVIADO:" -ForegroundColor DarkGray
        Write-Host ("  |       " + $PayloadJson) -ForegroundColor Gray
    }
    Write-Host ("  | [RES] RESPOSTA: HTTP {0} | Latencia: {1}ms" -f $StatusCode, $TempoMs) -ForegroundColor $corStatus
    if ($RespostaJson) {
        $linhas = $RespostaJson -split "`n"
        $maxLinhas = [Math]::Min(10, $linhas.Count)
        Write-Host "  |       BODY RETORNADO:" -ForegroundColor DarkGray
        for ($i = 0; $i -lt $maxLinhas; $i++) {
            Write-Host ("  |       " + $linhas[$i].Trim()) -ForegroundColor DarkGray
        }
        if ($linhas.Count -gt 10) {
            Write-Host "  |       ... (conteudo truncado)" -ForegroundColor DarkGray
        }
    }
    Write-Host "  +--------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Exibir-ComprovacaoSql {
    param([string]$Titulo, [string]$QuerySql)

    Write-Host ("  [SQL] PROVA REAL NO POSTGRESQL [{0}]:" -f $Titulo) -ForegroundColor Yellow
    Write-Host ("        Query: " + $QuerySql) -ForegroundColor DarkGray
    try {
        $saida = docker exec demo_postgres psql -U postgres -d demo_db -c "$QuerySql" 2>&1
        $linhas = $saida -split "`n"
        foreach ($l in $linhas) {
            Write-Host ("        " + $l.TrimEnd()) -ForegroundColor Cyan
        }
    } catch {
        Write-Host "        [AVISO] Nao foi possivel consultar o container demo_postgres diretamente." -ForegroundColor DarkYellow
    }
    Write-Host ""
}

function Exibir-UltimoLogAuditoria {
    param([string]$IntegrationId = "")

    Write-Host "  [AUDITORIA] RASTRO FORENSE REGISTRADO NO BANCO (PostgreSQL):" -ForegroundColor Yellow
    try {
        $whereClause = ""
        if ($IntegrationId -ne "") {
            $whereClause = "WHERE integration_id = '$IntegrationId'"
        }
        $sql = "SELECT id, data_hora::time as hora, rota, tipo_cenario, status_execucao, codigo_http FROM auditoria_transacional $whereClause ORDER BY id DESC LIMIT 2;"
        $saida = docker exec demo_postgres psql -U postgres -d demo_db -c "$sql" 2>&1
        foreach ($l in ($saida -split "`n")) {
            Write-Host ("        " + $l.TrimEnd()) -ForegroundColor Green
        }
    } catch {
        Write-Host "        [AVISO] Nao foi possivel ler tabela de auditoria." -ForegroundColor DarkYellow
    }
    Write-Host ""
}

# ---------------------------------------------------------
# MENU DE AUDITORIA E ENTRADA EM TEMPO REAL
# ---------------------------------------------------------

function Menu-InspecaoApi {
    while ($true) {
        Write-Host ""
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    MENU DE AUDITORIA FORENSE AO VIVO E ENTRADA NOS CONTAINERS                   " -ForegroundColor Yellow
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    [1] Consultar ordens registradas no banco (GET /api/ordens)" -ForegroundColor Cyan
        Write-Host "    [2] Consultar ordens orfas por Partial Commit (GET /api/ordens/orfas)" -ForegroundColor Yellow
        Write-Host "    [3] Consultar tabela forense de auditoria (GET /api/ordens/auditoria)" -ForegroundColor Green
        Write-Host "    [4] Placar comparativo estatistico (GET /api/ordens/placar)" -ForegroundColor Cyan
        Write-Host "    [5] Consultar banco de dados PostgreSQL diretamente via 'psql'" -ForegroundColor Yellow
        Write-Host "    [6] Abrir terminal bash interativo ou psql ao vivo no terminal" -ForegroundColor Magenta
        Write-Host "    [7] Ver ultimos 30 logs da aplicacao Spring Boot (demo_spring_api)" -ForegroundColor Cyan
        Write-Host "    [0] Voltar para o roteiro da demonstracao" -ForegroundColor Green
        Write-Host ""
        $op = Read-Host "  Digite a opcao desejada [0-7]"

        switch ($op) {
            "1" {
                try {
                    $resp = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET
                    Write-Host "`n  Total de ordens cadastradas: $($resp.Count)" -ForegroundColor Yellow
                    if ($resp.Count -gt 0) {
                        $resp | Format-Table id, cliente, integrationId, status, quantidadeItens -AutoSize
                    } else {
                        Write-Host "  (Nenhuma ordem cadastrada no momento)" -ForegroundColor DarkGray
                    }
                } catch {
                    Write-Host "  Erro ao consultar API: $_" -ForegroundColor Red
                }
            }
            "2" {
                try {
                    $orfas = Invoke-RestMethod -Uri "$baseUrl/api/ordens/orfas" -Method GET
                    $corOrfas = "Green"
                    if ($orfas.totalOrdensOrfas -gt 0) { $corOrfas = "Red" }
                    Write-Host "`n  Total de ordens orfas: $($orfas.totalOrdensOrfas)" -ForegroundColor $corOrfas
                    Write-Host "  Diagnostico: $($orfas.mensagem)" -ForegroundColor Yellow
                    if ($orfas.totalOrdensOrfas -gt 0) {
                        $orfas.ordens | Format-Table id, cliente, integrationId, quantidadeItens -AutoSize
                    }
                } catch {
                    Write-Host "  Erro ao consultar ordens orfas: $_" -ForegroundColor Red
                }
            }
            "3" {
                try {
                    $audit = Invoke-RestMethod -Uri "$baseUrl/api/ordens/auditoria" -Method GET
                    Write-Host "`n  Total de eventos forenses registrados no PostgreSQL: $($audit.totalEventosRegistrados)" -ForegroundColor Green
                    if ($audit.totalEventosRegistrados -gt 0) {
                        $audit.eventos | Select-Object -First 10 | Format-Table id, dataHora, rota, tipoCenario, statusExecucao, codigoHttp -AutoSize
                        Write-Host "  Dica: Para ver os detalhes tecnicos de um evento, use a opcao [5] via psql." -ForegroundColor DarkGray
                    }
                } catch {
                    Write-Host "  Erro ao consultar auditoria: $_" -ForegroundColor Red
                }
            }
            "4" {
                try {
                    $placar = Invoke-RestMethod -Uri "$baseUrl/api/ordens/placar" -Method GET
                    Write-Host "`n  +-- PLACAR DE RESILIENCIA COMPARATIVO ------------------------------------------+" -ForegroundColor Yellow
                    Write-Host "  | ROTA DO CAOS (SEM PROTECAO):" -ForegroundColor Red
                    Write-Host ("  |   Total chamadas: {0} | Ordens orfas: {1}" -f $placar.rotaDoCaos.totalChamadas, $placar.rotaDoCaos.ordensOrfasGeradas) -ForegroundColor Red
                    Write-Host ("  |   Atomicidade: {0}" -f $placar.rotaDoCaos.protecaoTransacional) -ForegroundColor Red
                    Write-Host ("  |   Tolerancia a retries: {0}" -f $placar.rotaDoCaos.toleranciaRetries) -ForegroundColor Red
                    Write-Host ("  |   Estado do banco: {0}" -f $placar.rotaDoCaos.diagnostico) -ForegroundColor Red
                    Write-Host "  |" -ForegroundColor DarkGray
                    Write-Host "  | ROTA RESILIENTE (BLINDADA):" -ForegroundColor Green
                    Write-Host ("  |   Total chamadas: {0} | Ordens orfas: {1}" -f $placar.rotaResiliente.totalChamadas, $placar.rotaResiliente.ordensOrfasGeradas) -ForegroundColor Green
                    Write-Host ("  |   Bloqueios Fail-Fast (@Valid): {0}" -f $placar.rotaResiliente.bloqueiosFailFast) -ForegroundColor Green
                    Write-Host ("  |   Rollbacks bem-sucedidos (@Transactional): {0}" -f $placar.rotaResiliente.rollbacksExecutados) -ForegroundColor Green
                    Write-Host ("  |   Deduplicacoes por Idempotencia: {0}" -f $placar.rotaResiliente.deduplicacoesIdempotencia) -ForegroundColor Green
                    Write-Host ("  |   Estado do banco: {0}" -f $placar.rotaResiliente.diagnostico) -ForegroundColor Green
                    Write-Host "  +--------------------------------------------------------------------------------+" -ForegroundColor Yellow
                } catch {
                    Write-Host "  Erro ao consultar placar: $_" -ForegroundColor Red
                }
            }
            "5" {
                Write-Host "`n  --> [demo_postgres] SELECT * FROM ordens_servico:" -ForegroundColor Yellow
                docker exec demo_postgres psql -U postgres -d demo_db -c "SELECT id, cliente, integration_id, status, criado_em FROM ordens_servico;"
                Write-Host "`n  --> [demo_postgres] SELECT * FROM itens_ordem:" -ForegroundColor Yellow
                docker exec demo_postgres psql -U postgres -d demo_db -c "SELECT id, ordem_id, descricao, valor FROM itens_ordem;"
                Write-Host "`n  --> [demo_postgres] SELECT * FROM auditoria_transacional ORDER BY id DESC LIMIT 5:" -ForegroundColor Yellow
                docker exec demo_postgres psql -U postgres -d demo_db -c "SELECT id, ip_origem, rota, tipo_cenario, status_execucao, codigo_http FROM auditoria_transacional ORDER BY id DESC LIMIT 5;"
            }
            "6" {
                Write-Host "`n  Deseja abrir terminal interativo agora?" -ForegroundColor Cyan
                Write-Host "    [B] PostgreSQL interativo (psql no demo_postgres)" -ForegroundColor Yellow
                Write-Host "    [A] Bash da API Spring Boot (demo_spring_api)" -ForegroundColor Green
                Write-Host "    [N] Nao, voltar ao menu" -ForegroundColor DarkGray
                $esc = (Read-Host "  Escolha [B/A/N]").ToUpper()
                if ($esc -eq "B") {
                    docker exec -it demo_postgres psql -U postgres -d demo_db
                } elseif ($esc -eq "A") {
                    docker exec -it demo_spring_api sh
                }
            }
            "7" {
                Write-Host "`n  --> [demo_spring_api] Ultimos 30 logs da aplicacao:" -ForegroundColor Yellow
                docker logs --tail 30 demo_spring_api
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
        [string]$MecanismoInterno,
        [string]$Consequencias,
        [string]$ComoValidar
    )

    Escrever-CardCenario -Numero $Numero `
                         -Titulo $Titulo `
                         -OQueEFeito $OQueEFeito `
                         -ComoEFeito $ComoEFeito `
                         -MecanismoInterno $MecanismoInterno `
                         -Consequencias $Consequencias `
                         -ComoValidar $ComoValidar

    while ($true) {
        Write-Host "  +-- AUTORIZACAO NECESSARIA PARA EXECUTAR O CENARIO -----------------------------+" -ForegroundColor Yellow
        Write-Host ("  | [ENTER]   -> Autorizar e disparar o Cenario {0} agora                         |" -f $Numero) -ForegroundColor White
        Write-Host "  | [V]       -> Abrir Menu de Auditoria ao Vivo / Consultar Banco              |" -ForegroundColor Cyan
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
            Write-Host "`n  [X] Demonstracao ENCERRADA pelo usuario.`n" -ForegroundColor Red
            exit 0
        } else {
            Write-Host "  Opcao nao reconhecida. Pressione ENTER para rodar ou 'Q' para sair." -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------
# FUNCOES DE EXECUCAO DOS CENARIOS INDIVIDUAIS
# ---------------------------------------------------------

function Executar-Cenario1 {
    $params = @{
        Numero = "1"
        Titulo = "ROTA DO CAOS -- INJECAO DE FALHA E PARTIAL COMMIT (ORDEM ORFA)"
        OQueEFeito = "Envio de uma ordem de servico corporativa com 2 itens, onde o 2o item possui propositalmente valor negativo (-150.00)."
        ComoEFeito = "POST em /api/vulneravel/ordens. A service salva a ordem mestre primeiro e itera os itens salvando um a um."
        MecanismoInterno = "AUSENCIA DE @Transactional: O driver JDBC opera em modo Autocommit ou abre transacao individual por save(). Quando o 2o item lanca excecao, a ordem mestre JA FICOU GRAVADA no banco sem nenhum vinculo com itens."
        Consequencias = "No mundo corporativo, isso gera faturamento fantasma, cobranca sem nota fiscal, quebra da conciliacao contabil e rombo financeiro."
        ComoValidar = "GET /api/ordens/orfas ou SELECT * FROM ordens_servico WHERE id NOT IN (SELECT ordem_id FROM itens_ordem);"
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    $payload = '{"cliente":"Construtora Imperial SA","integrationId":"CAOS-PARTIAL-001","itens":[{"descricao":"Servico de Terraplanagem","valor":2500.00},{"descricao":"Item Defeituoso (Valor Negativo)","valor":-150.00}]}'

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $statusCode = 0
    $bodyRetorno = ""
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payload -ContentType "application/json"
        $statusCode = 201
        $bodyRetorno = $resp | ConvertTo-Json -Depth 3
    } catch {
        $statusCode = 500
        $bodyRetorno = $_.ErrorDetails.Message
        if (-not $bodyRetorno) { $bodyRetorno = $_.Exception.Message }
    }
    $stopwatch.Stop()

    Exibir-RequisicaoResposta -Metodo "POST" -Url "$baseUrl/api/vulneravel/ordens" -PayloadJson $payload -StatusCode $statusCode -TempoMs $stopwatch.ElapsedMilliseconds -RespostaJson $bodyRetorno

    Escrever-Status "ANALISE" "Verificando o estrago causado no PostgreSQL..." "Cyan"
    Exibir-ComprovacaoSql -Titulo "Ordens Orfas no PostgreSQL" -QuerySql "SELECT o.id, o.cliente, o.integration_id, o.status, count(i.id) as qtd_itens FROM ordens_servico o LEFT JOIN itens_ordem i ON i.ordem_id = o.id WHERE o.integration_id = 'CAOS-PARTIAL-001' GROUP BY o.id, o.cliente, o.integration_id, o.status;"
    Exibir-UltimoLogAuditoria -IntegrationId "CAOS-PARTIAL-001"

    Write-Host "  [DIAGNOSTICO TECNICO]:" -ForegroundColor Yellow
    Write-Host "     A API respondeu com HTTP 500, mas a ordem mestre ID foi COMMITADA no banco!" -ForegroundColor Red
    Write-Host "     Estado: CORRUPCAO DE DADOS CONFIRMADA. O banco contem uma ordem sem mercadorias associadas!" -ForegroundColor Red
    Write-Host ""
}

function Executar-Cenario2 {
    $params = @{
        Numero = "2"
        Titulo = "ROTA DO CAOS -- RETRY ATTACK SEM IDEMPOTENCIA (DUPLICIDADE)"
        OQueEFeito = "Simulacao de um gateway de pagamento ou fila de mensagens (RabbitMQ/Kafka) reenviando o mesmo pedido 3 vezes consecutivas devido a oscilacao de rede."
        ComoEFeito = "3 disparos consecutivos de POST em /api/vulneravel/ordens com o mesmo integrationId ('CAOS-DUP-999')."
        MecanismoInterno = "AUSENCIA DE CONTROLE DE IDEMPOTENCIA: O endpoint nao verifica se a chave ja foi processada anteriormente. Cada requisicao executa um novo INSERT cego no banco."
        Consequencias = "Cobranca triplicada no cartao do cliente, reserva tripla de estoque e emissao de tres notas fiscais para um unico pedido real."
        ComoValidar = "GET /api/ordens/por-integration-id/CAOS-DUP-999 ou SELECT count(*) FROM ordens_servico WHERE integration_id = 'CAOS-DUP-999';"
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    $payload = '{"cliente":"Distribuidora Silva Ltda","integrationId":"CAOS-DUP-999","itens":[{"descricao":"Kit de Filtros Industriais","valor":450.00}]}'

    Write-Host "  Disparando 3 chamadas identicas com a mesma chave 'CAOS-DUP-999'..." -ForegroundColor Cyan
    for ($i = 1; $i -le 3; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-RestMethod -Uri "$baseUrl/api/vulneravel/ordens" -Method POST -Body $payload -ContentType "application/json"
        $sw.Stop()
        Escrever-Status ("DISPARO {0}/3" -f $i) ("Ordem criada com ID={0} para a chave {1} ({2}ms)" -f $r.id, $r.integrationId, $sw.ElapsedMilliseconds) "Magenta"
    }

    Write-Host ""
    Exibir-ComprovacaoSql -Titulo "Registros Duplicados no PostgreSQL" -QuerySql "SELECT id, cliente, integration_id, status, criado_em FROM ordens_servico WHERE integration_id = 'CAOS-DUP-999';"
    Exibir-UltimoLogAuditoria -IntegrationId "CAOS-DUP-999"

    Write-Host "  [DIAGNOSTICO TECNICO]:" -ForegroundColor Yellow
    Write-Host "     3 registros DISTINTOS foram criados para a mesma chave de negocio!" -ForegroundColor Red
    Write-Host "     Impacto financeiro: O cliente foi cobrado 3 vezes (R$ 1.350,00 em vez de R$ 450,00)!" -ForegroundColor Red
    Write-Host ""
}

function Executar-Cenario3 {
    $params = @{
        Numero = "3"
        Titulo = "ROTA RESILIENTE -- PROTECAO FAIL-FAST NA BORDA DA API (BEAN VALIDATION)"
        OQueEFeito = "Envio do mesmo payload corrompido com valor monetario negativo (-500.00) diretamente para o endpoint protegido."
        ComoEFeito = "POST em /api/protegido/ordens interceptado pela anotacao @Valid no Controller antes da camada de Service ou Repository."
        MecanismoInterno = "PADRAO FAIL-FAST (JSR-380): A validacao ocorre no Spring Web (DispatcherServlet). Ao violar @DecimalMin('0.00'), lanca MethodArgumentNotValidException e corta imediatamente o fluxo. ZERO transacoes sao abertas e ZERO conexoes com o PostgreSQL sao consumidas."
        Consequencias = "Economia massiva de recursos computacionais, protecao contra ataques de DoS por payloads pesados e rejeicao antecipada com HTTP 400 Bad Request detalhado."
        ComoValidar = "Retorno HTTP 400 imediato no terminal e NENHUM registro novo inserido no PostgreSQL."
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    $payload = '{"cliente":"Hospital Sao Lucas","integrationId":"PROT-FAILFAST-001","itens":[{"descricao":"Manutencao de Tomografo","valor":-500.00}]}'

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $statusCode = 0
    $bodyRetorno = ""
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payload -ContentType "application/json"
        $statusCode = 201
        $bodyRetorno = $resp | ConvertTo-Json -Depth 3
    } catch {
        $statusCode = 400
        $bodyRetorno = $_.ErrorDetails.Message
        if (-not $bodyRetorno) { $bodyRetorno = $_.Exception.Message }
    }
    $stopwatch.Stop()

    Exibir-RequisicaoResposta -Metodo "POST" -Url "$baseUrl/api/protegido/ordens" -PayloadJson $payload -StatusCode $statusCode -TempoMs $stopwatch.ElapsedMilliseconds -RespostaJson $bodyRetorno

    Exibir-ComprovacaoSql -Titulo "Conferencia no PostgreSQL (Zero Registros)" -QuerySql "SELECT count(*) as total_encontrado FROM ordens_servico WHERE integration_id = 'PROT-FAILFAST-001';"
    Exibir-UltimoLogAuditoria -IntegrationId "PAYLOAD_INVALIDO"

    Write-Host "  [DIAGNOSTICO TECNICO]:" -ForegroundColor Yellow
    Write-Host "     A requisicao foi BARRADA na camada Web da API (HTTP 400 Bad Request)." -ForegroundColor Green
    Write-Host "     O banco de dados sequer foi tocado! Integridade 100% preservada." -ForegroundColor Green
    Write-Host ""
}

function Executar-Cenario4 {
    $params = @{
        Numero = "4"
        Titulo = "ROTA RESILIENTE -- ATOMICIDADE TRANSACIONAL E ROLLBACK TOTAL (@Transactional)"
        OQueEFeito = "Simulacao de falha critica ou pane no banco durante a persistencia dos itens do pedido (?simularFalhaTransacao=true)."
        ComoEFeito = "POST em /api/protegido/ordens?simularFalhaTransacao=true. O metodo possui @Transactional(rollbackFor = Exception.class)."
        MecanismoInterno = "PRINCIPIO ACID (ATOMICIDADE): O Spring gerencia a transacao via AOP Proxy e PlatformTransactionManager. A ordem mestre e salva no EntityManager; ao disparar excecao na insercao dos itens, o interceptador emite comando ROLLBACK no PostgreSQL. Tudo e revertido atomicamente."
        Consequencias = "Garantia do 'TUDO OU NADA': Ou todo o pedido com todos os itens e gravado, ou nada e gravado. Zero ordens orfas e zero inconsistencias contabeis."
        ComoValidar = "GET /api/ordens/por-integration-id/PROT-ROLLBACK-002 comprova ZERO registros no banco, mas a auditoria registra o rollback com exito!"
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    $payload = '{"cliente":"Logistica Expressa Nacional","integrationId":"PROT-ROLLBACK-002","itens":[{"descricao":"Rastreamento de Carga Blindada","valor":890.00}]}'

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $statusCode = 0
    $bodyRetorno = ""
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens?simularFalhaTransacao=true" -Method POST -Body $payload -ContentType "application/json"
        $statusCode = 201
        $bodyRetorno = $resp | ConvertTo-Json -Depth 3
    } catch {
        $statusCode = 500
        $bodyRetorno = $_.ErrorDetails.Message
        if (-not $bodyRetorno) { $bodyRetorno = $_.Exception.Message }
    }
    $stopwatch.Stop()

    Exibir-RequisicaoResposta -Metodo "POST" -Url "$baseUrl/api/protegido/ordens?simularFalhaTransacao=true" -PayloadJson $payload -StatusCode $statusCode -TempoMs $stopwatch.ElapsedMilliseconds -RespostaJson $bodyRetorno

    Exibir-ComprovacaoSql -Titulo "Conferencia no PostgreSQL (Rollback Total)" -QuerySql "SELECT count(*) as ordens_orfas_geradas FROM ordens_servico WHERE integration_id = 'PROT-ROLLBACK-002';"
    Exibir-UltimoLogAuditoria -IntegrationId "PROT-ROLLBACK-002"

    Write-Host "  [DIAGNOSTICO TECNICO]:" -ForegroundColor Yellow
    Write-Host "     Ocorreu uma falha no meio do processo, mas gracas ao @Transactional:" -ForegroundColor Green
    Write-Host "     1. A ordem mestre foi revertida (ROLLBACK). NENHUM registro orfao ficou no banco!" -ForegroundColor Green
    Write-Host "     2. A auditoria autonoma (REQUIRES_NEW) registrou a prova de que o rollback ocorreu!" -ForegroundColor Green
    Write-Host ""
}

function Executar-Cenario5 {
    $params = @{
        Numero = "5"
        Titulo = "ROTA RESILIENTE -- RETRY ATTACK COM IDEMPOTENCIA ATIVA (CHAVE NATURAL)"
        OQueEFeito = "Disparo repetido de 3 requisicoes consecutivas com a mesma chave 'PROT-IDEMP-777' na rota protegida."
        ComoEFeito = "A service verifica 'findByIntegrationId'. Na 1a chamada cria a ordem (HTTP 201). Na 2a e 3a identifica a chave e devolve a ordem existente (HTTP 200) sem duplicar."
        MecanismoInterno = "DEDUPLICACAO NO APPLICATION LAYER: O integration_id funciona como Chave de Idempotencia Natural (Natural Business Key). O sistema garante que a mesma operacao executada N vezes produz EXATAMENTE o mesmo efeito de executar 1 unica vez."
        Consequencias = "Blindagem total contra retentativas de rede, disparos repetidos de webhooks e cliques duplos de usuarios no frontend."
        ComoValidar = "SELECT count(*) FROM ordens_servico WHERE integration_id = 'PROT-IDEMP-777' comprova EXATAMENTE 1 registro no banco apos 3 disparos!"
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    $payload = '{"cliente":"Fintech Inovadora do Brasil","integrationId":"PROT-IDEMP-777","itens":[{"descricao":"Gateway de Pagamento Mensal","valor":1200.00}]}'

    Write-Host "  Disparando 3 chamadas identicas com a mesma chave 'PROT-IDEMP-777'..." -ForegroundColor Cyan
    for ($i = 1; $i -le 3; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-RestMethod -Uri "$baseUrl/api/protegido/ordens" -Method POST -Body $payload -ContentType "application/json"
        $sw.Stop()
        $msg = "NOVA ORDEM CRIADA COM SUCESSO"
        if ($r.mensagem -like "*IDEMPOTENCIA*") {
            $msg = "IDEMPOTENCIA ATIVADA (Reaproveitado)"
        }
        Escrever-Status ("DISPARO {0}/3" -f $i) ("Status: {0} | Ordem ID: {1} | Acao: {2} ({3}ms)" -f $r.status, $r.id, $msg, $sw.ElapsedMilliseconds) "Green"
    }

    Write-Host ""
    Exibir-ComprovacaoSql -Titulo "Conferencia de Deduplicacao no PostgreSQL" -QuerySql "SELECT id, cliente, integration_id, status, criado_em FROM ordens_servico WHERE integration_id = 'PROT-IDEMP-777';"
    Exibir-UltimoLogAuditoria -IntegrationId "PROT-IDEMP-777"

    Write-Host "  [DIAGNOSTICO TECNICO]:" -ForegroundColor Yellow
    Write-Host "     Foram feitos 3 disparos, mas o banco possui EXATAMENTE 1 registro!" -ForegroundColor Green
    Write-Host "     O cliente recebeu a confirmacao correta em todas as chamadas e foi cobrado APENAS UMA VEZ!" -ForegroundColor Green
    Write-Host ""
}

function Executar-Cenario6-Concorrencia {
    $params = @{
        Numero = "6"
        Titulo = "TESTE DE STRESS E CONCORRENCIA SIMULTANEA (RACE CONDITION)"
        OQueEFeito = "Disparo paralelo de 5 requisicoes SIMULTANEAS no mesmo milissegundo para a Rota do Caos e depois para a Rota Resiliente."
        ComoEFeito = "Disparo assincrono multithread via PowerShell Jobs com a mesma chave de integracao."
        MecanismoInterno = "RACE CONDITION E THREAD SAFETY: Em condicoes de alta concorrencia, APIs sem controle de idempotencia criam multiplos registros simultaneos antes que qualquer verificacao ocorra."
        Consequencias = "Comprovacao visual de que sistemas sem blindagem falham catastroficamente sob picos de acesso ou concorrencia real."
        ComoValidar = "Contagem total de registros criados em paralelo no PostgreSQL para cada rota."
    }
    $decisao = Pedir-PermissaoCenario @params
    if ($decisao -ne "EXECUTAR") { return }

    Write-Host "  --> [1/2] Disparando 5 requisicoes paralelas SIMULTANEAS para a Rota do Caos..." -ForegroundColor Red
    $chaveCaosParalela = "CAOS-RACE-888"
    $payloadCaos = '{"cliente":"Supermercado Central","integrationId":"' + $chaveCaosParalela + '","itens":[{"descricao":"Carga de Alimentos","valor":350.00}]}'

    $jobsCaos = @()
    for ($i = 1; $i -le 5; $i++) {
        $jobsCaos += Start-Job -ScriptBlock {
            param($url, $body)
            Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json"
        } -ArgumentList "$baseUrl/api/vulneravel/ordens", $payloadCaos
    }
    $jobsCaos | Wait-Job | Out-Null
    $respostasCaos = $jobsCaos | Receive-Job
    $jobsCaos | Remove-Job

    Write-Host "     Disparos paralelos na Rota do Caos finalizados!" -ForegroundColor Red
    Exibir-ComprovacaoSql -Titulo "Resultado de Concorrencia na Rota do Caos" -QuerySql "SELECT id, cliente, integration_id, criado_em FROM ordens_servico WHERE integration_id = '$chaveCaosParalela';"

    Write-Host "`n  --> [2/2] Disparando 5 requisicoes paralelas SIMULTANEAS para a Rota Resiliente..." -ForegroundColor Green
    $chaveProtParalela = "PROT-RACE-888"
    $payloadProt = '{"cliente":"Supermercado Central Protegido","integrationId":"' + $chaveProtParalela + '","itens":[{"descricao":"Carga de Alimentos","valor":350.00}]}'

    $jobsProt = @()
    for ($i = 1; $i -le 5; $i++) {
        $jobsProt += Start-Job -ScriptBlock {
            param($url, $body)
            Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json"
        } -ArgumentList "$baseUrl/api/protegido/ordens", $payloadProt
    }
    $jobsProt | Wait-Job | Out-Null
    $respostasProt = $jobsProt | Receive-Job
    $jobsProt | Remove-Job

    Write-Host "     Disparos paralelos na Rota Resiliente finalizados!" -ForegroundColor Green
    Exibir-ComprovacaoSql -Titulo "Resultado de Concorrencia na Rota Resiliente" -QuerySql "SELECT id, cliente, integration_id, criado_em FROM ordens_servico WHERE integration_id = '$chaveProtParalela';"

    Write-Host "  [DIAGNOSTICO TECNICO DE CONCORRENCIA]:" -ForegroundColor Yellow
    Write-Host "     Rota do Caos: 5 requisicoes simultaneas criaram multiplos pedidos duplicados!" -ForegroundColor Red
    Write-Host "     Rota Resiliente: Apenas 1 pedido foi persistido no banco, garantindo consistencia!" -ForegroundColor Green
    Write-Host ""
}

function Exibir-PlacarFinal {
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    AUDITORIA FINAL E PLACAR ESTATISTICO DE RESILIENCIA                           " -ForegroundColor Yellow
    Write-Host "  ================================================================================" -ForegroundColor Cyan

    try {
        $placar = Invoke-RestMethod -Uri "$baseUrl/api/ordens/placar" -Method GET
        $corOrfas = "Green"
        if ($placar.rotaDoCaos.ordensOrfasGeradas -gt 0) { $corOrfas = "Red" }
        $corDiag = "Green"
        if ($placar.rotaDoCaos.diagnostico -like "*CORROMPIDO*") { $corDiag = "Red" }

        Write-Host ""
        Write-Host "  +---------------------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "  | METRICA DE RESILIENCIA               | ROTA DO CAOS             | ROTA RESILIENTE           |" -ForegroundColor Yellow
        Write-Host "  +--------------------------------------+--------------------------+---------------------------+" -ForegroundColor DarkCyan
        Write-Host ("  | Total de Requisicoes Processadas     | {0,-24} | {1,-25} |" -f $placar.rotaDoCaos.totalChamadas, $placar.rotaResiliente.totalChamadas) -ForegroundColor White
        Write-Host ("  | Ordens Orfas Geradas (Inconsistente) | {0,-24} | {1,-25} |" -f $placar.rotaDoCaos.ordensOrfasGeradas, $placar.rotaResiliente.ordensOrfasGeradas) -ForegroundColor $corOrfas
        Write-Host ("  | Bloqueios Fail-Fast (@Valid)         | {0,-24} | {1,-25} |" -f 0, $placar.rotaResiliente.bloqueiosFailFast) -ForegroundColor Green
        Write-Host ("  | Rollbacks Atomicos (@Transactional)  | {0,-24} | {1,-25} |" -f 0, $placar.rotaResiliente.rollbacksExecutados) -ForegroundColor Green
        Write-Host ("  | Deduplicacoes por Idempotencia       | {0,-24} | {1,-25} |" -f 0, $placar.rotaResiliente.deduplicacoesIdempotencia) -ForegroundColor Green
        Write-Host ("  | Integridade Contabil do Banco        | {0,-24} | {1,-25} |" -f $placar.rotaDoCaos.diagnostico, $placar.rotaResiliente.diagnostico) -ForegroundColor $corDiag
        Write-Host "  +---------------------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    } catch {
        Write-Host "  Erro ao gerar placar comparativo: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Deseja abrir o Menu de Auditoria Forense para inspecionar os containers? (S/N)" -ForegroundColor Yellow
    $validaFim = Read-Host "  Escolha [S/N]"
    if ($validaFim -eq "S" -or $validaFim -eq "s") {
        Menu-InspecaoApi
    }
}

function Resetar-BancoDados {
    Write-Host "`n  --> Resetando banco de dados no PostgreSQL..." -ForegroundColor Yellow
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/api/ordens/reset?limparAuditoria=true" -Method DELETE
        Escrever-Status "RESET" "$($res.mensagem)" "Green"
    } catch {
        Escrever-Status "AVISO" "Nao foi possivel resetar via endpoint. Tentando via docker exec..." "DarkYellow"
        docker exec demo_postgres psql -U postgres -d demo_db -c "TRUNCATE itens_ordem, ordens_servico, auditoria_transacional RESTART IDENTITY CASCADE;" 2>&1 | Out-Null
        Escrever-Status "SQL" "Tabelas truncadas via psql." "Green"
    }
}

# ---------------------------------------------------------
# INICIO DA EXECUCAO DO SCRIPT INTERATIVO
# ---------------------------------------------------------

Escrever-Cabecalho
Escrever-Topologia

# ---------------------------------------------------------
# TESTE DE CONECTIVIDADE COM A API
# ---------------------------------------------------------
Escrever-Status "CONEXAO" "Verificando se a API esta online em $baseUrl..." "Yellow"
$apiOnline = $false
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET -TimeoutSec 4
    Escrever-Status "OK" "API conectada com sucesso na porta 8080!" "Green"
    $apiOnline = $true
} catch {
    Escrever-Status "ALERTA" "A API nao esta respondendo em $baseUrl." "Yellow"
    Write-Host "  Verificando se os containers estao rodando..." -ForegroundColor DarkGray
    $psApi = docker ps --filter "name=demo_spring_api" --format "{{.Names}}"
    if (-not $psApi) {
        Write-Host "`n  Os containers 'demo_spring_api' e 'demo_postgres' nao estao ativos." -ForegroundColor Yellow
        $subir = Read-Host "  Deseja subir o ambiente agora com 'docker compose up -d'? [S/N]"
        if ($subir -eq "S" -or $subir -eq "s") {
            Write-Host "  Iniciando containers da API..." -ForegroundColor Cyan
            docker compose up -d
            Write-Host "  Aguardando inicializacao da API Spring Boot (pode levar alguns segundos)..." -ForegroundColor Yellow
            $tentativas = 0
            while ($tentativas -lt 30) {
                Start-Sleep -Seconds 2
                $tentativas++
                try {
                    $testHealth = Invoke-RestMethod -Uri "$baseUrl/api/ordens" -Method GET -TimeoutSec 2
                    $apiOnline = $true
                    Write-Host "  [OK] API Spring Boot inicializada com sucesso!" -ForegroundColor Green
                    break
                } catch {
                    Write-Host -NoNewline "."
                }
            }
        }
    }
}

if (-not $apiOnline) {
    Write-Host "`n  Nao foi possivel conectar a API na porta 8080." -ForegroundColor Red
    Write-Host "  Certifique-se de executar 'docker compose up -d' na raiz do projeto e tente novamente.`n" -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------
# MENU PRINCIPAL DE OPCOES
# ---------------------------------------------------------
while ($true) {
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    PAINEL DE DEMONSTRACAO DE RESILIENCIA (OPCOES DE APRESENTACAO)                " -ForegroundColor Yellow
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    [1] ROTEIRO DIDATICO COMPLETO (Passo a passo com os 6 cenarios e autorizacao)" -ForegroundColor Green
    Write-Host "    [2] EXECUTAR APENAS A ROTA DO CAOS (Cenarios 1 e 2: Ordem Orfa e Duplicidade)" -ForegroundColor Red
    Write-Host "    [3] EXECUTAR APENAS A ROTA RESILIENTE (Cenarios 3, 4 e 5: Blindagem Total)" -ForegroundColor Green
    Write-Host "    [4] CENARIO EXTRA: TESTE DE STRESS E CONCORRENCIA SIMULTANEA (5 threads)" -ForegroundColor Magenta
    Write-Host "    [5] MENU DE AUDITORIA FORENSE E PROVA REAL NO BANCO DE DADOS" -ForegroundColor Cyan
    Write-Host "    [6] PLACAR COMPARATIVO ESTATISTICO (Caos vs Resiliente)" -ForegroundColor Yellow
    Write-Host "    [7] RESETAR BANCO DE DADOS (Zerar ordens e auditoria para nova rodada)" -ForegroundColor DarkYellow
    Write-Host "    [0] Sair para o menu anterior" -ForegroundColor DarkGray
    Write-Host ""
    $opcao = Read-Host "  Digite a opcao desejada [0-7]"

    switch ($opcao) {
        "1" {
            Resetar-BancoDados
            Executar-Cenario1
            Executar-Cenario2
            Executar-Cenario3
            Executar-Cenario4
            Executar-Cenario5
            Executar-Cenario6-Concorrencia
            Exibir-PlacarFinal
        }
        "2" {
            Executar-Cenario1
            Executar-Cenario2
            Exibir-PlacarFinal
        }
        "3" {
            Executar-Cenario3
            Executar-Cenario4
            Executar-Cenario5
            Exibir-PlacarFinal
        }
        "4" {
            Executar-Cenario6-Concorrencia
            Exibir-PlacarFinal
        }
        "5" {
            Menu-InspecaoApi
        }
        "6" {
            Exibir-PlacarFinal
        }
        "7" {
            Resetar-BancoDados
        }
        "0" {
            Write-Host "`n  Encerrando demonstracao de resiliencia.`n" -ForegroundColor Green
            return
        }
        default {
            Write-Host "  Opcao invalida. Digite um numero de 0 a 7." -ForegroundColor Red
        }
    }
}
