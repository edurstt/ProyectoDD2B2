--------------------------------------------------------------------------------
-- tb_calculadora: banco de pruebas del sistema completo
--
-- Simula el teclado fisico activando las columnas correctas segun la fila
-- que el ctrl_tec esta escaneando. Usa solo senales (sin variables).
--
-- Secuencias de prueba:
--   1) 123 + 456  -> resultado esperado  579
--   2) 999 - 1    -> resultado esperado  998
--   3)  12 * 12   -> resultado esperado  144
--   4) (-50) - 200 -> resultado esperado -250
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_calculadora is
end entity;

architecture sim of tb_calculadora is

    constant CLK_PERIOD : time := 20 ns;

    signal clk  : std_logic := '0';
    signal nRst : std_logic := '0';

    -- Teclado como buses (activo bajo)
    signal columna_s : std_logic_vector(3 downto 0) := "1111";
    signal fila_s    : std_logic_vector(3 downto 0);

    -- Displays
    signal mux_s  : std_logic_vector(7 downto 0);
    signal disp_s : std_logic_vector(7 downto 0);

    -- Control de simulacion de teclado
    signal sim_tecla  : std_logic_vector(3 downto 0) := x"0";
    signal sim_pulsar : std_logic := '0';

    -- Fila y columna que corresponden a sim_tecla (one-hot activo bajo)
    -- Calculadas combinacionalmente para que el proceso de teclado no
    -- necesite variables.
    signal fila_de_tecla : std_logic_vector(3 downto 0);
    signal col_de_tecla  : std_logic_vector(3 downto 0);

begin

    clk <= not clk after CLK_PERIOD / 2;

    -- ---- DUT ---------------------------------------------------------------
    U_CALC: entity work.calculadora(estructural)
        generic map(
            DIV_TEC => 4,
            DIV_1MS => 4,
            DIV_5MS => 4
        )
        port map(
            clk      => clk,
            nRst     => nRst,
            columna  => columna_s,
            fila     => fila_s,
            mux_disp => mux_s,
            disp     => disp_s
        );

    -- ---- Decodificacion combinacional de fila y columna ------------------
    -- Fila activa (one-hot activo bajo) segun tecla deseada
    fila_de_tecla <= "1110" when sim_tecla = x"1" or sim_tecla = x"2" or
                                 sim_tecla = x"3" or sim_tecla = x"F" else
                     "1101" when sim_tecla = x"4" or sim_tecla = x"5" or
                                 sim_tecla = x"6" or sim_tecla = x"E" else
                     "1011" when sim_tecla = x"7" or sim_tecla = x"8" or
                                 sim_tecla = x"9" or sim_tecla = x"D" else
                     "0111";  -- A, 0, B, C

    -- Columna activa (one-hot activo bajo) segun tecla deseada
    col_de_tecla <= "1110" when sim_tecla = x"1" or sim_tecla = x"4" or
                                sim_tecla = x"7" or sim_tecla = x"A" else
                    "1101" when sim_tecla = x"2" or sim_tecla = x"5" or
                                sim_tecla = x"8" or sim_tecla = x"0" else
                    "1011" when sim_tecla = x"3" or sim_tecla = x"6" or
                                sim_tecla = x"9" or sim_tecla = x"B" else
                    "0111";  -- F, E, D, C

    -- Activar columna correcta solo cuando la fila escaneada coincide
    columna_s <= col_de_tecla when sim_pulsar = '1' and fila_s = fila_de_tecla
                 else "1111";

    -- ---- Proceso de estimulacion (sin variables) ------------------------
    process
        procedure wait_clk(n : integer) is
        begin
            for i in 1 to n loop
                wait until clk'event and clk = '1';
            end loop;
        end procedure;

        procedure pulsar(t : std_logic_vector(3 downto 0)) is
        begin
            sim_tecla  <= t;
            sim_pulsar <= '1';
            wait_clk(30);
            sim_pulsar <= '0';
            wait_clk(30);
        end procedure;

    begin
        nRst <= '0';
        wait_clk(5);
        nRst <= '1';
        wait_clk(10);

        -- Test 1: 123 + 456 = 579
        pulsar(x"1"); pulsar(x"2"); pulsar(x"3");
        pulsar(x"A");
        pulsar(x"4"); pulsar(x"5"); pulsar(x"6");
        pulsar(x"B");
        wait_clk(100);

        -- Test 2: 999 - 1 = 998
        pulsar(x"0");
        wait_clk(10);
        pulsar(x"9"); pulsar(x"9"); pulsar(x"9");
        pulsar(x"D");
        pulsar(x"1");
        pulsar(x"B");
        wait_clk(100);

        -- Test 3: 12 * 12 = 144
        pulsar(x"0");
        wait_clk(10);
        pulsar(x"1"); pulsar(x"2");
        pulsar(x"E");
        pulsar(x"1"); pulsar(x"2");
        pulsar(x"B");
        wait_clk(100);

        -- Test 4: (-50) - 200 = -250
        pulsar(x"0");
        wait_clk(10);
        pulsar(x"5"); pulsar(x"0");
        pulsar(x"C");   -- cambio de signo -> -50
        pulsar(x"D");
        pulsar(x"2"); pulsar(x"0"); pulsar(x"0");
        pulsar(x"B");
        wait_clk(100);

        report "tb_calculadora: simulacion completada. Verificar formas de onda." severity note;
        assert false severity failure;
    end process;

end sim;
