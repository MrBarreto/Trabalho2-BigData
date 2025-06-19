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