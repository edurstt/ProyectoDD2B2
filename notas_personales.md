# Notas personales — DD2 Calculadora VHDL
> Este fichero NO se entrega. Es solo para entender el proyecto.

---

## Estructura general del sistema

```
teclado físico (4×4)
    └─► interfaz_teclado
            ├─ clk_div  (genera tic cada 5 ms)
            └─ ctrl_tec (escaneo + antirebote + detección pulsación)
                    │ tecla[3:0], tecla_pulsada
                    ▼
              controlador  (FSM principal)
              ├─ guarda operando 1 (BCD, hasta 3 dígitos + signo)
              ├─ guarda operando 2
              ├─ elige operación (A=suma, D=resta, E=mult)
              └─ lanza cálculo cuando se pulsa B
                    │ op1_bcd, op2_bcd, op_sel, start_bcd
                    ▼
         bcd_to_bin × 2  (combinacional, BCD → binario complemento a 2)
                    │ op1[10:0], op2[10:0]
                    ▼
                  alu  (suma / resta / multiplicación con signo)
                    │ res[19:0] magnitud, res_sgn signo
                    ▼
             bin_to_bcd  (secuencial, 20 ciclos, binario → 6 dígitos BCD)
                    │ bcd[23:0], done
                    ▼
               displays  (mux 8 displays × 7 segmentos, 125 Hz)
```

---

## Por qué señales y no variables

### La diferencia real

```vhdl
-- CON SEÑALES (lo correcto en hardware)
process(clk)
begin
    if clk'event and clk='1' then
        a <= '1';    -- a todavía vale '0' aquí dentro
        b <= a;      -- b recibe el valor ANTIGUO de a (el de antes del flanco)
        c <= b;      -- c recibe el valor ANTIGUO de b
    end if;
end process;
-- Resultado: a, b, c actualizan a la vez al terminar el ciclo
-- → esto es un shift register de 3 etapas, exactamente como el hardware
```

```vhdl
-- CON VARIABLES (comportamiento software)
process(clk)
    variable a, b, c : std_logic;
begin
    if clk'event and clk='1' then
        a := '1';    -- a vale '1' AHORA MISMO
        b := a;      -- b recibe '1' (el valor nuevo)
        c := b;      -- c recibe '1' también
    end if;
end process;
-- Resultado: a=b=c='1' en el mismo ciclo
-- → esto NO es un shift register, es otra cosa completamente diferente
```

**La regla práctica para el examen:**
- Dentro del proceso: solo `<=` para actualizar registros (flip-flops)
- Fuera del proceso: toda la lógica combinacional con `<=` concurrente o `when/else`

### Por qué el profe no quiere variables

1. **No se ven en ModelSim** — las variables no aparecen en el waveform, lo que hace casi imposible depurar el diseño.
2. **La correspondencia con el hardware no es obvia** — hay que pensar mucho para saber qué circuito infiere el sintetizador de una variable.
3. **Es mala práctica en RTL** — en el mundo profesional se evitan las variables en procesos síncronos por exactamente estas razones.

### Cómo se arregló en este proyecto

| Módulo | Tenía | Se cambió por |
|---|---|---|
| `bin_to_bcd.vhd` | Variables para carry chain | Señales `c1..c5`, `tmp0..tmp5`, `n0..n5` fuera del proceso |
| `alu.vhd` | Variables `r`, `s`, `m12`, `m22` | Señales `sum_neg`, `sub_neg`, `mul_neg` + `when/else` concurrentes |
| `controlador.vhd` | Variable `acc` para acumular BCD | Señales `new_dig`, `acc_op2` concurrentes |
| `displays.vhd` | Variables `d1..d8`, `s`, `c`, `d`, `u` | Señales `sig_d1..sig_d8` + `when/else` por cada display |

---

## Cómo funciona el teclado (ctrl_tec)

El teclado es una matriz 4×4. Para leer qué tecla está pulsada:

1. **Escaneo de filas**: el módulo activa una fila cada vez (pone un '0' en ella, las demás a '1'). Rota: `fila = 1110 → 1101 → 1011 → 0111 → 1110 → ...` cada 5 ms (un tic).

2. **Lectura de columnas**: si se está pulsando una tecla en la fila activa, la columna correspondiente vale '0' (activo bajo). Si no hay ninguna tecla pulsada, todas las columnas valen '1'.

3. **Antirebote**: no se acepta la columna hasta que lleva dos tics consecutivos con el mismo valor. Eso son 10 ms de estabilidad mínima.

4. **Detección de release**: `tecla_pulsada` se genera en el momento en que se SUELTA la tecla (flanco de bajada de la señal interna). Esto es lo más común en teclados: la acción se registra al soltar, no al pulsar. Si se mantiene más de 2 s → `pulso_largo`.

---

## Cómo funciona el algoritmo bin_to_bcd (Horner en BCD)

Convierte un número binario de 20 bits a BCD de 6 dígitos en exactamente 20 ciclos.

**La idea**: el número binario se puede escribir como:
$$N = b_{19} \cdot 2^{19} + \ldots + b_0 = (\ldots((b_{19}) \cdot 2 + b_{18}) \cdot 2 + \ldots) \cdot 2 + b_0$$

Esto es Horner: se empieza por el bit más significativo y en cada paso se dobla el acumulador y se suma el siguiente bit. La clave es que se hace **en BCD**, no en binario.

**"Doblar en BCD"**: si un dígito BCD vale `d` y se dobla → `2d + carry_entrada`. Si el resultado ≥ 10: se le resta 10 (en hardware: se le suma 6, porque 16-10=6 aprovechando el wrap del nibble) y se genera carry hacia el dígito superior.

**Ejemplo con 8 bits: 10011101₂ = 157₁₀**

| Bit | Acumulador (decimal) |
|-----|----------------------|
| 1   | 1 |
| 0   | 2 |
| 0   | 4 |
| 1   | 9 |
| 1   | 19 → BCD: 1,9 |
| 1   | 39 → BCD: 3,9 |
| 0   | 78 → BCD: 7,8 |
| 1   | 157 → BCD: 1,5,7 ✓ |

---

## FSM del controlador (Fase 3)

```
        ┌──────────────────────────────────────────────────────────┐
        │  OP1: introduce dígitos op1                               │
        │  - tecla 0-9: acumula (máx 999, no leading zeros)        │
        │  - tecla C: cambia signo (si valor ≠ 0)                  │
        │  - tecla A/D/E: guarda operación → pasa a OP2            │
        └──────────────────────┬───────────────────────────────────┘
                               │ A, D o E pulsado
                               ▼
        ┌──────────────────────────────────────────────────────────┐
        │  OP2: introduce dígitos op2                               │
        │  - tecla 0-9: igual que OP1                               │
        │  - tecla C: cambia signo                                  │
        │  - tecla B: lanza cálculo → start_bcd=1 → pasa a WAIT   │
        └──────────────────────┬───────────────────────────────────┘
                               │ B pulsado
                               ▼
        ┌──────────────────────────────────────────────────────────┐
        │  WAIT_BCD: espera que bin_to_bcd termine                  │
        │  - done_bcd = '1': guarda signo resultado → pasa a RES   │
        └──────────────────────┬───────────────────────────────────┘
                               │ done_bcd = '1'
                               ▼
        ┌──────────────────────────────────────────────────────────┐
        │  RES: muestra resultado                                   │
        │  - cualquier tecla: vuelve a OP1                          │
        │  - si tecla 1-9: empieza nuevo op1 con ese dígito        │
        └──────────────────────────────────────────────────────────┘
```

---

## Codificación de teclas

| Tecla física | Código hex | Función |
|---|---|---|
| 0-9 | 0x0 - 0x9 | Dígito BCD |
| A | 0xA | Suma (+) |
| B | 0xB | Igual / Validar (=) |
| C | 0xC | Cambio de signo (±) |
| D | 0xD | Resta (-) |
| E | 0xE | Multiplicación (×) |
| F | 0xF | Sin función asignada |

---

## Comandos útiles para compilar y simular

```bat
rem Compilar todo (desde la carpeta del proyecto)
cd C:\Users\EDUARD~1\DOCUME~1\DD2\PROYEC~2
vlib work
vmap work work
vcom -93 fase1\bcd_to_bin.vhd fase1\bin_to_bcd.vhd ^
         fase2\lpm_mult.vhd fase2\alu.vhd fase2\timer.vhd ^
         fase2\clk_div.vhd fase2\ctrl_tec.vhd ^
         fase2\interfaz_teclado.vhd fase2\displays.vhd ^
         fase2\tb_alu.vhd ^
         fase3\controlador.vhd fase3\calculadora.vhd ^
         fase3\tb_calculadora.vhd

rem Simular la ALU
vsim -c work.tb_alu -do "run -all"

rem Simular la calculadora completa
vsim work.tb_calculadora
```

> **Importante**: la ruta del home tiene una `ñ` y ModelSim no la soporta.
> Usar siempre el path corto 8.3: `C:\Users\EDUARD~1\DOCUME~1\DD2\PROYEC~2`

---

## Plazos de entrega

| Fase | Fecha límite |
|---|---|
| Fase 2 | 14 Mayo 2026 |
| Fase 3 | 28 Mayo 2026 |
| Memoria completa | 3 Junio 2026 |
