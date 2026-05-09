--------------------------------------------------------------------------------
-- controlador: FSM principal de la calculadora
--
-- Flujo de operacion:
--   OP1  -> introduce digitos de op1 (y signo con C)
--          -> tecla operacion (A/D/E) -> guarda op1, pasa a OP2
--   OP2  -> introduce digitos de op2 (y signo con C)
--          -> tecla B (validar) -> lanza calculo, pasa a WAIT_BCD
--   WAIT_BCD -> espera done_bcd, captura signo resultado, pasa a RES
--   RES  -> muestra resultado
--          -> cualquier tecla: nueva entrada, vuelve a OP1
--
-- Acumulacion de digitos BCD (max 3 digitos, rango 0..999):
--   nuevo_reg = reg(7:0) & nuevo_nibble
--   se acepta si nuevo_reg <= x"999" (comparacion BCD directa)
--   cero inicial no se acumula (supresion de ceros a la izquierda)
--
-- Codigos de tecla (4 bits):
--   0-9: digitos   A:suma  D:resta  E:multiplicacion  B:validar  C:signo
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity controlador is
    port(
        clk          : in  std_logic;
        nRst         : in  std_logic;

        -- Entradas del teclado
        tecla        : in  std_logic_vector(3 downto 0);
        tecla_pulsada: in  std_logic;

        -- Del conversor bin_to_bcd
        done_bcd     : in  std_logic;
        res_sgn_alu  : in  std_logic;   -- signo ALU (combinacional, siempre valido)

        -- BCD de operandos hacia datapath
        op1_bcd      : out std_logic_vector(11 downto 0);  -- centenas,decenas,unidades
        op1_sgn      : out std_logic;
        op2_bcd      : out std_logic_vector(11 downto 0);
        op2_sgn      : out std_logic;
        op_sel       : out std_logic_vector(1 downto 0);   -- 00=+ 01=- 10=*

        -- Control de bin_to_bcd (pulso de 1 ciclo para iniciar conversion)
        start_bcd    : out std_logic;

        -- Control de displays
        pres         : out std_logic_vector(1 downto 0);   -- 00=op1 01=op2 10=res
        res_sgn_disp : out std_logic
    );
end entity;

architecture rtl of controlador is

    type estado_t is (OP1, OP2, WAIT_BCD, RES);
    signal estado : estado_t;

    signal reg_op1   : std_logic_vector(11 downto 0);
    signal reg_op2   : std_logic_vector(11 downto 0);
    signal sgn1      : std_logic;
    signal sgn2      : std_logic;
    signal reg_op    : std_logic_vector(1 downto 0);
    signal reg_sgn_r : std_logic;

    -- Candidatos para acumulacion de digito (uno por operando)
    signal new_dig   : std_logic_vector(11 downto 0);
    signal acc_op2   : std_logic_vector(11 downto 0);

begin

    -- Logica combinacional: siguiente digito BCD candidato (sin variables)
    new_dig <= reg_op1(7 downto 0) & tecla;
    acc_op2 <= reg_op2(7 downto 0) & tecla;

    -- Logica secuencial principal
    process(clk, nRst)
    begin
        if nRst = '0' then
            estado    <= OP1;
            reg_op1   <= (others => '0');
            reg_op2   <= (others => '0');
            sgn1      <= '0';
            sgn2      <= '0';
            reg_op    <= "00";
            reg_sgn_r <= '0';
            start_bcd <= '0';

        elsif clk'event and clk = '1' then
            start_bcd <= '0';    -- por defecto, sin inicio

            case estado is

                -- ---- Introduccion del operando 1 -------------------------
                when OP1 =>
                    if tecla_pulsada = '1' then

                        if tecla <= x"9" then
                            -- Digito 0..9: acumular si hay hueco y no es cero inicial
                            if not (reg_op1 = x"000" and tecla = x"0") then
                                if new_dig <= x"999" then
                                    reg_op1 <= new_dig;
                                end if;
                            end if;

                        elsif tecla = x"C" then
                            -- Cambio de signo (solo si el valor no es cero)
                            if reg_op1 /= x"000" then
                                sgn1 <= not sgn1;
                            end if;

                        elsif tecla = x"A" or tecla = x"D" or tecla = x"E" then
                            -- Operacion elegida: ir a OP2
                            if    tecla = x"A" then reg_op <= "00";
                            elsif tecla = x"D" then reg_op <= "01";
                            else                    reg_op <= "10";
                            end if;
                            reg_op2 <= (others => '0');
                            sgn2    <= '0';
                            estado  <= OP2;
                        end if;
                    end if;

                -- ---- Introduccion del operando 2 -------------------------
                when OP2 =>
                    if tecla_pulsada = '1' then

                        if tecla <= x"9" then
                            if not (reg_op2 = x"000" and tecla = x"0") then
                                if acc_op2 <= x"999" then
                                    reg_op2 <= acc_op2;
                                end if;
                            end if;

                        elsif tecla = x"C" then
                            if reg_op2 /= x"000" then
                                sgn2 <= not sgn2;
                            end if;

                        elsif tecla = x"B" then
                            -- Validar: lanzar calculo (pulso de 1 ciclo)
                            start_bcd <= '1';
                            estado    <= WAIT_BCD;
                        end if;
                    end if;

                -- ---- Esperar resultado de bin_to_bcd ---------------------
                when WAIT_BCD =>
                    if done_bcd = '1' then
                        reg_sgn_r <= res_sgn_alu;
                        estado    <= RES;
                    end if;

                -- ---- Mostrar resultado y esperar nueva entrada -----------
                when RES =>
                    if tecla_pulsada = '1' then
                        sgn1    <= '0';
                        sgn2    <= '0';
                        reg_op2 <= (others => '0');
                        reg_op  <= "00";
                        if tecla <= x"9" and tecla /= x"0" then
                            -- Empezar nuevo op1 con ese digito
                            reg_op1 <= x"00" & tecla;
                        else
                            reg_op1 <= (others => '0');
                        end if;
                        estado <= OP1;
                    end if;

            end case;
        end if;
    end process;

    -- Salidas registradas
    op1_bcd      <= reg_op1;
    op2_bcd      <= reg_op2;
    op1_sgn      <= sgn1;
    op2_sgn      <= sgn2;
    op_sel       <= reg_op;
    res_sgn_disp <= reg_sgn_r;

    -- Selector de display segun estado
    pres <= "00" when estado = OP1      else
            "01" when estado = OP2      else
            "10";   -- WAIT_BCD y RES: mostrar resultado

end rtl;
