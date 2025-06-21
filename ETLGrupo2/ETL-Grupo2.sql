------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------

-- PJ_Staging ok
INSERT INTO PJ_Staging (ID_PJ, CNPJ, Nome)
SELECT id, cnpj, nome_fantasia
FROM Empresa;


-- SEGUROS_Staging ok
INSERT INTO SEGUROS_Staging (ID_SEGUROS, Vidros, Farois, Faixa_Indenizacao)
SELECT id, 'Cobertura Vidros', 'Cobertura Farois', descricao
FROM ProtecaoAdicional;

-- PF_Staging (somente para clientes com reservas/locações nas últimas 24h) ok
INSERT INTO PF_Staging (
    ID_PF, Nome, CPF, CNH, Categoria_CNH, Endereco, Nacionalidade, Data_Nascimento, Data_Expedicao_CNH, ID_PJ
)
SELECT DISTINCT
    cond.id,
    cond.nome,
    cli.cpf_cnpj, -- checa se é CPF embaixo
    cond.cnh,
    cond.categoria_cnh,
    cli.endereco,
    'Brasileira',
    NULL, 
    cond.data_nascimento,
    NULL,
    NULL
FROM CONDUTOR cond
JOIN CLIENTE cli ON cond.id_cliente = cli.id_cliente
WHERE LENGTH(cli.cpf_cnpj) = 11
  AND cond.id IN (
    SELECT l.condutor_id
    FROM Locacao l
    WHERE l.data_retirada >= NOW() - INTERVAL 1 DAY
  );

-- PATIO_Staging ok
INSERT INTO PATIO_Staging (ID_PATIO, ID_PJ, Endereco)
SELECT id, empresa_id, endereco
FROM Patio

-- VEICULO_Staging
INSERT INTO VEICULO_Staging (
    ID_VEICULO, Placa, Chassi, Grupo, Modelo, Marca, Cor,
    AC, Crianca, Bebe, Teto_Solar, Multimidia, ID_PJ
)
SELECT 
    v.id,
    v.placa,
    v.chassi,
    v.grupo_id,
    v.modelo,
    v.marca,
    v.cor,
    v.ar_condicionado,
    va.cadeira_de_crianca,
    va.bebe_conforto,
    NULL, -- Teto Solar não consta
    NULL, -- Multimídia não consta
    NULL, -- ID_PJ não consta
FROM Veiculo v
JOIN Locacao l ON l.veiculo_id = v.id
LEFT JOIN AcessoriosVeiculo va ON v.id = va.veiculo_id
WHERE l.data_retirada >= NOW() - INTERVAL 1 DAY;

-- VAGAS_Staging (apenas para pátios envolvidos nas locações recentes)
-- como não existe tabela de vagas, VAGAS_Staging será preenchida com o mesmo numero de vagas em "total_vagas" com IDs fictícios 
INSERT INTO VAGAS_Staging (ID_VAGAS, ID_PATIO)
SELECT 
    GENERATE_SERIES(1, p.total_vagas) AS ID_VAGAS,
    p.id AS ID_PATIO
FROM Patio p
JOIN Locacao l ON l.patio_id = p.id
WHERE l.data_retirada >= NOW() - INTERVAL 1 DAY;

-- ESTADO_VEICULO_Staging (apenas para veículos com locação nas últimas 24h)
INSERT INTO ESTADO_VEICULO_Staging (
    ID_ESTADO_VEICULO, Data_Revisao, Quilometragem,
    Pressao_Pneu, Nivel_Oleo, Gasolina, Motor, Freios,
    Estado_Pneu, Vidros, Bateria, Estepe, Pintura,
    Retrovisor, Limpador_Parabrisa
)
SELECT 
    v.id,
    NULL, -- Data_Revisao não consta
    l.km_saida,
    NULL, -- Pressao_Pneu não consta
    NULL, -- Nivel_Oleo não consta
    NULL, -- Gasolina não consta
    NULL, -- Motor não consta
    NULL, -- Freios não consta
    NULL, -- Estado_Pneu não consta
    NULL, -- Vidros não consta
    NULL, -- Bateria não consta
    NULL, -- Estepe não consta
    NULL, -- Pintura não consta
    NULL, -- Retrovisor não consta
    NULL, -- Limpador_Parabrisa não consta
    NULL -- Data_Revisao não consta
FROM Veiculo v
JOIN Locacao l ON l.veiculo_id = v.id
WHERE l.data_retirada >= NOW() - INTERVAL 1 DAY;

-- RESERVA_Staging (últimas 24h)
INSERT INTO RESERVA_Staging (
    ID_RESERVA, ID_VEICULO, ID_PF, ID_PJ, Data_Inicio, Data_Fim
)
SELECT 
    r.id,
    l.veiculo_id,
    CASE WHEN c.tipo_cliente = 'PF' THEN c.id_cliente ELSE NULL END,
    CASE WHEN c.tipo_cliente = 'PJ' THEN c.id_cliente ELSE NULL END,
    r.data_prev_retirada,
    r.data_prev_devolucao
FROM Reserva r
JOIN Locacao l ON r.id = l.reserva_id
WHERE r.data_hora_reserva >= NOW() - INTERVAL 1 DAY
  AND (l.data_retirada IS NULL OR l.data_retirada >= NOW() - INTERVAL 1 DAY)
  AND (l.data_devolucao IS NULL OR l.data_devolucao >= NOW() - INTERVAL 1 DAY);
WHERE r.data_hora_reserva >= NOW() - INTERVAL 1 DAY;

-- LOCACAO_Staging (últimas 24h)
INSERT INTO LOCACAO_Staging (
    ID_LOCACAO, Data_Retirada, Data_Devolucao,
    Vaga_Retirada, Vaga_Devolucao,
    ID_PF, ID_ESTADO_VEICULO_Retirada, ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS, ID_RESERVA
)
SELECT 
    l.id,
    l.data_retirada,
    l.data_real_devolucao,
    NULL,
    NULL,
    l.condutor_id,
    NULL,
    NULL,
    NULL,
    l.id_reserva
FROM Locacao l
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY;
