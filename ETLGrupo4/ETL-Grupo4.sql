------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------

-- PJ_Staging
INSERT INTO PJ_Staging (ID_PJ, CNPJ, Nome, Endereco)
SELECT id_empresa, cnpj, nome_empresa, endereco
FROM EMPRESA;

-- SEGUROS_Staging
INSERT INTO SEGUROS_Staging (ID_SEGUROS, Vidros, Farois, Faixa_Indenizacao)
SELECT id_seguro, 'Cobertura Vidros', 'Cobertura Farois', descricao
FROM SEGURO;

-- PF_Staging (somente para clientes com reservas/locações nas últimas 24h)
INSERT INTO PF_Staging (
    ID_PF, Nome, CPF, CNH, Categoria_CNH, Endereco, Nacionalidade, Data_Nascimento, Data_Expedicao_CNH, ID_PJ
)
SELECT DISTINCT
    cond.id_condutor,
    cond.nome_completo,
    cli.cpf,
    cond.numero_cnh,
    cond.categoria_cnh,
    cli.endereco,
    'Brasileira',
    cond.data_nascimento,
    cond.data_expiracao_cnh,
    cli.id_cliente
FROM CONDUTOR cond
JOIN CLIENTE cli ON cond.id_cliente = cli.id_cliente
WHERE cli.tipo_cliente = 'PF'
  AND cond.id_condutor IN (
    SELECT l.id_condutor
    FROM LOCACAO l
    WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY
  );

-- PATIO_Staging
INSERT INTO PATIO_Staging (ID_PATIO, ID_PJ, Endereco)
SELECT DISTINCT p.id_patio, p.id_empresa, p.endereco
FROM PATIO p
JOIN LOCACAO l ON p.id_patio = l.id_patio_retirada_real
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY;

-- VEICULO_Staging
INSERT INTO VEICULO_Staging (
    ID_VEICULO, Placa, Chassi, Grupo, Modelo, Marca, Cor,
    AC, Crianca, Bebe, Teto_Solar, Multimidia, ID_PJ
)
SELECT 
    v.id_veiculo,
    v.placa,
    v.chassi,
    gv.nome_grupo,
    v.modelo,
    v.marca,
    v.cor,
    MAX(CASE WHEN a.nome_acessorio = 'Ar Condicionado' THEN 1 ELSE 0 END),
    MAX(CASE WHEN a.nome_acessorio = 'Assento Infantil' THEN 1 ELSE 0 END),
    MAX(CASE WHEN a.nome_acessorio = 'Bebê Conforto' THEN 1 ELSE 0 END),
    MAX(CASE WHEN a.nome_acessorio = 'Teto Solar' THEN 1 ELSE 0 END),
    MAX(CASE WHEN a.nome_acessorio = 'Multimídia' THEN 1 ELSE 0 END),
    p.id_empresa
FROM VEICULO v
JOIN LOCACAO l ON l.id_veiculo = v.id_veiculo
LEFT JOIN GRUPO_VEICULO gv ON v.id_grupo_veiculo = gv.id_grupo_veiculo
LEFT JOIN VEICULO_ACESSORIO va ON v.id_veiculo = va.id_veiculo
LEFT JOIN ACESSORIO a ON va.id_acessorio = a.id_acessorio
LEFT JOIN PATIO p ON v.id_patio_atual = p.id_patio
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY
GROUP BY v.id_veiculo, v.placa, v.chassi, gv.nome_grupo, v.modelo, v.marca, v.cor, p.id_empresa;

-- VAGAS_Staging (apenas para pátios envolvidos nas locações recentes)
INSERT INTO VAGAS_Staging (ID_VAGAS, ID_PATIO)
SELECT DISTINCT v.id_vaga, v.id_patio
FROM VAGA v
JOIN PATIO p ON v.id_patio = p.id_patio
JOIN LOCACAO l ON l.id_patio_retirada_real = p.id_patio
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY;

-- ESTADO_VEICULO_Staging (apenas para veículos com locação nas últimas 24h)
INSERT INTO ESTADO_VEICULO_Staging (
    ID_ESTADO_VEICULO, Data_Revisao, Quilometragem,
    Pressao_Pneu, Nivel_Oleo, Gasolina, Motor, Freios,
    Estado_Pneu, Vidros, Bateria, Estepe, Pintura,
    Retrovisor, Limpador_Parabrisa
)
SELECT 
    p.id_prontuario,
    p.data_ultima_revisao,
    p.quilometragem_ultima_revisao,
    NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL,
    NULL, NULL
FROM PRONTUARIO p
JOIN LOCACAO l ON l.id_veiculo = p.id_veiculo
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY;

-- RESERVA_Staging (últimas 24h)
INSERT INTO RESERVA_Staging (
    ID_RESERVA, ID_VEICULO, ID_PF, ID_PJ, Data_Inicio, Data_Fim
)
SELECT 
    r.id_reserva,
    NULL,
    CASE WHEN c.tipo_cliente = 'PF' THEN c.id_cliente ELSE NULL END,
    CASE WHEN c.tipo_cliente = 'PJ' THEN c.id_cliente ELSE NULL END,
    r.data_hora_retirada_prevista,
    r.data_hora_devolucao_prevista
FROM RESERVA r
JOIN CLIENTE c ON r.id_cliente = c.id_cliente
WHERE r.data_hora_reserva >= NOW() - INTERVAL 1 DAY;

-- LOCACAO_Staging (últimas 24h)
INSERT INTO LOCACAO_Staging (
    ID_LOCACAO, Data_Retirada, Data_Devolucao,
    Vaga_Retirada, Vaga_Devolucao,
    ID_PF, ID_ESTADO_VEICULO_Retirada, ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS, ID_RESERVA
)
SELECT 
    l.id_locacao,
    l.data_hora_retirada_real,
    l.data_hora_devolucao_real,
    NULL, NULL,
    l.id_condutor,
    NULL, NULL,
    NULL,
    l.id_reserva
FROM LOCACAO l
WHERE l.data_hora_retirada_real >= NOW() - INTERVAL 1 DAY;
