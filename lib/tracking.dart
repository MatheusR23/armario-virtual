import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'wardrobe.dart';
import 'widgets.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _period = 'mes';
  DateTimeRange? _range;
  String _cat = 'all';
  String _rank = 'mais';
  String _calKind = 'peca';
  String? _calTarget;
  int _calMonth = 0;
  int? _calDay;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final t = todayDay();
    final pieces = {for (final p in store.live) p.id: p};
    bool inCat(Piece p) => _cat == 'all' || store.catOf(p) == _cat;

    // ---- período
    late int from;
    late int to;
    String label;
    String phrase;
    if (_period == 'custom') {
      final r = _range ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 13)), end: DateTime.now());
      from = dayOf(r.start);
      to = dayOf(r.end);
      label = '${fmtDay(from)} a ${fmtDay(to)} · ${plural(to - from + 1, 'dia', 'dias')}';
      phrase = 'entre ${fmtDay(from)} e ${fmtDay(to)}';
    } else {
      const win = {'semana': 7, 'mes': 30, 'tri': 90, 'ano': 365};
      const labels = {'semana': 'Últimos 7 dias', 'mes': 'Últimos 30 dias', 'tri': 'Últimos 3 meses', 'ano': 'Últimos 12 meses'};
      to = t;
      from = t - win[_period]! + 1;
      label = labels[_period]!;
      phrase = label.toLowerCase().replaceFirst('últimos', 'nos últimos');
    }

    final liveLog = store.log.where((l) => pieces.containsKey(l.itemId)).toList();
    final pLog = liveLog.where((l) => l.day >= from && l.day <= to && inCat(pieces[l.itemId]!)).toList();
    final counts = <String, int>{};
    for (final l in pLog) {
      counts[l.itemId] = (counts[l.itemId] ?? 0) + 1;
    }
    final trackItems = store.live.where(inCat).toList();
    final liveW = store.washes.where((w) => pieces.containsKey(w.itemId)).toList();
    final wCat = liveW.where((w) => inCat(pieces[w.itemId]!)).toList();
    double avg(List<Wash> ws) => ws.isEmpty ? 0.0 : ws.fold<int>(0, (a, w) => a + w.uses) / ws.length;
    String nf(double x) => x.toStringAsFixed(1).replaceAll('.', ',');

    if (liveLog.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [
          const Text('Rastreio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          EmptyState(
            icon: Icons.bar_chart_rounded,
            text: 'Registre usos para acompanhar seus padrões.',
            actionLabel: 'Montar roupas de hoje',
            onAction: () => tabIndex.value = 1,
          ),
        ],
      );
    }

    // ---- ranking
    final sorted = trackItems.toList()
      ..sort((a, b) {
        final ca = counts[a.id] ?? 0, cb = counts[b.id] ?? 0;
        if (_rank == 'mais') return cb != ca ? cb.compareTo(ca) : b.total.compareTo(a.total);
        return ca != cb ? ca.compareTo(cb) : (a.lastUse ?? 0).compareTo(b.lastUse ?? 0);
      });
    final maxC = math.max(1, counts.values.fold<int>(0, (a, b) => math.max(a, b)));
    final byCount = trackItems.toList()..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final top = byCount.isNotEmpty && (counts[byCount.first.id] ?? 0) > 0 ? byCount.first : null;
    final stale = trackItems.toList()..sort((a, b) => (a.lastUse ?? -100000).compareTo(b.lastUse ?? -100000));
    final cimaW = liveW.where((w) => store.catOf(pieces[w.itemId]!) == 'cima').toList();
    final topLook = store.looks.isEmpty ? null : (store.looks.toList()..sort((a, b) => b.uses.compareTo(a.uses))).first;

    final insights = <(String, String, VoidCallback)>[
      if (top != null)
        ('Mais usada', '${top.name} é sua peça mais usada $phrase, com ${plural(counts[top.id]!, 'uso', 'usos')}.',
            () => showPieceDetail(context, top.id)),
      if (stale.isNotEmpty)
        (
          'Esquecida',
          stale.first.lastUse == null
              ? '${stale.first.name} ainda não foi usada.'
              : '${stale.first.name} está há ${t - stale.first.lastUse!} dias sem ser usada.',
          () => showPieceDetail(context, stale.first.id)
        ),
      if (cimaW.isNotEmpty)
        ('Antes de lavar', 'Você costuma usar peças de cima ${nf(avg(cimaW))} vezes antes de lavá-las.',
            () => setState(() => _cat = 'cima')),
      if (topLook != null && topLook.uses > 0)
        ('Look favorito', 'O look ${topLook.name} foi usado ${plural(topLook.uses, 'vez', 'vezes')} até agora.',
            () => showLookDialog(context, topLook.id)),
    ];

    // ---- por parte
    final cats = ['cima', 'baixo', 'unica', 'calcado', 'acessorio'];
    final byCat = {
      for (final c in cats)
        c: liveLog.where((l) => l.day >= from && l.day <= to && store.catOf(pieces[l.itemId]!) == c).length
    };
    final maxCat = math.max(1, byCat.values.fold<int>(0, (a, b) => math.max(a, b)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        const Text('Rastreio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 14, color: C.text2)),
        const SizedBox(height: 16),
        SegTabs<String>(
          fontSize: 13,
          options: const [('semana', 'Semana'), ('mes', 'Mês'), ('tri', '3 meses'), ('ano', 'Ano'), ('custom', 'Período')],
          value: _period,
          onChanged: (v) async {
            if (v == 'custom') {
              await _pickRange();
            } else {
              setState(() => _period = v);
            }
          },
        ),
        if (_period == 'custom') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text('${fmtDay(from)} a ${fmtDay(to)}'),
          ),
        ],
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in [('all', 'Todas'), ('cima', 'Parte de cima'), ('baixo', 'Parte de baixo'), ('unica', 'Peças únicas'), ('calcado', 'Calçados'), ('acessorio', 'Acessórios')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pill(
                    label: c.$2,
                    selected: _cat == c.$1,
                    onTap: () => setState(() {
                      _cat = c.$1;
                      _calDay = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statTile('${pLog.length}', 'usos no período'),
            const SizedBox(width: 8),
            _statTile('${counts.length}', 'peças diferentes'),
            const SizedBox(width: 8),
            _statTile(wCat.isEmpty ? '–' : nf(avg(wCat)), 'usos até lavar'),
          ],
        ),
        const SizedBox(height: 24),
        if (insights.isNotEmpty) ...[
          const Text('Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final ins = insights[i];
                return SizedBox(
                  width: 240,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: ins.$3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: C.primaryDark),
                              const SizedBox(width: 6),
                              Text(ins.$1.toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.primaryDark)),
                            ]),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(ins.$2,
                                  overflow: TextOverflow.fade, style: const TextStyle(fontSize: 15, height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ---- ranking
        Card2(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Ranking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  SizedBox(
                    width: 180,
                    child: SegTabs<String>(
                      options: const [('mais', 'Mais'), ('menos', 'Menos')],
                      value: _rank,
                      onChanged: (v) => setState(() => _rank = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < math.min(5, sorted.length); i++) _rankRow(context, i, sorted[i], counts[sorted[i].id] ?? 0, maxC),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- calendário
        _calendarCard(context, t, liveLog, inCat),
        const SizedBox(height: 16),

        // ---- por parte
        Card2(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Uso por parte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final c in cats) ...[
                Row(children: [
                  Expanded(child: Text(kCats[c]!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  Text(plural(byCat[c]!, 'uso', 'usos'), style: const TextStyle(fontSize: 14, color: C.text2)),
                ]),
                const SizedBox(height: 4),
                _bar(byCat[c]! / maxCat, const Color(0xFF8BA5B3)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- sem uso
        Card2(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sem uso há mais tempo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final p in stale.take(3))
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showPieceDetail(context, p.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 48, height: 48, child: PieceArt(p, radius: 12, padding: 6)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text(p.lastUse == null ? 'Nunca usada' : 'Sem uso há ${t - p.lastUse!} dias',
                                  style: const TextStyle(fontSize: 12, color: C.text2)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: C.text2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 13)), end: now),
      helpText: 'Escolha o período',
      saveText: 'Aplicar',
    );
    if (!mounted) return;
    if (r != null) {
      setState(() {
        _range = r;
        _period = 'custom';
      });
    }
  }

  Widget _statTile(String value, String label) => Expanded(
        child: Card2(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(fontSize: 12, color: C.text2)),
            ],
          ),
        ),
      );

  Widget _bar(double frac, Color color) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 10,
          color: const Color(0xFFEEF2F4),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: frac <= 0 ? 0 : math.max(0.03, math.min(1.0, frac)),
            child: Container(color: color),
          ),
        ),
      );

  Widget _rankRow(BuildContext context, int i, Piece p, int c, int maxC) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showPieceDetail(context, p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 20, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.text2))),
            SizedBox(width: 40, height: 40, child: PieceArt(p, radius: 10, padding: 5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    Text(plural(c, 'uso', 'usos'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  _bar(c / maxC, C.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarCard(BuildContext context, int t, List<UseLog> liveLog, bool Function(Piece) inCat) {
    final now = dateOf(t);
    final base = DateTime.utc(now.year, now.month + _calMonth, 1);
    final dim = DateTime.utc(base.year, base.month + 1, 0).day;
    final m0 = dayOf(base);
    final wd0 = base.weekday % 7;

    final pieceTargets = store.live.where(inCat).toList()..sort((a, b) => b.total.compareTo(a.total));
    final lookTargets = store.looks.toList()..sort((a, b) => b.uses.compareTo(a.uses));
    final used = <int>{};
    String? tName;
    if (_calKind == 'peca') {
      Piece? tp;
      for (final p in pieceTargets) {
        if (p.id == _calTarget) tp = p;
      }
      tp ??= pieceTargets.isEmpty ? null : pieceTargets.first;
      if (tp != null) {
        tName = tp.name;
        final id = tp.id;
        used.addAll(liveLog.where((l) => l.itemId == id).map((l) => l.day));
      }
    } else {
      Look? tl;
      for (final l in lookTargets) {
        if (l.id == _calTarget) tl = l;
      }
      tl ??= lookTargets.isEmpty ? null : lookTargets.first;
      if (tl != null) {
        tName = tl.name;
        final id = tl.id;
        used.addAll(store.lookLog.where((x) => x.lookId == id).map((x) => x.day));
      }
    }
    var monthUses = 0;
    for (var d = 0; d < dim; d++) {
      if (used.contains(m0 + d)) monthUses++;
    }

    // peças do dia escolhido
    List<Piece> dayPieces = [];
    String dayTitle = '';
    final cd = _calDay;
    if (cd != null) {
      final has = used.contains(cd);
      if (!has) {
        dayTitle = '${weekdayShort(cd)}, ${fmtDay(cd)} · sem uso';
      } else if (_calKind == 'peca') {
        final tid = pieceTargets.isEmpty ? null : (pieceTargets.any((p) => p.id == _calTarget) ? _calTarget : pieceTargets.first.id);
        dayPieces = liveLog.where((l) => l.day == cd && l.itemId != tid).map((l) => store.byId(l.itemId)).whereType<Piece>().toList();
        dayTitle = '${weekdayShort(cd)}, ${fmtDay(cd)} · ${dayPieces.isEmpty ? 'usada sozinha' : 'usada com:'}';
      } else {
        final lk = store.lookById(lookTargets.any((l) => l.id == _calTarget) ? _calTarget : (lookTargets.isEmpty ? null : lookTargets.first.id));
        dayPieces = (lk?.pieceIds() ?? []).map(store.byId).whereType<Piece>().toList();
        dayTitle = '${weekdayShort(cd)}, ${fmtDay(cd)} · peças do look:';
      }
    }

    final cells = <Widget>[
      for (final w in const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'])
        Center(child: Text(w, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text2))),
      for (var i = 0; i < wd0; i++) const SizedBox.shrink(),
      for (var d = 1; d <= dim; d++) _dayCell(m0 + d - 1, d, t, used),
    ];

    return Card2(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Calendário de usos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SegTabs<String>(
            options: const [('peca', 'Peças e acessórios'), ('look', 'Looks')],
            value: _calKind,
            onChanged: (v) => setState(() {
              _calKind = v;
              _calTarget = null;
              _calDay = null;
            }),
          ),
          const SizedBox(height: 12),
          if (tName == null)
            Text(_calKind == 'peca' ? 'Nenhuma peça nesta parte.' : 'Nenhum look salvo ainda.',
                style: const TextStyle(color: C.text2))
          else ...[
            Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  onPressed: () => setState(() {
                    _calMonth--;
                    _calDay = null;
                  }),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${kMesF[base.month - 1][0].toUpperCase()}${kMesF[base.month - 1].substring(1)} de ${base.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: () => _openTargetPicker(context, pieceTargets, lookTargets),
                        icon: const Icon(Icons.grid_view_rounded, size: 16),
                        label: Text('$tName · ${plural(monthUses, 'uso', 'usos')} no mês',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: TextButton.styleFrom(foregroundColor: C.text2),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  onPressed: _calMonth >= 0
                      ? null
                      : () => setState(() {
                            _calMonth++;
                            _calDay = null;
                          }),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: cells,
            ),
            const SizedBox(height: 8),
            Row(children: [
              _legend(C.primary, 'Usado'),
              const SizedBox(width: 16),
              _legend(const Color(0xFFEEF2F4), 'Sem uso'),
            ]),
            if (cd != null) ...[
              const Divider(height: 24),
              Text(dayTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in dayPieces)
                    ActionChip(
                      avatar: CircleAvatar(backgroundColor: Color(p.colors.isEmpty ? 0xFFC9D4DA : p.colors.first.hex)),
                      label: Text(p.name),
                      onPressed: () => showPieceDetail(context, p.id),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _dayCell(int dn, int d, int t, Set<int> used) {
    final future = dn > t;
    final isUsed = used.contains(dn);
    final sel = _calDay == dn;
    return Semantics(
      button: !future,
      label: '$d: ${future ? 'dia futuro' : (isUsed ? 'usado' : 'sem uso')}',
      child: GestureDetector(
        onTap: future ? null : () => setState(() => _calDay = sel ? null : dn),
        child: Container(
          decoration: BoxDecoration(
            color: future ? Colors.transparent : (isUsed ? C.primary : const Color(0xFFEEF2F4)),
            borderRadius: BorderRadius.circular(10),
            border: sel ? Border.all(color: C.text, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$d',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: future ? const Color(0xFF9AA5AB) : (isUsed ? Colors.white : C.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color c, String text) => Row(children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: C.text2)),
      ]);

  void _openTargetPicker(BuildContext context, List<Piece> pieces, List<Look> looks) {
    showAppSheet(context, (ctx) {
      if (_calKind == 'peca') {
        return SheetFrame(
          title: 'Peças e acessórios',
          subtitle: 'Escolha o que mostrar no calendário.',
          child: GalleryGrid(
            pieces: pieces,
            selectedIds: [if (_calTarget != null) _calTarget!],
            onTap: (p) {
              setState(() {
                _calTarget = p.id;
                _calDay = null;
              });
              Navigator.pop(ctx);
            },
          ),
        );
      }
      return SheetFrame(
        title: 'Looks',
        subtitle: 'Escolha o que mostrar no calendário.',
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
          children: [
            for (final l in looks)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calTarget = l.id;
                    _calDay = null;
                  });
                  Navigator.pop(ctx);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: C.tile,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _calTarget == l.id ? C.primaryDark : Colors.transparent, width: 3),
                        ),
                        child: GridView.count(
                          crossAxisCount: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          children: [
                            for (final p in l.pieceIds().map(store.byId).whereType<Piece>().take(4))
                              PieceArt(p, radius: 8, padding: 4, background: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(plural(l.uses, 'uso', 'usos'), style: const TextStyle(fontSize: 12, color: C.text2)),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
