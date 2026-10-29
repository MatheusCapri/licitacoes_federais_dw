# Licitações Federais 2025: pipeline de dados e data warehouse de compras públicas

> * Projeto em construção. As seções marcadas como *(em construção)* serão preenchidas ao longo das Sprints.

## Contexto

*(em construção)*

## Ferramentas

- Python 3 (pandas)
- MySQL 8.0 e MySQL Workbench
- Power BI Desktop
- Git e GitHub
- VS Code com Jupyter (notebook de auditoria)

## Estrutura do repositório

```
licitacoes_federais_dw/
├── README.md
├── requirements.txt
├── .env.example            # modelo das variáveis de conexão (o .env real não vai para o GitHub)
├── data/
│   └── raw/                # base bruta do PNCP 2025 (compras, itens, resultados), sem alteração
├── notebooks/
│   └── 01_auditoria.ipynb  # levantamento e contagem dos problemas da base bruta
├── src/                    # scripts Python do pipeline (limpeza, montagem das tabelas, carga)
├── sql/                    # criação do banco e perguntas de negócio
├── powerbi/                # dashboard
├── reports/                # logs e relatórios gerados pelo pipeline
└── docs/
    └── img/                # figuras do README (Sprints, modelo dimensional)
```

## Como executar

*(em construção)*

## Arquitetura

*(em construção)*

## Modelo dimensional

*(em construção)*

## Diagnóstico da origem

Antes de qualquer tratamento, a base bruta foi auditada no notebook [`notebooks/01_auditoria.ipynb`](notebooks/01_auditoria.ipynb). Os arquivos foram lidos sem nenhuma conversão automática (tudo como texto e sem transformar `N/A` ou `NULL` em vazio), para contar os problemas exatamente como chegaram. Cada número abaixo é gerado por uma célula do notebook.

### Tamanho e chaves

| Item | Valor |
|---|---|
| Linhas em `compras.csv` / `itens.csv` / `resultados.csv` | 2.042 / 7.077 / 15.896 |
| Contratações repetidas em `compras` | 0 |
| Itens repetidos em `itens` (`numero_controle_pncp` + `numero_item`) | 0 |
| Itens sem nenhum resultado (`tem_resultado = False`) | 852 |
| Itens com mais de um fornecedor classificado | 466 (o maior chega a 1.773) |
| Resultados cancelados (`data_cancelamento` preenchida) | 62 |

### Dicionário das inconsistências

| Problema (desafio do enunciado) | Onde aparece | Registros afetados | Como é tratado (`src/limpeza.py`) |
|---|---|---|---|
| Número em texto que o pandas não lê direto (2) | 6 colunas de quantidade e valor | de 1.481 (20,9%) a 3.832 (24,1%) por coluna | `converter_numero` |
| `R$` dentro do número (2) | `itens.valor_unitario_estimado` / `itens.quantidade` | 1.188 / 1.148 | `converter_numero` |
| Separadores misturados: `9,9`, `9.9,9` e `9,9.9` (2) | colunas de quantidade e valor | ver notebook, seção 4 | `converter_numero` |
| Espaço invisível (`\xa0`) (2) | `itens.valor_unitario_estimado` / `itens.quantidade` | 301 / 264 | `remover_invisiveis` e `tirar_espacos` |
| Espaço no começo do valor (2) | `itens.valor_unitario_estimado` / `itens.quantidade` | 260 / 287 | `tirar_espacos` |
| Data em 7 formatos no mesmo campo (3) | `compras.data_publicacao` / `resultados.data_resultado` | 7 formatos em cada coluna | `converter_data` |
| Data no padrão dia/mês/ano (3) | `compras.data_publicacao` / `resultados.data_resultado` | 501 / 3.712 | `converter_data` |
| Data colada, sem separador (`20250103`) (3) | `compras.data_publicacao` / `resultados.data_resultado` | 106 / 923 | `converter_data` |
| Homologação antes da publicação (3) | `resultados.data_resultado` | 234 resultados | regra 7 |
| CNPJ com máscara (1) | `compras.cnpj_orgao` | 176 | `limpar_documento` |
| CNPJ com zeros perdidos (12, 13 ou 11 dígitos) (1) | `compras.cnpj_orgao` | 64, 10 e 3 | `limpar_documento` (`.zfill`) |
| CNPJ de fornecedor com zeros perdidos (13, 12 ou 11 dígitos) (1) | `resultados.ni_fornecedor`, PJ | 175, 18 e 1 | `limpar_documento` (`.zfill`) |
| CPF com zeros perdidos (10, 9 ou 8 dígitos) (1) | `resultados.ni_fornecedor`, PF | 154, 4 e 1 | `limpar_documento` (`.zfill`) |
| Documento de estrangeiro sem padrão (1) | `resultados.ni_fornecedor`, PE | 21 | `limpar_documento` (só limpa espaços e põe em maiúsculas) |
| Nulo disfarçado em 10 grafias (`N/A`, `NULL`, `-`, `0`, `Não Informado`...) (4) | `resultados.porte` | 4.893 (30,8%) | `limpar_texto` e `eh_nulo` |
| Nulo disfarçado (4) | `compras.processo` / `compras.modo_disputa` | 77 / 967 | `limpar_texto` e `eh_nulo` |
| Nulo disfarçado (4) | `itens.situacao_item` / `itens.criterio_julgamento` | 220 / 1.883 | `limpar_texto` e `eh_nulo` |
| Coluna inteira sem informação (`Não se aplica`) (4) | `itens.categoria_item` | 7.077 (todas as linhas) | `limpar_texto` e `eh_nulo` |
| Acento quebrado (`BrasÃ­lia`) (5) | `compras.objeto_compra` / `municipio` / `nome_unidade` | 43 / 28 / 14 | `consertar_acento` |
| Acento quebrado (5) | `itens.descricao` / `resultados.nome_fornecedor` | 116 / 1 | `consertar_acento` |

**Achados importantes:**

- **A primeira análise escondia um problema nas datas.** Trocando cada *bloco* de dígitos por 9, `2025/01/08` e `08/01/2025` viravam o mesmo formato (`9/9/9`). O problema só apareceu quando o maior valor da primeira parte deu 2025. Trocando cada *dígito* por 9, surgiram os dois padrões, e a ordem dia/mês foi provada pelo maior valor de cada parte (o dia chega a 31; o mês não passa de 12).
- **O porte da empresa falta em quase um terço dos resultados** (30,8%), escrito de 10 jeitos diferentes. Sem a limpeza, o "sem informação" seriam 10 categorias falsas.
- **Acento quebrado em colunas que viram dimensão** (`municipio`, `nome_unidade`, `nome_fornecedor`) duplicaria registros: `Brasília` e `BrasÃ­lia` seriam vistos como dois municípios diferentes.

## Decisões técnicas

- **Economia vazia nos itens não comparáveis:** o código do kit (`src/montar_tabelas.py`, etapa 6) gravava `economia_valor = 0` nos itens não comparáveis, mas o enunciado (seção 4.3) pede que esse campo fique vazio. A regra foi mantida; o que mudou foi o código, para seguir o enunciado. O zero diria "não houve economia"; o vazio diz "não é possível calcular" (como num credenciamento). O percentual de economia não muda, porque só soma os itens comparáveis.
- **Carga em uma transação só:** o kit gravava (commit) cada tabela separadamente; se a fato falhasse, as dimensões ficariam no banco sem a fato. A função `inserir_em_lote` (`src/banco.py`) ganhou o parâmetro `confirmar`, e o `src/carregar.py` passou a dar um único commit no fim, com rollback se qualquer etapa falhar. Teste: com o nome da fato trocado de propósito, a carga falhou e a `dim_orgao` ficou com 0 linhas no banco.
- **Sem CHECK na economia:** a fato recusa quantidade ≤ 0 e valores negativos, mas `economia_valor` pode ser negativa: são os itens com sobrepreço (homologado acima do estimado), uma informação que a Controladoria precisa ver.
- **Sem linha −1 "Não informado":** todas as chaves estrangeiras da fato encontraram a sua linha nas dimensões (a carga com as FKs ativas não recusou nenhum item), então a linha −1 não foi necessária, como prevê o enunciado (4.3).

## Perguntas de negócio

As consultas estão em [`sql/02_perguntas.sql`](sql/02_perguntas.sql), cada uma com o resultado e a leitura logo abaixo. Os números das perguntas 1, 4 e 6 conferem com a prova real do enunciado (seção 8).

**Termos usados:** *volume* é a soma do valor total homologado de todos os itens da fato. *Economia* (ou *deságio*) é o estimado menos o homologado, calculada só nos itens comparáveis (regra 6), e o percentual é a soma da economia dividida pela soma do estimado comparável.

### P1. Qual é o percentual e o valor economizado pelo governo?

| Indicador | Valor |
|---|---|
| Estimado da base comparável | R$ 6.867.663.469,91 |
| Economia | R$ 992.861.686,95 |
| Economia % | 14,46% |

**Conclusão:** nos itens em que a comparação é possível, o governo pagou 14,46% abaixo do estimado, uma economia de R$ 992.861.686,95.

### P2. Quem são os maiores fornecedores e quanto do orçamento está concentrado neles?

| # | Fornecedor | Volume | % do volume |
|---|---|---|---|
| 1 | NOW SEGUROS SA | R$ 1.060.000.000,00 | 13,18% |
| 2 | CONSTRUTORA CIDADE LIMITADA | R$ 524.935.394,97 | 6,53% |
| 3 | BANCO BRADESCO S.A. | R$ 379.194.320,07 | 4,71% |
| 4 | CONSTRUTORA NORTE BRASIL LTDA. | R$ 335.401.470,80 | 4,17% |
| 5 | LCM CONSTRUCAO E COMERCIO S.A | R$ 228.885.493,53 | 2,85% |

Os 10 maiores juntos concentram **41,43%** do volume (ranking completo no arquivo SQL).

**Conclusão:** a concentração é alta: 10 dos 2.652 fornecedores ficam com 41,43% do volume, e o maior, sozinho, com 13,18%. Seis dos dez maiores são construtoras ou empresas de engenharia. Para a Controladoria, isso é um risco de dependência: um problema com poucos fornecedores afeta uma parte grande das compras públicas.

### P3. Quais modalidades economizam mais e quais concentram mais volume?

| Modalidade | Volume | % do volume | Economia % |
|---|---|---|---|
| Concorrência - Eletrônica | R$ 4.700.493.122,98 | 58,43% | 14,27% |
| Credenciamento | R$ 2.141.301.557,16 | 26,62% | (não se aplica) |
| Pregão - Eletrônico | R$ 502.223.491,28 | 6,24% | 24,02% |
| Concorrência - Presencial | R$ 444.752.757,18 | 5,53% | 6,79% |
| Inexigibilidade | R$ 213.365.238,19 | 2,65% | 8,77% |
| Dispensa | R$ 39.887.350,44 | 0,50% | 4,49% |
| Pregão - Presencial | R$ 2.475.288,51 | 0,03% | 0,02% |

**Conclusão:** a Concorrência Eletrônica concentra o volume (58,43%), com economia próxima da média geral (14,27%). O Pregão Eletrônico é a modalidade que mais economiza (24,02%, quase o dobro da média), mesmo com apenas 6,24% do volume. O Credenciamento movimenta 26,62% do volume, mas não tem economia mensurável (regra 6): mais de um quarto do dinheiro passa por uma modalidade em que o desconto não pode ser medido. O Pregão Presencial tem volume pequeno demais (0,03%) para conclusões.

### P4. Qual o tempo médio entre a publicação do edital e a homologação, por órgão?

**Visão geral:** ciclo médio de **48,1 dias**, máximo de **611 dias**, 5.896 itens com ciclo e 230 sem ciclo (homologação anterior à publicação, anulada pela regra 7).

Os 5 órgãos mais lentos (com 5 ou mais itens com ciclo, agrupados pelo nome):

| Órgão | Itens com ciclo | Ciclo médio (dias) | Ciclo máximo (dias) |
|---|---|---|---|
| UNIVERSIDADE FEDERAL DE CAMPINA GRANDE | 16 | 266,3 | 309 |
| CONSELHO FEDERAL DE ENGENHARIA E AGRONOMIA | 20 | 223,0 | 223 |
| DNIT - DEPARTAMENTO NACIONAL DE INFRAEST DE TRANSPORTES | 62 | 156,2 | 437 |
| UNIVERSIDADE FEDERAL DO ESTADO DO RIO DE JANEIRO | 26 | 135,4 | 176 |
| INSTITUTO FEDERAL DE EDUCACAO,CIENCIA E TECNOLOGIA DE RONDONIA | 9 | 125,0 | 226 |

**Conclusão:** os 10 órgãos mais lentos têm ciclo médio de 100 dias ou mais, mais que o dobro da média geral. Seis deles são universidades ou institutos federais. Ponto de atenção: a média é calculada por item, então uma única compra lenta com muitos itens pesa muito no ranking. No Conselho Federal de Engenharia e Agronomia, por exemplo, o ciclo médio é igual ao máximo (223 dias): todos os 20 itens tiveram o mesmo ciclo, provavelmente por virem da mesma compra.

### P5. Quais estados e regiões concentram mais despesa e quais têm melhores descontos?

| Região | Unidades compradoras | Volume | % do volume | Economia % |
|---|---|---|---|---|
| Centro-Oeste | 107 | R$ 3.559.879.991,73 | 44,25% | 17,02% |
| Nordeste | 106 | R$ 1.850.420.285,02 | 23,00% | 14,18% |
| Sudeste | 120 | R$ 1.083.309.811,49 | 13,47% | 11,62% |
| Sul | 65 | R$ 1.021.624.955,41 | 12,70% | 7,96% |
| Norte | 59 | R$ 529.263.762,09 | 6,58% | 21,43% |

Por estado (tabela completa com as 27 UFs no arquivo SQL):

| UF | Volume | % do volume | Economia % |
|---|---|---|---|
| DF | R$ 3.135.638.456,35 | 38,98% | 15,90% |
| RS | R$ 820.584.056,64 | 10,20% | 7,18% |
| RJ | R$ 461.925.602,27 | 5,74% | 11,57% |
| PI | R$ 408.389.525,89 | 5,08% | 5,98% |
| SP | R$ 393.783.392,48 | 4,90% | 9,22% |

**Conclusão:** o Centro-Oeste concentra quase metade do volume (44,25%), puxado pelo Distrito Federal (38,98%), sede da maior parte dos órgãos federais, e ainda tem economia acima da média (17,02%). O maior desconto regional é o do Norte (21,43%), justamente a região com menos volume (6,58%), e o menor é o do Sul (7,96%). Entre os estados, os maiores descontos são do Acre (26,71%), de Mato Grosso (25,84%) e da Bahia (25,01%). O Rio Grande do Sul é o 2º em volume, mas tem um dos menores descontos (7,18%). Estados com volume muito pequeno, como Amapá e Tocantins (0,10% cada), têm percentuais pouco confiáveis: uma única compra muda o resultado. Observação: a UF vem da compra, e uma mesma unidade compradora pode ter compras em mais de uma UF, por isso as unidades das regiões não devem ser somadas.

### P6. Como os recursos se distribuem entre bens, serviços e obras?

| Perfil | Itens | Volume | % do volume | Ticket médio por item |
|---|---|---|---|---|
| Obras e engenharia | 967 | R$ 4.892.362.732,70 | 60,8% | R$ 5.059.320,30 |
| Serviços | 1.849 | R$ 2.940.950.885,18 | 36,6% | R$ 1.590.562,94 |
| Bens | 3.310 | R$ 211.185.187,86 | 2,6% | R$ 63.802,17 |

**Conclusão:** obras e engenharia têm a menor quantidade de itens e a maior fatia do dinheiro (60,8%): poucos contratos, de valor muito alto. Bens são mais da metade dos itens, mas só 2,6% do volume. Para a Controladoria, fiscalizar poucas obras cobre a maior parte do dinheiro público, o que combina com a P2, em que seis dos dez maiores fornecedores são construtoras.

## Planejamento em Sprints

*(em construção)*

## Melhorias futuras

- **Documentos de fornecedores estrangeiros:** a função `limpar_documento` do kit não altera documentos de estrangeiros (`tipo_pessoa = PE`), além de limpar espaços. Com isso, `ESTRANG0002421` e `ES.TRA.NG0/0024-21` continuam diferentes e o mesmo fornecedor pode aparecer duas vezes. São 21 linhas; a regra foi mantida, como pede o enunciado, e a melhoria fica registrada aqui.

- **Números de documento no nome do fornecedor:** alguns fornecedores, normalmente microempreendedores, têm número de documento no nome (a raiz do CNPJ no início ou o CPF no fim), já que a razão social está registrada assim. A função `padronizar_nome` do kit não elimina os números, e a regra foi mantida, como pede o enunciado. Isso não duplica fornecedores, porque a dimensão é montada pelo documento. Apesar de a base ser pública, retirar do nome esses números, que já estão em `ni_fornecedor`, seguiria melhor o princípio da necessidade da LGPD e evitaria que o CPF aparecesse no dashboard.

## Vídeo

*(em construção)*

## Fonte dos dados

Portal Nacional de Contratações Públicas (PNCP), contratações federais de 2025. Arquivos brutos fornecidos no Projeto Final do Módulo 2 do curso SC TEC (SENAI SC), Análise de Dados com Python.

## Autor

**Matheus Capri**
[LinkedIn](https://www.linkedin.com/in/matheus-capri-nery-215a3737) · [GitHub](https://github.com/MatheusCapri)
