--Criação de Tabelas

CREATE TABLE staging_vendas (
  nr_pedido INT,
  dt_momento DATE,
  codigo_filial INT,
  nome_filial VARCHAR(100),
  codigo_cliente INT,
  nome_cliente VARCHAR(150),
  uf CHAR(2),
  codigo_produto INT,
  descricao_produto VARCHAR(200),
  marca VARCHAR(100),
  preco_unitario NUMERIC(10,2),
  quantidade INT,
  avaliacao INT
);


TRUNCATE staging_vendas;

COPY staging_vendas

-- Importação do CSV
FROM 'D:\Downloads\Downloads\CURSO\8 Banco de Dados\Ciclo 07\CICLO08-Aula51-projetofinal.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS filiais CASCADE;

-- Criando novas tabelas

CREATE TABLE filiais (
  codigo_filial INT PRIMARY KEY,
  nome_filial VARCHAR(100),
  uf CHAR(2)
);

CREATE TABLE clientes (
  codigo_cliente INT PRIMARY KEY,
  nome_cliente VARCHAR(150)
);

CREATE TABLE produtos (
  codigo_produto INT PRIMARY KEY,
  descricao_produto VARCHAR(200),
  marca VARCHAR(100),
  preco_unitario NUMERIC(10,2) CHECK (preco_unitario > 0)
);

CREATE TABLE pedidos (
  nr_pedido INT,
  dt_momento DATE,
  codigo_filial INT REFERENCES filiais,
  codigo_cliente INT REFERENCES clientes,
  codigo_produto INT REFERENCES produtos,
  quantidade INT CHECK (quantidade > 0),
  avaliacao INT,
  PRIMARY KEY (nr_pedido, codigo_produto)
);

INSERT INTO filiais (codigo_filial, nome_filial, uf)
SELECT DISTINCT codigo_filial, nome_filial, uf
FROM staging_vendas
ON CONFLICT (codigo_filial) DO NOTHING;

INSERT INTO clientes (codigo_cliente, nome_cliente)
SELECT DISTINCT codigo_cliente, nome_cliente
FROM staging_vendas
ON CONFLICT (codigo_cliente) DO NOTHING;

INSERT INTO produtos (codigo_produto, descricao_produto, marca, preco_unitario)
SELECT DISTINCT codigo_produto, descricao_produto, marca, preco_unitario
FROM staging_vendas
ON CONFLICT (codigo_produto) DO NOTHING;

INSERT INTO pedidos (nr_pedido, dt_momento, codigo_filial, codigo_cliente, codigo_produto, quantidade, avaliacao)
SELECT nr_pedido, dt_momento, codigo_filial, codigo_cliente, codigo_produto, quantidade, avaliacao
FROM staging_vendas;



---Queries analíticas

-- Top 5 Clientes que mais compraram
SELECT nome_cliente, SUM(quantidade) AS total
FROM pedidos
JOIN clientes USING(codigo_cliente)
GROUP BY nome_cliente
ORDER BY total DESC
LIMIT 5;

-- Top 3 produtos mais vendidos
SELECT descricao_produto, SUM(quantidade) AS total
FROM pedidos
JOIN produtos USING(codigo_produto)
GROUP BY descricao_produto
ORDER BY total DESC
LIMIT 3;


-- Produto mais vendido por marca (julho–dezembro/2023):
SELECT 
  pr.marca,
  pr.descricao_produto,
  SUM(p.quantidade) AS total_vendido
FROM pedidos p
JOIN produtos pr USING (codigo_produto)
WHERE p.dt_momento BETWEEN '2023-07-01' AND '2023-12-31'
GROUP BY pr.marca, pr.descricao_produto
ORDER BY pr.marca, total_vendido DESC;

--Criar a view de vendas por filial e UF:
CREATE OR REPLACE VIEW vendas_por_filial_regiao AS
SELECT
  f.nome_filial AS filial,

  SUM(CASE 
    WHEN sv.uf IN ('AM','PA','AC','RO','RR','AP','TO')
    THEN pr.preco_unitario * p.quantidade ELSE 0 END) AS norte,

  SUM(CASE 
    WHEN sv.uf IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA')
    THEN pr.preco_unitario * p.quantidade ELSE 0 END) AS nordeste,

  SUM(CASE 
    WHEN sv.uf IN ('MT','MS','GO','DF')
    THEN pr.preco_unitario * p.quantidade ELSE 0 END) AS "centro-oeste",

  SUM(CASE 
    WHEN sv.uf IN ('SP','RJ','MG','ES')
    THEN pr.preco_unitario * p.quantidade ELSE 0 END) AS sudeste,

  SUM(CASE 
    WHEN sv.uf IN ('PR','SC','RS')
    THEN pr.preco_unitario * p.quantidade ELSE 0 END) AS sul,

  SUM(pr.preco_unitario * p.quantidade) AS "total de vendas"

FROM pedidos p
JOIN filiais f USING (codigo_filial)
JOIN produtos pr USING (codigo_produto)
JOIN staging_vendas sv
  ON sv.nr_pedido = p.nr_pedido
 AND sv.codigo_produto = p.codigo_produto

GROUP BY f.nome_filial;



SELECT * FROM vendas_por_filial_regiao;



--Ver acumulado de vendas por filial e UF:
SELECT 
  f.nome_filial,
  f.uf,
  SUM(pr.preco_unitario * p.quantidade) AS total_vendido
FROM pedidos p
JOIN filiais f USING (codigo_filial)
JOIN produtos pr USING (codigo_produto)
GROUP BY f.nome_filial, f.uf
ORDER BY total_vendido DESC;




