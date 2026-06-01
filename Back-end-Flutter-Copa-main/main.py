"""Ponto de entrada do backend: cria o app Flask e inicia o servidor."""

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
