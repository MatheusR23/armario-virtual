import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

/// Histórico de usos: cada linha é um uso (look ou peças avulsas) com a data.
class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final list = store.history;
    final rows = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(plural(list.length, 'uso', 'usos'), style: const TextStyle(fontSize: 14, color: C.text2)),
          ),
          FilledButton.tonalIcon(
            onPressed: () => showWearEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar'),
          ),
        ],
      ),
    ];
    if (list.isEmpty) {
      rows.add(const EmptyState(icon: Icons.history_rounded, text: 'Nenhum uso registrado.'));
    }
    String? month;
    for (final w in list) {
      final d = dateOf(w.day);
      final m = '${kMesF[d.month - 1]} de ${d.year}';
      if (m != month) {
        month = m;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(m[0].toUpperCase() + m.substring(1),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text2)),
        ));
      }
      rows.add(_WearRow(wear: w));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

String wearTitle(Wear w) {
  final lk = store.lookById(w.lookId);
  if (lk != null) return lk.name;
  final names = w.items.map(store.byId).whereType<Piece>().map((p) => p.name).toList();
  return names.isEmpty ? 'Uso' : names.join(', ');
}

class _WearRow extends StatelessWidget {
  final Wear wear;
  const _WearRow({required this.wear});

  @override
  Widget build(BuildContext context) {
    final lk = store.lookById(wear.lookId);
    final pieces = wear.items.map(store.byId).whereType<Piece>().toList();
    final rel = relDay(wear.day);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showWearEditor(context, id: wear.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: lk != null
                  ? LookArt(lk, radius: 10)
                  : pieces.isNotEmpty
                      ? PieceArt(pieces.first, radius: 10, padding: 6)
                      : const SizedBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wearTitle(wear),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    lk != null ? pieces.map((p) => p.name).join(', ') : plural(pieces.length, 'peça', 'peças'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: C.text2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rel == fmtDay(wear.day) ? fmtDay(wear.day) : rel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(rel == fmtDay(wear.day) ? weekdayShort(wear.day) : fmtDay(wear.day),
                    style: const TextStyle(fontSize: 12, color: C.text2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================== Editar uso
Future<void> showWearEditor(BuildContext context, {String? id}) {
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet(context, (_) => WearEditSheet(messenger: messenger, wearId: id));
}

class WearEditSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  final String? wearId;
  const WearEditSheet({super.key, required this.messenger, this.wearId});
  @override
  State<WearEditSheet> createState() => _WearEditSheetState();
}

class _WearEditSheetState extends State<WearEditSheet> {
  late int _day;
  String? _lookId;
  final List<String> _items = [];
  String? _error;

  bool get _editing => store.wearById(widget.wearId) != null;

  @override
  void initState() {
    super.initState();
    final w = store.wearById(widget.wearId);
    _day = w?.day ?? todayDay();
    _lookId = store.lookById(w?.lookId)?.id;
    if (w != null) _items.addAll(w.items.where((x) => store.byId(x) != null));
  }

  void _save() {
    final err = store.saveWear(id: widget.wearId, day: _day, lookId: _lookId, items: _items);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context);
    widget.messenger.hideCurrentSnackBar();
    widget.messenger.showSnackBar(SnackBar(content: Text(_editing ? 'Uso atualizado.' : 'Uso registrado.')));
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Apagar uso?',
      text: 'O uso de ${fmtDay(_day)} sai do histórico e da contagem das peças.',
      confirmLabel: 'Apagar',
      danger: true,
    );
    if (!ok || !mounted) return;
    store.deleteWear(widget.wearId!);
    Navigator.pop(context);
    widget.messenger.hideCurrentSnackBar();
    widget.messenger.showSnackBar(const SnackBar(content: Text('Uso apagado.')));
  }

  void _chooseLook(String? id) {
    setState(() {
      _lookId = id;
      _error = null;
      final lk = store.lookById(id);
      if (lk != null && _items.isEmpty) {
        _items.addAll(lk.pieceIds().where((x) => store.byId(x)?.deleted == false));
      }
    });
  }

  Future<void> _addPieces() async {
    final pieces = store.live;
    await showAppSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SheetFrame(
          title: 'Peças',
          footer: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Pronto')),
          child: pieces.isEmpty
              ? const EmptyState(icon: Icons.checkroom_outlined, text: 'Nenhuma peça.')
              : GalleryGrid(
                  pieces: pieces,
                  selectedIds: _items,
                  onTap: (p) => setSheet(() {
                    if (!_items.remove(p.id)) _items.add(p.id);
                  }),
                ),
        ),
      ),
    );
    if (mounted) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final pieces = _items.map(store.byId).whereType<Piece>().toList();
    return SheetFrame(
      title: _editing ? 'Editar uso' : 'Novo uso',
      footer: FilledButton(onPressed: _save, child: const Text('Salvar')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayField(
            day: _day,
            onChanged: (d) => setState(() {
              _day = d;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _lookId,
            decoration: const InputDecoration(labelText: 'Look'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Sem look')),
              for (final l in store.looks) DropdownMenuItem<String?>(value: l.id, child: Text(l.name)),
            ],
            onChanged: _chooseLook,
          ),
          const SizedBox(height: 24),
          SectionLabel('Peças · ${pieces.length}'),
          for (final p in pieces)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 44, height: 44, child: PieceArt(p, radius: 10, padding: 5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(store.typeOf(p).name, style: const TextStyle(fontSize: 12, color: C.text2)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover ${p.name}',
                    onPressed: () => setState(() {
                      _items.remove(p.id);
                      _error = null;
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addPieces,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar peças'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: C.error, fontSize: 14)),
          ],
          if (_editing) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Apagar uso'),
              style: TextButton.styleFrom(foregroundColor: C.danger),
            ),
          ],
        ],
      ),
    );
  }
}
