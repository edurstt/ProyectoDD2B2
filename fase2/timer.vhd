--------------------------------------------------------------------------------
-- timer: generador de tics de temporizacion para la calculadora
-- Genera tic_1ms (multiplex de displays) y tic_5ms (escaneo de teclado)
-- Reloj base: 50 MHz (periodo 20 ns)
--
-- Genericos de simulacion: reducir DIV_1ms para acelerar simulaciones
--   Sintesis:   DIV_1ms = 49999  (50000 ciclos = 1 ms a 50 MHz)
--   Simulacion: DIV_1ms = 4      (valor pequenyo para no esperar ms reales)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity timer is
    generic(
        DIV_1ms : natural := 49999;   -- divisor para 1 ms a 50 MHz
        DIV_5ms : natural := 4        -- tic_5ms = tic_1ms cada 5 tics
    );
    port(
        clk     : in  std_logic;
        nRst    : in  std_logic;
        tic_1ms : out std_logic;
        tic_5ms : out std_logic
    );
end entity;

architecture rtl of timer is
    signal cnt_1ms  : integer range 0 to 49999;
    signal cnt_5ms  : integer range 0 to 7;
    signal t1ms_reg : std_logic;
    signal t5ms_reg : std_logic;
begin

    process(clk, nRst)
    begin
        if nRst = '0' then
            cnt_1ms  <= 0;
            cnt_5ms  <= 0;
            t1ms_reg <= '0';
            t5ms_reg <= '0';
        elsif clk'event and clk = '1' then
            t1ms_reg <= '0';
            t5ms_reg <= '0';

            -- Tic cada 1 ms
            if cnt_1ms = DIV_1ms then
                t1ms_reg <= '1';
                cnt_1ms  <= 0;

                -- Tic cada 5 ms (cada 5 tics de 1 ms)
                if cnt_5ms = DIV_5ms then
                    t5ms_reg <= '1';
                    cnt_5ms  <= 0;
                else
                    cnt_5ms <= cnt_5ms + 1;
                end if;
            else
                cnt_1ms <= cnt_1ms + 1;
            end if;
        end if;
    end process;

    tic_1ms <= t1ms_reg;
    tic_5ms <= t5ms_reg;

end rtl;
