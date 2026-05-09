--------------------------------------------------------------------------------
-- ctrl_tec: controlador del teclado hexadecimal matricial 4x4
-- Incluye antirebote de columnas (col_reb -> col_ok), escaneo de filas
-- y deteccion de pulsacion corta (tecla_pulsada) y pulsacion larga (pulso_largo)
--
-- Interfaz:
--   tic      : pulso periodico de 5 ms (desde clk_div externo)
--   columna  : 4 bits activo bajo (1=no pulsada, 0=pulsada)
--   fila     : 4 bits activo bajo (salida, solo 1 bit a '0' a la vez)
--   tecla    : ultimo codigo detectado (4 bits)
--   tecla_pulsada : pulso de 1 ciclo de reloj al soltar la tecla (pulsacion corta)
--   pulso_largo   : se activa tras mantener pulsada TICS_2s ticks de 5 ms
--
-- Matriz de teclas (fila activa = '0', columna activa = '0'):
--   fila="1110": col=1110->1  1101->2  1011->3  0111->F
--   fila="1101": col=1110->4  1101->5  1011->6  0111->E
--   fila="1011": col=1110->7  1101->8  1011->9  0111->D
--   fila="0111": col=1110->A  1101->0  1011->B  0111->C
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl_tec is
    generic(
        TICS_2s : natural := 400   -- 400 tics de 5 ms = 2 s a 50 MHz
    );
    port(
        clk           : in  std_logic;
        nRst          : in  std_logic;
        tic           : in  std_logic;
        columna       : in  std_logic_vector(3 downto 0);
        fila          : buffer std_logic_vector(3 downto 0);
        tecla_pulsada : buffer std_logic;
        tecla         : buffer std_logic_vector(3 downto 0);
        pulso_largo   : buffer std_logic
    );
end entity;

architecture rtl of ctrl_tec is

    signal cnt_tic_2s : std_logic_vector(8 downto 0);

    signal col_reb : std_logic_vector(3 downto 0);
    signal col_ok  : std_logic_vector(3 downto 0);

    signal ctrl_tecla_pulsada : std_logic;
    signal ena_muestreo       : std_logic;
    signal pulso_hab_tecla    : std_logic;
    signal pulso_hab_largo    : std_logic;
    signal tecla_aux          : std_logic_vector(3 downto 0);

begin

    -- ---- Contador de tics para deteccion de pulso largo -----------------
    process(clk, nRst)
    begin
        if nRst = '0' then
            cnt_tic_2s <= (others => '0');
            pulso_largo <= '0';
        elsif clk'event and clk = '1' then
            if tic = '1' then
                if ctrl_tecla_pulsada = '0' then
                    cnt_tic_2s  <= (others => '0');
                    pulso_largo <= '0';
                elsif cnt_tic_2s <= TICS_2s and col_ok /= X"F" then
                    cnt_tic_2s <= cnt_tic_2s + 1;
                    if cnt_tic_2s = TICS_2s then
                        pulso_largo <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ---- Antirebote de columnas: 2 registros muestreados a tic ---------
    process(clk, nRst)
    begin
        if nRst = '0' then
            col_reb <= (others => '1');
            col_ok  <= (others => '1');
        elsif clk'event and clk = '1' then
            col_reb <= columna;
            if tic = '1' then
                col_ok <= col_reb;
            end if;
        end if;
    end process;

    -- ---- Conformador: tecla_pulsada = pulso de 1 ciclo al soltar -------
    process(clk, nRst)
    begin
        if nRst = '0' then
            pulso_hab_tecla <= '0';
        elsif clk'event and clk = '1' then
            pulso_hab_tecla <= ctrl_tecla_pulsada;
        end if;
    end process;

    -- ---- Registro del estado de pulso_largo (retardo 1 ciclo) ----------
    process(clk, nRst)
    begin
        if nRst = '0' then
            pulso_hab_largo <= '0';
        elsif clk'event and clk = '1' then
            pulso_hab_largo <= pulso_largo;
        end if;
    end process;

    -- ---- Senales combinacionales ----------------------------------------
    -- Paramos el muestreo de filas mientras haya rebotes en las columnas
    ena_muestreo <= '0' when col_reb /= X"F" else '1';

    -- Tecla considerada pulsada cuando col_ok detecta actividad (sin rebotes)
    ctrl_tecla_pulsada <= '1' when col_ok /= X"F" else '0';

    -- Pulso de 1 ciclo en el flanco de bajada de ctrl_tecla_pulsada
    -- (al soltar), siempre que no sea un pulso largo
    tecla_pulsada <= '1' when pulso_hab_tecla = '1'
                          and ctrl_tecla_pulsada = '0'
                          and pulso_hab_largo = '0'
                     else '0';

    -- ---- Escaneo de filas -----------------------------------------------
    process(clk, nRst)
    begin
        if nRst = '0' then
            fila <= (others => '1');
        elsif clk'event and clk = '1' then
            if tic = '1' then
                if ena_muestreo = '1' then
                    if fila = X"F" then
                        fila <= "1110";          -- arrancar escaneo en fila 0
                    else
                        fila <= fila(2 downto 0) & fila(3);  -- rotacion izquierda
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ---- Decodificador fila x columna -> tecla --------------------------
    process(clk, nRst)
    begin
        if nRst = '0' then
            tecla_aux <= (others => '0');
        elsif clk'event and clk = '1' then
            if    fila = "1110" and col_ok = "1110" then tecla_aux <= X"1";
            elsif fila = "1110" and col_ok = "1101" then tecla_aux <= X"2";
            elsif fila = "1110" and col_ok = "1011" then tecla_aux <= X"3";
            elsif fila = "1110" and col_ok = "0111" then tecla_aux <= X"F";
            elsif fila = "1101" and col_ok = "1110" then tecla_aux <= X"4";
            elsif fila = "1101" and col_ok = "1101" then tecla_aux <= X"5";
            elsif fila = "1101" and col_ok = "1011" then tecla_aux <= X"6";
            elsif fila = "1101" and col_ok = "0111" then tecla_aux <= X"E";
            elsif fila = "1011" and col_ok = "1110" then tecla_aux <= X"7";
            elsif fila = "1011" and col_ok = "1101" then tecla_aux <= X"8";
            elsif fila = "1011" and col_ok = "1011" then tecla_aux <= X"9";
            elsif fila = "1011" and col_ok = "0111" then tecla_aux <= X"D";
            elsif fila = "0111" and col_ok = "1110" then tecla_aux <= X"A";
            elsif fila = "0111" and col_ok = "1101" then tecla_aux <= X"0";
            elsif fila = "0111" and col_ok = "1011" then tecla_aux <= X"B";
            elsif fila = "0111" and col_ok = "0111" then tecla_aux <= X"C";
            end if;
        end if;
    end process;

    -- ---- Registro de la tecla activa ------------------------------------
    process(clk, nRst)
    begin
        if nRst = '0' then
            tecla <= (others => '0');
        elsif clk'event and clk = '1' then
            if (pulso_hab_tecla = '1' and ctrl_tecla_pulsada = '0' and pulso_hab_largo = '0')
               or (pulso_largo = '1') then
                tecla <= tecla_aux;
            end if;
        end if;
    end process;

end rtl;
