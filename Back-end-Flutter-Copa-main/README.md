# Back-end Flutter Copa

API REST em **Python (Flask)** para o app Flutter da Copa do Mundo 2026.

Repositório do front-end: configure a URL da API no `ApiService` do projeto Flutter (`http://localhost:5000` em desenvolvimento).

## Estrutura

```
├── main.py              # Inicia o servidor Flask
├── requirements.txt     # Dependências Python
├── copa.sql             # Script do banco MySQL
├── .env.example         # Modelo de variáveis de ambiente
└── app/
    ├── __init__.py      # create_app() + CORS + blueprints
    ├── database/        # Conexão MySQL
    ├── routes/          # Endpoints HTTP
    └── services/        # Regras de negócio e SQL
```

## Pré-requisitos

- Python 3.10+
- MySQL

## Configuração

1. Importe `copa.sql` no MySQL (banco `copado_mundo`).
2. Copie o arquivo de exemplo e preencha sua senha:

```powershell
copy .env.example .env
```

3. Instale as dependências e suba o servidor:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python main.py
```

Servidor: `http://localhost:5000` (porta padrão Flask).

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/cadastro`, `/login` | Autenticação |
| POST | `/recuperar/*` | Recuperação de senha |
| GET/POST/PUT/DELETE | `/listaequipes`, `/cadastraequipe`, … | Seleções |
| GET/POST/PUT/DELETE | `/listajogadores`, … | Jogadores |
| GET/POST/PUT/DELETE | `/listapartidas`, … | Partidas |
| GET | `/listafases`, `/listachaveamento` | Dados do torneio |

## Autores

- Luiza Ferraz — Mobile Front-End/UX
- Anny Luisa — Mobile Back-end
- Maria Isabel Mariz — Mobile Full-Stack
- Monalisa Ellen — Arquitetura/Back-end
