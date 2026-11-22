import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'catalog.dart';
import 'models.dart';

final Store store = Store();

/// Aba ativa da navegação inferior (0 Guarda-Roupas, 1 Início, 2 Rastreio, 3 Menu).
final ValueNotifier<int> tabIndex = ValueNotifier<int>(1);

/// Tema escolhido: sistema | claro | escuro.
final ValueNotifier<String> themeMode = ValueNotifier<String>('sistema');

/// Colunas da grade do Guarda-Roupas (ajustável com pinça).
const int kMinCols = 2;
const int kMaxCols = 4;

class Selection {
  List<String?> cima = [null];
  List<String?> baixo = [null];
  String? calcado;
  List<String> acess = [];
  Map<String, int> layer = {'cima': 0, 'baixo': 0};
  String? fromLook;

  /// Itens no formato "secao|nome" das peças do look que estão no cesto.
  List<String> missing = [];

  List<String> ids() {
    final all = <String>[
      ...cima.whereType<String>(),
      ...baixo.whereType<String>(),
      if (calcado != null) calcado!,
      ...acess,
    ];
    final out = <String>[];
    for (final id in all) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }
}

class Store extends ChangeNotifier {
  bool loaded = false;
  List<Piece> items = [];
  List<Look> looks = [];
  List<UseLog> log = [];
  List<LookLog> lookLog = [];
  List<Wash> washes = [];
  List<Removal> removals = [];
  List<PieceType> customTypes = [];
  List<ColorTag> customColors = [];
  List<String> extraTags = [];
  List<String> customOccasions = [];
  List<Wear> wears = [];
  WeatherData? weather;
  Map<String, String> rules = {};
  String profileName = '';
  int cols = 2;

  Selection sel = Selection();
  final Map<String, int> focus = {};
  List<MapEntry<String, String>>? undo;
  File? _file;

  // ---------------------------------------------------------------- consultas
  List<Piece> get live => items.where((p) => !p.deleted).toList();
  List<PieceType> get allTypes => [...kTypes, ...customTypes];
  List<ColorTag> get allColors => [...kColors, ...customColors];

  PieceType typeById(String id) {
    for (final t in allTypes) {
      if (t.id == id) return t;
    }
    return kTypes.last;
  }

  PieceType typeOf(Piece p) => typeById(p.typeId);
  String catOf(Piece p) => typeOf(p).cat;
  String shapeOf(Piece p) => p.shape ?? typeOf(p).shape;
  String typeRule(String typeId) => rules[typeId] ?? typeById(typeId).rule;
  String ruleOf(Piece p) => p.rule ?? typeRule(p.typeId);

  Piece? byId(String? id) {
    if (id == null) return null;
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }

  Look? lookById(String? id) {
    if (id == null) return null;
    for (final l in looks) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<String> get allTags {
    final s = <String>{};
    for (final p in live) {
      s.addAll(p.tags);
    }
    final l = s.toList();
    l.sort();
    return l;
  }

  List<Piece> get pilha {
    final l = live.where((p) => p.status == 'emUso').toList();
    l.sort((a, b) {
      final c = (b.lastUse ?? 0).compareTo(a.lastUse ?? 0);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return l;
  }

  List<Piece> get cesto => live.where((p) => p.status == 'cesto').toList();

  // ---------------------------------------------------------------- persistência
  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/armario_virtual.json');
      _file = f;
      if (await f.exists()) {
        _fromJson(Map<String, dynamic>.from(jsonDecode(await f.readAsString()) as Map));
      } else {
        // Primeira vez: armário vazio, abrindo no Guarda-Roupas.
        tabIndex.value = 0;
        await _save();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final f = _file;
    if (f == null) return;
    try {
      await f.writeAsString(jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('Erro ao salvar dados: $e');
    }
  }

  void commit() {
    notifyListeners();
    _save();
  }

  Map<String, dynamic> _toJson() => {
        'v': 1,
        'items': items.map((e) => e.toJson()).toList(),
        'looks': looks.map((e) => e.toJson()).toList(),
        'log': log.map((e) => e.toJson()).toList(),
        'lookLog': lookLog.map((e) => e.toJson()).toList(),
        'washes': washes.map((e) => e.toJson()).toList(),
        'removals': removals.map((e) => e.toJson()).toList(),
        'customTypes': customTypes.map((e) => e.toJson()).toList(),
        'customColors': customColors.map((e) => e.toJson()).toList(),
        'extraTags': extraTags,
        'customOccasions': customOccasions,
        'wears': wears.map((e) => e.toJson()).toList(),
        'weather': weather?.toJson(),
        'rules': rules,
        'profileName': profileName,
        'cols': cols,
        'theme': themeMode.value,
      };

  void _fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> l(String k) => ((j[k] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    items = l('items').map(Piece.fromJson).toList();
    looks = l('looks').map(Look.fromJson).toList();
    log = l('log').map(UseLog.fromJson).toList();
    lookLog = l('lookLog').map(LookLog.fromJson).toList();
    washes = l('washes').map(Wash.fromJson).toList();
    removals = l('removals').map(Removal.fromJson).toList();
    customTypes = l('customTypes').map(PieceType.fromJson).toList();
    customColors = l('customColors').map(ColorTag.fromJson).toList();
    extraTags = ((j['extraTags'] as List?) ?? const []).map((e) => e.toString()).toList();
    customOccasions = ((j['customOccasions'] as List?) ?? const []).map((e) => e.toString()).toList();
    if (j['wears'] is List) {
      wears = l('wears').map(Wear.fromJson).toList();
    } else {
      _migrateWears();
    }
    final w = j['weather'];
    weather = w is Map ? WeatherData.fromJson(Map<String, dynamic>.from(w)) : null;
    rules = {};
    final r = j['rules'];
    if (r is Map) {
      r.forEach((k, v) => rules[k.toString()] = v.toString());
    }
    profileName = (j['profileName'] as String?) ?? '';
    cols = ((j['cols'] as num?)?.toInt() ?? 2).clamp(kMinCols, kMaxCols);
    final th = j['theme'];
    if (th is String && const ['sistema', 'claro', 'escuro'].contains(th)) themeMode.value = th;
  }

  /// Dados antigos (sem histórico): agrupa os usos por dia e liga ao look
  /// usado naquele dia quando as peças batem.
  void _migrateWears() {
    wears = [];
    final byDay = <int, List<String>>{};
    for (final l in log) {
      (byDay[l.day] ??= <String>[]).add(l.itemId);
    }
    var n = 0;
    for (final e in byDay.entries) {
      final rest = List<String>.of(e.value);
      for (final ll in lookLog.where((x) => x.day == e.key)) {
        final lk = lookById(ll.lookId);
        if (lk == null) continue;
        final ids = lk.pieceIds();
        final mine = rest.where(ids.contains).toList();
        if (mine.isEmpty) continue;
        rest.removeWhere(mine.contains);
        wears.add(Wear(id: 'w${e.key}_${n++}', day: e.key, lookId: lk.id, items: mine));
      }
      if (rest.isNotEmpty) wears.add(Wear(id: 'w${e.key}_${n++}', day: e.key, items: rest));
    }
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());

  /// Cópia dos dados no formato salvo (usada pelo backup).
  Map<String, dynamic> snapshot() => _toJson();

  /// Substitui todos os dados pelos de um backup. Se o backup estiver com
  /// problema, mantém os dados atuais e repassa o erro.
  void restore(Map<String, dynamic> j) {
    final before = _toJson();
    try {
      _fromJson(j);
    } catch (_) {
      _fromJson(before);
      rethrow;
    }
    undo = null;
    sel = Selection();
    focus.clear();
    commit();
  }

  String exportCsv() {
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final b = StringBuffer('peca;tipo;cores;tags;status;usos_total;usos_desde_lavagem;ultimo_uso;ultima_lavagem\n');
    for (final p in live) {
      b.writeln([
        q(p.name),
        q(typeOf(p).name),
        q(p.colors.map((c) => c.name).join(', ')),
        q(p.tags.join(', ')),
        q(statusMeta(p.status).label),
        p.total,
        p.since,
        p.lastUse == null ? '' : dateOf(p.lastUse!).toIso8601String().substring(0, 10),
        p.lastWash == null ? '' : dateOf(p.lastWash!).toIso8601String().substring(0, 10),
      ].join(';'));
    }
    return b.toString();
  }

  void wipe() {
    items = [];
    looks = [];
    log = [];
    lookLog = [];
    washes = [];
    removals = [];
    customTypes = [];
    customColors = [];
    extraTags = [];
    customOccasions = [];
    wears = [];
    rules = {};
    undo = null;
    sel = Selection();
    focus.clear();
    commit();
  }

  // ---------------------------------------------------------------- Início: seleção
  bool _inSection(String key, String cat) {
    switch (key) {
      case 'cima':
        return cat == 'cima' || cat == 'unica';
      case 'baixo':
        return cat == 'baixo' || cat == 'unica';
      case 'calcado':
        return cat == 'calcado';
      default:
        return cat == 'acessorio' || cat == 'outros';
    }
  }

  List<Piece> sectionItems(String key) {
    final l = live
        .where((p) => (p.status == 'guardado' || p.status == 'emUso') && _inSection(key, catOf(p)))
        .toList();
    l.sort((a, b) {
      final c = a.total.compareTo(b.total);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return l;
  }

  bool isOnePiece(String id) {
    final p = byId(id);
    return p != null && catOf(p) == 'unica';
  }

  List<String?> layersOf(String key) => key == 'cima' ? sel.cima : sel.baixo;

  String? slotId(String key) {
    switch (key) {
      case 'cima':
        return sel.cima[sel.layer['cima']!];
      case 'baixo':
        return sel.baixo[sel.layer['baixo']!];
      case 'calcado':
        return sel.calcado;
      default:
        return null;
    }
  }

  String _focusKey(String key) => (key == 'cima' || key == 'baixo') ? '$key${sel.layer[key]}' : key;

  int focusIndex(String key, List<Piece> list) {
    if (list.isEmpty) return 0;
    final id = slotId(key);
    if (id != null) {
      final i = list.indexWhere((p) => p.id == id);
      if (i >= 0) return i;
    }
    final f = focus[_focusKey(key)] ?? 0;
    return math.min(math.max(f, 0), list.length - 1);
  }

  void pick(String key, String id, {bool toggle = true}) {
    if (key == 'cima' || key == 'baixo') {
      final otherKey = key == 'cima' ? 'baixo' : 'cima';
      final arr = layersOf(key);
      final other = layersOf(otherKey);
      final l = sel.layer[key]!;
      final ol = sel.layer[otherKey]!;
      final prev = arr[l];
      void dropOther(String x) {
        for (var i = 0; i < other.length; i++) {
          if (other[i] == x) other[i] = null;
        }
      }

      if (prev == id) {
        if (!toggle) return;
        arr[l] = null;
        if (isOnePiece(id)) dropOther(id);
      } else {
        final ix = arr.indexOf(id);
        if (ix >= 0) arr[ix] = null;
        arr[l] = id;
        if (prev != null && isOnePiece(prev)) dropOther(prev);
        if (isOnePiece(id)) {
          dropOther(id);
          other[math.min(ol, other.length - 1)] = id;
        }
      }
      final one = isOnePiece(id);
      sel.missing.removeWhere((m) => m.startsWith('$key|') || (one && m.startsWith('$otherKey|')));
    } else if (key == 'acess') {
      if (sel.acess.contains(id)) {
        if (toggle) sel.acess.remove(id);
      } else {
        sel.acess.add(id);
      }
      sel.missing.removeWhere((m) => m.startsWith('acess|'));
    } else {
      if (sel.calcado == id) {
        if (toggle) sel.calcado = null;
      } else {
        sel.calcado = id;
      }
      sel.missing.removeWhere((m) => m.startsWith('calcado|'));
    }
    notifyListeners();
  }

  /// O carrossel parou em [index]. Se a camada já tem peça, troca por esta.
  void carouselMoved(String key, List<Piece> list, int index) {
    if (index < 0 || index >= list.length) return;
    if (slotId(key) != null) {
      if (slotId(key) != list[index].id) pick(key, list[index].id, toggle: false);
    } else {
      focus[_focusKey(key)] = index;
      notifyListeners();
    }
  }

  void tapCenter(String key, List<Piece> list, int index) {
    if (index < 0 || index >= list.length) return;
    focus[_focusKey(key)] = index;
    pick(key, list[index].id);
  }

  void setLayer(String key, int i) {
    sel.layer[key] = i;
    notifyListeners();
  }

  void addLayer(String key) {
    final arr = layersOf(key);
    if (arr.length >= 3) return;
    arr.add(null);
    sel.layer[key] = arr.length - 1;
    notifyListeners();
  }

  void removeLayer(String key) {
    final arr = layersOf(key);
    if (arr.length <= 1) return;
    final l = sel.layer[key]!;
    arr.removeAt(l);
    sel.layer[key] = math.max(0, l - 1);
    notifyListeners();
  }

  void clearSelection() {
    sel = Selection();
    focus.clear();
    notifyListeners();
  }

  bool usedOn(String id, int day) => log.any((l) => l.itemId == id && l.day == day);

  /// Registra o uso das peças selecionadas. Retorna (registradas, já existentes).
  (int, int) confirmUse(int day) {
    final ok = <String>[];
    var dup = 0;
    for (final id in sel.ids()) {
      if (byId(id) == null) continue;
      if (usedOn(id, day)) {
        dup++;
        continue;
      }
      ok.add(id);
    }
    if (ok.isNotEmpty) {
      final w = Wear(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        day: day,
        lookId: lookById(sel.fromLook)?.id,
        items: ok,
      );
      wears.add(w);
      _applyWear(w, 1);
      for (final id in ok) {
        byId(id)!.status = 'emUso';
      }
    }
    sel = Selection();
    focus.clear();
    commit();
    return (ok.length, dup);
  }

  // ---------------------------------------------------------------- Histórico de usos
  /// Usos do mais recente para o mais antigo.
  List<Wear> get history {
    final l = List<Wear>.of(wears);
    l.sort((a, b) => a.day != b.day ? b.day.compareTo(a.day) : b.id.compareTo(a.id));
    return l;
  }

  Wear? wearById(String? id) {
    for (final w in wears) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Soma (sign = 1) ou desfaz (sign = -1) os efeitos de um uso: registros,
  /// contadores das peças e usos do look.
  void _applyWear(Wear w, int sign) {
    for (final id in w.items) {
      final p = byId(id);
      if (p == null) continue;
      final countsSince = p.lastWash == null || w.day >= p.lastWash!;
      if (sign > 0) {
        log.add(UseLog(id, w.day));
        p.total++;
        if (countsSince) p.since++;
        p.lastUse = math.max(p.lastUse ?? -1, w.day);
      } else {
        final i = log.indexWhere((l) => l.itemId == id && l.day == w.day);
        if (i >= 0) log.removeAt(i);
        p.total = math.max(0, p.total - 1);
        if (countsSince) p.since = math.max(0, p.since - 1);
        if (p.lastUse == w.day) {
          final days = log.where((l) => l.itemId == id).map((l) => l.day);
          p.lastUse = days.isEmpty ? null : days.reduce(math.max);
        }
      }
    }
    final lk = lookById(w.lookId);
    if (lk == null) return;
    if (sign > 0) {
      lk.uses++;
      if (!lookLog.any((x) => x.lookId == lk.id && x.day == w.day)) lookLog.add(LookLog(lk.id, w.day));
    } else {
      lk.uses = math.max(0, lk.uses - 1);
      final other = wears.any((o) => !identical(o, w) && o.lookId == lk.id && o.day == w.day);
      if (!other) lookLog.removeWhere((x) => x.lookId == lk.id && x.day == w.day);
    }
  }

  /// Cria ([id] nulo) ou altera um uso. Retorna a mensagem de erro, ou null.
  String? saveWear({String? id, required int day, String? lookId, required List<String> items}) {
    final list = <String>[];
    for (final x in items) {
      if (!list.contains(x) && byId(x) != null) list.add(x);
    }
    if (list.isEmpty) return 'Escolha ao menos uma peça.';
    final old = wearById(id);
    if (old != null) _applyWear(old, -1);
    final clash = list.where((x) => usedOn(x, day)).map((x) => byId(x)!.name).toList();
    if (clash.isNotEmpty) {
      if (old != null) _applyWear(old, 1);
      return '${joinNames(clash)} já ${clash.length > 1 ? 'têm' : 'tem'} uso nesse dia.';
    }
    final w = old ?? Wear(id: 'w${DateTime.now().millisecondsSinceEpoch}', day: day);
    w.day = day;
    w.lookId = lookById(lookId)?.id;
    w.items = list;
    if (old == null) wears.add(w);
    _applyWear(w, 1);
    commit();
    return null;
  }

  void deleteWear(String id) {
    final w = wearById(id);
    if (w == null) return;
    _applyWear(w, -1);
    wears.remove(w);
    commit();
  }

  // ---------------------------------------------------------------- Clima
  void setWeather(WeatherData? w) {
    weather = w;
    commit();
  }

  // ---------------------------------------------------------------- Pilha e Cesto
  void sendPilha(String id, String dest) {
    final p = byId(id);
    if (p == null) return;
    undo = [MapEntry(id, p.status)];
    p.status = dest;
    commit();
  }

  (int, int) autoDecide() {
    final list = pilha;
    if (list.isEmpty) return (0, 0);
    undo = list.map((p) => MapEntry(p.id, p.status)).toList();
    var c = 0;
    var g = 0;
    for (final p in list) {
      final r = ruleOf(p);
      if (r == 'cesto') {
        c++;
      } else {
        g++;
      }
      p.status = r;
    }
    commit();
    return (c, g);
  }

  void doUndo() {
    final u = undo;
    if (u == null) return;
    for (final e in u) {
      final p = byId(e.key);
      if (p != null) p.status = e.value;
    }
    undo = null;
    commit();
  }

  void setStatus(String id, String status) {
    final p = byId(id);
    if (p == null) return;
    p.status = status;
    commit();
  }

  void wash(List<String> ids) {
    final t = todayDay();
    for (final id in ids) {
      final p = byId(id);
      if (p == null) continue;
      washes.add(Wash(id, t, p.since));
      p.since = 0;
      p.lastWash = t;
      p.status = 'guardado';
    }
    commit();
  }

  // ---------------------------------------------------------------- Looks
  void useLook(String id) {
    final lk = lookById(id);
    if (lk == null) return;
    bool ok(String? x) {
      final p = byId(x);
      return p != null && !p.deleted && p.status != 'cesto';
    }

    final miss = <String>[];
    void mark(String? x, String sec) {
      final p = byId(x);
      if (p != null && !p.deleted && p.status == 'cesto') {
        final entry = '$sec|${p.name}';
        if (!miss.any((m) => m.endsWith('|${p.name}'))) miss.add(entry);
      }
    }

    for (final x in lk.cima) {
      mark(x, 'cima');
    }
    for (final x in lk.baixo) {
      mark(x, 'baixo');
    }
    mark(lk.calcado, 'calcado');
    for (final x in lk.acess) {
      mark(x, 'acess');
    }
    final s = Selection();
    s.cima = lk.cima.isEmpty ? <String?>[null] : lk.cima.map<String?>((x) => ok(x) ? x : null).toList();
    s.baixo = lk.baixo.isEmpty ? <String?>[null] : lk.baixo.map<String?>((x) => ok(x) ? x : null).toList();
    s.calcado = ok(lk.calcado) ? lk.calcado : null;
    s.acess = lk.acess.where((x) => ok(x)).toList();
    s.layer = {'cima': math.max(0, s.cima.indexOf(null)), 'baixo': math.max(0, s.baixo.indexOf(null))};
    s.fromLook = id;
    s.missing = miss;
    sel = s;
    focus.clear();
    notifyListeners();
    tabIndex.value = 1;
  }

  void saveLook(String name, String occasion, {List<ColorTag> colors = const [], String? photoPath}) {
    final id = 'l${DateTime.now().millisecondsSinceEpoch}';
    looks.add(Look(
      id: id,
      name: name,
      occasion: occasion,
      cima: sel.cima.whereType<String>().toList(),
      baixo: sel.baixo.whereType<String>().toList(),
      calcado: sel.calcado,
      acess: List<String>.of(sel.acess),
      colors: List<ColorTag>.of(colors),
      photoPath: photoPath,
    ));
    sel.fromLook = id;
    commit();
  }

  void updateLook(String id,
      {required String name, required String occasion, required List<ColorTag> colors, String? photoPath}) {
    final l = lookById(id);
    if (l == null) return;
    l.name = name;
    l.occasion = occasion;
    l.colors = List<ColorTag>.of(colors);
    l.photoPath = photoPath;
    commit();
  }

  /// Cores do look: as escolhidas ou, se nenhuma, as das peças (sem repetir nome).
  List<ColorTag> lookColors(Look l) {
    if (l.colors.isNotEmpty) return l.colors;
    final out = <ColorTag>[];
    for (final id in l.pieceIds()) {
      final p = byId(id);
      if (p == null || p.deleted) continue;
      for (final c in p.colors) {
        if (!out.any((x) => x.name == c.name)) out.add(c);
      }
    }
    return out;
  }

  /// Ocasiões padrão, criadas e as já usadas nos looks.
  List<String> get occasions {
    final s = <String>[...kOccasions];
    for (final o in customOccasions) {
      if (!s.contains(o)) s.add(o);
    }
    for (final l in looks) {
      if (l.occasion.isNotEmpty && !s.contains(l.occasion)) s.add(l.occasion);
    }
    return s;
  }

  /// Cria uma ocasião. Retorna a mensagem de erro, ou null se deu certo.
  String? addOccasion(String name) {
    final n = name.trim();
    if (n.isEmpty) return 'Informe a ocasião.';
    if (occasions.any((o) => norm(o) == norm(n))) return 'Essa ocasião já existe.';
    customOccasions.add(n);
    commit();
    return null;
  }

  void toggleFav(String id) {
    final l = lookById(id);
    if (l == null) return;
    l.fav = !l.fav;
    commit();
  }

  void duplicateLook(String id) {
    final l = lookById(id);
    if (l == null) return;
    looks.add(Look(
      id: 'l${DateTime.now().millisecondsSinceEpoch}',
      name: '${l.name} (cópia)',
      occasion: l.occasion,
      cima: List<String>.of(l.cima),
      baixo: List<String>.of(l.baixo),
      calcado: l.calcado,
      acess: List<String>.of(l.acess),
      colors: List<ColorTag>.of(l.colors),
      photoPath: l.photoPath,
    ));
    commit();
  }

  void deleteLook(String id) {
    looks.removeWhere((l) => l.id == id);
    lookLog.removeWhere((l) => l.lookId == id);
    for (final w in wears) {
      if (w.lookId == id) w.lookId = null;
    }
    commit();
  }

  // ---------------------------------------------------------------- Peças
  void addPiece({
    required String name,
    required String typeId,
    required List<ColorTag> colors,
    required List<String> tags,
    required bool patterned,
    required String status,
    String? photoPath,
  }) {
    items.add(Piece(
      id: 'n${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      typeId: typeId,
      colors: List<ColorTag>.of(colors),
      tags: List<String>.of(tags),
      patterned: patterned,
      status: status,
      photoPath: photoPath,
    ));
    commit();
  }

  void updatePiece(
    String id, {
    required String name,
    required String typeId,
    required List<ColorTag> colors,
    required List<String> tags,
    required bool patterned,
    required String status,
    String? photoPath,
  }) {
    final p = byId(id);
    if (p == null) return;
    p.name = name;
    if (p.typeId != typeId) p.shape = null;
    p.typeId = typeId;
    p.colors = List<ColorTag>.of(colors);
    p.tags = List<String>.of(tags);
    p.patterned = patterned;
    p.status = status;
    p.photoPath = photoPath;
    commit();
  }

  void deletePiece(String id, String reason) {
    final p = byId(id);
    if (p == null) return;
    p.deleted = true;
    removals.add(Removal(id, reason, todayDay()));
    for (final arr in [sel.cima, sel.baixo]) {
      for (var i = 0; i < arr.length; i++) {
        if (arr[i] == id) arr[i] = null;
      }
    }
    if (sel.calcado == id) sel.calcado = null;
    sel.acess.remove(id);
    commit();
  }

  void setPieceRule(String id, String rule) {
    final p = byId(id);
    if (p == null) return;
    p.rule = rule == typeRule(p.typeId) ? null : rule;
    commit();
  }

  void setTypeRule(String typeId, String rule) {
    rules[typeId] = rule;
    commit();
  }

  /// Cria um tipo. Retorna a mensagem de erro, ou null se deu certo.
  String? addType(String name, String cat, String rule, void Function(String id) onCreated) {
    final n = name.trim();
    if (n.isEmpty) return 'Informe o nome do tipo.';
    if (allTypes.any((t) => norm(t.name) == norm(n))) return 'Já existe um tipo com esse nome.';
    final id = 't${DateTime.now().millisecondsSinceEpoch}';
    customTypes.add(PieceType(id, n, cat, rule, kCatShape[cat] ?? 'tee', custom: true));
    commit();
    onCreated(id);
    return null;
  }

  String? addColor(String name, int hex, void Function(ColorTag c) onCreated) {
    final n = name.trim();
    if (n.isEmpty) return 'Dê um nome à cor.';
    if (allColors.any((c) => norm(c.name) == norm(n))) return 'Já existe uma cor com esse nome.';
    final c = ColorTag(n, hex);
    customColors.add(c);
    commit();
    onCreated(c);
    return null;
  }

  void addExtraTag(String t) {
    if (!extraTags.contains(t)) {
      extraTags.add(t);
      commit();
    }
  }

  void setName(String v) {
    profileName = v;
    commit();
  }

  void setCols(int c) {
    final v = c.clamp(kMinCols, kMaxCols);
    if (v == cols) return;
    cols = v;
    commit();
  }

  void setTheme(String v) {
    themeMode.value = v;
    _save();
  }
}
