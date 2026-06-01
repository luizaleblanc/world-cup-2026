# Front-end Flutter Copa

Aplicativo **Flutter** da Copa do Mundo 2026 — interface de acompanhamento e gestão do torneio.

Repositório do back-end: [Back-end-Flutter-Copa](https://github.com/Monalisaess/Back-end-Flutter-Copa)

## Estrutura

```
lib/
├── main.dart
├── core/           # ApiService, tema, widgets globais
└── features/
    ├── auth/       # Login, cadastro, perfil ADM
    ├── dashboard/  # Painel e notícias
    ├── equipes/    # Seleções
    ├── jogadores/
    └── campeonato/ # Partidas e chaveamento
assets/             # Imagens do app
android/, web/      # Plataformas
```

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Back-end rodando em `http://localhost:5000` (ver README do repositório da API)

## Executar

```powershell
flutter pub get
flutter run -d chrome
```

No emulador Android, a API usa `http://10.0.2.2:5000` (configurado em `lib/core/network/api_service.dart`).

## Funcionalidades

- Login, cadastro e recuperação de senha (API)
- Tema claro/escuro
- Dashboard com estatísticas
- CRUD de seleções, jogadores e partidas
- Chaveamento e notícias
- Tela de perfil administrador

## Autores

- Luiza Ferraz — Mobile Front-End/UX
- Anny Luisa — Mobile Back-end
- Maria Isabel Mariz — Mobile Full-Stack
- Monalisa Ellen — Arquitetura/Back-end
