--------------------------------------------------------------------------------
-- rebotes: filtro antirebote para las 4 columnas del teclado matricial
-- Las columnas son activas en nivel bajo (pressed = '0')
-- Implementa un filtro mayoritario de 3 muestras por columna:
--   columna estable a '0' si las ultimas 3 lecturas son '0'
--   columna estable a '1' si las ultimas 3 lecturas son '1'
--   en caso contrario mantiene el valor anterior
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity rebotes is
    port(
        clk          : in  std_logic;
        nRst         : in  std_logic;
        columnas_in  : in  std_logic_vector(3 downto 0);
        columnas_out : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of rebotes is
    -- Tres etapas de registro para cada columna
    signal r0, r1, r2 : std_logic_vector(3 downto 0);
    signal filt        : std_logic_vector(3 downto 0);
    -- Estado estable previo (necesario para VHDL-93: no se puede leer un out)
    signal estable     : std_logic_vector(3 downto 0);
begin

    -- Pipeline de 3 registros (sincronizador + 1 etapa de filtro)
    process(clk, nRst)
    begin
        if nRst = '0' then
            r0      <= (others => '1');   -- reposo: columnas sin pulsar = '1'
            r1      <= (others => '1');
            r2      <= (others => '1');
            estable <= (others => '1');
        elsif clk'event and clk = '1' then
            r0 <= columnas_in;
            r1 <= r0;
            r2 <= r1;
            -- Actualizar el estado estable solo cuando hay unanimidad
            for i in 0 to 3 loop
                if r0(i) = '0' and r1(i) = '0' and r2(i) = '0' then
                    estable(i) <= '0';
                elsif r0(i) = '1' and r1(i) = '1' and r2(i) = '1' then
                    estable(i) <= '1';
                end if;
            end loop;
        end if;
    end process;

    columnas_out <= estable;

end rtl;
