----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/12/05 09:10:10
-- Design Name: 
-- Module Name: V2OM_C - Behavioral
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

entity V2OM_C is
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
end V2OM_C;

architecture Behavioral of V2OM_C is


COMPONENT mult_gen_0
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
END COMPONENT;


signal A :STD_LOGIC_VECTOR(23 DOWNTO 0);
signal B :STD_LOGIC_VECTOR(23 DOWNTO 0);
signal P :STD_LOGIC_VECTOR(47 DOWNTO 0);



signal ad_data_buf_abs:ad_buf_t;
signal ad_data_buf_abs_vld:std_logic;


SIGNAL cnt_cal:integer range 0 to 63;





begin

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_buf_abs_vld<='0';
    else
        if rising_edge(clkin) then
            if ad_data_buf_vld='1' then
                for i in 0 to 35 loop
                    if ad_data_buf(i)(23)='1' then
                        ad_data_buf_abs(i)<= not ad_data_buf(i)+1;
                    else
                        ad_data_buf_abs(i)<=ad_data_buf(i);
                    end if;
                end loop;
                ad_data_buf_abs_vld<='1';
            else
                ad_data_buf_abs_vld<='0';
            end if;
        end if;
    end if;
end process;

------------------------------------------------
--latecy=5
ins_mult : mult_gen_0
  PORT MAP (
    CLK => clkin,
    A => A,
    B => change_fac0,
    P => P
  );

------------------转换系数----------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        A<=(others=>'0');
        cnt_cal<=63;
    else
        if rising_edge(clkin) then
            if ad_data_buf_abs_vld='1' then
                cnt_cal<=0;
            else
                if cnt_cal>=63 then
                    cnt_cal<=cnt_cal;
                else
                    cnt_cal<=cnt_cal+1;
                end if;
            end if;
            if cnt_cal<=35 then
                A<=ad_data_buf_abs(cnt_cal);
            end if;
        end if;
    end if;
end process;

-----------------数据输出--------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        om_data_buf_vld<='0';
        om_data_buf<=(others=>X"0000_00");
    else
        if rising_edge(clkin) then
            if cnt_cal>=6 and cnt_cal<=41 then
                om_data_buf(cnt_cal-6)<=P(47 downto 24)+change_fac1;
            end if;
            
            if cnt_cal=41 then
                om_data_buf_vld<='1';
            else
                om_data_buf_vld<='0';
            end if;
        end if;
    end if;
end process;















end Behavioral;
