--------------------------------------------------------------------------------
-- tb_alu: banco de pruebas para la ALU de la calculadora
-- La ALU es combinacional: se cambian las entradas y se espera propagacion
--
-- Casos de prueba:
--   Suma:   100 + 200 = +300
--           (-100) + (-200) = -300
--           (-100) + 200 = +100
-- Resta:    300 - 100 = +200
--           100 - 300 = -200
-- Producto: 12 * 12 = +144
--           (-3) * 5 = -15
--           999 * 999 = +998001
--
-- Representacion complemento a 2 de 11 bits (precomputadas):
--   +100 = "00001100100"   -100 = "11110011100"
--   +200 = "00011001000"   -200 = "11100111000"
--   +300 = "00100101100"   -300 = "11011010100"
--   +12  = "00000001100"   -3   = "11111111101"
--   +5   = "00000000101"   +999 = "01111100111"
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_alu is
end entity;

architecture sim of tb_alu is

    signal op1     : std_logic_vector(10 downto 0);
    signal op2     : std_logic_vector(10 downto 0);
    signal op      : std_logic_vector(1 downto 0);
    signal res     : std_logic_vector(19 downto 0);
    signal res_sgn : std_logic;
    signal overflow: std_logic;

    -- Constantes para operandos en complemento a 2 (11 bits)
    constant C_P100  : std_logic_vector(10 downto 0) := "00001100100";  -- +100
    constant C_N100  : std_logic_vector(10 downto 0) := "11110011100";  -- -100
    constant C_P200  : std_logic_vector(10 downto 0) := "00011001000";  -- +200
    constant C_N200  : std_logic_vector(10 downto 0) := "11100111000";  -- -200
    constant C_P300  : std_logic_vector(10 downto 0) := "00100101100";  -- +300
    constant C_N300  : std_logic_vector(10 downto 0) := "11011010100";  -- -300
    constant C_P12   : std_logic_vector(10 downto 0) := "00000001100";  -- +12
    constant C_N3    : std_logic_vector(10 downto 0) := "11111111101";  -- -3
    constant C_P5    : std_logic_vector(10 downto 0) := "00000000101";  -- +5
    constant C_P999  : std_logic_vector(10 downto 0) := "01111100111";  -- +999

    -- Constantes de operacion
    constant OP_SUM : std_logic_vector(1 downto 0) := "00";
    constant OP_SUB : std_logic_vector(1 downto 0) := "01";
    constant OP_MUL : std_logic_vector(1 downto 0) := "10";

    procedure check(
        tag     : in string;
        got_mag : in std_logic_vector(19 downto 0);
        got_sgn : in std_logic;
        exp_mag : in integer;
        exp_sgn : in std_logic
    ) is
    begin
        assert got_sgn = exp_sgn
            report tag & ": signo incorrecto. Esperado " & std_logic'image(exp_sgn) &
                   " obtenido " & std_logic'image(got_sgn)
            severity error;
        assert got_mag = exp_mag
            report tag & ": magnitud incorrecta. Esperado " & integer'image(exp_mag) &
                   " obtenido " & integer'image(conv_integer(got_mag))
            severity error;
    end procedure;

begin

    -- Instancia del modulo bajo prueba
    U_ALU: entity work.alu(rtl)
        port map(
            op1      => op1,
            op2      => op2,
            op       => op,
            res      => res,
            res_sgn  => res_sgn,
            overflow => overflow
        );

    process
    begin
        -- Dejar tiempo de inicializacion
        op1 <= (others => '0');
        op2 <= (others => '0');
        op  <= OP_SUM;
        wait for 20 ns;

        -- ---- SUMA --------------------------------------------------------

        -- 100 + 200 = +300
        op1 <= C_P100; op2 <= C_P200; op <= OP_SUM; wait for 20 ns;
        check("100+200", res, res_sgn, 300, '0');

        -- (-100) + (-200) = -300
        op1 <= C_N100; op2 <= C_N200; op <= OP_SUM; wait for 20 ns;
        check("(-100)+(-200)", res, res_sgn, 300, '1');

        -- (-100) + 200 = +100
        op1 <= C_N100; op2 <= C_P200; op <= OP_SUM; wait for 20 ns;
        check("(-100)+200", res, res_sgn, 100, '0');

        -- ---- RESTA -------------------------------------------------------

        -- 300 - 100 = +200
        op1 <= C_P300; op2 <= C_P100; op <= OP_SUB; wait for 20 ns;
        check("300-100", res, res_sgn, 200, '0');

        -- 100 - 300 = -200
        op1 <= C_P100; op2 <= C_P300; op <= OP_SUB; wait for 20 ns;
        check("100-300", res, res_sgn, 200, '1');

        -- (-100) - 200 = -300
        op1 <= C_N100; op2 <= C_P200; op <= OP_SUB; wait for 20 ns;
        check("(-100)-200", res, res_sgn, 300, '1');

        -- ---- PRODUCTO ----------------------------------------------------

        -- 12 * 12 = +144
        op1 <= C_P12; op2 <= C_P12; op <= OP_MUL; wait for 20 ns;
        check("12*12", res, res_sgn, 144, '0');

        -- (-3) * 5 = -15
        op1 <= C_N3; op2 <= C_P5; op <= OP_MUL; wait for 20 ns;
        check("(-3)*5", res, res_sgn, 15, '1');

        -- 999 * 999 = 998001
        op1 <= C_P999; op2 <= C_P999; op <= OP_MUL; wait for 20 ns;
        check("999*999", res, res_sgn, 998001, '0');

        -- 0 * 999 = 0 (resultado cero es positivo)
        op1 <= (others => '0'); op2 <= C_P999; op <= OP_MUL; wait for 20 ns;
        check("0*999", res, res_sgn, 0, '0');

        report "tb_alu: todos los casos completados" severity note;
        assert false severity failure;
    end process;

end sim;
