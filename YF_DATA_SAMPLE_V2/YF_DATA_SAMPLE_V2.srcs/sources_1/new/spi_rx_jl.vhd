----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/10/12 14:19:53
-- Design Name: 
-- Module Name: spi_rx_jl - Behavioral
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

entity spi_rx_jl is
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
end spi_rx_jl;

architecture Behavioral of spi_rx_jl is

type t1 is array(0 to 119) of std_logic_vector(7 downto 0);
signal spi_rx_buf:t1;

signal spi_clk_o:std_logic;
signal spi_cs_o:std_logic;
signal spi_data_o:std_logic_vector(7 downto 0);

signal spi_clk_d1:std_logic;
signal spi_clk_d2:std_logic;
signal spi_clk_d3:std_logic;
signal spi_clk_pos:std_logic;

signal spi_cs_d1:std_logic;
signal spi_cs_d2:std_logic;
signal spi_cs_d3:std_logic;



signal spi_data_d1:std_logic_vector(3 downto 0);
signal spi_data_d2:std_logic_vector(3 downto 0);
signal spi_data_d3:std_logic_vector(3 downto 0);
signal sync:std_logic_vector(1 downto 0);


signal shift_reg:std_logic_vector(15 downto 0);
signal spi_rx_data_temp:std_logic_vector(7 downto 0);
signal spi_rx_buf_type:std_logic_vector(7 downto 0);


signal cnt_rx_vld:std_logic;
signal link_sus:std_logic;
signal spi_rx_data_temp_vld:std_logic;
signal spi_rx_buf_vld:std_logic;

signal data_length:integer range 0 to 1023;
signal cnt_rx     :integer range 0 to 1023;
signal s1:integer range 0 to 3;
signal cnt_fal:integer ;


begin


process(clkin,rst_n)
begin
    if rising_edge(clkin) then
        spi_clk_d1<=spi_clk;
        spi_clk_d2<=spi_clk_d1;
        spi_clk_d3<=spi_clk_d2;
        spi_cs_d1<=spi_cs;
        spi_cs_d2<=spi_cs_d1;
        spi_cs_d3<=spi_cs_d2;
        spi_data_d1<=spi_data;
        spi_data_d2<=spi_data_d1;
        spi_data_d3<=spi_data_d2;
    end if;
end process;

spi_clk_pos<=spi_clk_d2 and not spi_clk_d3;

process(clkin,rst_n)    
begin
    if rst_n='0' then
        spi_rx_data_temp_vld<='0';
    else
        if rising_edge(clkin) then
            if spi_cs_d2='0' then
                if spi_cs_d2='0' and  spi_clk_pos='1' then
                    spi_rx_data_temp<=spi_rx_data_temp(3 downto 0)&spi_data_d2;
                    spi_rx_data_temp_vld<=cnt_rx_vld;
                    cnt_rx_vld<= not cnt_rx_vld;
                else
                    spi_rx_data_temp_vld<='0';
                end if;
            else
                spi_rx_data_temp_vld<='0';
                cnt_rx_vld<='0';   
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------------
process(clkin,rst_n)    
begin
    if rst_n='0' then
        shift_reg<=(others=>'0');
    else
        if rising_edge(clkin) then
            if spi_rx_data_temp_vld='1' then
                shift_reg<=shift_reg(7 downto 0)&spi_rx_data_temp;
            else
                shift_reg<=shift_reg;
            end if;
        end if;
    end if;
end process;

sync(0)<='1' when shift_reg=X"55AA" else'0';
sync(1)<='1' when shift_reg=X"55CC" else'0';


------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
        spi_rx_buf_vld<='0';
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    if sync(0)='1' then
                        s1<=1;
                        data_length<=120;
                    elsif sync(1)='1' then
                        s1<=1;
                        data_length<=10;
                    else
                        s1<=s1;
                    end if;
                    cnt_rx<=2;
                    spi_rx_buf_type<=shift_reg(7 DOWNTO 0);
                    spi_rx_buf_vld<='0';
                
                when 1=>
                    if spi_rx_data_temp_vld='1' then
                        spi_rx_buf(cnt_rx)<=spi_rx_data_temp;
                        if cnt_rx>=data_length-1 then
                            cnt_rx<=0;
                            s1<=2;
                        else
                            cnt_rx<=cnt_rx+1;
                        end if;
                    else
                        s1<=s1;
                    end if;
                
                when 2=>
                    if spi_rx_buf(data_length-1)=X"A3" then
                        spi_rx_buf_vld<='1';
                    else
                        spi_rx_buf_vld<='0';
                    end if;
                    s1<=0;
                    
                    
                    
                when others=>
                    s1<=0;
            end case;
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
            if spi_rx_buf_vld='1' and spi_rx_buf_type=X"cc" then
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


-------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_buf_o_vld<='0';
        adc_spi_inf<=(others=>'0');
    else
        if rising_edge(clkin) then
            if spi_rx_buf_vld='1' and spi_rx_buf_type=X"AA" then
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

            else
                ad_data_buf_o_vld<='0';
            end if;
        end if;
    end if;
end process;




















end Behavioral;
