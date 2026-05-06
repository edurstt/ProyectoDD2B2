--------------------------------------------------------------------------------
-- Testbench: bin_to_bcd
-- Casos simples y verificables. Ejecutar: run 2000 ns por conversion
-- En ModelSim 5.1: run 8000 ns cubre todas las pruebas
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_bin_to_bcd is
end entity;

architecture sim of tb_bin_to_bcd is
    signal clk   : std_logic := '0';
    signal nRst  : std_logic := '0';
    signal start : std_logic := '0';
    signal bin   : std_logic_vector(19 downto 0) := (others => '0');
    signal done  : std_logic := '0';
    signal bcd   : std_logic_vector(23 downto 0);

    constant clk_period : time := 20 ns;  -- 50 MHz
begin
    uut: entity work.bin_to_bcd
        generic map( N_BITS => 20 )
        port map(
            clk   => clk,
            nRst  => nRst,
            start => start,
            bin   => bin,
            done  => done,
            bcd   => bcd
        );

    -- Reloj 50 MHz
    clk_process: process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process

        -- Procedimiento auxiliar: lanza conversion y espera done = '1'
        -- Alinea con flanco de reloj antes de activar start para evitar
        -- condiciones de carrera entre start y el muestreo del estado
        procedure run_test(val : std_logic_vector(19 downto 0)) is
        begin
            -- Esperar flanco de subida de reloj para alinear
            wait until clk'event and clk = '1';
            bin   <= val;
            start <= '1';
            wait until clk'event and clk = '1';  -- done baja aqui (IDLE ve start)
            start <= '0';
            wait until done = '1';        -- esperar fin de conversion
            wait for clk_period * 2;      -- margen para ver resultado en waveform
        end procedure;

    begin
        -- Reset
        nRst <= '0';
        wait for 50 ns;
        nRst <= '1';
        wait for clk_period * 2;

        -- Caso 1: 0 -> BCD esperado 000_000 (0x000000)
        run_test("00000000000000000000");

        -- Caso 2: 1 -> BCD esperado 000_001 (0x000001)
        run_test("00000000000000000001");

        -- Caso 3: 9 -> BCD esperado 000_009 (0x000009)
        run_test("00000000000000001001");

        -- Caso 4: 10 -> BCD esperado 000_010 (0x000010)
        -- 10 en binario = 0000...001010
        run_test("00000000000000001010");

        -- Caso 5: 100 -> BCD esperado 000_100 (0x000100)
        -- 100 = 64+32+4 = 1100100
        run_test("00000000000001100100");

        -- Caso 6: 255 -> BCD esperado 000_255 (0x000255)
        -- 255 = 11111111
        run_test("00000000000011111111");

        -- Caso 7: 999 -> BCD esperado 000_999 (0x000999)
        -- 999 = 1111100111
        run_test("00000000001111100111");

        -- Caso 8: 1000 -> BCD esperado 001_000 (0x001000)
        -- 1000 = 1111101000
        run_test("00000000001111101000");

        -- Caso 9: 9999 -> BCD esperado 009_999 (0x009999)
        -- 9999 = 10011100001111
        run_test("00000010011100001111");

        -- Caso 10: 999999 -> BCD esperado 999_999 (0x999999)
        -- 999999 = 0xF423F = 11110100001000111111 b
        run_test("11110100001000111111");

        assert false report "Fin de simulacion" severity failure;
        wait;
    end process;
end sim;