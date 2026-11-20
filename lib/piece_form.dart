import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'catalog.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showPieceForm(BuildContext context, {String? editId}) {
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet(context, (_) => PieceFormSheet(editId: editId, messenger: messenger));
}

class PieceFormSheet extends StatefulWidget {
  final String? editId;
  final ScaffoldMessengerState messenger;
  const PieceFormSheet({super.key, this.editId, required this.messenger});

  @override
  State<PieceFormSheet> createState() => _PieceFormSheetState();
}

class _PieceFormSheetState extends State<PieceFormSheet> {
  String? _photo;
  String _typeId = 'camiseta';
  List<ColorTag> _colors = [const ColorTag('Azul', 0xFF26406A)];
  List<String> _tags = [];
  bool _patterned = false;
  String _status = 'guardado';
  final _desc = TextEditingController();
  bool _forceDesc = false;
  bool _photoError = false;

  // nova tag
  final _newTag = TextEditingController();
  String? _tagError;

  // novo tipo
  bool _ntOpen = false;
  final _ntName = TextEditingController();
  String _ntCat = 'cima';
  String _ntRule = 'cesto';
  String? _ntError;

  // nova cor
  bool _ncOpen = false;
  final _ncName = TextEditingController();
  int _ncHex = kPalette.last;
  String? _ncError;

  bool get _editing => widget.editId != null;

  @override
  void initState() {
    super.initState();
    final p = store.byId(widget.editId);
    if (p != null) {
      _photo = p.photoPath;
      _typeId = p.typeId;
      _colors = List<ColorTag>.of(p.colors);
      _tags = List<String>.of(p.tags);
      _patterned = p.patterned;
      _status = p.status;
      _desc.text = p.name;
    }
  }

  @override
  void dispose() {
    _desc.dispose();
    _newTag.dispose();
    _ntName.dispose();
    _ncName.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final dest = await pickAppPhoto(context, source);
    if (dest == null || !mounted) return;
    setState(() {
      _photo = dest;
      _photoError = false;
    });
  }

  void _save() {
    final name = _desc.text.trim();
    final needsPhoto = !_editing && _photo == null;
    setState(() {
      _forceDesc = name.isEmpty;
      _photoError = needsPhoto;
    });
    if (name.isEmpty || needsPhoto) return;
    if (_editing) {
      store.updatePiece(widget.editId!,
          name: name,
          typeId: _typeId,
          colors: _colors,
          tags: _tags,
          patterned: _patterned,
          status: _status,
          photoPath: _photo);
      Navigator.pop(context);
      widget.messenger.showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
    } else {
      store.addPiece(
          name: name,
          typeId: _typeId,
          colors: _colors,
          tags: _tags,
          patterned: _patterned,
          status: _status,
          photoPath: _photo);
      Navigator.pop(context);
      widget.messenger.showSnackBar(const SnackBar(content: Text('Peça salva.')));
    }
  }

  void _addTag() {
    final t = _newTag.text.trim().replaceAll(RegExp(r'^#+'), '').trim().toLowerCase();
    if (t.isEmpty) {
      setState(() => _tagError = 'Escreva o nome da tag.');
      return;
    }
    if (_tags.contains(t)) {
      setState(() => _tagError = 'Essa tag já está na peça.');
      return;
    }
    store.addExtraTag(t);
    setState(() {
      _tags.add(t);
      _newTag.clear();
      _tagError = null;
    });
  }

  void _addType() {
    final err = store.addType(_ntName.text, _ntCat, _ntRule, (id) => _typeId = id);
    setState(() {
      _ntError = err;
      if (err == null) {
        _ntOpen = false;
        _ntName.clear();
      }
    });
  }

  void _addColor() {
    final err = store.addColor(_ncName.text, _ncHex, (c) => _colors.add(c));
    setState(() {
      _ncError = err;
      if (err == null) {
        _ncOpen = false;
        _ncName.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tagPool = <String>{...store.allTags, ...store.extraTags, ..._tags}.toList()..sort();
    final previewPiece = Piece(id: 'preview', name: '', typeId: _typeId, colors: _colors, patterned: _patterned, photoPath: _photo);
    return SheetFrame(
      title: _editing ? 'Editar peça' : 'Nova peça',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_photoError)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Adicione uma foto.',
                  textAlign: TextAlign.center, style: TextStyle(color: C.error, fontWeight: FontWeight.w600)),
            ),
          FilledButton(onPressed: _save, child: Text(_editing ? 'Salvar alterações' : 'Salvar peça')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- foto
          SectionLabel(_editing ? 'Foto' : 'Foto *'),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: C.tile,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _photoError ? C.error : Colors.transparent, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(child: PieceArt(previewPiece, radius: 18, padding: 36)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Câmera'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeria'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- tipo
          const SectionLabel('Tipo *'),
          for (final cat in kCats.keys)
            if (store.allTypes.any((t) => t.cat == cat)) ...[
              Text(kCats[cat]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text2)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in store.allTypes.where((t) => t.cat == cat))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pill(label: t.name, selected: _typeId == t.id, onTap: () => setState(() => _typeId = t.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          if (!_ntOpen)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _ntOpen = true;
                  _ntError = null;
                }),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo tipo'),
              ),
            )
          else
            _panel(
              children: [
                TextField(
                  controller: _ntName,
                  decoration: InputDecoration(labelText: 'Nome do tipo *', hintText: 'Ex.: Cropped', errorText: _ntError),
                  onChanged: (_) {
                    if (_ntError != null) setState(() => _ntError = null);
                  },
                ),
                const SizedBox(height: 12),
                const SectionLabel('Parte'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in kCats.entries)
                      Pill(
                        label: e.value,
                        selected: _ntCat == e.key,
                        onTap: () => setState(() {
                          _ntCat = e.key;
                          _ntRule = (e.key == 'calcado' || e.key == 'acessorio' || e.key == 'outros') ? 'guardado' : 'cesto';
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const SectionLabel('Após o uso'),
                SegTabs<String>(
                  options: const [('cesto', 'Cesto'), ('guardado', 'Guardado')],
                  value: _ntRule,
                  onChanged: (v) => setState(() => _ntRule = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _ntOpen = false), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _addType, child: const Text('Criar tipo')),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // ---- descrição
          RequiredField(
            controller: _desc,
            label: 'Descrição',
            message: 'Descreva a peça.',
            hint: 'Ex.: Camiseta listrada',
            forceError: _forceDesc,
          ),
          const SizedBox(height: 24),

          // ---- tags
          const SectionLabel('Tags'),
          if (tagPool.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tagPool)
                  Pill(
                    label: '#$t',
                    selected: _tags.contains(t),
                    onTap: () => setState(() {
                      if (!_tags.remove(t)) _tags.add(t);
                    }),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newTag,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: 'Nova tag', errorText: _tagError),
                  onChanged: (_) {
                    if (_tagError != null) setState(() => _tagError = null);
                  },
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(onPressed: _addTag, icon: const Icon(Icons.add_rounded), label: const Text('Criar')),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- cores
          const SectionLabel('Cores'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in store.allColors) _swatch(c),
              Semantics(
                button: true,
                label: 'Criar nova cor',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() {
                    _ncOpen = true;
                    _ncError = null;
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF9FB1BB), width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: C.primaryDark),
                  ),
                ),
              ),
            ],
          ),
          if (_ncOpen) ...[
            const SizedBox(height: 12),
            _panel(
              children: [
                const SectionLabel('Tom'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in kPalette)
                      GestureDetector(
                        onTap: () => setState(() => _ncHex = h),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(h),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ncHex == h ? C.primaryDark : const Color(0xFFC9D4DA),
                              width: _ncHex == h ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ncName,
                  decoration: InputDecoration(labelText: 'Nome da cor *', hintText: 'Ex.: Verde-oliva', errorText: _ncError),
                  onChanged: (_) {
                    if (_ncError != null) setState(() => _ncError = null);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _ncOpen = false), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _addColor, child: const Text('Criar cor')),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // ---- estampa e status
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: C.primary,
            value: _patterned,
            onChanged: (v) => setState(() => _patterned = v ?? false),
            title: const Text('Estampada'),
          ),
          const SizedBox(height: 8),
          const SectionLabel('Status'),
          SegTabs<String>(
            options: const [('guardado', 'Guardado'), ('emUso', 'Em uso'), ('cesto', 'Cesto')],
            value: _status,
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
    );
  }

  Widget _swatch(ColorTag c) {
    final on = _colors.any((x) => x.hex == c.hex && x.name == c.name);
    return Semantics(
      button: true,
      selected: on,
      label: c.name,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() {
          if (on) {
            _colors.removeWhere((x) => x.hex == c.hex && x.name == c.name);
          } else {
            _colors.add(c);
          }
        }),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(c.hex),
            shape: BoxShape.circle,
            border: Border.all(color: on ? C.primaryDark : Colors.white, width: on ? 3 : 2),
            boxShadow: const [BoxShadow(color: Color(0x331D2930), blurRadius: 0, spreadRadius: 1)],
          ),
          child: on ? Icon(Icons.check_rounded, size: 18, color: _isLight(c.hex) ? C.text : Colors.white) : null,
        ),
      ),
    );
  }

  bool _isLight(int hex) => Color(hex).computeLuminance() > 0.5;

  Widget _panel({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF3F6F8), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}
