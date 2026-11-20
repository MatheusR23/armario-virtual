import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'backup.dart';
import 'catalog.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final TextEditingController _name = TextEditingController(text: store.profileName);
  final _feedback = TextEditingController();
  String? _busy;

  @override
  void dispose() {
    _name.dispose();
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final subject = Uri.encodeComponent('Feedback — Armário Virtual');
    final body = Uri.encodeComponent(_feedback.text);
    final uri = Uri.parse('mailto:matheus.raraujo@hotmail.com?subject=$subject&body=$body');
    bool ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) toast(context, 'Não foi possível abrir o app de e-mail.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final initial = store.profileName.trim().isEmpty ? '' : store.profileName.trim()[0].toUpperCase();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          children: [
            const Text('Configurações', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Card2(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: C.primary,
                    child: Text(initial, style: const TextStyle(color: C.onPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RequiredField(
                      controller: _name,
                      label: 'Nome',
                      message: 'Informe seu nome.',
                      onChanged: store.setName,
                    ),
                  ),
                ],
              ),
            ),
            _header('Guarda-roupas'),
            Card2(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.shopping_basket_outlined, color: C.primaryDark),
                title: const Text('Regras pós-uso', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showAppSheet(context, (_) => const RulesSheet()),
              ),
            ),
            _header('Aparência e idioma'),
            Card2(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ListTile(
                    leading: Icon(Icons.dark_mode_outlined, color: C.primaryDark),
                    title: Text('Tema'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ValueListenableBuilder<String>(
                      valueListenable: themeMode,
                      builder: (context, mode, _) => SegTabs<String>(
                        options: const [('sistema', 'Sistema'), ('claro', 'Claro'), ('escuro', 'Escuro')],
                        value: mode,
                        onChanged: store.setTheme,
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.language_rounded, color: C.primaryDark),
                    title: Text('Idioma'),
                    trailing: Text('Português (Brasil)', style: TextStyle(color: C.text2)),
                  ),
                ],
              ),
            ),
            _header('Dados locais'),
            Card2(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${plural(store.live.length, 'peça', 'peças')} · ${plural(store.looks.length, 'look', 'looks')} · '
                      '${plural(store.log.length, 'uso', 'usos')}',
                      style: const TextStyle(fontSize: 14, color: C.text2),
                    ),
                  ),
                  _action(
                    id: 'save',
                    icon: Icons.save_alt_rounded,
                    title: 'Salvar backup',
                    subtitle: 'Dados e fotos (.zip)',
                    run: () async {
                      final ok = await saveBackupToFile();
                      if (ok && mounted) toast(this.context, 'Backup salvo.');
                    },
                  ),
                  _action(
                    id: 'share',
                    icon: Icons.ios_share_rounded,
                    title: 'Enviar backup',
                    subtitle: 'E-mail, WhatsApp, Drive…',
                    run: shareBackup,
                  ),
                  _action(
                    id: 'restore',
                    icon: Icons.settings_backup_restore_rounded,
                    title: 'Restaurar backup',
                    subtitle: 'Substitui os dados atuais',
                    run: _restore,
                  ),
                  _action(
                    id: 'csv',
                    icon: Icons.table_chart_outlined,
                    title: 'Enviar relatório',
                    subtitle: 'Planilha (.csv)',
                    run: shareCsv,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: C.danger),
                    title: const Text('Apagar todos os dados',
                        style: TextStyle(fontWeight: FontWeight.w600, color: C.danger)),
                    onTap: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Apagar todos os dados?',
                        text: 'Não é possível desfazer.',
                        confirmLabel: 'Apagar tudo',
                        danger: true,
                      );
                      if (ok) store.wipe();
                    },
                  ),
                ],
              ),
            ),
            _header('Central de feedback'),
            Card2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _feedback,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Sua mensagem',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sendFeedback,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Enviar por e-mail'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Item de backup com estado de carregamento; só uma ação roda por vez.
  Widget _action({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() run,
  }) {
    final busy = _busy == id;
    return ListTile(
      enabled: _busy == null,
      leading: busy
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Icon(icon, color: C.primaryDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: () async {
        setState(() => _busy = id);
        try {
          await run();
        } on BackupError catch (e) {
          if (mounted) toast(context, e.message);
        } catch (e) {
          debugPrint('Erro no backup: $e');
          if (mounted) toast(context, 'Não foi possível concluir. Tente de novo.');
        } finally {
          if (mounted) setState(() => _busy = null);
        }
      },
    );
  }

  Future<void> _restore() async {
    final pending = await pickBackup();
    if (pending == null || !mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Restaurar backup?',
      text: '${plural(pending.pieces, 'peça', 'peças')} · ${plural(pending.looks, 'look', 'looks')} · '
          '${plural(pending.uses, 'uso', 'usos')} · ${plural(pending.photos, 'foto', 'fotos')}\n\n'
          'Os dados atuais serão substituídos.',
      confirmLabel: 'Restaurar',
      danger: true,
    );
    if (!ok) return;
    final info = await pending.apply();
    _name.text = store.profileName;
    if (mounted) {
      toast(context, 'Backup restaurado.');
    }
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text2, letterSpacing: 0.6)),
      );
}

class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SheetFrame(
        title: 'Regras pós-uso',
        child: Column(
          children: [
            for (final t in store.allTypes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(kCats[t.cat] ?? '', style: const TextStyle(fontSize: 12, color: C.text2)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: SegTabs<String>(
                        fontSize: 13,
                        options: const [('cesto', 'Cesto'), ('guardado', 'Guardado')],
                        value: store.typeRule(t.id),
                        onChanged: (v) => store.setTypeRule(t.id, v),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
