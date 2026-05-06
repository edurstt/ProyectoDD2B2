-- Wave viewer: tb_bcd_to_bin
add wave -radix hex      /tb_bcd_to_bin/bcd_in
add wave -radix unsigned /tb_bcd_to_bin/bin_out
run -all
