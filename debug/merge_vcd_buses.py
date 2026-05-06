"""
merge_vcd_buses.py
Convierte un VCD de ModelSim con bits sueltos "signal [N]" en vectores agrupados.
Uso: python merge_vcd_buses.py input.vcd output.vcd
"""
import sys
import re
from collections import defaultdict

def merge_buses(in_path, out_path):
    with open(in_path, 'r') as f:
        lines = f.readlines()

    # --- Separar cabecera del cuerpo ---
    header_lines = []
    body_lines = []
    in_body = False
    for line in lines:
        if not in_body and re.match(r'\s*#\d', line):
            in_body = True
        if in_body:
            body_lines.append(line.rstrip())
        else:
            header_lines.append(line.rstrip())

    # --- Parsear variables bit a bit: $var wire 1 ID signal [N] $end ---
    bit_pattern = re.compile(r'\$var\s+wire\s+1\s+(\S+)\s+(\w+)\s+\[(\d+)\]\s+\$end')
    buses = defaultdict(dict)   # nombre -> {bit: id}
    id_to_info = {}             # id -> (nombre, bit)

    for line in header_lines:
        m = bit_pattern.search(line)
        if m:
            vid, name, bit = m.group(1), m.group(2), int(m.group(3))
            buses[name][bit] = vid
            id_to_info[vid] = (name, bit)

    # ID nuevo por bus: usar nombre con prefijo corto
    bus_new_id = {}
    for name in buses:
        bus_new_id[name] = 'W' + name[:6]  # max 7 chars

    # --- Nueva cabecera: reemplazar bits sueltos por vectores ---
    new_header = []
    written = set()
    for line in header_lines:
        m = bit_pattern.search(line)
        if m:
            name = m.group(2)
            if name not in written:
                width = len(buses[name])
                new_header.append(f'$var wire {width} {bus_new_id[name]} {name} $end')
                written.add(name)
            # bits sueltos: omitir
        else:
            new_header.append(line)

    # --- Estado actual de cada bus (inicializado a 'x') ---
    bus_state = {}
    for name, bits in buses.items():
        width = len(bits)
        bus_state[name] = ['x'] * width  # índice = número de bit

    # --- Procesar cuerpo agrupando cambios por timestamp ---
    new_body = []
    pending_time = None
    pending_changes = defaultdict(dict)  # nombre -> {bit: valor}

    def flush(t, changes):
        out = []
        if t is not None:
            out.append(t)
        for nm, bit_vals in changes.items():
            for b, v in bit_vals.items():
                bus_state[nm][b] = v
            width = len(buses[nm])
            vec = ''.join(bus_state[nm][b] for b in range(width - 1, -1, -1))
            out.append(f'b{vec} {bus_new_id[nm]}')
        return out

    for line in body_lines:
        if re.match(r'\s*#\d', line):
            if pending_time is not None or pending_changes:
                new_body.extend(flush(pending_time, pending_changes))
            pending_time = line.strip()
            pending_changes = defaultdict(dict)
        elif re.match(r'^[01xzXZ]\S+', line):
            val = line[0].lower()
            vid = line[1:].strip()
            if vid in id_to_info:
                name, bit = id_to_info[vid]
                pending_changes[name][bit] = val
            else:
                # señal no agrupada: volcar timestamp pendiente y escribir tal cual
                if pending_time is not None or pending_changes:
                    new_body.extend(flush(pending_time, pending_changes))
                    pending_time = None
                    pending_changes = defaultdict(dict)
                new_body.append(line)
        else:
            if pending_time is not None or pending_changes:
                new_body.extend(flush(pending_time, pending_changes))
                pending_time = None
                pending_changes = defaultdict(dict)
            new_body.append(line)

    if pending_time is not None or pending_changes:
        new_body.extend(flush(pending_time, pending_changes))

    with open(out_path, 'w') as f:
        f.write('\n'.join(new_header + new_body) + '\n')

    print(f'Generado: {out_path}')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Uso: python merge_vcd_buses.py input.vcd output.vcd')
        sys.exit(1)
    merge_buses(sys.argv[1], sys.argv[2])
