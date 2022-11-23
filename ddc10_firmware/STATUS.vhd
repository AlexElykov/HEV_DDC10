-- This small component is used to read back the user settings and
-- the obtained baseline value via the get_status.c class
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity STATUS_COMPONENT is
	PORT (
		CLK_ADC				: in std_logic;
		get_status 			: in std_logic;
		input_b 				: out std_logic_vector(15 downto 0);
		enable_b 			: out std_logic;
		wrenable_b 			: out std_logic_vector(0 downto 0);
		MemAddr_ctr 		: inout std_logic_vector (12 downto 0);
		-- parameters
		signal_sign			: in std_logic;
		width_cut			: in integer range 0 to 1000;
		risetime_cut		: in integer range 0 to 500;
		int_window			: in integer range 0 to 50000;
		veto_delay			: in integer range 0 to 1000;
		signal_threshold		 : in std_logic_vector(15 downto 0);
		int_threshold		 	 : in std_logic_vector(31 downto 0);
		rho_3                 : in std_logic_vector(63 downto 0);
		rho_2 					 : in std_logic_vector(63 downto 0);  
		rho_1 					 : in std_logic_vector(63 downto 0);  
		rho_0 					 : in std_logic_vector(63 downto 0);
		component_selector	 : in std_logic_vector(15 downto 0);
		PreScaling				 : in std_logic_vector(15 downto 0);
		baseline					 : in std_logic_vector(15 downto 0);
		--adc_to_out				 : in std_logic_vector(15 downto 0);
		static_veto_duration  : in std_logic_vector(15 downto 0);
		dynamic_veto_limit 	 : in std_logic_vector(15 downto 0) 
	);
end STATUS_COMPONENT;


architecture Behavioral of STATUS_COMPONENT is

type parameter_type is array (29 downto 0) OF std_logic_vector (15 downto 0);

signal do_status 	: std_logic :='0';
signal parameter	: parameter_type; 
signal counter 	: integer range 0 to 4096 :=0;
signal address		: std_logic_vector(12 downto 0);

begin	
	
	process (CLK_ADC) begin
		if rising_edge (CLK_ADC) then			
			if signal_sign = '0' then
				parameter(0)<=(others => '0');
			else
				parameter(0)<="0000000000000001";
			end if;	
			parameter(1)  <=	conv_std_logic_vector(int_window, 16);
			parameter(2)  <=	conv_std_logic_vector(veto_delay, 16);
			parameter(3)  <=	signal_threshold;
			parameter(4)  <=	int_threshold(31 downto 16);
			parameter(5)  <=	int_threshold(15 downto 0);
			parameter(6)  <=	conv_std_logic_vector(width_cut, 16);
			parameter(7)  <=	conv_std_logic_vector(risetime_cut, 16);
			parameter(8)  <=	ext(component_selector, 16);

			parameter(9)  <= rho_0(63 downto 48);
			parameter(10) <= rho_0(47 downto 32);
			parameter(11) <= rho_0(31 downto 16);
			parameter(12) <= rho_0(15 downto 0);
			parameter(13) <= rho_1(63 downto 48);
			parameter(14) <= rho_1(47 downto 32);
			parameter(15) <= rho_1(31 downto 16);
			parameter(16) <= rho_1(15 downto 0);
			parameter(17) <= rho_2(63 downto 48);
			parameter(18) <= rho_2(47 downto 32);
			parameter(19) <= rho_2(31 downto 16);
			parameter(20) <= rho_2(15 downto 0);
			parameter(21) <= rho_3(63 downto 48);
			parameter(22) <= rho_3(47 downto 32);
			parameter(23) <= rho_3(31 downto 16);
			parameter(24) <= rho_3(15 downto 0);

			parameter(25) <= static_veto_duration;
			parameter(26) <= dynamic_veto_limit;
			parameter(27) <= PreScaling;
			parameter(28) <= baseline;
			--parameter(29) <= adc_to_out;

			
			if get_status = '1' and do_status = '0' then
				do_status	<=	'1';
				MemAddr_ctr	<=	(others => '0');
				enable_b		<=	'1';
				wrenable_b	<=	"1";
				counter		<=	1;
				input_b		<=	parameter(0);
			end if;
			
			if do_status = '1' then
				MemAddr_ctr	<=	MemAddr_ctr + 1;
				counter	<=	counter + 1;
				input_b	<=	parameter(counter); 
				-- BRAM needs one clk cycle, therefore parameter(counter) coresponds to parameter(counter -1)
				if counter = 29 then --29
					do_status	<='0';
					enable_b		<='0';
					wrenable_b	<="0";
					MemAddr_ctr	<=	(others => '0');
				end if;
			end if;
			
		end if; -- CLK 
	end process;
	
	--parameter(0) contains nothing (waiting for BRAM)
--	<slv_sig> = CONV_STD_LOGIC_VECTOR(<int_sig>, <integer_size>);

end Behavioral;
