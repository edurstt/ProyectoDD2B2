--------------------------------------------------------------------------------
-- Conversor Binario a BCD - Suma de pesos (método de Horner en BCD)
-- Para cada bit de MSB a LSB: acc = 2*acc + bit  (aritmética BCD)
-- Latencia: N_BITS ciclos
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bin_to_bcd is
    generic( N_BITS : natural := 20 );
    port(
        clk   : in  std_logic;
        nRst  : in  std_logic;
        start : in  std_logic;
        bin   : in  std_logic_vector(N_BITS-1 downto 0);
        done  : out std_logic;
        bcd   : out std_logic_vector(23 downto 0)
    );
end entity;

architecture rtl of bin_to_bcd is
    type state_type is (IDLE, CALC, FINISH);
    signal state     : state_type;
    signal acc_bcd   : std_logic_vector(23 downto 0);
    signal bin_reg   : std_logic_vector(N_BITS-1 downto 0);
    signal bits_left : integer range 0 to N_BITS;

    -- Cadena de carry BCD combinacional (un paso de Horner):
    --   acc_bcd_nuevo = 2*acc_bcd + bit_in  (en aritmetica BCD)
    -- Todo esto es logica combinacional pura; solo acc_bcd es un registro.
    signal bit_in          : std_logic;
    signal tmp0,tmp1,tmp2,tmp3,tmp4,tmp5 : std_logic_vector(4 downto 0);
    signal n0,n1,n2,n3,n4,n5             : std_logic_vector(3 downto 0);
    signal c1,c2,c3,c4,c5                : std_logic;

begin
    -- ---- Logica combinacional: cadena de carry BCD ----------------------
    -- bit_in: MSB del registro de desplazamiento (bit que entra en este ciclo)
    bit_in <= bin_reg(N_BITS-1);

    -- Digito 0 (unidades, bits 3:0)
    tmp0 <= ('0' & acc_bcd(3  downto  0)) + ('0' & acc_bcd(3  downto  0)) + ("0000" & bit_in);
    n0   <= tmp0(3 downto 0) + "0110" when tmp0 >= "01010" else tmp0(3 downto 0);
    c1   <= '1' when tmp0 >= "01010" else '0';

    -- Digito 1 (decenas, bits 7:4)
    tmp1 <= ('0' & acc_bcd(7  downto  4)) + ('0' & acc_bcd(7  downto  4)) + ("0000" & c1);
    n1   <= tmp1(3 downto 0) + "0110" when tmp1 >= "01010" else tmp1(3 downto 0);
    c2   <= '1' when tmp1 >= "01010" else '0';

    -- Digito 2 (centenas, bits 11:8)
    tmp2 <= ('0' & acc_bcd(11 downto  8)) + ('0' & acc_bcd(11 downto  8)) + ("0000" & c2);
    n2   <= tmp2(3 downto 0) + "0110" when tmp2 >= "01010" else tmp2(3 downto 0);
    c3   <= '1' when tmp2 >= "01010" else '0';

    -- Digito 3 (millares, bits 15:12)
    tmp3 <= ('0' & acc_bcd(15 downto 12)) + ('0' & acc_bcd(15 downto 12)) + ("0000" & c3);
    n3   <= tmp3(3 downto 0) + "0110" when tmp3 >= "01010" else tmp3(3 downto 0);
    c4   <= '1' when tmp3 >= "01010" else '0';

    -- Digito 4 (decenas de millar, bits 19:16)
    tmp4 <= ('0' & acc_bcd(19 downto 16)) + ('0' & acc_bcd(19 downto 16)) + ("0000" & c4);
    n4   <= tmp4(3 downto 0) + "0110" when tmp4 >= "01010" else tmp4(3 downto 0);
    c5   <= '1' when tmp4 >= "01010" else '0';

    -- Digito 5 (centenas de millar, bits 23:20)
    tmp5 <= ('0' & acc_bcd(23 downto 20)) + ('0' & acc_bcd(23 downto 20)) + ("0000" & c5);
    n5   <= tmp5(3 downto 0) + "0110" when tmp5 >= "01010" else tmp5(3 downto 0);

    -- ---- Proceso secuencial: solo registros, sin variables --------------
    process(clk, nRst)
    begin
        if nRst = '0' then
            state     <= IDLE;
            acc_bcd   <= (others => '0');
            bin_reg   <= (others => '0');
            bits_left <= 0;
            done      <= '0';

        elsif clk'event and clk = '1' then
            case state is

                when IDLE =>
                    if start = '1' then
                        done      <= '0';
                        acc_bcd   <= (others => '0');
                        bin_reg   <= bin;
                        bits_left <= N_BITS;
                        state     <= CALC;
                    end if;

                when CALC =>
                    if bits_left > 0 then
                        -- Registrar el nuevo valor BCD (calculado combinacionalmente)
                        acc_bcd   <= n5 & n4 & n3 & n2 & n1 & n0;
                        bin_reg   <= bin_reg(N_BITS-2 downto 0) & '0';
                        bits_left <= bits_left - 1;
                    else
                        state <= FINISH;
                    end if;

                when FINISH =>
                    done  <= '1';
                    state <= IDLE;

            end case;
        end if;
    end process;

    bcd <= acc_bcd;
end rtl;