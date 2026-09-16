#!/usr/bin/env python3
# ==============================================================
# login.py — Script de login do usuário (VÍTIMA)
# Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
#
# FLUXO:
#   1ª execução: Conecta no BD → exibe dados → salva session.pkl
#   2ª execução: Carrega session.pkl via pickle.load (VULNERÁVEL)
#     - Se .pkl limpo: exibe sessão anterior
#     - Se .pkl infectado: EXECUTA O PAYLOAD MALICIOSO
# ==============================================================

import os
import pickle
import sys
import time
from datetime import datetime

import psycopg2

from config import DB_CONFIG, SESSION_FILE

# ── Cores ANSI para output no terminal ──
RESET   = "\033[0m"
BOLD    = "\033[1m"
GREEN   = "\033[92m"
CYAN    = "\033[96m"
YELLOW  = "\033[93m"
RED     = "\033[91m"
MAGENTA = "\033[95m"
DIM     = "\033[2m"
WHITE   = "\033[97m"

# ── Velocidade das animações (segundos) ──
PAUSA_CURTA  = 0.8
PAUSA_MEDIA  = 1.5
PAUSA_LONGA  = 2.5


def digitar(texto, delay=0.03):
    """Efeito de digitação caractere por caractere."""
    for char in texto:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()


def pausar(mensagem="Pressione ENTER para continuar..."):
    """Pausa interativa — espera o apresentador apertar ENTER."""
    print()
    input(f"  {DIM}>> {mensagem}{RESET}")
    print()


def barra_progresso(descricao, duracao=2.0, etapas=20):
    """Barra de progresso animada para simular processamento."""
    sys.stdout.write(f"  {CYAN}[{descricao}]{RESET} [")
    sys.stdout.flush()
    for i in range(etapas):
        time.sleep(duracao / etapas)
        sys.stdout.write(f"{GREEN}█{RESET}")
        sys.stdout.flush()
    print(f"] {GREEN}OK{RESET}")


def banner():
    """Exibe o banner do sistema de login."""
    print()
    print(f"{CYAN}{'═' * 62}{RESET}")
    print(f"{CYAN}║{RESET}  {BOLD}🔐  SISTEMA DE LOGIN — ACESSO AO BANCO DE DADOS{RESET}         {CYAN}║{RESET}")
    print(f"{CYAN}║{RESET}  {DIM}Projeto Demonstrativo de Segurança — OWASP A08:2021{RESET}    {CYAN}║{RESET}")
    print(f"{CYAN}{'═' * 62}{RESET}")
    print()


def login_fresh():
    """
    Realiza login legítimo no banco de dados e salva a sessão
    em um arquivo .pkl (pickle serializado).
    """
    # ─── Passo 1: Informar que não há sessão ───
    print(f"  {YELLOW}▸ Passo 1:{RESET} Verificando sessão anterior...")
    time.sleep(PAUSA_CURTA)
    print(f"  {YELLOW}[LOGIN]{RESET} Nenhum arquivo {BOLD}session.pkl{RESET} encontrado.")
    print(f"  {DIM}         O sistema vai conectar diretamente no banco de dados.{RESET}")
    time.sleep(PAUSA_CURTA)

    pausar("Pressione ENTER para conectar no banco de dados...")

    # ─── Passo 2: Conectar no BD ───
    print(f"  {YELLOW}▸ Passo 2:{RESET} Conectando ao banco de dados...")
    print(f"  {DIM}         Host: {DB_CONFIG['host']}:{DB_CONFIG['port']}{RESET}")
    print(f"  {DIM}         Database: {DB_CONFIG['dbname']}{RESET}")
    print(f"  {DIM}         Usuário: {DB_CONFIG['user']}{RESET}")
    print()

    barra_progresso("Conectando", duracao=1.5)

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        time.sleep(PAUSA_CURTA)
        print(f"  {GREEN}[OK]{RESET} Conexão estabelecida com sucesso!")
        print()

    except psycopg2.OperationalError as e:
        print(f"  {RED}[ERRO]{RESET} Não foi possível conectar ao banco de dados!")
        print(f"  {RED}[ERRO]{RESET} {e}")
        print()
        print(f"  {YELLOW}Dica:{RESET} Verifique se os containers Docker estão rodando:")
        print(f"  {DIM}  docker compose up -d{RESET}")
        sys.exit(1)

    pausar("Pressione ENTER para executar a query de autenticação...")

    # ─── Passo 3: Executar query ───
    print(f"  {YELLOW}▸ Passo 3:{RESET} Executando query de autenticação...")
    print()
    print(f"  {DIM}  SQL > SELECT current_user, current_database(), version();{RESET}")
    time.sleep(PAUSA_CURTA)

    barra_progresso("Executando", duracao=1.0)

    cursor.execute("SELECT current_user, current_database(), version();")
    user_db, database, version_info = cursor.fetchone()

    cursor.execute("""
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
    """)
    total_tabelas = cursor.fetchone()[0]

    cursor.close()
    conn.close()

    time.sleep(PAUSA_CURTA)

    # ─── Passo 4: Exibir dados obtidos ───
    print()
    print(f"  {YELLOW}▸ Passo 4:{RESET} Dados retornados pelo servidor:")
    time.sleep(PAUSA_CURTA)
    print()
    print(f"  {GREEN}┌{'─' * 58}┐{RESET}")
    print(f"  {GREEN}│  ✅  LOGIN REALIZADO COM SUCESSO                         │{RESET}")
    print(f"  {GREEN}├{'─' * 58}┤{RESET}")
    time.sleep(0.3)
    print(f"  {GREEN}│{RESET}  Usuário:    {BOLD}{user_db}{RESET}")
    time.sleep(0.3)
    print(f"  {GREEN}│{RESET}  Database:   {BOLD}{database}{RESET}")
    time.sleep(0.3)
    print(f"  {GREEN}│{RESET}  Servidor:   {DIM}{version_info[:50]}...{RESET}")
    time.sleep(0.3)
    print(f"  {GREEN}│{RESET}  Tabelas:    {BOLD}{total_tabelas}{RESET} tabela(s) no schema público")
    time.sleep(0.3)

    session_data = {
        "usuario": user_db,
        "database": database,
        "versao_servidor": version_info,
        "total_tabelas": total_tabelas,
        "timestamp_login": datetime.now().isoformat(),
        "ip_servidor": f"{DB_CONFIG['host']}:{DB_CONFIG['port']}",
    }

    print(f"  {GREEN}│{RESET}  Timestamp:  {session_data['timestamp_login']}")
    time.sleep(0.3)
    print(f"  {GREEN}│{RESET}  Endereço:   {session_data['ip_servidor']}")
    print(f"  {GREEN}└{'─' * 58}┘{RESET}")
    print()

    pausar("Pressione ENTER para salvar a sessão em session.pkl...")

    # ─── Passo 5: Salvar sessão (PONTO VULNERÁVEL) ───
    print(f"  {YELLOW}▸ Passo 5:{RESET} Salvando sessão no disco...")
    print()
    print(f"  {WHITE}  O sistema vai serializar os dados da sessão usando{RESET}")
    print(f"  {WHITE}  a biblioteca {BOLD}pickle{RESET}{WHITE} do Python e salvar em um arquivo .pkl{RESET}")
    print()
    time.sleep(PAUSA_CURTA)

    # ⚠️ PONTO VULNERÁVEL: Salva sessão via pickle.dump (sem assinatura/HMAC)
    with open(SESSION_FILE, "wb") as f:
        pickle.dump(session_data, f)

    barra_progresso("Serializando", duracao=1.0)
    print()
    print(f"  {CYAN}[SESSÃO]{RESET} Arquivo salvo: {BOLD}{SESSION_FILE}{RESET}")
    print()

    # Mostrar o tamanho do arquivo gerado
    tamanho = os.path.getsize(SESSION_FILE)
    print(f"  {DIM}  Tamanho: {tamanho} bytes{RESET}")
    print(f"  {DIM}  Método: pickle.dump() — serialização binária Python{RESET}")
    print()

    print(f"  {YELLOW}┌{'─' * 58}┐{RESET}")
    print(f"  {YELLOW}│  ⚠️  ATENÇÃO: Ponto de vulnerabilidade!                  │{RESET}")
    print(f"  {YELLOW}├{'─' * 58}┤{RESET}")
    print(f"  {YELLOW}│{RESET}  O arquivo {BOLD}session.pkl{RESET} foi salvo SEM nenhuma")
    print(f"  {YELLOW}│{RESET}  validação de integridade (sem HMAC, sem assinatura).")
    print(f"  {YELLOW}│{RESET}  ")
    print(f"  {YELLOW}│{RESET}  Se alguém modificar este arquivo, o sistema vai")
    print(f"  {YELLOW}│{RESET}  carregar o conteúdo alterado sem perceber!")
    print(f"  {YELLOW}└{'─' * 58}┘{RESET}")
    print()

    return session_data


def login_from_session():
    """
    Carrega sessão anterior do arquivo .pkl.

    ⚠️ VULNERABILIDADE: pickle.load() executa código arbitrário
    se o arquivo tiver sido modificado com um payload malicioso.
    """
    # ─── Passo 1: Detectar sessão existente ───
    print(f"  {YELLOW}▸ Passo 1:{RESET} Verificando sessão anterior...")
    time.sleep(PAUSA_CURTA)
    tamanho = os.path.getsize(SESSION_FILE)
    print(f"  {CYAN}[SESSÃO]{RESET} Arquivo encontrado: {BOLD}{SESSION_FILE}{RESET} ({tamanho} bytes)")
    print(f"  {DIM}         O sistema vai restaurar a sessão anterior.{RESET}")
    time.sleep(PAUSA_CURTA)

    pausar("Pressione ENTER para carregar o arquivo session.pkl...")

    # ─── Passo 2: Carregar o .pkl ───
    print(f"  {YELLOW}▸ Passo 2:{RESET} Carregando sessão via {BOLD}pickle.load(){RESET}...")
    print()
    print(f"  {DIM}  Python > data = pickle.load(open('{SESSION_FILE}', 'rb')){RESET}")
    print()
    time.sleep(PAUSA_CURTA)

    barra_progresso("Desserializando", duracao=1.5)

    # ⚠️ PONTO DE ATAQUE: pickle.load sem qualquer validação!
    # Se o .pkl foi infectado pelo exploit.py, o código malicioso
    # será executado AQUI, antes mesmo de retornar os dados.
    with open(SESSION_FILE, "rb") as f:
        session_data = pickle.load(f)

    time.sleep(PAUSA_CURTA)

    # ─── Passo 3: Exibir resultado ───
    print()
    print(f"  {YELLOW}▸ Passo 3:{RESET} Resultado da desserialização:")
    time.sleep(PAUSA_CURTA)
    print()

    # Se chegou aqui com dados legítimos, exibe normalmente
    if isinstance(session_data, dict) and "usuario" in session_data:
        print(f"  {GREEN}┌{'─' * 58}┐{RESET}")
        print(f"  {GREEN}│  ✅  SESSÃO RESTAURADA COM SUCESSO                       │{RESET}")
        print(f"  {GREEN}├{'─' * 58}┤{RESET}")
        time.sleep(0.3)
        print(f"  {GREEN}│{RESET}  Usuário:    {BOLD}{session_data.get('usuario', '?')}{RESET}")
        time.sleep(0.3)
        print(f"  {GREEN}│{RESET}  Database:   {BOLD}{session_data.get('database', '?')}{RESET}")
        time.sleep(0.3)
        print(f"  {GREEN}│{RESET}  Login em:   {session_data.get('timestamp_login', '?')}")
        time.sleep(0.3)
        print(f"  {GREEN}│{RESET}  Endereço:   {session_data.get('ip_servidor', '?')}")
        print(f"  {GREEN}└{'─' * 58}┘{RESET}")

        # Se a sessão foi comprometida, o dict terá a chave "status"
        if session_data.get("status") == "COMPROMETIDO":
            time.sleep(PAUSA_MEDIA)
            print()
            print(f"  {RED}{'═' * 58}{RESET}")
            print(f"  {RED}  ⚠️  ESTA SESSÃO FOI COMPROMETIDA POR UM ATACANTE!{RESET}")
            print(f"  {RED}  O payload malicioso foi executado durante o{RESET}")
            print(f"  {RED}  pickle.load() — ANTES de exibir estes dados!{RESET}")
            print(f"  {RED}{'═' * 58}{RESET}")
    else:
        # Caso o payload retorne algo inesperado
        print(f"  {YELLOW}[AVISO]{RESET} Dados da sessão em formato inesperado:")
        print(f"  {DIM}{session_data}{RESET}")

    print()
    return session_data


def main():
    banner()

    if os.path.exists(SESSION_FILE):
        # Sessão existe — carrega via pickle.load (VULNERÁVEL!)
        session = login_from_session()
    else:
        # Primeiro login — conecta no BD e salva sessão
        session = login_fresh()

    print(f"  {DIM}─── Fim do processo de login ───{RESET}")
    print()


if __name__ == "__main__":
    main()
