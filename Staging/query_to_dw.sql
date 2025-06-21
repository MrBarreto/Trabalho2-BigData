INSERT INTO DimEmpresa_Dona (
    ID_Empresa_Dona,
    CNPJ_Empresa,
    Nome_Empresa,
    Endereco_Empresa
)
SELECT DISTINCT
    ID_PJ, 
    CNPJ, 
    Nome, 
    Endereco
FROM PJ_Staging
WHERE PJ_Staging.ID_PJ IN (
    SELECT ID_PJ
    FROM VEICULO_Staging
)
ON CONFLICT (ID_Empresa_Dona) DO NOTHING;

INSERT INTO DimVeiculo (
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
    Teto_solar,
    Multimidia
)
SELECT DISTINCT
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
    Multimidia
FROM VEICULO_Staging
ON CONFLICT (ID_VEICULO) DO NOTHING;

-- Inserindo na tabela DimEstado_Veiculo
INSERT INTO DimEstado_Veiculo (
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
SELECT DISTINCT
    ID_ESTADO_VEICULO, Pressao_Pneu, Nivel_Oleo, Gasolina, Quilometragem,
    Motor, Freios, Estado_Pneu, Vidros, Bateria, Estepe, Pintura,
    Retrovisor, Limpador_Parabrisa, Data_Revisao
FROM ESTADO_VEICULO_Staging
ON CONFLICT (ID_ESTADO_VEICULO) DO NOTHING;

-- Inserindo na tabela DimSeguro
INSERT INTO DimSeguro (
    ID_SEGUROS, 
    Vidros, 
    Farois, 
    Faixa_Indenizacao
)
SELECT DISTINCT ID_SEGUROS, Vidros, Farois, Faixa_Indenizacao
FROM SEGUROS_Staging
ON CONFLICT (ID_SEGUROS) DO NOTHING;

-- Inserindo na tabela DimVaga
INSERT INTO DimVaga (
    ID_Vaga, 
    ID_PATIO, 
    Endereco_Patio,
    ID_Empresa, 
    CNPJ_Empresa, 
    Nome_Empresa, 
    Endereco_Empresa
)
SELECT DISTINCT
    v.ID_VAGAS, v.ID_PATIO, pt.Endereco,
    pj.ID_PJ, pj.CNPJ, pj.Nome, pj.Endereco
FROM VAGAS_Staging v
JOIN PATIO_Staging pt ON v.ID_PATIO = pt.ID_PATIO
JOIN PJ_Staging pj ON pt.ID_PJ = pj.ID_PJ
ON CONFLICT (ID_Vaga) DO NOTHING;

-- Inserindo na tabela DimPessoa
INSERT INTO DimPessoa (
    ID_Pessoa,
    Nome,
    CPF,
    CNH,
    Categoria_CNH,
    Endereco,
    Nacionalidade,
    Data_Nascimento,
    Data_Expedicao_CNH,
    ID_Empresa,
    Nome_empresa,
    CNPJ,
    Endereco_Empresa
)
SELECT DISTINCT 
    PF.ID_PF, PF.Nome, PF.CPF, PF.CNH, 
    PF.Categoria_CNH, PF.Endereco, PF.Nacionalidade, PF.Data_Nascimento,
    PF.Data_Expedicao_CNH, PJ.ID_PJ, PJ.Nome, PJ.CNPJ,
    PJ.Endereco
FROM PF_Staging PF
LEFT JOIN PJ_Staging PJ ON PF.ID_PJ = PJ.ID_PJ
ON CONFLICT (ID_Pessoa) DO NOTHING;

-- Inserindo na Tabela FatoLocacao
INSERT INTO FatoLocacao (
    ID_LOCACAO,
    Data_Retirada,
    Data_Devolucao,
    Vaga_Retirada,
    Vaga_Devolucao,
    ID_Pessoa,
    ID_ESTADO_VEICULO_Retirada,
    ID_ESTADO_VEICULO_Devolucao,
    ID_SEGUROS,
    ID_EMPRESA_Dona,
    ID_VEICULO, 
    ID_RESERVA
)
SELECT DISTINCT
    LOC.ID_LOCACAO, LOC.Data_Retirada, LOC.Data_Devolucao, LOC.Vaga_Retirada,
    LOC.Vaga_Devolucao, LOC.ID_PF, LOC.ID_ESTADO_VEICULO_Retirada, LOC.ID_ESTADO_VEICULO_Devolucao,
    LOC.ID_SEGUROS, VEC.ID_PJ, VEC.ID_VEICULO, LOC.ID_RESERVA
FROM LOCACAO_Staging LOC 
JOIN RESERVA_Staging RSV ON LOC.ID_RESERVA = RSV.ID_RESERVA
JOIN VEICULO_Staging VEC ON RSV.ID_VEICULO = VEC.ID_VEICULO
ON CONFLICT (ID_LOCACAO) DO NOTHING;

-- Inserindo na Tabela FatoReserva
INSERT INTO FatoReserva (
    ID_RESERVA,
    ID_Pessoa,
    ID_VEICULO,
    ID_Vaga_Retirada
    Data_Retirada_Prevista,
    Data_Devolucao_Prevista
)
SELECT DISTINCT
    ID_RESERVA,
    ID_PF,
    ID_VEICULO,
    ID_Vaga_Retirada
    Data_Inicio,
    Data_Fim
FROM RESERVA_Staging 
ON CONFLICT (ID_RESERVA) DO NOTHING;