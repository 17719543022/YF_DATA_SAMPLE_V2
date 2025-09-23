----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/12/05 09:41:16
-- Design Name: 
-- Module Name: tb_v2om_c - Behavioral
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

entity tb_v2om_c is
--  Port ( );
end tb_v2om_c;

architecture Behavioral of tb_v2om_c is

component V2OM_C is
Port (
    clkin             :in std_logic;
    rst_n             :in std_logic;
    ad_data_buf       :in ad_buf_t;
    ad_data_buf_vld   :in std_logic;
    change_fac0       :in std_logic_vector(23 downto 0);
    change_fac1       :in std_logic_vector(23 downto 0);
    om_data_buf       :out ad_buf_t;
    om_data_buf_vld   :out std_logic
 );
end component;


signal    clkin             :std_logic:='0';
signal    rst_n             :std_logic:='0';
signal    ad_data_buf       :ad_buf_t:=(others=>X"A000_00");
signal    ad_data_buf_vld   :std_logic;
signal    change_fac0       :std_logic_vector(23 downto 0);
signal    change_fac1       :std_logic_vector(23 downto 0);
signal    om_data_buf       : ad_buf_t;
signal    om_data_buf_vld   : std_logic;


signal A1:STD_LOGIC:='0';
signal A2:STD_LOGIC:='0';
signal A3:STD_LOGIC:='0';
signal A4:STD_LOGIC:='0';
signal A5:STD_LOGIC:='0';


begin

clkin<= not clkin after 10ns;
rst_n<='1' after 100ns;
----------------------------------
uut:V2OM_C port map(
    clkin                => clkin            , 
    rst_n                => rst_n            ,
    ad_data_buf          => ad_data_buf      ,
    ad_data_buf_vld      => ad_data_buf_vld  ,
    change_fac0          => change_fac0      ,
    change_fac1          => change_fac1      ,
    om_data_buf          => om_data_buf      ,
    om_data_buf_vld      => om_data_buf_vld 
);

-----------------------------------------------------
ad_data_buf(0)<=X"4000_00";
ad_data_buf(1)<=X"5000_00";
ad_data_buf(2)<=X"6000_00";
ad_data_buf(3)<=X"7000_00";

change_fac0<=conv_std_logic_vector(10000,24);
change_fac1<=conv_std_logic_vector(80000,24);



process(clkin,rst_n)
variable cnt:integer:=0;
begin
    if rst_n='0' then
         cnt:=0;
         ad_data_buf_vld<='0';
    else
        if rising_edge(clkin) then
            if cnt>=50*10**6/2000-1 then
                cnt:=0;
            else
                cnt:=cnt+1;
            end if;
            
            
            if cnt=100 then
                ad_data_buf_vld<='1';
            else
                ad_data_buf_vld<='0';
            end if;

        end if;
    end if;
end process;

-------------------------------------------------------
-- A1<= not A1 after 1us;

-- A2<= not A1;

-- A3<=

























end Behavioral;
