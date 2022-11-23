-- Calculates baseline based on the average of 64 adc samples (640ns).
--	The component returns the value of the average (baseline) as well as a 
-- control signal, that the baseline has been calculated.
-- If there are no dark counts, it takes about 1 us to get the baseline
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity BLINE is
	port (
	clk			:	in std_logic;									-- ADC clock
	getBline		:	in std_logic;
	initiate 	:  in std_logic;
	signal_sign	:	in std_logic;
	ADC_in		:	in std_logic_vector(15 downto 0); 	   -- signal input
	ADC_out		:	out std_logic_vector(15 downto 0);		-- signal output (baseline corrected if available)
	baseline		:	out std_logic_vector(15 downto 0);
	baseline_ok	:	out std_logic := '0'
);
end BLINE;

architecture Behavioral of BLINE is

signal sum 		: std_logic_vector(21 downto 0) := (others => '0');
signal average : std_logic_vector(15 downto 0) := (others => '0');
signal counter : integer range 0 to 64 := 0;
signal sum_ok	: std_logic := '0';
signal baseline_done : std_logic := '0';
signal temp_adc1 : std_logic_vector(15 downto 0) := (others => '0');
signal temp_adc2 : std_logic_vector(15 downto 0) := (others => '0');
signal temp_adc3 : std_logic_vector(15 downto 0) := (others => '0');

begin

	process (clk) begin
		if rising_edge (clk) then
		-- Get baseline if requested by user or when initiate hev
			if getBline = '1' or initiate = '1' then
				counter <= 0;
				sum_ok <= '0';
				baseline_done <= '0';
				average <=(others => '0');
				sum <=(others => '0');
			end if;
		
			if sum_ok = '0' and counter < 64 then 
				-- set counter to zero if there is a signal
				if ADC_in < temp_adc3 then
					if (temp_adc3 - ADC_in) > 100 then
						counter <= 0;
						temp_adc1 <= ADC_in;
						temp_adc2 <= temp_adc1;
						temp_adc3 <= temp_adc2;
						sum <=(others => '0');
					else 
						counter <= counter + 1;
						sum <= sum + ADC_in;
						temp_adc1 <= ADC_in;
						temp_adc2 <= temp_adc1;
						temp_adc3 <= temp_adc2;
					end if;
				end if; -- ADC_in < temp_adc
				
				if ADC_in >= temp_adc3 then
					if (ADC_in - temp_adc3) > 100 then
						counter <= 0;
						temp_adc1 <= ADC_in;
						temp_adc2 <= temp_adc1;
						temp_adc3 <= temp_adc2;
						sum <= (others => '0');
					else 
						counter <= counter + 1;
						sum <= sum + ADC_in;
						temp_adc1 <= ADC_in;
						temp_adc2 <= temp_adc1;
						temp_adc3 <= temp_adc2;
					end if;
				end if; -- ADC_in >= temp_adc
			end if; -- get baseline
			
			if counter = 64 then
				sum_ok <= '1';
			end if;
			
			-- division by 64 not very elaborated yet (seems OK)
			IF sum_ok = '1' and baseline_done = '0' then
				baseline_done <= '1';
				if sum(5) = '0' then 
					average <= sum(21 downto 6); -- round off
				else
					average <= sum(21 downto 6) + "0000000000000001"; -- round up
				end if;
			end if;

			
			-- substract baseline, if available and invert signal if it is posivive (signal_sign = '1')
			if signal_sign = '0' then
				if baseline_done = '1' then
					ADC_out <= ADC_in - average; -- - average; 
					baseline <= average;
					baseline_ok <= '1';
				else
					ADC_out <= ADC_in;
					baseline <=(others=>'0');
					baseline_ok <= '0';
				end if;
			end if;
			
			-- invert signal if it is positive (signal_sign = '1')
			if signal_sign = '1' then
				if baseline_done = '1' then
					ADC_out <=(not ADC_in) + average + 1; -- - average; 
					baseline <= average;
					baseline_ok <= '1';
				else
					ADC_out <= (not ADC_in) + 1;
					baseline <=(others=>'0');
					baseline_ok <= '0';
				end if;
			end if;	
		end if; -- CLK 
	end process;	
	

end Behavioral;

