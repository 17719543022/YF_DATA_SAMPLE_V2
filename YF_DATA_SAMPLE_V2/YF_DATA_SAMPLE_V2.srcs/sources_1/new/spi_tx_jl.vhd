----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/10/12 15:41:18
-- Design Name: 
-- Module Name: spi_tx_jl - Behavioral
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

entity spi_tx_jl is
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
  );
end spi_tx_jl;

architecture Behavioral of spi_tx_jl is

constant spi_clk_div:integer:=8;
constant spi_clk_div_half:integer:=spi_clk_div/2;

type t1 is array(0 to 119) of std_logic_vector(7 downto 0);
signal spi_tx_buf:t1;

type t2 is array(0 to 9) of std_logic_vector(7 downto 0);
signal sync_buf:t2;

signal s2:integer range 0 to 7;
signal cnt_tx:integer range 0 to 1023;
signal cnt_spi_clk:integer range 0 to 1023;
signal cnt_sync:integer ;


signal tx_over:std_logic;
signal tx_low:std_logic;
signal sync_buf_tx_en:std_logic;
signal frame_tx_cnt:std_logic_vector(31 downto 0);

signal    ad_data_buf_in_vld_lock             : std_logic;
signal    spi_clk_o             : std_logic;
signal    spi_cs_o              : std_logic;
signal    spi_data_o            : std_logic_vector(3 downto 0);

begin

spi_clk<=spi_clk_o;
spi_cs<=spi_cs_o;
spi_data<=spi_data_o;

----------主机从机同步码10hz ----------------------

sync_buf(0)<=X"55";
sync_buf(1)<=X"cc";
sync_buf(2)<=X"00";
sync_buf(3)<=X"00";
sync_buf(4)<=X"00";
sync_buf(5)<=X"00";
sync_buf(6)<=X"00";
sync_buf(7)<=X"00";
sync_buf(8)<=X"00";
sync_buf(9)<=X"a3";


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
            elsif s2=3 then
                sync_buf_tx_en<='0';
            else
                sync_buf_tx_en<=sync_buf_tx_en;
            end if;

        end if;
    end if;
end process;
----------主机从机同步码 10hz ----------------------


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

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_buf_in_vld_lock<='0';
    else
        if rising_edge(clkin) then
            if ad_data_buf_in_vld='1' then
                ad_data_buf_in_vld_lock<='1';
            elsif s2=1 then
                ad_data_buf_in_vld_lock<='0';
            else
                ad_data_buf_in_vld_lock<=ad_data_buf_in_vld_lock;
            end if;
        end if;
    end if;
end process;
                

process(clkin,rst_n)
begin
    if rst_n='0' then
        frame_tx_cnt<=(others=>'0');
        spi_data_o<=(others=>'0');
        s2<=0;
        spi_clk_o<='0';
        spi_cs_o<='1';
        cnt_tx<=0;   
        cnt_spi_clk<=0;   
        tx_over<='0'; 
    else
        if rising_edge(clkin) then
            case s2 is
                when 0=>
                    if sync_buf_tx_en='1' then
                        s2<=3;
                    elsif ad_data_buf_in_vld_lock='1' then
                        s2<=1;
                    else
                        s2<=s2;
                    end if;
                    spi_clk_o<='0';
                    spi_cs_o<='1';
                    cnt_tx<=0;
                    cnt_spi_clk<=0;  
                    tx_over<='0'; 
                when 1=>
                    spi_cs_o<='0';
                    if cnt_spi_clk>=5 then
                        cnt_spi_clk<=0;
                        s2<=2;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;
                    tx_low<='1';
                
                when 2=>
                    if cnt_spi_clk>=spi_clk_div-1 then
                        cnt_spi_clk<=0;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;
                    
                    if cnt_spi_clk>=spi_clk_div_half then
                        spi_clk_o<='1';
                    else
                        spi_clk_o<='0';
                    end if;
                    
                    if cnt_spi_clk=0 then
                        if tx_low='1' then
                            spi_data_o<=spi_tx_buf(cnt_tx)(7 downto 4);
                        else
                            cnt_tx<=cnt_tx+1;
                            spi_data_o<=spi_tx_buf(cnt_tx)(3 downto 0);
                        end if;
                        tx_low<= not tx_low;
                    end if;
                    
                    if cnt_tx>=119 and cnt_spi_clk=0 and tx_low='0' then
                        tx_over<='1';
                    end if;
                    
                    if cnt_spi_clk=spi_clk_div-1 and tx_over='1' then
                        s2<=0;
                        frame_tx_cnt<=frame_tx_cnt+1;
                    end if;
-----------------------------------------------------------------------------------------------------
                when 3=>
                    spi_cs_o<='0';
                    if cnt_spi_clk>=5 then
                        cnt_spi_clk<=0;
                        s2<=4;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;
                    tx_low<='1';                    
                    
                    
                 when 4=>
                    if cnt_spi_clk>=spi_clk_div-1 then
                        cnt_spi_clk<=0;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;
                    
                    if cnt_spi_clk>=spi_clk_div_half then
                        spi_clk_o<='1';
                    else
                        spi_clk_o<='0';
                    end if;
                    
                    if cnt_spi_clk=0 then
                        if tx_low='1' then
                            spi_data_o<=sync_buf(cnt_tx)(7 downto 4);
                        else
                            cnt_tx<=cnt_tx+1;
                            spi_data_o<=sync_buf(cnt_tx)(3 downto 0);
                        end if;
                        tx_low<= not tx_low;
                    end if;
                    
                    if cnt_tx>=9 and cnt_spi_clk=0 and tx_low='0' then
                        tx_over<='1';
                    end if;
                    
                    if cnt_spi_clk=spi_clk_div-1 and tx_over='1' then
                        s2<=0;
                        frame_tx_cnt<=frame_tx_cnt+1;
                    end if;                   
                    
                   
                
                when others=>
                    s2<=0;
            end case;
        end if;
    end if;
end process;









end Behavioral;
