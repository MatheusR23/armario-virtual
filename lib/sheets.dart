import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

// ============================================================== Pilha
Future<void> showPilha(BuildContext context) => showAppSheet(context, (_) => const PilhaSheet());

class PilhaSheet extends StatefulWidget {
  const PilhaSheet({super.key});
  @override
  State<PilhaSheet> createState() => _PilhaSheetState();
}

class _PilhaSheetState extends State<PilhaSheet> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.pilha;
        if (list.isEmpty) {
          return SheetFrame(
            title: 'Pilha de roupas',
            subtitle: 'Puxe para baixo para fechar.',
            child: Column(
              children: [
                const EmptyState(icon: Icons.layers_outlined, text: 'Nenhuma roupa está em uso no momento.'),
                if (store.undo != null)
                  TextButton.icon(
                    onPressed: store.doUndo,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Desfazer última ação'),
                  ),
              ],
            ),
          );
        }
        final top = list.first;
        final rule = store.ruleOf(top);
        return SheetFrame(
          title: 'Pilha de roupas',
          subtitle: 'Direita: cesto · Esquerda: guardar',
          child: Column(
            children: [
              SizedBox(
                height: 340,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    for (var i = 2; i >= 1; i--)
                      if (list.length > i)
                        Positioned(
                          top: i * 12.0,
                          child: Transform.scale(
                            scale: 1 - i * 0.05,
                            child: Container(
                              width: 260,
                              height: 310,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: C.line),
                              ),
                            ),
                          ),
                        ),
                    Dismissible(
                      key: ValueKey('pilha-${top.id}-$_version'),
                      direction: DismissDirection.horizontal,
                      onDismissed: (d) {
                        _version++;
                        store.sendPilha(top.id, d == DismissDirection.startToEnd ? 'cesto' : 'guardado');
                      },
                      background: _swipeLabel('Cesto', Icons.shopping_basket_outlined, const Color(0xFF7A4F0E), Alignment.centerLeft),
                      secondaryBackground: _swipeLabel('Guardar', Icons.checkroom_outlined, C.success, Alignment.centerRight),
                      child: Container(
                        width: 260,
                        height: 310,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: C.line),
                          boxShadow: const [BoxShadow(color: Color(0x241D2930), blurRadius: 28, offset: Offset(0, 12))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: PieceArt(top, radius: 0, padding: 32)),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(top.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  Text(
                                    'Usada ${relDay(top.lastUse).toLowerCase()} · ${plural(top.since, 'uso', 'usos')} desde a lavagem',
                                    style: const TextStyle(fontSize: 12, color: C.text2),
                                  ),
                                  Text(
                                    rule == 'cesto' ? 'Regra: vai para o cesto' : 'Regra: volta a ser guardada',
                                    style: const TextStyle(fontSize: 12, color: C.primaryDark, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text('1 de ${list.length} na pilha', style: const TextStyle(fontSize: 12, color: C.text2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => store.sendPilha(top.id, 'guardado'),
                      icon: const Icon(Icons.arrow_back_rounded, color: C.success),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => store.sendPilha(top.id, 'cesto'),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF9A6516)),
                      label: const Text('Cesto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => store.autoDecide(),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(list.length > 1 ? 'Decisão automática (${list.length})' : 'Decisão automática'),
                  ),
                  if (store.undo != null)
                    TextButton.icon(
                      onPressed: store.doUndo,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Desfazer'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _swipeLabel(String text, IconData icon, Color color, Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ============================================================== Cesto
Future<void> showCesto(BuildContext context) => showAppSheet(context, (_) => const CestoSheet());

class CestoSheet extends StatefulWidget {
  const CestoSheet({super.key});
  @override
  State<CestoSheet> createState() => _CestoSheetState();
}

class _CestoSheetState extends State<CestoSheet> {
  final Set<String> _off = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.cesto;
        final checked = list.where((p) => !_off.contains(p.id)).map((p) => p.id).toList();
        return SheetFrame(
          title: 'Cesto',
          subtitle: list.isEmpty
              ? 'Puxe para baixo para fechar.'
              : '${plural(list.length, 'peça aguardando', 'peças aguardando')} lavagem. Desmarque o que não vai lavar agora.',
          footer: list.isEmpty
              ? null
              : FilledButton.icon(
                  onPressed: checked.isEmpty
                      ? null
                      : () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'Mandar para a máquina?',
                            text:
                                'As ${plural(checked.length, 'peça marcada', 'peças marcadas')} voltam para o guarda-roupas limpas, e o contador de usos desde a lavagem é zerado.',
                            confirmLabel: 'Lavar ${plural(checked.length, 'peça', 'peças')}',
                          );
                          if (ok) {
                            store.wash(checked);
                            _off.clear();
                          }
                        },
                  icon: const Icon(Icons.local_laundry_service_outlined),
                  label: Text('Mandar para a máquina · ${checked.length}'),
                ),
          child: list.isEmpty
              ? const EmptyState(icon: Icons.shopping_basket_outlined, text: 'O cesto está vazio.')
              : Column(
                  children: [
                    for (final p in list)
                      Opacity(
                        opacity: _off.contains(p.id) ? 0.5 : 1,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Checkbox(
                                value: !_off.contains(p.id),
                                activeColor: C.primary,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _off.remove(p.id);
                                  } else {
                                    _off.add(p.id);
                                  }
                                }),
                              ),
                              SizedBox(width: 52, height: 52, child: PieceArt(p, radius: 12, padding: 6)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('${plural(p.since, 'uso', 'usos')} desde a lavagem',
                                        style: const TextStyle(fontSize: 12, color: C.text2)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => store.setStatus(p.id, 'emUso'),
                                child: const Text('Voltar à pilha', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

// ============================================================== Confirmar uso
Future<void> showConfirmUse(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet(context, (_) => ConfirmUseSheet(messenger: messenger));
}

class ConfirmUseSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  const ConfirmUseSheet({super.key, required this.messenger});
  @override
  State<ConfirmUseSheet> createState() => _ConfirmUseSheetState();
}

class _ConfirmUseSheetState extends State<ConfirmUseSheet> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final t = todayDay();
    final day = t - _offset;
    final pieces = store.sel.ids().map(store.byId).whereType<Piece>().toList();
    final okN = pieces.where((p) => !store.usedOn(p.id, day)).length;
    return SheetFrame(
      title: 'Confirmar uso',
      subtitle: 'Os usos entram no rastreio e as peças vão para a Pilha.',
      footer: FilledButton(
        onPressed: okN == 0
            ? null
            : () {
                final r = store.confirmUse(day);
                Navigator.pop(context);
                final text = r.$2 > 0
                    ? '${plural(r.$1, 'peça registrada', 'peças registradas')}; ${r.$2} já tinha${r.$2 > 1 ? 'm' : ''} uso nesta data.'
                    : '${plural(r.$1, 'peça registrada', 'peças registradas')}. Elas estão na Pilha.';
                widget.messenger.hideCurrentSnackBar();
                widget.messenger.showSnackBar(SnackBar(content: Text(text)));
              },
        child: Text(okN == 0 ? 'Nada novo para registrar' : 'Registrar ${plural(okN, 'uso', 'usos')}'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Data de uso'),
          Wrap(
            spacing: 8,
            children: [
              Pill(label: 'Hoje · ${fmtDay(t)}', selected: _offset == 0, onTap: () => setState(() => _offset = 0)),
              Pill(label: 'Ontem · ${fmtDay(t - 1)}', selected: _offset == 1, onTap: () => setState(() => _offset = 1)),
            ],
          ),
          const SizedBox(height: 16),
          for (final p in pieces)
            Opacity(
              opacity: store.usedOn(p.id, day) ? 0.55 : 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 48, height: 48, child: PieceArt(p, radius: 12, padding: 6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            store.usedOn(p.id, day)
                                ? 'Já registrada nesta data · será ignorada'
                                : '${store.typeOf(p).name} · vai para a Pilha',
                            style: TextStyle(
                              fontSize: 12,
                              color: store.usedOn(p.id, day) ? const Color(0xFF8A5A12) : C.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================== Criar look
Future<void> showSaveLook(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet(context, (_) => SaveLookSheet(messenger: messenger));
}

class SaveLookSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  const SaveLookSheet({super.key, required this.messenger});
  @override
  State<SaveLookSheet> createState() => _SaveLookSheetState();
}

class _SaveLookSheetState extends State<SaveLookSheet> {
  final _name = TextEditingController();
  String _occasion = 'Dia a dia';
  bool _force = false;
  static const _occasions = ['Dia a dia', 'Trabalho', 'Lazer', 'Passeio', 'Festa'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = store.sel.ids().map(store.byId).whereType<Piece>().map((p) => p.name).toList();
    return SheetFrame(
      title: 'Criar novo look',
      subtitle: 'Salve esta combinação para usar de novo.',
      footer: FilledButton(
        onPressed: () {
          final n = _name.text.trim();
          if (n.isEmpty) {
            setState(() => _force = true);
            return;
          }
          store.saveLook(n, _occasion);
          Navigator.pop(context);
          widget.messenger.showSnackBar(SnackBar(content: Text('Look $n salvo.')));
        },
        child: const Text('Salvar look'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequiredField(
            controller: _name,
            label: 'Nome do look',
            message: 'Dê um nome ao look.',
            hint: 'Ex.: Reunião de sexta',
            forceError: _force,
          ),
          const SizedBox(height: 16),
          const SectionLabel('Ocasião'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _occasions)
                Pill(label: o, selected: _occasion == o, onTap: () => setState(() => _occasion = o)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Peças: ${joinNames(names)}.', style: const TextStyle(fontSize: 14, color: C.text2)),
        ],
      ),
    );
  }
}

// ============================================================== Ver todas (galeria de uma parte)
Future<void> showPicker(BuildContext context, String key) =>
    showAppSheet(context, (_) => PickerSheet(sectionKey: key));

class PickerSheet extends StatelessWidget {
  final String sectionKey;
  const PickerSheet({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final list = store.sectionItems(sectionKey);
    final layered = sectionKey == 'cima' || sectionKey == 'baixo';
    final slot = store.slotId(sectionKey);
    const titles = {'cima': 'Parte de cima', 'baixo': 'Parte de baixo', 'calcado': 'Calçados', 'acess': 'Acessórios'};
    return SheetFrame(
      title: titles[sectionKey] ?? '',
      subtitle: layered ? 'Escolhendo a camada ${store.sel.layer[sectionKey]! + 1}' : 'Toque para escolher',
      child: list.isEmpty
          ? const EmptyState(icon: Icons.checkroom_outlined, text: 'Nenhuma peça disponível nesta parte.')
          : GalleryGrid(
              pieces: list,
              selectedIds: sectionKey == 'acess' ? store.sel.acess : [if (slot != null) slot],
              onTap: (p) {
                store.pick(sectionKey, p.id, toggle: sectionKey == 'acess');
                Navigator.pop(context);
              },
            ),
    );
  }
}

/// Grade de peças em 3 colunas.
class GalleryGrid extends StatelessWidget {
  final List<Piece> pieces;
  final List<String> selectedIds;
  final ValueChanged<Piece> onTap;
  final String Function(Piece)? subtitle;
  const GalleryGrid({super.key, required this.pieces, required this.selectedIds, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.66,
      children: [
        for (final p in pieces)
          GestureDetector(
            onTap: () => onTap(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 0.92,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedIds.contains(p.id) ? C.primaryDark : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: PieceArt(p, radius: 13, padding: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle != null ? subtitle!(p) : plural(p.total, 'uso', 'usos'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.text2)),
              ],
            ),
          ),
      ],
    );
  }
}
