"""Fábrica do app Flask: cria a instância e registra os Blueprints."""

import os

from flask import Flask
from flask_cors import CORS

from app.routes.auth_routes import auth_bp
from app.routes.selecoes_routes import selecoes_bp
from app.routes.jogadores_routes import jogadores_bp
from app.routes.partidas_routes import partidas_bp
from app.routes.torneio_routes import torneio_bp
from app.services.schema_service import garantir_colunas_usuario


def create_app() -> Flask:
    app = Flask(__name__)
    app.secret_key = os.getenv("SECRET_KEY", "copa-do-mundo-dev")
    CORS(app, supports_credentials=True)

    with app.app_context():
        garantir_colunas_usuario()

    app.register_blueprint(auth_bp)
    app.register_blueprint(selecoes_bp)
    app.register_blueprint(jogadores_bp)
    app.register_blueprint(partidas_bp)
    app.register_blueprint(torneio_bp)

    return app
