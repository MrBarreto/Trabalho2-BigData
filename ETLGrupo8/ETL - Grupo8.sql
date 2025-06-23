------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------
------------------------------------------------------------------------------
-- 1) PJ → PJ_Staging OK!
------------------------------------------------------------------------------
INSERT INTO PJ_Staging (
    ID_PJ,
    CNPJ,
    Nome,
    Endereco
)
SELECT
    e.ID_EMPRESA AS ID_PJ,
    e.CNPJ_EMPRESA AS CNPJ,
    e.NOME_EMPRESA AS Nome,
    CONCAT(en.LOGRADOURO, en.NUMERO_LOGRADOURO, en.COMPLEMENTO) AS Endereco -- não existia na modelagem de origem
FROM Empresa e
LEFT JOIN Patio p 
    ON e.ID_EMPRESA = p.FK_ID_EMPRESA
LEFT JOIN Endereco en 
    ON p.FK_ID_ENDERECO = en.ID_ENDERECO;

------------------------------------------------------------------------------
-- 2) SEGUROS → SEGUROS_Staging OK!
------------------------------------------------------------------------------

-- Não há como integrar pois não há um ID_COBERTURA associado à locação que ajude a vincular quais os tipos de proteções contratados para a locação

------------------------------------------------------------------------------
-- 3) PF → PF_Staging OK!
------------------------------------------------------------------------------
INSERT INTO PF_Staging (
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
)
SELECT
    c.ID_CLIENTE AS ID_PF,
    c.NOME_CLIENTE AS Nome,
    c.DOCUMENTO AS CPF,
    d.NUMERO_CNH AS CNH, -- vem da tabela Condutor
    d.CATEGORIA_CNH AS Categoria_CNH, -- vem da tabela Condutor
    CONCAT(e.LOGRADOURO, e.NUMERO_LOGRADOURO, e.COMPLEMENTO) AS Endereco, -- vem da associação Cliente Endereco
    'Brasileira' AS Nacionalidade, -- não existia na origem
    NULL AS Data_Nascimento, -- não existia na origem
    NULL AS Data_Expedicao_CNH, -- não existia na origem
    p.FK_ID_EMPRESA AS ID_PJ -- vem da associação com Reserva e Patio
FROM Cliente c
LEFT JOIN Condutor d
    ON d.FK_ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN Reserva r
    ON r.FK_ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN Patio p
    ON r.FK_ID_PATIO_RETIRADA = p.ID_PATIO
LEFT JOIN Endereco e
    ON c.FK_ID_ENDERECO = e.ID_ENDERECO
WHERE c.TIPO_PESSOA = 'F';

------------------------------------------------------------------------------
-- 4) PATIO → PATIO_Staging OK!
------------------------------------------------------------------------------
INSERT INTO PATIO_Staging (
    ID_PATIO,
    ID_PJ,
    Endereco
)
SELECT
    p.ID_PATIO AS ID_PATIO,
    p.FK_ID_EMPRESA AS ID_PJ,
    CONCAT(e.LOGRADOURO, e.NUMERO_LOGRADOURO, e.COMPLEMENTO) AS Endereco -- não existia na modelagem de origem
FROM Patio p
LEFT JOIN Endereco e
    ON p.FK_ID_ENDERECO = e.ID_ENDERECO;

------------------------------------------------------------------------------
-- 5) VEICULO → VEICULO_Staging OK!
------------------------------------------------------------------------------
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
    v.ID_VEICULO AS ID_VEICULO,
    v.PLACA AS Placa,
    v.CHASSI AS Chassi,
    gv.NOME_GRUPO AS Grupo,
    mv.NOME_MODELO AS Modelo,
    mar.NOME_MARCA AS Marca,
    v.COR_VEICULO AS Cor,
    v.POSSUI_AR_CONDICIONADO AS AC,
    v.POSSUI_CADEIRINHA_CRIANCA AS Crianca,
    v.POSSUI_BEBE_CONFORTO AS Bebe,
    NULL AS Teto_Solar, -- não existia na origem
    NULL AS Multimidia, -- não existia na origem
    v.FK_ID_EMPRESA AS ID_PJ
FROM Veiculo v
LEFT JOIN GrupoVeiculo gv
  ON gv.ID_GRUPO_VEICULO = v.FK_ID_GRUPO_VEICULO
LEFT JOIN ModeloVeiculo mv
  ON mv.ID_MODELO_VEICULO = v.FK_ID_MODELO_VEICULO
LEFT JOIN MarcaVeiculo mar
  ON mar.ID_MARCA_VEICULO = v.FK_ID_MARCA_VEICULO;

------------------------------------------------------------------------------
-- 6) VAGAS → VAGAS_Staging OK!
------------------------------------------------------------------------------
INSERT INTO VAGAS_Staging (
    ID_VAGAS,
    ID_PATIO
)
SELECT
    v.ID_VAGA       AS ID_VAGAS,
    v.FK_ID_PATIO   AS ID_PATIO
FROM Vaga v;

------------------------------------------------------------------------------
-- 7) ESTADO_VEICULO → ESTADO_VEICULO_Staging OK!
-- (não há atributos discretos na origem → preenche tudo NULL)
------------------------------------------------------------------------------
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
    NULL AS ID_ESTADO_VEICULO, -- não havia PK de estado separado
    NULL AS Pressao_Pneu, -- não existia
    NULL AS Nivel_Oleo, -- não existia
    NULL AS Gasolina, -- não existia
    NULL AS Quilometragem, -- não existia
    NULL AS Motor, -- não existia
    NULL AS Freios, -- não existia
    NULL AS Estado_Pneu, -- não existia
    NULL AS Vidros, -- não existia
    NULL AS Bateria, -- não existia
    NULL AS Estepe, -- não existia
    NULL AS Pintura, -- não existia
    NULL AS Retrovisor, -- não existia
    NULL AS Limpador_Parabrisa -- não existia
    NULL AS Data_Revisao, -- não existia
;

------------------------------------------------------------------------------
-- 8) RESERVA → RESERVA_Staging ok!
------------------------------------------------------------------------------
INSERT INTO RESERVA_Staging (
    ID_RESERVA,
    ID_VEICULO,
    ID_PF,
    ID_Vaga_Retirada,
    ID_PJ,
    Data_Inicio,
    Data_Fim
)
SELECT
    r.ID_RESERVA AS ID_RESERVA,
    NULL AS ID_VEICULO, -- na origem só havia FK_GRUPO_VEICULO
    CASE
        c.TIPO_PESSOA = 'F' THEN r.FK_ID_CLIENTE
        ELSE NULL
    END AS ID_PF,
    NULL AS ID_Vaga_Retirada, -- não existia
    CASE
        c.TIPO_PESSOA = 'J' THEN r.FK_ID_CLIENTE
        ELSE NULL
    END AS ID_PJ,           
    CAST(r.DATA_HORA_PREVISTA_RETIRADA  AS DATE) AS Data_Inicio,
    CAST(r.DATA_HORA_PREVISTA_DEVOLUCAO   AS DATE) AS Data_Fim
FROM Reserva r
LEFT JOIN Cliente c
    ON r.FK_ID_CLIENTE = c.ID_CLIENTE;

------------------------------------------------------------------------------
-- 9) LOCACAO → LOCACAO_Staging OK!
------------------------------------------------------------------------------
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
    l.ID_LOCACAO AS ID_LOCACAO,
    CAST(l.DATA_HORA_RETIRADA_REALIZADA AS DATE) AS Data_Retirada,
    CAST(l.DATA_HORA_DEVOLUCAO_REALIZADA  AS DATE) AS Data_Devolucao,
    va.CODIGO_VAGA AS Vaga_Retirada, 
    NULL AS Vaga_Devolucao,   -- não existia
    l.FK_ID_CLIENTE AS ID_PF, 
    NULL AS ID_ESTADO_VEICULO_Retirada,  -- não existia
    NULL AS ID_ESTADO_VEICULO_Devolucao, -- não existia
    lp.FK_ID_PROTECAO_ADICIONAL AS ID_SEGUROS,        -- associação via LocacaoProtecao
    r.ID_RESERVA AS ID_RESERVA
FROM Locacao l
LEFT JOIN LocacaoProtecao lp
  ON lp.FK_ID_LOCACAO = l.ID_LOCACAO
LEFT JOIN Cliente c 
    ON l.FK_ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN Veiculo v
    ON l.FK_ID_VEICULO = v.ID_VEICULO
LEFT JOIN Vaga va
    ON v.FK_ID_VAGA = va.ID_VAGA
LEFT JOIN Reserva r
    ON r.FK_ID_CLIENTE = l.FK_ID_CLIENTE AND CAST(l.DATA_HORA_RETIRADA_PREVISTA AS DATE) = CAST(r.DATA_HORA_PREVISTA_RETIRADA AS DATE) -- solução um pouco mais generalista para tentar associar reserva e locacao
WHERE c.TIPO_PESSOA = 'F';
