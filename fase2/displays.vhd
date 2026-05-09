--------------------------------------------------------------------------------
-- displays: controlador de 8 displays de 7 segmentos multiplexados
-- Display DECA MAX10 + XDECA: cátodo común, activo alto
--
-- Formato del vector disp (8 bits): dp, a, b, c, d, e, f, g  (bit7..bit0)
-- Codigos de digit:
--   0-9 : digito decimal
--   x"A": 'A'    x"B": 'P'    x"C": 'C'
--   x"D": 'r'    x"E": blanco x"F": '-' (signo negativo)
--
-- Entradas de datos (todos en BCD, 4 bits por digito):
--   op1_bcd(11:0) : BCD operando 1 (centenas,decenas,unidades)
--   op1_sgn       : signo op1 (1=negativo)
--   op2_bcd(11:0) : BCD operando 2
--   op2_sgn       : signo op2
--   res_bcd(23:0) : BCD resultado (6 digitos: Md,Mc,Mb,Ma,D,U)
--   res_sgn       : signo resultado
--
-- Selector de presentacion (pres):
--   "00": muestra operando 1 en displays 1-4  (D4=signo D3..D1=digitos)
--   "01": muestra operando 2 en displays 1-4
--   "10": muestra resultado en displays 1-8   (D8=signo D7..D1=digitos)
--
-- Disposicion de displays (izquierda=D8, derecha=D1):
--   pres="00"/"01": [  D4  | D3  | D2  | D1  ] (4 displays activos)
--   pres="10":      [D8..D1] todos activos
--
-- La etiqueta del operador actual se muestra en D5 cuando pres="01"
--   no implementado: D5 fijo a blanco
--
-- mux_disp (8 bits): one-hot activo bajo, rota cada tic_1ms
--   bit 0 = display 1, bit 7 = display 8
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity displays is
    port(
        clk      : in  std_logic;
        nRst     : in  std_logic;
        tic_1ms  : in  std_logic;

        pres     : in  std_logic_vector(1 downto 0);   -- 00=op1 01=op2 10=res

        op1_bcd  : in  std_logic_vector(11 downto 0);  -- C,D,U en BCD
        op1_sgn  : in  std_logic;
        op2_bcd  : in  std_logic_vector(11 downto 0);
        op2_sgn  : in  std_logic;
        res_bcd  : in  std_logic_vector(23 downto 0);  -- 6 digitos BCD
        res_sgn  : in  std_logic;

        mux_disp : out std_logic_vector(7 downto 0);   -- one-hot activo bajo
        disp     : out std_logic_vector(7 downto 0)    -- dp,a,b,c,d,e,f,g
    );
end entity;

architecture rtl of displays is

    -- Registro del display activo (one-hot activo bajo, rotacion izquierda)
    signal mux_reg  : std_logic_vector(7 downto 0);

    -- Valor de los 8 digitos a mostrar (4 bits cada uno)
    -- digitos(3:0)   = display 1, digitos(31:28) = display 8
    signal digitos  : std_logic_vector(31 downto 0);

    -- Digito seleccionado actualmente (el que corresponde a mux_reg)
    signal dig_sel  : std_logic_vector(3 downto 0);

    -- Posicion activa (3 bits: 0..7 para displays 1..8)
    signal pos      : integer range 0 to 7;

    -- Digitos calculados combinacionalmente (sin variables)
    signal sig_d1, sig_d2, sig_d3, sig_d4 : std_logic_vector(3 downto 0);
    signal sig_d5, sig_d6, sig_d7, sig_d8 : std_logic_vector(3 downto 0);

    -- Funcion de decodificacion 4-bit -> 7 segmentos -----------------------
    function decode_seg(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when x"0" => return "01111110"; --  0 : abcdef
            when x"1" => return "00110000"; --  1 : bc
            when x"2" => return "01101101"; --  2 : abdeg
            when x"3" => return "01111001"; --  3 : abcdg
            when x"4" => return "00110011"; --  4 : bcfg
            when x"5" => return "01011011"; --  5 : acdfg
            when x"6" => return "01011111"; --  6 : acdefg
            when x"7" => return "01110000"; --  7 : abc
            when x"8" => return "01111111"; --  8 : abcdefg
            when x"9" => return "01111011"; --  9 : abcdfg
            when x"A" => return "00110111"; --  A : abcefg
            when x"B" => return "00011111"; --  P : adfg -> usamos como 'P'
            when x"C" => return "01001110"; --  C : adef
            when x"D" => return "00000101"; --  r : eg
            when x"E" => return "00000000"; -- blanco
            when x"F" => return "00000001"; -- '-' : g
            when others => return "00000000";
        end case;
    end function;

begin

    -- Digito 1 (unidades): siempre el valor de unidades
    sig_d1 <= op1_bcd(3 downto 0)  when pres = "00" else
              op2_bcd(3 downto 0)  when pres = "01" else
              res_bcd(3 downto 0);

    -- Digito 2 (decenas): blanco si centenas y decenas son cero
    sig_d2 <= x"E"                when pres = "00" and op1_bcd(11 downto 4) = x"00" else
              op1_bcd(7 downto 4) when pres = "00" else
              x"E"                when pres = "01" and op2_bcd(11 downto 4) = x"00" else
              op2_bcd(7 downto 4) when pres = "01" else
              x"E"                when res_bcd(23 downto 4) = x"00000" else
              res_bcd(7 downto 4);

    -- Digito 3 (centenas o signo si centenas=0)
    sig_d3 <= x"F"                 when pres = "00" and op1_bcd(11 downto 8) = x"0" and op1_sgn = '1' else
              x"E"                 when pres = "00" and op1_bcd(11 downto 8) = x"0" else
              op1_bcd(11 downto 8) when pres = "00" else
              x"F"                 when pres = "01" and op2_bcd(11 downto 8) = x"0" and op2_sgn = '1' else
              x"E"                 when pres = "01" and op2_bcd(11 downto 8) = x"0" else
              op2_bcd(11 downto 8) when pres = "01" else
              x"E"                 when res_bcd(23 downto 8) = x"0000" else
              res_bcd(11 downto 8);

    -- Digito 4 (signo si hay centenas / 4o digito BCD en resultado)
    sig_d4 <= x"F"                 when pres = "00" and op1_sgn = '1' and op1_bcd(11 downto 8) /= x"0" else
              x"E"                 when pres = "00" else
              x"F"                 when pres = "01" and op2_sgn = '1' and op2_bcd(11 downto 8) /= x"0" else
              x"E"                 when pres = "01" else
              x"E"                 when res_bcd(23 downto 12) = x"000" else
              res_bcd(15 downto 12);

    -- Digito 5: solo en resultado
    sig_d5 <= x"E"                 when pres /= "10" else
              x"E"                 when res_bcd(23 downto 16) = x"00" else
              res_bcd(19 downto 16);

    -- Digito 6: solo en resultado
    sig_d6 <= x"E"                 when pres /= "10" else
              x"E"                 when res_bcd(23 downto 20) = x"0" else
              res_bcd(23 downto 20);

    -- Digito 7: signo del resultado
    sig_d7 <= x"E"                 when pres /= "10" else
              x"F"                 when res_sgn = '1' else
              x"E";

    -- Digito 8: siempre blanco
    sig_d8 <= x"E";

    -- Concatenar todos los digitos
    digitos <= sig_d8 & sig_d7 & sig_d6 & sig_d5 & sig_d4 & sig_d3 & sig_d2 & sig_d1;

    -- Registro del multiplexor (one-hot activo bajo, rota izquierda) ------
    process(clk, nRst)
    begin
        if nRst = '0' then
            mux_reg <= "11111110";   -- display 1 activo (bit 0 = '0')
        elsif clk'event and clk = '1' then
            if tic_1ms = '1' then
                mux_reg <= mux_reg(6 downto 0) & mux_reg(7);  -- rotacion izq
            end if;
        end if;
    end process;

    -- Seleccionar el digito que corresponde al display activo -------------
    process(mux_reg, digitos)
    begin
        case mux_reg is
            when "11111110" => dig_sel <= digitos(3  downto 0);
            when "11111101" => dig_sel <= digitos(7  downto 4);
            when "11111011" => dig_sel <= digitos(11 downto 8);
            when "11110111" => dig_sel <= digitos(15 downto 12);
            when "11101111" => dig_sel <= digitos(19 downto 16);
            when "11011111" => dig_sel <= digitos(23 downto 20);
            when "10111111" => dig_sel <= digitos(27 downto 24);
            when "01111111" => dig_sel <= digitos(31 downto 28);
            when others     => dig_sel <= x"E";
        end case;
    end process;

    mux_disp <= mux_reg;
    disp     <= decode_seg(dig_sel);

end rtl;
