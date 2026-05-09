

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl_tec is
generic(
    TICS_2s : natural := 10
   );
port(clk:     	    in std_logic;
     nRst:    	    in std_logic;
     tic:     	    in std_logic; -- UTILIZAR SEÑAL TIC DE 5ms para muestrear y rebotes
     columna: 	    in std_logic_vector(3 downto 0);
     fila:    	    buffer std_logic_vector(3 downto 0);
     tecla_pulsada: buffer std_logic;
     tecla: 	    buffer std_logic_vector(3 downto 0);
     pulso_largo:   buffer std_logic
     );
end entity;

architecture rtl of ctrl_tec is
signal cnt_tic_2s: std_logic_vector(8 downto 0);
--constant TICS_2s: natural := 10;

signal col_reb: std_logic_vector(3 downto 0);
signal col_ok: std_logic_vector(3 downto 0);

signal ctrl_tecla_pulsada: std_logic;

signal ena_muestreo: std_logic;

signal pulso_hab_tecla:	  std_logic;
signal pulso_hab_largo:	  std_logic;

signal tecla_aux: std_logic_vector(3 downto 0);
begin

-- PROCESO PARA CONTAR TICS DE 5MS Y OBTENER UN TIC DE 2S PARA PULSO LARGO
process(clk, nRst)    
  begin
   if nRst = '0' then 
     cnt_tic_2s <= (others => '0');
     pulso_largo <= '0'; --nuevo
   elsif clk'event and clk = '1' then
     if tic = '1' then
      if ctrl_tecla_pulsada = '0' then
        cnt_tic_2s <= (others => '0');
        pulso_largo <= '0';--nuevo

       elsif cnt_tic_2s <= TICS_2s and col_ok /= X"F" then
         cnt_tic_2s <= cnt_tic_2s +1;  
         -- nuevo
         -- Activamos el registro de forma síncrona al llegar al límite
         if cnt_tic_2s = TICS_2s then
           pulso_largo <= '1';
         end if;   

       end if;
     end if;
    end if;   
end process;


-- PROCESO PARA SEÑAL COLUMNAS SIN REBOTES
process(clk, nRst)    
  begin
   if nRst = '0' then 
     col_reb <= (others => '1');
     col_ok <= (others => '1');
   elsif clk'event and clk = '1' then        
	col_reb <= columna;
        if tic = '1' then
	  col_ok <= col_reb; 
        end if;
   end if;
end process;


-- PROCESO PARA OBTENER EN TECLA PULSADA LA ANCHURA DE UN CICLO DE RELOJ DEL SISTEMA (CONFORMADOR)
process(clk, nRst)    
  begin
   if nRst = '0' then 
     pulso_hab_tecla <= '0';
   elsif clk'event and clk = '1' then
     pulso_hab_tecla <= ctrl_tecla_pulsada;
   end if;
end process;

-- PROCESO PARA SABER SI LA PULSACION ES LARGA Y NO ACTIVAR TECLA_PULSADA
process(clk, nRst)    
  begin
   if nRst = '0' then 
     pulso_hab_largo <= '0';
   elsif clk'event and clk = '1' then
     pulso_hab_largo <= pulso_largo;
   end if;
end process;

ena_muestreo <= '0' when col_reb /=X"F" else -- PARAMOS MUESTREO CON COLUMNAS CON REBOTES PARA DETECTAR LA PULSACION DE FORMA INMEDIATA
	        '1' ;

ctrl_tecla_pulsada <= '1' when col_ok /=X"F" else -- SEGNAL UTILIZADA PARA CONFORMAR TECLA PULSADA CON COLUMNAS LIBRE DE REBOTES
		'0';

tecla_pulsada <= '1' when pulso_hab_tecla = '1' and ctrl_tecla_pulsada = '0' and pulso_hab_largo = '0' else
             '0';

--pulso_largo <= '1' when ctrl_tecla_pulsada = '1' and cnt_tic_2s >TICS_2s else
--	     '0';


-- PROCESO PARA MUESTREAR LAS FILAS
 process(clk, nRst)    
  begin
   if nRst = '0' then 
     fila <= (others => '1');
   elsif clk'event and clk = '1' then
    if tic = '1' then
      if ena_muestreo = '1' then
        if fila = X"F" then
           fila <= "1110";
        else
            fila(3 downto 0) <= fila(2 downto 0) & fila(3);           
       end if;
      end if;
    end if;
   end if;
end process;



-- PROCESO PARA OBTENER QUE TECLA SE HA PULSADO... DECODIFICADOR
 process(clk, nRst)    
  begin
   if nRst = '0' then 
     tecla_aux <= (others => '0');--Cambio de X a 0
   elsif clk'event and clk = '1' then       
      if fila = "1110" and col_ok = "1110" then   
        tecla_aux <= X"1";
      elsif  fila = "1110" and col_ok ="1101" then
	tecla_aux <= X"2"; 
      elsif fila = "1110" and col_ok = "1011" then
	 tecla_aux <= X"3";
      elsif fila = "1110" and col_ok = "0111" then
	 tecla_aux <= X"F";
      elsif  fila = "1101"  and col_ok = "1110" then
	tecla_aux <= X"4";
      elsif fila = "1101" and col_ok = "1101" then
	 tecla_aux <= X"5";
      elsif fila = "1101"  and col_ok = "1011" then
	 tecla_aux <= X"6";
      elsif fila = "1101" and col_ok = "0111" then
	tecla_aux <= X"E";
      elsif fila = "1011" and col_ok = "1110" then
	tecla_aux <= X"7";
      elsif  fila = "1011"  and col_ok = "1101" then
	tecla_aux <= X"8";
      elsif  fila = "1011"and col_ok = "1011" then
	tecla_aux <= X"9";
      elsif fila ="1011"  and col_ok = "0111" then
	 tecla_aux <= X"D";
      elsif fila = "0111"  and col_ok = "1110" then
	 tecla_aux <= X"A";
      elsif fila = "0111"  and col_ok = "1101" then
	 tecla_aux <= X"0";
      elsif fila = "0111" and col_ok = "1011" then
	 tecla_aux <= X"B";
      elsif fila = "0111" and col_ok = "0111" then
	 tecla_aux <= X"C";
     -- elsif col_ok = "1111" then
      --   tecla_aux <= (others => '0');  --Cambio x por 0
      end if;
    end if;
end process;

---- CARGAMOS EL VALOR DE TECLA CUANDO TECLA_PULSADA = '1' OR PULSO_LARGO = '1'
--tecla <= tecla_aux when tecla_pulsada = '1' else
--	 tecla_aux when pulso_largo = '1' else
-- 	 "XXXX";
-- PROCESO PARA REGISTRAR EL VALOR DE LA TECLA (ELIMINA LINEAS ROJAS)
process(clk, nRst)
begin
  if nRst = '0' then
    tecla <= (others => '0'); -- Valor inicial limpio (evita la 'X' al arrancar)
  elsif clk'event and clk = '1' then
    -- Solo actualizamos el registro cuando hay una pulsación detectada
    --if tecla_pulsada = '1' or pulso_largo = '1' then
--      tecla <= tecla_aux;
--    end if;
    -- Al no poner un 'else', el valor anterior se mantiene por sí solo
    if (pulso_hab_tecla = '1' and ctrl_tecla_pulsada = '0' and pulso_hab_largo = '0') or (pulso_largo = '1') then
      tecla <= tecla_aux;
    end if;
  end if;
end process;

end rtl;
    