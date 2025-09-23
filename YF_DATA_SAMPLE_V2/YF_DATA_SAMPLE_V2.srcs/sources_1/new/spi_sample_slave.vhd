----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/25 16:36:51
-- Design Name: 
-- Module Name: spi_sample_slave - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_sample_slave is
generic( dw :integer:=8);
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------------------    
    spi_clk             :in std_logic;
    spi_cs              :in std_logic;
    spi_miso            :in std_logic;
------------------------------------------
    rx_data             :out std_logic_vector(dw-1 downto 0);
    rx_data_vld         :out std_logic

 );
end spi_sample_slave;

architecture Behavioral of spi_sample_slave is

signal spi_clk_d1:std_logic;
signal spi_clk_d2:std_logic;
signal spi_clk_d3:std_logic;
signal spi_miso_d1:std_logic;
signal spi_miso_d2:std_logic;
signal spi_cs_d1:std_logic;
signal spi_cs_d2:std_logic;
signal spi_cs_d3:std_logic;

signal spi_clk_pos:std_logic;
signal spi_cs_pos:std_logic;

signal cnt_rx:integer range 0 to dw-1;

signal rx_data_temp:std_logic_vector(dw-1 downto 0);

begin

process(clkin,rst_n)
begin
    if rising_edge(clkin) then
        spi_clk_d1<=spi_clk;
        spi_clk_d2<=spi_clk_d1;
        spi_clk_d3<=spi_clk_d2;
        spi_miso_d1<=spi_miso;
        spi_miso_d2<=spi_miso_d1;
        spi_cs_d1<=spi_cs;
        spi_cs_d2<=spi_cs_d1;
        spi_cs_d3<=spi_cs_d2;
    end if;
end process;

spi_clk_pos<= spi_clk_d2 and not spi_clk_d3;

spi_cs_pos<=spi_cs_d2 and not spi_cs_d3;
----------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt_rx<=0;
        rx_data_temp<=(others=>'0');
    else
        if rising_edge(clkin) then
            if spi_cs_d2='0' then
                if spi_clk_pos='1' then
                    rx_data_temp(dw-1 -cnt_rx)<=spi_miso_d2;
                    if cnt_rx>=dw-1 then
                        cnt_rx<=cnt_rx;
                    else
                        cnt_rx<=cnt_rx+1;
                    end if;
                else
                    cnt_rx<=cnt_rx;
                end if;
            else
                cnt_rx<=0;
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        rx_data     <=(others=>'0');
        rx_data_vld <='0' ;
    else
        if rising_edge(clkin) then
            if spi_cs_pos='1' and cnt_rx=dw-1 then
                rx_data_vld<='1';
                rx_data<=rx_data_temp;
            else
                rx_data_vld<='0';
            end if;
        end if;
    end if;
end process;
            













end Behavioral;
