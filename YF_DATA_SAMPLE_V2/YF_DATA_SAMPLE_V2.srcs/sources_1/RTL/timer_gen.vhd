----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 9:46 2024/11/6
-- Design Name: 
-- Module Name: timer_gen - Behavioral
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

entity timer_gen is
generic(freq:integer:=50*10**6);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
----------------------------
    time_s_vld      :out std_logic; ---秒脉冲
    s_out           :out std_logic_vector(7 downto 0);
    m_out           :out std_logic_vector(7 downto 0);
    h_out           :out std_logic_vector(7 downto 0);
    d_out           :out std_logic_vector(7 downto 0)
 );
end timer_gen;

architecture Behavioral of timer_gen is


signal cnt:integer;

signal base_time_vld:std_logic;

signal second_cnt   :std_logic_vector(7 downto 0);
signal min_cnt      :std_logic_vector(7 downto 0);
signal hour_cnt     :std_logic_vector(7 downto 0);
signal day_cnt      :std_logic_vector(7 downto 0);

begin

-----------------秒定时器-----------------------------------

process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt<=0;
        base_time_vld<='0';
    else
        if rising_edge(clkin) then
            if cnt>=freq-1 then
                cnt<=0;
            else
                cnt<=cnt+1;
            end if;
            
            
            if cnt=freq-2 then
                base_time_vld<='1';
            else
                base_time_vld<='0';
            end if;
            
            time_s_vld<=base_time_vld;
            
            
        end if;
    end if;
end process;
--------------后续时间的产生--------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        second_cnt<=(others=>'0');
        min_cnt   <=(others=>'0');
        hour_cnt  <=(others=>'0');
        day_cnt   <=(others=>'0');
    else
        if rising_edge(clkin) then
            if base_time_vld='1' then
                if second_cnt>=59 then
                    second_cnt<=(others=>'0');
                else
                    second_cnt<=second_cnt+1;
                end if;
            end if;   
                
            if base_time_vld='1' and  second_cnt=59 then
                if min_cnt>=59  then
                    min_cnt<=(others=>'0');
                else
                    min_cnt<=min_cnt+1;
                end if;
            end if;

            if base_time_vld='1' and second_cnt=59 and  min_cnt=59 then
                if hour_cnt>=23 then
                    hour_cnt<=(others=>'0');
                else
                    hour_cnt<=hour_cnt+1;
                end if;
            end if;
            
            if base_time_vld='1' and second_cnt=59 and  min_cnt=59 and hour_cnt=23 then
                day_cnt<=day_cnt+1;
            end if;
        end if;
    end if;
end process;
            
            
s_out<=   second_cnt;             
m_out<=   min_cnt;             
h_out<=   hour_cnt;             
d_out<=   day_cnt;             
        
        
        
        
        
        
        
        
        
        


end Behavioral;
