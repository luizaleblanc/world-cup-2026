import 'package:flutter/material.dart';

import '../../../core/widgets/copa_flag_image.dart';

class EmBreveContent extends StatelessWidget {
  const EmBreveContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmBreveContent();
  }
}

class _EmBreveContent extends StatefulWidget {
  const _EmBreveContent();

  @override
  State<_EmBreveContent> createState() => _EmBreveContentState();
}

class _EmBreveContentState extends State<_EmBreveContent> {
  // Favoritos existem apenas durante a sessão atual desta tela.
  final Set<String> _favoriteGroupIds = {};
  final List<_FavoriteMatch> _favoriteMatches = [];

  bool _somenteFavoritos = false;

  Map<String, List<PaisCopa>> get _grupos {
    final grupos = <String, List<PaisCopa>>{};

    for (final pais in paisesCopa) {
      grupos.putIfAbsent(pais.grupo, () => []).add(pais);
    }

    return Map.fromEntries(
      grupos.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _alternarFavorito(String grupo) {
    setState(() {
      if (!_favoriteGroupIds.remove(grupo)) {
        _favoriteGroupIds.add(grupo);
      }
    });
  }

  Future<void> _abrirGrupo(String grupo, List<PaisCopa> equipes) async {
    final selecionadas = <PaisCopa>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> alternarSelecao(PaisCopa equipe) async {
              if (selecionadas.contains(equipe)) {
                setModalState(() => selecionadas.remove(equipe));
                return;
              }

              if (selecionadas.length >= 2) return;

              setModalState(() => selecionadas.add(equipe));
              if (selecionadas.length != 2) return;

              final partida = _FavoriteMatch(
                grupo: grupo,
                equipeA: selecionadas[0],
                equipeB: selecionadas[1],
              );
              final confirmar = await _confirmarPartida(context, partida);

              if (!context.mounted) return;
              if (confirmar) {
                setState(() {
                  if (!_favoriteMatches.contains(partida)) {
                    _favoriteMatches.add(partida);
                  }
                });
                Navigator.pop(sheetContext);
                return;
              }

              setModalState(() => selecionadas.removeLast());
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecione até 2 seleções deste grupo.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selecionadas.length} de 2 seleções escolhidas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ...equipes.map(
                      (equipe) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EquipeSelectionTile(
                          equipe: equipe,
                          selecionada: selecionadas.contains(equipe),
                          onTap: () => alternarSelecao(equipe),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmarPartida(
    BuildContext context,
    _FavoriteMatch partida,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: const Text('Acompanhar jogo?'),
              content: Text(
                'Você quer acompanhar o jogo entre '
                '${partida.equipeA.nome} e ${partida.equipeB.nome}?',
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE61E4D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sim'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFD7E3FF)
        : const Color(0xFF0B1F4D);
    final totalFavoritos = _favoriteGroupIds.length + _favoriteMatches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grupos da Copa do Mundo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Seleções organizadas conforme a divisão oficial do projeto.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      const ButtonSegment(
                        value: false,
                        icon: Icon(Icons.grid_view_outlined),
                        label: Text('Todos os Grupos'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.favorite_outline),
                        label: Text('Favoritos ($totalFavoritos)'),
                      ),
                    ],
                    selected: {_somenteFavoritos},
                    onSelectionChanged: (selection) {
                      setState(() => _somenteFavoritos = selection.first);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_somenteFavoritos) _buildFavoritos() else _buildGrupos(),
      ],
    );
  }

  Widget _buildGrupos() {
    final grupos = _grupos;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        return GridView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 270,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grupos.length,
          itemBuilder: (context, index) {
            final entry = grupos.entries.elementAt(index);
            return _GrupoCard(
              grupo: entry.key,
              equipes: entry.value,
              favorito: _favoriteGroupIds.contains(entry.key),
              onFavoritePressed: () => _alternarFavorito(entry.key),
              onTap: () => _abrirGrupo(entry.key, entry.value),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritos() {
    final gruposFavoritos = _favoriteGroupIds.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _FavoritosSection(
          titulo: 'Grupos favoritos',
          vazio: 'Nenhum grupo favorito ainda.',
          children: gruposFavoritos.map((grupo) {
            final equipes = _grupos[grupo] ?? [];
            return _FavoriteGroupTile(
              grupo: grupo,
              equipes: equipes,
              onTap: () => _abrirGrupo(grupo, equipes),
              onRemove: () => _alternarFavorito(grupo),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _FavoritosSection(
          titulo: 'Jogos que quero acompanhar',
          vazio: 'Nenhum jogo escolhido ainda.',
          children: _favoriteMatches
              .map(
                (partida) => _FavoriteMatchTile(
                  partida: partida,
                  onRemove: () {
                    setState(() => _favoriteMatches.remove(partida));
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GrupoCard extends StatelessWidget {
  final String grupo;
  final List<PaisCopa> equipes;
  final bool favorito;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;

  const _GrupoCard({
    required this.grupo,
    required this.equipes,
    required this.favorito,
    required this.onFavoritePressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: isDark ? const Color(0xFF24324A) : const Color(0xFFE5E9F2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      grupo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: favorito
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: onFavoritePressed,
                    icon: Icon(
                      favorito ? Icons.favorite : Icons.favorite_border,
                      color: favorito
                          ? const Color(0xFFE61E4D)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: equipes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final equipe = equipes[index];
                  return SizedBox(
                    height: 30,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CopaFlagImage(pais: equipe, width: 34, height: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            equipe.nome,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipeSelectionTile extends StatelessWidget {
  final PaisCopa equipe;
  final bool selecionada;
  final VoidCallback onTap;

  const _EquipeSelectionTile({
    required this.equipe,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionada
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        leading: CopaFlagImage(pais: equipe, width: 38, height: 26),
        title: Text(
          equipe.nome,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Icon(
          selecionada ? Icons.check_circle : Icons.circle_outlined,
          color: selecionada ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
}

class _FavoritosSection extends StatelessWidget {
  final String titulo;
  final String vazio;
  final List<Widget> children;

  const _FavoritosSection({
    required this.titulo,
    required this.vazio,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Text(vazio, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...children,
      ],
    );
  }
}

class _FavoriteGroupTile extends StatelessWidget {
  final String grupo;
  final List<PaisCopa> equipes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteGroupTile({
    required this.grupo,
    required this.equipes,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.groups_outlined),
        title: Text(grupo, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(equipes.map((equipe) => equipe.nome).join(', ')),
        trailing: IconButton(
          tooltip: 'Remover dos favoritos',
          onPressed: onRemove,
          icon: const Icon(Icons.favorite, color: Color(0xFFE61E4D)),
        ),
      ),
    );
  }
}

class _FavoriteMatchTile extends StatelessWidget {
  final _FavoriteMatch partida;
  final VoidCallback onRemove;

  const _FavoriteMatchTile({required this.partida, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CopaFlagImage(pais: partida.equipeA, width: 34, height: 24),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${partida.equipeA.nome} x ${partida.equipeB.nome}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            CopaFlagImage(pais: partida.equipeB, width: 34, height: 24),
          ],
        ),
        subtitle: Text(partida.grupo),
        trailing: IconButton(
          tooltip: 'Remover jogo',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _FavoriteMatch {
  final String grupo;
  final PaisCopa equipeA;
  final PaisCopa equipeB;

  const _FavoriteMatch({
    required this.grupo,
    required this.equipeA,
    required this.equipeB,
  });

  @override
  bool operator ==(Object other) {
    if (other is! _FavoriteMatch) return false;

    return grupo == other.grupo &&
        ((equipeA.nome == other.equipeA.nome &&
                equipeB.nome == other.equipeB.nome) ||
            (equipeA.nome == other.equipeB.nome &&
                equipeB.nome == other.equipeA.nome));
  }

  @override
  int get hashCode {
    final nomes = [equipeA.nome, equipeB.nome]..sort();
    return Object.hash(grupo, nomes[0], nomes[1]);
  }
}
