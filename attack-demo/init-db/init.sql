-- ==============================================================
-- init.sql — Seed do banco de dados para a demonstração
-- Projeto: Demonstração de Pickle Deserialization Attack (A08:2021)
--
-- Cria tabelas e popula com dados fictícios "sensíveis" para
-- que a exfiltração do ataque tenha impacto visual na apresentação
-- ==============================================================

-- ─── Tabela de Usuários (dados sensíveis) ───
CREATE TABLE IF NOT EXISTS usuarios (
    id            SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    senha_hash    VARCHAR(255) NOT NULL,
    cargo         VARCHAR(50),
    salario       DECIMAL(10, 2),
    data_admissao DATE DEFAULT CURRENT_DATE,
    ativo         BOOLEAN DEFAULT TRUE
);

-- ─── Tabela de Clientes ───
CREATE TABLE IF NOT EXISTS clientes (
    id        SERIAL PRIMARY KEY,
    nome      VARCHAR(150) NOT NULL,
    cpf       VARCHAR(14) UNIQUE NOT NULL,
    telefone  VARCHAR(20),
    endereco  TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── Tabela de Transações Financeiras ───
CREATE TABLE IF NOT EXISTS transacoes (
    id              SERIAL PRIMARY KEY,
    cliente_id      INTEGER REFERENCES clientes(id),
    tipo            VARCHAR(20) NOT NULL CHECK (tipo IN ('DEPOSITO', 'SAQUE', 'TRANSFERENCIA', 'PIX')),
    valor           DECIMAL(12, 2) NOT NULL,
    descricao       TEXT,
    data_transacao  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── Tabela de Configurações do Sistema (dados críticos) ───
CREATE TABLE IF NOT EXISTS config_sistema (
    chave   VARCHAR(100) PRIMARY KEY,
    valor   TEXT NOT NULL,
    descricao TEXT
);

-- ==============================================================
-- SEED DE DADOS FICTÍCIOS
-- ==============================================================

-- Usuários do sistema (senhas são hashes fictícios)
INSERT INTO usuarios (nome, email, senha_hash, cargo, salario) VALUES
    ('Carlos Administrador',  'carlos.admin@empresa.com',    '$2b$12$LJ3m8Dv0K8F...hashficticio01', 'Administrador', 15000.00),
    ('Ana Desenvolvedora',    'ana.dev@empresa.com',         '$2b$12$PQ9n7Rw1X2G...hashficticio02', 'Desenvolvedora', 12000.00),
    ('Roberto Financeiro',    'roberto.fin@empresa.com',     '$2b$12$MK4p5Ty3Z8H...hashficticio03', 'Gerente Financeiro', 18500.00),
    ('Juliana Suporte',       'juliana.sup@empresa.com',     '$2b$12$WN6o2Sv4A1J...hashficticio04', 'Suporte N2', 7500.00),
    ('Pedro Estagiário',      'pedro.est@empresa.com',       '$2b$12$XR8q4Uw5B3K...hashficticio05', 'Estagiário', 2000.00)
ON CONFLICT (email) DO NOTHING;

-- Clientes (CPFs fictícios)
INSERT INTO clientes (nome, cpf, telefone, endereco) VALUES
    ('Maria Silva Santos',      '123.456.789-00', '(11) 98765-4321', 'Rua das Flores, 42 - São Paulo/SP'),
    ('João Pedro Oliveira',     '987.654.321-00', '(21) 91234-5678', 'Av. Brasil, 1500 - Rio de Janeiro/RJ'),
    ('Empresa TechCorp LTDA',   '12.345.678/0001-90', '(11) 3333-4444', 'Al. Santos, 900 - São Paulo/SP'),
    ('Fernanda Costa Lima',     '456.789.123-00', '(31) 99876-5432', 'Rua Minas Gerais, 200 - Belo Horizonte/MG'),
    ('Ricardo Mendes Jr.',      '321.654.987-00', '(41) 98888-7777', 'Rua XV de Novembro, 80 - Curitiba/PR')
ON CONFLICT (cpf) DO NOTHING;

-- Transações financeiras
INSERT INTO transacoes (cliente_id, tipo, valor, descricao) VALUES
    (1, 'DEPOSITO',      5000.00,    'Depósito inicial em conta'),
    (1, 'PIX',           1250.00,    'PIX para fornecedor - NF 4521'),
    (2, 'TRANSFERENCIA', 3200.00,    'TED recebida - Salário'),
    (2, 'SAQUE',         800.00,     'Saque em caixa eletrônico'),
    (3, 'DEPOSITO',      45000.00,   'Aporte de capital - Contrato 2024/001'),
    (3, 'PIX',           12500.00,   'Pagamento fornecedor - NF 8901'),
    (4, 'DEPOSITO',      2800.00,    'Depósito em espécie'),
    (4, 'TRANSFERENCIA', 1500.00,    'Transferência entre contas'),
    (5, 'PIX',           950.00,     'PIX - Mensalidade curso'),
    (5, 'DEPOSITO',      6700.00,    'Depósito - Freelance projeto X');

-- Configurações do sistema (dados críticos que não deveriam ser acessíveis)
INSERT INTO config_sistema (chave, valor, descricao) VALUES
    ('JWT_SECRET',          'minha-chave-secreta-super-segura-2024!',    'Chave para assinatura de tokens JWT'),
    ('API_KEY_PAGAMENTO',   'SUA_API_KEY_AQUI',                         'API Key do gateway de pagamento (PRODUÇÃO)'),
    ('SMTP_PASSWORD',       'S3nh@EmAIL!Pr0d',                          'Senha do servidor de e-mail'),
    ('ENCRYPTION_KEY',      'aes-256-cbc-key-d41d8cd98f00b204e980',     'Chave de criptografia AES-256'),
    ('DB_BACKUP_PATH',      '/mnt/backups/producao/',                    'Caminho dos backups do banco')
ON CONFLICT (chave) DO NOTHING;
