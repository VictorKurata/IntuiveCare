DROP TABLE IF EXISTS demonstracoes_contabeis;
DROP TABLE IF EXISTS operadoras;
DROP TABLE IF EXISTS stg_demonstracoes_contabeis;

CREATE TABLE operadoras (
    registro_ans VARCHAR(20),
    cnpj VARCHAR(14),
    razao_social TEXT,
    nome_fantasia TEXT,
    modalidade TEXT,
    logradouro TEXT,
    numero TEXT,
    complemento TEXT,
    bairro TEXT,
    cidade TEXT,
    uf TEXT,
    cep TEXT,
    ddd TEXT,
    telefone TEXT,
    fax TEXT,
    endereco_eletronico TEXT,
    representante TEXT,
    cargo_representante TEXT,
    regiao_comercializacao TEXT,
    data_registro_ans DATE
);

CREATE TABLE demonstracoes_contabeis (
    data_registro DATE,
    reg_ans VARCHAR(20),
    cd_conta_contabil VARCHAR(20),
    descricao TEXT,
    vl_saldo_inicial NUMERIC(15, 2),
    vl_saldo_final NUMERIC(15, 2)
);

CREATE TABLE stg_demonstracoes_contabeis (
    data_registro DATE,
    reg_ans VARCHAR(20),
    cd_conta_contabil VARCHAR(20),
    descricao TEXT,
    vl_saldo_inicial VARCHAR(200),
    vl_saldo_final VARCHAR(200)
);

-- importando dados cadastrais
COPY operadoras (
    registro_ans, 
    cnpj, 
    razao_social, 
    nome_fantasia, 
    modalidade, 
    logradouro, 
    numero, 
    complemento, 
    bairro, 
    cidade, 
    uf, 
    cep, 
    ddd, 
    telefone, 
    fax, 
    endereco_eletronico, 
    representante, 
    cargo_representante, 
    regiao_comercializacao, 
    data_registro_ans
)
FROM 'C:\Intuitivecare\Relatorio_cadop.csv'
DELIMITER ';' CSV HEADER ENCODING 'UTF8';

-- importando dados dos ultimos 2 anos
DO $$
DECLARE
    arquivo TEXT;
BEGIN
    FOR arquivo IN SELECT unnest(ARRAY[
        'C:\Intuitivecare\1T2023.csv',
        'C:\Intuitivecare\2T2023.csv',
        'C:\Intuitivecare\3T2023.csv',
        'C:\Intuitivecare\4T2023.csv',
        'C:\Intuitivecare\1T2024.csv',
        'C:\Intuitivecare\2T2024.csv',
        'C:\Intuitivecare\3T2024.csv',
        'C:\Intuitivecare\4T2024.csv'
    ]) LOOP
        EXECUTE format(
            'COPY stg_demonstracoes_contabeis(data_registro, reg_ans, cd_conta_contabil, descricao, vl_saldo_inicial, vl_saldo_final) FROM %L DELIMITER '';'' CSV HEADER ENCODING ''UTF8'';',
            arquivo
        );
    END LOOP;

	INSERT INTO demonstracoes_contabeis (
    data_registro, reg_ans, cd_conta_contabil, descricao, vl_saldo_inicial, vl_saldo_final
	)
	SELECT 
	    data_registro, 
	    reg_ans, 
	    cd_conta_contabil, 
	    descricao, 
	    REPLACE(vl_saldo_inicial, ',', '.')::NUMERIC, 
	    REPLACE(vl_saldo_final, ',', '.')::NUMERIC
	FROM stg_demonstracoes_contabeis;

END $$;

-- Ultimo trimestre
SELECT 
    demonstracoes_contabeis.reg_ans,
    operadoras.nome_fantasia,
    SUM(demonstracoes_contabeis.vl_saldo_final) AS total_despesas
FROM demonstracoes_contabeis
JOIN operadoras ON demonstracoes_contabeis.reg_ans = operadoras.registro_ans
WHERE 
    (descricao ILIKE '%EVENTOS/SINISTROS%' 
    OR descricao ILIKE '%ASSISTÊNCIA MÉDICO HOSPITALAR%' 
    OR descricao ILIKE '%ASSISTÊNCIA MÉDICO-HOSPITALAR%')
    AND demonstracoes_contabeis.data_registro = (
        SELECT MAX(data_registro) FROM demonstracoes_contabeis
    )
GROUP BY demonstracoes_contabeis.reg_ans, operadoras.nome_fantasia
ORDER BY total_despesas DESC
LIMIT 10;


-- Ultimo ano
SELECT 
    demonstracoes_contabeis.reg_ans,
    operadoras.nome_fantasia,
    SUM(demonstracoes_contabeis.vl_saldo_final) AS total_despesas
FROM demonstracoes_contabeis
JOIN operadoras ON demonstracoes_contabeis.reg_ans = operadoras.registro_ans
WHERE 
    (descricao ILIKE '%EVENTOS/SINISTROS%' 
    OR descricao ILIKE '%ASSISTÊNCIA MÉDICO HOSPITALAR%' 
    OR descricao ILIKE '%ASSISTÊNCIA MÉDICO-HOSPITALAR%')
    AND demonstracoes_contabeis.data_registro >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY demonstracoes_contabeis.reg_ans, operadoras.nome_fantasia
ORDER BY total_despesas DESC
LIMIT 10;









