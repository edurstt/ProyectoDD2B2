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
begin
    process(clk, nRst)
        -- tmp recoge 2*digito + carry_in (rango 0..19, necesita 5 bits)
        variable tmp : std_logic_vector(4 downto 0);
        variable c   : std_logic;
        variable n0,n1,n2,n3,n4,n5 : std_logic_vector(3 downto 0);
    begin
        if nRst = '0' then
            state     <= IDLE;
            acc_bcd   <= (others => '0');
            bin_reg   <= (others => '0');
            bits_left <= 0;
            done      <= '0';

        elsif rising_edge(clk) then
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

                        -- acc_bcd = 2*acc_bcd + MSB_bin_reg  (aritmética BCD)
                        -- El bit entrante (0 o 1) se suma al dígito de unidades
                        c := bin_reg(N_BITS-1);

                        -- Dígito 0 (unidades): bits 3:0
                        tmp := ('0' & acc_bcd(3  downto  0)) + ('0' & acc_bcd(3  downto  0)) + ("0000" & c);
                        if tmp >= "01010" then n0 := tmp(3 downto 0) + "0110"; c := '1'; else n0 := tmp(3 downto 0); c := '0'; end if;

                        -- Dígito 1 (decenas): bits 7:4
                        tmp := ('0' & acc_bcd(7  downto  4)) + ('0' & acc_bcd(7  downto  4)) + ("0000" & c);
                        if tmp >= "01010" then n1 := tmp(3 downto 0) + "0110"; c := '1'; else n1 := tmp(3 downto 0); c := '0'; end if;

                        -- Dígito 2 (centenas): bits 11:8
                        tmp := ('0' & acc_bcd(11 downto  8)) + ('0' & acc_bcd(11 downto  8)) + ("0000" & c);
                        if tmp >= "01010" then n2 := tmp(3 downto 0) + "0110"; c := '1'; else n2 := tmp(3 downto 0); c := '0'; end if;

                        -- Dígito 3 (millares): bits 15:12
                        tmp := ('0' & acc_bcd(15 downto 12)) + ('0' & acc_bcd(15 downto 12)) + ("0000" & c);
                        if tmp >= "01010" then n3 := tmp(3 downto 0) + "0110"; c := '1'; else n3 := tmp(3 downto 0); c := '0'; end if;

                        -- Dígito 4 (decenas de millar): bits 19:16
                        tmp := ('0' & acc_bcd(19 downto 16)) + ('0' & acc_bcd(19 downto 16)) + ("0000" & c);
                        if tmp >= "01010" then n4 := tmp(3 downto 0) + "0110"; c := '1'; else n4 := tmp(3 downto 0); c := '0'; end if;

                        -- Dígito 5 (centenas de millar): bits 23:20
                        tmp := ('0' & acc_bcd(23 downto 20)) + ('0' & acc_bcd(23 downto 20)) + ("0000" & c);
                        if tmp >= "01010" then n5 := tmp(3 downto 0) + "0110"; c := '1'; else n5 := tmp(3 downto 0); c := '0'; end if;

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