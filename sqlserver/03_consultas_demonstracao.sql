USE TP1_FornecedoresStock;
GO
-- Consulta que o colega coloca no DB Query Reader do KNIME:
SELECT produto_id, fornecedor_id, referencia_normalizada,
       designacao_normalizada, preco_eur, quantidade_disponivel
FROM dbo.vw_CatalogoKNIME;

-- Contagens: 3 fornecedores, 5 produtos, 15 ofertas no cenario original.
SELECT (SELECT COUNT(*) FROM dbo.Fornecedores) AS fornecedores,
       (SELECT COUNT(*) FROM dbo.Produtos) AS produtos,
       (SELECT COUNT(*) FROM dbo.Ofertas) AS ofertas;

-- Relacoes: o ID numerico da oferta identifica um fornecedor existente.
SELECT o.produto_id, p.designacao AS produto, f.fornecedor_id, f.codigo,
       o.referencia_normalizada, o.preco_eur, o.quantidade_disponivel
FROM dbo.Ofertas o
JOIN dbo.Produtos p ON p.produto_id = o.produto_id
JOIN dbo.Fornecedores f ON f.fornecedor_id = o.fornecedor_id
ORDER BY o.produto_id, o.preco_eur;

-- Agregacao SQL para demonstracao; nao calcula ainda as compras.
SELECT f.codigo, COUNT(*) AS numero_ofertas, MIN(o.preco_eur) AS menor_preco
FROM dbo.Ofertas o JOIN dbo.Fornecedores f ON f.fornecedor_id=o.fornecedor_id
GROUP BY f.codigo;
