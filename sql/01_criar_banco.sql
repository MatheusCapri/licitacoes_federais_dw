-- criação database
CREATE DATABASE IF NOT EXISTS pncp_controladoria;
USE pncp_controladoria;

-- drop das tabelas para que o script possa rodar mais de uma vez
DROP TABLE IF EXISTS fato_item_contratado;
DROP TABLE IF EXISTS dim_orgao;
DROP TABLE IF EXISTS dim_fornecedor;
DROP TABLE IF EXISTS dim_modalidade;
DROP TABLE IF EXISTS dim_localidade;

-- dim_modalidade: 
CREATE TABLE dim_modalidade(
    sk_modalidade               INT PRIMARY KEY,
    modalidade_id               INT NOT NULL    UNIQUE,
    nome_modalidade             VARCHAR(50) NOT NULL
) ENGINE=InnoDB;


-- dim_orgao:
CREATE TABLE dim_orgao(
    sk_orgao                    INT PRIMARY KEY,
    cnpj_orgao                  VARCHAR(14) NOT NULL UNIQUE,
    nome_orgao                  VARCHAR(255) NOT NULL,
    poder                       VARCHAR(50) NOT NULL
) ENGINE=InnoDB;


-- dim_fornecedor:
CREATE TABLE dim_fornecedor(
    sk_fornecedor               INT PRIMARY KEY,
    ni_fornecedor               VARCHAR(20) NOT NULL UNIQUE,
    nome_fornecedor             VARCHAR(255) NOT NULL,
    tipo_pessoa                 VARCHAR(2) NOT NULL,
    porte                       VARCHAR(50)
) ENGINE=InnoDB;


-- dim_localidade:
CREATE TABLE dim_localidade(
    sk_localidade               INT PRIMARY KEY,
    uf_sigla                    VARCHAR(2) NOT NULL UNIQUE,
    uf_nome                     VARCHAR(50) NOT NULL,
    regiao                      VARCHAR(50) NOT NULL
) ENGINE=InnoDB;


-- fato_item_contratado:
CREATE TABLE fato_item_contratado(
    sk_fato                     INT AUTO_INCREMENT,
    numero_controle_pncp        VARCHAR(30) NOT NULL,
    numero_item                 INT  NOT NULL,
    sk_orgao                    INT  NOT NULL,
    sk_fornecedor               INT  NOT NULL,
    sk_modalidade               INT  NOT NULL,
    sk_localidade               INT  NOT NULL,
    data_publicacao             DATE NOT NULL,
    data_homologacao            DATE,
    descricao_item              TEXT NOT NULL,
    perfil_gasto                VARCHAR(30)     NOT NULL,
    quantidade                  DECIMAL(18,4)   NOT NULL,
    valor_unitario_estimado     DECIMAL(18,4)   NOT NULL,
    valor_total_estimado        DECIMAL(18,2)   NOT NULL,
    valor_unitario_homologado   DECIMAL(18,4)   NOT NULL,
    valor_total_homologado      DECIMAL(18,2)   NOT NULL,
    comparavel                  TINYINT         NOT NULL,
    economia_valor              DECIMAL(18,2),
    dias_ciclo                  INT,

    CONSTRAINT pk_fato PRIMARY KEY (sk_fato),
    CONSTRAINT uk_fato_item UNIQUE (numero_controle_pncp, numero_item),

    CONSTRAINT fk_fato_orgao
        FOREIGN KEY (sk_orgao)
        REFERENCES dim_orgao (sk_orgao),
    
    CONSTRAINT fk_fato_fornecedor
        FOREIGN KEY (sk_fornecedor)
        REFERENCES dim_fornecedor (sk_fornecedor),

    CONSTRAINT fk_fato_modalidade
        FOREIGN KEY (sk_modalidade)
        REFERENCES dim_modalidade (sk_modalidade),

    CONSTRAINT fk_fato_localidade
        FOREIGN KEY (sk_localidade)
        REFERENCES dim_localidade (sk_localidade),

    CONSTRAINT chk_quantidade                   CHECK (quantidade   > 0),
    CONSTRAINT chk_valor_unitario_estimado      CHECK (valor_unitario_estimado >= 0),
    CONSTRAINT chk_valor_total_estimado         CHECK (valor_total_estimado >= 0),
    CONSTRAINT chk_valor_unitario_homologado    CHECK (valor_unitario_homologado >= 0),
    CONSTRAINT chk_valor_total_homologado       CHECK (valor_total_homologado >= 0)


) ENGINE=InnoDB;