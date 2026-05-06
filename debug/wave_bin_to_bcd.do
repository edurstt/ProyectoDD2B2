-- Wave viewer: tb_bin_to_bcd
add wave                  /tb_bin_to_bcd/clk
add wave                  /tb_bin_to_bcd/nRst
add wave                  /tb_bin_to_bcd/start
add wave -radix unsigned  /tb_bin_to_bcd/bin
add wave                  /tb_bin_to_bcd/done
add wave -radix hex       /tb_bin_to_bcd/bcd
run -all
