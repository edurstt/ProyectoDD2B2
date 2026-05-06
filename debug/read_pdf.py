import re

with open(r'C:\Users\Eduardo Muñoz\Documents\DD2\ProyectoDD2\Especificacion_CALCULADORA_2026_ordpdf.pdf', 'rb') as f:
    raw = f.read()

text = raw.decode('latin-1', errors='replace')
words = re.findall(r'[A-Za-z\u00C0-\u00FF\s\.\,\:\-\(\)\/\%\+\=\d]{20,}', text)
for w in words[:200]:
    w2 = w.strip()
    if len(w2) > 20:
        print(w2)
