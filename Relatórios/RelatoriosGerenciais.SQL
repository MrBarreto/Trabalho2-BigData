------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------


-- Relatórios Gerenciais Baseados no Esquema do Banco de Dados

-- a. Controle de Pátio: quantitativo de veículos no pátio por “grupo” e “origem”.
--    "Origem" aqui é inferida como a empresa dona do pátio ou uma empresa associada.
--    Nota: Esta consulta tenta inferir veículos "no pátio" pela última devolução.
--    Para um controle de inventário em tempo real, seria ideal ter uma tabela de status atual do veículo.

WITH UltimaDevolucao AS (
    SELECT
        FL.ID_VEICULO,
        DV.ID_PATIO,
        DE.ID_Empresa_Dona AS ID_Empresa_Dona_Patio,
        FL.Data_Devolucao,
        ROW_NUMBER() OVER (PARTITION BY FL.ID_VEICULO ORDER BY FL.Data_Devolucao DESC, FL.ID_LOCACAO DESC) as rn
    FROM
        FatoLocacao FL
    JOIN
        DimVaga DV ON FL.Vaga_Devolucao = DV.ID_Vaga
    JOIN
        DimEmpresa_Dona DE ON DV.ID_Empresa = DE.ID_Empresa_Dona
),
VeiculosNoPatio AS (
    SELECT
        UD.ID_VEICULO,
        UD.ID_PATIO,
        UD.ID_Empresa_Dona_Patio,
        DVei.Grupo,
        DVei.Marca,
        DVei.Modelo,
        CASE
            WHEN DVei.AC THEN 'Com AC' ELSE 'Sem AC'
        END AS TipoMecanizacao -- Exemplo, você pode expandir para outros booleanos
    FROM
        UltimaDevolucao UD
    JOIN
        DimVeiculo DVei ON UD.ID_VEICULO = DVei.ID_VEICULO
    WHERE
        UD.rn = 1
        -- Opcional: Adicione condições para considerar apenas veículos
        -- que não foram alugados novamente após a última devolução,
        -- ou que a Data_Devolucao é recente.
        -- Por exemplo: AND UD.Data_Devolucao > (CURRENT_DATE - INTERVAL '7 days')
)
SELECT
    VNP.ID_PATIO,
    DV.Nome_Empresa AS Nome_Empresa_Patio,
    VNP.Grupo,
    VNP.Marca,
    VNP.Modelo,
    VNP.TipoMecanizacao,
    CASE
        WHEN VNP.ID_Empresa_Dona_Patio = DV.ID_Empresa_Dona THEN 'Frota da Empresa Dona do Pátio'
        ELSE 'Frota de Empresas Associadas'
    END AS OrigemFrota,
    COUNT(VNP.ID_VEICULO) AS QuantidadeVeiculos
FROM
    VeiculosNoPatio VNP
JOIN
    DimEmpresa_Dona DV ON VNP.ID_Empresa_Dona_Patio = DV.ID_Empresa_Dona
GROUP BY
    VNP.ID_PATIO, DV.Nome_Empresa, VNP.Grupo, VNP.Marca, VNP.Modelo, VNP.TipoMecanizacao, OrigemFrota
ORDER BY
    VNP.ID_PATIO, OrigemFrota, VNP.Grupo;


-- b. Controle das Locações: quantitativo de veículos alugados por “grupo”,
--    dimensão de tempo de locação e tempo restante para devolução (para locações ativas).

SELECT
    DV.Grupo,
    COUNT(FL.ID_LOCACAO) AS QuantidadeLocacoes,
    AVG(FL.Data_Devolucao - FL.Data_Retirada) AS TempoMedioLocacaoDias,
    -- Para "tempo restante para devolução", consideramos apenas locações ATIVAS (retiradas e ainda não devolvidas)
    CASE
        WHEN FL.Data_Retirada <= CURRENT_DATE AND FL.Data_Devolucao >= CURRENT_DATE THEN
            AVG(FL.Data_Devolucao - CURRENT_DATE)
        ELSE NULL
    END AS TempoRestanteDevolucaoMedioDias
FROM
    FatoLocacao FL
JOIN
    DimVeiculo DV ON FL.ID_VEICULO = DV.ID_VEICULO
GROUP BY
    DV.Grupo
ORDER BY
    DV.Grupo;


-- c. Controle de Reservas: quantas reservas por “grupo” de veículo e “pátio”,
--    por tempo de retirada futura, tempo de duração das locações, e cidades de origem dos clientes.

SELECT
    DV.Grupo,
    DVa.ID_PATIO,
    DVa.Endereco_Patio AS EnderecoPatio,
    -- Agrupamento por tempo de retirada futura (ex: semana, mês, ano)
    CASE
        WHEN FR.Data_Retirada_Prevista BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days') THEN 'Próxima Semana'
        WHEN FR.Data_Retirada_Prevista BETWEEN (CURRENT_DATE + INTERVAL '8 days') AND (CURRENT_DATE + INTERVAL '30 days') THEN 'Próximo Mês'
        WHEN FR.Data_Retirada_Prevista > (CURRENT_DATE + INTERVAL '30 days') THEN 'Futuro (mais de 30 dias)'
        ELSE 'Passado ou Hoje'
    END AS TempoRetiradaFutura,
    -- Duração prevista da locação
    (FR.Data_Devolucao_Prevista - FR.Data_Retirada_Prevista) AS DuracaoPrevistaDias,
    -- Cidade de origem do cliente (inferida do Endereco_Pessoa)
    -- Nota: Esta é uma simplificação. A extração de cidade de um campo de texto pode ser imprecisa.
    SPLIT_PART(DP.Endereco, ',', 2) AS CidadeOrigemCliente, -- Assumindo "Rua, Cidade, Estado"
    COUNT(FR.ID_RESERVA) AS QuantidadeReservas
FROM
    FatoReserva FR
JOIN
    DimVeiculo DV ON FR.ID_VEICULO = DV.ID_VEICULO
JOIN
    DimVaga DVa ON FR.ID_Vaga_Retirada = DVa.ID_Vaga
JOIN
    DimPessoa DP ON FR.ID_Pessoa = DP.ID_Pessoa
GROUP BY
    DV.Grupo, DVa.ID_PATIO, DVa.Endereco_Patio, TempoRetiradaFutura, DuracaoPrevistaDias, CidadeOrigemCliente
ORDER BY
    QuantidadeReservas DESC, DV.Grupo, TempoRetiradaFutura;


-- d. Quais os “grupos” de veículos mais alugados, cruzando, eventualmente, com a origem dos clientes.

SELECT
    DV.Grupo,
    -- Cidade de origem do cliente para locações
    -- Nota: Similar à consulta de reservas, a extração de cidade é uma simplificação.
    SPLIT_PART(DP.Endereco, ',', 2) AS CidadeOrigemCliente,
    COUNT(FL.ID_LOCACAO) AS TotalLocacoes
FROM
    FatoLocacao FL
JOIN
    DimVeiculo DV ON FL.ID_VEICULO = DV.ID_VEICULO
JOIN
    DimPessoa DP ON FL.ID_Pessoa = DP.ID_Pessoa
GROUP BY
    DV.Grupo, CidadeOrigemCliente
ORDER BY
    TotalLocacoes DESC, DV.Grupo;
