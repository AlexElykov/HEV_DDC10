----------------------------------------------------------------------
-- Simple test-bench for simulating the performance of HEV firmware --
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
 
ENTITY test_bench_xenonnt IS
END test_bench_xenonnt;
 
ARCHITECTURE behavior OF test_bench_xenonnt IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT HEV_XENONnT
    PORT(
         CLK_BF : IN  std_logic;
         CLK_100MHZ : IN  std_logic;
         ADC_PCB_CLK : IN  std_logic;
         BF_PCB_CLK : IN  std_logic;
         DIP_SWITCH : IN  std_logic_vector(2 downto 0);
         NIM_IN : IN  std_logic_vector(3 downto 0);
         NIM_OUT : OUT  std_logic_vector(3 downto 0);
         LED : OUT  std_logic_vector(3 downto 0);
         LED_ADC_CLK : OUT  std_logic;
         LED_BF_CLK : OUT  std_logic;
         BF_PF1 : INOUT  std_logic;
         BF_AWE_b : IN  std_logic;
         BF_ARE_b : IN  std_logic;
         BF_AMS0_b : IN  std_logic;
         BF_AMS1_b : IN  std_logic;
         BF_DATA : INOUT  std_logic_vector(31 downto 0);  --INOUT
         BF_ADDR : IN  std_logic_vector(25 downto 1);
         BF_SPISEL_4 : IN  std_logic;
         BF_SPISEL_5 : IN  std_logic;
         XSPI_MISO : IN  std_logic;
         XSPI_MOSI : IN  std_logic;
         XSPI_CLK : IN  std_logic;
         XSPI_CS_B : IN  std_logic;
         UNUSED_MISO : IN  std_logic;
         UNUSED_MOSI : IN  std_logic;
         UNUSED_CLK : IN  std_logic;
         UNUSED_CS_B : IN  std_logic;
         AD0_A : IN  std_logic_vector(16 downto 0);
         AD0_B : IN  std_logic_vector(16 downto 0);
         AD1_A : IN  std_logic_vector(16 downto 0);
         AD1_B : IN  std_logic_vector(16 downto 0);
         AD2_A : IN  std_logic_vector(16 downto 0);
         AD2_B : IN  std_logic_vector(16 downto 0);
         AD3_A : IN  std_logic_vector(16 downto 0);
         AD3_B : IN  std_logic_vector(16 downto 0);
         AD4_A : IN  std_logic_vector(16 downto 0);
         AD4_B : IN  std_logic_vector(16 downto 0);
         TXDAC : IN  std_logic_vector(13 downto 0);
         TXDAC_CLK : IN  std_logic;
         TXDAC_RST : IN  std_logic;
         TXDAC_SDIO : IN  std_logic;
         TXDAC_SCK : IN  std_logic;
         TXDAC_CS_B : IN  std_logic;
         AD0_CS_B : IN  std_logic;
         AD1_CS_B : IN  std_logic;
         AD2_CS_B : IN  std_logic;
         AD3_CS_B : IN  std_logic;
         AD4_CS_B : IN  std_logic;
         ADC_SCK : IN  std_logic;
         ADC_SDIO : IN  std_logic;
         SDAC_SDI : IN  std_logic;
         SDAC_1_LOAD : IN  std_logic;
         SDAC_0_LOAD : IN  std_logic;
         SDAC_SCK : IN  std_logic;
         SDAC_PRESET_B : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK_BF : std_logic := '0';
   signal CLK_100MHZ : std_logic := '0';
   signal ADC_PCB_CLK : std_logic := '0';
   signal BF_PCB_CLK : std_logic := '0';
   signal DIP_SWITCH : std_logic_vector(2 downto 0) := (others => '0');
   signal NIM_IN : std_logic_vector(3 downto 0) := (others => '0');
   signal BF_AWE_b : std_logic := '0';
   signal BF_ARE_b : std_logic := '0';
   signal BF_AMS0_b : std_logic := '0';
   signal BF_AMS1_b : std_logic := '0';
   signal BF_ADDR : std_logic_vector(25 downto 1) := (others => '0');
   signal BF_SPISEL_4 : std_logic := '0';
   signal BF_SPISEL_5 : std_logic := '0';
   signal XSPI_MISO : std_logic := '0';
   signal XSPI_MOSI : std_logic := '0';
   signal XSPI_CLK : std_logic := '0';
   signal XSPI_CS_B : std_logic := '0';
   signal UNUSED_MISO : std_logic := '0';
   signal UNUSED_MOSI : std_logic := '0';
   signal UNUSED_CLK : std_logic := '0';
   signal UNUSED_CS_B : std_logic := '0';
   signal AD0_A : std_logic_vector(16 downto 0) := (others => '0');
   signal AD0_B : std_logic_vector(16 downto 0) := (others => '0');
   signal AD1_A : std_logic_vector(16 downto 0) := (others => '0');
   signal AD1_B : std_logic_vector(16 downto 0) := (others => '0');
   signal AD2_A : std_logic_vector(16 downto 0) := (others => '0');
   signal AD2_B : std_logic_vector(16 downto 0) := (others => '0');
   signal AD3_A : std_logic_vector(16 downto 0) := (others => '0');
   signal AD3_B : std_logic_vector(16 downto 0) := (others => '0');
   signal AD4_A : std_logic_vector(16 downto 0) := (others => '0');
   signal AD4_B : std_logic_vector(16 downto 0) := (others => '0');
   signal TXDAC : std_logic_vector(13 downto 0) := (others => '0');
   signal TXDAC_CLK : std_logic := '0';
   signal TXDAC_RST : std_logic := '0';
   signal TXDAC_SDIO : std_logic := '0';
   signal TXDAC_SCK : std_logic := '0';
   signal TXDAC_CS_B : std_logic := '0';
   signal AD0_CS_B : std_logic := '0';
   signal AD1_CS_B : std_logic := '0';
   signal AD2_CS_B : std_logic := '0';
   signal AD3_CS_B : std_logic := '0';
   signal AD4_CS_B : std_logic := '0';
   signal ADC_SCK : std_logic := '0';
   signal ADC_SDIO : std_logic := '0';
   signal SDAC_SDI : std_logic := '0';
   signal SDAC_1_LOAD : std_logic := '0';
   signal SDAC_0_LOAD : std_logic := '0';
   signal SDAC_SCK : std_logic := '0';
   signal SDAC_PRESET_B : std_logic := '0';

	--BiDirs
   signal BF_PF1 : std_logic;
   signal BF_DATA : std_logic_vector(31 downto 0);

 	--Outputs
   signal NIM_OUT : std_logic_vector(3 downto 0);
   signal LED : std_logic_vector(3 downto 0);
   signal LED_ADC_CLK : std_logic;
   signal LED_BF_CLK : std_logic;

   -- Clock period definitions
	-- check out BlackVME_ADC10chan.ucf
   constant CLK_BF_period : time := 8 ns;            
   constant CLK_100MHZ_period  : time := 10 ns;      
   constant ADC_PCB_CLK_period : time := 10 ns;
   constant BF_PCB_CLK_period  : time := 10 ns;
   constant LED_ADC_CLK_period : time := 10 ns;
   constant LED_BF_CLK_period : time := 10 ns;
   constant XSPI_CLK_period   : time := 10 ns;
   constant UNUSED_CLK_period : time := 10 ns;
   constant TXDAC_CLK_period  : time := 10 ns;
   
	-- Defining values for input simulation
	signal 	pattern	 			: std_logic_vector (16 downto 0) := (others =>'0');
	constant A				   	: real := 2500.0;
	constant B				  		: real := 800.0; 
	signal 	Pulse_Dist_rand 	: real := 8000.0;
	signal 	t			        	: real := -2000.0; 
	signal 	analog	        	: real;
	-- :=4000.0 ->14bit conversion, :=1000 ->12bit conversion := 32000 -> 17bit conversion
   constant scale	        		: real := 1.0;
	signal   scale_input	      : integer := 50;
	signal 	shift_rand 			: real := 2.0;
	signal 	t_rand 				: real := 2.0;
	constant C 						: real := 0.00005;
	
	-- Gaussian equation
	constant sig 					: real := 0.2;
	constant mu 					: real := 0.0;
	constant pi 					: real := MATH_PI;


BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: HEV_XENONnT PORT MAP (
          CLK_BF => CLK_BF,
          CLK_100MHZ => CLK_100MHZ,
          ADC_PCB_CLK => ADC_PCB_CLK,
          BF_PCB_CLK => BF_PCB_CLK,
          DIP_SWITCH => DIP_SWITCH,
          NIM_IN => NIM_IN,
          NIM_OUT => NIM_OUT,
          LED => LED,
          LED_ADC_CLK => LED_ADC_CLK,
          LED_BF_CLK => LED_BF_CLK,
          BF_PF1 => BF_PF1,
          BF_AWE_b => BF_AWE_b,
          BF_ARE_b => BF_ARE_b,
          BF_AMS0_b => BF_AMS0_b,
          BF_AMS1_b => BF_AMS1_b,
          BF_DATA => BF_DATA,
          BF_ADDR => BF_ADDR,
          BF_SPISEL_4 => BF_SPISEL_4,
          BF_SPISEL_5 => BF_SPISEL_5,
          XSPI_MISO => XSPI_MISO,
          XSPI_MOSI => XSPI_MOSI,
          XSPI_CLK => XSPI_CLK,
          XSPI_CS_B => XSPI_CS_B,
          UNUSED_MISO => UNUSED_MISO,
          UNUSED_MOSI => UNUSED_MOSI,
          UNUSED_CLK => UNUSED_CLK,
          UNUSED_CS_B => UNUSED_CS_B,
          AD0_A => AD0_A,
          AD0_B => AD0_B,
          AD1_A => AD1_A,
          AD1_B => AD1_B,
          AD2_A => AD2_A,
          AD2_B => AD2_B,
          AD3_A => AD3_A,
          AD3_B => AD3_B,
          AD4_A => AD4_A,
          AD4_B => AD4_B,
          TXDAC => TXDAC,
          TXDAC_CLK => TXDAC_CLK,
          TXDAC_RST => TXDAC_RST,
          TXDAC_SDIO => TXDAC_SDIO,
          TXDAC_SCK => TXDAC_SCK,
          TXDAC_CS_B => TXDAC_CS_B,
          AD0_CS_B => AD0_CS_B,
          AD1_CS_B => AD1_CS_B,
          AD2_CS_B => AD2_CS_B,
          AD3_CS_B => AD3_CS_B,
          AD4_CS_B => AD4_CS_B,
          ADC_SCK => ADC_SCK,
          ADC_SDIO => ADC_SDIO,
          SDAC_SDI => SDAC_SDI,
          SDAC_1_LOAD => SDAC_1_LOAD,
          SDAC_0_LOAD => SDAC_0_LOAD,
          SDAC_SCK => SDAC_SCK,
          SDAC_PRESET_B => SDAC_PRESET_B
        );
		  
		  
-- ###################################### --

   -- Clock process definitions
   CLK_BF_process :process
   begin
		CLK_BF <= '0';
		wait for CLK_BF_period/2;
		CLK_BF <= '1';
		wait for CLK_BF_period/2;
   end process;
 
   CLK_100MHZ_process :process
   begin
		CLK_100MHZ <= '0';
		wait for CLK_100MHZ_period/2;
		CLK_100MHZ <= '1';
		wait for CLK_100MHZ_period/2;
   end process;
 
   ADC_PCB_CLK_process :process
   begin
		ADC_PCB_CLK <= '0';
		wait for ADC_PCB_CLK_period/2;
		ADC_PCB_CLK <= '1';
		wait for ADC_PCB_CLK_period/2;
   end process;
 
   BF_PCB_CLK_process :process
   begin
		BF_PCB_CLK <= '0';
		wait for BF_PCB_CLK_period/2;
		BF_PCB_CLK <= '1';
		wait for BF_PCB_CLK_period/2;
   end process;
 
   LED_ADC_CLK_process :process
   begin
		LED_ADC_CLK <= '0';
		wait for LED_ADC_CLK_period/2;
		LED_ADC_CLK <= '1';
		wait for LED_ADC_CLK_period/2;
   end process;
 
   LED_BF_CLK_process :process
   begin
		LED_BF_CLK <= '0';
		wait for LED_BF_CLK_period/2;
		LED_BF_CLK <= '1';
		wait for LED_BF_CLK_period/2;
   end process;
   
 
-- ##### Input from user Function ####
-- Simulating analog pulses as input for the HEV ADC_IN
-- Using a Moyal function to mimic S1 or S2 shapes

-- Moyal distribution is a universal form for the energy loss by 
-- ionization for a fast charged particle and the number of 
-- ion pairs produced in this process.

--  	analog_pulses: process
--	begin
--		if t >= Pulse_Dist_rand then
--			t <= -2000.0; --100
--			wait for 50000 ns;
--		elsif t < -1999.0 then 
--		   wait for 500 ns;
--			t <= t + 0.01;
--		else
--			--analog <= -scale*( -A*2.0 * ( exp( -0.5 * ( (t)/(B) + exp(-(t)/(B))) ) ) ); 
--			--analog <= -scale*( -A*2.0 * ( exp( -0.5 * ( (t-0.5)/(B) + exp(-(t-0.5)/(B))) ) ) ); 
--			analog <= scale*( - shift_rand*A*3.0 * ( exp( -0.5 * ( (t+t_rand-5.0)/(B*0.691) + exp(-(t+t_rand-5.0)/(B*0.691))-1.0 ) ) ) )+ C * 0.0-0.2; 
--			t <= t + 0.01;
--		end if;
--		
--		wait for 0.01 ns;
--	end process;
--
--	process
--	begin
--		wait until rising_edge(ADC_PCB_CLK);  -- The design uses the ADC clock for most parts
--		--pattern <= std_logic_vector(to_unsigned(131072-integer(scale*(4.096+analog)),pattern'length));
--			pattern <= std_logic_vector(to_signed(integer((analog)),pattern'length));
--			AD0_A(16 downto 0) <= pattern(16 downto 0);
--	end process; 
	
	
	
-- ##### Input from File ####
-- Using "real" acquisition monitor peaks as input to the HEV simulation

	read_file: process is
	
		file file_in          : text open read_mode is "range_of_s2_widths.dat";
		variable row          : line;
		variable v_data_read  : integer :=0;
   
		begin	

		if(not endfile(file_in)) then
			readline(file_in, row);
			read(row, v_data_read);
			report "Val: " & integer'image(v_data_read);
			pattern <= std_logic_vector(to_signed(scale_input*v_data_read, pattern'length));
			AD0_A(16 downto 0) <= pattern(16 downto 0);
			AD0_B(16 downto 0) <= pattern(16 downto 0);
			AD1_A(16 downto 0) <= pattern(16 downto 0);
			AD1_B(16 downto 0) <= pattern(16 downto 0);
		end if;
   
		wait for ADC_PCB_CLK_period/2;
   end process;

-- ##### Output to File ####
-- Outputing some of the waves to a text file for further plotting
	file_dump : process(ADC_PCB_CLK)
	
		file output_file 	: text open write_mode is "output_waves.txt";
		variable row_out	: line;
		
		begin 
		if rising_edge(ADC_PCB_CLK) then
			-- incoming waveform	
			write(row_out, to_integer(signed(AD0_A)), right, 16);
			-- the final veto output NIMs
			hwrite(row_out, NIM_OUT, right, 6);		
			writeline(output_file, row_out);
		end if;
	end process file_dump;
	
END;