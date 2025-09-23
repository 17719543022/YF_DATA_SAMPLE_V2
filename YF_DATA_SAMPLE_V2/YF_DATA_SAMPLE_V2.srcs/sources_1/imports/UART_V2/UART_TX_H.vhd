----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/04/12 17:27:10
-- Design Name: 
-- Module Name: UART_TX_H - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--********************************-----


entity UART_TX_H is
generic (
	ini_baud_div:std_logic_vector(15 downto 0):=X"01b1";  --时钟分频比 =主时频率/波特率-1
	ini_parity	:std_logic_vector(1 downto 0) :="01";	  --parity_mode="01"=>奇校验 parity_mode="10"=>偶校验 其他 无校验
	ini_stop_bit:std_logic_vector(1 downto 0) :="01"	  --停止位个数 00 11 为2个停止位，01为1个停止位，10为1.5个停止位
);
 Port (
	clkin:in std_logic;
	rst_n:in std_logic;
---------------------------	
	txd	 			:out std_logic;
	baud_div		:in std_logic_vector(15 downto 0);
	parity			:in std_logic_vector(1 downto 0);
	stop_bit		:in std_logic_vector(1 downto 0);
	cfg_vld			:in std_logic;
	
	s_axis_tvalid	:in std_logic;
    s_axis_tready   :out  std_logic;
    s_axis_tdata    :in std_logic_vector(7 downto 0)
 );
end UART_TX_H;

architecture Behavioral of UART_TX_H is

signal check_ini_bit:std_logic:='0';
signal check_bit:std_logic:='0';
signal txd_i:std_logic:='1';
signal s_axis_tready_buf:std_logic:='0';

signal baud_div_i:std_logic_vector(15 downto 0);
signal parity_i:std_logic_vector(1 downto 0);
signal stop_bit_i:std_logic_vector(1 downto 0);
signal tx_data:std_logic_vector(8 downto 0);

signal num_bit:integer range 0 to 15;
signal s1:integer range 0 to 4;


signal stop_bit_num:std_logic_vector(16 downto 0);


begin

process(clkin)
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			baud_div_i<=ini_baud_div;
			parity_i  <=ini_parity;
			stop_bit_i<=ini_stop_bit;
		else
			if cfg_vld='1' then			------------获取配置参数
				baud_div_i<=baud_div;
				parity_i  <=parity;
				stop_bit_i<=stop_bit;
			else
				baud_div_i<=baud_div_i;
				parity_i  <=parity_i;
				stop_bit_i<=stop_bit_i;
			end if;
			
			if parity_i="01" or parity_i="10" then
				num_bit<=8;				-----数据BIT数
			else
				num_bit<=7;
			end if;
			
			if parity_i="01" then	----
				check_ini_bit<='1';
			else
				check_ini_bit<='0';
			end if;
			
			if stop_bit_i="01" then				------停止位计算
				stop_bit_num<='0'&baud_div_i;
			elsif stop_bit_i="10" then
				stop_bit_num<=('0'&baud_div_i)+baud_div_i(15 downto 1)+1;
			elsif stop_bit_i="11" then
				stop_bit_num<=(baud_div_i&'0')+1;
			else
				stop_bit_num<=(baud_div_i&'0')+1;
			end if;
			
		end if;
	end if;
end process;


-------------------------------------
tx_data(8)<=check_bit;
process(clkin)
variable cnt:integer:=0;
variable cnt1:integer:=0;
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			txd_i<='1';
			s1<=0;
			s_axis_tready_buf<='0';
		else
			case s1 is
				when 0=>
					txd_i<='1';
					if s_axis_tready_buf='1' and s_axis_tvalid='1' then
						tx_data(7 downto 0)<=s_axis_tdata;
						s1<=1;
						s_axis_tready_buf<='0';
					else
						s1<=s1;
						s_axis_tready_buf<='1';
					end if;
					cnt:=0;
					cnt1:=0;
				
				when 1=>
					txd_i<='0';
					check_bit<=check_ini_bit;
					if cnt>=baud_div_i then
						cnt:=0;
						s1<=2;
					else
						cnt:=cnt+1;
					end if;
					
				when 2=>
					txd_i<=tx_data(cnt1);
					if cnt>=baud_div_i then		
						if cnt1<=7 then
							check_bit<=check_bit xor tx_data(cnt1);
						else
							check_bit<=check_bit;
						end if;
						
						if cnt1>=num_bit then
							cnt1:=0;
							s1<=3;
						else
							cnt1:=cnt1+1;
						end if;

						cnt:=0;
					else
						cnt:=cnt+1;
					end if;
					
				when 3=>
					txd_i<='1' ;	---------停止位
					if cnt>=stop_bit_num then
						s1<=0;
					else
						s1<=s1;
						cnt:=cnt+1;
					end if;
				
				when others=>
					s1<=0;
			end case;
		end if;
	end if;
end process;

s_axis_tready<=s_axis_tready_buf;
txd<=txd_i;


end Behavioral;
