"""Rotas HTTP de seleÃ§Ãµes â€” delega a lÃ³gica para selecoes_service."""

from flask import Blueprint, jsonify, request

from app.services.selecoes_service import (
    atualizar_selecao,
    criar_selecao,
    listar_selecoes,
    remover_selecao,
)

selecoes_bp = Blueprint("selecoes", __name__)


# Flutter chama: GET /listaequipes
@selecoes_bp.route("/listaequipes", methods=["GET"])
def consulta_selecoes():
    return jsonify(listar_selecoes())


# Flutter chama: POST /cadastraequipe  â†’  body: {nomeEquipe, cidadeEquipe}
@selecoes_bp.route("/cadastraequipe", methods=["POST"])
def create_selecao():
    resultado = criar_selecao(request.get_json() or {})
    return jsonify(resultado), resultado.get('code', 200)


# Flutter chama: PUT /atualizaequipe  â†’  body: {idEquipe, nomeEquipe, cidadeEquipe}
@selecoes_bp.route("/atualizaequipe", methods=["PUT"])
def update_selecao():
    resultado = atualizar_selecao(request.get_json() or {})
    return jsonify(resultado), resultado.get('code', 200)


# Flutter chama: DELETE /removeequipe  â†’  body: {idEquipe}
@selecoes_bp.route("/removeequipe", methods=["DELETE"])
def delete_selecao():
    resultado = remover_selecao(request.get_json() or {})
    return jsonify(resultado), resultado.get('code', 200)

