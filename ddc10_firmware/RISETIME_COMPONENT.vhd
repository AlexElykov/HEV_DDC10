-- This component calculates the rise time of the peak. The output of the risetime
--	is updated continuously. Maybe this has to be changed in order to take into account
--	second peaks, that appear within the veto delay.
--
-- If the maximum time for risetime calculation was exceeded and no risetime was found
-- the component outputs a signal indicating that we probably see a very wide S2 
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity RISETIME_COMPONENT is
	port (
	clk				: in std_logic;								-- ADC clock
	baseline_ok		: in std_logic;
	ADC				: in std_logic_vector(15 downto 0);
	signal_threshold 		: in std_logic_vector(15 downto 0);
	risetime_overflow 	: out std_logic;
	risetime			: out integer range 0 to 1000
);
end RISETIME_COMPONENT;

architecture Behavioral of RISETIME_COMPONENT is
signal peak_on : std_logic := '0';
signal rise_time_over_f : std_logic := '0';

signal maximum   : std_logic_vector(15 downto 0);
signal counter   : integer range 0 to 1000;
signal max_count : integer := 500;
 
begin
	process (clk) begin
		if rising_edge (clk) then
			risetime_overflow <= rise_time_over_f;
		
			if "abs"(signed(ADC)) > "abs"(signed(signal_threshold)) and peak_on = '0' then 
				maximum <= ADC;
				counter <= 1; 
				peak_on <= '1';
			end if;
			if "abs"(signed(ADC)) < "abs"(signed(signal_threshold)) then
			-- Don't reset counter and risetime when peak goes below signal threshold
			-- because we need this information when width and integral are calculated!
			-- which might be slightly after the signal drops below the threshold.
			--	risetime <= 0;
			   peak_on <= '0';
				counter <= 0; 
				rise_time_over_f <= '0';
				
			end if;

			if peak_on = '1' and counter < max_count then
				counter <= counter + 1;
				if "abs"(signed(ADC)) > "abs"(signed(maximum)) then
					maximum <= ADC;
					risetime <= counter;
				end if;
			elsif peak_on = '1' and counter = max_count then
				rise_time_over_f <= '1';
				counter <= max_count; 
			end if;
		end if; -- CLK if end 
	end process;
	
end Behavioral;

