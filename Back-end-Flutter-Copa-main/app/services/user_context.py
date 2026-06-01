"""Helpers para identificar o usuario atual nas rotas."""

from flask import has_request_context, request, session

from app.database.connection import conectaBanco


def buscar_id_usuario_por_email(email: str | None) -> int | None:
    if not email:
        return None

    bd = conectaBanco()
    cursor = bd.cursor()
    try:
        cursor.execute("SELECT id_usuario FROM usuario WHERE email = %s;", (email,))
        resultado = cursor.fetchone()
        return resultado[0] if resultado else None
    finally:
        bd.close()


def resolver_id_usuario(dados: dict | None = None) -> int | None:
    """Resolve o usuario por body, query string, headers ou sessao Flask."""
    dados = dados or {}

    for chave in ("idUsuario", "id_usuario", "idUsuarioFk", "id_usuario_fk"):
        valor = dados.get(chave)
        if valor:
            return int(valor)

    email = dados.get("email") or dados.get("usuarioEmail")

    if has_request_context():
        for chave in ("idUsuario", "id_usuario", "idUsuarioFk", "id_usuario_fk"):
            valor = request.args.get(chave) or request.headers.get(chave)
            if valor:
                return int(valor)

        email = (
            email
            or request.args.get("email")
            or request.args.get("usuarioEmail")
            or request.headers.get("email")
            or request.headers.get("usuarioEmail")
        )

        id_sessao = session.get("id_usuario")
        if id_sessao:
            return int(id_sessao)

    return buscar_id_usuario_por_email(email)
