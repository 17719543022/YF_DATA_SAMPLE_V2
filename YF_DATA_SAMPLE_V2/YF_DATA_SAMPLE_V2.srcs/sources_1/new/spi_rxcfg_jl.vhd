----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/10/28 16:08:33
-- Design Name: 
-- Module Name: spi_rxcfg_jl - Behavioral
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

entity spi_rxcfg_jl is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
    spi_clk             :in std_logic;
    spi_cs              :in std_logic;
    spi_mosi            :in std_logic;
---------------------------------------------------------
    rst_n_ad_o          :out std_logic;
    master_en           :out std_logic;
    work_mod            :out std_logic_vector(7 downto 0);
    self_check_sta      :out std_logic;
    ad_channel_en       :out std_logic_vector(35 downto 0);
    up_freq             :out std_logic_vector(31 downto 0); 
    cfg_data_vld        :out std_logic
---------------------------------------------------------    
 );
end spi_rxcfg_jl;

architecture Behavioral of spi_rxcfg_jl is

constant freq:integer :=50*10**6;
constant sps :integer:=2000;
constant ini_sample_rate:integer:=freq/sps;

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


signal shift_reg:std_logic_vector(32-1 downto 0);
signal rx_data:std_logic_vector(8-1 downto 0);
signal spi_rx_buf_type:std_logic_vector(8-1 downto 0);
signal rx_vld:std_logic;
signal sync:std_logic;
signal spi_rx_buf_vld:std_logic;

signal s1:integer range 0 to 3;
signal cnt_rx:integer range 0 to 1023;


type t1 is array(0 to 63)of std_logic_vector(7 downto 0);
signal spi_rx_buf:t1;



begin

ins_spi_slave:spi_slave_v3 port map(

    clkin	        =>  clkin			,
    rst_n		    =>  rst_n		    ,
    ------------    =>  ------------    ,
    spi_cs		    =>  spi_cs		    ,
    spi_clk		    =>  spi_clk		    ,
    spi_mosi 	    =>  spi_mosi 	    ,
    ------------    =>  ------------
    rx_data		    =>  rx_data		    ,
    rx_vld		    =>  rx_vld		

);


process(clkin,rst_n)
begin
    if rst_n='0' then
        shift_reg<=(others=>'0');
    elsif rising_edge(clkin) then
        if rx_vld='1'  then
            shift_reg<=shift_reg(23 downto 0)&rx_data(7 downto 0);
        else
            shift_reg<=shift_reg;
        end if;        
    end if;
end process;

sync<='1' when shift_reg=X"55AACBCD" else '0';

process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
        cnt_rx<=0;
        spi_rx_buf_vld<='0';
    elsif rising_edge(clkin) then
        case s1 is
            when 0=>
                if sync='1' then
                    s1<=1;
                else
                    s1<=s1;
                end if;
                cnt_rx<=4;
                spi_rx_buf_vld<='0';
            
            when 1=>
                if rx_vld='1' then
                    spi_rx_buf(cnt_rx)<=rx_data;
                    if cnt_rx>=39 then
                        s1<=2;
                        cnt_rx<=0;
                    else
                        cnt_rx<=cnt_rx+1;
                    end if;
                else
                    s1<=s1;
                end if;
                
            when 2=>    
                if spi_rx_buf(39)=X"a3" then
                    spi_rx_buf_vld<='1';
                    spi_rx_buf_type<=spi_rx_buf(4);
                else
                    spi_rx_buf_vld<='0';
                end if;
                s1<=0;
            
            when others=>
                s1<=0;
        end case;
    end if;
end process;



process(clkin,rst_n)
begin
    if rst_n='0' then
        work_mod        <=X"51";            ----问询上传
        up_freq         <=conv_std_logic_vector(ini_sample_rate,32); 
        ad_channel_en   <=(others=>'0');
        master_en       <='0';                     ---从机
        self_check_sta  <='0';                     ---从机
        cfg_data_vld    <='0';
    elsif rising_edge(clkin) then
        if spi_rx_buf_vld='1' and spi_rx_buf_type=X"10" then        ---配置命令
            work_mod<=spi_rx_buf(5);
            for i in 0 to 3 loop 
                up_freq(i*8+7 downto i*8)<=spi_rx_buf(i+6);
            end loop;
            if spi_rx_buf(10)=X"00" then
                ad_channel_en<=(others=>'1');       ---阻抗模式
            elsif spi_rx_buf(10)=X"01" then
                ad_channel_en<=(others=>'0');       ---采集模式
            end if;
            master_en     <=spi_rx_buf(28)(1);
            self_check_sta<=spi_rx_buf(28)(2);
            rst_n_ad_o    <=spi_rx_buf(29)(1);
            cfg_data_vld<='1';
        else
            cfg_data_vld<='0';
        end if;        
    end if;
end process;








end Behavioral;
