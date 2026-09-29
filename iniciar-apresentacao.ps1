# =====================================================================
# iniciar-apresentacao.ps1 -- Painel Central de Apresentacao Tecnica
# Projeto: Demonstracao de Seguranca e Resiliencia (Ataque e Defesa)
# =====================================================================

$ErrorActionPreference = "Continue"

function Exibir-MenuPrincipal {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    PROJETO DEMONSTRATIVO DE SEGURANCA E RESILIENCIA (ATAQUE E DEFESA)            " -ForegroundColor Yellow
    Write-Host "    Painel Central de Execucao, Validacao e Auditoria em Tempo Real               " -ForegroundColor Cyan
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Selecione a frente que deseja apresentar:" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] DEMONSTRACAO DE ATAQUE -- Pickle Deserialization (OWASP A08:2021)" -ForegroundColor Red
    Write-Host "        - 3 containers: servidor_bd, maquina_vitima, maquina_atacante" -ForegroundColor DarkGray
    Write-Host "        - Injecao via __reduce__, exfiltracao de dados e destruicao DROP TABLE" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [2] DEMONSTRACAO DE DEFESA -- Resiliencia e Idempotencia em APIs" -ForegroundColor Green
    Write-Host "        - 2 containers: demo_spring_api, demo_postgres" -ForegroundColor DarkGray
    Write-Host "        - Rota do Caos (Ordem Orfa, Duplicidade) vs Rota Resiliente (Rollback, Idemp)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [3] GUIA DE VALIDACAO E ACESSO AS MAQUINAS EM TEMPO REAL" -ForegroundColor Cyan
    Write-Host "        - Instrucoes e comandos prontos para entrar em cada container Docker" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [4] LIMPEZA TOTAL DE CONTAINERS E VOLUMES" -ForegroundColor Yellow
    Write-Host "        - Derruba os ambientes de ambas as frentes e limpa volumes" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [0] Sair" -ForegroundColor DarkGray
    Write-Host ""
}

while ($true) {
    Exibir-MenuPrincipal
    $escolha = Read-Host "  Digite a opcao desejada [0-4]"

    switch ($escolha) {
        "1" {
            Write-Host "`n  --> Iniciando Demonstracao de Ataque..." -ForegroundColor Yellow
            Set-Location "$PSScriptRoot\attack-demo"
            & ".\executar-ataque.ps1"
            Set-Location "$PSScriptRoot"
            Read-Host "`n  Pressione ENTER para voltar ao menu principal..."
        }
        "2" {
            Write-Host "`n  --> Iniciando Demonstracao de Resiliencia..." -ForegroundColor Yellow
            & "$PSScriptRoot\executar-demo.ps1"
            Read-Host "`n  Pressione ENTER para voltar ao menu principal..."
        }
        "3" {
            Clear-Host
            Write-Host ""
            Write-Host "  ================================================================================" -ForegroundColor Cyan
            Write-Host "    COMANDOS PARA ENTRAR NAS MAQUINAS E COMPROVAR EM TEMPO REAL                   " -ForegroundColor Yellow
            Write-Host "  ================================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  1. MAQUINA DA VITIMA (container: maquina_vitima):" -ForegroundColor Green
            Write-Host "     docker exec -it maquina_vitima bash" -ForegroundColor White
            Write-Host "     ls -la /app/shared/session.pkl" -ForegroundColor DarkGray
            Write-Host '     python -c "import pickle; print(pickle.load(open(''/app/shared/session.pkl'', ''rb'')))"' -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  2. MAQUINA DO ATACANTE (container: maquina_atacante):" -ForegroundColor Red
            Write-Host "     docker exec -it maquina_atacante bash" -ForegroundColor White
            Write-Host "     cat /app/exploit.py" -ForegroundColor DarkGray
            Write-Host "     cat /app/comandos/__init__.py" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  3. SERVIDOR DO BANCO DE DADOS (container: servidor_bd):" -ForegroundColor Yellow
            Write-Host "     docker exec -it servidor_bd psql -U postgres -d demo_db" -ForegroundColor White
            Write-Host "     \dt                                 # Listar tabelas publicas" -ForegroundColor DarkGray
            Write-Host "     SELECT * FROM usuarios;             # Listar usuarios com salarios" -ForegroundColor DarkGray
            Write-Host "     SELECT * FROM config_sistema;       # Listar secrets e JWT_SECRET" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  4. AMBIENTE DA API RESILIENTE (demo_spring_api e demo_postgres):" -ForegroundColor Magenta
            Write-Host "     docker logs -f demo_spring_api      # Ver logs do Spring Boot em tempo real" -ForegroundColor DarkGray
            Write-Host '     docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT * FROM ordens_servico;"' -ForegroundColor DarkGray
            Write-Host '     docker exec -it demo_postgres psql -U postgres -d demo_db -c "SELECT id, ip_origem, rota, tipo_cenario, status_execucao, codigo_http FROM auditoria_transacional ORDER BY id DESC LIMIT 10;"' -ForegroundColor DarkGray
            Write-Host ""
            Read-Host "  Pressione ENTER para voltar ao menu..."
        }
        "4" {
            Write-Host "`n  --> Derrubando containers de ambas as frentes..." -ForegroundColor Yellow
            docker compose down -v 2>&1 | Out-Null
            if (Test-Path "$PSScriptRoot\attack-demo\docker-compose.yml") {
                Push-Location "$PSScriptRoot\attack-demo"
                docker compose down -v 2>&1 | Out-Null
                Pop-Location
            }
            Write-Host "  [OK] Todos os containers e volumes foram limpos com sucesso!" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        "0" {
            Write-Host "`n  Ate logo!`n" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "  Opcao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
