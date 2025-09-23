----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/02/16 15:57:37
-- Design Name: 
-- Module Name: tb_jl_v2 - Behavioral
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
use work.my_package.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_jl_v2 is
--  Port ( );
end tb_jl_v2;

architecture Behavioral of tb_jl_v2 is

constant freq:integer :=50*10**6;
constant sps :integer:=5000;
constant cnt_plus:integer:=freq/sps;

component SPI_TX_JL_V2 is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------数据传输SPI---------------------
    spi_clk             :out std_logic;
    spi_cs              :out std_logic;
    spi_data            :out std_logic_vector(3 downto 0);
---------------------------------------------
    ad_data_buf_in      :in ad_buf_t;
    ad_data_buf_in_vld  :in std_logic;
    adui_data_in        :in std_logic_vector(23 downto 0);
---------------------------------------------    
    adc_spi_inf         :in std_logic_vector(40-1 downto 0)
---------------------------------------------------------    
 );
end component;

signal    clkin               :std_logic:='0';
signal    rst_n               :std_logic:='0';
signal    spi_clk             :std_logic;
signal    spi_cs              :std_logic;
signal    spi_data            :std_logic_vector(3 downto 0);
signal    ad_data_buf_in      :ad_buf_t;
signal    ad_data_buf_in_vld  :std_logic;
signal    adui_data_in        :std_logic_vector(23 downto 0); 
signal    adc_spi_inf         :std_logic_vector(40-1 downto 0);


component SPI_RX_JL_V2 is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------数据传输SPI---------------------
    spi_clk             :in std_logic;
    spi_cs              :in std_logic;
    spi_data            :in std_logic_vector(3 downto 0);
---------------------------------------------
    link_sta            :out std_logic;
    adc_spi_inf         :out std_logic_vector(40-1 downto 0);
    ad_data_buf_out     :out ad_buf_t;
    adui_data_out       :out std_logic_vector(23 downto 0);     
    ad_data_buf_o_vld   :out std_logic
 );
end component;


signal    link_sta            : std_logic;
signal    adc_spi_inf_o         : std_logic_vector(40-1 downto 0);
signal    ad_data_buf_out     : ad_buf_t;
signal    adui_data_out       : std_logic_vector(23 downto 0);     
signal    ad_data_buf_o_vld   : std_logic;

signal cnt:integer;

begin

clkin<=not clkin after 10ns;
rst_n<='1' after 110ns;


ad_data_buf_in(0)<=X"112233";
ad_data_buf_in(1)<=X"445566";
ad_data_buf_in(2)<=X"778899";
adui_data_in<=X"aabbcc";
adc_spi_inf<=X"123456789a";


uut1:SPI_TX_JL_V2 port map(


    clkin                   =>  clkin               ,   
    rst_n                   =>  rst_n               ,
    spi_clk                 =>  spi_clk             ,
    spi_cs                  =>  spi_cs              ,
    spi_data                =>  spi_data            ,
    ad_data_buf_in          =>  ad_data_buf_in      ,
    ad_data_buf_in_vld      =>  ad_data_buf_in_vld  ,
    adui_data_in            =>  adui_data_in        ,
    adc_spi_inf             =>  adc_spi_inf       
);


uut2:SPI_RX_JL_V2 port map(

    clkin                   =>  clkin               ,
    rst_n                   =>  rst_n               ,
    spi_clk                 =>  spi_clk             ,
    spi_cs                  =>  spi_cs              ,
    spi_data                =>  spi_data            ,
    link_sta                =>  link_sta            ,
    adc_spi_inf             =>  adc_spi_inf_o       ,
    ad_data_buf_out         =>  ad_data_buf_out     ,
    adui_data_out           =>  adui_data_out       ,
    ad_data_buf_o_vld       =>  ad_data_buf_o_vld
    
);


process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt<=0;
        ad_data_buf_in_vld<='0';
    elsif rising_edge(clkin) then
        if cnt>=cnt_plus-1 then
            cnt<=0;
        else
            cnt<=cnt+1;
        end if;
        
        
        if cnt=100 then
            ad_data_buf_in_vld<='1';
        else
            ad_data_buf_in_vld<='0';
        end if;
    end if;
end process;






end Behavioral;
