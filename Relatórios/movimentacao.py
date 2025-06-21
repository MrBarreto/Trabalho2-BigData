"""
------------------------------------------------------------------
--Alanna Figueiredo Simões (Mat. Aplic.) — 120053919
-- Alexandre Belfort de Almeida Chiacchio (ECI) — 123116732
-- Leon Barboza (Mat. Aplic.) — 121061020
-- Sávio Barreto Teles da Silva (ECI) — 120037175
-- William Petterle Pfaltzgraff (ECI) — 120021807
------------------------------------------------------------------
"""

import psycopg2
import numpy as np
import pandas as pd
import logging

# Configuração do logger para mensagens de erro
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# Configuração da conexão com seu banco PostgreSQL
# ATENÇÃO: Substitua 'seu_banco', 'seu_usuario', 'sua_senha', 'localhost' pelos seus dados reais
config = {
    'dbname': 'seu_banco',
    'user': 'seu_usuario',
    'password': 'sua_senha',
    'host': 'localhost',
    'port': '5432'
}

def construir_matriz_transicao():
    """
    Constrói a matriz de transição de probabilidades com base nos dados
    de locação de veículos entre pátios no banco de dados.

    Retorna:
        tuple: Uma tupla contendo a matriz de transição (numpy.ndarray)
               e a lista de IDs dos pátios (list).
    """
    conn = None
    cursor = None
    try:
        conn = psycopg2.connect(**config)
        cursor = conn.cursor()

        # 1. Obter IDs distintos dos pátios e criar um mapeamento de índice
        cursor.execute("SELECT DISTINCT ID_PATIO FROM DimVaga ORDER BY ID_PATIO;")
        patios = [row[0] for row in cursor.fetchall()]
        n = len(patios)
        patio_index = {pid: i for i, pid in enumerate(patios)}
        matriz = np.zeros((n, n), dtype=float)

        # 2. Contar as transições de veículos entre os pátios
        # Esta consulta junta a tabela FatoLocacao com DimVaga duas vezes
        # para obter os pátios de retirada e devolução de cada locação.
        cursor.execute("""
            SELECT V1.ID_PATIO, V2.ID_PATIO, COUNT(*)
            FROM FatoLocacao L
            JOIN DimVaga V1 ON L.Vaga_Retirada = V1.ID_Vaga
            JOIN DimVaga V2 ON L.Vaga_Devolucao = V2.ID_Vaga
            GROUP BY V1.ID_PATIO, V2.ID_PATIO;
        """)

        # 3. Preencher a matriz de contagens
        for origem, destino, total in cursor.fetchall():
            i = patio_index[origem]
            j = patio_index[destino]
            matriz[i][j] += total

        # 4. Normalizar a matriz para obter probabilidades de transição
        # Cada linha da matriz deve somar 1.
        # Trata o caso de divisão por zero: se uma linha soma 0 (nenhum carro saiu do pátio),
        # a divisão retorna 0 para aquela linha, indicando que não há transição de saída.
        row_sums = matriz.sum(axis=1, keepdims=True)
        matriz = np.divide(matriz, row_sums, out=np.zeros_like(matriz), where=row_sums!=0)

        logging.info("Matriz de transição construída com sucesso.")
        return matriz, patios

    except psycopg2.Error as e:
        logging.error(f"Erro ao conectar ou consultar o banco de dados: {e}")
        return None, None
    except Exception as e:
        logging.error(f"Ocorreu um erro inesperado: {e}")
        return None, None
    finally:
        # Garante que a conexão e o cursor sejam fechados, mesmo em caso de erro
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def obter_estado_inicial_do_banco(patios):
    """
    Obtém uma estimativa do estado inicial de ocupação dos pátios
    contando as devoluções mais recentes de veículos para cada pátio.

    Args:
        patios (list): A lista de IDs dos pátios, na mesma ordem usada pela matriz de transição.

    Retorna:
        numpy.ndarray: Um vetor de estado inicial com a contagem de veículos por pátio.
                       Retorna um vetor de zeros se houver um erro ou nenhum dado.
    """
    conn = None
    cursor = None
    try:
        conn = psycopg2.connect(**config)
        cursor = conn.cursor()

        # Mapeamento de pátio para índice para garantir a ordem correta no vetor de estado
        patio_index = {pid: i for i, pid in enumerate(patios)}
        estado_inicial = np.zeros(len(patios), dtype=float)

        # Consulta para contar o número de veículos devolvidos para cada pátio.
        # Esta é uma simplificação para um "estado inicial" se não houver uma tabela de inventário.
        # Para uma ocupação exata, seria necessário um rastreamento mais granular dos veículos.
        cursor.execute("""
            SELECT
                DV.ID_PATIO,
                COUNT(FL.ID_VEICULO) AS total_veiculos
            FROM FatoLocacao AS FL
            JOIN DimVaga AS DV ON FL.Vaga_Devolucao = DV.ID_Vaga
            -- Opcional: Adicionar um filtro de data se você quiser um estado inicial recente
            -- WHERE FL.Data_Devolucao >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY DV.ID_PATIO
            ORDER BY DV.ID_PATIO;
        """)

        for patio_id, count in cursor.fetchall():
            if patio_id in patio_index:
                estado_inicial[patio_index[patio_id]] = count

        logging.info("Estado inicial obtido do banco de dados com sucesso.")
        return estado_inicial

    except psycopg2.Error as e:
        logging.error(f"Erro ao obter estado inicial do banco de dados: {e}")
        return np.zeros(len(patios), dtype=float) # Retorna zeros em caso de erro
    except Exception as e:
        logging.error(f"Ocorreu um erro inesperado ao obter estado inicial: {e}")
        return np.zeros(len(patios), dtype=float) # Retorna zeros em caso de erro
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def simular_ocupacao(matriz, patios, estado_inicial, dias=10):
    """
    Simula a ocupação dos pátios ao longo do tempo usando a matriz de transição.

    Args:
        matriz (numpy.ndarray): A matriz de transição de probabilidades.
        patios (list): A lista de IDs dos pátios.
        estado_inicial (numpy.ndarray): O vetor de estado inicial de ocupação.
        dias (int): O número de dias para simular.

    Retorna:
        pandas.DataFrame: Um DataFrame mostrando a ocupação dos pátios por dia.
    """
    if matriz is None or estado_inicial is None:
        logging.warning("Matriz de transição ou estado inicial inválido. Não foi possível simular a ocupação.")
        return pd.DataFrame() # Retorna um DataFrame vazio

    # Verifica se a dimensão do estado inicial corresponde ao número de pátios na matriz
    if len(estado_inicial) != len(patios):
        logging.error("A dimensão do estado inicial não corresponde ao número de pátios.")
        return pd.DataFrame()

    estado_dia = [estado_inicial]
    for dia in range(dias):
        # A ocupação do próximo dia é calculada multiplicando o estado atual pela matriz de transição
        next_state = np.dot(estado_dia[-1], matriz)
        estado_dia.append(next_state)
        logging.info(f"Simulação do Dia {dia+1} concluída.")

    # Cria um DataFrame para visualizar os resultados da simulação
    df = pd.DataFrame(estado_dia, columns=[f"Pátio {p}" for p in patios])
    df.index.name = "Dia"
    logging.info("Simulação de ocupação concluída e DataFrame gerado.")
    return df.round(2)

# --- EXEMPLO DE USO ---
if __name__ == "__main__":
    logging.info("Iniciando a construção da matriz de transição...")
    matriz_transicao, ids_patios = construir_matriz_transicao()

    if matriz_transicao is not None and ids_patios:
        logging.info("Matriz de transição:")
        logging.info(matriz_transicao)
        logging.info("IDs dos Pátios:")
        logging.info(ids_patios)

        logging.info("Obtendo estado inicial do banco de dados...")
        estado_inicial_do_banco = obter_estado_inicial_do_banco(ids_patios)
        logging.info(f"Estado inicial obtido do banco: {estado_inicial_do_banco}")

        if np.sum(estado_inicial_do_banco) == 0:
            logging.warning("O estado inicial obtido do banco de dados é zero. A simulação pode não ter resultados significativos.")
            # Você pode optar por usar um estado inicial padrão aqui se o do banco for zero
            # estado_inicial_exemplo = np.array([100] * len(ids_patios))
            # logging.info(f"Usando estado inicial de exemplo: {estado_inicial_exemplo}")
            # estado_inicial_para_simulacao = estado_inicial_exemplo
            estado_inicial_para_simulacao = estado_inicial_do_banco # Usará o zero
        else:
            estado_inicial_para_simulacao = estado_inicial_do_banco


        logging.info("Iniciando a simulação de ocupação...")
        resultado_simulacao = simular_ocupacao(matriz_transicao, ids_patios, estado_inicial_para_simulacao, dias=10)

        if not resultado_simulacao.empty:
            logging.info("\nResultado da Simulação de Ocupação:")
            print(resultado_simulacao)
        else:
            logging.info("Nenhum resultado de simulação para exibir.")
    else:
        logging.error("Não foi possível construir a matriz de transição. Verifique as configurações do banco de dados e os logs de erro.")
