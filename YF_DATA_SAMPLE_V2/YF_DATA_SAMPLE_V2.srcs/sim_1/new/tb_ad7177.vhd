----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/05/23 16:14:23
-- Design Name: 
-- Module Name: tb_ad7177 - Behavioral
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
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_ad7177 is
--  Port ( );
end tb_ad7177;

architecture Behavioral of tb_ad7177 is

component ctrl_ad7177 is
generic(device_num:integer:=18);
 Port (
    clkin         :in std_logic;
    rst_n         :in std_logic;
----------------------------
    spi_clk       :out std_logic;
    spi_cs        :out std_logic;
    spi_mosi      :out std_logic;
    spi_miso      :in std_logic_vector(device_num-1 downto 0);
    sync_n        :out std_logic;
----------------------------
    m_axis_tvalid :out std_logic;
    m_axis_tdata  :out std_logic_vector(2*device_num*32-1 downto 0)
 );
end component;

signal    clkin             :std_logic:='0';
signal    rst_n             :std_logic:='0';
signal    spi_clk           :std_logic:='0';
signal    spi_cs            :std_logic:='0';
signal    spi_mosi          :std_logic:='0';
signal    spi_miso          :std_logic_vector(18-1 downto 0):=(others=>'0');
signal    sync_n            :std_logic:='0';
signal    m_axis_tvalid     :std_logic:='0';
signal    m_axis_tdata      :std_logic_vector(2*18*32-1 downto 0):=(others=>'0');


begin

clkin<= not clkin after 10ns;
rst_n<='1' after 100ns;


uut:ctrl_ad7177 port map(

    clkin               =>  clkin           ,          
    rst_n               =>  rst_n           ,
    spi_clk             =>  spi_clk         ,
    spi_cs              =>  spi_cs          ,
    spi_mosi            =>  spi_mosi        ,
    spi_miso            =>  spi_miso        ,
    sync_n              =>  sync_n          ,
    m_axis_tvalid       =>  m_axis_tvalid   ,
    m_axis_tdata        =>  m_axis_tdata    
);













end Behavioral;
