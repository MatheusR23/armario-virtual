class ColorTag {
  final String name;
  final int hex;
  const ColorTag(this.name, this.hex);

  Map<String, dynamic> toJson() => {'name': name, 'hex': hex};
  factory ColorTag.fromJson(Map<String, dynamic> j) =>
      ColorTag(j['name'] as String, (j['hex'] as num).toInt());
}

class PieceType {
  final String id;
  final String name;
  final String cat;
  final String rule;
  final String shape;
  final bool custom;
  const PieceType(this.id, this.name, this.cat, this.rule, this.shape, {this.custom = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'cat': cat, 'rule': rule, 'shape': shape, 'custom': custom};
  factory PieceType.fromJson(Map<String, dynamic> j) => PieceType(
        j['id'] as String,
        j['name'] as String,
        j['cat'] as String,
        j['rule'] as String,
        j['shape'] as String,
        custom: (j['custom'] as bool?) ?? true,
      );
}

class Piece {
  String id;
  String name;
  String typeId;
  List<ColorTag> colors;
  List<String> tags;
  bool patterned;
  String status; // guardado | emUso | cesto
  int total;
  int since;
  int? lastUse;
  int? lastWash;
  String? rule;
  String? photoPath;
  String? shape;
  bool deleted;

  Piece({
    required this.id,
    required this.name,
    required this.typeId,
    required this.colors,
    List<String>? tags,
    this.patterned = false,
    this.status = 'guardado',
    this.total = 0,
    this.since = 0,
    this.lastUse,
    this.lastWash,
    this.rule,
    this.photoPath,
    this.shape,
    this.deleted = false,
  }) : tags = tags ?? <String>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'typeId': typeId,
        'colors': colors.map((c) => c.toJson()).toList(),
        'tags': tags,
        'patterned': patterned,
        'status': status,
        'total': total,
        'since': since,
        'lastUse': lastUse,
        'lastWash': lastWash,
        'rule': rule,
        'photoPath': photoPath,
        'shape': shape,
        'deleted': deleted,
      };

  factory Piece.fromJson(Map<String, dynamic> j) => Piece(
        id: j['id'] as String,
        name: j['name'] as String,
        typeId: j['typeId'] as String,
        colors: ((j['colors'] as List?) ?? const [])
            .map((e) => ColorTag.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        tags: ((j['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
        patterned: (j['patterned'] as bool?) ?? false,
        status: (j['status'] as String?) ?? 'guardado',
        total: (j['total'] as num?)?.toInt() ?? 0,
        since: (j['since'] as num?)?.toInt() ?? 0,
        lastUse: (j['lastUse'] as num?)?.toInt(),
        lastWash: (j['lastWash'] as num?)?.toInt(),
        rule: j['rule'] as String?,
        photoPath: j['photoPath'] as String?,
        shape: j['shape'] as String?,
        deleted: (j['deleted'] as bool?) ?? false,
      );
}

class Look {
  String id;
  String name;
  String occasion;
  bool fav;
  List<String> cima;
  List<String> baixo;
  String? calcado;
  List<String> acess;
  int uses;

  /// Cores principais escolhidas para o look (vazio = usa as cores das peças).
  List<ColorTag> colors;
  String? photoPath;

  Look({
    required this.id,
    required this.name,
    required this.occasion,
    this.fav = false,
    List<String>? cima,
    List<String>? baixo,
    this.calcado,
    List<String>? acess,
    this.uses = 0,
    List<ColorTag>? colors,
    this.photoPath,
  })  : cima = cima ?? <String>[],
        baixo = baixo ?? <String>[],
        acess = acess ?? <String>[],
        colors = colors ?? <ColorTag>[];

  List<String> pieceIds() {
    final out = <String>[];
    for (final id in [...cima, ...baixo, if (calcado != null) calcado!, ...acess]) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'occasion': occasion,
        'fav': fav,
        'cima': cima,
        'baixo': baixo,
        'calcado': calcado,
        'acess': acess,
        'uses': uses,
        'colors': colors.map((c) => c.toJson()).toList(),
        'photoPath': photoPath,
      };

  factory Look.fromJson(Map<String, dynamic> j) {
    List<String> ls(String k) => ((j[k] as List?) ?? const []).map((e) => e.toString()).toList();
    return Look(
      id: j['id'] as String,
      name: j['name'] as String,
      occasion: (j['occasion'] as String?) ?? '',
      fav: (j['fav'] as bool?) ?? false,
      cima: ls('cima'),
      baixo: ls('baixo'),
      calcado: j['calcado'] as String?,
      acess: ls('acess'),
      uses: (j['uses'] as num?)?.toInt() ?? 0,
      colors: ((j['colors'] as List?) ?? const [])
          .map((e) => ColorTag.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      photoPath: j['photoPath'] as String?,
    );
  }
}

class UseLog {
  final String itemId;
  final int day;
  const UseLog(this.itemId, this.day);
  Map<String, dynamic> toJson() => {'itemId': itemId, 'day': day};
  factory UseLog.fromJson(Map<String, dynamic> j) =>
      UseLog(j['itemId'] as String, (j['day'] as num).toInt());
}

class LookLog {
  final String lookId;
  final int day;
  const LookLog(this.lookId, this.day);
  Map<String, dynamic> toJson() => {'lookId': lookId, 'day': day};
  factory LookLog.fromJson(Map<String, dynamic> j) =>
      LookLog(j['lookId'] as String, (j['day'] as num).toInt());
}

class Wash {
  final String itemId;
  final int day;
  final int uses;
  const Wash(this.itemId, this.day, this.uses);
  Map<String, dynamic> toJson() => {'itemId': itemId, 'day': day, 'uses': uses};
  factory Wash.fromJson(Map<String, dynamic> j) =>
      Wash(j['itemId'] as String, (j['day'] as num).toInt(), (j['uses'] as num).toInt());
}

class Removal {
  final String itemId;
  final String reason;
  final int day;
  const Removal(this.itemId, this.reason, this.day);
  Map<String, dynamic> toJson() => {'itemId': itemId, 'reason': reason, 'day': day};
  factory Removal.fromJson(Map<String, dynamic> j) => Removal(
      j['itemId'] as String, (j['reason'] as String?) ?? '', (j['day'] as num).toInt());
}
