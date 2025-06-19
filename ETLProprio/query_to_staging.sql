-- Criando uma tabela temporaria comm as locações do dia
CREATE TEMP TABLE locacoes_do_dia AS
SELECT 
    ID_LOCACAO,
    Data_Retirada,
    Data_Devolucao,
    Vaga_Retirada::INT,
    Vaga_Devolucao::INT,
    ID_PF,
    ID_ESTADO_VEICULO_Retirada,
    ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS, 
    ID_RESERVA
FROM public.LOCACAO
WHERE 
    Data_Devolucao >= CURRENT_DATE - INTERVAL '1 day'
    AND Data_Devolucao < CURRENT_DATE;

--Criando uma tabela temporária para verificar os carros alugados no dia
CREATE TEMP TABLE carros_do_dia AS
SELECT DISTINCT
    ID_VEICULO
FROM public.RESERVA rsv
WHERE rsv.ID_RESERVA IN (
    SELECT ID_RESERVA
    FROM locacoes_do_dia
);

-- Criando uma tabela temporaria para armazenar os clientes PJs do dia 
CREATE TEMP TABLE clientesPJ_do_dia AS
SELECT DISTINCT 
    ID_PJ
FROM public.PF PF 
WHERE PF.ID_PF IN (
    SELECT ID_PF
    FROM locacoes_do_dia
);

-- Criando uma tabela tempooraria para armazenar os pátios visitados no ultimo dia 
CREATE TEMP TABLE Patios_do_dia AS
SELECT DISTINCT 
    ID_PATIO
FROM public.VAGAS VG 
WHERE VG.ID_VAGAS IN (
    SELECT Vaga_Retirada FROM locacoes_do_dia
    UNION
    SELECT Vaga_Devolucao FROM locacoes_do_dia
);

--Adicionando as locacoes das últimas 24h para dentro da tabela de staging
INSERT INTO LOCACAO_Staging (
    ID_LOCACAO,
    Data_Retirada,
    Data_Devolucao,
    Vaga_Retirada,
    Vaga_Devolucao,
    ID_PF,
    ID_ESTADO_VEICULO_Retirada,
    ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS
)
SELECT 
    ID_LOCACAO,
    Data_Retirada,
    Data_Devolucao,
    Vaga_Retirada::INT,
    Vaga_Devolucao::INT,
    ID_PF,
    ID_ESTADO_VEICULO_Retirada,
    ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS
FROM locacoes_do_dia;

-- Selecionando as linhas de estado do veiculo que apareceram no ultimo dia e adicionando na tabela de staging
INSERT INTO ESTADO_VEICULO_Staging (
    ID_ESTADO_VEICULO,
    Pressao_Pneu,
    Nivel_Oleo,
    Gasolina,
    Quilometragem,
    Motor,
    Freios,
    Estado_Pneu,
    Vidros,
    Bateria,
    Estepe,
    Pintura,
    Retrovisor,
    Limpador_Parabrisa,
    Data_Revisao
)
SELECT 
    ID_ESTADO_VEICULO,
    Pressao_Pneu::FLOAT,
    Nivel_Oleo,
    Gasolina,
    Quilometragem::FLOAT,
    Motor,
    Freios,
    Estado_Pneu,
    Vidros,
    Bateria,
    Estepe,
    Pintura,
    Retrovisor,
    Limpador_Parabrisa,
    Data_Revisao
FROM public.ESTADO_VEICULO ev
WHERE ev.ID_ESTADO_VEICULO IN (
    SELECT ID_ESTADO_VEICULO_Retirada FROM locacoes_do_dia
    UNION
    SELECT ID_ESTADO_VEICULO_Devolucao FROM locacoes_do_dia
);

--Selecioando as linhas de veiculos que apareceram no ultimo dia.
INSERT INTO VEICULO_Staging (
    ID_VEICULO,
    Placa,
    Chassi,
    Grupo,
    Modelo,
    Marca,
    Cor,
    AC,
    Crianca,
    Bebe,
    Teto_Solar,
    Multimidia,
    ID_PJ
)
SELECT 
    ID_VEICULO,
    Placa,
    Chassi,
    Grupo,
    Modelo,
    Marca,
    Cor,
    AC,
    Crianca,
    Bebe,
    Teto_Solar,
    Multimidia,
    ID_PJ
FROM public.VEICULO vei
WHERE vei.ID_VEICULO IN (
    SELECT ID_VEICULO
    FROM carros_do_dia
);

-- Adicionando seguros ao Staging
INSERT INTO SEGUROS_Staging(
    ID_SEGUROS,
    Vidros,
    Farois,
    Faixa_Indenizacao
)
SELECT 
    ID_SEGUROS,
    Vidros,
    Farois,
    Faixa_Indenizacao
FROM public.SEGUROS seg
WHERE seg.ID_SEGUROS IN (
    SELECT ID_SEGUROS
    FROM locacoes_do_dia
);

-- Adicionando PFs ao Staging
INSERT INTO PF_Staging (
    ID_PF,
    Nome ,
    CPF,
    CNH,
    Categoria_CNH,
    Endereco,
    Nacionalidade,
    Data_Nascimento,
    Data_Expedicao_CNH,
    ID_PJ
)
SELECT 
    ID_PF,
    Nome,
    CPF,
    CNH,
    Categoria_CNH,
    Endereco,
    Nacionalidade,
    Data_Nascimento,
    Data_Expedicao_CNH,
    ID_PJ
FROM public.PF PF 
WHERE PF.ID_PF IN(
    SELECT ID_PF
    FROM locacoes_do_dia
);

-- Adicionando PJs ao Staging
INSERT INTO PJ_Staging (
    ID_PJ,
    CNPJ,
    Nome,
    Endereco
)
SELECT 
    ID_PJ,
    CNPJ,
    Nome,
    Endereco
FROM public.PJ PJ 
WHERE PJ.ID_PJ IN(
    SELECT ID_PJ
    FROM clientesPJ_do_dia
);

--Adicionando Vagas
INSERT INTO VAGAS_Staging (
    ID_VAGAS,
    ID_PATIO
)
SELECT
    ID_VAGAS,
    ID_PATIO
FROM public.VAGAS VG
WHERE VG.ID_VAGAS IN (
    SELECT Vaga_Retirada FROM locacoes_do_dia
    UNION
    SELECT Vaga_Devolucao FROM locacoes_do_dia
);

-- Adicionando Patios
INSERT INTO PATIO_Staging (
    ID_PATIO,
    ID_PJ,
    Endereco
)
SELECT
    ID_PATIO,
    ID_PJ,
    Endereco,
FROM public.PATIO PT 
WHERE PT.ID_PATIO IN (
    SELECT ID_PATIO
    FROM Patios_do_dia
);