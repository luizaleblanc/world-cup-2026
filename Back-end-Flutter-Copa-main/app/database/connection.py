"""Conexao com o MySQL - le as credenciais do arquivo .env."""

import os

import pymysql
from dotenv import load_dotenv
from pymysql import OperationalError

# Carrega as variaveis do arquivo .env (cada dev tem o seu com sua senha).
load_dotenv()


def conectaBanco():
    """Retorna uma conexao aberta com o banco MySQL.

    As credenciais sao lidas do .env:
        DB_NAME     - nome do banco (padrao: copado_mundo)
        DB_HOST     - endereco do servidor (padrao: localhost)
        DB_USER     - usuario MySQL (padrao: root)
        DB_PASSWORD - senha do MySQL
        DB_PORT     - porta (padrao: 3306)
    """
    database = os.getenv("DB_NAME", "copado_mundo")
    host = os.getenv("DB_HOST", "localhost")
    user = os.getenv("DB_USER", "root")
    password = os.getenv("DB_PASSWORD", "")
    port = int(os.getenv("DB_PORT", 3306))

    try:
        return pymysql.connect(
            database=database,
            host=host,
            user=user,
            passwd=password,
            port=port,
            charset="utf8mb4",
            connect_timeout=5,
        )
    except OperationalError as exc:
        code = exc.args[0] if exc.args else None
        dicas = {
            1045: "usuario/senha incorretos. Crie o .env a partir do .env.example e ajuste DB_USER/DB_PASSWORD.",
            1049: f"banco '{database}' nao existe. Importe o arquivo copa.sql no MySQL.",
            2003: f"nao foi possivel conectar em {host}:{port}. Confira se o MySQL esta rodando.",
        }
        detalhe = dicas.get(
            code,
            "falha ao conectar no MySQL. Confira o .env e o servico do MySQL.",
        )
        raise RuntimeError(f"Erro de banco de dados ({code}): {detalhe}") from exc
