import 'dart:io';

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'piece_form.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});
  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

/// Cor disponível como filtro: nome, tom de exemplo e quantos itens têm a cor.
class _ColorOption {
  final ColorTag color;
  int count;
  _ColorOption(this.color, this.count);
}

List<_ColorOption> _colorOptions(Iterable<List<ColorTag>> lists) {
  final out = <String, _ColorOption>{};
  for (final l in lists) {
    for (final c in {for (final c in l) c.name: c}.values) {
      out.putIfAbsent(c.name, () => _ColorOption(c, 0)).count++;
    }
  }
  final list = out.values.toList()..sort((a, b) => b.count.compareTo(a.count));
  return list;
}

class _WardrobePageState extends State<WardrobePage> {
  String _seg = 'roupas';

  // ---- filtros de roupas
  String _q = '';
  final Set<String> _status = {'guardado'};
  final Set<String> _colors = {};
  final Set<String> _types = {};
  final Set<String> _tags = {};
  final Set<String> _pattern = {}; // vazio, {lisa} ou {estampada}
  String _sort = 'menos';
  final _search = TextEditingController();

  // ---- filtros de looks
  String _lq = '';
  final Set<String> _lColors = {};
  final Set<String> _lOcc = {};
  bool _lFav = false;
  final _lSearch = TextEditingController();

  static const _sortLabels = {'menos': 'Menos usadas', 'mais': 'Mais usadas', 'recentes': 'Recentes'};
  static const _statusLabels = {'guardado': 'Guardado', 'emUso': 'Em uso', 'cesto': 'No cesto'};

  @override
  void dispose() {
    _search.dispose();
    _lSearch.dispose();
    super.dispose();
  }

  bool get _clothesFiltered =>
      _q.isNotEmpty || _status.isNotEmpty || _colors.isNotEmpty || _types.isNotEmpty || _tags.isNotEmpty || _pattern.isNotEmpty;

  bool get _looksFiltered => _lq.isNotEmpty || _lColors.isNotEmpty || _lOcc.isNotEmpty || _lFav;

  void _clearClothes() => setState(() {
        _q = '';
        _search.clear();
        _status.clear();
        _colors.clear();
        _types.clear();
        _tags.clear();
        _pattern.clear();
      });

  void _clearLooks() => setState(() {
        _lq = '';
        _lSearch.clear();
        _lColors.clear();
        _lOcc.clear();
        _lFav = false;
      });

  List<Piece> _filtered() {
    final q = norm(_q);
    final list = store.live.where((p) {
      if (_status.isNotEmpty && !_status.contains(p.status)) return false;
      if (_colors.isNotEmpty && !p.colors.any((c) => _colors.contains(c.name))) return false;
      if (_types.isNotEmpty && !_types.contains(p.typeId)) return false;
      if (_tags.isNotEmpty && !p.tags.any(_tags.contains)) return false;
      if (_pattern.contains('lisa') && p.patterned) return false;
      if (_pattern.contains('estampada') && !p.patterned) return false;
      if (q.isEmpty) return true;
      final hay = norm([
        p.name,
        store.typeOf(p).name,
        p.colors.map((c) => c.name).join(' '),
        p.tags.join(' '),
        p.patterned ? 'estampada' : 'lisa',
        statusMeta(p.status).label,
      ].join(' '));
      return q.split(' ').where((w) => w.isNotEmpty).every(hay.contains);
    }).toList();
    switch (_sort) {
      case 'mais':
        list.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'recentes':
        list.sort((a, b) => (b.lastUse ?? -1).compareTo(a.lastUse ?? -1));
        break;
      default:
        list.sort((a, b) => a.total.compareTo(b.total));
    }
    return list;
  }

  List<Look> _filteredLooks() {
    final q = norm(_lq);
    final list = store.looks.where((l) {
      if (_lFav && !l.fav) return false;
      if (_lOcc.isNotEmpty && !_lOcc.contains(l.occasion)) return false;
      final colors = store.lookColors(l);
      if (_lColors.isNotEmpty && !colors.any((c) => _lColors.contains(c.name))) return false;
      if (q.isEmpty) return true;
      final hay = norm([
        l.name,
        l.occasion,
        colors.map((c) => c.name).join(' '),
        l.pieceIds().map(store.byId).whereType<Piece>().map((p) => p.name).join(' '),
      ].join(' '));
      return q.split(' ').where((w) => w.isNotEmpty).every(hay.contains);
    }).toList();
    list.sort((a, b) {
      if (a.fav != b.fav) return a.fav ? -1 : 1;
      return b.uses.compareTo(a.uses);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Guarda-Roupas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        SegTabs<String>(
                          options: const [('roupas', 'Roupas'), ('looks', 'Looks')],
                          value: _seg,
                          onChanged: (v) => setState(() => _seg = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_seg == 'roupas') ..._clothes(context) else ..._looks(context),
                const SliverToBoxAdapter(child: SizedBox(height: 104)),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: 'fab-guarda',
                backgroundColor: C.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  if (_seg == 'looks') {
                    tabIndex.value = 1;
                    toast(context, 'Escolha as peças no Início.');
                  } else {
                    showPieceForm(context);
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(_seg == 'looks' ? 'Novo look' : 'Nova peça'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================ filtros
  Widget _searchField(TextEditingController c, String hint, ValueChanged<String> onChanged) {
    return TextField(
      controller: c,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: hint,
        suffixIcon: c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  c.clear();
                  onChanged('');
                },
              ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _filterRow(List<Widget> chips, {required bool filtered, required VoidCallback onClear}) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (filtered)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterButton(
                label: 'Limpar',
                active: false,
                dropdown: false,
                leading: const Icon(Icons.close_rounded, size: 18, color: C.primaryDark),
                onTap: onClear,
              ),
            ),
          for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  /// Rótulo de um filtro: nome do filtro, a opção escolhida ou "Nome · 2".
  String _label(String base, Set<String> sel, String Function(String) name) {
    if (sel.isEmpty) return base;
    if (sel.length == 1) return name(sel.first);
    return '$base · ${sel.length}';
  }

  Widget? _dotFor(Set<String> sel, List<_ColorOption> options) {
    if (sel.isEmpty) return null;
    final colors = [
      for (final o in options)
        if (sel.contains(o.color.name)) o.color,
    ];
    return ColorDots(colors, size: 16, max: 3);
  }

  void _toggle(Set<String> s, String v) {
    if (!s.remove(v)) s.add(v);
  }

  /// Folha com a grade de cores (como o filtro de cor da busca de imagens).
  void _openColors(List<_ColorOption> options, Set<String> sel) {
    showAppSheet(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        void tap(String name) {
          setState(() => _toggle(sel, name));
          setSheet(() {});
        }

        return SheetFrame(
          title: 'Cor',
          footer: Row(
            children: [
              TextButton(
                onPressed: sel.isEmpty
                    ? null
                    : () {
                        setState(sel.clear);
                        setSheet(() {});
                      },
                child: const Text('Limpar'),
              ),
              const Spacer(),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ver resultados')),
            ],
          ),
          child: options.isEmpty
              ? const EmptyState(icon: Icons.palette_outlined, text: 'Nenhuma cor.')
              : GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: [
                    for (final o in options)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => tap(o.color.name),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorSwatchButton(
                              color: o.color,
                              size: 48,
                              selected: sel.contains(o.color.name),
                              onTap: () => tap(o.color.name),
                            ),
                            const SizedBox(height: 4),
                            Text(o.color.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('${o.count}', style: const TextStyle(fontSize: 12, color: C.text2)),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      });
    });
  }

  /// Folha com opções em lista (tipo, tag, status, ocasião…).
  void _openOptions(String title, List<(String, String)> options, Set<String> sel, {bool single = false}) {
    showAppSheet(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        return SheetFrame(
          title: title,
          footer: Row(
            children: [
              TextButton(
                onPressed: sel.isEmpty
                    ? null
                    : () {
                        setState(sel.clear);
                        setSheet(() {});
                      },
                child: const Text('Limpar'),
              ),
              const Spacer(),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ver resultados')),
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                Pill(
                  label: o.$2,
                  selected: sel.contains(o.$1),
                  onTap: () {
                    setState(() {
                      if (single) {
                        final had = sel.contains(o.$1);
                        sel.clear();
                        if (!had) sel.add(o.$1);
                      } else {
                        _toggle(sel, o.$1);
                      }
                    });
                    setSheet(() {});
                  },
                ),
            ],
          ),
        );
      });
    });
  }

  void _openSort() {
    showAppSheet(context, (ctx) {
      return SheetFrame(
        title: 'Ordenar',
        child: Column(
          children: [
            for (final e in _sortLabels.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                trailing: _sort == e.key ? const Icon(Icons.check_rounded, color: C.primaryDark) : null,
                onTap: () {
                  setState(() => _sort = e.key);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      );
    });
  }

  // ============================================================ roupas
  List<Widget> _clothes(BuildContext context) {
    final list = _filtered();
    final noItems = store.live.isEmpty;
    final colorOpts = _colorOptions(store.live.map((p) => p.colors));
    final usedTypes = {for (final p in store.live) p.typeId};
    final typeOpts = [
      for (final t in store.allTypes)
        if (usedTypes.contains(t.id)) (t.id, t.name),
    ];
    final tagOpts = [for (final t in store.allTags) (t, '#$t')];

    final chips = <Widget>[
      FilterButton(
        label: _label('Cor', _colors, (v) => v),
        active: _colors.isNotEmpty,
        leading: _dotFor(_colors, colorOpts),
        onTap: () => _openColors(colorOpts, _colors),
      ),
      FilterButton(
        label: _label('Tipo', _types, (v) => store.typeById(v).name),
        active: _types.isNotEmpty,
        onTap: () => _openOptions('Tipo', typeOpts, _types),
      ),
      if (tagOpts.isNotEmpty)
        FilterButton(
          label: _label('Tag', _tags, (v) => '#$v'),
          active: _tags.isNotEmpty,
          onTap: () => _openOptions('Tag', tagOpts, _tags),
        ),
      FilterButton(
        label: _label('Status', _status, (v) => _statusLabels[v]!),
        active: _status.isNotEmpty,
        onTap: () => _openOptions('Status', _statusLabels.entries.map((e) => (e.key, e.value)).toList(), _status),
      ),
      FilterButton(
        label: _pattern.isEmpty ? 'Estampa' : (_pattern.contains('lisa') ? 'Lisa' : 'Estampada'),
        active: _pattern.isNotEmpty,
        onTap: () => _openOptions('Estampa', const [('lisa', 'Lisa'), ('estampada', 'Estampada')], _pattern, single: true),
      ),
      FilterButton(
        label: _sortLabels[_sort]!,
        active: false,
        leading: const Icon(Icons.swap_vert_rounded, size: 18, color: C.primaryDark),
        onTap: _openSort,
      ),
    ];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(_search, 'Buscar peças', (v) => setState(() => _q = v)),
              const SizedBox(height: 12),
              _filterRow(chips, filtered: _clothesFiltered, onClear: _clearClothes),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      noItems ? '' : plural(list.length, 'peça', 'peças'),
                      style: const TextStyle(fontSize: 14, color: C.text2),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: C.seg, borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        _colBtn(2, Icons.view_column_outlined, '2 colunas'),
                        _colBtn(3, Icons.view_week_outlined, '3 colunas'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.checkroom_outlined,
            text: noItems ? 'Nenhuma peça ainda.' : 'Nada encontrado.',
            actionLabel: noItems ? 'Adicionar peça' : 'Limpar filtros',
            onAction: () {
              if (noItems) {
                showPieceForm(context);
              } else {
                _clearClothes();
              }
            },
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: store.cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: store.cols == 2 ? 0.74 : 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PieceCard(piece: list[i]),
              childCount: list.length,
            ),
          ),
        ),
    ];
  }

  Widget _colBtn(int n, IconData icon, String label) {
    final on = store.cols == n;
    return Semantics(
      selected: on,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => store.setCols(n),
        child: Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: on ? C.text : C.text2),
        ),
      ),
    );
  }

  // ============================================================ looks
  List<Widget> _looks(BuildContext context) {
    if (store.looks.isEmpty) {
      return const [
        SliverToBoxAdapter(child: EmptyState(icon: Icons.style_outlined, text: 'Nenhum look salvo.')),
      ];
    }
    final looks = _filteredLooks();
    final colorOpts = _colorOptions(store.looks.map(store.lookColors));
    final occOpts = [
      for (final o in {for (final l in store.looks) l.occasion}.where((o) => o.isNotEmpty)) (o, o),
    ];
    final chips = <Widget>[
      FilterButton(
        label: _label('Cor', _lColors, (v) => v),
        active: _lColors.isNotEmpty,
        leading: _dotFor(_lColors, colorOpts),
        onTap: () => _openColors(colorOpts, _lColors),
      ),
      if (occOpts.isNotEmpty)
        FilterButton(
          label: _label('Ocasião', _lOcc, (v) => v),
          active: _lOcc.isNotEmpty,
          onTap: () => _openOptions('Ocasião', occOpts, _lOcc),
        ),
      FilterButton(
        label: 'Favoritos',
        active: _lFav,
        dropdown: false,
        leading: Icon(_lFav ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18, color: _lFav ? Colors.white : C.primaryDark),
        onTap: () => setState(() => _lFav = !_lFav),
      ),
    ];
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(_lSearch, 'Buscar looks', (v) => setState(() => _lq = v)),
              const SizedBox(height: 12),
              _filterRow(chips, filtered: _looksFiltered, onClear: _clearLooks),
              const SizedBox(height: 8),
              Text(plural(looks.length, 'look', 'looks'), style: const TextStyle(fontSize: 14, color: C.text2)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      if (looks.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.style_outlined,
            text: 'Nada encontrado.',
            actionLabel: 'Limpar filtros',
            onAction: _clearLooks,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _LookCard(look: looks[i]),
              childCount: looks.length,
            ),
          ),
        ),
    ];
  }
}

class _PieceCard extends StatelessWidget {
  final Piece piece;
  const _PieceCard({required this.piece});

  @override
  Widget build(BuildContext context) {
    final p = piece;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: const Color(0x331D2930),
      child: InkWell(
        onTap: () => showPieceDetail(context, p.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: PieceArt(p, radius: 0, padding: 16)),
                  if (p.status != 'guardado') Positioned(top: 8, left: 8, child: StatusBadge(p.status)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${store.typeOf(p).name} · ${plural(p.total, 'uso', 'usos')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: C.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  final Look look;
  const _LookCard({required this.look});

  @override
  Widget build(BuildContext context) {
    final pieces = look.pieceIds().map(store.byId).whereType<Piece>().where((p) => !p.deleted).toList();
    final inBasket = pieces.where((p) => p.status == 'cesto').length;
    final colors = store.lookColors(look);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: const Color(0x331D2930),
      child: InkWell(
        onTap: () => showLookDialog(context, look.id),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: LookArt(look, radius: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(look.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (colors.isNotEmpty) ...[ColorDots(colors, size: 12), const SizedBox(width: 6)],
                          Expanded(
                            child: Text(
                              inBasket > 0 ? '$inBasket no cesto' : look.occasion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: inBasket > 0 ? const Color(0xFF8A5A12) : C.text2,
                                fontWeight: inBasket > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: look.fav ? 'Remover dos favoritos' : 'Favoritar',
                onPressed: () => store.toggleFav(look.id),
                icon: Icon(
                  look.fav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: look.fav ? const Color(0xFFB07A1E) : C.text2,
                ),
                style: IconButton.styleFrom(backgroundColor: const Color(0xF0FFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================== Detalhe da peça
Future<void> showPieceDetail(BuildContext context, String id) =>
    showAppSheet(context, (_) => PieceDetailSheet(id: id, host: context));

class PieceDetailSheet extends StatelessWidget {
  final String id;
  final BuildContext host;
  const PieceDetailSheet({super.key, required this.id, required this.host});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.byId(id);
        if (p == null || p.deleted) return const SizedBox(height: 120);
        final type = store.typeOf(p);
        final events = <(int, String, Color)>[
          for (final l in store.log.where((l) => l.itemId == p.id)) (l.day, 'Usada', C.primary),
          for (final w in store.washes.where((w) => w.itemId == p.id))
            (w.day, 'Lavada após ${plural(w.uses, 'uso', 'usos')}', C.success),
        ];
        events.sort((a, b) => b.$1.compareTo(a.$1));
        return SheetFrame(
          title: p.name,
          subtitle: '${type.name} · ${statusMeta(p.status).label}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 220, child: PieceArt(p, radius: 20, padding: 36)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(Text(type.name)),
                  for (final c in p.colors)
                    _chip(Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(c.hex),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x331D2930)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(c.name),
                    ])),
                  _chip(Text(p.patterned ? 'Estampada' : 'Lisa')),
                  for (final t in p.tags) _chip(Text('#$t')),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Status'),
              SegTabs<String>(
                options: const [('guardado', 'Guardado'), ('emUso', 'Em uso'), ('cesto', 'Cesto')],
                value: p.status,
                onChanged: (v) => store.setStatus(p.id, v),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.3,
                children: [
                  _stat('Total de usos', '${p.total}'),
                  _stat('Desde a lavagem', '${p.since}'),
                  _stat('Último uso', relDay(p.lastUse)),
                  _stat('Última lavagem', relDay(p.lastWash)),
                ],
              ),
              const SizedBox(height: 16),
              const SectionLabel('Após o uso'),
              SegTabs<String>(
                options: const [('cesto', 'Cesto'), ('guardado', 'Guardado')],
                value: store.ruleOf(p),
                onChanged: (v) => store.setPieceRule(p.id, v),
              ),
              const SizedBox(height: 24),
              const Text('Histórico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Text('Nenhum uso ainda.', style: TextStyle(color: C.text2))
              else
                for (final e in events.take(6))
                  Container(
                    height: 40,
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF2F4)))),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.$2, style: const TextStyle(fontSize: 14))),
                        Text(relDay(e.$1), style: const TextStyle(fontSize: 14, color: C.text2)),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showPieceForm(host, editId: p.id);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFA23E3C)),
                    onPressed: () => _askDelete(context, p),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF1F4F6), borderRadius: BorderRadius.circular(999)),
        child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), child: child),
      );

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF3F6F8), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: C.text2)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Future<void> _askDelete(BuildContext context, Piece p) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir ${p.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 80, width: 80, child: PieceArt(p, radius: 16, padding: 8)),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir peça'),
          ),
        ],
      ),
    );
    if (ok == true) {
      store.deletePiece(p.id, reason.text.trim());
      if (context.mounted) Navigator.pop(context);
    }
    reason.dispose();
  }
}

// ============================================================== Look (pop-up)
Future<void> showLookDialog(BuildContext context, String id) => showDialog<void>(
      context: context,
      builder: (_) => LookDialog(id: id, host: context),
    );

class LookDialog extends StatelessWidget {
  final String id;
  final BuildContext host;
  const LookDialog({super.key, required this.id, required this.host});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final look = store.lookById(id);
        if (look == null) return const SizedBox.shrink();
        final pieces = look.pieceIds().map(store.byId).whereType<Piece>().where((p) => !p.deleted).toList();
        final inBasket = pieces.where((p) => p.status == 'cesto').length;
        final colors = store.lookColors(look);
        final photo = look.photoPath;
        final hasPhoto = photo != null && File(photo).existsSync();
        String sectionOf(Piece p) {
          final cat = store.catOf(p);
          if (cat == 'unica') return 'Peça única';
          if (look.cima.contains(p.id)) return 'Cima';
          if (look.baixo.contains(p.id)) return 'Baixo';
          if (look.calcado == p.id) return 'Calçado';
          return 'Acessório';
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(look.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            Row(
                              children: [
                                if (colors.isNotEmpty) ...[ColorDots(colors, size: 14, max: 5), const SizedBox(width: 8)],
                                Flexible(
                                  child: Text(
                                    '${look.occasion} · ${plural(look.uses, 'uso', 'usos')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: C.text2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar look',
                        onPressed: () {
                          Navigator.pop(context);
                          showEditLook(host, look.id);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: look.fav ? 'Remover dos favoritos' : 'Favoritar',
                        onPressed: () => store.toggleFav(look.id),
                        icon: Icon(look.fav ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: look.fav ? const Color(0xFFB07A1E) : C.text2),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasPhoto) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(photo!), height: 240, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                        ],
                        GalleryGrid(
                          pieces: pieces,
                          selectedIds: const [],
                          subtitle: (p) => p.status == 'guardado' ? sectionOf(p) : '${sectionOf(p)} · ${statusMeta(p.status).label}',
                          onTap: (p) {
                            Navigator.pop(context);
                            showPieceDetail(host, p.id);
                          },
                        ),
                        if (inBasket > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: C.warningBg, borderRadius: BorderRadius.circular(14)),
                            child: Text(
                              '${plural(inBasket, 'peça', 'peças')} no cesto',
                              style: const TextStyle(color: C.warningFg, fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEF2F4)))),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Excluir look',
                        color: const Color(0xFFA23E3C),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'Excluir o look ${look.name}?',
                            text: 'As peças continuam no guarda-roupas.',
                            confirmLabel: 'Excluir look',
                            danger: true,
                          );
                          if (ok) {
                            store.deleteLook(look.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                      IconButton(
                        tooltip: 'Duplicar look',
                        onPressed: () {
                          store.duplicateLook(look.id);
                          Navigator.pop(context);
                          toast(host, 'Look duplicado.');
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            store.useLook(look.id);
                          },
                          child: const Text('Usar look'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
