import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';

/// Backup completo em .zip: `armario_virtual.json` com os dados e a pasta
/// `fotos/` com as fotos das peças. No JSON, `photoPath` aponta para o arquivo
/// dentro do zip (ex.: `fotos/3_foto_123.jpg`).
const _jsonEntry = 'armario_virtual.json';

class BackupInfo {
  final int pieces;
  final int looks;
  final int uses;
  final int photos;
  const BackupInfo(this.pieces, this.looks, this.uses, this.photos);
}

String _two(int n) => n.toString().padLeft(2, '0');

String _stamp() {
  final d = DateTime.now();
  return '${d.year}-${_two(d.month)}-${_two(d.day)}';
}

String backupFileName() => 'armario-virtual-backup-${_stamp()}.zip';

String _baseName(String path) => path.split(RegExp(r'[\\/]')).last;

/// Monta o .zip do backup com os dados atuais e as fotos.
Future<(Uint8List, BackupInfo)> buildBackup() async {
  final data = store.snapshot();
  final archive = Archive();
  final entries = <String, String>{}; // caminho no celular -> nome no zip
  final withPhotos = [
    ...(data['items'] as List).cast<Map<String, dynamic>>(),
    ...(data['looks'] as List).cast<Map<String, dynamic>>(),
  ];
  for (final it in withPhotos) {
    final path = it['photoPath'] as String?;
    if (path == null) continue;
    final known = entries[path];
    if (known != null) {
      it['photoPath'] = known;
      continue;
    }
    final f = File(path);
    if (!await f.exists()) {
      it['photoPath'] = null;
      continue;
    }
    final bytes = await f.readAsBytes();
    final name = 'fotos/${entries.length + 1}_${_baseName(path)}';
    entries[path] = name;
    // Fotos já são JPEG comprimido; guardar sem recomprimir é mais rápido.
    archive.addFile(ArchiveFile.noCompress(name, bytes.length, bytes));
    it['photoPath'] = name;
  }
  data['app'] = 'armario-virtual';
  data['exportedAt'] = DateTime.now().toIso8601String();
  archive.addFile(ArchiveFile.string(_jsonEntry, const JsonEncoder.withIndent('  ').convert(data)));
  final zip = ZipEncoder().encodeBytes(archive);
  return (
    zip,
    BackupInfo(store.live.length, store.looks.length, store.log.length, entries.length),
  );
}

/// Abre o seletor do Android para escolher onde salvar o backup.
/// Retorna `false` se a pessoa cancelar.
Future<bool> saveBackupToFile() async {
  final (bytes, _) = await buildBackup();
  final uri = await FilePicker.saveFile(
    fileName: backupFileName(),
    bytes: bytes,
    mimeType: 'application/zip',
    dialogTitle: 'Salvar backup',
  );
  return uri != null;
}

Future<File> _tempFile(String name, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes, flush: true);
  return f;
}

/// Abre o compartilhamento do Android (e-mail, WhatsApp, Drive…) com o backup.
Future<void> shareBackup() async {
  final (bytes, info) = await buildBackup();
  final f = await _tempFile(backupFileName(), bytes);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(f.path, mimeType: 'application/zip')],
    subject: 'Backup — Armário Virtual (${_stamp()})',
    text: 'Backup do Armário Virtual: ${info.pieces} peças, ${info.looks} looks e ${info.photos} fotos. '
        'Para restaurar, abra o app em Menu > Restaurar backup e escolha este arquivo.',
  ));
}

/// Compartilha o relatório de peças em CSV.
Future<void> shareCsv() async {
  // BOM para o Excel reconhecer os acentos.
  final bytes = utf8.encode('﻿${store.exportCsv()}');
  final f = await _tempFile('armario-virtual-relatorio-${_stamp()}.csv', bytes);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(f.path, mimeType: 'text/csv')],
    subject: 'Relatório — Armário Virtual (${_stamp()})',
  ));
}

/// Erro com mensagem pronta para mostrar na tela.
class BackupError implements Exception {
  final String message;
  const BackupError(this.message);
  @override
  String toString() => message;
}

Map<String, dynamic> _decodeJson(List<int> bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  final Object? j;
  try {
    j = jsonDecode(text);
  } on FormatException {
    throw const BackupError('O arquivo não é um backup do Armário Virtual.');
  }
  if (j is! Map || j['items'] is! List) {
    throw const BackupError('O arquivo não é um backup do Armário Virtual.');
  }
  final v = (j['v'] as num?)?.toInt() ?? 1;
  if (v > 1) {
    throw const BackupError('Este backup foi feito numa versão mais nova do app. Atualize o app e tente de novo.');
  }
  return Map<String, dynamic>.from(j);
}

/// Abre o seletor de arquivos e lê o backup escolhido, sem aplicar ainda.
/// Retorna `null` se a pessoa cancelar.
Future<PendingBackup?> pickBackup() async {
  final picked = await FilePicker.pickFile(type: FileType.any, dialogTitle: 'Escolher backup');
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return PendingBackup.parse(bytes);
}

/// Backup lido e validado, pronto para substituir os dados do celular.
class PendingBackup {
  final Map<String, dynamic> data;
  final Archive? archive;
  PendingBackup._(this.data, this.archive);

  factory PendingBackup.parse(Uint8List bytes) {
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    if (!isZip) {
      // Backups antigos eram só o JSON copiado para a área de transferência.
      return PendingBackup._(_decodeJson(bytes), null);
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupError('Não foi possível abrir o arquivo. Ele pode estar corrompido.');
    }
    final jf = archive.findFile(_jsonEntry);
    final jb = jf?.readBytes();
    if (jb == null) {
      throw const BackupError('O arquivo não é um backup do Armário Virtual.');
    }
    return PendingBackup._(_decodeJson(jb), archive);
  }

  List<Map> get _items => (data['items'] as List).whereType<Map>().toList();
  List<Map> get _looks => ((data['looks'] as List?) ?? const []).whereType<Map>().toList();
  int get pieces => _items.where((e) => e['deleted'] != true).length;
  int get looks => _looks.length;
  int get uses => (data['log'] as List?)?.length ?? 0;
  int get photos => [..._items, ..._looks].where((e) => e['photoPath'] != null).length;

  /// Extrai as fotos para a pasta do app e substitui os dados atuais.
  Future<BackupInfo> apply() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final written = <String, String>{};
    var restored = 0;
    var i = 0;
    for (final it in [..._items, ..._looks]) {
      final path = it['photoPath'];
      if (path is! String) continue;
      String? dest;
      final a = archive;
      if (a != null && path.startsWith('fotos/')) {
        dest = written[path];
        if (dest == null) {
          final bytes = a.findFile(path)?.readBytes();
          if (bytes != null) {
            i++;
            dest = '${dir.path}/foto_${ts}_$i.jpg';
            await File(dest).writeAsBytes(bytes, flush: true);
            written[path] = dest;
          }
        }
      } else if (await File(path).exists()) {
        // JSON antigo: a foto continua no mesmo lugar deste celular.
        dest = path;
      }
      it['photoPath'] = dest;
      if (dest != null) restored++;
    }
    store.restore(data);
    return BackupInfo(store.live.length, store.looks.length, store.log.length, restored);
  }
}
