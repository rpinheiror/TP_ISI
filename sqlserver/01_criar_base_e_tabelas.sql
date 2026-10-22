-- TP1: executar no SQL Server Management Studio ou com sqlcmd.
-- Cria apenas a base dedicada TP1_FornecedoresStock. Nao elimina bases ou tabelas.
USE master;
GO
IF DB_ID(N'TP1_FornecedoresStock') IS NULL
    EXEC(N'CREATE DATABASE TP1_FornecedoresStock');
GO
USE TP1_FornecedoresStock;
GO
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.Fornecedores', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fornecedores (
        fornecedor_id int NOT NULL CONSTRAINT PK_Fornecedores PRIMARY KEY,
        codigo nvarchar(30) NOT NULL CONSTRAINT UQ_Fornecedores_Codigo UNIQUE,
        nome nvarchar(150) NOT NULL
    );
END;
IF OBJECT_ID(N'dbo.Produtos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Produtos (
        produto_id nvarchar(20) NOT NULL CONSTRAINT PK_Produtos PRIMARY KEY,
        designacao nvarchar(200) NOT NULL
    );
END;
IF OBJECT_ID(N'dbo.Ofertas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ofertas (
        fornecedor_id int NOT NULL,
        referencia_normalizada nvarchar(50) NOT NULL,
        produto_id nvarchar(20) NOT NULL,
        designacao_normalizada nvarchar(200) NOT NULL,
        preco_eur decimal(12,2) NOT NULL,
        quantidade_disponivel int NOT NULL,
        CONSTRAINT PK_Ofertas PRIMARY KEY (fornecedor_id, referencia_normalizada),
        CONSTRAINT FK_Ofertas_Fornecedores FOREIGN KEY (fornecedor_id)
            REFERENCES dbo.Fornecedores(fornecedor_id),
        CONSTRAINT FK_Ofertas_Produtos FOREIGN KEY (produto_id)
            REFERENCES dbo.Produtos(produto_id),
        CONSTRAINT CK_Ofertas_Preco CHECK (preco_eur > 0),
        CONSTRAINT CK_Ofertas_Quantidade CHECK (quantidade_disponivel >= 0)
    );
    CREATE INDEX IX_Ofertas_Produto ON dbo.Ofertas(produto_id);
END;
BEGIN TRANSACTION;
INSERT INTO dbo.Fornecedores (fornecedor_id, codigo, nome)
SELECT v.id, v.codigo, v.nome
FROM (VALUES (1, N'FORN_A', N'Fornecedor A'),
             (2, N'FORN_B', N'Fornecedor B'),
             (3, N'FORN_C', N'Fornecedor C')) v(id, codigo, nome)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Fornecedores f WHERE f.fornecedor_id = v.id);
INSERT INTO dbo.Produtos (produto_id, designacao)
SELECT v.produto_id, v.designacao
FROM (VALUES
        (N'P001', N'Cabo USB-C 1 m'),
        (N'P002', N'Rato sem fios'),
        (N'P003', N'Teclado USB'),
        (N'P004', N'Monitor 24 polegadas'),
        (N'P005', N'Hub USB 4 portas')) v(produto_id, designacao)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Produtos p WHERE p.produto_id = v.produto_id);
COMMIT;
GO
-- Mantem o contrato de seis colunas do CSV para facilitar a troca do leitor no KNIME.
-- Nesta view, fornecedor_id representa o CODIGO (FORN_A). Na tabela Ofertas e INT.
CREATE OR ALTER VIEW dbo.vw_CatalogoKNIME AS
SELECT o.produto_id, f.codigo AS fornecedor_id, o.referencia_normalizada,
       o.designacao_normalizada, o.preco_eur, o.quantidade_disponivel
FROM dbo.Ofertas o
INNER JOIN dbo.Fornecedores f ON f.fornecedor_id = o.fornecedor_id;
GO
SELECT N'Estrutura pronta: fornecedores e produtos de referencia; ofertas carregadas pelo Kettle.' AS resultado;
