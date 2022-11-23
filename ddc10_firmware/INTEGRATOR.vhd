-- Integration component, performs a continuous integration of the input ADC 
-- signal in a rolling window of user defined length.
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity INTEGRATOR is
	port (
	clk				  : in  std_logic;							  -- ADC clock
	int_window		  : in  integer range -1 to 8000;  		  -- maximum integration time is 8 us
	ADC				  : in  std_logic_vector(15 downto 0);   -- Input from the ADC == XENONnT sum of top PMT array
	signal_threshold : in std_logic_vector(15 downto 0);
	integral		     : out std_logic_vector(23 downto 0) := (others => '0')
	);
end INTEGRATOR;

architecture Behavioral of INTEGRATOR is
	type ADC_MemBuffer is array (1000 downto 0) of std_logic_vector (15 downto 0); -- Buffer for ADC samples
	
	-- Setting initial values for the buffer vectors and signals
	signal adc_buffer : ADC_MemBuffer := (others => "0000000000000000"); 
	signal sum 			: std_logic_vector (23 downto 0):= (others => '0');
	signal counter 	: integer range 0 to 1000 := 0;
	signal enable 		: std_logic := '0'; 

begin
	process (clk) begin	
		if rising_edge (clk) then			
		-- Making sure that the integration begins only after the int_window was set to some proper value
		-- and that vector 0 at the adc_buffer array is set to 0 and not to 'U' or 'X', especially at the transition
		-- between int_window 0 -> set_value
			if int_window  /= 0 then    
				enable <= '1'; 
			end if;
			
			-- Starting the integration	
			if enable = '1' then
				if counter = int_window then 
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
				-- Continuous integration with a window size equivalent to the one set in int_window
				-- Note: at the verge when the counter converts back to 0 after reaching the int_window value the 
				-- following will be seen: sum < = sum  + ADC - adc_buffer(0)
				-- where adc_buffer(0) is the 0th array from buffer that was filled in the previous inegration cycle of int_window length.
				-- This is because the adc_buffer(0) <= ADC in the line above will be updated only for the next clk cycle.			
				-- sum <= sum + ADC - adc_buffer(counter);
				-- integral <= sum + ADC - adc_buffer(counter);	

				adc_buffer(counter) <= ADC;
				sum <= std_logic_vector(signed(sum) + signed(ADC) - signed(adc_buffer(counter)));
				integral <= std_logic_vector(signed(sum) + signed(ADC) - signed(adc_buffer(counter)));
			end if;
		 end if; --clk
	end process;
end Behavioral;

