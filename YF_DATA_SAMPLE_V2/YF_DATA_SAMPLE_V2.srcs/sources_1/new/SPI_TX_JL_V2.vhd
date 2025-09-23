----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/02/16 15:12:10
-- Design Name: 
-- Module Name: SPI_TX_JL_V2 - Behavioral
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

entity SPI_TX_JL_V2 is
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
end SPI_TX_JL_V2;

architecture Behavioral of SPI_TX_JL_V2 is

component spi_master_sample is
generic(
	DW_DIN:INTEGER:=8;
	SPI_DIV:INTEGER:=8;			---最小分频比为2
	T_WAITE:INTEGER:=30;
	DEV_NUM:INTEGER:=4
);
port(
	clkin			:in std_logic;
	rst_n			:in std_logic;
------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata 	:in std_logic_vector(DEV_NUM*DW_DIN-1 downto 0);
------------------------------
	spi_cs			:out std_logic;
	spi_clk			:out std_logic;
	spi_sdo			:out std_logic_vector(DEV_NUM-1 downto 0)	
);
end component;

signal	tx_en	:std_logic;
signal	s_axis_tvalid	:std_logic;
signal	s_axis_tready	: std_logic;
signal	s_axis_tdata 	:std_logic_vector(4*8-1 downto 0);


constant spi_clk_div:integer:=8;
constant spi_clk_div_half:integer:=spi_clk_div/2;

type t1 is array(0 to 119) of std_logic_vector(7 downto 0);
signal spi_tx_buf:t1;

type t2 is array(0 to 7) of std_logic_vector(7 downto 0);
signal sync_buf:t2;

signal s1:integer range 0 to 7;
signal cnt_tx:integer range 0 to 1023;
signal cnt_spi_clk:integer range 0 to 1023;
signal cnt_sync:integer ;


signal tx_over:std_logic;
signal tx_low:std_logic;
signal sync_buf_tx_en:std_logic;
signal frame_tx_cnt:std_logic_vector(31 downto 0);

signal    ad_data_buf_in_vld_lock             : std_logic;


begin


ins_spi:spi_master_sample port map(

    clkin		        =>  clkin			   , 	
    rst_n			    =>  rst_n			   ,
    ----------------    =>  ----------------   ,
    s_axis_tvalid	    =>  s_axis_tvalid	   ,
    s_axis_tready	    =>  s_axis_tready	   ,
    s_axis_tdata 	    =>  s_axis_tdata 	   ,
    ----------------    =>  ----------------   ,
    spi_cs			    =>  spi_cs			   ,
    spi_clk			    =>  spi_clk			   ,
    spi_sdo  			=>  spi_data		
);

----------主机从机同步码10hz ----------------------

sync_buf(0)<=X"55";
sync_buf(1)<=X"cc";
sync_buf(2)<=X"00";
sync_buf(3)<=X"A3";

process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt_sync<=0;
        sync_buf_tx_en<='0';
    else
        if rising_edge(clkin) then
            if cnt_sync>=50*10**6/100-1 then
                cnt_sync<=0;
            else
                cnt_sync<=cnt_sync+1;
            end if;
            
            if cnt_sync=1000 then
                sync_buf_tx_en<='1';
            elsif s1=1 then
                sync_buf_tx_en<='0';
            else
                sync_buf_tx_en<=sync_buf_tx_en;
            end if;

        end if;
    end if;
end process;
process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_buf_in_vld_lock<='0';
    else
        if rising_edge(clkin) then
            if ad_data_buf_in_vld='1' then
                ad_data_buf_in_vld_lock<='1';
            elsif s1=2 then
                ad_data_buf_in_vld_lock<='0';
            else
                ad_data_buf_in_vld_lock<=ad_data_buf_in_vld_lock;
            end if;
        end if;
    end if;
end process;
----------主机从机同步码 10hz ----------------------
----------数据发送 ----------------------
spi_tx_buf(0)<=X"55";
spi_tx_buf(1)<=X"AA";

spi_tx_buf(2)<=frame_tx_cnt(1*8-1 downto 0*8);

spi_tx_buf(3)<=adui_data_in(1*8-1 downto 0*8);
spi_tx_buf(4)<=adui_data_in(2*8-1 downto 1*8);
spi_tx_buf(5)<=adui_data_in(3*8-1 downto 2*8);


spi_tx_buf(6)<=adc_spi_inf(1*8-1 downto 0*8);
spi_tx_buf(7)<=adc_spi_inf(2*8-1 downto 1*8);
spi_tx_buf(8)<=adc_spi_inf(3*8-1 downto 2*8);
spi_tx_buf(9)<=adc_spi_inf(4*8-1 downto 3*8);
spi_tx_buf(10)<=adc_spi_inf(5*8-1 downto 4*8);

g1: for i in 0 to 35 generate
   spi_tx_buf(11+3*i)<=ad_data_buf_in(i)(1*8-1 downto 0*8);
   spi_tx_buf(12+3*i)<=ad_data_buf_in(i)(2*8-1 downto 1*8);
   spi_tx_buf(13+3*i)<=ad_data_buf_in(i)(3*8-1 downto 2*8);
end generate;
spi_tx_buf(119)<=X"A3";
----------数据发送 ----------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
        frame_tx_cnt<=(others=>'0');
    else
        if rising_edge(clkin) then
            case s1 is 
                when 0=>
                    if sync_buf_tx_en='1' then
                        s1<=1;
                    elsif ad_data_buf_in_vld_lock='1' then
                        s1<=2;
                    else
                        s1<=s1;
                    end if;
                    s_axis_tvalid<='0';
                    cnt_tx<=0;
                
                when 1=>
                    s_axis_tdata(1*8-1 DOWNTO 0*8)<=sync_buf(0);
                    s_axis_tdata(2*8-1 DOWNTO 1*8)<=sync_buf(1);
                    s_axis_tdata(3*8-1 DOWNTO 2*8)<=sync_buf(2);
                    s_axis_tdata(4*8-1 DOWNTO 3*8)<=sync_buf(3);
                    if s_axis_tvalid='1' and s_axis_tready='1' then --同步码
                        s_axis_tvalid<='0';
                        s1<=0;
                    else
                        s_axis_tvalid<='1';
                    end if;
                    
                    
                    
                when 2=>
                    s_axis_tdata(1*8-1 DOWNTO 0*8)<=spi_tx_buf(cnt_tx+0);
                    s_axis_tdata(2*8-1 DOWNTO 1*8)<=spi_tx_buf(cnt_tx+1);
                    s_axis_tdata(3*8-1 DOWNTO 2*8)<=spi_tx_buf(cnt_tx+2);
                    s_axis_tdata(4*8-1 DOWNTO 3*8)<=spi_tx_buf(cnt_tx+3);
                    if s_axis_tvalid='1' and s_axis_tready='1' then --数据内容
                        s_axis_tvalid<='0';
                        if cnt_tx>=116 then
                            s1<=0;
                            frame_tx_cnt<=frame_tx_cnt+1;
                            cnt_tx<=0;
                        else
                            s1<=s1;
                            cnt_tx<=cnt_tx+4;
                        end if;
                    else
                        s_axis_tvalid<='1';
                    end if;                   
                   
                
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;















end Behavioral;
