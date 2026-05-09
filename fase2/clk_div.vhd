--------------------------------------------------------------------------------
-- clk_div: divisor de reloj para el modulo de teclado
-- Genera un pulso de 1 ciclo cada 5 ms a partir del reloj de 50 MHz
-- Generic DIV: numero de ciclos menos 1 (default 249999 para 50 MHz -> 5 ms)
-- Para simulacion usar DIV pequenyo via generic map en el nivel superior
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clk_div is
    generic(
        DIV : natural := 249999   -- 250000 ciclos = 5 ms a 50 MHz
    );
    port(
        clk  : in  std_logic;
        nRst : in  std_logic;
        tic  : out std_logic
    );
end entity;

architecture rtl of clk_div is
    signal cnt     : integer range 0 to 249999;
    signal tic_reg : std_logic;
begin
    process(clk, nRst)
    begin
        if nRst = '0' then
            cnt     <= 0;
            tic_reg <= '0';
        elsif clk'event and clk = '1' then
            tic_reg <= '0';
            if cnt = DIV then
                tic_reg <= '1';
                cnt     <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    tic <= tic_reg;
end rtl;
