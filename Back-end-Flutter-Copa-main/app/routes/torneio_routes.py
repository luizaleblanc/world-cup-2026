"""Rotas HTTP de dados do torneio (fases e chaveamento)."""

from flask import Blueprint, jsonify

from app.services.torneio_service import listar_chaveamento, listar_fases

torneio_bp = Blueprint("torneio", __name__)


@torneio_bp.route("/listafases", methods=["GET"])
def consulta_fases():
    return jsonify(listar_fases())


@torneio_bp.route("/listachaveamento", methods=["GET"])
def consulta_chaveamento():
    return jsonify(listar_chaveamento())
