----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/02/16 15:30:06
-- Design Name: 
-- Module Name: SPI_RX_JL_V2 - Behavioral
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

entity SPI_RX_JL_V2 is
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
    frame_cnt           :out std_logic_vector(7 downto 0);     
    ad_data_buf_o_vld   :out std_logic
 );
end SPI_RX_JL_V2;

architecture Behavioral of SPI_RX_JL_V2 is

type t1 is array(0 to 119) of std_logic_vector(7 downto 0);
signal spi_rx_buf:t1;


component spi_slave_v3 is
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
end component;

signal	rx_data0			:std_logic_vector(8-1 downto 0);
signal	rx_vld0			    :std_logic;

signal	rx_data1			:std_logic_vector(8-1 downto 0);
signal	rx_vld1			    :std_logic;

signal	rx_data2			:std_logic_vector(8-1 downto 0);
signal	rx_vld2			    :std_logic;

signal	rx_data3			:std_logic_vector(8-1 downto 0);
signal	rx_vld3			    :std_logic;
signal	spi_rx_buf_vld			    :std_logic;



signal cnt_fal:integer ;
signal s1:integer  range 0 to 3;

signal cnt_rx:integer  range 0 to 1023;

signal	link_sus			    :std_logic;

begin
ins_spi_slave0:spi_slave_v3 port map(

    clkin	        =>  clkin			,
    rst_n		    =>  rst_n		    ,
    ------------    =>  ------------    ,
    spi_cs		    =>  spi_cs		    ,
    spi_clk		    =>  spi_clk		    ,
    spi_mosi 	    =>  spi_data(0) 	    ,
    ------------    =>  ------------
    rx_data		    =>  rx_data0		,
    rx_vld		    =>  rx_vld0		

);

ins_spi_slave1:spi_slave_v3 port map(

    clkin	        =>  clkin			,
    rst_n		    =>  rst_n		    ,
    ------------    =>  ------------    ,
    spi_cs		    =>  spi_cs		    ,
    spi_clk		    =>  spi_clk		    ,
    spi_mosi 	    =>  spi_data(1) 	,
    ------------    =>  ------------
    rx_data		    =>  rx_data1		,
    rx_vld		    =>  rx_vld1		

);

ins_spi_slave2:spi_slave_v3 port map(

    clkin	        =>  clkin			,
    rst_n		    =>  rst_n		    ,
    ------------    =>  ------------    ,
    spi_cs		    =>  spi_cs		    ,
    spi_clk		    =>  spi_clk		    ,
    spi_mosi 	    =>  spi_data(2) 	,
    ------------    =>  ------------
    rx_data		    =>  rx_data2		,
    rx_vld		    =>  rx_vld2		

);

ins_spi_slave3:spi_slave_v3 port map(

    clkin	        =>  clkin			,
    rst_n		    =>  rst_n		    ,
    ------------    =>  ------------    ,
    spi_cs		    =>  spi_cs		    ,
    spi_clk		    =>  spi_clk		    ,
    spi_mosi 	    =>  spi_data(3) 	,
    ------------    =>  ------------
    rx_data		    =>  rx_data3		,
    rx_vld		    =>  rx_vld3		
);
----------------------------------------------------------------------

process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
        cnt_rx<=0;
        spi_rx_buf_vld<='0';
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    if rx_vld0='1' then
                        if rx_data0=X"55" and rx_data1=X"aa" then
                            spi_rx_buf(2)<=rx_data2;
                            spi_rx_buf(3)<=rx_data3;
                            s1<=1;
                        end if;
                    else
                        s1<=s1;
                    end if;
					spi_rx_buf(0)<=X"55";
					spi_rx_buf(1)<=X"aa";
                    cnt_rx<=0;
                    spi_rx_buf_vld<='0';
                    
                when 1=>
                    if rx_vld0 ='1' then
                        spi_rx_buf(cnt_rx+4)<=rx_data0;
                        spi_rx_buf(cnt_rx+5)<=rx_data1;
                        spi_rx_buf(cnt_rx+6)<=rx_data2;
                        spi_rx_buf(cnt_rx+7)<=rx_data3;
                        if cnt_rx>=112 then
                            s1<=2;
                            cnt_rx<=0;
                        else
                            cnt_rx<=cnt_rx+4;
                        end if;
                    end if;
                when 2=>
                    if spi_rx_buf(119)=X"A3" then
                        spi_rx_buf_vld<='1';
                    else
                        spi_rx_buf_vld<='0';
                    end if;
                    s1<=0;
                
                when others=>
                    s1<=0;
            end case ;
        end if;
    end if;
end process;




------锁定链接状态 1秒内没有收到回复，断开连接状态----------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        link_sus<='0';
        cnt_fal<=0;
    else
        if rising_edge(clkin) then
            if rx_vld0='1' and rx_data0=X"55" and rx_data1=X"cc" and rx_data2=X"00" and rx_data3=X"a3"  then
                cnt_fal<=0;
                link_sus<='1';
            else
                if cnt_fal>=50*10**6+1 then
                    cnt_fal<=cnt_fal;
                else
                    cnt_fal<=cnt_fal+1;
                end if;
                
                if cnt_fal>=50*10**6 then
                    link_sus<='0';
                else
                    link_sus<=link_sus;
                end if;
            end if;
        end if;
    end if;
end process;

link_sta<=link_sus;

-----------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_buf_o_vld<='0';
        adc_spi_inf<=(others=>'0');
    else
        if rising_edge(clkin) then
            if spi_rx_buf_vld='1' then
                for i in 0 to 35 loop
                    ad_data_buf_out(i)(7 downto 0)  <=spi_rx_buf(i*3+11);
                    ad_data_buf_out(i)(15 downto 8) <=spi_rx_buf(i*3+12);
                    ad_data_buf_out(i)(23 downto 16)<=spi_rx_buf(i*3+13);
                end loop;
                
                for i in 0 to 4 loop                
                    adc_spi_inf(7+8*i downto 0+8*i)<=spi_rx_buf(6+i);
                end loop;
                
                for i in 0 to 2 loop                
                    adui_data_out(7+8*i downto 0+8*i)<=spi_rx_buf(3+i);
                end loop;
                
                frame_cnt<=spi_rx_buf(2);
                ad_data_buf_o_vld<='1';

            else
                ad_data_buf_o_vld<='0';
            end if;
        end if;
    end if;
end process;

end Behavioral;
