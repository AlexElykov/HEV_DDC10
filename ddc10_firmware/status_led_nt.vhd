-- Just a small component to output the veto decision about the rise time, 
-- width and integral to the front STATUS LEDs
-- 0 -> risetime
-- 1 -> width
-- 2 -> integral
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity STATUS_LED_COMPONENT is
	port (
	clk		      :	in std_logic;
	veto_pars    	:	in std_logic_vector(2 downto 0);
	LED_out     	:	out std_logic_vector(3 downto 0)
);

end STATUS_LED_COMPONENT;
architecture Behavioral of STATUS_LED_COMPONENT is

begin
	process (clk) begin
		if rising_edge (clk) then
			if veto_pars /= "000" then
				LED_out(0) <= veto_pars(0);
				LED_out(1) <= veto_pars(1);
				LED_out(2) <= veto_pars(2);
		   else
				LED_out(0) <= '0';
				LED_out(1) <= '0';
				LED_out(2) <= '0';
			end if;
		end if; -- CLK 
	end process;
end Behavioral;

