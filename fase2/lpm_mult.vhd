--------------------------------------------------------------------------------
-- lpm_mult: modelo behavioral del multiplicador con signo IP de Altera
-- Para SINTESIS: sustituir por la IP lpm_mult generada en Quartus (catalogo IP)
-- Para SIMULACION: este modelo calcula dataa * datab como numeros con signo
-- Entradas:  dataa, datab (11 bits complemento a 2)
-- Salida:    result (22 bits complemento a 2, result = dataa * datab)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lpm_mult is
    port(
        dataa  : in  std_logic_vector(10 downto 0);
        datab  : in  std_logic_vector(10 downto 0);
        result : out std_logic_vector(21 downto 0)
    );
end entity;

architecture behavioral of lpm_mult is
begin
    process(dataa, datab)
        variable a : signed(10 downto 0);
        variable b : signed(10 downto 0);
        variable r : signed(21 downto 0);
    begin
        a := signed(dataa);
        b := signed(datab);
        r := a * b;
        result <= std_logic_vector(r);
    end process;
end behavioral;
