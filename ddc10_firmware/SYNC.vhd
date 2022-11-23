-- Metastability:  
-- Synchronizing an external signal to an internal clock
-- Before using the incoming signal from the ADC we need to make sure that it is synchronised to 
-- the internal FPGA clock we do this by using a clocked circuit with flip-flops, 
-- which delays the incoming signal by several clock cycles before furhter use.

-- Note: A proper debouncer was not implemented, 
-- didn't really exist in the XENON1T version despite being named debouncer -_-

-- The input ADC channel 0 in the ucf file defined as 0_16 bits, while in principle the 
-- ADC signal should be a 14 bit one. Hence, below not only we delay the signal by several 
-- clock cycles but we also can read only 14 bits of the 17 bit input, 
-- and extend the resulting logic vector of bits to the conventional 16 bit format by padding the MSB with 0.
-------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SYNC is
	port (
	clk	:	in  std_logic;				
	ADC_0	:	in  std_logic_vector(16 downto 0); 
	ADC_1	:	in  std_logic_vector(16 downto 0); 
	ADC_2	:	in  std_logic_vector(16 downto 0); 
	ADC_3	:	in  std_logic_vector(16 downto 0); 
	ADC_out	:  out std_logic_vector(15 downto 0)
	); 	
end SYNC;

architecture Behavioral of SYNC is
	-- The ADC chips on the board are 14bit
	signal Q1, Q2, Q3 : std_logic_vector(13 downto 0) := (others => '0');
	signal ADC_in : std_logic_vector(16 downto 0) := (others => '0');
	
begin
	process (clk) begin
		if rising_edge (clk) then
			-- Can use 4 inputs and sum up them here, if a bigger vector is needed as output for ADC_in can do
			-- answer <= resize(std_vec_1, answer'length) + resize(std_vec_2, answer'length);

			-- ADC_in <= std_logic_vector(unsigned(ADC_0) + unsigned(ADC_1) + unsigned(ADC_2) + unsigned(ADC_3));
			-- I guess besides removing the MSB (overflow bit), the 2 LSB bits could be also removed to divide by 4
			-- Q1 <= std_logic_vector(shift_right(unsigned(ADC_in), 2));
			
			Q1      <= ADC_0(15 downto 2); -- ADC_0(13 downto 0) doesn't seem to work irl
			Q2 	  <= Q1;
			Q3 	  <= Q2;
			ADC_out <= std_logic_vector(resize(unsigned(Q3), ADC_out'length));			
		end if; 
	end process;
end Behavioral;

