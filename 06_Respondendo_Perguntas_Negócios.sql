-- Respondendo perguntas de negócio utilizando Funçoes de Agregação, Subquerys, CTE e Funções Window

SELECT * FROM ecommerce.analise_ecommerce;

-- Qual total de vendas feita por ano?
SELECT EXTRACT(YEAR FROM data_venda) AS ano,
	   SUM(valor_venda) total_vendas,
	   SUM(quantidade) qtde
FROM ecommerce.analise_ecommerce 
GROUP BY ano
ORDER BY ano;


-- Quais os produtos vendidos por ano e propocional de vendas
SELECT EXTRACT(YEAR FROM data_venda) AS ano,
	   nome_produto,
	   SUM(valor_total_desconto) AS valor_total,
	   SUM(SUM(valor_total_desconto)) OVER (PARTITION BY EXTRACT(YEAR FROM data_venda)) AS total_vendas_ano,
	   ROUND(SUM(valor_total_desconto) / SUM(SUM(valor_total_desconto)) OVER (PARTITION BY EXTRACT(YEAR FROM data_venda)) * 100, 2) AS proporcional_vendas_ano
FROM ecommerce.analise_ecommerce 
GROUP BY ano, nome_produto
ORDER BY ano;


-- Quais os produtos vendidos por cidade, ano e propocional de vendas
SELECT EXTRACT(YEAR FROM data_venda) AS ano,
	   cidade,
	   SUM(valor_total_desconto) AS valor_total,
	   SUM(SUM(valor_total_desconto)) OVER (PARTITION BY EXTRACT(YEAR FROM data_venda)) AS total_vendas_ano,
	   ROUND(SUM(valor_total_desconto) / SUM(SUM(valor_total_desconto)) OVER (PARTITION BY EXTRACT(YEAR FROM data_venda)) * 100, 2) AS proporcional_vendas_ano
FROM ecommerce.analise_ecommerce 
GROUP BY cidade, ano
ORDER BY ano, cidade;


-- Quantos clientes compram por site e realizam mais de uma compra ?
SELECT DISTINCT(id_cliente), COUNT(*) AS total_clientes
FROM ecommerce.analise_ecommerce
WHERE canal_venda = 'Site'
GROUP BY id_cliente
HAVING COUNT(id_cliente) > 1;


-- Quais produtos foram comprados por meio do mercado livre e tiveram um feedback acima de 4 ?
SELECT id_cliente, 
       cidade,
	   nome_produto, 
	   feedback_venda
FROM ecommerce.analise_ecommerce
WHERE canal_venda = 'Mercado Livre' AND feedback_venda > 4
GROUP BY id_cliente, nome_produto, feedback_venda, cidade
ORDER BY feedback_venda, cidade, nome_produto;


-- Qual é o produto top 1 de vendas por cidade?
SELECT * 
       FROM ( SELECT EXTRACT(YEAR FROM data_venda) as ano,
	   		  cidade, 
			  nome_produto,
	   		  valor_total_desconto AS total_vendas,
	   		  RANK() OVER (PARTITION BY cidade ORDER BY valor_total_desconto DESC) AS rank_vendas
			  FROM ecommerce.analise_ecommerce) AS subquery
WHERE rank_vendas = 1
	
	
-- Qual é o top 3 vendas por cidade no ano de 2022?
SELECT * 
       FROM ( SELECT EXTRACT(YEAR FROM data_venda) as ano,
	   		  cidade, 
			  nome_produto,
	   		  valor_total_desconto AS total_vendas,
	   		  DENSE_RANK() OVER (PARTITION BY cidade ORDER BY valor_total_desconto DESC) AS rank_vendas
			  FROM ecommerce.analise_ecommerce
			  WHERE EXTRACT(YEAR FROM data_venda) = 2022) AS subquery
WHERE rank_vendas IN (1, 2, 3)


-- Comparação de venda anterior com a atual por ano e mês
SELECT EXTRACT(YEAR FROM data_venda) AS ano,
	   EXTRACT(MONTH FROM data_venda) AS mes,
	   SUM(valor_total_desconto) AS total_venda_mes,
	   COALESCE(CAST(LAG(SUM(valor_total_desconto)) OVER (ORDER BY EXTRACT(YEAR FROM data_venda), 
												 EXTRACT(MONTH FROM data_venda)) AS VARCHAR), 'Sem Dados')  AS total_venda_anterior
FROM ecommerce.analise_ecommerce
GROUP BY ano, mes;


-- Quais clientes tiveram o feedback abaixo da média?
WITH feedback AS (
SELECT id_cliente,
	   COUNT(*) AS total_compra_cliente,
	   cidade,
	   feedback_venda,
	   ROUND(AVG(feedback_venda),2) AS media_feedback_cliente,
	   ROUND(AVG(feedback_venda) OVER(), 2) AS media_feedback
FROM ecommerce.analise_ecommerce
GROUP BY cidade, id_cliente, feedback_venda
)
SELECT id_cliente, cidade, feedback_venda
FROM feedback
WHERE media_feedback_cliente < media_feedback
ORDER BY cidade;

