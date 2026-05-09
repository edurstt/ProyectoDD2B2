--------------------------------------------------------------------------------
-- interfaz_teclado: subsistema completo del teclado hexadecimal
-- Instancia: clk_div (5 ms tic) + ctrl_tec (antirebote + escaneo + FSM)
--
-- Generic DIV_TEC: divisor para el clk_div
--   Sintesis:   249999  (5 ms a 50 MHz)
--   Simulacion: valor pequenyo (ej. 4) para no esperar tiempos reales
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity interfaz_teclado is
    generic(
        DIV_TEC : natural := 249999;   -- divisor clk_div: 5 ms a 50 MHz
        TICS_2s : natural := 400       -- tics para pulso largo: 400*5ms = 2 s
    );
    port(
        clk           : in  std_logic;
        nRst          : in  std_logic;

        columna       : in  std_logic_vector(3 downto 0);   -- activo bajo
        fila          : out std_logic_vector(3 downto 0);   -- activo bajo

        tecla         : out std_logic_vector(3 downto 0);
        tecla_pulsada : out std_logic;
        pulso_largo   : out std_logic
    );
end entity;

architecture estructural of interfaz_teclado is

    signal tic_s   : std_logic;
    signal fila_s  : std_logic_vector(3 downto 0);
    signal tp_s    : std_logic;
    signal pl_s    : std_logic;
    signal tec_s   : std_logic_vector(3 downto 0);  -- buffer->out necesita senal intermedia

begin

    -- Divisor de reloj: genera tic cada 5 ms
    U_DIV: entity work.clk_div(rtl)
        generic map(DIV => DIV_TEC)
        port map(clk => clk, nRst => nRst, tic => tic_s);

    -- Controlador de teclado (antirebote integrado)
    U_CTRL: entity work.ctrl_tec(rtl)
        generic map(TICS_2s => TICS_2s)
        port map(
            clk           => clk,
            nRst          => nRst,
            tic           => tic_s,
            columna       => columna,
            fila          => fila_s,
            tecla_pulsada => tp_s,
            tecla         => tec_s,
            pulso_largo   => pl_s
        );

    fila          <= fila_s;
    tecla         <= tec_s;
    tecla_pulsada <= tp_s;
    pulso_largo   <= pl_s;

end estructural;
