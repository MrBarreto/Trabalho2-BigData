------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------

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
    Data_Retirada >= NOW() - INTERVAL '1 day'

--Criar uma tabela temporária para as reservas do dia.
CREATE TEMP TABLE reservas_do_dia AS
SELECT 
    ID_RESERVA,
    ID_VEICULO,
    ID_PF,
    Data_Inicio,
    Data_Fim
FROM public.RESERVA
WHERE
    Data_Inicio >= NOW() - INTERVAL '1 day'

-- Criando uma tabela temporaria para armazenar os clientes PJs do dia 
CREATE TEMP TABLE clientesPJ_do_dia AS
SELECT DISTINCT 
    ID_PJ
FROM public.PF PF 
WHERE PF.ID_PF IN (
    SELECT ID_PF FROM reservas_do_dia
);

-- Criando uma tabela temporaria para armazenar os pátios visitados no ultimo dia 
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
    ID_SEGUROS, 
    ID_RESERVA
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
    ID_SEGUROS,
    ID_RESERVA
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
    FROM reservas_do_dia
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
    FROM reservas_do_dia
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
    Endereco
FROM public.PATIO PT 
WHERE PT.ID_PATIO IN (
    SELECT ID_PATIO
    FROM Patios_do_dia
);

-- Adicionando Reservas ao Staging
INSERT INTO RESERVA_Staging (
    ID_RESERVA,
    ID_VEICULO,
    ID_PF,
    ID_PJ,
    Data_Inicio,
    Data_Fim
)
SELECT 
    ID_RESERVA,
    ID_VEICULO,
    ID_PF,
    NULL AS ID_Vaga_Retirada,
    ID_PJ,
    Data_Inicio,
    Data_Fim
FROM public.RESERVA RSV 
WHERE RSV.ID_RESERVA IN(
    SELECT ID_RESERVA
    FROM reservas_do_dia
);