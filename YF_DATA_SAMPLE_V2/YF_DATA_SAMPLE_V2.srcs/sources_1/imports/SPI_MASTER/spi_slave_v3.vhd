----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:10:44 2024/10/23
-- Design Name: 
-- Module Name: spi_slave_v3 - Behavioral
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
use ieee.std_Logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave_v3 is
generic(RX_DW:integer:=8);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
----------------------------
	spi_cs			:in std_logic;
	spi_clk			:in std_logic;
	spi_mosi 		:in std_logic;
-----------------------------
	rx_data			:out std_logic_vector(RX_DW-1 downto 0);
	rx_vld			:out std_logic
-------------------------------	
 );
end spi_slave_v3;

architecture Behavioral of spi_slave_v3 is


signal spi_cs_d0:std_logic;
signal spi_clk_d0:std_logic;
signal spi_sdi_d0:std_logic;

signal spi_cs_d1:std_logic;
signal spi_clk_d1:std_logic;
signal spi_sdi_d1:std_logic;

signal spi_cs_d2:std_logic;
signal spi_clk_d2:std_logic;
signal spi_sdi_d2:std_logic;

signal spi_cs_neg:std_logic;
signal spi_clk_pos:std_logic;
signal spi_clk_neg:std_logic;




signal rx_data_temp:std_logic_vector(RX_DW-1 downto 0);
signal s1:integer range 0 to 3;
signal cnt_rx:integer range 0 to RX_DW-1;
signal cnt_spi_rst:integer range 0 to 32-1;
signal spi_rst:std_logic;
signal rx_data_temp_vld:std_logic;



begin

process(clkin,rst_n)
begin
	if rst_n='0' then
		spi_cs_d0<='0';
		spi_cs_d1<='0';
		spi_cs_d2<='0';
		spi_clk_d0<='0';
		spi_clk_d1<='0';
		spi_clk_d2<='0';
		spi_sdi_d0<='0';
		spi_sdi_d1<='0';
		spi_sdi_d2<='0';
	elsif rising_edge(clkin) then
		spi_cs_d0	<=spi_cs;
		spi_cs_d1	<=spi_cs_d0;
		spi_clk_d0	<=spi_clk;
		spi_clk_d1	<=spi_clk_d0;
		spi_sdi_d0	<=spi_mosi;
		spi_sdi_d1	<=spi_sdi_d0;
		spi_cs_d2	<=spi_cs_d1;
		spi_clk_d2	<=spi_clk_d1;
		spi_sdi_d2	<=spi_sdi_d1;		
	end if;
end process;

spi_cs_neg <=not spi_cs_d1 and spi_cs_d2  ;
spi_clk_pos<=spi_clk_d1 and not spi_clk_d2;
spi_clk_neg<=(not spi_clk_d1) and (spi_clk_d2);
-----------------------------------------------------------------------------------
process(clkin,rst_n)                ---收数进程
begin
    if rst_n='0' then
        rx_data_temp_vld<='0';
        s1<=0;    
        cnt_rx<=0;
    else
        if rising_edge(clkin) then
            if spi_rst='1' then
                s1<=0;
                rx_data_temp_vld<='0';
                cnt_rx<=0;
            else
                case s1 is
                    when 0=>
                        if spi_cs_neg='1' then
                            s1<=1;
                        else
                            s1<=s1;
                        end if;
                         rx_data_temp_vld<='0';
                         cnt_rx<=0;
                    
                    when 1=>
                        if spi_clk_pos='1' then
                            rx_data_temp(RX_DW-1-cnt_rx)<=spi_sdi_d1;
                            if cnt_rx>=RX_DW-1 then
                                cnt_rx<=0;
                                s1<=0;
                                rx_data_temp_vld<='1';
                            else
                                cnt_rx<=cnt_rx+1;
                            end if;
                        else
                            s1<=s1;
                        end if;
                    
                    when others=>
                        s1<=0;
                end case;
            end if;
        end if;
    end if;
end process;



process(clkin,rst_n)
begin
    if rst_n='0' then
        rx_vld<='0';
        rx_data<=(others=>'0');    
    else
        if rising_edge(clkin) then
            if rx_data_temp_vld='1' then
                rx_data<=rx_data_temp;
            end if;
            rx_vld<=rx_data_temp_vld;
        end if;
    end if;
end process;
            








process(clkin,rst_n)
begin
    if rst_n='0' then
        spi_rst<='0';
        cnt_spi_rst<=0;
    else
        if rising_edge(clkin) then
            if spi_cs_d1='1' then
                if cnt_spi_rst>=20 then
                    cnt_spi_rst<=cnt_spi_rst;
                else
                    cnt_spi_rst<=cnt_spi_rst+1;
                end if;
            else
                cnt_spi_rst<=0;
            end if;
            
            
            if cnt_spi_rst=5 then
                spi_rst<='1';
            else
                spi_rst<='0';
            end if;
        end if;
    end if;
end process;
        





end Behavioral;
