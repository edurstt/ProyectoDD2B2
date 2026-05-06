--------------------------------------------------------------------------------
-- Conversor BCD a Binario - logica combinacional
-- Entrada:  bcd(11..8)=centenas, bcd(7..4)=decenas, bcd(3..0)=unidades
-- Salida:   bin = centenas*100 + decenas*10 + unidades  (0 a 999)
-- NOTA: sin multiplicacion directa, se usan desplazamientos (shifts = sumas)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bcd_to_bin is
    port(
        bcd : in  std_logic_vector(11 downto 0);
        bin : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of bcd_to_bin is
    signal c : std_logic_vector(9 downto 0);
    signal d : std_logic_vector(9 downto 0);
    signal u : std_logic_vector(9 downto 0);

    signal c100 : std_logic_vector(9 downto 0);
    signal d10  : std_logic_vector(9 downto 0);
begin
    -- Extender digitos a 10 bits
    c <= "000000" & bcd(11 downto 8);
    d <= "000000" & bcd( 7 downto 4);
    u <= "000000" & bcd( 3 downto 0);

    -- c * 100 = c*64 + c*32 + c*4
    --         = (c shl 6) + (c shl 5) + (c shl 2)
    c100 <= (c(3 downto 0) & "000000")          -- c * 64
          + (c(4 downto 0) & "00000")           -- c * 32
          + (c(7 downto 0) & "00");             -- c * 4

    -- d * 10 = d*8 + d*2
    --        = (d shl 3) + (d shl 1)
    d10  <= (d(6 downto 0) & "000")             -- d * 8
          + (d(8 downto 0) & '0');              -- d * 2

    bin <= c100 + d10 + u;
end rtl;