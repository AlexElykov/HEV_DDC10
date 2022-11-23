-- Controlling the FPGA with a register.
-- CTRL_reg_CPU_writes.vhd. A register Blackfin --> FPGA.
-- This component is intended to control the circuitry in the FPGA allowing not only '0' and '1' 
-- states but also 'Z' for an 'OFF' state i.e. the register bits of IOBUS can turn some 
-- options ON and OFF on the FPGA.
--
-- Alternatively, the value written to the register can be used as a calculation coefficient.
-- * This register can be written and read back by the CPU.
-- * It does not read data from the FPGA fabric.
-- * It can only read back the data previously written to it.

-- This component is a straight copy from Chapter_F1_FPA_Intro.pdf of the DDC10 manual
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity CTRL_reg_CPU_writes is
	generic (regWdt: integer :=16);
	port (
		CLK		: in std_logic;
		CS			: in std_logic;	-- chip selection
		WR			: in std_logic;	-- write enable
		RD			: in std_logic;	-- read enable
		IOBUS		: inout std_logic_vector (regWdt-1 downto 0);	-- data BUS (BF_DATA)  inout
		regout	: out std_logic_vector (regWdt-1 downto 0));		-- output
end CTRL_reg_CPU_writes;

architecture Behavioral of CTRL_reg_CPU_writes is
	signal rena, wrena : std_logic;
	signal local 		 : std_logic_vector(regWdt-1 downto 0);
	signal counter   	 : integer range 0 to 20 := 0;

-- ARCHITECTURE IMPLEMENTATION
begin 
	wrena <= '1' when ((CS='1') and (WR='1') and (RD='0')) else '0';
	rena  <= '1' when ((CS='1') and (WR='0') and (RD='1')) else '0';
	IOBUS <= local when rena = '1' else (others => 'Z');

-- Implementation of a flip-flop to allow the readout of the latched values from the IOBUS register
make_register: process (CLK, wrena) begin
	if rising_edge(CLK) then
		if (wrena = '1') then
			local <= IOBUS;	-- from Blackfin to fabric
		end if;
	end if;	-- clk
end process make_register;

regout <= local; -- output from the register to controlled logic , uncoment for real firmware!


 --### Just for testing ### ---
-- Cause I'm too lazy to make a proper simulation ini
-- INITIATE.vhd
-- 1. Change counter to 28 for simulation
-- 2. Uncomment input signals
-- CTRL_reg_CPU_writes.vhd
-- 1. Uncomment test process
-- 2. Comment regout signal

--test : process (CLK) begin
--	if rising_edge(CLK) then
--		if counter < 20 then
--			counter <= counter + 1;
--			regout <= "0000000000000011";
--		else
--			regout <= "0000000000000000";
--		end if;
--	end if;	-- clk
--end process test;
-- ######################## ---


end Behavioral;

