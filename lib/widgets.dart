import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:path_provider/path_provider.dart';

import 'catalog.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';

final Map<String, Path> _pathCache = {};
Path _path(String d) => _pathCache.putIfAbsent(d, () => parseSvgPathData(d));

/// Desenho da peça (usado quando não há foto).
class GarmentPainter extends CustomPainter {
  final String shape;
  final List<ColorTag> colors;
  final bool patterned;
  GarmentPainter(this.shape, this.colors, this.patterned);

  @override
  void paint(Canvas canvas, Size size) {
    final def = kShapes[shape] ?? kShapes['tee']!;
    final s = math.min(size.width, size.height) / 64;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - 64 * s) / 2, (size.height - 64 * s) / 2);
    canvas.scale(s);
    final main = Color(colors.isNotEmpty ? colors.first.hex : 0xFFC9D4DA);
    final p = _path(def.d);
    canvas.drawPath(p, Paint()..color = main);
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0x521D2930)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    final Color? second = colors.length > 1 ? Color(colors[1].hex) : null;
    if (patterned) {
      canvas.drawPath(_path(kDots), Paint()..color = second ?? const Color(0xFF3E7D5A));
    } else if (def.d2.isNotEmpty) {
      canvas.drawPath(_path(def.d2), Paint()..color = second ?? Color(def.detail ?? 0x00000000));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GarmentPainter old) =>
      old.shape != shape || old.patterned != patterned || old.colors != colors;
}

class GarmentArt extends StatelessWidget {
  final String shape;
  final List<ColorTag> colors;
  final bool patterned;
  const GarmentArt({super.key, required this.shape, required this.colors, this.patterned = false});

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: CustomPaint(painter: GarmentPainter(shape, colors, patterned)));
}

/// Foto da peça, ou o desenho dela quando não houver foto.
class PieceArt extends StatelessWidget {
  final Piece piece;
  final double radius;
  final double padding;
  final double opacity;
  final Color background;
  const PieceArt(
    this.piece, {
    super.key,
    this.radius = 16,
    this.padding = 14,
    this.opacity = 1,
    this.background = C.tile,
  });

  @override
  Widget build(BuildContext context) {
    final path = piece.photoPath;
    final hasPhoto = path != null && File(path).existsSync();
    Widget child;
    if (hasPhoto) {
      child = Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      child = Padding(
        padding: EdgeInsets.all(padding),
        child: GarmentArt(shape: store.shapeOf(piece), colors: piece.colors, patterned: piece.patterned),
      );
    }
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

const double kPhotoMaxHeight = 640;

/// Tira ou escolhe uma foto e salva na pasta do app. Retorna o caminho, ou
/// `null` se a pessoa cancelar. Mostra um aviso se a câmera/galeria falhar.
Future<String?> pickAppPhoto(BuildContext context, ImageSource source) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    // Toda foto é reduzida para no máximo 640px de altura (mantém a proporção).
    final x = await ImagePicker().pickImage(source: source, maxHeight: kPhotoMaxHeight, imageQuality: 85);
    if (x == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await x.saveTo(dest);
    return dest;
  } catch (_) {
    messenger.showSnackBar(SnackBar(
      content: Text(source == ImageSource.camera ? 'Câmera indisponível.' : 'Galeria indisponível.'),
    ));
    return null;
  }
}

/// Bolinhas de cor sobrepostas (ex.: cores de um look).
class ColorDots extends StatelessWidget {
  final List<ColorTag> colors;
  final double size;
  final int max;
  const ColorDots(this.colors, {super.key, this.size = 14, this.max = 4});

  @override
  Widget build(BuildContext context) {
    final shown = colors.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: colors.map((c) => c.name).join(', '),
      child: SizedBox(
        width: size + (shown.length - 1) * size * 0.65,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * size * 0.65,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Color(shown[i].hex),
                    shape: BoxShape.circle,
                    border: Border.all(color: C.surface, width: 1.5),
                    boxShadow: const [BoxShadow(color: Color(0x401D2930), spreadRadius: 0.5)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bolinha de cor selecionável (44px de toque).
class ColorSwatchButton extends StatelessWidget {
  final ColorTag color;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  const ColorSwatchButton({super.key, required this.color, required this.selected, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final light = Color(color.hex).computeLuminance() > 0.5;
    return Semantics(
      button: true,
      selected: selected,
      label: color.name,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Color(color.hex),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? C.accent : C.surface, width: selected ? 3 : 2),
            boxShadow: const [BoxShadow(color: Color(0x331D2930), spreadRadius: 1)],
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 18, color: light ? const Color(0xFF1D2930) : Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Foto do look, ou mosaico com até 4 peças.
class LookArt extends StatelessWidget {
  final Look look;
  final double radius;
  const LookArt(this.look, {super.key, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final path = look.photoPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    }
    final pieces = look.pieceIds().map(store.byId).whereType<Piece>().where((p) => !p.deleted).take(4).toList();
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (final p in pieces) PieceArt(p, radius: radius * 0.6, padding: 6, opacity: p.status == 'guardado' ? 1 : 0.38),
      ],
    );
  }
}

/// Botão de filtro no estilo de busca de imagens: "Cor ▾", ativo fica escuro.
/// Com [open], a seta vira para cima (as opções estão abertas logo abaixo).
class FilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? leading;
  final bool dropdown;
  final bool open;
  const FilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.leading,
    this.dropdown = true,
    this.open = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? C.onAccent : C.text;
    return Semantics(
      button: true,
      selected: active,
      expanded: dropdown ? open : null,
      child: Material(
        color: active ? C.accent : C.surface,
        shape: StadiumBorder(side: BorderSide(color: active || open ? C.accent : C.border, width: open ? 2 : 1)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsets.only(left: leading == null ? 14 : 10, right: dropdown ? 6 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme.merge(data: IconThemeData(size: 18, color: fg), child: leading!),
                  const SizedBox(width: 6),
                ],
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                if (dropdown) Icon(open ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  const StatusBadge(this.status, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final m = statusMeta(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: m.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(m.label, style: TextStyle(color: m.fg, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
  }
}

/// Chip no estilo da barra de categorias do YouTube: cantos de 8px, cinza
/// claro quando solto e escuro com texto branco quando selecionado.
class YtChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final double fontSize;
  const YtChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.fontSize = 14,
  });

  static const bg = C.surface2;
  static const bgOn = C.accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 32px visíveis + margem vertical = 44px de toque.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: selected ? bgOn : bg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(size: 18, color: selected ? C.onAccent : C.text),
                    child: leading!,
                  ),
                  if (label.isNotEmpty) const SizedBox(width: 6),
                ],
                if (label.isNotEmpty)
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: selected ? C.onAccent : C.text,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seletor de visualização no estilo das abas do YouTube: só o texto, sem
/// fundo, com uma barra embaixo da opção ativa e uma linha fina sob todas.
class SegTabs<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double fontSize;
  const SegTabs({super.key, required this.options, required this.value, required this.onChanged, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.divider))),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final o in options)
              Semantics(
                button: true,
                selected: o.$1 == value,
                child: InkWell(
                  onTap: () => onChanged(o.$1),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: o.$1 == value ? C.accent : const Color(0x00000000), width: 3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      o.$2,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w500,
                        color: o.$1 == value ? C.text : C.text2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Véu cinza semitransparente sobre a imagem (peça não selecionada). A imagem
/// em si não fica transparente.
class Veiled extends StatelessWidget {
  final bool veiled;
  final Widget child;
  final double radius;
  const Veiled({super.key, required this.veiled, required this.child, this.radius = 0});

  @override
  Widget build(BuildContext context) {
    if (!veiled) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(color: C.veil, borderRadius: BorderRadius.circular(radius)),
            ),
          ),
        ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  const Pill({super.key, required this.label, required this.selected, required this.onTap, this.leading});

  @override
  Widget build(BuildContext context) =>
      YtChip(label: label, selected: selected, onTap: onTap, leading: leading);
}

class Card2 extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Card2({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F1D2930), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: C.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: C.primaryDark, size: 28),
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Campo obrigatório: mostra alerta ao sair dele vazio.
class RequiredField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String message;
  final String? hint;
  final bool forceError;
  final ValueChanged<String>? onChanged;
  const RequiredField({
    super.key,
    required this.controller,
    required this.label,
    required this.message,
    this.hint,
    this.forceError = false,
    this.onChanged,
  });

  @override
  State<RequiredField> createState() => _RequiredFieldState();
}

class _RequiredFieldState extends State<RequiredField> {
  final FocusNode _node = FocusNode();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (!_node.hasFocus && widget.controller.text.trim().isEmpty) {
        setState(() => _touched = true);
      }
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.controller.text.trim().isEmpty;
    final showError = empty && (_touched || widget.forceError);
    return TextField(
      controller: widget.controller,
      focusNode: _node,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: '${widget.label} *',
        hintText: widget.hint,
        errorText: showError ? widget.message : null,
      ),
      onChanged: (v) {
        if (v.trim().isNotEmpty && _touched) setState(() => _touched = false);
        if (v.trim().isEmpty && widget.forceError) setState(() {});
        widget.onChanged?.call(v);
      },
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

void toast(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 4),
    action: actionLabel != null && onAction != null
        ? SnackBarAction(label: actionLabel, textColor: const Color(0xFFBFD4E0), onPressed: onAction)
        : null,
  ));
}

Future<void> showAppSheet(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: C.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: builder,
  );
}

/// Estrutura padrão de uma aba que sobe de baixo.
class SheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool scroll;
  const SheetFrame({super.key, required this.title, this.subtitle, required this.child, this.footer, this.scroll = true});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle!, style: const TextStyle(fontSize: 14, color: C.text2)),
                    ),
                ],
              ),
            ),
            Flexible(
              child: scroll
                  ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: child)
                  : Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), child: child),
            ),
            if (footer != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider))),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String text,
  required String confirmLabel,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: C.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}
