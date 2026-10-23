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
| Homologação antes da publicação (3) | `resultados.data_resultado` | *(em construção: medido depois da limpeza das datas)* | regra 7 |
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

*(em construção)*

## Perguntas de negócio

*(em construção)*

## Planejamento em Sprints

*(em construção)*

## Melhorias futuras

- **Documentos de fornecedores estrangeiros:** a função `limpar_documento` do kit não altera documentos de estrangeiros (`tipo_pessoa = PE`), além de limpar espaços. Com isso, `ESTRANG0002421` e `ES.TRA.NG0/0024-21` continuam diferentes e o mesmo fornecedor pode aparecer duas vezes. São 21 linhas; a regra foi mantida, como pede o enunciado, e a melhoria fica registrada aqui.

## Vídeo

*(em construção)*

## Fonte dos dados

Portal Nacional de Contratações Públicas (PNCP), contratações federais de 2025. Arquivos brutos fornecidos no Projeto Final do Módulo 2 do curso SC TEC (SENAI SC), Análise de Dados com Python.

## Autor

**Matheus Capri**
[LinkedIn](https://www.linkedin.com/in/matheus-capri-nery-215a3737) · [GitHub](https://github.com/MatheusCapri)
