# Armário Virtual — contexto para o Claude Code

App Android em Flutter para organizar roupas, montar looks em camadas, registrar usos e controlar lavagens. Funciona offline; os dados ficam no celular. Interface e textos em **português do Brasil**.

## Como o APK é gerado

- Não há pasta `android/` versionada. O workflow `.github/workflows/build-apk.yml` roda `flutter create . --platforms=android`, aplica `.github/scripts/patch_android.py` (nome do app, consulta `mailto`, desliga o `lintVital` que trava no plugin image_picker) e faz `flutter build apk --release`.
- Cada push na `main` publica uma versão em **Releases** (`v1.0.<run>`) com `armario-virtual.apk`.
- Se a compilação falhar, o log vai para a branch `ci-logs` (`ci/last-build.log`, `ci/analyze.log`).
- Para rodar localmente: `flutter create . --platforms=android --project-name armario_virtual`, `python .github/scripts/patch_android.py`, `flutter run`.
- Pendente: assinatura fixa. Hoje o APK sai com chave de debug gerada a cada build, então atualizar exige desinstalar (e perder os dados).

## Estrutura (`lib/`)

| Arquivo | Conteúdo |
| --- | --- |
| `models.dart` | Piece, PieceType, ColorTag, Look, UseLog, LookLog, Wash, Removal (com JSON) |
| `catalog.dart` | Tipos padrão, cores, paleta, desenhos das peças (paths SVG 64×64), datas e textos |
| `store.dart` | `Store` (ChangeNotifier global `store`), persistência em JSON no diretório do app, dados de exemplo, seleção do Início, regras de uso/pilha/cesto/lavagem |
| `theme.dart` | Cores (`C`) e tema Material 3 |
| `widgets.dart` | PieceArt (foto ou desenho), SegTabs, Pill, RequiredField, SheetFrame, toast, confirmDialog |
| `home.dart` | Início: carrosséis infinitos (cima, baixo, calçados) com camadas, galeria de acessórios, Pilha/Cesto |
| `sheets.dart` | Abas inferiores: Pilha, Cesto, Confirmar uso, Criar look, Ver todas, GalleryGrid |
| `wardrobe.dart` | Guarda-Roupas, detalhe da peça, pop-up do look |
| `piece_form.dart` | Cadastro/edição: foto, tipos (e novos tipos), várias cores (e novas), tags, estampa, status |
| `tracking.dart` | Rastreio: períodos e intervalo personalizado, ranking, calendário por peça ou look |
| `menu.dart` | Perfil, regras pós-uso, backup (área de transferência), dados, feedback por e-mail |

Navegação: `tabIndex` (ValueNotifier) com 4 abas — Guarda-Roupas, Início (padrão), Rastreio, Menu. Barra inferior escura, só ícones.

## Regras de negócio principais

- Status: `guardado` → `emUso` (Pilha) → `cesto` → lavagem → `guardado`.
- Uma peça não pode ter dois usos no mesmo dia.
- Regra pós-uso: a da peça vale mais que a do tipo; tipos de cima/baixo/peça única vão ao cesto, calçados e acessórios são guardados.
- Peças únicas (vestido, macacão) aparecem em cima e embaixo; selecionar numa seção seleciona na outra.
- Até 3 camadas em cima e embaixo; a camada 1 é a interna.

## Decisões e diferenças em relação ao prompt original

- Persistência em arquivo JSON + `ChangeNotifier` em vez de Drift/SQLite + Riverpod + GoRouter (sem geração de código). Migrar é possível sem mudar as telas.
- Clima ainda não implementado.
- Backup/CSV são copiados para a área de transferência.

## Diretrizes de interface (resumo)

Grade de 8pt; texto base 16px; um único CTA primário por tela; toque mínimo de 44px; contraste ≥ 4.5:1; estados hover/pressed/focus/disabled/loading; janelas que arrastam para baixo não têm "X"; campos obrigatórios mostram alerta ao sair vazios e nunca são preenchidos automaticamente. Cores: primária `#516B7A`, escura `#344955`, clara `#DCE7ED`, fundo `#F7F9FA`, texto `#1D2930`, texto secundário `#5F6B72`.

## Referências

- Protótipo interativo (design): https://claude.ai/artifact/RaoRQY7cC4DyK37gEjbi1j
- Notas do projeto: cofre Obsidian, pasta "Armário Virtual" (Prompt de Desenvolvimento e Diretrizes de UI e UX).
