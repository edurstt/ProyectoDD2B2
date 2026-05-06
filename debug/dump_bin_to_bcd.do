-- VCD dump: tb_bin_to_bcd
vcd file debug/tb_bin_to_bcd.vcd
vcd add /tb_bin_to_bcd/clk
vcd add /tb_bin_to_bcd/nRst
vcd add /tb_bin_to_bcd/start
vcd add /tb_bin_to_bcd/bin
vcd add /tb_bin_to_bcd/done
vcd add /tb_bin_to_bcd/bcd
run -all
vcd flush
quit -f
