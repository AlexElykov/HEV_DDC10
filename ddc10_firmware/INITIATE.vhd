-- This component takes care of initiating the parameters whenever the class
--	Initialize.c in the module is called by the DDC10 class in the DAQ software. 
--
-- In XENONnT DAQ the DDC10 class (DDC10.cc, DDC10.hh) is incorporated 
-- in to the REDAX software: https://github.com/AxFoundation/redax
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- DON'T USE these two libraries below :P use use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all; 

entity INITIATE_COMPONENT is
	port (
		CLK_ADC  			 : in std_logic;
		initiate 			 : in std_logic;
		output_b 			 : in std_logic_vector(15 downto 0);
		enable_b 			 : out std_logic;
		MemAddr_ctr 		 : inout std_logic_vector(12 downto 0);
		-- High Energy Veto parameters from the ini file in REDAX
		signal_sign			 : out std_logic;
		int_window			 : out std_logic_vector(15 downto 0);
		veto_delay			 : out std_logic_vector(15 downto 0);
		signal_threshold	 : out std_logic_vector(15 downto 0);
		int_threshold		 : out std_logic_vector(31 downto 0); 
		width_cut			 : out std_logic_vector(15 downto 0);
		risetime_cut		 : out std_logic_vector(15 downto 0);
		component_selector : out std_logic_vector(15 downto 0);
		PreScaling         : out std_logic_vector(15 downto 0);
			
		static_veto_duration  : out std_logic_vector(15 downto 0);
		dynamic_veto_limit    : out std_logic_vector(15 downto 0);
		
		rho_0 				 	 : out std_logic_vector(63 downto 0);
		rho_1 				 	 : out std_logic_vector(63 downto 0);
		rho_2     			    : out std_logic_vector(63 downto 0);
		rho_3     			    : out std_logic_vector(63 downto 0)

	);
end INITIATE_COMPONENT;


architecture Behavioral of INITIATE_COMPONENT is
	type parameter_type is array (28 downto 0) OF std_logic_vector (15 DOWNTO 0);
	signal do_initiation : std_logic :='0';
	signal parameter  	: parameter_type; 
	signal counter 		: integer range 0 to 4096 :=0;
	signal address			: std_logic_vector(12 downto 0);

begin
	process (CLK_ADC) begin

		if rising_edge (CLK_ADC) then
			-- At the launch of the HEV we make a sudo reset
			if initiate = '1' and do_initiation = '0' then
				do_initiation <= '1';
				MemAddr_ctr <= (others => '0');
				enable_b <= '1';
				counter <= 0;
			end if;
			
			-- Addressing the BRAM from the FPGA side via MemAddr_ctr, using the counter to step through the memory range
			if do_initiation = '1' then
            MemAddr_ctr <= MemAddr_ctr + 1; 
				counter <= counter + 1;
				-- BRAM needs one clk cycle to initialise, therefore parameter(counter) coresponds to parameter(counter -1)
				-- the assigned values are then 
				parameter(counter) <= output_b; 
				
            -- Change to 29 when using on real board!
				if counter = 29 then
					do_initiation <= '0';
					enable_b <= '0';
					MemAddr_ctr <= (others => '0');
					
--					-- '0' for negative input, '1' for positive
					if parameter(1) = "0000000000000000" then
						signal_sign <= '0';
					else
						signal_sign <= '1';
					end if;
					
					-- ### Just for testing ### ---
					-- Cause I'm too lazy to make a proper simulation ini
					-- INITIATE.vhd
					-- 1. Change counter to 28 for simulation
					-- 2. Uncomment input signals
					-- CTRL_reg_CPU_writes.vhd
					-- 1. Uncomment test process
					-- 2. Comment regout signal
					
--					signal_sign 			<= '0';
--					int_window       		<= conv_std_logic_vector(300, int_window'length);       -- 300 --80
--					veto_delay       		<= conv_std_logic_vector(400, veto_delay'length);       -- 400 --20
--					signal_threshold 		<= conv_std_logic_vector(10, signal_threshold'length); -- 200 --25
--					int_threshold    		<= conv_std_logic_vector(1000, int_threshold'length); -- 450000 --30
--					width_cut        		<= conv_std_logic_vector(25, width_cut'length);    -- 30       --3
--					risetime_cut     		<= conv_std_logic_vector(5, risetime_cut'length); -- 30       --4
--					component_selector 	<= conv_std_logic_vector(23, component_selector'length); -- 6  --7
-- 				   PreScaling    	   	<= conv_std_logic_vector(0, PreScaling'length);    -- 100     --0
--
--					rho_0 <= conv_std_logic_vector(20, rho_0'length); 
--					rho_1 <= conv_std_logic_vector(20, rho_1'length); 
--					rho_2 <= conv_std_logic_vector(20, rho_2'length); 
--					rho_3 <= conv_std_logic_vector(20, rho_3'length); 
--
--					-- was inner ring factor
--					dynamic_veto_limit     <= conv_std_logic_vector(57, dynamic_veto_limit'length); -- 10ms -- 4000000
--					-- was outer ring factor
--					static_veto_duration   <= conv_std_logic_vector(56, static_veto_duration'length);   --20

					-- ######################### --
					int_window						 <= parameter(2);
					veto_delay						 <= parameter(3);
					signal_threshold				 <= parameter(4);
					int_threshold(31 downto 16) <= parameter(5);
					int_threshold(15 downto 0)	 <= parameter(6);
					width_cut						 <= parameter(7);
					risetime_cut					 <= parameter(8);
					component_selector 			 <= parameter(9);
					
					rho_0(63 downto 48)	       <= parameter(10);
					rho_0(47 downto 32)         <= parameter(11);
					rho_0(31 downto 16)         <= parameter(12);
					rho_0(15 downto 0)          <= parameter(13);
					rho_1(63 downto 48)	       <= parameter(14);
					rho_1(47 downto 32)         <= parameter(15);
					rho_1(31 downto 16)         <= parameter(16);
					rho_1(15 downto 0)          <= parameter(17);
					rho_2(63 downto 48)			 <= parameter(18);
					rho_2(47 downto 32)			 <= parameter(19);
					rho_2(31 downto 16)			 <= parameter(20);
					rho_2(15 downto 0) 			 <= parameter(21);
					rho_3(63 downto 48)			 <= parameter(22);
					rho_3(47 downto 32)			 <= parameter(23);
					rho_3(31 downto 16)			 <= parameter(24);
					rho_3(15 downto 0)			 <= parameter(25);
					
					static_veto_duration        <= parameter(26); 
					dynamic_veto_limit          <= parameter(27);			
					PreScaling						 <= parameter(28);
				end if;
			end if;-- do initialization
		end if; -- CLK 
	end process;	
	--parameter(0) contains nothing (waiting for BRAM)
end Behavioral;
