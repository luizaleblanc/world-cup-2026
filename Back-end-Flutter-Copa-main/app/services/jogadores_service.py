"""Regras de negócio de jogadores (CRUD) — campos alinhados com o Flutter."""

import pymysql

from app.database.connection import conectaBanco
from app.services.user_context import resolver_id_usuario


def listar_jogadores(id_selecao: str = None) -> list:
    """Retorna jogadores. Se id_selecao for passado, filtra por seleção.
    Flutter espera: idJogador, nomeJogador, posicaoJogador, idTimeFk, nomeSelecao.
    """
    bd = conectaBanco()
    cursor = bd.cursor()
    id_usuario = resolver_id_usuario()
    catalogo = False
    try:
        from flask import request

        catalogo = request.args.get("catalogo") == "1"
    except RuntimeError:
        catalogo = False

    if catalogo and id_selecao:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao
                 WHERE j.id_selecao_fk = %s AND j.id_usuario_fk IS NULL;"""
        cursor.execute(sql, (id_selecao,))
    elif catalogo:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao
                 WHERE j.id_usuario_fk IS NULL;"""
        cursor.execute(sql)
    elif id_selecao and id_usuario:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao
                 WHERE j.id_selecao_fk = %s AND j.id_usuario_fk = %s;"""
        cursor.execute(sql, (id_selecao, id_usuario))
    elif id_selecao:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao
                 WHERE j.id_selecao_fk = %s;"""
        cursor.execute(sql, (id_selecao,))
    elif id_usuario:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao
                 WHERE j.id_usuario_fk = %s;"""
        cursor.execute(sql, (id_usuario,))
    else:
        sql = """SELECT j.id_jogador, j.nome, j.posicao, j.id_selecao_fk, s.nome
                 FROM jogador j
                 JOIN selecao s ON j.id_selecao_fk = s.id_selecao;"""
        cursor.execute(sql)

    resultado = cursor.fetchall()
    bd.close()

    return [
        {
            "idJogador": jog[0],        # Flutter usa idJogador
            "nomeJogador": jog[1],      # Flutter usa nomeJogador
            "posicaoJogador": jog[2],   # Flutter usa posicaoJogador
            "idTimeFk": jog[3],         # Flutter usa idTimeFk
            "nomeSelecao": jog[4],      # Flutter usa nomeSelecao
        }
        for jog in resultado
    ]


def criar_jogador(dados: dict) -> dict:
    """Cadastra um novo jogador.
    Flutter envia: nomeJogador, posicaoJogador, idTimeFk.
    """
    nome = dados.get("nomeJogador")
    posicao = dados.get("posicaoJogador")
    id_selecao = dados.get("idTimeFk")
    id_usuario = resolver_id_usuario(dados)

    if not all([nome, posicao, id_selecao]):
        return {"mensagem": "Nome, posição e seleção são obrigatórios.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        cursor.execute(
            "INSERT INTO jogador (nome, posicao, id_selecao_fk, id_usuario_fk) VALUES (%s, %s, %s, %s);",
            (nome, posicao, id_selecao, id_usuario),
        )
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.err.IntegrityError:
        bd.rollback()
        return {"mensagem": "Seleção inválida para cadastrar jogador.", "code": 400}
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao cadastrar jogador.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Jogador cadastrado com sucesso!", "code": 200}
    return {"mensagem": "Erro ao cadastrar jogador.", "code": 400}


def atualizar_jogador(dados: dict) -> dict:
    """Atualiza um jogador existente.
    Flutter envia: idJogador, nomeJogador, posicaoJogador, idTimeFk.
    """
    id_jogador = dados.get("idJogador")
    nome = dados.get("nomeJogador")
    posicao = dados.get("posicaoJogador")
    id_selecao = dados.get("idTimeFk")
    id_usuario = resolver_id_usuario(dados)

    if not id_jogador:
        return {"mensagem": "ID do jogador é obrigatório.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        if id_usuario:
            cursor.execute(
                """UPDATE jogador
                   SET nome = %s, posicao = %s, id_selecao_fk = %s
                   WHERE id_jogador = %s AND id_usuario_fk = %s;""",
                (nome, posicao, id_selecao, id_jogador, id_usuario),
            )
        else:
            cursor.execute(
                "UPDATE jogador SET nome = %s, posicao = %s, id_selecao_fk = %s WHERE id_jogador = %s;",
                (nome, posicao, id_selecao, id_jogador),
            )
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.err.IntegrityError:
        bd.rollback()
        return {"mensagem": "Seleção inválida para atualizar jogador.", "code": 400}
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao atualizar jogador.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Dados do jogador atualizados!", "code": 200}
    return {"mensagem": "Jogador não localizado ou sem alterações.", "code": 400}


def remover_jogador(dados: dict) -> dict:
    """Remove um jogador do banco.
    Flutter envia: idJogador.
    """
    id_jogador = dados.get("idJogador")
    id_usuario = resolver_id_usuario(dados)

    if not id_jogador:
        return {"mensagem": "ID do jogador é obrigatório.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        if id_usuario:
            cursor.execute(
                "DELETE FROM jogador WHERE id_jogador = %s AND id_usuario_fk = %s;",
                (id_jogador, id_usuario),
            )
        else:
            cursor.execute("DELETE FROM jogador WHERE id_jogador = %s;", (id_jogador,))
        bd.commit()
        resultado = cursor.rowcount
    except pymysql.MySQLError:
        bd.rollback()
        return {"mensagem": "Erro ao remover jogador.", "code": 400}
    finally:
        bd.close()

    if resultado > 0:
        return {"mensagem": "Jogador removido com sucesso!", "code": 200}
    return {"mensagem": "Jogador não localizado.", "code": 400}
