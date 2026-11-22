"""Ajusta o projeto Android gerado pelo `flutter create`: nome do app e consulta de e-mail."""
import re

p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
s = re.sub(r'android:label="[^"]*"', 'android:label="Armário Virtual"', s, count=1)
q = ('<intent><action android:name="android.intent.action.SENDTO"/>'
     '<data android:scheme="mailto"/></intent>')
if 'android:scheme="mailto"' not in s:
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>' + q, 1)
    else:
        s = s.replace('</manifest>', '<queries>' + q + '</queries>\n</manifest>', 1)
# Internet para o clima (o manifesto principal gerado não pede).
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
open(p, 'w', encoding='utf-8').write(s)
print('AndroidManifest ajustado')

# O "lint vital" do Android trava ao analisar o plugin image_picker (bug do próprio lint).
# Ele não afeta o app; desligamos só essa verificação na compilação de release.
import os
for root in ('android/build.gradle.kts', 'android/build.gradle'):
    if os.path.exists(root):
        g = open(root, encoding='utf-8').read()
        if 'lintVital' not in g:
            g += '\nsubprojects {\n    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }\n}\n'
            open(root, 'w', encoding='utf-8').write(g)
            print('Lint vital desligado em', root)
        break

# Assinatura fixa: se o CI colocou a chave em android/app/release.jks, a compilação de
# release usa essa chave (senhas vêm de variáveis de ambiente). Sem a chave, continua a de
# debug — útil para rodar localmente.
if os.path.exists('android/app/release.jks'):
    kts = 'android/app/build.gradle.kts'
    groovy = 'android/app/build.gradle'
    if os.path.exists(kts):
        g = open(kts, encoding='utf-8').read()
        bloco = (
            '    signingConfigs {\n'
            '        create("release") {\n'
            '            storeFile = file("release.jks")\n'
            '            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")\n'
            '            keyAlias = System.getenv("ANDROID_KEY_ALIAS")\n'
            '            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")\n'
            '        }\n'
            '    }\n\n'
        )
        antigo = 'signingConfig = signingConfigs.getByName("debug")'
        novo = 'signingConfig = signingConfigs.getByName("release")'
        destino = kts
    elif os.path.exists(groovy):
        g = open(groovy, encoding='utf-8').read()
        bloco = (
            '    signingConfigs {\n'
            '        release {\n'
            '            storeFile file("release.jks")\n'
            '            storePassword System.getenv("ANDROID_KEYSTORE_PASSWORD")\n'
            '            keyAlias System.getenv("ANDROID_KEY_ALIAS")\n'
            '            keyPassword System.getenv("ANDROID_KEY_PASSWORD")\n'
            '        }\n'
            '    }\n\n'
        )
        antigo = 'signingConfig signingConfigs.debug'
        novo = 'signingConfig signingConfigs.release'
        destino = groovy
    else:
        raise SystemExit('build.gradle do app não encontrado')
    if antigo not in g or '    buildTypes {' not in g:
        raise SystemExit('Não achei onde configurar a assinatura em ' + destino)
    g = g.replace('    buildTypes {', bloco + '    buildTypes {', 1).replace(antigo, novo)
    open(destino, 'w', encoding='utf-8').write(g)
    print('Assinatura de release configurada em', destino)
else:
    print('Sem android/app/release.jks: release assinado com a chave de debug')
