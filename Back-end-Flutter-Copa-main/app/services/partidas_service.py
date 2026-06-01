"""Regras de negócio de partidas (CRUD) — campos alinhados com o Flutter."""

import pymysql

from app.database.connection import conectaBanco
from app.services.user_context import resolver_id_usuario


def listar_partidas() -> list:
    """Retorna todas as partidas com nomes das seleções via JOIN.
    Flutter espera: idPartida, dataPartida, selecaoCasa, selecaoVisitante,
                    placarEquipeCasa, placarEquipeVisitante, idEquipeCasa, idEquipeVisitante.
    """
    bd = conectaBanco()
    cursor = bd.cursor()
    id_usuario = resolver_id_usuario()
    sql = """
        SELECT p.id_partidas,
               p.data,
               s1.nome AS selecao_casa,
               s2.nome AS selecao_visitante,
               p.placar_casa,
               p.placar_visitante,
               p.id_selecao_casa_fk,
               p.id_selecao_visitante_fk
        FROM partidas p
        JOIN selecao s1 ON p.id_selecao_casa_fk = s1.id_selecao
        JOIN selecao s2 ON p.id_selecao_visitante_fk = s2.id_selecao
    """
    if id_usuario:
        sql += " WHERE p.id_usuario_fk = %s;"
        cursor.execute(sql, (id_usuario,))
    else:
        sql += ";"
        cursor.execute(sql)
    resultado = cursor.fetchall()
    bd.close()

    return [
        {
            "idPartida": part[0],               # Flutter usa idPartida
            "dataPartida": str(part[1]),         # Flutter usa dataPartida
            "selecaoCasa": part[2],              # Flutter usa selecaoCasa
            "selecaoVisitante": part[3],         # Flutter usa selecaoVisitante
            "placarEquipeCasa": part[4],         # Flutter usa placarEquipeCasa
            "placarEquipeVisitante": part[5],    # Flutter usa placarEquipeVisitante
            "idEquipeCasa": part[6],             # Flutter usa idEquipeCasa
            "idEquipeVisitante": part[7],        # Flutter usa idEquipeVisitante
        }
        for part in resultado
    ]


def criar_partida(dados: dict) -> dict:
    """Cadastra uma nova partida.
    Flutter envia: dataPartida, placarEquipeCasa, placarEquipeVisitante,
                   idEquipeCasa, idEquipeVisitante.
    """
    data = dados.get("dataPartida")
    placar_casa = dados.get("placarEquipeCasa")
    placar_visitante = dados.get("placarEquipeVisitante")
    id_casa = dados.get("idEquipeCasa")
    id_visitante = dados.get("idEquipeVisitante")
    id_usuario = resolver_id_usuario(dados)

    if not all([data, id_casa, id_visitante]):
        return {"mensagem": "Data e IDs das seleções são obrigatórios.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        cursor.execute(
            """INSERT INTO partidas
               (data, placar_casa, placar_visitante, id_selecao_casa_fk, id_selecao_visitante_fk, id_usuario_fk)
               VALUES (%s, %s, %s, %s, %s, %s);""",
            (data, placar_casa, placar_visitante, id_casa, id_visitante, id_usuario),
        )
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.err.IntegrityError:
        bd.rollback()
        return {"mensagem": "Seleções inválidas para registrar partida.", "code": 400}
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao registrar partida.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Partida registrada com sucesso!", "code": 200}
    return {"mensagem": "Erro ao registrar partida.", "code": 400}


def atualizar_partida(dados: dict) -> dict:
    """Atualiza uma partida existente.
    Flutter envia: idPartida, dataPartida, placarEquipeCasa, placarEquipeVisitante,
                   idEquipeCasa, idEquipeVisitante.
    """
    id_partida = dados.get("idPartida")
    data = dados.get("dataPartida")
    placar_casa = dados.get("placarEquipeCasa")
    placar_visitante = dados.get("placarEquipeVisitante")
    id_casa = dados.get("idEquipeCasa")
    id_visitante = dados.get("idEquipeVisitante")
    id_usuario = resolver_id_usuario(dados)

    if not id_partida:
        return {"mensagem": "ID da partida é obrigatório.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        if id_usuario:
            cursor.execute(
                """UPDATE partidas
                   SET data = %s, placar_casa = %s, placar_visitante = %s,
                       id_selecao_casa_fk = %s, id_selecao_visitante_fk = %s
                   WHERE id_partidas = %s AND id_usuario_fk = %s;""",
                (data, placar_casa, placar_visitante, id_casa, id_visitante, id_partida, id_usuario),
            )
        else:
            cursor.execute(
                """UPDATE partidas
                   SET data = %s, placar_casa = %s, placar_visitante = %s,
                       id_selecao_casa_fk = %s, id_selecao_visitante_fk = %s
                   WHERE id_partidas = %s;""",
                (data, placar_casa, placar_visitante, id_casa, id_visitante, id_partida),
            )
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.err.IntegrityError:
        bd.rollback()
        return {"mensagem": "Seleções inválidas para atualizar partida.", "code": 400}
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao atualizar partida.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Partida atualizada com sucesso!", "code": 200}
    return {"mensagem": "Partida não localizada ou sem alterações.", "code": 400}


def remover_partida(dados: dict) -> dict:
    """Remove uma partida do banco.
    Flutter envia: idPartida.
    """
    id_partida = dados.get("idPartida")
    id_usuario = resolver_id_usuario(dados)

    if not id_partida:
        return {"mensagem": "ID da partida é obrigatório.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        if id_usuario:
            cursor.execute(
                "DELETE FROM partidas WHERE id_partidas = %s AND id_usuario_fk = %s;",
                (id_partida, id_usuario),
            )
        else:
            cursor.execute("DELETE FROM partidas WHERE id_partidas = %s;", (id_partida,))
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao remover partida.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Partida removida com sucesso!", "code": 200}
    return {"mensagem": "Partida não localizada.", "code": 400}
