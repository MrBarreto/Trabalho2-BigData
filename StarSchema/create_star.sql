------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------

CREATE TABLE DimEmpresa_Dona (
    ID_Empresa_Dona INT PRIMARY KEY,
    CNPJ_Empresa VARCHAR(18) UNIQUE NOT NULL,
    Nome_Empresa VARCHAR(255) NOT NULL,
    Endereco_Empresa VARCHAR(255)
);

CREATE TABLE DimVeiculo (
    ID_VEICULO INT PRIMARY KEY,
    Placa VARCHAR(10) UNIQUE NOT NULL,
    Chassi VARCHAR(17) UNIQUE NOT NULL,
    Grupo VARCHAR(50),
    Modelo VARCHAR(100),
    Marca VARCHAR(100),
    Cor VARCHAR(50),
    AC BOOLEAN DEFAULT FALSE,
    Crianca BOOLEAN DEFAULT FALSE,
    Bebe BOOLEAN DEFAULT FALSE,
    Teto_solar BOOLEAN DEFAULT FALSE,
    Multimidia BOOLEAN DEFAULT FALSE
);

CREATE TABLE DimEstado_Veiculo (
    ID_ESTADO_VEICULO INT PRIMARY KEY,
    Pressao_Pneu FLOAT,
    Nivel_Oleo VARCHAR(50),
    Gasolina VARCHAR(50),
    Quilometragem FLOAT,
    Motor VARCHAR(100),
    Freios VARCHAR(100),
    Estado_Pneu VARCHAR(100),
    Vidros VARCHAR(100),
    Bateria VARCHAR(100),
    Estepe VARCHAR(100),
    Pintura VARCHAR(100),
    Retrovisor VARCHAR(100),
    Limpador_Parabrisa VARCHAR(100),
    Data_Revisao DATE NOT NULL,
);

CREATE TABLE DimPessoa (
    ID_Pessoa INT PRIMARY KEY,
    Nome VARCHAR(255) NOT NULL,
    CPF VARCHAR(14) NOT NULL,
    CNH VARCHAR(20) NOT NULL,
    Categoria_CNH VARCHAR(5),
    Endereco VARCHAR(255),
    Nacionalidade VARCHAR(50),
    Data_Nascimento DATE,
    Data_Expedicao_CNH DATE,
    ID_Empresa INT,
    Nome_empresa VARCHAR(255),
    CNPJ VARCHAR(18),
    Endereco_Empresa VARCHAR(255)
);

CREATE TABLE DimSeguro (
    ID_SEGUROS INT PRIMARY KEY,
    Vidros VARCHAR(255),
    Farois VARCHAR(255),
    Faixa_Indenizacao VARCHAR(100)
);

CREATE TABLE DimVaga (
    ID_Vaga INT PRIMARY KEY,
    ID_PATIO INTEGER NOT NULL,
    Endereco_Patio VARCHAR(255) NOT NULL,
    ID_Empresa INT NOT NULL,
    CNPJ_Empresa VARCHAR(18) NOT NULL,
    Nome_Empresa VARCHAR(255) NOT NULL,
    Endereco_Empresa VARCHAR(255) NOT NULL
);

CREATE TABLE FatoLocacao (
    ID_LOCACAO INT PRIMARY KEY,
    Data_Retirada DATE NOT NULL,
    Data_Devolucao DATE NOT NULL,
    Vaga_Retirada INT NOT NULL,
    Vaga_Devolucao INT NOT NULL,
    ID_Pessoa INT NOT NULL,
    ID_ESTADO_VEICULO_Retirada INT NOT NULL,
    ID_ESTADO_VEICULO_Devolucao INT NOT NULL,
    ID_SEGUROS INT,
    ID_EMPRESA_Dona INT NOT NULL,
    ID_VEICULO INT NOT NULL,
    ID_RESERVA INT,
    
    CONSTRAINT FK_Locacao_Vaga_Retirada FOREIGN KEY (Vaga_Retirada)
        REFERENCES DimVaga(ID_Vaga)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Vaga_Devolucao FOREIGN KEY (Vaga_Devolucao)
        REFERENCES DimVaga(ID_Vaga)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Pessoa FOREIGN KEY (ID_Pessoa)
        REFERENCES DimPessoa(ID_Pessoa)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Estado_Retirada FOREIGN KEY (ID_ESTADO_VEICULO_Retirada)
        REFERENCES DimEstado_Veiculo(ID_ESTADO_VEICULO)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Estado_Devolucao FOREIGN KEY (ID_ESTADO_VEICULO_Devolucao)
        REFERENCES DimEstado_Veiculo(ID_ESTADO_VEICULO)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Seguro FOREIGN KEY (ID_SEGUROS)
        REFERENCES DimSeguro(ID_SEGUROS)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Locacao_Empresa FOREIGN KEY (ID_EMPRESA_Dona)
        REFERENCES DimEmpresa_Dona(ID_Empresa_Dona)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_Locacao_Veiculo FOREIGN KEY (ID_VEICULO)
        REFERENCES DimVeiculo(ID_VEICULO)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE FatoReserva (
    ID_RESERVA INT PRIMARY KEY,
    ID_Pessoa INT NOT NULL,
    ID_VEICULO INT NOT NULL,
    ID_Vaga_Retirada INT NOT NULL,
    Data_Retirada_Prevista DATE NOT NULL,
    Data_Devolucao_Prevista DATE NOT NULL,

    CONSTRAINT FK_Reserva_Pessoa FOREIGN KEY (ID_Pessoa)
        REFERENCES DimPessoa(ID_Pessoa),
    CONSTRAINT FK_Reserva_Veiculo FOREIGN KEY (ID_VEICULO)
        REFERENCES DimVeiculo(ID_VEICULO),
    CONSTRAINT FK_Reserva_Vaga FOREIGN KEY (ID_Vaga_Retirada)
        REFERENCES DimVaga(ID_Vaga)
);