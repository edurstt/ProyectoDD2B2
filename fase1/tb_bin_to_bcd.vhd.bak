--------------------------------------------------------------------------------
-- Conversor Binario a BCD - Double Dabble correcto
-- Cada ciclo: (1) add-3 a nibbles >= 5, (2) shift izquierda del total
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
    -- Registro combinado: 24 bits BCD + N_BITS binario
    -- Durante CALC hacemos shift izquierda sobre los 24+N_BITS bits
    signal acc_bcd   : std_logic_vector(23 downto 0);
    signal bin_reg   : std_logic_vector(N_BITS-1 downto 0);
    signal bits_left : integer range 0 to N_BITS;
begin
    process(clk, nRst)
        variable n0,n1,n2,n3,n4,n5 : std_logic_vector(3 downto 0);
        variable bcd_adj : std_logic_vector(23 downto 0);
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

                        -- Add-3 a cada nibble BCD si >= 5
                        if acc_bcd(3 downto 0)   >= "0101" then n0 := acc_bcd(3 downto 0)   + "0011"; else n0 := acc_bcd(3 downto 0);   end if;
                        if acc_bcd(7 downto 4)   >= "0101" then n1 := acc_bcd(7 downto 4)   + "0011"; else n1 := acc_bcd(7 downto 4);   end if;
                        if acc_bcd(11 downto 8)  >= "0101" then n2 := acc_bcd(11 downto 8)  + "0011"; else n2 := acc_bcd(11 downto 8);  end if;
                        if acc_bcd(15 downto 12) >= "0101" then n3 := acc_bcd(15 downto 12) + "0011"; else n3 := acc_bcd(15 downto 12); end if;
                        if acc_bcd(19 downto 16) >= "0101" then n4 := acc_bcd(19 downto 16) + "0011"; else n4 := acc_bcd(19 downto 16); end if;
                        if acc_bcd(23 downto 20) >= "0101" then n5 := acc_bcd(23 downto 20) + "0011"; else n5 := acc_bcd(23 downto 20); end if;

                        -- Vector ajustado completo de 24 bits
                        bcd_adj := n5 & n4 & n3 & n2 & n1 & n0;

                        -- Shift izquierda 1: MSB de bin_reg entra en LSB de bcd_adj
                        acc_bcd <= bcd_adj(22 downto 0) & bin_reg(N_BITS-1);

                        -- Shift izquierda del registro binario
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