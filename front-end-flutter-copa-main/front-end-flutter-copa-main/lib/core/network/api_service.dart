import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_service.dart';

class ApiService {
  bool _migracaoLocalExecutada = false;

  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  Future<String?> _getUserEmail() async {
    final session = await SessionService.getSession();
    final email = session?['email']?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  bool _sucesso(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) return false;
    final body = json.decode(response.body) as Map<String, dynamic>;
    final code = int.tryParse(body['code']?.toString() ?? '');
    return code == null || (code >= 200 && code < 300);
  }

  Future<List<dynamic>> _getList(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Erro ao buscar $path: $e');
    }
    return [];
  }

  Future<bool> _postOrPut(
    String path,
    Map<String, dynamic> body, {
    bool put = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = {'Content-Type': 'application/json'};
      final payload = json.encode(body);
      final response = put
          ? await http.put(uri, headers: headers, body: payload)
          : await http.post(uri, headers: headers, body: payload);
      return _sucesso(response);
    } catch (e) {
      debugPrint('Erro ao enviar $path: $e');
    }
    return false;
  }

  Future<bool> _delete(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      return _sucesso(response);
    } catch (e) {
      debugPrint('Erro ao remover $path: $e');
    }
    return false;
  }

  Future<void> _migrarDadosLocaisSePrecisar(String email) async {
    if (_migracaoLocalExecutada) return;
    _migracaoLocalExecutada = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'user_backend_migrated_$email';
      if (prefs.getBool(migrationKey) == true) return;

      final backendEquipes = await _getList(
        '/listaequipes',
        query: {'email': email},
      );
      if (backendEquipes.isNotEmpty) {
        await prefs.setBool(migrationKey, true);
        return;
      }

      final equipesLocal =
          json.decode(prefs.getString('user_equipes_$email') ?? '[]')
              as List<dynamic>;
      final jogadoresLocal =
          json.decode(prefs.getString('user_jogadores_$email') ?? '[]')
              as List<dynamic>;
      final partidasLocal =
          json.decode(prefs.getString('user_partidas_$email') ?? '[]')
              as List<dynamic>;

      for (final item in equipesLocal) {
        await _postOrPut('/cadastraequipe', {
          'email': email,
          'nomeEquipe': item['nome'],
          'cidadeEquipe': item['cidade'],
        });
      }

      final equipesMigradas = await _getList(
        '/listaequipes',
        query: {'email': email},
      );
      final idsAntigosParaNovos = <int, int>{};
      for (final antiga in equipesLocal) {
        final nome = antiga['nome']?.toString();
        final idAntigo = int.tryParse(antiga['idTime']?.toString() ?? '');
        if (nome == null || idAntigo == null) continue;

        for (final nova in equipesMigradas) {
          if (nova['nome']?.toString() == nome) {
            final idNovo = int.tryParse(nova['idTime']?.toString() ?? '');
            if (idNovo != null) idsAntigosParaNovos[idAntigo] = idNovo;
            break;
          }
        }
      }

      for (final item in jogadoresLocal) {
        await _postOrPut('/cadastrajogador', {
          'email': email,
          'nomeJogador': item['nomeJogador'],
          'posicaoJogador': item['posicaoJogador'],
          'idTimeFk': item['idTimeFk'],
        });
      }

      for (final item in partidasLocal) {
        final idCasaAntigo = int.tryParse(
          item['idEquipeCasa']?.toString() ?? '',
        );
        final idVisitanteAntigo = int.tryParse(
          item['idEquipeVisitante']?.toString() ?? '',
        );
        final idCasa = idsAntigosParaNovos[idCasaAntigo];
        final idVisitante = idsAntigosParaNovos[idVisitanteAntigo];
        if (idCasa == null || idVisitante == null) continue;

        await _postOrPut('/cadastrapartida', {
          'email': email,
          'dataPartida': item['dataPartida'],
          'placarEquipeCasa': item['placarEquipeCasa'],
          'placarEquipeVisitante': item['placarEquipeVisitante'],
          'idEquipeCasa': idCasa,
          'idEquipeVisitante': idVisitante,
        });
      }

      await prefs.setBool(migrationKey, true);
    } catch (e) {
      debugPrint('Erro ao migrar dados locais para o backend: $e');
    }
  }

  Future<bool> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String perguntaSeguranca,
    required String respostaSeguranca,
  }) async {
    return _postOrPut('/cadastro', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'pergunta_seguranca': perguntaSeguranca,
      'resposta_seguranca': respostaSeguranca,
    });
  }

  Future<Map<String, dynamic>?> loginUsuario({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['code'] == 200) return body;
      }
    } catch (e) {
      debugPrint('Erro ao fazer login: $e');
    }
    return null;
  }

  Future<bool> validarRecuperacao({
    required String email,
    required String perguntaSeguranca,
    required String respostaSeguranca,
  }) async {
    return _postOrPut('/recuperar/validar', {
      'email': email,
      'pergunta_seguranca': perguntaSeguranca,
      'resposta_seguranca': respostaSeguranca,
    });
  }

  Future<List<dynamic>> fetchEquipes() async {
    final email = await _getUserEmail();
    if (email == null) return [];
    await _migrarDadosLocaisSePrecisar(email);
    return _getList('/listaequipes', query: {'email': email});
  }

  Future<bool> cadastrarEquipe(String nome, String cidade) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/cadastraequipe', {
      'email': email,
      'nomeEquipe': nome,
      'cidadeEquipe': cidade,
    });
  }

  Future<bool> atualizarEquipe(int idEquipe, String nome, String cidade) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/atualizaequipe', {
      'email': email,
      'idEquipe': idEquipe,
      'nomeEquipe': nome,
      'cidadeEquipe': cidade,
    }, put: true);
  }

  Future<bool> deletarEquipe(int idEquipe) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _delete('/removeequipe', {'email': email, 'idEquipe': idEquipe});
  }

  Future<List<dynamic>> fetchJogadores({int? idSelecao}) async {
    final email = await _getUserEmail();
    if (email == null) return [];
    await _migrarDadosLocaisSePrecisar(email);
    return _getList(
      '/listajogadores',
      query: {
        'email': email,
        if (idSelecao != null) 'idSelecao': idSelecao.toString(),
      },
    );
  }

  Future<List<dynamic>> fetchCatalogoJogadores({required int idSelecao}) {
    return _getList(
      '/listajogadores',
      query: {'catalogo': '1', 'idSelecao': idSelecao.toString()},
    );
  }

  Future<bool> cadastrarJogador(
    String nome,
    String posicao,
    int idEquipe,
  ) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/cadastrajogador', {
      'email': email,
      'nomeJogador': nome,
      'posicaoJogador': posicao,
      'idTimeFk': idEquipe,
    });
  }

  Future<bool> atualizarJogador(
    int idJogador,
    String nome,
    String posicao,
    int idEquipe,
  ) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/atualizajogador', {
      'email': email,
      'idJogador': idJogador,
      'nomeJogador': nome,
      'posicaoJogador': posicao,
      'idTimeFk': idEquipe,
    }, put: true);
  }

  Future<bool> deletarJogador(int idJogador) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _delete('/removejogador', {'email': email, 'idJogador': idJogador});
  }

  Future<List<dynamic>> fetchPartidas() async {
    final email = await _getUserEmail();
    if (email == null) return [];
    await _migrarDadosLocaisSePrecisar(email);
    return _getList('/listapartidas', query: {'email': email});
  }

  Future<bool> cadastrarPartida(
    String data,
    int placarCasa,
    int placarVisitante,
    int idEquipeCasa,
    int idEquipeVisitante,
  ) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/cadastrapartida', {
      'email': email,
      'dataPartida': data,
      'placarEquipeCasa': placarCasa,
      'placarEquipeVisitante': placarVisitante,
      'idEquipeCasa': idEquipeCasa,
      'idEquipeVisitante': idEquipeVisitante,
    });
  }

  Future<bool> atualizarPartida(
    int idPartida,
    String data,
    int placarCasa,
    int placarVisitante,
    int idEquipeCasa,
    int idEquipeVisitante,
  ) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _postOrPut('/atualizapartida', {
      'email': email,
      'idPartida': idPartida,
      'dataPartida': data,
      'placarEquipeCasa': placarCasa,
      'placarEquipeVisitante': placarVisitante,
      'idEquipeCasa': idEquipeCasa,
      'idEquipeVisitante': idEquipeVisitante,
    }, put: true);
  }

  Future<bool> deletarPartida(int idPartida) async {
    final email = await _getUserEmail();
    if (email == null) return false;
    return _delete('/removepartida', {'email': email, 'idPartida': idPartida});
  }
}
