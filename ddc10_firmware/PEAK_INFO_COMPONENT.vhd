-- Collects the information about the properties of the observed peaks
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity PEAK_INFO_COMPONENT is
	port (
	clk					:	in std_logic;
	ADC_All				:	in std_logic_vector(15 downto 0);
	GetBLine				:	in std_logic;
	Initiate				:	in std_logic;
	Baseline				:	in std_logic_vector(15 downto 0);
	BaselineOK			:  in std_logic;
	SignalSign			:	in std_logic;
	IntWindow			:	in integer range 0 to 8000;
	SignalThreshold	:  in std_logic_vector(15 downto 0);
	PeakStart			:	in std_logic;
	PeakIntegral		:	out std_logic_vector(23 downto 0);
	PeakWidth			:	out integer range 0 to 1000;
	Width_limit			:  out std_logic;
	Risetime_limit		:  out std_logic;
	PeakRiseTime		:	out integer range 0 to 1000
);
end PEAK_INFO_COMPONENT;



architecture Behavioral of PEAK_INFO_COMPONENT is
----------- INTEGRATOR COMPONENT ---------
component INTEGRATOR
	port (
	clk			:	in std_logic;								-- ADC clock
	int_window	: 	in integer range -1 to 8000;
	ADC			:  in std_logic_vector(15 downto 0);
	integral		: 	out std_logic_vector(23 downto 0);
	signal_threshold	: in std_logic_vector(15 downto 0)
);
end component;

----------- WIDTH COMPONENT ---------
component WIDTH_COMPONENT
	port (
	clk					: in std_logic;								-- ADC clock
	baseline_ok			: in std_logic;
	peak_start			: in std_logic;
	ADC					: in std_logic_vector(15 downto 0);
	signal_threshold	: in std_logic_vector(15 downto 0);
	width_overflow    : out std_logic;
	width					: out integer range 0 to 1000
);
end component;

----------- RISE TIME COMPONENT ---------
component RISETIME_COMPONENT
	port (
	clk					: in std_logic;								-- ADC clock
	baseline_ok			: in std_logic;
	ADC					: in std_logic_vector(15 downto 0);
	signal_threshold	: in std_logic_vector(15 downto 0);
	risetime_overflow : out std_logic;
	risetime				: out integer range 0 to 1000
);
end component;

-- Width
signal peak_width : integer range 0 to 1000;

-- Rise time
signal peak_risetime : integer range 0 to 1000;

begin		
	ADC_integral : INTEGRATOR 
	port map (
		clk			=>clk,
		int_window	=>IntWindow,
		ADC			=>ADC_All,
		integral		=>PeakIntegral,
		signal_threshold	=>SignalThreshold
	);
		
	width : WIDTH_COMPONENT
	port map (
		clk					=>clk,
		baseline_ok			=>BaselineOk,
		peak_start			=>PeakStart,
		ADC					=>ADC_All,
		signal_threshold	=>SignalThreshold,
		width_overflow      =>Width_limit,
		width					=>PeakWidth
	);

	risetime : RISETIME_COMPONENT
	port map (
		clk					=>clk,
		baseline_ok			=>BaselineOk,
		ADC					=>ADC_All,
		signal_threshold	=>SignalThreshold,
		risetime_overflow	=>Risetime_limit,
		risetime				=>PeakRiseTime
	);
end Behavioral;

