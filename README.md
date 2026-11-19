# Armário Virtual

App Android (Flutter) para organizar roupas, montar looks em camadas, registrar usos e controlar lavagens. Funciona offline; os dados ficam no celular.

## Como baixar o APK

1. Abra a aba **Releases** deste repositório (ou **Actions → Compilar APK**).
2. Baixe `armario-virtual.apk` no celular.
3. Abra o arquivo e permita a instalação de apps desta fonte, se o Android pedir.

Cada envio para a branch `main` gera um APK novo automaticamente.

## Estrutura

- `lib/store.dart` — dados, regras de uso, pilha, cesto, lavagem e persistência (JSON local).
- `lib/home.dart` — Início com carrosséis infinitos e camadas.
- `lib/wardrobe.dart` — Guarda-Roupas, detalhe da peça e pop-up de look.
- `lib/piece_form.dart` — cadastro/edição de peça (foto, tipos, cores, tags).
- `lib/tracking.dart` — Rastreio, ranking e calendário de usos.
- `lib/menu.dart` — perfil, regras, backup e feedback.
