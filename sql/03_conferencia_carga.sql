-- volume homologado (prova real: 8.044.498.805,74)
SELECT SUM(valor_total_homologado) FROM fato_item_contratado;

-- vazios da regra 7 e da economia (prova real: 230 sem ciclo; 669 nao comparaveis)
SELECT COUNT(*) - COUNT(dias_ciclo)     AS sem_ciclo,
       COUNT(*) - COUNT(economia_valor) AS sem_economia
FROM fato_item_contratado;