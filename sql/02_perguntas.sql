-- Perguntas de negocio da Controladoria (enunciado, secao 4.4)
USE pncp_controladoria;



-- P1. Qual e o percentual e o valor economizado pelo governo?
SELECT
    SUM(valor_total_homologado) AS volume_homologado,
	SUM(comparavel)                            AS itens_comparaveis,
    COUNT(*)                                   AS total_itens,
    ROUND(100 * SUM(comparavel) / COUNT(*), 2) AS pct_comparaveis,
    SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END) AS estimado_comparavel,
    SUM(economia_valor)                                                     AS economia_rs,
    ROUND(100 * SUM(economia_valor)
          / SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 2) AS economia_pct
FROM fato_item_contratado;

/*
Resultado: 

volume_homologado		itens_comparaveis		total_itens		pct_comparaveis		economia_rs			estimado_comparavel		economia_pct
8044498805.74			5457					6126			89.08				6867663469.91		992861686.95			14.46



-- P2a. Quem sao os 10 maiores fornecedores em volume?
SELECT
    d.nome_fornecedor,
    d.ni_fornecedor,
    SUM(f.valor_total_homologado) AS volume,
    ROUND(100 * SUM(f.valor_total_homologado)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 2) AS pct_do_total
FROM fato_item_contratado f
JOIN dim_fornecedor d ON f.sk_fornecedor = d.sk_fornecedor
GROUP BY d.sk_fornecedor, d.nome_fornecedor, d.ni_fornecedor
ORDER BY volume DESC
LIMIT 10;

/*
Resultados:

nome_fornecedor												ni_fornecedor		volume				pct_do_total
NOW SEGUROS SA												46973571000103		1060000000.00		13.18
CONSTRUTORA CIDADE LIMITADA									92943398000118		524935394.97		6.53
BANCO BRADESCO S.A.											60746948000112		379194320.07		4.71
CONSTRUTORA NORTE BRASIL LTDA.								31596625000191		335401470.80		4.17
LCM CONSTRUCAO E COMERCIO S.A								19758842000135		228885493.53		2.85
CONSTRUTORA OTIMA LTDA										45776055000126		192344816.46		2.39
CONPATE ENGENHARIA LTDA										41320417000119		166644303.41		2.07
INDIGO HIVE CONSULTORIA EM TECNOLOGIA DA INFORMACAO S.A.	38217648000197		160000000.00		1.99
CONSTRUTORA HIDROS LTDA										12066346000171		159193730.62		1.98
ARTELESTE CONSTRUCOES LIMITADA								75911438000120		125884500.00		1.56

- O maior fornecedor sozinho tem 13,18% do volume. 
- 6 dos 10 maiores sao construtoras ou empresas de engenharia.
*/


-- P2b. Quanto os 10 maiores fornecedores concentram do volume total?
SELECT
    ROUND(100 * SUM(volume)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 2) AS pct_top10
FROM (
    SELECT SUM(valor_total_homologado) AS volume
    FROM fato_item_contratado
    GROUP BY sk_fornecedor
    ORDER BY volume DESC
    LIMIT 10
) AS top10;

-- Resultado: 41,43%. Os 10 maiores (de 2.652 fornecedores) concentram 41,43% do volume homologado.



-- P3. Quais modalidades economizam mais e quais concentram mais volume?
SELECT
    m.nome_modalidade,
    SUM(f.valor_total_homologado) AS volume,
    ROUND(100 * SUM(f.valor_total_homologado)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 2) AS pct_volume,
    ROUND(100 * SUM(f.economia_valor)
          / NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0), 2) AS economia_pct,
    ROUND(
        100 * SUM(f.economia_valor)
            / NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0)
        - (SELECT 100 * SUM(economia_valor)
                  / SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END)
           FROM fato_item_contratado),
    1) AS desagio_vs_media_pp
FROM fato_item_contratado f
JOIN dim_modalidade m ON f.sk_modalidade = m.sk_modalidade
GROUP BY m.sk_modalidade, m.nome_modalidade
ORDER BY volume DESC;
/*
Resultados:

nome_modalidade					volume				pct_volume		economia_pct	desagio_vs_media_pp
Concorrência - Eletrônica		4700493122.98		58.43			14.27			-0.2
Credenciamento					2141301557.16		26.62							
Pregão - Eletrônico				502223491.28		6.24			24.02			9.6
Concorrência - Presencial		444752757.18		5.53			6.79			-7.7
Inexigibilidade					213365238.19		2.65			8.77			-5.7
Dispensa						39887350.44			0.50			4.49			-10.0
Pregão - Presencial				2475288.51			0.03			0.02			-14.4

- Pregão - Eletrônico, com 24,02% é a modalidade que mais economiza (quase o dobro da média), mesmo tendo um volume de apenas 6,24%.
- O maior volume é de Concorrência Eletrônica, com 58,43% de volume e economia de 14,27%
- O Credenciamento tem 26,62% do volume total, porém como previsto (regra 6), tem economia vazia. Isso indica que mais de um quarto do valor 
passa por uma modalidade onde a economia não pode ser medida. Limitação importante para a controladoria.
- Pregão Presencial tem 0,02% de economia, mas só 0,03% de volume. A base pode ser pequena demais para maiores conclusões.

*/



-- P4. Qual o ciclo medio (dias) entre publicacao e homologacao, por orgao?
SELECT
    o.nome_orgao,
    COUNT(f.dias_ciclo)          AS itens_com_ciclo,
    ROUND(AVG(f.dias_ciclo), 1)  AS ciclo_medio,
    MAX(f.dias_ciclo)            AS ciclo_maximo
FROM fato_item_contratado f
JOIN dim_orgao o ON f.sk_orgao = o.sk_orgao
GROUP BY o.nome_orgao
HAVING COUNT(f.dias_ciclo) >= 5
ORDER BY ciclo_medio DESC
LIMIT 10;

/*
Resultados:

nome_orgao														itens_com_ciclo		ciclo_medio		ciclo_maximo
UNIVERSIDADE FEDERAL DE CAMPINA GRANDE							16					266.3			309
CONSELHO FEDERAL DE ENGENHARIA E AGRONOMIA						20					223.0			223
DNIT - DEPARTAMENTO NACIONAL DE INFRAEST DE TRANSPORTES			62					156.2			437
UNIVERSIDADE FEDERAL DO ESTADO DO RIO DE JANEIRO				26					135.4			176
INSTITUTO FEDERAL DE EDUCACAO,CIENCIA E TECNOLOGIA DE RONDONIA	9					125.0			226
UNIVERSIDADE FEDERAL DE ALAGOAS									34					108.0			370
INSTITUTO FEDERAL DE EDUCACAO, CIENCIA E TECNOLOGIA DO PARANA	30					107.8			155
UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE						123					101.7			378
CONSELHO REGIONAL DE MEDICINA DO ESTADO DE MINAS GERAIS			6					100.3			111
DEFENSORIA PUBLICA DA UNIAO										11					100.0			154

- Dos 10 órgãos mais lentos, 6 são universidades ou institutos federais.
- O DNIT tem 62 itens e um ciclo máximo de 437 dias.
- O CONFEA tem 20 itens com ciclo medio igual ao maximo (223 dias): todos os itens tiveram o mesmo ciclo,
  provavelmente porque vieram de uma unica compra. Como a media e por item, uma compra lenta com muitos
  itens pesa muito no ranking. "Lento" aqui quer dizer "itens que demoraram", nao necessariamente
  "o orgao e lento em todas as compras".

*/



-- P4b. Ciclo geral (para comparar com os orgaos)
SELECT
    ROUND(AVG(dias_ciclo), 1)        AS ciclo_medio_geral,
    MAX(dias_ciclo)                  AS ciclo_maximo,
    COUNT(dias_ciclo)                AS itens_com_ciclo,
    COUNT(*) - COUNT(dias_ciclo)     AS itens_sem_ciclo
FROM fato_item_contratado;

/*
Resultado: 

ciclo_medio_geral		ciclo_maximo		itens_com_ciclo			itens_sem_ciclo
48.1					611					5896					230

*/



-- P5a. Quais regioes concentram mais despesa e quais tem mais desconto?
SELECT
    l.regiao,
    COUNT(DISTINCT f.sk_orgao)    AS unidades_compradoras,
    SUM(f.valor_total_homologado) AS volume,
    ROUND(100 * SUM(f.valor_total_homologado)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 2) AS pct_volume,
    ROUND(100 * SUM(f.economia_valor)
          / NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0), 2) AS economia_pct
FROM fato_item_contratado f
JOIN dim_localidade l ON f.sk_localidade = l.sk_localidade
GROUP BY l.regiao
ORDER BY volume DESC;

/*
Resultados:

regiao			unidades_compradoras		volume				pct_volume		economia_pct
Centro-Oeste	107							3559879991.73		44.25			17.02
Nordeste		106							1850420285.02		23.00			14.18
Sudeste			120							1083309811.49		13.47			11.62
Sul				65							1021624955.41		12.70			7.96
Norte			59							529263762.09		6.58			21.43

- Maior despesa: Centro-Oeste, com quase metade do volume, por causa de Brasília. E com uma economia acima da média (17,02%).
- Maior desconto: o Norte, com 21,43%, mesmo sendo a região com menos volume (6,58%). O mesmo padrão do Pregão Eletrônico na P3: quem economiza mais não é quem movimenta mais.
- Menor desconto: o Sul, com 7,96%, cerca de metade da média geral (14,46%).
- Sudeste: é a região com mais unidades compradoras (120), mas fica em terceiro no volume. São muitos órgãos com compras menores.

*/




-- P5b. Quais estados concentram mais despesa e quais tem mais desconto?
SELECT
    l.uf_sigla,
    l.uf_nome,
	COUNT(DISTINCT f.sk_orgao)    AS unidades_compradoras,
    SUM(f.valor_total_homologado) AS volume,
    ROUND(100 * SUM(f.valor_total_homologado)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 2) AS pct_volume,
    ROUND(100 * SUM(f.economia_valor)
          / NULLIF(SUM(CASE WHEN f.comparavel = 1 THEN f.valor_total_estimado ELSE 0 END), 0), 2) AS economia_pct
FROM fato_item_contratado f
JOIN dim_localidade l ON f.sk_localidade = l.sk_localidade
GROUP BY l.sk_localidade, l.uf_sigla, l.uf_nome
ORDER BY volume DESC;

/*
Resultados:

uf_sigla	uf_nome						unidades_compradoras		volume				pct_volume		economia_pct
DF			DISTRITO FEDERAL			78							3135638456.35		38.98			15.90
RS			RIO GRANDE DO SUL			31							820584056.64		10.20			7.18
RJ			RIO DE JANEIRO				46							461925602.27		5.74			11.57
PI			PIAUÍ						11							408389525.89		5.08			5.98
SP			SÃO PAULO					41							393783392.48		4.90			9.22
PE			PERNAMBUCO					31							277610822.64		3.45			18.75
CE			CEARÁ						21							273063635.47		3.39			7.88
BA			BAHIA						29							243705954.94		3.03			25.01
MT			MATO GROSSO					15							240920586.26		2.99			25.84
AC			ACRE						9							207336488.34		2.58			26.71
AL			ALAGOAS						10							200475716.34		2.49			16.43
MG			MINAS GERAIS				45							198701363.92		2.47			14.34
RN			RIO GRANDE DO NORTE			20							193722442.76		2.41			16.42
MS			MATO GROSSO DO SUL			16							151844486.73		1.89			12.13
AM			AMAZONAS					19							150043153.77		1.87			14.92
PR			PARANÁ						22							124166989.28		1.54			12.17
MA			MARANHÃO					15							107784353.34		1.34			22.17
PA			PARÁ						21							82949670.30			1.03			19.11
PB			PARAÍBA						15							78243676.65			0.97			16.88
SC			SANTA CATARINA				27							76873909.49			0.96			11.59
SE			SERGIPE						12							67424156.99			0.84			6.47
RR			RORAIMA						7							47718188.56			0.59			19.81
GO			GOIÁS						20							31476462.39			0.39			12.64
ES			ESPÍRITO SANTO				16							28899452.82			0.36			22.64
RO			RONDÔNIA					11							25255010.96			0.31			21.36
AP			AMAPÁ						9							8075852.27			0.10			22.65
TO			TOCANTINS					12							7885397.89			0.10			17.80

- Maior despesa: DF (38,98%), em segundo (longe) Rio Grande do Sul (10,20%).
- RS: é o 2º em volume, mas tem um dos menores descontos (7,18%). Assim como o Piauí (5,08% do volume e 5,98% de economia), são estados com bastante dinheiro e pouco desconto.
- Maiores descontos: Acre (26,71%), Mato Grosso (25,84%) e Bahia (25,01%), todos acima de 25%.
- Amapá e Tocantins: têm 22,65% e 17,80% de economia, mas só 0,10% do volume cada. Com tão pouco dinheiro, uma única compra muda o percentual. É o mesmo ponto de atenção do Pregão Presencial na P3.

*/



-- P6. Como os recursos se distribuem entre bens, servicos e obras?
SELECT
    perfil_gasto,
    COUNT(*)                     AS itens,
    ROUND(100 * COUNT(*)
          / (SELECT COUNT(*) FROM fato_item_contratado), 2) AS pct_itens,
    SUM(valor_total_homologado)  AS volume,
    ROUND(100 * SUM(valor_total_homologado)
          / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 1) AS pct_volume,
    ROUND(SUM(valor_total_homologado) / COUNT(*), 2) AS ticket_medio,
    ROUND(100 * SUM(economia_valor)
          / NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0), 2) AS economia_pct
FROM fato_item_contratado
GROUP BY perfil_gasto
ORDER BY volume DESC;

/*

Resultados:

perfil_gasto			itens		pct_itens		volume				pct_volume		ticket_medio		economia_pct
Obras e engenharia		967			15.79			4892362732.70		60.8			5059320.30			14.17
Serviços				1849		30.18			2940950885.18		36.6			1590562.94			16.11
Bens					3310		54.03			211185187.86		2.6				63802.17			14.19

- Obras e engenharia: a menor quantidade de itens e a maior fatia do dinheiro. Poucos contratos, de valor muito alto.
- Bens: mais da metade dos itens da fato, e só 2,6% do volume. Muitas compras pequenas.
- Controladoria: fiscalizar poucas obras cobre a maior parte do dinheiro público. Esse dado combina com a P2: 6 dos 10 maiores fornecedores são construtoras.

*/
