-- This component collects the information about the peaks and makes the final veto decision

-- Two veto option can be initialized by the user:
-- A. Wide s2 veto: Deals with very wide S2s that exceed the max time for 
-- risetime or width calculation
--
-- B. Standard veto: Deals with standard S2s (S1s), whose risetime
-- and width could be calculated
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VETO_COMPONENT is
	port (
	clk						 : in std_logic;
	ADC_in					 : in std_logic_vector(15 downto 0);
	component_selector	 : in std_logic_vector(15 downto 0);
	signal_threshold		 : in std_logic_vector(15 downto 0);
	threshold				 : in std_logic_vector(31 downto 0); 	-- threshold of integral cut
	integral					 : in std_logic_vector(23 downto 0);
	PreScaling				 : in std_logic_vector(15 downto 0);
	
	width_cut				 : in integer range 0 to 1000;
	risetime_cut			 : in integer range 0 to 500;
	IntWindow				 : in integer range 0 to 8000;
	width						 : in integer range 0 to 1000;
	risetime					 : in integer range 0 to 1000;
	veto_delay				 : in integer range 0 to 1000;
	rise_time_ex		    : in std_logic;
	width_ex 				 : in std_logic;
	rho_3                 : in std_logic_vector(63 downto 0);
	rho_2 					 : in std_logic_vector(63 downto 0);
	rho_1 					 : in std_logic_vector(63 downto 0);
	rho_0 					 : in std_logic_vector(63 downto 0);

  	static_veto_duration  : in std_logic_vector(15 downto 0);
	dynamic_veto_limit    : in std_logic_vector(15 downto 0);
		
	--ADC_out					 : out std_logic_vector(15 downto 0);
	veto_verdict			 : out std_logic_vector(2 downto 0);
	veto						 : out std_logic;
	start_peak				 : out std_logic;
	start_veto				 : out std_logic
	);
end VETO_COMPONENT;

architecture Behavioral of VETO_COMPONENT is

-- Input 16 bit ns time, conversion to us
signal us_conversion 			  : integer range 0 to 10000 := 0;

----------------------------------------------------------------------
-- "Wide" veto for dealing with wide S2s
----------------------------------------------------------------------
signal Signal_wr 	    			  : std_logic_vector(1 downto 0) := "00";
signal Signal_rr 	    			  : std_logic_vector(1 downto 0) := "00";
signal wide_veto_start 	    	  : std_logic := '0';
signal wide_veto 					  : std_logic := '0';
signal PreScaleCounter_w		  : integer range 0 to 1100000000 := 0;
signal counter_wide_v			  : integer range 0 to 1100000000 := 0;
signal wide_veto_duration 		  : std_logic := '0';
signal wide_peak_on		 		  : std_logic := '0';
signal ADC_wide_out				  : std_logic_vector(15 downto 0) := (others => '0');


----------------------------------------------------------------------
-- "Std" veto for dealing with nrmal S2s and S1s
----------------------------------------------------------------------
-- General signals                                       
signal peak_on 					  : std_logic := '0';
signal veto_start				  	  : std_logic := '0';
signal veto_OK 					  : std_logic := '0';
signal PreScaleCounter 			  : integer range 0 to 1100000000 := 0;
signal veto_length 				  : integer range 0 to 1100000000 := 0;
signal ADC_std_out				  : std_logic_vector(15 downto 0) := (others => '0');

-- Parameters for peaks
signal integral_scaled 		 	  : std_logic_vector(13 downto 0);
signal delay_counter 			  : integer range 0 to 1100 := 1100;
signal get_delay 				  	  : std_logic := '1';

-- Veto_decision:  bit 2 = integral, bit 1 = width, bit 0 = risetime
signal veto_decision 			  : std_logic_vector(2 downto 0) := "000"; 
signal width_ready 				  : std_logic := '0';

-- Polynomial signals
signal r_temp_sum 				  : std_logic_vector(87 downto 0);
signal res_temp0 				 	  : integer range 0 to 1100000000 := 0;
signal r_prod2 					  : std_logic_vector(87 downto 0);
signal r_count 					  : integer range 0 to 500 := 0;
signal r_prod1			  			  : std_logic_vector(135 downto 0);
signal r_length					  : std_logic_vector(135 downto 0);
signal temp_integral 			  : std_logic_vector (47 downto 0);
signal temp_integral_0 			  : std_logic_vector (47 downto 0);
signal std_veto 					  : std_logic := '0';
signal counter_std_v				  : integer range 0 to 1100000000 := 0;


begin
	-- Adjusting conversion factor so we would have a ns resultion for ~200ns wide S1s
	-- and us resolution for >>20us wide S2s
	us_conversion <= 1 when component_selector(3) = '0' else
					  1000 when component_selector(3) = '1' else 0;
						
	----------------------------------------------------------------------------------
	-- HEV needs to deal with very wide peaks
	-- If the rise time or the width could not be calculated due to the excessively large
	-- width of the peak, issue a veto of fixed length
	wide_S2_veto : process(clk) begin
	
		if rising_edge (clk) then
		-- Check if in wide hev mode
			if component_selector(5) = '1' then 
				-- This comparison needs to be signed as unsigned means that the signal will be only positive.
				-- and the FPGA will use Two's Complement representation for it i.e. 
				-- -1 == "1111111111111111" == 65535
				if "abs"(signed(ADC_in)) > "abs"(signed(signal_threshold)) then
					wide_peak_on<='1';
					ADC_wide_out <= ADC_in;
				else				
					wide_peak_on <= '0';
				end if;
			
				-- No need for signal > threshold check, as risetime & width counter components activation means signal > threshold
				Signal_wr <= Signal_wr(0) & width_ex;
				Signal_rr <= Signal_rr(0) & rise_time_ex;

				-- Check if the wide regime triggered by excess of width or risetime counters
				if Signal_wr = "01" or Signal_rr = "01" then
					-- Check if we need to pass the peak due to prescale selection or veto it
					if PreScaleCounter_w < to_integer(unsigned(PreScaling))-1  or to_integer(unsigned(PreScaling)) = 0 then
						PreScaleCounter_w <= PreScaleCounter_w + 1;
						wide_veto_start <= '1';
						wide_veto_duration <= '1';
						counter_wide_v <= 0;
					-- If counter = prescale_indx, pass the peak
					elsif PreScaleCounter_w >= to_integer(unsigned(PreScaling))-1 then
						PreScaleCounter_w <= 0;
						wide_veto_start <= '0';
						wide_veto_duration <= '0';
					end if;
				else
					wide_veto_start <= '0';						
				end if;
			
				-- Issue veto for set time length duration
				if wide_veto_duration = '1' then 
					if counter_wide_v < to_integer(unsigned(static_veto_duration(15 downto 0))) * us_conversion then
						wide_veto <= '1';
						counter_wide_v <= counter_wide_v + 1; 				
					elsif counter_wide_v = to_integer(unsigned(static_veto_duration(15 downto 0))) * us_conversion then
						wide_veto <= '0';
						wide_veto_duration <= '0';
					else
						wide_veto <= '0';
						wide_veto_duration <= '0';
					end if;
				end if;
				
			else 
				wide_peak_on <= '0';
			end if; -- end check if in wide hev mode
			
			if component_selector(5 downto 0) ="000000" then 
				wide_veto <= '0';
			end if;
		end if;	--end clk
		
	end process wide_S2_veto;	



	----------------------------------------------------------------------------------
	-- Normal HEV operation mode			
	-- Find peaks that exceed pre-defined thresholds in risetime, width and interal and
	-- issue a fixed length veto or a veto that was calculated based on the size of the
	-- peak
	he_veto : process(clk) begin
	
		if rising_edge (clk) then		
			-- check if signal is above threshold	
			if component_selector(4) = '1' then 
		  
				if "abs"(signed(ADC_in)) > "abs"(signed(signal_threshold)) then
					peak_on<='1';
					ADC_std_out <= ADC_in;
				else				
					peak_on <= '0';
					ADC_std_out <= (others => '0');
				end if;
			
				-- get width 
				if "abs"(signed(ADC_in)) > "abs"(signed(signal_threshold)) and peak_on = '0' and get_delay = '1' then
					delay_counter  <= 0;
					get_delay 	<= '0';
					width_ready 	<= '1';
				end if;

				-- get peak width and risetime whenever a new peak width is found
				if width > 0 then
					if width_ready = '1' then
						width_ready <= '0';
					
						if width > width_cut then
							veto_decision(1) <= '1';
						else 
							veto_decision(1) <= '0';
						end if;
						
						if risetime > risetime_cut then
							veto_decision(0) <= '1';
						else 
							veto_decision(0) <= '0';
						end if;
					end if;
				end if;			
			
				-- delay veto decision
				if delay_counter < (veto_delay + 1) then 
					delay_counter <= delay_counter + 1;
					-- get the integral of the detected signal
					if "abs"(signed(integral)) > "abs"(signed(threshold)) then
						veto_decision(2) <= '1'; -- abs integral value is above integral threshold => integral cut condidtion fullfiled 
					end if;
				end if;

				-- Start veto after delay 
				if delay_counter = veto_delay then
					-- veto decision: risetime and integral are coupled via logic and (if components are on)
					if (component_selector(0) <= veto_decision(0) and component_selector(1) <= veto_decision(1) and
						component_selector(2) <= veto_decision(2) and component_selector(2 downto 0)/="000") then 
					
						veto_start <= '1';
						-- prescale the vetoed pulses allowing only each Nth pulse to pass based on prescale condition
						if PreScaleCounter < to_integer(unsigned(PreScaling))-1 or to_integer(unsigned(PreScaling)) = 0 then
							PreScaleCounter <= PreScaleCounter + 1;
							veto_OK <= '1';
						end if;
						if PreScaleCounter >= to_integer(unsigned(PreScaling))-1 then
							PreScaleCounter <= 0;						
						end if;
					end if;
				end if;
			
			
				if delay_counter = (veto_delay + 1) then 
					delay_counter    <= 1000;
					veto_start 	  	  <= '0';
					veto_decision    <= "000";
					res_temp0 		  <= 0;
					integral_scaled  <= (others => '0');
					get_delay 	     <= '1';
					width_ready 	  <= '0';
				end if;

--   		If all the conditions for veto are met, we calculate the veto length based on a 			
--			second order polynomial calculation
--			Using a simplfication of the form: f(x) = a_0 + (a_1 + a_2*x)*x
				if (component_selector(0) <= veto_decision(0) and component_selector(1) <= veto_decision(1) and
						component_selector(2) <= veto_decision(2)and component_selector(2 downto 0)/="000") then 
					if r_count >= 4 then
						r_prod2		  	 <= (others => '0');
						r_temp_sum    	 <= (others => '0');
						r_prod1		  	 <= (others => '0');
						temp_integral 	 <= (others => '0');
						temp_integral_0 <= (others => '0');
					else
						r_count 		  	 <= r_count + 1; 										
						temp_integral_0 <= std_logic_vector(resize(unsigned(integral), temp_integral_0'length));
						temp_integral	 <= temp_integral_0;
						-- the a_2*x part
						r_prod2         <= std_logic_vector(unsigned(unsigned(rho_2)) * unsigned(integral));	
						-- the a_1 + a_2*x part
						r_temp_sum    	 <= std_logic_vector(unsigned(rho_1) + unsigned(r_prod2));
						-- the x*x part
						r_prod1         <= std_logic_vector(unsigned(temp_integral) * unsigned(r_temp_sum));
						-- the a_0 + (result) part
						r_length        <= std_logic_vector(unsigned(rho_0) + unsigned(r_prod1));					
					end if;
				else 
					r_prod2		  	 <= (others => '0');
					r_temp_sum    	 <= (others => '0');
					r_prod1		  	 <= (others => '0');
					temp_integral 	 <= (others => '0');
					temp_integral_0 <= (others => '0');
					r_length      	 <= (others => '0');
					r_count         <= 0;				
				end if;
				-- Output calculated veto length to be used for veto duration
				-- if it is too big we would have to use only 29 bits for the int!
				res_temp0 <= to_integer(unsigned(r_length(28 downto 0)));
		
				-- Veto_OK waits for veto_start in order to initiate the veto always at the same time
				if veto_OK = '1' then
					counter_std_v <= 0;
					veto_OK <= '0';
					-- if no user defined veto set dynamic veto length to the result of the polynomial calculation
					if to_integer(unsigned(static_veto_duration(15 downto 0))) = 0 and res_temp0 > 0 then
						veto_length <= res_temp0;
					-- if static veto length is set by user, use it instead
					elsif to_integer(unsigned(static_veto_duration(15 downto 0))) > 0 then
						veto_length <= to_integer(unsigned(static_veto_duration(15 downto 0))) * us_conversion;
					else 
						veto_length <= 0;
					end if;
				end if;

				-- The veto is active up to its maximum length or until it reaches a predefined max duration
				-- This is done to avoid extremely long vetos and subsequently abnormal deadtimes 			
				if counter_std_v < veto_length and counter_std_v < to_integer(unsigned(dynamic_veto_limit(15 downto 0))) * us_conversion then 
					std_veto <= '1';
					-- if veto length is larger than maximum of counter, counter will wrap around
					counter_std_v <= counter_std_v + 1; 
				elsif counter_std_v = veto_length then
					std_veto <= '0';
				else
					std_veto <= '0';
				end if;	
			else 
				ADC_std_out <= (others => '0'); 
			end if; --check if in normal hev mode
			
			if component_selector(5 downto 0) ="000000" then 
				std_veto <= '0';		
			end if;
			
		end if;	--end clk				
	end process he_veto;	
	
	-- Just a test output to see when the signal goes above thr. ADCc
	--ADC_out <= ADC_wide_out or ADC_std_out;
	
	-- Output some usefule monitoring signals 
	veto <= wide_veto or std_veto; 						-- NIM OUT 0,1
	veto_verdict <= veto_decision; 						-- LED OUT 0,1,2
	start_peak   <= peak_on or wide_peak_on;			-- NIM OUT 2
	start_veto   <= veto_start or wide_veto_start;	-- NIM OUT 3

end Behavioral;
