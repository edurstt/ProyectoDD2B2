--------------------------------------------------------------------------------
-- ALU: Unidad Aritmético-Lógica para la calculadora
-- Operaciones: suma, resta, multiplicación en complemento a 2
--
-- Entradas:
--   op1, op2 : 11 bits complemento a 2 (rango -999..+999)
--   op       : "00"=suma, "01"=resta, "10"=multiplicacion
-- Salidas:
--   res      : 20 bits, valor absoluto del resultado
--   res_sgn  : '1' si el resultado es negativo
--   overflow : siempre '0' (los operandos +-999 no pueden desbordar 20 bits)
--
-- La multiplicacion usa el componente lpm_mult (signed 11x11 -> 22 bits).
-- Para simulacion: incluir fase2/lpm_mult.vhd (modelo behavioral).
-- Para sintesis:   generar la IP lpm_mult desde el catalogo de Quartus.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu is
    port(
        op1      : in  std_logic_vector(10 downto 0);  -- complemento a 2
        op2      : in  std_logic_vector(10 downto 0);  -- complemento a 2
        op       : in  std_logic_vector(1 downto 0);   -- 00=+  01=-  10=*
        res      : out std_logic_vector(19 downto 0);  -- magnitud resultado
        res_sgn  : out std_logic;                      -- 0=positivo, 1=negativo
        overflow : out std_logic                       -- siempre '0' en esta version
    );
end entity;

architecture rtl of alu is

    -- Extension de signo a 12 bits para suma/resta
    signal op1_12    : std_logic_vector(11 downto 0);
    signal op2_12    : std_logic_vector(11 downto 0);
    signal sum_12    : std_logic_vector(11 downto 0);
    signal sub_12    : std_logic_vector(11 downto 0);

    -- Resultado del multiplicador (22 bits complemento a 2)
    signal mult_res  : std_logic_vector(21 downto 0);

    -- Complementos a 2 para extraer magnitud (sin variables)
    signal sum_neg  : std_logic_vector(11 downto 0);
    signal sub_neg  : std_logic_vector(11 downto 0);
    signal mul_neg  : std_logic_vector(21 downto 0);

    component lpm_mult is
        port(
            dataa  : in  std_logic_vector(10 downto 0);
            datab  : in  std_logic_vector(10 downto 0);
            result : out std_logic_vector(21 downto 0)
        );
    end component;

begin

    -- Extension de signo de 11 a 12 bits (replica el bit de signo)
    op1_12 <= op1(10) & op1;
    op2_12 <= op2(10) & op2;

    -- Suma y resta combinacionales (12 bits)
    sum_12 <= op1_12 + op2_12;
    sub_12 <= op1_12 - op2_12;

    -- Multiplicador con signo 11x11 -> 22 bits
    U_MULT: lpm_mult
        port map(
            dataa  => op1,
            datab  => op2,
            result => mult_res
        );

    overflow <= '0';

    -- Complementos a 2 para extraer magnitud (combinacional, sin variables)
    sum_neg <= (not sum_12) + 1;
    sub_neg <= (not sub_12) + 1;
    mul_neg <= (not mult_res) + 1;

    -- Magnitud del resultado segun operacion y signo
    res <= "00000000" & sum_neg      when op = "00" and sum_12(11)   = '1' else
           "00000000" & sum_12       when op = "00"                       else
           "00000000" & sub_neg      when op = "01" and sub_12(11)   = '1' else
           "00000000" & sub_12       when op = "01"                       else
           mul_neg(19 downto 0)      when op = "10" and mult_res(21) = '1' else
           mult_res(19 downto 0);

    -- Signo del resultado: '1' si negativo
    res_sgn <= '1' when (op = "00" and sum_12(11)   = '1') or
                        (op = "01" and sub_12(11)   = '1') or
                        (op = "10" and mult_res(21) = '1') else '0';

end rtl;
