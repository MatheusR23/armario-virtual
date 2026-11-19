import 'package:flutter/material.dart';

import 'models.dart';

const Map<String, String> kCats = {
  'cima': 'Parte de cima',
  'baixo': 'Parte de baixo',
  'unica': 'Peças únicas',
  'calcado': 'Calçados',
  'acessorio': 'Acessórios',
  'outros': 'Outros',
};

const List<PieceType> kTypes = [
  PieceType('camisa', 'Camisa', 'cima', 'cesto', 'long'),
  PieceType('camiseta', 'Camiseta', 'cima', 'cesto', 'tee'),
  PieceType('regata', 'Regata', 'cima', 'cesto', 'tank'),
  PieceType('polo', 'Polo', 'cima', 'cesto', 'tee'),
  PieceType('blusa', 'Blusa', 'cima', 'cesto', 'tee'),
  PieceType('casaco', 'Casaco', 'cima', 'guardado', 'long'),
  PieceType('moletom', 'Moletom', 'cima', 'guardado', 'hoodie'),
  PieceType('jaqueta', 'Jaqueta', 'cima', 'guardado', 'long'),
  PieceType('calca', 'Calça', 'baixo', 'cesto', 'pants'),
  PieceType('bermuda', 'Bermuda', 'baixo', 'cesto', 'shorts'),
  PieceType('short', 'Short', 'baixo', 'cesto', 'shorts'),
  PieceType('saia', 'Saia', 'baixo', 'cesto', 'skirt'),
  PieceType('vestido', 'Vestido', 'unica', 'cesto', 'dress'),
  PieceType('macacao', 'Macacão', 'unica', 'cesto', 'dress'),
  PieceType('sapato', 'Sapato', 'calcado', 'guardado', 'shoe'),
  PieceType('tenis', 'Tênis', 'calcado', 'guardado', 'shoe'),
  PieceType('chinelo', 'Chinelo', 'calcado', 'guardado', 'sandal'),
  PieceType('bota', 'Bota', 'calcado', 'guardado', 'boot'),
  PieceType('sandalia', 'Sandália', 'calcado', 'guardado', 'sandal'),
  PieceType('meia', 'Meia', 'acessorio', 'cesto', 'sock'),
  PieceType('bolsa', 'Bolsa', 'acessorio', 'guardado', 'bag'),
  PieceType('bone', 'Boné', 'acessorio', 'guardado', 'cap'),
  PieceType('cinto', 'Cinto', 'acessorio', 'guardado', 'belt'),
  PieceType('relogio', 'Relógio', 'acessorio', 'guardado', 'watch'),
  PieceType('oculos', 'Óculos', 'acessorio', 'guardado', 'glasses'),
  PieceType('acessorios', 'Acessórios', 'acessorio', 'guardado', 'watch'),
  PieceType('outros', 'Outros', 'outros', 'guardado', 'tee'),
];

const Map<String, String> kCatShape = {
  'cima': 'tee',
  'baixo': 'pants',
  'unica': 'dress',
  'calcado': 'shoe',
  'acessorio': 'bag',
  'outros': 'tee',
};

const List<ColorTag> kColors = [
  ColorTag('Preto', 0xFF25292D),
  ColorTag('Branco', 0xFFF5F3EE),
  ColorTag('Cinza', 0xFF9AA3A8),
  ColorTag('Azul', 0xFF26406A),
  ColorTag('Azul-claro', 0xFF8DB2D6),
  ColorTag('Verde', 0xFF4F7A5A),
  ColorTag('Bege', 0xFFD9C4A0),
  ColorTag('Marrom', 0xFF7B5336),
  ColorTag('Vermelho', 0xFFB5473F),
  ColorTag('Rosa', 0xFFE8A6B6),
  ColorTag('Amarelo', 0xFFE3C25A),
];

/// Tons para criar cores novas.
const List<int> kPalette = [
  0xFF1B1F23, 0xFF4A4F55, 0xFFBFC5CA, 0xFFFFFFFF, 0xFF0F2A4A, 0xFF2F5D9E,
  0xFF5FA8D3, 0xFF2A7F7A, 0xFF6B7F3A, 0xFF8DBF6A, 0xFF3E5E2E, 0xFFE9D8A6,
  0xFFC9A26B, 0xFFA0522D, 0xFF5C3A21, 0xFF8E1F2F, 0xFFD94F3D, 0xFFF08A5D,
  0xFFF4C542, 0xFFF7B6C2, 0xFFC86B98, 0xFF6C4BA6, 0xFFB79FE0, 0xFF7FA7C9,
];

class ShapeDef {
  final String d;
  final String d2;
  final int? detail;
  const ShapeDef(this.d, [this.d2 = '', this.detail]);
}

const Map<String, ShapeDef> kShapes = {
  'tee': ShapeDef('M22 8 L12 12 L4 22 L12 30 L16 27 V58 H48 V27 L52 30 L60 22 L52 12 L42 8 C40 13 36 15 32 15 C28 15 24 13 22 8 Z'),
  'tank': ShapeDef('M22 6 H27 C27 13 37 13 37 6 H42 C42 14 46 18 48 22 V58 H16 V22 C18 18 22 14 22 6 Z'),
  'long': ShapeDef('M23 7 L13 11 L6 42 L13 43 L17 26 V58 H47 V26 L51 43 L58 42 L51 11 L41 7 L32 17 Z', 'M31 17 H33 V58 H31 Z', 0x381D2930),
  'hoodie': ShapeDef('M23 9 C23 3 41 3 41 9 L51 12 L58 42 L51 43 L47 28 V58 H17 V28 L13 43 L6 42 L13 12 Z', 'M24 42 H40 L42 51 H22 Z', 0x291D2930),
  'pants': ShapeDef('M18 6 H46 L50 58 H37 L32 22 L27 58 H14 Z'),
  'shorts': ShapeDef('M16 14 H48 L52 46 L36 48 L32 28 L28 48 L12 46 Z'),
  'skirt': ShapeDef('M20 12 H44 L54 54 H10 Z'),
  'dress': ShapeDef('M24 6 H28 C29 10 35 10 36 6 H40 L42 22 L38 26 L52 58 H12 L26 26 L22 22 Z'),
  'shoe': ShapeDef('M6 40 L8 26 L20 28 L28 20 L38 22 L42 32 L56 37 C60 39 60 46 58 48 H8 C6 46 6 43 6 40 Z', 'M6 43 H59.6 C59.6 45 59 47 58 48 H8 C6.6 47 6 45 6 43 Z', 0x331D2930),
  'boot': ShapeDef('M18 8 H34 V36 L52 42 C56 43 58 46 58 50 V54 H18 Z', 'M18 50 H58 V54 H18 Z', 0x381D2930),
  'sandal': ShapeDef('M8 42 H56 V50 H8 Z M15 42 L27 28 H33 L22 42 Z M33 42 L43 28 H49 L40 42 Z'),
  'sock': ShapeDef('M22 6 H38 V36 C38 40 40 42 46 44 C52 46 54 50 52 54 C50 58 46 58 40 56 L28 52 C24 51 22 48 22 44 Z'),
  'bag': ShapeDef('M14 24 H50 L54 58 H10 Z M24 24 V18 C24 9 40 9 40 18 V24 H36 V18 C36 13 28 13 28 18 V24 Z'),
  'cap': ShapeDef('M10 40 C10 22 20 14 32 14 C44 14 54 22 54 36 L60 40 C60 44 56 44 54 44 H12 C10 44 10 42 10 40 Z'),
  'belt': ShapeDef('M4 26 H60 V38 H4 Z', 'M42 23 H51 V41 H42 Z', 0xFFD6B668),
  'watch': ShapeDef('M24 4 H40 V20 H24 Z M24 44 H40 V60 H24 Z M16 32 A16 16 0 1 0 48 32 A16 16 0 1 0 16 32 Z', 'M21 32 A11 11 0 1 0 43 32 A11 11 0 1 0 21 32 Z', 0xFFF7F9FA),
  'glasses': ShapeDef('M6 26 H28 V33 C28 39 24 42 18 42 C10 42 6 38 6 32 Z M36 26 H58 V32 C58 38 54 42 46 42 C40 42 36 39 36 33 Z M28 27 H36 V31 H28 Z'),
};

const String kDots =
    'M23.6 34 A2.4 2.4 0 1 0 28.4 34 A2.4 2.4 0 1 0 23.6 34 Z M34.6 42 A2.4 2.4 0 1 0 39.4 42 A2.4 2.4 0 1 0 34.6 42 Z M29 27 A2 2 0 1 0 33 27 A2 2 0 1 0 29 27 Z M39 33 A2 2 0 1 0 43 33 A2 2 0 1 0 39 33 Z M20 47 A2 2 0 1 0 24 47 A2 2 0 1 0 20 47 Z M38.8 52 A2.2 2.2 0 1 0 43.2 52 A2.2 2.2 0 1 0 38.8 52 Z';

class StatusMeta {
  final String label;
  final Color bg;
  final Color fg;
  const StatusMeta(this.label, this.bg, this.fg);
}

StatusMeta statusMeta(String s) {
  switch (s) {
    case 'emUso':
      return const StatusMeta('Em uso', Color(0xFFDCE9F2), Color(0xFF2B5674));
    case 'cesto':
      return const StatusMeta('No cesto', Color(0xFFF7E9D2), Color(0xFF7A4F0E));
    default:
      return const StatusMeta('Guardado', Color(0xFFDDF0E6), Color(0xFF1F5C42));
  }
}

const List<String> kOccasions = ['Dia a dia', 'Trabalho', 'Lazer', 'Passeio', 'Festa'];

// ---------- datas ----------
const List<String> kMes = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
const List<String> kMesF = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
];
const List<String> kDiaSemana = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

int dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
DateTime dateOf(int day) => DateTime.fromMillisecondsSinceEpoch(day * 86400000, isUtc: true);
int todayDay() => dayOf(DateTime.now());

String fmtDay(int day) {
  final d = dateOf(day);
  return '${d.day} ${kMes[d.month - 1]}';
}

String relDay(int? day) {
  if (day == null) return 'Nunca';
  final k = todayDay() - day;
  if (k <= 0) return 'Hoje';
  if (k == 1) return 'Ontem';
  if (k < 7) return 'Há $k dias';
  return fmtDay(day);
}

String weekdayShort(int day) => kDiaSemana[dateOf(day).weekday % 7];

String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

String joinNames(List<String> names) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
}

String norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().toLowerCase().trim();
}
