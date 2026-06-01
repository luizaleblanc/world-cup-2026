import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/copa_banner_header.dart';
import '../../../core/widgets/copa_flag_image.dart';
import '../../../core/widgets/theme_mode_button.dart';
import '../../auth/presentation/login_screen.dart';
import '../../equipes/presentation/equipes_screen.dart';
import '../../jogadores/presentation/jogadores_screen.dart';
import '../../campeonato/presentation/partidas_screen.dart';
import '../../campeonato/presentation/eliminatorias_screen.dart';
import '../../campeonato/presentation/em_breve_screen.dart';
import 'noticias_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  int _totalEquipes = 0;
  int _totalJogadores = 0;
  int _totalPartidas = 0;
  int _totalGols = 0;
  final int _totalGrupos = 12;
  bool _carregando = true;
  bool _emBreveSelecionado = false;
  List<dynamic> _partidasRecentes = [];

  bool get _isAdmin => true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final equipes = await _apiService.fetchEquipes();
    final jogadores = await _apiService.fetchJogadores();
    final partidas = await _apiService.fetchPartidas();

    if (!mounted) return;

    int somaGols = 0;
    for (var partida in partidas) {
      somaGols +=
          (int.tryParse(partida['placarCasa']?.toString() ?? '') ??
              int.tryParse(partida['placarEquipeCasa']?.toString() ?? '') ??
              0) +
          (int.tryParse(partida['placarVisitante']?.toString() ?? '') ??
              int.tryParse(
                partida['placarEquipeVisitante']?.toString() ?? '',
              ) ??
              0);
    }

    setState(() {
      _totalEquipes = equipes.length;
      _totalJogadores = jogadores.length;
      _totalPartidas = partidas.length;
      _totalGols = somaGols;
      _partidasRecentes = partidas.take(2).toList();
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4C0AD6),
                            image: DecorationImage(
                              image: AssetImage('assets/copa_banner.png'),
                              fit: BoxFit.fitHeight,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top > 0
                              ? MediaQuery.of(context).padding.top + 8
                              : 16,
                          left: 16,
                          child: Builder(
                            builder: (ctx) => Material(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                hoverColor: const Color(
                                  0xFF0B5FFF,
                                ).withValues(alpha: 0.15),
                                onTap: () => Scaffold.of(ctx).openDrawer(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.menu,
                                    color: Color(0xFF0B1F4D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top > 0
                              ? MediaQuery.of(context).padding.top + 8
                              : 16,
                          right: 16,
                          child: Column(
                            children: [
                              const HeaderCircleIconButton(
                                child: ThemeModeButton(),
                              ),
                              const SizedBox(height: 8),
                              HeaderCircleIconButton(
                                child: Tooltip(
                                  message: 'Atualizar',
                                  child: SizedBox.square(
                                    dimension: 44,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _carregarDados,
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Color(0xFF0B1F4D),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('HOJE'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('EM BREVE'),
                                ),
                              ],
                              selected: {_emBreveSelecionado},
                              onSelectionChanged: (selection) {
                                setState(
                                  () => _emBreveSelecionado = selection.first,
                                );
                              },
                              style: ButtonStyle(
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Offstage(
                            offstage: !_emBreveSelecionado,
                            child: const EmBreveContent(),
                          ),
                          Offstage(
                            offstage: _emBreveSelecionado,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                if (_partidasRecentes.isEmpty)
                                  _buildEmptyMatchesCard()
                                else
                                  ..._partidasRecentes.map(
                                    (partida) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _buildMatchCard(
                                        nameA:
                                            partida['selecaoCasa']
                                                ?.toString() ??
                                            'Seleção',
                                        nameB:
                                            partida['selecaoVisitante']
                                                ?.toString() ??
                                            'Seleção',
                                        score:
                                            '${partida['placarEquipeCasa'] ?? 0} - ${partida['placarEquipeVisitante'] ?? 0}',
                                        timeOrDate:
                                            partida['dataPartida']
                                                ?.toString() ??
                                            '',
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 32),
                                Text(
                                  'Visão Geral',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 800
                                      ? 4
                                      : 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  shrinkWrap: true,
                                  childAspectRatio:
                                      MediaQuery.of(context).size.width > 800
                                      ? 3.4
                                      : 2.45,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildEstatisticaCard(
                                      'Seleções',
                                      _totalEquipes.toString(),
                                      const Color(0xFF3B82F6),
                                      Icons.flag,
                                    ),
                                    _buildEstatisticaCard(
                                      'Jogadores',
                                      _totalJogadores.toString(),
                                      const Color(0xFF10B981),
                                      Icons.people,
                                    ),
                                    _buildEstatisticaCard(
                                      'Partidas',
                                      _totalPartidas.toString(),
                                      const Color(0xFFF59E0B),
                                      Icons.sports_soccer,
                                    ),
                                    _buildEstatisticaCard(
                                      'Gols',
                                      _totalGols.toString(),
                                      const Color(0xFFEF4444),
                                      Icons.sports_score,
                                    ),
                                    _buildEstatisticaCard(
                                      'Grupos',
                                      _totalGrupos.toString(),
                                      const Color(0xFF8B5CF6),
                                      Icons.table_chart,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMatchCard({
    required String nameA,
    required String nameB,
    required String score,
    required String timeOrDate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark
        ? const Color(0xFFD7E3FF)
        : const Color(0xFF64748B);
    final paisA = paisCopaPorNome(nameA);
    final paisB = paisCopaPorNome(nameB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CopaFlagImage(pais: paisA, width: 34, height: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameA,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Casa',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                score,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeOrDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: secondaryText,
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nameB,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Visitante',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CopaFlagImage(pais: paisB, width: 34, height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMatchesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        'Nenhuma partida registrada ainda.',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD7E3FF) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildEstatisticaCard(
    String titulo,
    String valor,
    Color cor,
    IconData icone,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF24324A)
        : const Color(0xFFF1F5F9);
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark
        ? const Color(0xFFD7E3FF)
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -10,
            child: Icon(icone, size: 48, color: cor.withValues(alpha: 0.045)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icone, color: cor, size: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 170,
            decoration: const BoxDecoration(color: Colors.black),
            child: Image.asset(
              'assets/copa_menu.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF160A3A),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(context, Icons.flag_outlined, 'Seleções', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipesScreen(canEdit: _isAdmin),
                    ),
                  ).then((_) => _carregarDados());
                }),
                _buildDrawerItem(
                  context,
                  Icons.people_outline,
                  'Jogadores',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JogadoresScreen(canEdit: _isAdmin),
                      ),
                    ).then((_) => _carregarDados());
                  },
                ),
                _buildDrawerItem(context, Icons.sports_soccer, 'Partidas', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartidasScreen(canEdit: _isAdmin),
                    ),
                  ).then((_) => _carregarDados());
                }),
                _buildDrawerItem(
                  context,
                  Icons.account_tree_outlined,
                  'Chaveamento',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EliminatoriasScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.article_outlined,
                  'Notícias',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticiasScreen(canEdit: _isAdmin),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1F2937)),
          _buildDrawerItem(context, Icons.logout, 'Sair', () async {
            await SessionService.clearSession();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }, isDestructive: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final foregroundColor = isDestructive
        ? const Color(0xFFEF4444)
        : Colors.white;
    final stateColor = isDestructive ? const Color(0xFFEF4444) : Colors.white;

    return ListTile(
      iconColor: foregroundColor,
      textColor: foregroundColor,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      selectedTileColor: stateColor.withValues(alpha: 0.14),
      splashColor: stateColor.withValues(alpha: 0.18),
      leading: Icon(icon, color: foregroundColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: foregroundColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
