import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
            const Text('Menu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Card2(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: C.primary,
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
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
                title: const Text('Regras pós-uso por tipo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Para onde cada tipo vai depois de usado'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showAppSheet(context, (_) => const RulesSheet()),
              ),
            ),
            _header('Aparência e idioma'),
            const Card2(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: C.primaryDark),
                    title: Text('Tema'),
                    trailing: Text('Azul-acinzentado', style: TextStyle(color: C.text2)),
                  ),
                  ListTile(
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
                      'Neste celular: ${plural(store.live.length, 'peça', 'peças')}, ${plural(store.looks.length, 'look', 'looks')}, '
                      '${plural(store.log.length, 'uso registrado', 'usos registrados')} e ${plural(store.washes.length, 'lavagem', 'lavagens')}.',
                      style: const TextStyle(fontSize: 14, color: C.text2),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy_all_outlined, color: C.primaryDark),
                    title: const Text('Copiar backup (JSON)', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: store.exportJson()));
                      if (context.mounted) toast(context, 'Backup copiado. Cole num e-mail ou nota para guardar.');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined, color: C.primaryDark),
                    title: const Text('Copiar relatório (CSV)', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: store.exportCsv()));
                      if (context.mounted) toast(context, 'Relatório copiado.');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded, color: C.primaryDark),
                    title: const Text('Recriar dados demonstrativos', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Recriar dados demonstrativos?',
                        text: 'Peças, looks e histórico voltam ao exemplo inicial. O que você cadastrou será substituído.',
                        confirmLabel: 'Recriar dados',
                        danger: true,
                      );
                      if (ok) {
                        store.reseed();
                        _name.text = store.profileName;
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFA23E3C)),
                    title: const Text('Apagar todos os dados',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFA23E3C))),
                    onTap: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Apagar todos os dados?',
                        text: 'Peças, fotos, looks e histórico serão removidos deste celular. Essa ação não pode ser desfeita. Copie um backup antes, se quiser.',
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
                      hintText: 'Conte o que funcionou, o que faltou ou um problema que encontrou.',
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
            const SizedBox(height: 24),
            const Center(
              child: Text('Armário Virtual · MVP · funciona offline', style: TextStyle(fontSize: 12, color: C.text2)),
            ),
          ],
        );
      },
    );
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
        subtitle: 'A regra de uma peça, se definida, vale mais que a do tipo.',
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
