----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/10/28 10:04:23
-- Design Name: 
-- Module Name: adc_7177_result_process - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc_7177_result_process is
generic(
    channel_num         : integer:=19;
    rx_data_width       : integer:=32;
    rx_addr_width       : integer:=8
);
Port(
    clkin               : in std_logic;
    rst_n               : in std_logic;
    read_trigger        : in std_logic;
    read_period         : in std_logic;
    spi_state_cnt       : in std_logic_vector(15 downto 0);
    ad7177_dout         : in std_logic_vector(channel_num-1 downto 0);
    
    adc_result_data	    : out std_logic_vector(channel_num*(rx_data_width+rx_addr_width)-1 downto 0);	
    adc_result_valid    : out std_logic
);
end adc_7177_result_process;

architecture Behavioral of adc_7177_result_process is

signal ad7177_dout_d1   : std_logic_vector(channel_num-1 downto 0);
signal ad7177_dout_d2   : std_logic_vector(channel_num-1 downto 0);
type t1 is array(0 to channel_num-1) of std_logic_vector(31 downto 0);
signal adc_result_shift_reg :t1;

attribute mark_debug                        : string;
attribute mark_debug of read_trigger        : signal is "true";
attribute mark_debug of read_period         : signal is "true";
attribute mark_debug of spi_state_cnt       : signal is "true";
attribute mark_debug of ad7177_dout         : signal is "true";

begin

g1:for i in 0 to channel_num-1 generate
begin
    process(clkin,rst_n)
    begin
        if rising_edge(clkin) then
            ad7177_dout_d1(i)<=ad7177_dout(i);
            ad7177_dout_d2(i)<=ad7177_dout_d1(1);
        end if;
    end process;
    
    process(clkin,rst_n)
    begin
        if rst_n='0' then
            adc_result_shift_reg(i)<=X"0000_0000";
        elsif rising_edge(clkin) then
            if read_trigger='1' then
                adc_result_shift_reg(i)<=X"FFFF_FFFF";
            elsif read_period='1' and spi_state_cnt(4 downto 0)="01101" then
                adc_result_shift_reg(i)<=adc_result_shift_reg(i)(30 downto 0) & ad7177_dout_d2(i);
            end if;
        end if;
    end process;
end generate;

process(clkin,rst_n)
begin
    if rst_n='0' then
        adc_result_valid<='0';
    else
        if rising_edge(clkin) then
            if spi_state_cnt=X"0001" then
                adc_result_valid<='1';
            else
                adc_result_valid<='0';
            end if;
        end if;
    end if;
end process;


end Behavioral;
