-- VCD dump: tb_alu
vcd file debug/tb_alu.vcd
vcd add /tb_alu/op1
vcd add /tb_alu/op2
vcd add /tb_alu/op
vcd add /tb_alu/res
vcd add /tb_alu/res_sgn
vcd add /tb_alu/overflow
run -all
vcd flush
quit -f
