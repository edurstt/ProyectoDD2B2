-- VCD dump: tb_calculadora
vcd file debug/tb_calculadora.vcd
-- Teclado
vcd add /tb_calculadora/fil0_s
vcd add /tb_calculadora/fil1_s
vcd add /tb_calculadora/fil2_s
vcd add /tb_calculadora/fil3_s
vcd add /tb_calculadora/col0_s
vcd add /tb_calculadora/col1_s
vcd add /tb_calculadora/col2_s
vcd add /tb_calculadora/col3_s
vcd add /tb_calculadora/sim_tecla
vcd add /tb_calculadora/sim_pulsar
-- Displays
vcd add /tb_calculadora/mux_s
vcd add /tb_calculadora/disp_s
-- Señales internas del DUT (via jerarquia)
vcd add /tb_calculadora/U_CALC/tecla_s
vcd add /tb_calculadora/U_CALC/tecla_pulsada_s
vcd add /tb_calculadora/U_CALC/op1_bcd_s
vcd add /tb_calculadora/U_CALC/op1_sgn_s
vcd add /tb_calculadora/U_CALC/op2_bcd_s
vcd add /tb_calculadora/U_CALC/op2_sgn_s
vcd add /tb_calculadora/U_CALC/op_sel_s
vcd add /tb_calculadora/U_CALC/start_s
vcd add /tb_calculadora/U_CALC/done_bcd_s
vcd add /tb_calculadora/U_CALC/res_bin_s
vcd add /tb_calculadora/U_CALC/res_bcd_s
vcd add /tb_calculadora/U_CALC/res_sgn_s
vcd add /tb_calculadora/U_CALC/pres_s
run -all
vcd flush
quit -f
