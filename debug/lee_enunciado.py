import pdfplumber
pdf = pdfplumber.open(r'c:\Users\Eduardo Muñoz\Documents\DD2\ProyectoDD2\Especificacion_CALCULADORA_2026_ordpdf.pdf')
for i, p in enumerate(pdf.pages):
    t = p.extract_text()
    if t:
        print(f'=== Pagina {i+1} ===')
        print(t)
pdf.close()
