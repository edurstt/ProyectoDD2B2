--------------------------------------------------------------------------------
-- calculadora: top-level del sistema de la calculadora
--
-- Conecta:
--   interfaz_teclado   -> tecla, tecla_pulsada
--   controlador (FSM)  -> op1_bcd, op2_bcd, op1_sgn, op2_sgn, op_sel,
--                         start_bcd, pres, res_sgn_disp
--   bcd_to_bin (x2)    -> convierte op1_bcd y op2_bcd a magnitud 10-bit
--   Logica inline       -> aplica signo: magnitud -> complemento a 2 (11 bits)
--   alu                 -> opera en complemento a 2, da magnitud 20-bit + sgn
--   bin_to_bcd          -> convierte magnitud ALU a BCD de 6 digitos (24 bits)
--   timer               -> tic_1ms para displays
--   displays            -> mux_disp + disp
--
-- Genericos para simulacion:
--   DIV_TEC : divisor del teclado (default 249999 para 5ms a 50MHz)
--   DIV_1MS : divisor timer 1ms  (default 49999  para 1ms a 50MHz)
--   DIV_5MS : divisor tic_5ms dentro del timer (5 tics de 1ms)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity calculadora is
    generic(
        DIV_TEC : natural := 249999;   -- teclado: 5 ms a 50 MHz
        DIV_1MS : natural := 49999;    -- timer: 1 ms a 50 MHz
        DIV_5MS : natural := 4         -- 5 tics de 1ms = 5 ms
    );
    port(
        clk     : in  std_logic;
        nRst    : in  std_logic;

        -- Teclado (XDECA, columnas activo bajo, bus 4 bits)
        columna : in  std_logic_vector(3 downto 0);   -- columnas activo bajo
        fila    : out std_logic_vector(3 downto 0);   -- filas activo bajo

        -- Displays 7 segmentos (8 displays multiplexados)
        mux_disp: out std_logic_vector(7 downto 0);
        disp    : out std_logic_vector(7 downto 0)
    );
end entity;

architecture estructural of calculadora is

    -- ---- Senales de teclado ----
    signal tecla_s         : std_logic_vector(3 downto 0);
    signal tecla_pulsada_s : std_logic;
    signal pulso_largo_s   : std_logic;

    -- ---- Senales de control (FSM) ----
    signal op1_bcd_s  : std_logic_vector(11 downto 0);
    signal op2_bcd_s  : std_logic_vector(11 downto 0);
    signal op1_sgn_s  : std_logic;
    signal op2_sgn_s  : std_logic;
    signal op_sel_s   : std_logic_vector(1 downto 0);
    signal start_s    : std_logic;
    signal pres_s     : std_logic_vector(1 downto 0);
    signal res_sgn_d  : std_logic;  -- signo del resultado para displays

    -- ---- Datapath: BCD -> binario (magnitudes) ----
    signal op1_mag_s  : std_logic_vector(9 downto 0);   -- 0..999
    signal op2_mag_s  : std_logic_vector(9 downto 0);

    -- Operandos en complemento a 2 (11 bits) hacia ALU
    signal op1_bin_s  : std_logic_vector(10 downto 0);
    signal op2_bin_s  : std_logic_vector(10 downto 0);

    -- ---- ALU ----
    signal res_bin_s  : std_logic_vector(19 downto 0);  -- magnitud resultado
    signal res_sgn_s  : std_logic;

    -- ---- bin_to_bcd ----
    signal done_bcd_s : std_logic;
    signal res_bcd_s  : std_logic_vector(23 downto 0);

    -- ---- Timer ----
    signal tic_1ms_s  : std_logic;
    signal tic_5ms_s  : std_logic;   -- no usado aqui, interfaz_teclado tiene el propio

begin

    -- ---- Subsistema de teclado ------------------------------------------
    U_TEC: entity work.interfaz_teclado(estructural)
        generic map(DIV_TEC => DIV_TEC)
        port map(
            clk           => clk,
            nRst          => nRst,
            columna       => columna,
            fila          => fila,
            tecla         => tecla_s,
            tecla_pulsada => tecla_pulsada_s,
            pulso_largo   => pulso_largo_s
        );

    -- ---- FSM controlador ------------------------------------------------
    U_CTRL: entity work.controlador(rtl)
        port map(
            clk           => clk,
            nRst          => nRst,
            tecla         => tecla_s,
            tecla_pulsada => tecla_pulsada_s,
            done_bcd      => done_bcd_s,
            res_sgn_alu   => res_sgn_s,
            op1_bcd       => op1_bcd_s,
            op1_sgn       => op1_sgn_s,
            op2_bcd       => op2_bcd_s,
            op2_sgn       => op2_sgn_s,
            op_sel        => op_sel_s,
            start_bcd     => start_s,
            pres          => pres_s,
            res_sgn_disp  => res_sgn_d
        );

    -- ---- BCD -> magnitud binaria para op1 --------------------------------
    U_BCD2BIN1: entity work.bcd_to_bin(rtl)
        port map(
            bcd => op1_bcd_s,
            bin => op1_mag_s
        );

    -- ---- BCD -> magnitud binaria para op2 --------------------------------
    U_BCD2BIN2: entity work.bcd_to_bin(rtl)
        port map(
            bcd => op2_bcd_s,
            bin => op2_mag_s
        );

    -- ---- Aplicar signo: magnitud -> complemento a 2 de 11 bits ---------
    -- Si sgn=0: op_bin = '0' & magnitud (positivo)
    -- Si sgn=1: op_bin = complemento_a_2('0' & magnitud)
    op1_bin_s <= ('0' & op1_mag_s) when op1_sgn_s = '0'
                 else (not ('0' & op1_mag_s)) + 1;

    op2_bin_s <= ('0' & op2_mag_s) when op2_sgn_s = '0'
                 else (not ('0' & op2_mag_s)) + 1;

    -- ---- ALU ------------------------------------------------------------
    U_ALU: entity work.alu(rtl)
        port map(
            op1      => op1_bin_s,
            op2      => op2_bin_s,
            op       => op_sel_s,
            res      => res_bin_s,
            res_sgn  => res_sgn_s,
            overflow => open
        );

    -- ---- Conversor resultado binario -> BCD (N_BITS = 20) ---------------
    U_BIN2BCD: entity work.bin_to_bcd(rtl)
        generic map(N_BITS => 20)
        port map(
            clk   => clk,
            nRst  => nRst,
            start => start_s,
            bin   => res_bin_s,
            done  => done_bcd_s,
            bcd   => res_bcd_s
        );

    -- ---- Temporizador para displays -------------------------------------
    U_TIMER: entity work.timer(rtl)
        generic map(DIV_1ms => DIV_1MS, DIV_5ms => DIV_5MS)
        port map(
            clk     => clk,
            nRst    => nRst,
            tic_1ms => tic_1ms_s,
            tic_5ms => tic_5ms_s
        );

    -- ---- Controlador de displays ----------------------------------------
    U_DISP: entity work.displays(rtl)
        port map(
            clk      => clk,
            nRst     => nRst,
            tic_1ms  => tic_1ms_s,
            pres     => pres_s,
            op1      => op1_bcd_s,
            op1_sgn  => op1_sgn_s,
            op2      => op2_bcd_s,
            op2_sgn  => op2_sgn_s,
            res      => res_bcd_s,
            res_sgn  => res_sgn_d,
            mux_disp => mux_disp,
            disp     => disp
        );

end estructural;
