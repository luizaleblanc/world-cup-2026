"""Regras de negócio de autenticação: cadastro, login e recuperação de senha."""

import pymysql
from flask import session

from app.database.connection import conectaBanco


def cadastro_usuario(dados: dict) -> dict:
    """Cadastra um novo usuário. Todos os usuários são ADM por padrão."""
    nome = dados.get("nome")
    email = dados.get("email")
    senha = dados.get("senha")
    pergunta = dados.get("pergunta_seguranca")
    resposta = dados.get("resposta_seguranca")

    if not all([nome, email, senha, pergunta, resposta]):
        return {"mensagem": "Todos os campos são obrigatórios.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        sql = """INSERT INTO usuario (nome, email, senha, pergunta_seguranca, resposta_seguranca)
                 VALUES (%s, %s, %s, %s, %s);"""
        cursor.execute(sql, (nome, email, senha, pergunta, resposta))
        bd.commit()
        id_usuario = cursor.lastrowid
        session["id_usuario"] = id_usuario
        session["email"] = email
        return {
            "mensagem": "Usuário cadastrado com sucesso!",
            "code": 201,
            "id_usuario": id_usuario,
            "idUsuario": id_usuario,
            "nome": nome,
            "email": email,
        }
    except pymysql.MySQLError:
        return {"mensagem": "Erro ao cadastrar. Email já cadastrado no sistema.", "code": 400}
    finally:
        bd.close()


def login_usuario(dados: dict) -> dict:
    """Valida e-mail e senha. Retorna os dados do usuário em caso de sucesso."""
    email = dados.get("email")
    senha = dados.get("senha")

    if not all([email, senha]):
        return {"mensagem": "Email e senha são obrigatórios.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    sql = "SELECT id_usuario, nome, email FROM usuario WHERE email = %s AND senha = %s;"
    cursor.execute(sql, (email, senha))
    usuario = cursor.fetchone()
    bd.close()

    if usuario:
        session["id_usuario"] = usuario[0]
        session["email"] = usuario[2]
        return {
            "code": 200,
            "id_usuario": usuario[0],
            "idUsuario": usuario[0],
            "nome": usuario[1],
            "email": usuario[2],
        }
    return {"mensagem": "Credenciais incorretas.", "code": 401}


def buscar_pergunta_seguranca(dados: dict) -> dict:
    """Retorna a pergunta de segurança associada ao e-mail informado."""
    email = dados.get("email")

    if not email:
        return {"mensagem": "Email é obrigatório.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    sql = "SELECT pergunta_seguranca FROM usuario WHERE email = %s;"
    cursor.execute(sql, (email,))
    resultado = cursor.fetchone()
    bd.close()

    if resultado:
        return {"pergunta_seguranca": resultado[0], "code": 200}
    return {"mensagem": "Email não encontrado.", "code": 404}


def validar_recuperacao(dados: dict) -> dict:
    """Valida e-mail + pergunta + resposta antes de permitir trocar a senha."""
    email = dados.get("email")
    pergunta = dados.get("pergunta_seguranca")
    resposta = dados.get("resposta_seguranca")

    bd = conectaBanco()
    cursor = bd.cursor()
    sql = """SELECT id_usuario FROM usuario
             WHERE email = %s AND pergunta_seguranca = %s AND resposta_seguranca = %s;"""
    cursor.execute(sql, (email, pergunta, resposta))
    resultado = cursor.fetchone()
    bd.close()

    if resultado:
        return {"mensagem": "Dados de recuperação confirmados.", "code": 200}
    return {"mensagem": "Email ou resposta de segurança inválidos.", "code": 400}


def alterar_senha_por_recuperacao(dados: dict) -> dict:
    """Altera a senha do usuário após validar a resposta de segurança."""
    email = dados.get("email")
    resposta = dados.get("resposta_seguranca")
    nova_senha = dados.get("nova_senha")

    if not all([email, resposta, nova_senha]):
        return {"mensagem": "Todos os campos são obrigatórios.", "code": 400}

    bd = conectaBanco()
    cursor = bd.cursor()
    sql = "UPDATE usuario SET senha = %s WHERE email = %s AND resposta_seguranca = %s;"
    cursor.execute(sql, (nova_senha, email, resposta))
    bd.commit()
    resultado = cursor.rowcount
    bd.close()

    if resultado > 0:
        return {"mensagem": "Senha redefinida com sucesso!", "code": 200}
    return {"mensagem": "Resposta de segurança inválida.", "code": 400}
