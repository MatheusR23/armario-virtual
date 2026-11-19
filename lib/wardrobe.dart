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

class _WardrobePageState extends State<WardrobePage> {
  String _seg = 'roupas';
  String _q = '';
  final Set<String> _status = {'guardado'};
  final Set<String> _tags = {};
  String _sort = 'menos';
  final _search = TextEditingController();

  static const _sortLabels = {'menos': 'Menos usadas', 'mais': 'Mais usadas', 'recentes': 'Usadas recentemente'};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Piece> _filtered() {
    final q = norm(_q);
    final list = store.live.where((p) {
      if (_status.isNotEmpty && !_status.contains(p.status)) return false;
      if (_tags.isNotEmpty && !p.tags.any(_tags.contains)) return false;
      if (q.isEmpty) return true;
      final hay = norm([
        p.name,
        store.typeOf(p).name,
        p.colors.map((c) => c.name).join(' '),
        p.tags.join(' '),
        p.patterned ? 'estampada' : 'lisa',
        statusMeta(p.status).label,
      ].join(' '));
      return hay.contains(q);
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
                    toast(context, 'Escolha as peças e toque em Criar look.');
                  } else {
                    showPieceForm(context);
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(_seg == 'looks' ? 'Montar look' : 'Nova peça'),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _clothes(BuildContext context) {
    final list = _filtered();
    final tags = store.allTags;
    final noItems = store.live.isEmpty;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por nome, tipo, cor ou tag',
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in const [('guardado', 'Guardado'), ('emUso', 'Em uso'), ('cesto', 'No cesto')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pill(
                          label: s.$2,
                          selected: _status.contains(s.$1),
                          onTap: () => setState(() {
                            if (!_status.remove(s.$1)) _status.add(s.$1);
                          }),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.swap_vert_rounded, size: 18, color: C.primaryDark),
                      label: Text(_sortLabels[_sort]!),
                      onPressed: () => setState(() {
                        _sort = {'menos': 'mais', 'mais': 'recentes', 'recentes': 'menos'}[_sort]!;
                      }),
                    ),
                  ],
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text('Tags', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.text2)),
                      ),
                      for (final t in tags)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Pill(
                            label: '#$t',
                            selected: _tags.contains(t),
                            onTap: () => setState(() {
                              if (!_tags.remove(t)) _tags.add(t);
                            }),
                          ),
                        ),
                      if (_tags.isNotEmpty)
                        TextButton(onPressed: () => setState(_tags.clear), child: const Text('Limpar')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      noItems
                          ? 'Nenhuma peça cadastrada'
                          : '${plural(list.length, 'peça', 'peças')} · ${_sortLabels[_sort]!.toLowerCase()} primeiro',
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
            text: noItems
                ? 'Seu armário está pronto para ganhar as primeiras peças.'
                : 'Nenhuma peça encontrada com esses filtros.',
            actionLabel: noItems ? 'Adicionar peça' : 'Limpar filtros',
            onAction: () {
              if (noItems) {
                showPieceForm(context);
              } else {
                setState(() {
                  _q = '';
                  _search.clear();
                  _status.clear();
                  _tags.clear();
                });
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

  List<Widget> _looks(BuildContext context) {
    final looks = store.looks;
    if (looks.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EmptyState(icon: Icons.style_outlined, text: 'Salve combinações para reutilizar seus looks favoritos.'),
        ),
      ];
    }
    return [
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
    final inUse = pieces.where((p) => p.status == 'emUso').length;
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
                    child: GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      children: [
                        for (final p in pieces.take(4))
                          PieceArt(p, radius: 10, padding: 6, opacity: p.status == 'guardado' ? 1 : 0.38),
                      ],
                    ),
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
                      Text('${look.occasion} · ${plural(look.uses, 'uso', 'usos')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: C.text2)),
                      if (inBasket + inUse > 0)
                        Text(
                          inBasket > 0
                              ? plural(inBasket, 'peça no cesto', 'peças no cesto')
                              : plural(inUse, 'peça em uso', 'peças em uso'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8A5A12)),
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
              const SectionLabel('Depois de usar, vai para'),
              SegTabs<String>(
                options: const [('cesto', 'Cesto'), ('guardado', 'Guardado')],
                value: store.ruleOf(p),
                onChanged: (v) => store.setPieceRule(p.id, v),
              ),
              const SizedBox(height: 24),
              const Text('Histórico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Text('Esta peça ainda não foi usada.', style: TextStyle(color: C.text2))
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
            const Text('A peça sai do guarda-roupas e dos looks.'),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)', hintText: 'Ex.: não serve mais, doada'),
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
                            Text(
                              '${look.occasion} · usado ${plural(look.uses, 'vez', 'vezes')} · ${plural(pieces.length, 'peça', 'peças')}',
                              style: const TextStyle(fontSize: 14, color: C.text2),
                            ),
                          ],
                        ),
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
                              inBasket == 1
                                  ? '1 peça está no cesto. Ao usar o look, você escolhe uma substituta no Início antes de confirmar.'
                                  : '$inBasket peças estão no cesto. Ao usar o look, você escolhe substitutas no Início antes de confirmar.',
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
