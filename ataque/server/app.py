"""
=======================================================================
SERVIDOR VULNERÁVEL — DEMONSTRAÇÃO DE ATAQUE LATERAL
API Flask com falhas de segurança intencionais:
  - Endpoint /admin/sessions sem autenticação
  - Leitura de notas sem validação de autoria
  - Execução de comandos remotos sem autorização
=======================================================================
"""

from flask import Flask, request, jsonify
import sqlite3
import time
import uuid
import os

app = Flask(__name__)
DB_PATH = "/app/data/server.db"


def get_db():
    """Retorna conexão com o banco SQLite."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Inicializa as tabelas do banco de dados."""
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            ip_address TEXT,
            hostname TEXT,
            token TEXT,
            connected_at TEXT DEFAULT (datetime('now','localtime'))
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now','localtime'))
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target_user TEXT NOT NULL,
            command TEXT NOT NULL,
            requested_by TEXT NOT NULL,
            status TEXT DEFAULT 'PENDING',
            result TEXT,
            created_at TEXT DEFAULT (datetime('now','localtime')),
            executed_at TEXT
        )
    """)

    conn.commit()
    conn.close()


# =====================================================================
# ROTA DE SAÚDE
# =====================================================================
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "demo-server"}), 200


# =====================================================================
# REGISTRO DE SESSÃO — Usuário se conecta ao servidor
# =====================================================================
@app.route("/register", methods=["POST"])
def register_session():
    data = request.get_json()
    username = data.get("username")
    ip_address = data.get("ip_address", request.remote_addr)
    hostname = data.get("hostname", "desconhecido")
    token = str(uuid.uuid4())

    conn = get_db()
    cursor = conn.cursor()

    # Remove sessão anterior do mesmo user (simula reconexão)
    cursor.execute("DELETE FROM sessions WHERE username = ?", (username,))

    cursor.execute(
        "INSERT INTO sessions (username, ip_address, hostname, token) VALUES (?, ?, ?, ?)",
        (username, ip_address, hostname, token),
    )
    conn.commit()
    conn.close()

    print(f"[REGISTRO] Usuário '{username}' conectado de {ip_address} ({hostname})")

    return jsonify({
        "status": "CONECTADO",
        "username": username,
        "token": token,
        "message": f"Sessão registrada com sucesso para '{username}'."
    }), 201


# =====================================================================
# NOTAS PESSOAIS — CRUD simples
# =====================================================================
@app.route("/notes", methods=["POST"])
def create_note():
    data = request.get_json()
    username = data.get("username")
    title = data.get("title")
    content = data.get("content")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO notes (username, title, content) VALUES (?, ?, ?)",
        (username, title, content),
    )
    conn.commit()
    note_id = cursor.lastrowid
    conn.close()

    print(f"[NOTA] Usuário '{username}' criou nota: '{title}'")

    return jsonify({
        "id": note_id,
        "username": username,
        "title": title,
        "message": "Nota criada com sucesso."
    }), 201


# =====================================================================
# ⚠️  VULNERABILIDADE 1: Leitura de notas SEM validação de autoria
# Qualquer pessoa pode ler as notas de qualquer usuário apenas
# sabendo o username. Não há token ou autenticação no header.
# =====================================================================
@app.route("/notes/<username>", methods=["GET"])
def get_notes(username):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM notes WHERE username = ?", (username,))
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    print(f"[ACESSO] Notas do usuário '{username}' foram acessadas ({len(notes)} notas)")

    return jsonify({
        "username": username,
        "total_notes": len(notes),
        "notes": notes
    }), 200


# =====================================================================
# ⚠️  VULNERABILIDADE 2: Endpoint administrativo SEM autenticação
# Qualquer requisição lista todas as sessões ativas do sistema,
# expondo IPs, hostnames e tokens de todos os usuários conectados.
# =====================================================================
@app.route("/admin/sessions", methods=["GET"])
def list_sessions():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM sessions ORDER BY connected_at DESC")
    sessions = [dict(row) for row in cursor.fetchall()]
    conn.close()

    print(f"[⚠️  ADMIN] Listagem de sessões acessada! {len(sessions)} sessão(ões) exposta(s).")

    return jsonify({
        "total_sessions": len(sessions),
        "sessions": sessions
    }), 200


# =====================================================================
# ⚠️  VULNERABILIDADE 3: Execução remota SEM autorização
# Qualquer usuário pode enviar um comando para ser executado
# na máquina de outro usuário. Não valida quem está pedindo.
# =====================================================================
@app.route("/exec", methods=["POST"])
def send_command():
    data = request.get_json()
    target_user = data.get("target_user")
    command = data.get("command")
    requested_by = data.get("requested_by", "anonimo")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO commands (target_user, command, requested_by) VALUES (?, ?, ?)",
        (target_user, command, requested_by),
    )
    conn.commit()
    cmd_id = cursor.lastrowid
    conn.close()

    print(f"[⚠️  EXEC] Comando enfileirado: '{command}' -> alvo: '{target_user}' (solicitado por: '{requested_by}')")

    return jsonify({
        "command_id": cmd_id,
        "target_user": target_user,
        "command": command,
        "status": "PENDING",
        "message": f"Comando enfileirado para execução na máquina de '{target_user}'."
    }), 201


# =====================================================================
# POLLING DE COMANDOS — Agente do usuário busca comandos pendentes
# =====================================================================
@app.route("/exec/pending/<username>", methods=["GET"])
def get_pending_commands(username):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT * FROM commands WHERE target_user = ? AND status = 'PENDING' ORDER BY created_at ASC LIMIT 1",
        (username,),
    )
    row = cursor.fetchone()
    conn.close()

    if row:
        return jsonify({"has_command": True, "command": dict(row)}), 200
    else:
        return jsonify({"has_command": False}), 200


# =====================================================================
# RESULTADO DE COMANDO — Agente reporta resultado da execução
# =====================================================================
@app.route("/exec/result", methods=["POST"])
def post_command_result():
    data = request.get_json()
    command_id = data.get("command_id")
    result = data.get("result", "")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE commands SET status = 'EXECUTED', result = ?, executed_at = datetime('now','localtime') WHERE id = ?",
        (result, command_id),
    )
    conn.commit()
    conn.close()

    print(f"[EXEC RESULT] Comando #{command_id} executado. Resultado: {result[:200]}")

    return jsonify({
        "command_id": command_id,
        "status": "EXECUTED",
        "message": "Resultado do comando registrado."
    }), 200


# =====================================================================
# CONSULTA DE RESULTADO — Busca resultado de um comando específico
# =====================================================================
@app.route("/exec/result/<int:command_id>", methods=["GET"])
def get_command_result(command_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM commands WHERE id = ?", (command_id,))
    row = cursor.fetchone()
    conn.close()

    if row:
        return jsonify(dict(row)), 200
    else:
        return jsonify({"error": "Comando não encontrado."}), 404


# =====================================================================
# INICIALIZAÇÃO
# =====================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("  SERVIDOR DE DEMONSTRAÇÃO — API VULNERÁVEL")
    print("  ⚠️  ESTE SERVIDOR POSSUI FALHAS DE SEGURANÇA INTENCIONAIS")
    print("=" * 60)
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=False)
