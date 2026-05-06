--------------------------------------------------------------------------------
-- Testbench: bcd_to_bin
-- Sin numeric_std: se usan literales hexadecimales directamente
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_bcd_to_bin is
end entity;

architecture sim of tb_bcd_to_bin is
    signal bcd_in  : std_logic_vector(11 downto 0);
    signal bin_out : std_logic_vector(9 downto 0);
begin
    uut: entity work.bcd_to_bin
        port map(
            bcd => bcd_in,
            bin => bin_out
        );

    stim_proc: process
    begin
        -- Prueba 1: BCD 000 -> bin esperado 0
        bcd_in <= x"000"; wait for 20 ns;

        -- Prueba 2: BCD 123 (c=1,d=2,u=3) -> bin esperado 123
        bcd_in <= x"123"; wait for 20 ns;

        -- Prueba 3: BCD 999 -> bin esperado 999
        bcd_in <= x"999"; wait for 20 ns;

        -- Prueba 4: BCD 010 -> bin esperado 10
        bcd_in <= x"010"; wait for 20 ns;

        -- Prueba 5: BCD 100 -> bin esperado 100
        bcd_in <= x"100"; wait for 20 ns;

        wait;
    end process;
end sim;