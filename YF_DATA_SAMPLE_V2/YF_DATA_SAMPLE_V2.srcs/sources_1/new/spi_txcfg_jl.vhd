----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/10/28 16:46:51
-- Design Name: 
-- Module Name: spi_txcfg_jl - Behavioral
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

entity spi_txcfg_jl is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
    spi_clk             :out std_logic;
    spi_cs              :out std_logic;
    spi_mosi            :out std_logic;
---------------------------------------------------------
    rst_n_ad_i           :in std_logic;
    master_en           :in std_logic;
    work_mod            :in std_logic_vector(7 downto 0);
    self_check_sta      :in std_logic;
    ad_channel_en       :in std_logic_vector(35 downto 0);
    up_freq             :in std_logic_vector(31 downto 0)
---------------------------------------------------------    
 );
end spi_txcfg_jl;

architecture Behavioral of spi_txcfg_jl is

constant freq:integer :=50*10**6;
constant sps :integer:=100;
constant cnt_tx_plus:integer:=freq/sps;

component spi_master_sample is
generic(
	DW_DIN:INTEGER:=8;
	SPI_DIV:INTEGER:=8;			---最小分频比为2
	T_WAITE:INTEGER:=30;
	DEV_NUM:INTEGER:=1
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
signal	s_axis_tdata 	:std_logic_vector(1*8-1 downto 0);


type t1 is array(0 to 63)of std_logic_vector(7 downto 0);
signal spi_tx_buf:t1:=(others=>X"00");


signal s1:integer range 0 to 3;
signal cnt_tx:integer range 0 to 1023;
signal cnt_cycle:integer;

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
    spi_sdo(0)			=>  spi_mosi		
);

process(clkin)
begin
    if rising_edge(clkin) then
        spi_tx_buf(0)<=X"55";
        spi_tx_buf(1)<=X"aa";
        spi_tx_buf(2)<=X"cb";
        spi_tx_buf(3)<=X"cd";
        spi_tx_buf(4)<=X"10";
        spi_tx_buf(5)<=work_mod;
        for i in 0 to 3 loop
            spi_tx_buf(6+i)<=up_freq(7+8*i downto 0+8*i);
        end loop;

        spi_tx_buf(10)<=B"0000_000"&(not ad_channel_en(0));
        spi_tx_buf(28)<=X"00";      ---从机
        spi_tx_buf(29)<=B"0000_00"&rst_n_ad_i&'0';      ---复位AD
        spi_tx_buf(39)<=X"a3";
    end if;
end process;





process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
    else
        if rising_edge(clkin) then
            case s1 is 
                when 0=>
                    if tx_en='1' then
                        s1<=1;
                    else
                        s1<=0;
                    end if;
                    s_axis_tvalid<='0';
                    cnt_tx<=0;
                
                when 1=>
                    s_axis_tdata<=spi_tx_buf(cnt_tx);
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        if cnt_tx>=39 then
                            cnt_tx<=0;
                            s1<=0;
                        else
                            cnt_tx<=cnt_tx+1;
                        end if;
                        s_axis_tvalid<='0';
                    else
                        s_axis_tvalid<='1';
                    end if;
                   
                
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;
                        
process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt_cycle<=0;
        tx_en<='0';
    else
        if rising_edge(clkin) then            
            if cnt_cycle>=cnt_tx_plus-1 then
                tx_en<='1';
                cnt_cycle<=0;
            else
                tx_en<='0';
                cnt_cycle<=cnt_cycle+1;
            end if;
            
        end if;
    end if;
end process;






end Behavioral;
