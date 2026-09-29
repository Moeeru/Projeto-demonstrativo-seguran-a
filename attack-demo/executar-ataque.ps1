# =====================================================================
# executar-ataque.ps1 -- Script Interativo de Demonstracao de Ataque
# Projeto: Pickle Deserialization Attack (OWASP A08:2021)
#
# Demonstracao didatica de Software and Data Integrity Failures
# Arquitetura simulada: 3 Maquinas isoladas em Docker
#   1. servidor_bd      -> PostgreSQL 16 (Banco de Dados Corporativo)
#   2. maquina_vitima   -> Python 3.11 (Executa login e salva sessao)
#   3. maquina_atacante -> Python 3.11 (Infecta a sessao via exploit)
# =====================================================================

$ErrorActionPreference = "Continue"

# ─────────────────────────────────────────────────────────
# FUNCOES DE FORMATACAO VISUAL E LOGS
# ─────────────────────────────────────────────────────────

function Escrever-Cabecalho {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host "    LABORATORIO EDUCATIVO: ATAQUE DE DESSERIALIZACAO INSEGURA (OWASP A08)         " -ForegroundColor Yellow
    Write-Host "    Demonstracao Tecnica com 3 Maquinas Virtuais Isoladas em Docker               " -ForegroundColor Cyan
    Write-Host "  ================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Escrever-Topologia {
    Write-Host "  +-- TOPOLOGIA DO AMBIENTE SIMULADO (REDE DOCKER: rede-ataque) -----------------+" -ForegroundColor DarkCyan
    Write-Host "  |                                                                               |" -ForegroundColor DarkCyan
    Write-Host "  |   [ MAQUINA DA VITIMA ]                        [ MAQUINA DO ATACANTE ]        |" -ForegroundColor White
    Write-Host "  |     container: maquina_vitima                    container: maquina_atacante  |" -ForegroundColor DarkGray
    Write-Host "  |     script: login.py                             script: exploit.py           |" -ForegroundColor DarkGray
    Write-Host "  |              \                                       /                        |" -ForegroundColor DarkCyan
    Write-Host "  |               \       VOLUME COMPARTILHADO          /                         |" -ForegroundColor Yellow
    Write-Host "  |                \---> [ /app/shared/session.pkl ] <-/                          |" -ForegroundColor Yellow
    Write-Host "  |                                  |                                            |" -ForegroundColor DarkCyan
    Write-Host "  |                                  v conexao SQL autenticada                    |" -ForegroundColor DarkCyan
    Write-Host "  |                     [ SERVIDOR DE BANCO DE DADOS ]                            |" -ForegroundColor Green
    Write-Host "  |                       container: servidor_bd (Postgres 16)                    |" -ForegroundColor DarkGreen
    Write-Host "  |                       tabelas: usuarios, clientes, transacoes, config...      |" -ForegroundColor DarkGreen
    Write-Host "  +-------------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Escrever-CardEtapa {
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
    Write-Host ("  ETAPA {0}: {1}" -f $Numero, $Titulo) -ForegroundColor Yellow
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
    Write-Host "  [*] COMO VALIDAR / ENTRAR NA MAQUINA EM TEMPO REAL:" -ForegroundColor Cyan
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
# MENU INTERATIVO DE INSPECAO EM TEMPO REAL
# ─────────────────────────────────────────────────────────

function Menu-InspecaoTempoReal {
    while ($true) {
        Write-Host ""
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    MENU DE AUDITORIA E ENTRADA NAS MAQUINAS (TEMPO REAL)                         " -ForegroundColor Yellow
        Write-Host "  ================================================================================" -ForegroundColor Green
        Write-Host "    [1] SERVIDOR_BD    -> Ver tabelas e registros com 'psql'" -ForegroundColor Cyan
        Write-Host "    [2] MAQUINA_VITIMA -> Inspecionar /app/shared/session.pkl" -ForegroundColor Cyan
        Write-Host "    [3] MAQUINA_ATACANTE -> Inspecionar scripts de exploit e payloads" -ForegroundColor Cyan
        Write-Host "    [4] EXIBIR DUMP BRUTO DO SESSION.PKL (conteudo atual do arquivo)" -ForegroundColor Yellow
        Write-Host "    [5] ABRIR TERMINAL BASH INTERATIVO EM UMA DAS MAQUINAS" -ForegroundColor Magenta
        Write-Host "    [6] VER DADOS ROUBADOS/EXFILTRADOS PELO ATACANTE" -ForegroundColor Red
        Write-Host "    [7] REGISTRO DE ACESSO (rastro forense em tempo real)" -ForegroundColor Yellow
        Write-Host "    [0] VOLTAR PARA O ROTEIRO DA DEMONSTRACAO" -ForegroundColor Green
        Write-Host ""
        $opcao = Read-Host "  Digite a opcao desejada [0-7]"

        switch ($opcao) {
            "1" {
                Write-Host "`n  --> [servidor_bd] Consultando tabelas existentes:" -ForegroundColor Yellow
                docker exec servidor_bd psql -U postgres -d demo_db -c "\dt"
                Write-Host "`n  --> [servidor_bd] Amostra de usuarios:" -ForegroundColor Yellow
                docker exec servidor_bd psql -U postgres -d demo_db -c "SELECT id, nome, email, cargo, salario FROM usuarios LIMIT 3;"
                Write-Host "`n  --> [servidor_bd] Amostra de segredos em config_sistema:" -ForegroundColor Yellow
                docker exec servidor_bd psql -U postgres -d demo_db -c "SELECT chave, valor FROM config_sistema LIMIT 3;"
                Write-Host "`n  --> [servidor_bd] Registro de Acessos (rastro forense):" -ForegroundColor Yellow
                docker exec servidor_bd psql -U postgres -d demo_db -c "SELECT id, endereco_ip, metodo_acesso, status, descricao, data_acesso FROM registro_acesso ORDER BY data_acesso DESC LIMIT 10;"
            }
            "2" {
                Write-Host "`n  --> [maquina_vitima] Listando pasta compartilhada:" -ForegroundColor Yellow
                docker exec maquina_vitima ls -la /app/shared
                Write-Host "`n  --> [maquina_vitima] Processos em execucao:" -ForegroundColor Yellow
                docker exec maquina_vitima ps aux
            }
            "3" {
                Write-Host "`n  --> [maquina_atacante] Arquivos do atacante:" -ForegroundColor Yellow
                docker exec maquina_atacante ls -la /app
                docker exec maquina_atacante ls -la /app/comandos
            }
            "4" {
                Write-Host "`n  --> Inspecionando /app/shared/session.pkl diretamente:" -ForegroundColor Yellow
                docker exec maquina_vitima test -f /app/shared/session.pkl
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Tamanho do arquivo:" -ForegroundColor Cyan
                    docker exec maquina_vitima ls -lh /app/shared/session.pkl
                    Write-Host "`n  Tentativa de leitura de metadados via Python:" -ForegroundColor Cyan
                    docker exec maquina_vitima python -c "
import pickle
try:
    with open('/app/shared/session.pkl', 'rb') as f:
        data = pickle.load(f)
    print('  [TIPO CARREGADO]:', type(data))
    print('  [CONTEUDO]:', data)
except Exception as e:
    print('  [ERRO AO LER]:', e)
"
                } else {
                    Write-Host "  O arquivo /app/shared/session.pkl ainda nao existe (sera criado na Etapa 1)." -ForegroundColor DarkYellow
                }
            }
            "5" {
                Write-Host "`n  Comandos para entrar em cada maquina:" -ForegroundColor Cyan
                Write-Host "    docker exec -it servidor_bd psql -U postgres -d demo_db" -ForegroundColor Green
                Write-Host "    docker exec -it maquina_vitima bash" -ForegroundColor Green
                Write-Host "    docker exec -it maquina_atacante bash" -ForegroundColor Green
                Write-Host "`n  Deseja abrir um bash interativo agora nesta janela? (V=Vitima, A=Atacante, B=Banco, N=Nao)" -ForegroundColor Yellow
                $bashChoice = (Read-Host "  Escolha [V/A/B/N]").ToUpper()
                if ($bashChoice -eq "V") { docker exec -it maquina_vitima bash }
                elseif ($bashChoice -eq "A") { docker exec -it maquina_atacante bash }
                elseif ($bashChoice -eq "B") { docker exec -it servidor_bd psql -U postgres -d demo_db }
            }
            "6" {
                Write-Host ""
                Write-Host "  +-- DADOS ROUBADOS PELO ATACANTE ---------------------------------------------------+" -ForegroundColor Red
                Write-Host ""
                Write-Host "  --> Verificando se existem dados exfiltrados:" -ForegroundColor Yellow
                docker exec maquina_atacante test -d /app/shared/dados_roubados
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "  --> [ATACANTE] Arquivos baixados na pasta de exfiltracao:" -ForegroundColor Red
                    docker exec maquina_atacante ls -lh /app/shared/dados_roubados
                    Write-Host ""
                    Write-Host "  --> [ATACANTE] Credenciais capturadas:" -ForegroundColor Red
                    docker exec maquina_atacante cat /app/shared/dados_roubados/credenciais_vitima.txt 2>$null
                    Write-Host ""
                    Write-Host "  --> [ATACANTE] Preview dos primeiros registros de cada arquivo CSV:" -ForegroundColor Red
                    $csvFiles = docker exec maquina_atacante find /app/shared/dados_roubados -name '*.csv' 2>$null
                    if ($csvFiles) {
                        foreach ($csvFile in ($csvFiles -split "`n")) {
                            $csvFile = $csvFile.Trim()
                            if ($csvFile) {
                                Write-Host "`n  --- $csvFile ---" -ForegroundColor Yellow
                                docker exec maquina_atacante head -10 $csvFile
                            }
                        }
                    }
                    Write-Host ""
                    Write-Host "  COMPROVACAO: Os dados acima estao salvos NA MAQUINA DO ATACANTE!" -ForegroundColor Red
                    Write-Host "  Se o payload de destruicao foi usado, o BD da vitima esta VAZIO," -ForegroundColor Red
                    Write-Host "  mas o atacante MANTEM a copia completa." -ForegroundColor Red
                } else {
                    Write-Host "  Nenhum dado exfiltrado ainda. Execute o ataque primeiro (Etapas 2 e 3)." -ForegroundColor DarkYellow
                }
                Write-Host ""
                Write-Host "  +-------------------------------------------------------------------------------+" -ForegroundColor Red
            }
            "7" {
                Write-Host ""
                Write-Host "  +-- REGISTRO DE ACESSO (TABELA registro_acesso) ----------------------------+" -ForegroundColor Yellow
                Write-Host "  |  Cada etapa da demo deixa rastros reais nesta tabela!                     |" -ForegroundColor White
                Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Yellow
                Write-Host ""
                docker exec servidor_bd psql -U postgres -d demo_db -c "SELECT id, endereco_ip, user_agent, metodo_acesso, status, descricao, data_acesso FROM registro_acesso ORDER BY data_acesso;"
                Write-Host ""
                Write-Host "  Tipos de metodo_acesso que voce pode encontrar:" -ForegroundColor Cyan
                Write-Host "    LOGIN            -> Login legitimo da vitima" -ForegroundColor Green
                Write-Host "    PICKLE_LOAD      -> Carregamento do session.pkl (legitimo ou comprometido)" -ForegroundColor Yellow
                Write-Host "    RECONHECIMENTO   -> Atacante localizou o arquivo .pkl" -ForegroundColor Red
                Write-Host "    INFECCAO_PKL     -> Atacante infectou o session.pkl" -ForegroundColor Red
                Write-Host "    EXPLOIT_CONEXAO  -> Payload conectou no BD com credenciais roubadas" -ForegroundColor Red
                Write-Host "    ROUBO_CREDENCIAIS-> Credenciais capturadas e salvas" -ForegroundColor Red
                Write-Host "    EXFILTRACAO      -> Dados roubados e salvos em CSV" -ForegroundColor Red
                Write-Host "    BACKUP_MALICIOSO -> Atacante fez backup antes de destruir" -ForegroundColor Red
                Write-Host "    DROP_TABLE       -> Destruicao de tabelas em andamento" -ForegroundColor Red
                Write-Host ""
            }
            "0" { return }
            default { Write-Host "Opcao invalida." -ForegroundColor Red }
        }
    }
}

# ─────────────────────────────────────────────────────────
# FUNCAO DE CONTROLE DE PERMISSAO POR ETAPA
# ─────────────────────────────────────────────────────────

function Pedir-PermissaoEtapa {
    param(
        [string]$Numero,
        [string]$Titulo,
        [string]$OQueEFeito,
        [string]$ComoEFeito,
        [string]$Tecnicas,
        [string]$Consequencias,
        [string]$ComoValidar
    )

    Escrever-CardEtapa -Numero $Numero `
                       -Titulo $Titulo `
                       -OQueEFeito $OQueEFeito `
                       -ComoEFeito $ComoEFeito `
                       -Tecnicas $Tecnicas `
                       -Consequencias $Consequencias `
                       -ComoValidar $ComoValidar

    while ($true) {
        Write-Host "  +-- AUTORIZACAO NECESSARIA PARA PROSSEGUIR ------------------------------------+" -ForegroundColor Yellow
        Write-Host "  | [ENTER]   -> Autorizar e executar Etapa $Numero agora                            |" -ForegroundColor White
        Write-Host "  | [V]       -> Abrir Menu de Validacao / Entrar nas Maquinas em Tempo Real    |" -ForegroundColor Cyan
        Write-Host "  | [S]       -> Pular esta etapa (Skip)                                        |" -ForegroundColor DarkGray
        Write-Host "  | [Q]       -> Encerrar e sair da demonstracao                                |" -ForegroundColor Red
        Write-Host "  +-----------------------------------------------------------------------------+" -ForegroundColor Yellow
        $resp = Read-Host "  >> Pressione ENTER para prosseguir ou digite uma opcao [V/S/Q]"

        if ([string]::IsNullOrWhiteSpace($resp)) {
            Write-Host "`n  [+] Permissao CONCEDIDA pelo usuario. Iniciando Etapa $Numero...`n" -ForegroundColor Green
            return "EXECUTAR"
        }

        $respUpper = $resp.ToUpper()
        if ($respUpper -eq "V") {
            Menu-InspecaoTempoReal
        } elseif ($respUpper -eq "S") {
            Write-Host "`n  [-] Etapa $Numero PULADA pelo usuario.`n" -ForegroundColor Yellow
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
# INICIO DA DEMONSTRACAO
# ═════════════════════════════════════════════════════════

Escrever-Cabecalho
Escrever-Topologia

# ─────────────────────────────────────────────────────────
# ETAPA 0: Subir a Infraestrutura
# ─────────────────────────────────────────────────────────
$params0 = @{
    Numero = "0"
    Titulo = "SUBINDO A INFRAESTRUTURA COMPLETA (3 CONTAINERS DOCKER)"
    OQueEFeito = "Compilacao e inicializacao de 3 maquinas simuladas em uma rede isolada."
    ComoEFeito = "docker compose up --build -d com volume compartilhado montado em /app/shared."
    Tecnicas = "Isolamento de containers Docker, Bridge Network ('rede-ataque') e Seed automatico SQL."
    Consequencias = "Ambiente 100% seguro, reproduzivel e isolado da rede host para testes de seguranca."
    ComoValidar = "docker compose ps ou 'docker exec -it servidor_bd pg_isready -U postgres -d demo_db'"
}
$acao0 = Pedir-PermissaoEtapa @params0

if ($acao0 -eq "EXECUTAR") {
    Escrever-Status "DOCKER" "Iniciando build e start dos containers..." "Yellow"
    docker compose up --build -d

    Write-Host ""
    Escrever-Status "DOCKER" "Aguardando inicializacao dos servicos..." "Cyan"
    Start-Sleep -Seconds 2

    # Verificar banco
    $maxTentativas = 20
    $tentativa = 0
    do {
        $tentativa++
        $healthCheck = docker exec servidor_bd pg_isready -U postgres -d demo_db 2>&1
        if ($LASTEXITCODE -eq 0) {
            Escrever-Status "BD" "Servidor PostgreSQL 16 PRONTO e aceitando conexoes!" "Green"
            break
        }
        Write-Host "  ... Aguardando inicializacao do banco ($tentativa/$maxTentativas)" -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
    } while ($tentativa -lt $maxTentativas)

    if ($tentativa -ge $maxTentativas) {
        Escrever-Status "ERRO" "O PostgreSQL nao iniciou a tempo!" "Red"
        exit 1
    }

    # Garantir que as maquinas da vitima e atacante estejam rodando
    docker compose up -d 2>&1 | Out-Null
    docker start maquina_vitima maquina_atacante 2>&1 | Out-Null
    Start-Sleep -Seconds 1

    # Limpar qualquer session.pkl anterior
    docker exec maquina_vitima rm -f /app/shared/session.pkl 2>&1 | Out-Null
    Escrever-Status "SESSAO" "Diretorio compartilhado limpo (/app/shared/session.pkl resetado)." "Green"

    # Mostrar status dos containers
    Write-Host ""
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    Write-Host ""

    # Conferir tabelas criadas no seed
    $qtdTabelas = docker exec servidor_bd psql -U postgres -d demo_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
    $qtdTabelas = ($qtdTabelas -replace '\s','')
    Escrever-Status "SEED" "Banco de dados populado com $qtdTabelas tabelas de dados sensiveis (usuarios, clientes, transacoes, config_sistema)!" "Green"
}

# ─────────────────────────────────────────────────────────
# ETAPA 1: Login Legitimo (Maquina da Vitima)
# ─────────────────────────────────────────────────────────
$params1 = @{
    Numero = "1"
    Titulo = "LOGIN LEGITIMO E SERIALIZACAO DE SESSAO (MAQUINA DA VITIMA)"
    OQueEFeito = "A vitima conecta no BD, valida acesso e salva o estado de sessao em 'session.pkl'."
    ComoEFeito = "Execucao de login.py na maquina_vitima. O script usa pickle.dump() para gravar dados em disco."
    Tecnicas = "Serializacao binaria de objetos Python nativos sem assinatura digital ou controle HMAC."
    Consequencias = "Criacao de vulnerabilidade OWASP A08: o arquivo em disco fica vulneravel a adulteracao externa."
    ComoValidar = "docker exec -it maquina_vitima ls -la /app/shared/session.pkl (arquivo legitimo gerado)."
}
$acao1 = Pedir-PermissaoEtapa @params1

if ($acao1 -eq "EXECUTAR") {
    Write-Host "  [EXECUCAO] Disparando login.py na Maquina da Vitima..." -ForegroundColor Cyan
    Write-Host "  Comando: docker exec -i maquina_vitima python login.py" -ForegroundColor DarkGray
    Write-Host ""

    docker exec -i maquina_vitima python login.py

    Write-Host ""
    Escrever-Status "VALIDACAO" "Inspecionando arquivo gerado no volume compartilhado:" "Cyan"
    docker exec maquina_vitima ls -lh /app/shared/session.pkl
    Write-Host ""
    Escrever-Status "RESULTADO" "Sessao legitima criada com sucesso pela vitima!" "Green"
}

# ─────────────────────────────────────────────────────────
# ETAPA 2: Infeccao do .pkl (Maquina do Atacante)
# ─────────────────────────────────────────────────────────
$params2 = @{
    Numero = "2"
    Titulo = "RECONHECIMENTO E INFECCAO DO .PKL (MAQUINA DO ATACANTE)"
    OQueEFeito = "O atacante localiza o 'session.pkl' no storage compartilhado e o substitui por um payload malicioso."
    ComoEFeito = "Simulando intrusao em storage/rede: o atacante varre o disco, detecta a sessao e executa exploit.py armando __reduce__."
    Tecnicas = "Cyber Kill Chain: Reconhecimento de filesystem, Privilege Escalation e Pickle Code Injection (__reduce__ RCE)."
    Consequencias = "Adulteracao invisivel da integridade do arquivo. Qualquer desserializacao executara codigo do atacante."
    ComoValidar = "docker exec -it maquina_atacante ls -la /app/shared/session.pkl (tamanho e hash alterados)."
}
$acao2 = Pedir-PermissaoEtapa @params2

if ($acao2 -eq "EXECUTAR") {
    Write-Host "  +-- COMO O ATACANTE CHEGOU ATE ESTE ARQUIVO? (CADEIA DE ATAQUE) ---------------+" -ForegroundColor DarkYellow
    Write-Host "  | No mundo real, o atacante usa um dos seguintes vetores de intrusao:           |" -ForegroundColor DarkGray
    Write-Host "  |   1. Storage de Rede (NFS/SMB/AWS EFS) mal configurado com permissao frouxa.  |" -ForegroundColor DarkGray
    Write-Host "  |   2. Invasao previa com baixo privilegio (ex: LFI/Web) + Escalao de Privilegio|" -ForegroundColor DarkGray
    Write-Host "  |   3. Container compartilhado em Kubernetes (PVC ReadWriteMany).               |" -ForegroundColor DarkGray
    Write-Host "  +-------------------------------------------------------------------------------+" -ForegroundColor DarkYellow
    Write-Host ""
    Escrever-Status "RECON" "Atacante executando varredura: find / -name '*.pkl' 2>/dev/null" "Cyan"
    Start-Sleep -Milliseconds 600
    Escrever-Status "RECON" "Alvo localizado: /app/shared/session.pkl (Permissao de escrita confirmada!)" "Green"
    Start-Sleep -Milliseconds 400
    Write-Host ""

    Write-Host "  Escolha o tipo de payload para o atacante injetar:" -ForegroundColor Yellow
    Write-Host "    [1] Exfiltracao + Download (Rouba TODOS os dados, salva em CSV e captura credenciais)" -ForegroundColor Cyan
    Write-Host "    [2] Destruicao + Backup (Baixa TODOS os dados para o atacante e APAGA do servidor)" -ForegroundColor Red
    $payloadEscolhido = Read-Host "  Digite o numero do payload [1 ou 2] (Padrao: 1)"
    if ($payloadEscolhido -ne "2") { $payloadEscolhido = "1" }

    Write-Host ""
    Write-Host "  [EXECUCAO] Disparando exploit.py na Maquina do Atacante com Payload $payloadEscolhido..." -ForegroundColor Red
    Write-Host "  Comando: docker exec -i maquina_atacante python exploit.py $payloadEscolhido" -ForegroundColor DarkGray
    Write-Host ""

    docker exec -i maquina_atacante python exploit.py $payloadEscolhido

    Write-Host ""
    Escrever-Status "ALERTA" "O arquivo session.pkl agora contem uma bomba-relogio de codigo arbitrario!" "Red"
    Escrever-Status "VALIDACAO" "Inspecionando os novos metadados do arquivo adulterado:" "Cyan"
    docker exec maquina_vitima ls -lh /app/shared/session.pkl
    Write-Host ""
}

# ─────────────────────────────────────────────────────────
# ETAPA 3: Login Infectado (Maquina da Vitima)
# ─────────────────────────────────────────────────────────
$params3 = @{
    Numero = "3"
    Titulo = "EXECUCAO DO PAYLOAD NO LOGIN DA VITIMA (O ATAQUE ACONTECE!)"
    OQueEFeito = "A vitima roda login.py novamente para carregar a sessao anterior sem saber da adulteracao."
    ComoEFeito = "O comando pickle.load() reconstroi o objeto e aciona automaticamente o metodo __reduce__."
    Tecnicas = "Execucao Arbitraria de Codigo (RCE) no contexto e com as permissoes e credenciais da vitima."
    Consequencias = "Vazamento catastrofico de dados confidenciais ou destruicao de todo o banco corporativo!"
    ComoValidar = "Observe o console da vitima: o codigo do atacante toma conta do fluxo antes de exibir a sessao."
}
$acao3 = Pedir-PermissaoEtapa @params3

if ($acao3 -eq "EXECUTAR") {
    Write-Host "  [EXECUCAO] A vitima executa login.py novamente..." -ForegroundColor Yellow
    Write-Host "  Comando: docker exec -i maquina_vitima python login.py" -ForegroundColor DarkGray
    Write-Host ""

    docker exec -i maquina_vitima python login.py

    Write-Host ""
    Escrever-Status "IMPACTO" "O ataque foi executado com sucesso dentro do processo da propria vitima!" "Red"
    Write-Host ""

    # Verificar se dados foram exfiltrados
    docker exec maquina_atacante test -d /app/shared/dados_roubados 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  +-- COMPROVACAO DE SUCESSO DO ATAQUE ------------------------------------------+" -ForegroundColor Red
        Write-Host "  |  Os dados exfiltrados pelo atacante estao disponiveis para inspecao:         |" -ForegroundColor Yellow
        Write-Host "  +-----------------------------------------------------------------------------+" -ForegroundColor Red
        Write-Host ""
        Escrever-Status "EXFIL" "Arquivos roubados pelo atacante:" "Red"
        docker exec maquina_atacante ls -lh /app/shared/dados_roubados
        Write-Host ""
        Escrever-Status "CREDS" "Credenciais capturadas:" "Red"
        docker exec maquina_atacante cat /app/shared/dados_roubados/credenciais_vitima.txt 2>$null
        Write-Host ""
        Escrever-Status "DICA" "Use a opcao [V] -> [6] no menu para ver preview dos CSV completos." "Cyan"
    }
}

# ─────────────────────────────────────────────────────────
# ETAPA 4: Auditoria Pos-Ataque e Validacao em Tempo Real
# ─────────────────────────────────────────────────────────
$params4 = @{
    Numero = "4"
    Titulo = "AUDITORIA FORENSE E COMPROVACAO DO ESTADO DAS MAQUINAS"
    OQueEFeito = "Auditoria direta no container do servidor de banco de dados para comprovar as consequencias."
    ComoEFeito = "Consultas SQL no PostgreSQL (servidor_bd) e conferencia de logs dos containers."
    Tecnicas = "Auditoria de Integridade, verificacao de consistencia de schema e catalogo de dados."
    Consequencias = "Comprovacao empirica do dano causado pelo ataque diante da banca ou audiencia."
    ComoValidar = "docker exec -it servidor_bd psql -U postgres -d demo_db -c '\dt'"
}
$acao4 = Pedir-PermissaoEtapa @params4

if ($acao4 -eq "EXECUTAR") {
    Write-Host ""
    Write-Host "  +-- ESTADO ATUAL DO BANCO DE DADOS (servidor_bd) ------------------------------+" -ForegroundColor Cyan
    $tabelasAtuais = docker exec servidor_bd psql -U postgres -d demo_db -c "\dt" 2>&1
    Write-Host $tabelasAtuais
    Write-Host "  +------------------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  +-- RASTRO FORENSE: REGISTRO DE ACESSO (registro_acesso) ---------------------+" -ForegroundColor Yellow
    Write-Host "  |  Cada etapa da demo deixou um rastro REAL nesta tabela!                      |" -ForegroundColor White
    Write-Host "  +------------------------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    docker exec servidor_bd psql -U postgres -d demo_db -c "SELECT id, endereco_ip, metodo_acesso, status, descricao, data_acesso FROM registro_acesso ORDER BY data_acesso;" 2>$null
    Write-Host ""

    Escrever-Status "FORENSE" "Auditoria de logs e arquivos concluida!" "Green"
    Write-Host "  Deseja abrir o Menu de Validacao ao Vivo para inspecionar os containers? (S/N)" -ForegroundColor Yellow
    $validaAgora = Read-Host "  Escolha [S/N]"
    if ($validaAgora -eq "S" -or $validaAgora -eq "s") {
        Menu-InspecaoTempoReal
    }
}

# ─────────────────────────────────────────────────────────
# ETAPA 5: Mitigacoes e Licoes Aprendidas
# ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ================================================================================" -ForegroundColor Green
Write-Host "    COMO MITIGAR ESTA VULNERABILIDADE NA PRATICA (ARQUITETURA DEFENSIVA)          " -ForegroundColor Yellow
Write-Host "  ================================================================================" -ForegroundColor Green
Write-Host "    1. NUNCA use 'pickle' para dados trafegados na rede ou em discos partilhados" -ForegroundColor White
Write-Host "       -> Substitua por formatos neutros de serializacao: JSON, Protocol Buffers" -ForegroundColor Cyan
Write-Host ""
Write-Host "    2. Assinatura Criptografica de Integridade (HMAC-SHA256)" -ForegroundColor White
Write-Host "       -> Assine qualquer arquivo serializado com chave secreta antes de salvar" -ForegroundColor Cyan
Write-Host "       -> Rejeite o arquivo imediatamente se a assinatura nao conferir" -ForegroundColor Cyan
Write-Host ""
Write-Host "    3. RestrictedUnpickler (Lista Branca de Classes)" -ForegroundColor White
Write-Host "       -> Bloqueie a instanciacao de callables arbitrarios pelo protocolo pickle" -ForegroundColor Cyan
Write-Host ""
Write-Host "    4. Principio do Menor Privilegio no Banco de Dados (PoLP)" -ForegroundColor White
Write-Host "       -> O usuario da aplicacao nao deve ter permissao de DROP TABLE ou acesso" -ForegroundColor Cyan
Write-Host "          a tabelas de outros contextos e configuracoes do sistema" -ForegroundColor Cyan
Write-Host "  ================================================================================" -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────────────────────
# ENCERRAMENTO E LIMPEZA
# ─────────────────────────────────────────────────────────
Write-Host "  Deseja desligar e remover os containers e volumes da demonstracao agora? (S/N)" -ForegroundColor Yellow
$cleanup = Read-Host "  Escolha [S/N] (Padrao: N para manter containers ativos para validacao)"
if ($cleanup -eq "S" -or $cleanup -eq "s") {
    Escrever-Status "DOCKER" "Derrubando containers e removendo volumes..." "Yellow"
    docker compose down -v
    Escrever-Status "DOCKER" "Ambiente limpo com sucesso!" "Green"
} else {
    Write-Host ""
    Escrever-Status "DOCKER" "Containers mantidos rodando! Para entrar neles a qualquer momento:" "Green"
    Write-Host "    docker exec -it servidor_bd psql -U postgres -d demo_db" -ForegroundColor Cyan
    Write-Host "    docker exec -it maquina_vitima bash" -ForegroundColor Cyan
    Write-Host "    docker exec -it maquina_atacante bash" -ForegroundColor Cyan
    Write-Host "    Para derrubar manualmente depois: docker compose down -v" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Demonstracao finalizada com sucesso!" -ForegroundColor Green
Write-Host ""
