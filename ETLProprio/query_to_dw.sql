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
ON CONFLICT (ID_Pessoa) DO NOTHING;

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
    PF.Data_Expedicao_CNH, PJ.ID_Empresa, PJ.Nome_Empresa, PJ.CNPJ,
    PJ.Endereco_Empresa
FROM PF_Staging PF
LEFT JOIN PJ_Staging PJ ON PF.ID_PJ = PJ.ID_PJ
ON CONFLICT (ID_Pessoa) DO NOTHING;

-- Inserindo na Tabela FatoLocacao