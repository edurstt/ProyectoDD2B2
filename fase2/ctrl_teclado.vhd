--------------------------------------------------------------------------------
-- ctrl_teclado: controlador FSM del teclado hexadecimal matricial 4x4
--
-- Matriz de teclas (filas activas en bajo, columnas activas en bajo):
--   fil0: col0=1  col1=2  col2=3  col3=F
--   fil1: col0=4  col1=5  col2=6  col3=E
--   fil2: col0=7  col1=8  col2=9  col3=D
--   fil3: col0=A  col1=0  col2=B  col3=C
--
-- Teclas relevantes para la calculadora:
--   0-9 : digitos     A: suma     D: resta    E: multiplicacion
--   B: validar op2    C: cambio de signo
--
-- Salidas:
--   tecla         : codigo de la ultima tecla detectada (4 bits)
--   tecla_pulsada : pulso de 1 ciclo de reloj al soltar la tecla (pulsacion corta)
--   fil0..3       : filas a activar (activo bajo)
--
-- Estados: ESCANEO -> PULSADO -> ESCANEO
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl_teclado is
    port(
        clk           : in  std_logic;
        nRst          : in  std_logic;
        tic           : in  std_logic;   -- pulso periodico del clk_div (5 ms)

        col0          : in  std_logic;
        col1          : in  std_logic;
        col2          : in  std_logic;
        col3          : in  std_logic;

        fil0          : out std_logic;
        fil1          : out std_logic;
        fil2          : out std_logic;
        fil3          : out std_logic;

        tecla         : out std_logic_vector(3 downto 0);
        tecla_pulsada : out std_logic    -- 1 ciclo al soltar la tecla
    );
end entity;

architecture rtl of ctrl_teclado is

    type estado_t is (ESCANEO, PULSADO);
    signal estado    : estado_t;

    signal fila_sel  : std_logic_vector(1 downto 0);
    signal tecla_reg : std_logic_vector(3 downto 0);
    signal tp_reg    : std_logic;

    -- Alguna columna activa?
    signal pulsacion : std_logic;

begin

    pulsacion <= '1' when (col0 = '0' or col1 = '0' or col2 = '0' or col3 = '0')
                 else '0';

    process(clk, nRst)
    begin
        if nRst = '0' then
            estado    <= ESCANEO;
            fila_sel  <= "00";
            tecla_reg <= (others => '0');
            tp_reg    <= '0';

        elsif clk'event and clk = '1' then
            tp_reg <= '0';   -- pulso de 1 ciclo por defecto

            case estado is

                -- ESCANEO: activar filas de una en una con cada tic --------
                when ESCANEO =>
                    if tic = '1' then
                        if pulsacion = '1' then
                            -- Registrar que tecla esta pulsada
                            case fila_sel is
                                when "00" =>
                                    if    col0 = '0' then tecla_reg <= x"1";
                                    elsif col1 = '0' then tecla_reg <= x"2";
                                    elsif col2 = '0' then tecla_reg <= x"3";
                                    else                  tecla_reg <= x"F";
                                    end if;
                                when "01" =>
                                    if    col0 = '0' then tecla_reg <= x"4";
                                    elsif col1 = '0' then tecla_reg <= x"5";
                                    elsif col2 = '0' then tecla_reg <= x"6";
                                    else                  tecla_reg <= x"E";
                                    end if;
                                when "10" =>
                                    if    col0 = '0' then tecla_reg <= x"7";
                                    elsif col1 = '0' then tecla_reg <= x"8";
                                    elsif col2 = '0' then tecla_reg <= x"9";
                                    else                  tecla_reg <= x"D";
                                    end if;
                                when others =>
                                    if    col0 = '0' then tecla_reg <= x"A";
                                    elsif col1 = '0' then tecla_reg <= x"0";
                                    elsif col2 = '0' then tecla_reg <= x"B";
                                    else                  tecla_reg <= x"C";
                                    end if;
                            end case;
                            estado <= PULSADO;
                        else
                            -- Ninguna columna activa: avanzar a siguiente fila
                            fila_sel <= fila_sel + 1;
                        end if;
                    end if;

                -- PULSADO: esperar a que se suelte la tecla ---------------
                when PULSADO =>
                    if tic = '1' then
                        if pulsacion = '0' then
                            -- Tecla soltada: generar pulso y volver a escanear
                            tp_reg   <= '1';
                            fila_sel <= "00";
                            estado   <= ESCANEO;
                        end if;
                    end if;

            end case;
        end if;
    end process;

    -- Activar la fila seleccionada (activo bajo)
    fil0 <= '0' when fila_sel = "00" else '1';
    fil1 <= '0' when fila_sel = "01" else '1';
    fil2 <= '0' when fila_sel = "10" else '1';
    fil3 <= '0' when fila_sel = "11" else '1';

    tecla         <= tecla_reg;
    tecla_pulsada <= tp_reg;

end rtl;
