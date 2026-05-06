# Resumen y FAQ – Fase 1: Conversores BCD ↔ Binario

---

## 1. ¿Qué hace cada módulo?

### `bcd_to_bin` (lógica combinacional)

Convierte un número BCD de 3 dígitos (centenas, decenas, unidades) a su equivalente binario natural.

- **Entrada:** `bcd[11:0]` — tres nibbles: `[11:8]` centenas, `[7:4]` decenas, `[3:0]` unidades.
- **Salida:** `bin[9:0]` — valor binario de 0 a 999.
- **Fórmula:** `bin = centenas × 100 + decenas × 10 + unidades`
- **Sin multiplicadores:** se descompone mediante desplazamientos y sumas:
  - `c × 100 = c×64 + c×32 + c×4` → shifts de 6, 5 y 2 posiciones.
  - `d × 10 = d×8 + d×2` → shifts de 3 y 1 posición.
- **Arquitectura:** puramente combinacional (`architecture rtl`), sin reloj.

### `bin_to_bcd` (secuencial – Double Dabble)

Convierte un número binario de hasta 20 bits a BCD de 6 dígitos (hasta 999 999).

- **Entradas:** `clk`, `nRst` (reset activo bajo), `start`, `bin[19:0]`
- **Salidas:** `done`, `bcd[23:0]` (seis nibbles BCD)
- **Algoritmo Double Dabble:**
  1. Se inicializa el acumulador BCD a 0 y se carga el registro binario.
  2. En cada ciclo: si algún nibble BCD ≥ 5, se le suma 3 (*add-3*).
  3. Se desplaza todo el conjunto (BCD+bin) un bit a la izquierda.
  4. Se repite N_BITS veces (20 ciclos para 20 bits).
- **Latencia:** `N_BITS + 2` ciclos de reloj (20 ciclos CALC + 1 FINISH + 1 IDLE de salida).
- **Máquina de estados:** `IDLE → CALC → FINISH → IDLE`.

---

## 2. Diagrama de estados de `bin_to_bcd`

```
        start='1'            bits_left=0
IDLE ──────────────► CALC ──────────────► FINISH
 ▲                                           │
 └───────────────────────────────────────────┘
              (done='1', vuelve a IDLE)
```

---

## 3. ¿Por qué Double Dabble?

- Evita divisiones y módulos (costosos en hardware).
- Solo usa desplazamientos y sumas de 3, operaciones muy baratas en lógica digital.
- Resultado directo en BCD, listo para conectar a displays de 7 segmentos.

---

## 4. ¿Por qué `nRst` activo en bajo?

Convención habitual en diseño síncrono. `nRst = '0'` fuerza el reset; `nRst = '1'` operación normal.

---

## 5. ¿Por qué `c × 100 = c×64 + c×32 + c×4`?

$100 = 64 + 32 + 4 = 2^6 + 2^5 + 2^2$

Multiplicar por una potencia de 2 equivale a un desplazamiento a la izquierda, implementable con simple reasignación de bits (cero coste en área).

$$d \times 10 = d \times 8 + d \times 2 = d \cdot 2^3 + d \cdot 2^1$$

---

## 6. ¿Por qué `std_logic_unsigned` en vez de `numeric_std`?

Es la librería disponible en ModelSim 5.1 (versión del laboratorio). Permite operar aritméticas sobre `std_logic_vector` directamente sin necesidad de conversiones `unsigned(...)`.

---

## 7. Testbenches

### `tb_bcd_to_bin`
Prueba combinacional pura: aplica 5 vectores de estímulo con 20 ns de separación.

| Prueba | BCD entrada | Binario esperado |
|--------|-------------|-----------------|
| 1      | 0x000       | 0               |
| 2      | 0x123       | 123             |
| 3      | 0x999       | 999             |
| 4      | 0x010       | 10              |
| 5      | 0x100       | 100             |

Finaliza con `assert false report "Fin de simulacion" severity failure`.

### `tb_bin_to_bcd`
Prueba secuencial: aplica reset, luego 10 conversiones usando el procedimiento `run_test`.

| Caso | Binario (decimal) | BCD esperado (hex) |
|------|-------------------|--------------------|
| 1    | 0                 | 0x000000           |
| 2    | 1                 | 0x000001           |
| 3    | 9                 | 0x000009           |
| 4    | 10                | 0x000010           |
| 5    | 100               | 0x000100           |
| 6    | 255               | 0x000255           |
| 7    | 999               | 0x000999           |
| 8    | 1000              | 0x001000           |
| 9    | 9999              | 0x009999           |
| 10   | 999999            | 0x999999           |

Sincronización: `wait until clk'event and clk = '1'` (compatible con ModelSim 5.1).  
Finaliza con `assert false report "Fin de simulacion" severity failure`.

---

## 8. ¿Cómo se verifica la salida en ModelSim?

1. En la ventana *Wave*, añadir `bcd_in`/`bin_out` (bcd_to_bin) o `bin`/`bcd`/`done` (bin_to_bcd).
2. Formato hex para los vectores BCD; decimal o binario para `bin`.
3. La simulación para automáticamente al llegar al `assert failure` — aparece un mensaje en la consola:
   ```
   # ** Failure: Fin de simulacion
   ```
4. Comprobar que el valor de `bin_out` o `bcd` coincide con la tabla de casos de prueba.

---

## 9. Posibles preguntas del profesor

**¿Qué pasa si se introduce un BCD inválido (p.ej. nibble = 0xA)?**  
El circuito no valida la entrada; el resultado sería erróneo. Si se necesitara, habría que añadir lógica de saturación o detección de error.

**¿Cuántos ciclos tarda `bin_to_bcd` en convertir 20 bits?**  
20 ciclos en estado CALC + 1 ciclo FINISH = 21 ciclos desde que `start` se activa hasta que `done` se pone a '1'. A 50 MHz → ~420 ns.

**¿Por qué `generic N_BITS`?**  
Para reutilizar el módulo con distintos anchos de entrada sin reescribir el código. En el proyecto se instancia con `N_BITS => 20`.

**¿El conversor BCD→bin tiene registros?**  
No, es puramente combinacional. La salida cambia en cuanto cambia la entrada, sin reloj.

**¿Qué diferencia hay entre `rising_edge(clk)` y `clk'event and clk='1'`?**  
`rising_edge` detecta solo la transición `'0'→'1'`, ignorando transiciones desde `'U'` o `'X'`. `clk'event and clk='1'` dispara también desde estados indefinidos. En ModelSim 5.1 (VHDL-87/93) el estilo `clk'event` es el original estándar.

---

## 10. Archivos del proyecto

| Archivo | Descripción |
|---------|-------------|
| `bcd_to_bin.vhd` | Conversor BCD→bin, combinacional |
| `bin_to_bcd.vhd` | Conversor bin→BCD, secuencial (Double Dabble) |
| `tb_bcd_to_bin.vhd` | Testbench combinacional |
| `tb_bin_to_bcd.vhd` | Testbench secuencial |
| `PROYECTO.mpf` | Proyecto ModelSim |
