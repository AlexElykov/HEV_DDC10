---------------------------------------------------------------
-- Firmware for the XENONnT HEV module based on Skutek DDC10 --
---------------------------------------------------------------
-- Author : A. Elykov (alexey.elykov@physik.uni-freiburg.de) --
---------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all; 

entity HEV_XENONnT is

port (
   CLK_BF		: in 	 std_logic;  							-- clock from BF microprocessor (120 MHz)
	CLK_100MHZ	: in 	 std_logic;  							-- Main clock 100 MHz.
	ADC_PCB_CLK : in 	 std_logic;  							-- 10 ns HIGH 50 %;  # ADC 100 MHz
	BF_PCB_CLK 	: in 	 std_logic;								-- 8 ns HIGH 50 %;  # specified as 125 MHz
	DIP_SWITCH	: in   std_logic_vector(2 downto 0);	-- DIP switch, lowest three
	NIM_IN      : in   std_logic_vector(3 downto 0);	-- NIM inputs
	NIM_OUT     : out  std_logic_vector(3 downto 0) := "0000";	-- NIM outputs	
	LED         : out  std_logic_vector(3 downto 0) := "0000";	-- Front panel LED's
	LED_ADC_CLK	: out  std_logic := '0'; 					-- Diag: connect to ADC PLL lock (not front panel)
	LED_BF_CLK	: out  std_logic := '0'; 					-- Diag: connect to BF  PLL lock (not front panel)
	
	-- One general-purpose GPIO pin between the FPGA and the BF processor
	BF_PF1	   : inout  std_logic;							-- Blackfin PF1 / SPISEL_1 / TMR1
	-- FPGA is connected as BF external memory
	-- Memory strobes are active LOW (marked with suffix "_b" after the names)
	BF_AWE_b		: in std_logic;								-- write strobe,  AWE#
	BF_ARE_b		: in std_logic;								-- read strobe,   ARE#
	BF_AMS0_b	: in std_logic;								-- AMS0: asynch bank 0 0x2000 0000
	BF_AMS1_b	: in std_logic;								-- AMS1: asynch bank 1 0x2400 0000


	-- When BF memory is configured in 32-bit mode then ADDR(1) is not needed
	-- All BF addresses are on the 4-byte grid (i.e., 32-bit).
	-- When BF memory is configured in 16-bit mode then ADDR(1) is defined in UCF.
	-- All BF addresses are on the 2-byte grid (i.e., 16-bit).

	-- AMS0 and AMS1 can be be independently configured 16 or 32 bits.
	-- BF_DATA should be "inout", but for testing it is declared it "in"
	BF_DATA	: inout 	std_logic_vector(31 downto 0); 	-- BF data bus     inout
	BF_ADDR	: in	std_logic_vector(25 downto 1); 	 	-- BF addr bus
	
	-- The input ADC channels for the sum of the bottom PMT array in XENONnT 
	-- actual ADC chips are 14 bit but input is 16
	AD0_A : in   std_logic_vector(16 downto 0);
	AD1_A : in   std_logic_vector(16 downto 0);
	AD2_A : in   std_logic_vector(16 downto 0);
	AD3_A : in   std_logic_vector(16 downto 0);
   
	-- -------------------------------------------------------------------------------------------------------- 
	-- Below is a bunch of stuff that was defined in the ucf file but have no real use in the XENONnT HEV logic 
	-- SPI  on the main board  --
	BF_SPISEL_4 : in std_logic; -- BF_PF4 --> ADC  chips
	BF_SPISEL_5 : in std_logic; -- BF_PF5 --> ADC  chips
	XSPI_MISO   : in std_logic;
	XSPI_MOSI   : in std_logic;
	XSPI_CLK    : in std_logic;
	XSPI_CS_B   : in std_logic;
	UNUSED_MISO : in std_logic;
	UNUSED_MOSI : in std_logic;
	UNUSED_CLK  : in std_logic;
	UNUSED_CS_B : in std_logic;

	-- Non used ADC channel connections
	AD0_B : in   std_logic_vector(16 downto 0);
	AD1_B : in   std_logic_vector(16 downto 0);
	AD2_B : in   std_logic_vector(16 downto 0);
	AD3_B : in   std_logic_vector(16 downto 0);
	AD4_A : in   std_logic_vector(16 downto 0);
	AD4_B : in   std_logic_vector(16 downto 0);

	-- connection to DAC
	TXDAC         : in std_logic_vector(13 downto 0);
	TXDAC_CLK     : in std_logic; -- digital synthesis TxDAC clock
	TXDAC_RST     : in std_logic; -- TxDAC reset / pin mode
	TXDAC_SDIO    : in std_logic; -- TXDAC SPI data
	TXDAC_SCK     : in std_logic; -- TXDAX SPI clock
	TXDAC_CS_B    : in std_logic; 
	AD0_CS_B      : in std_logic;
	AD1_CS_B      : in std_logic;
	AD2_CS_B      : in std_logic;
	AD3_CS_B      : in std_logic;
	AD4_CS_B      : in std_logic;
	ADC_SCK       : in std_logic;
	ADC_SDIO      : in std_logic;
	SDAC_SDI      : in std_logic; --SDAC SPI data to SDAC
	SDAC_1_LOAD   : in std_logic;
	SDAC_0_LOAD   : in STD_LOGIC;
	SDAC_SCK      : in STD_LOGIC;
	SDAC_PRESET_B : in std_logic -- preset both SDACs
	-- -------------------------------------------------------------------------------------------------------- 
  );
 
 
end HEV_XENONnT;
architecture Behavioral of HEV_XENONnT is

type BF_MemBus_t is array (3 downto 0) OF std_logic_vector (31 DOWNTO 0);

--########## COMPONENTS ##########
----------- BRAM -----------
-- The BRAM is addressed from 2 sides both from the the Blackfin processor side and from the FPGA side
-- FPGA side: 8k 16-bit samples. BF side: 4k 32-bit words
component BRAM
	port (
	-- PORT A, BF processor side	
	clka		: in std_logic;								-- BF clock
	ena		: in std_logic;								-- read enable tied to MemSelect(...)
	wea		: in std_logic_vector(0 downto 0);		-- write enable
	addra		: in std_logic_vector(11 downto 0);		-- BF_ADDR(13 downto 2) meaning (13 : 2) = 12 bits, (2^12=4k)   
	dina		: in std_logic_vector(31 downto 0);		-- BF processor writes to this signal with 
																	-- BF_DATA(31 downto 0) used to store initialisation 
	douta		: 	out std_logic_vector(31 downto 0);	-- connected to the Multiplexer
	-- PORT B, FPGA side
	-- The signals marked with "_b" are active-low signals from the processor and they are converted to 
	-- active-high ones before being used by the FPGA 
	clkb		: in std_logic;								-- ADC_PCB_CLK
	enb		: in std_logic;								-- 
	web		: in std_logic_vector(0 downto 0);		-- create own write enable
	addrb		: in std_logic_vector(12 downto 0);		-- create own addr, (12 : 0) = 13 bits (2^13=8k)
	dinb		: in std_logic_vector(15 downto 0);		--
	doutb		: out std_logic_vector(15 downto 0)		--  
	);
end component;

-- Synplicity black box declaration
attribute syn_black_box 			: boolean;
attribute syn_black_box of BRAM	: component is true;


----------- CONTROL REGISTER -----------
-- Intended to control the circuitry in the FPGA via the CPU i.e. it
-- allows the Blackfin processor to toggle several control bits inside the FPGA
component CTRL_reg_CPU_writes
	generic (regWdt : integer := 16);
	port (
		CLK		: in std_logic;
		CS			: in std_logic;
		WR			: in std_logic;
		RD			: in std_logic;
		IOBUS		: inout std_logic_vector (regWdt-1 downto 0); --inout
		regout	: out std_logic_vector (regWdt-1 downto 0)
	);
end component;

----------- INITIATE COMPONENT -----------
-- Allows to set the parameters for the XENONnT HEV
component INITIATE_COMPONENT
	port (
		CLK_ADC			    : in std_logic;
		initiate 		    : in std_logic;
		output_b 	   	 : in std_logic_vector(15 downto 0);
		enable_b 		    : out std_logic;
		MemAddr_ctr 	  	 : inout std_logic_vector(12 downto 0);
		-- HEV specific parameters
		signal_sign			 	 : out std_logic;
		int_window			 	 : out std_logic_vector(15 downto 0);
		veto_delay			 	 : out std_logic_vector(15 downto 0);
		signal_threshold	 	 : out std_logic_vector(15 downto 0);
		int_threshold		 	 : out std_logic_vector(31 downto 0); 
		width_cut		    	 : out std_logic_vector(15 downto 0);
		risetime_cut		 	 : out std_logic_vector(15 downto 0);
		component_selector 	 : out std_logic_vector(15 downto 0);
		rho_3 				 	 : out std_logic_vector(63 downto 0);
		rho_2 				 	 : out std_logic_vector(63 downto 0);
		rho_1 				 	 : out std_logic_vector(63 downto 0);
		rho_0 				 	 : out std_logic_vector(63 downto 0);			
		static_veto_duration  : out std_logic_vector(15 downto 0); 
		dynamic_veto_limit    : out std_logic_vector(15 downto 0); 
		PreScaling 		    	 : out std_logic_vector(15 downto 0)
	);
end component;


----------- GET VETO STATUS COMPONENT -----------
component STATUS_COMPONENT
	port (
		CLK_ADC			    : in std_logic;
		get_status			 : in std_logic;
		input_b				 : out std_logic_vector(15 downto 0);
		enable_b 			 : out std_logic;
		wrenable_b 			 : out std_logic_vector(0 downto 0);
		MemAddr_ctr 		 : inout std_logic_vector(12 downto 0);
		-- parameter
		signal_sign			 : in std_logic;
		int_window			 : in integer range 0 to 50000 := 100;
		veto_delay			 : in integer range 0 to 1000 := 400;
		signal_threshold   : in std_logic_vector(15 downto 0);
		int_threshold		 : in std_logic_vector (31 downto 0);
		width_cut		    : in integer range 0 to 500;
		risetime_cut		 : in integer range 0 to 500;
		component_selector : in std_logic_vector(15 downto 0);
		PreScaling			    : in std_logic_vector(15 downto 0);		
		rho_3                : in std_logic_vector(63 downto 0);  
		rho_2 					 : in std_logic_vector(63 downto 0);
		rho_1 					 : in std_logic_vector(63 downto 0);
		rho_0 				    	: in std_logic_vector(63 downto 0);
		--adc_to_out				   : in std_logic_vector(15 downto 0);
		baseline				      : in std_logic_vector(15 downto 0);
		static_veto_duration    : in std_logic_vector(15 downto 0);
		dynamic_veto_limit      : in std_logic_vector(15 downto 0)
	);
end component;

------------- SYNCHRONIZATION COMPONENT ---------
component SYNC
	port (
		clk		: in std_logic;								-- ADC clock
		ADC_0	: in std_logic_vector(16 downto 0);
		ADC_1	: in std_logic_vector(16 downto 0);
		ADC_2	: in std_logic_vector(16 downto 0);
		ADC_3	: in std_logic_vector(16 downto 0);
		ADC_out	: out std_logic_vector(15 downto 0)
	);
end component;

----------- BASELINE COMPONENT ---------
component BLINE
	port (
		clk				: in std_logic;								-- ADC clock
		getBline			: in std_logic;
		initiate 		: in std_logic;
		signal_sign		: in std_logic;
		ADC_in			: in std_logic_vector(15 downto 0);
		ADC_out			: out std_logic_vector(15 downto 0);
		baseline			: out std_logic_vector(15 downto 0);
		baseline_ok		: out std_logic
	);
end component;

----------- PEAK INFO COMPONENT ---------
component PEAK_INFO_COMPONENT
	port (
		clk					: in std_logic;
		ADC_All				: in std_logic_vector(15 downto 0);
		GetBLine				: in std_logic;
		Initiate				: in std_logic;
		Baseline				: in std_logic_vector(15 downto 0);
		BaselineOK			: in std_logic;	
		SignalSign			: in std_logic;
		IntWindow			: in integer range 0 to 8000;
		SignalThreshold	: in std_logic_vector(15 downto 0);
		PeakStart			: in std_logic;
		PeakIntegral		: out std_logic_vector(23 downto 0);
		PeakWidth			: out integer range 0 to 1000;
		Width_limit			: out std_logic;
		Risetime_limit		: out std_logic;
		PeakRiseTime		: out integer range 0 to 1000
	);
end component;


----------- VETO COMPONENT ---------
component VETO_COMPONENT
	port (
		clk						: in std_logic;
		veto_delay				: in integer range 0 to 1000;
		ADC_in					: in std_logic_vector(15 downto 0);
		component_selector	: in std_logic_vector(15 downto 0);
		width_cut				: in integer range 0 to 1000;
		risetime_cut			: in integer range 0 to 500;
		signal_threshold		: in std_logic_vector(15 downto 0);
		threshold				: in std_logic_vector(31 downto 0);
		IntWindow				: in integer range 0 to 8000;
		integral					: in std_logic_vector(23 downto 0);
		width						: in integer range 0 to 1000;
		risetime					: in integer range 0 to 1000;
		rise_time_ex			: in std_logic;
		width_ex 				: in std_logic;
		PreScaling				: in std_logic_vector(15 downto 0);	
		rho_3                 : in std_logic_vector(63 downto 0);  
		rho_2 					 : in std_logic_vector(63 downto 0);  
		rho_1 					 : in std_logic_vector(63 downto 0);  
		rho_0 					 : in std_logic_vector(63 downto 0);
		static_veto_duration  : in std_logic_vector(15 downto 0);
		dynamic_veto_limit    : in std_logic_vector(15 downto 0);
		--ADC_out  				 : out std_logic_vector(15 downto 0);
		veto_verdict			 : out std_logic_vector(2 downto 0);		
		veto						 : out std_logic;
		start_peak				 : out std_logic;
		start_veto				 : out std_logic
	);
end component;


component STATUS_LED_COMPONENT
	port (
	clk				: in  std_logic;
	veto_pars    	: in  std_logic_vector(2 downto 0);
	LED_out			: out std_logic_vector(3 downto 0)
);
end component;


--########## SIGNALS ##########
-- BRAM signals
signal BF_AMS1, BF_AMS0 	 	  : std_logic; 						-- BF is using AMS0 or AMS1
signal BF_WR, BF_RD 			 	  : std_logic;							-- BF is reading/writing
signal BF_rena0, BF_rena1   	  : std_logic; 						-- read enable for AMS0/AMS1
signal BF_WRENA0, BF_WRENA1     : std_logic; 						-- write enable for AMS0/AMS1
signal BF_WRENA0_v, BF_WRENA1_v : std_logic_vector(0 downto 0); 
signal MemSelect 					  : std_logic_vector(3 downto 0); 
signal MemorySpace0 				  : std_logic_vector(31 downto 0);

signal MemAddr_ctr  : std_logic_vector (12 downto 0); 			-- declaration 4k*32 bit words
signal input_b 	  : std_logic_vector(15 downto 0); 
signal output_b 	  : std_logic_vector(15 downto 0);  			
signal wrenable_b   : std_logic_vector(0 downto 0):="0";
signal enable_b 	  : std_logic :='0';
signal BF_MemBus 	  : BF_MemBus_t; 										-- array of BF memory outputs, 32 bits each.

signal enableB 	: std_logic :='0';
signal wenableB 	: std_logic :='0';
signal addrB 		: std_logic_vector (12 downto 0);
signal fpga_in 	: std_logic_vector (15 downto 0);
signal fpga_out 	: std_logic_vector (15 downto 0);

-- CONTROL REGISTER
signal RegSelect   : std_logic_vector (3 downto 0);
signal RawSelect 	 : std_logic_vector (3 downto 0);
signal BF_ctrl_Reg : std_logic_vector(15 downto 0);

-- INITIATE 
signal initiate 			: std_logic := '0';  
signal address_initiate : std_logic_vector(12 downto 0);
signal enable_initiate  : std_logic;

-- GET STATUS
signal get_status 	 : std_logic := '0';
signal address_status : std_logic_vector(12 downto 0);
signal enable_status  : std_logic;

-- RECORDER signals
signal get_event : std_logic :='0';
signal get_background : std_logic := '0';
signal q1, q2, q3, adc_deb : std_logic_vector (15 downto 0);

-- SYNCHRONIZATION
signal adc0_16 :  std_logic_vector(15 downto 0) := (others => '0');

-- BASELINE
signal baseline 		 : std_logic_vector(15 downto 0);
signal get_baseline   : std_logic :='0';
signal baseline_ok	 : std_logic;
signal baseline_error : std_logic;
signal adc0_16_corr   : std_logic_vector(15 downto 0);

-- INTEGRAL
signal integrated_sig : std_logic_vector(23 downto 0);

-- WIDTH
signal peak_width : integer range 0 to 1000;
signal width_l    : std_logic;

-- RISE TIME
signal peak_risetime : integer range 0 to 1000;
signal risetime_l    : std_logic;

-- VETO
signal veto_out 				: std_logic;
signal start_veto 			: std_logic;
signal start_peak 			: std_logic;
signal veto_verdict        : std_logic_vector (2 downto 0);
signal adc_out				  	: std_logic_vector (15 downto 0);

-- Signals for converting input from control file
signal int_window					: integer range 0 to 50000 := 100;
signal veto_delay					: integer range 0 to 1000 := 400;
signal width_cut 					: integer range 0 to 1000;
signal risetime_cut 				: integer range 0 to 500;	

signal signal_sign 				: std_logic;
signal component_selector  	: std_logic_vector (15 downto 0);
signal int_threshold          : std_logic_vector(31 downto 0) :=(others => '0');
signal PreScaling 				: std_logic_vector(15 downto 0);
signal signal_threshold     	: std_logic_vector(15 downto 0);

signal int_window_vec 			: std_logic_vector(15 downto 0);
signal veto_delay_vec 			: std_logic_vector(15 downto 0);
signal width_cut_vec 			: std_logic_vector(15 downto 0);
signal risetime_cut_vec 		: std_logic_vector(15 downto 0);
signal component_selector_vec : std_logic_vector(15 downto 0);
signal signal_threshold_vec 	: std_logic_vector(15 downto 0);
signal dynamic_veto_limit   	: std_logic_vector(15 downto 0);
signal static_veto_duration   : std_logic_vector(15 downto 0); 
signal rho_3 					   : std_logic_vector(63 downto 0); 
signal rho_2 					   : std_logic_vector(63 downto 0);
signal rho_1 					   : std_logic_vector(63 downto 0); 
signal rho_0 					   : std_logic_vector(63 downto 0);
--signal adc_to_out 				: std_logic_vector(15 downto 0);

-- Just a simple test LED
signal LED_out  : std_logic_vector(3 downto 0);

--########## INSTANTIATE THE COMPONENTS ##########
-----------------------------------

begin
-- Change active low into active high signals
	BF_AMS0	<= not BF_AMS0_b;
	BF_AMS1	<= not BF_AMS1_b;
	BF_WR		<= not BF_AWE_b;
	BF_RD		<= not BF_ARE_b;

-- Logic for 'enable' signals
	BF_rena0			<= BF_AMS0 and BF_RD and (not BF_WR);
	BF_rena1			<= BF_AMS1 and BF_RD and (not BF_WR);
	BF_WRENA0		<= BF_AMS0 and BF_WR and (not BF_RD);
	BF_WRENA1		<= BF_AMS1 and BF_WR and (not BF_RD);
	BF_WRENA0_v(0) <= BF_WRENA0;

-- One can find a bit more information about the BF BRAM address use in the Chapter_F1_FPGA_Intro.pdf of the manual
-- Address decoder AMS0
	MemSelect <=																		-- result addr
	"0001" when BF_AMS0& BF_ADDR (25 downto 14)="1000000000000" else	-- 0x20000000
	"0010" when BF_AMS0& BF_ADDR (25 downto 14)="1000001000000" else	-- 0x20100000
	"0010" when BF_AMS0& BF_ADDR (25 downto 14)="1000001000000" else	-- 0x20100000
	"0100" when BF_AMS0& BF_ADDR (25 downto 14)="1000010000000" else	-- 0x20200000
	"1000" when BF_AMS0& BF_ADDR (25 downto 14)="1000011000000" else	-- 0x20300000
	(others => '0');
	
-- Address decoder CONTROL REGISTER
	RawSelect <=
	"0001" when BF_ADDR (25 downto 2)="000000000000000000000001" else
	"0010" when BF_ADDR (25 downto 2)="000000000000000000000010" else
	"0100" when BF_ADDR (25 downto 2)="000000000000000000000011" else
	"1000" when BF_ADDR (25 downto 2)="000000000000000000000100" else
	(others => '0');
	RegSelect <= RawSelect when (BF_AMS0 = '0') and (BF_AMS1 = '1') -- LOW = '0' ?? HIGH = '1' ??
					else (others => '0');

	-- Multiplexer
	-- BRAM outputs need to be multiplexed in order to wire them to the readout bus
	MemorySpace0 <=
		BF_MemBus(0) when MemSelect="0001" else
		BF_MemBus(1) when MemSelect="0010" else
		BF_MemBus(2) when MemSelect="0100" else
		BF_MemBus(3) when MemSelect="1000" else
		(others=>'Z');
	BF_DATA <= MemorySpace0 when BF_rena0 = '1' else (others=>'Z');


	-- Initiate BRAM component
	BRAM0 : BRAM
		port map (
			-- PORT A, BF processer side
			clka	=> BF_PCB_CLK,
			ena 	=> MemSelect(0),
			wea 	=> BF_WRENA0_v,
			addra => BF_ADDR(13 downto 2),
			dina 	=> BF_DATA,
			douta => BF_MemBus(0),
			-- PORT B, FPGA side
			clkb 	=> ADC_PCB_CLK,
			enb 	=> enable_b,
			web 	=> wrenable_b,
			addrb => MemAddr_ctr,
			dinb 	=> input_b,
			doutb => output_b
		);
	MemAddr_ctr<=address_initiate + address_status;
	enable_b<=enable_initiate OR enable_status;


	initiate_parameters : INITIATE_COMPONENT
		port map(
			CLK_ADC			=> ADC_PCB_CLK,
			initiate 		=> initiate,
			output_b 		=> output_b,
			enable_b 		=> enable_initiate,
			MemAddr_ctr 	=> address_initiate,
			-- HEV parameters
			signal_sign		=> signal_sign,
			int_window		=> int_window_vec,
			veto_delay		=> veto_delay_vec,
			signal_threshold => signal_threshold,
			int_threshold	=> int_threshold,
			width_cut		=> width_cut_vec,
			risetime_cut	=> risetime_cut_vec,
			component_selector => component_selector_vec,
			PreScaling     => PreScaling,
			rho_0 		   => rho_0,			
			rho_1 			=> rho_1,
			rho_2 			=> rho_2,
			rho_3 			=> rho_3,
			static_veto_duration => static_veto_duration,
			dynamic_veto_limit 	=> dynamic_veto_limit
		);
	int_window 			    <= to_integer(signed(int_window_vec));
	width_cut 			    <= to_integer(signed(width_cut_vec));
	risetime_cut 		    <= to_integer(signed(risetime_cut_vec));
	veto_delay 			    <= to_integer(signed(veto_delay_vec));
	component_selector <= component_selector_vec(15 downto 0);
	


	-- Initiate CONTROL REGISTER
	BFcontrol: CTRL_reg_CPU_writes -- BF control over FPGA
		generic map (regWdt => 16)
		port map (
			CLK		=> BF_PCB_CLK,
			CS			=> RegSelect(0),
			WR			=> BF_WRENA1,
			RD			=> BF_rena1,
			IOBUS		=> BF_DATA (15 downto 0),
			regout	=> BF_ctrl_Reg (15 downto 0)
		);
			
	get_baseline <=  BF_ctrl_Reg(0);
	initiate 	 <=  BF_ctrl_Reg(1);
	get_status 	 <=  BF_ctrl_Reg(2);


	Veto_status : STATUS_COMPONENT
		port map(
			CLK_ADC				 => ADC_PCB_CLK,
			get_status 			 => get_status,
			input_b 				 => input_b,
			enable_b 			 => enable_status,
			wrenable_b 			 => wrenable_b,
			MemAddr_ctr 		 => address_status,
			-- HEV parameters
			signal_sign			 => signal_sign,
			int_window			 => int_window,
			veto_delay			 => veto_delay,
			signal_threshold   => signal_threshold,
			int_threshold 		 => int_threshold,
			width_cut			 => width_cut,
			risetime_cut		 => risetime_cut,
			baseline				 => baseline,
			component_selector => component_selector,
			PreScaling 			 => PreScaling,
			dynamic_veto_limit    => dynamic_veto_limit,
			static_veto_duration  => static_veto_duration, 
			--adc_to_out				 => adc_out,
			rho_0 				 	 => rho_0,			
			rho_1 					 => rho_1, 
			rho_2 					 => rho_2,
			rho_3 					 => rho_3
		);

---- Synchronise the signal and find a baseline for the sum signal-----
	Sync_input: SYNC
		port map(
			clk   => ADC_PCB_CLK,
			ADC_0 => AD0_A,
			ADC_1 => AD0_B,
			ADC_2 => AD1_A,
			ADC_3 => AD1_B,
			ADC_out  => adc0_16
		);

	BLine_calculator : BLINE
		port map (
			clk			=>	ADC_PCB_CLK,
			getBline		=>	get_baseline, -- get baseline when ctrl_reg(0) := '1'
			initiate		=>	initiate,     -- get baseline when initiation is '1'
			signal_sign	=>	signal_sign,
			ADC_in		=>	adc0_16,
			ADC_out		=>	adc0_16_corr,
			baseline		=>	baseline,
			baseline_ok	=>	baseline_ok
		);
------------------------------------------------
	
	PeakInfo : PEAK_INFO_COMPONENT
		PORT MAP (
		clk					=> ADC_PCB_CLK,
		ADC_All				=> adc0_16_corr,
		GetBLine				=> get_baseline,
		Initiate				=> initiate,
		Baseline				=> baseline,
		BaselineOK			=> baseline_ok,
		SignalSign			=> signal_sign,
		IntWindow			=> int_window,
		SignalThreshold	=> signal_threshold,
		PeakStart			=> start_peak,
		PeakIntegral		=> integrated_sig,
		Width_limit			=> width_l,
		Risetime_limit		=> risetime_l,
		PeakWidth			=> peak_width,
		PeakRiseTime		=> peak_risetime
	);


	Veto: VETO_COMPONENT
	-- delay
	PORT MAP(
		clk						=>	ADC_PCB_CLK,
		veto_delay				=>	veto_delay,
		ADC_in					=>	adc0_16_corr,
		component_selector	=>	component_selector,
		width_cut				=>	width_cut,
		risetime_cut			=>	risetime_cut,
		signal_threshold		=>	signal_threshold,
		threshold				=>	int_threshold,
		IntWindow				=>	int_window,
		integral					=>	integrated_sig,
		width						=>	peak_width,
		risetime					=> peak_risetime,
		PreScaling				=>	PreScaling,
		rho_0 					=> rho_0,
		rho_1 					=> rho_1,
		rho_2 					=> rho_2,
		rho_3 					=> rho_3,
		static_veto_duration => static_veto_duration,
		dynamic_veto_limit 	=> dynamic_veto_limit,
		veto_verdict			=>	veto_verdict,
		veto						=>	veto_out,
	--	ADC_out					=>	adc_out,
		start_peak				=>	start_peak,
		start_veto				=>	start_veto,
		rise_time_ex			=> risetime_l,
		width_ex					=> width_l
	);
	
	status_LED : STATUS_LED_COMPONENT
	port map(
		clk 		       => ADC_PCB_CLK,
		veto_pars	    => veto_verdict,
		LED_out	       => LED_out
	);
	
	
	---------- NIM DDC10 Veto Output ------------
	-- start_peak : is on if signal is above threshold on sum signal
	-- veto_out: final veto output to the V1495 module
	NIM_OUT(0)<= veto_out;
	NIM_OUT(1)<= veto_out;
	NIM_OUT(2)<= start_peak; 
	NIM_OUT(3)<= start_veto;
	
	---- Some LEDs to show that the HEV indeed issues a veto
	LED(0)<= LED_out(0);
	LED(1)<= LED_out(1);
	LED(2)<= LED_out(2);
	------------------------------------------

end Behavioral;
