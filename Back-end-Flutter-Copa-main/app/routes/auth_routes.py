"""Rotas HTTP de autenticação — delega a lógica para auth_service."""

from flask import Blueprint, jsonify, request

from app.services.auth_service import (
    alterar_senha_por_recuperacao,
    buscar_pergunta_seguranca,
    cadastro_usuario,
    login_usuario,
    validar_recuperacao,
)

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/cadastro", methods=["POST"])
def cadastro():
    resultado = cadastro_usuario(request.get_json() or {})
    return jsonify(resultado), resultado.get("code", 200)


@auth_bp.route("/login", methods=["POST"])
def login():
    resultado = login_usuario(request.get_json() or {})
    return jsonify(resultado), resultado.get("code", 200)


@auth_bp.route("/recuperar/pergunta", methods=["POST"])
def buscar_pergunta():
    resultado = buscar_pergunta_seguranca(request.get_json() or {})
    return jsonify(resultado), resultado.get("code", 200)


@auth_bp.route("/recuperar/validar", methods=["POST"])
def validar_recuperacao_route():
    resultado = validar_recuperacao(request.get_json() or {})
    return jsonify(resultado), resultado.get("code", 200)


@auth_bp.route("/recuperar/senha", methods=["POST"])
def alterar_senha():
    resultado = alterar_senha_por_recuperacao(request.get_json() or {})
    return jsonify(resultado), resultado.get("code", 200)
