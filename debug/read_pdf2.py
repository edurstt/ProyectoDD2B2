import pypdf

reader = pypdf.PdfReader(r'C:\Users\Eduardo Muñoz\Documents\DD2\ProyectoDD2\Especificacion_CALCULADORA_2026_ordpdf.pdf')
for i, page in enumerate(reader.pages):
    print(f"\n===== PÁGINA {i+1} =====")
    print(page.extract_text())
