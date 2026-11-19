import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'sheets.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

const Map<String, String> kSectionTitles = {
  'cima': 'Parte de cima',
  'baixo': 'Parte de baixo',
  'calcado': 'Calçados',
  'acess': 'Acessórios',
};

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final ids = store.sel.ids();
        final name = store.profileName.trim();
        final pilhaN = store.pilha.length;
        final cestoN = store.cesto.length;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 220),
              children: [
                Text(
                  name.isEmpty ? 'Olá!' : 'Olá, $name',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('Roupas de hoje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                if (store.sel.missing.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _MissingBanner(names: store.sel.missing.map((m) => m.split('|').last).toList()),
                ],
                for (final key in const ['cima', 'baixo', 'calcado']) _CarouselSection(sectionKey: key),
                const _AccessoriesSection(),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 92,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'fab-pilha',
                    tooltip: 'Pilha de roupas',
                    backgroundColor: Colors.white,
                    foregroundColor: C.primaryDark,
                    shape: const CircleBorder(),
                    onPressed: () => showPilha(context),
                    child: Badge(
                      isLabelVisible: pilhaN > 0,
                      backgroundColor: const Color(0xFF2B5674),
                      label: Text('$pilhaN'),
                      child: const Icon(Icons.layers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'fab-cesto',
                    tooltip: 'Cesto de roupas sujas',
                    backgroundColor: C.primaryDark,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    onPressed: () => showCesto(context),
                    child: Badge(
                      isLabelVisible: cestoN > 0,
                      backgroundColor: const Color(0xFFE3A33B),
                      textColor: const Color(0xFF3D2604),
                      label: Text('$cestoN'),
                      child: const Icon(Icons.shopping_basket_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xF2F7F9FA),
                  border: Border(top: BorderSide(color: C.line)),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: ids.isEmpty ? null : () => showSaveLook(context),
                      child: const Text('Criar look'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: ids.isEmpty ? null : () => showConfirmUse(context),
                        child: Text(ids.isEmpty ? 'Confirmar uso' : 'Confirmar uso · ${ids.length}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MissingBanner extends StatelessWidget {
  final List<String> names;
  const _MissingBanner({required this.names});

  @override
  Widget build(BuildContext context) {
    final verb = names.length > 1 ? 'estão' : 'está';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.warningBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: C.warningFg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${joinNames(names)} $verb no cesto.',
              style: const TextStyle(color: C.warningFg, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSection extends StatelessWidget {
  final String sectionKey;
  const _CarouselSection({required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final key = sectionKey;
    final list = store.sectionItems(key);
    final layered = key != 'calcado';
    final f = store.focusIndex(key, list);
    final Piece? cur = list.isEmpty ? null : list[f];
    final slot = store.slotId(key);
    final centerSel = cur != null && slot == cur.id;
    final peeks = <int>[];
    if (layered) {
      final arr = store.layersOf(key);
      final l = store.sel.layer[key]!;
      for (var i = 0; i < arr.length; i++) {
        if (i != l && arr[i] != null) peeks.add(i - l);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Text(kSectionTitles[key]!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (cur == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhuma peça disponível nesta parte.', style: TextStyle(color: C.text2)),
            )
          else ...[
            CoverCarousel(
              key: ValueKey('car-$key-${layered ? store.sel.layer[key] : 0}'),
              items: list,
              focus: f,
              centerSelected: centerSel,
              peeks: peeks,
              onFocus: (i) => store.carouselMoved(key, list, i),
              onTapCenter: (i) => store.tapCenter(key, list, i),
              overlay: layered ? LayerColumn(sectionKey: key) : null,
            ),
            const SizedBox(height: 4),
            Text(cur.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(cur.status),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => showPicker(context, key),
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: Text('${f + 1} de ${list.length}'),
                  style: TextButton.styleFrom(foregroundColor: C.text2),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class LayerColumn extends StatelessWidget {
  final String sectionKey;
  const LayerColumn({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final key = sectionKey;
    final arr = store.layersOf(key);
    final l = store.sel.layer[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < arr.length; i++)
          SizedBox(
            height: 44,
            child: Center(
              child: i == l
                  ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: C.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color(0x381D2930), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          if (arr.length > 1)
                            Semantics(
                              button: true,
                              label: 'Remover camada ${i + 1}',
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => store.removeLayer(key),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(color: Color(0xFFF2C4C2), shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF7A1F1C)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Semantics(
                      button: true,
                      label: 'Camada ${i + 1}',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => store.setLayer(key, i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE1E8EC),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Color(0x1F1D2930), blurRadius: 4, offset: Offset(0, 1))],
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(color: C.primaryDark, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        if (arr.length < 3)
          SizedBox(
            height: 44,
            child: Center(
              child: Semantics(
                button: true,
                label: 'Adicionar camada',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => store.addLayer(key),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFE1E8EC), shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, size: 18, color: C.primaryDark),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Carrossel infinito com a peça em destaque no centro.
class CoverCarousel extends StatefulWidget {
  final List<Piece> items;
  final int focus;
  final bool centerSelected;
  final List<int> peeks;
  final ValueChanged<int> onFocus;
  final ValueChanged<int> onTapCenter;
  final Widget? overlay;
  const CoverCarousel({
    super.key,
    required this.items,
    required this.focus,
    required this.centerSelected,
    required this.peeks,
    required this.onFocus,
    required this.onTapCenter,
    this.overlay,
  });

  @override
  State<CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<CoverCarousel> {
  static const int _loops = 1000;
  late PageController _ctrl;
  bool _programmatic = false;

  int get _n => widget.items.length;
  int _pageFor(int idx) => _n <= 1 ? 0 : _loops * _n + idx;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.4, initialPage: _pageFor(widget.focus));
  }

  @override
  void didUpdateWidget(covariant CoverCarousel old) {
    super.didUpdateWidget(old);
    if (_n == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ctrl.hasClients) return;
      final cur = (_ctrl.page ?? _ctrl.initialPage.toDouble()).round();
      if (_n <= 1) return;
      if (old.items.length != _n) {
        _jump(_pageFor(widget.focus));
        return;
      }
      if (cur % _n != widget.focus) {
        var delta = widget.focus - cur % _n;
        if (delta > _n / 2) delta -= _n;
        if (delta < -_n / 2) delta += _n;
        _jump(cur + delta);
      }
    });
  }

  void _jump(int page) {
    _programmatic = true;
    _ctrl.jumpToPage(page);
    _programmatic = false;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _n;
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          for (final k in widget.peeks)
            Center(
              child: Transform.translate(
                offset: Offset(0, k * 18.0),
                child: Container(
                  width: 124,
                  height: 152,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D6DD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.primaryDark, width: 4),
                  ),
                ),
              ),
            ),
          PageView.builder(
            controller: _ctrl,
            itemCount: n <= 1 ? 1 : null,
            onPageChanged: (p) {
              if (_programmatic || n == 0) return;
              widget.onFocus(p % n);
            },
            itemBuilder: (context, p) {
              final idx = n == 0 ? 0 : p % n;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  double page = p.toDouble();
                  if (_ctrl.hasClients && _ctrl.position.haveDimensions) {
                    page = _ctrl.page ?? page;
                  } else {
                    page = _ctrl.initialPage.toDouble();
                  }
                  final diff = (page - p).abs();
                  final scale = (1 - diff * 0.22).clamp(0.6, 1.0).toDouble();
                  final opacity = (1 - diff * 0.35).clamp(0.3, 1.0).toDouble();
                  final isCenter = diff < 0.5;
                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: _card(idx, p, isCenter),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (n > 1) ...[
            Positioned(
              left: -6,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  tooltip: 'Peça anterior',
                  onPressed: () => _ctrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  icon: const Icon(Icons.chevron_left_rounded, size: 32, color: C.text),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  tooltip: 'Próxima peça',
                  onPressed: () => _ctrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  icon: const Icon(Icons.chevron_right_rounded, size: 32, color: C.text),
                ),
              ),
            ),
          ],
          if (widget.overlay != null)
            Positioned(right: 40, top: 0, bottom: 0, child: Center(child: widget.overlay!)),
        ],
      ),
    );
  }

  Widget _card(int idx, int page, bool isCenter) {
    final piece = widget.items[idx];
    final selected = isCenter && widget.centerSelected;
    return Semantics(
      button: true,
      label: isCenter
          ? (selected ? 'Tirar ${piece.name} das roupas de hoje' : 'Usar ${piece.name} hoje')
          : 'Mostrar ${piece.name}',
      child: GestureDetector(
        onTap: () {
          if (isCenter) {
            widget.onTapCenter(idx);
          } else {
            _ctrl.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
          }
        },
        child: Container(
          width: 136,
          height: 152,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isCenter
                ? Border.all(color: selected ? C.primaryDark : const Color(0xFF8FA3AE), width: selected ? 4 : 3)
                : null,
            boxShadow: isCenter
                ? const [BoxShadow(color: Color(0x331D2930), blurRadius: 20, offset: Offset(0, 8))]
                : const [BoxShadow(color: Color(0x1A1D2930), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: PieceArt(
                  piece,
                  radius: isCenter ? 16 : 20,
                  background: isCenter ? C.tile : const Color(0xFFD9E2E7),
                ),
              ),
              if (isCenter && !selected)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                      child: const Text('Toque para usar',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.primaryDark)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessoriesSection extends StatelessWidget {
  const _AccessoriesSection();

  @override
  Widget build(BuildContext context) {
    final list = store.sectionItems('acess');
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const Text('Acessórios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum acessório disponível.', style: TextStyle(color: C.text2)),
            )
          else
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.74,
              children: [
                for (final p in list)
                  _AccessoryTile(piece: p, selected: store.sel.acess.contains(p.id)),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccessoryTile extends StatelessWidget {
  final Piece piece;
  final bool selected;
  const _AccessoryTile({required this.piece, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: piece.name,
      child: GestureDetector(
        onTap: () => store.pick('acess', piece.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? C.primaryDark : Colors.transparent, width: 3),
                      ),
                      child: PieceArt(piece, radius: 11, padding: 8),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(color: C.primaryDark, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(piece.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
