-- At the moment the speed of the WIDTH COMPONENT is not maximised. Could be improved by 
--	calculating the peak position and start with the search for left_edge at this time, 
--	not after right_edge has been found.
--
-- If the maximum time for width calculation was exceeded and no width was found
-- the component outputs a signal indicating that we probably see a very wide S2 
-----------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity WIDTH_COMPONENT is
	port (
		clk					: in std_logic;								-- ADC clock
		baseline_ok			: in std_logic;
		peak_start			: in std_logic;
		ADC					: in std_logic_vector(15 downto 0);
		signal_threshold	: in std_logic_vector(15 downto 0);
		width_overflow    : out std_logic;
		width					: out integer range 0 to 1000
	);
end WIDTH_COMPONENT;

architecture Behavioral of WIDTH_COMPONENT is
TYPE ADC_MemBuffer IS ARRAY (1000 downto 0) OF std_logic_vector (15 DOWNTO 0); -- Buffer for ADC samples
	signal adc_buffer 	: ADC_MemBuffer := (others => "0000000000000000");

	signal maximum 		: std_logic_vector(15 downto 0);
	signal half_maximum 	: std_logic_vector(14 downto 0);
	signal counter 		: integer range 0 to 1000;
	signal right_edge 	: integer range 0 to 1000 := 1;
	signal right_ok 		: std_logic := '1';
	signal left_ok 		: std_logic := '1';
	signal width_temp 	: integer range 0 to 1000 := 0;
	signal send_width 	: std_logic :='0';
	signal width_over_f  : std_logic := '0';
	signal max_count     : integer := 500;


begin
	--threshold <= to_integer(unsigned(signal_threshold));
	process (clk) begin
		if rising_edge (clk) then
		
		width_overflow <= width_over_f;
		
			if baseline_ok = '0' then
				left_ok <= '1';
				right_ok <= '1';
				counter <= 0;
				width_over_f <= '0';
			end if;
		
			if baseline_ok = '1' then	
				-- peak went above threshold
				if "abs"(signed(ADC)) > "abs"(signed(signal_threshold)) and left_ok = '1' and right_ok = '1' and width_over_f = '0' then 
					maximum <= ADC;
					half_maximum <= ADC(15 downto 1);
					adc_buffer(counter) <= ADC; 
					counter <= counter + 1; -- set counter to 1
					right_edge <= 0;				
					right_ok <= '0';
					left_ok <= '0';
					send_width <= '0';
					width <= 0;
				-- width too big and cannot be determined and peak still above thr
				-- so don't try to calculate things till its back to normal again
				elsif "abs"(signed(ADC)) > "abs"(signed(signal_threshold)) and width_over_f = '1' then
					width <= max_count;
					left_ok <= '1';
				   right_ok <= '1';
				-- wide peak ended get back to work and reset the values
				elsif "abs"(signed(ADC)) < "abs"(signed(signal_threshold)) and width_over_f = '1' then
					width_over_f <= '0';	
					counter <= 0;
					maximum <= (others => '0');
					half_maximum <= (others => '0');				
				end if;
								
				
				-- Get right edge, and don't try to find it again if we know that the peak is too wide
				--------------------------------
				if left_ok = '0' and right_ok = '0' and width_over_f = '0' then 
					adc_buffer(counter) <= ADC;
					-- Finding maximum of peak
					if "abs"(signed(ADC)) > "abs"(signed(maximum)) then
						maximum <= ADC;
						half_maximum <= ADC(15 downto 1);
					end if;
					
					-- input ADC went below half_max, meaning that we found the right edge of peak
					if "abs"(signed(ADC)) < "abs"(signed(half_maximum)) and right_ok = '0' then
						right_edge <= counter;
						right_ok <= '1';
						counter <= 0;
						-- reached max counter and didn't find the right edge (peak too wide)
					elsif counter = max_count then
						width_over_f <= '1';
						counter <= max_count;
					else
						counter <= counter + 1;
					end if;
				end if; 
				--------------------------------
					
				-- Get left edge
				-- count through the buffer we just populated to find when half max was bigger 
				-- than the input ADC on the left side of the waveform
			   --------------------------------
				if left_ok = '0' and right_ok = '1' then
					-- negative peaks
						if "abs"(signed(adc_buffer(counter))) > "abs"(signed(half_maximum)) then
							--left_edge<=counter;
							left_ok <= '1';
							send_width<='1';
							-- 
							-- There is a problem with small and very narrow pulses. 
							-- Somehow 'right_edge' gets smaller then left_edge (i.e. counter), therefore width
							-- gets negative an jumps to ~512. 
							-- Since this happens only for small and narrow pulses the width is artificially set to 1 sample
							-- for these cases.
							-- The reason for this bug is not found yet.
							--
							if (right_edge - counter) < 0 then
								width_temp <= 1;
							else
								width_temp <= right_edge - counter;
							end if;
							counter <= 0;
						else 
							counter <= counter + 1;
						end if;				
				end if;
			   --------------------------------

				--width should be zero unless a new width has been found					
				if send_width = '1' then
					width <= width_temp;
					send_width <= '0';
				end if;
				
				if send_width = '0' then
					width <= 0;
				end if;
				
			end if; -- baseline_ok
		end if; -- CLK 
	end process;

end Behavioral;

