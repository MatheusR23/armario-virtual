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
open(p, 'w', encoding='utf-8').write(s)
print('AndroidManifest ajustado')
