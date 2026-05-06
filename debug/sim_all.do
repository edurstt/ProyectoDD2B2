-- Script ModelSim: compilar y simular ambos testbenches
-- Uso: vsim -c -do sim_all.do

vlib work
vmap work work

echo "=== Compilando fuentes ==="
vcom -93 bcd_to_bin.vhd
vcom -93 bin_to_bcd.vhd
vcom -93 tb_bcd_to_bin.vhd
vcom -93 tb_bin_to_bcd.vhd

echo ""
echo "=== Simulando tb_bcd_to_bin ==="
vsim -c work.tb_bcd_to_bin -do "run -all; quit -f"

echo ""
echo "=== Simulando tb_bin_to_bcd ==="
vsim -c work.tb_bin_to_bcd -do "run -all; quit -f"

echo ""
echo "=== Simulaciones completadas ==="
quit -f
