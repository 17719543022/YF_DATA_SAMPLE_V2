----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/04/12 15:03:02
-- Design Name: 
-- Module Name: UART_RX_H - Behavioral
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

entity UART_RX_H is
generic (
	ini_baud_div:std_logic_vector(15 downto 0):=X"01b1";	--时钟分频比 =主时频率/波特率-1
	ini_parity	:std_logic_vector(1 downto 0) :="01"        --parity_mode="01"=>奇校验 parity_mode="10"=>偶校验 其他 无校验
);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
------------------------------
	rxd	 			:in std_logic;
	baud_div		:in std_logic_vector(15 downto 0);
	parity			:in std_logic_vector(1 downto 0);
	cfg_vld			:in std_logic;							--配置数据有效
	
------------------------------------------------------------------
	rx_data_num		:out std_logic_vector(15 downto 0);	
	rx_data_num_vld	:out std_logic;	
	
	m_axis_tvalid	:out std_logic;
    m_axis_tready   :in  std_logic;
    m_axis_tdata    :out std_logic_vector(7 downto 0);
    m_axis_tlast	:out std_logic;							-- 表示串口接收到的最后一个字节
    m_axis_tuser	:out std_logic							--为0表示数据校验正确 为1表示数据校验错误

 );
end UART_RX_H;

architecture Behavioral of UART_RX_H is


signal check_ini_bit:std_logic:='0';
signal check_bit:std_logic:='0';
signal rxd_i0:std_logic:='0';
signal rxd_i:std_logic:='0';
signal rxd_i1:std_logic:='0';
signal rx_en:std_logic:='0';
signal rxd_neg:std_logic:='0';
signal rxd_temp_vld:std_logic:='0';
signal rx_data_vld:std_logic:='0';
signal rx_data_last:std_logic:='0';


signal baud_div_i:std_logic_vector(15 downto 0);
signal parity_i:std_logic_vector(1 downto 0);
signal rx_data:std_logic_vector(8 downto 0);
signal rxd_temp:std_logic_vector(8 downto 0);

signal cnt_neg:std_logic_vector(15 downto 0);
signal cnt_pos:std_logic_vector(15 downto 0);
signal rx_data_num_i:std_logic_vector(15 downto 0);

signal num_bit:integer range 0 to 15;
signal s1:integer range 0 to 4;



begin

process(clkin)
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			baud_div_i<=ini_baud_div;
			parity_i  <=ini_parity;
		else
			if cfg_vld='1' then
				baud_div_i<=baud_div;
				parity_i  <=parity;
			else
				baud_div_i<=baud_div_i;
				parity_i  <=parity_i;
			end if;
			
			if parity_i="01" or parity_i="10" then
				num_bit<=8;				-----数据BIT数-1
			else
				num_bit<=7;
			end if;
			
			if parity_i="01" then
				check_ini_bit<='1';
			else
				check_ini_bit<='0';
			end if;

		end if;
	end if;
end process;

----------------------------------------------------------------
process(clkin,rst_n)
begin
	if rst_n='0' then
		rxd_i0<='1';
		rxd_i<='1';
		rxd_i1<='1';
	else
		if rising_edge(clkin) then
			rxd_i0<=rxd;
			rxd_i<=rxd_i0;
			rxd_i1<=rxd_i;
		end if;
	end if;
end process;

rxd_neg<= not rxd_i and rxd_i1;	------下降沿





process(clkin,rst_n)-- 接收数据
variable cnt:integer :=0;
variable cnt1:integer :=0;
variable cnt2:integer :=0;
variable cnt3:integer :=0;
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			cnt:=0;
			s1<=0;
			rxd_temp_vld<='0';
			rxd_temp<=(others=>'0');
			rx_en<='0';
			cnt3:=0;
		else
			case s1 is
				when 0=>
					if rxd_neg='1' then
						s1<=1;
					else
						s1<=s1;
					end if;
					cnt:=0;
					cnt1:=0;
					cnt2:=0;
					rx_en<='0';
					cnt_pos<=(others=>'0');
					cnt_neg<=(others=>'0');				
					if cnt3>=baud_div_i&"0000" and rxd_temp_vld='1' then
						rx_data<=rxd_temp;
						rx_data_vld<='1';
						rx_data_last<='1';
						rxd_temp_vld<='0';
						cnt3:=0;
					else
						rx_data_vld<='0';
						rx_data_last<='0';						
						cnt3:=cnt3+1;
					end if;
				
				when 1=>				------滤除线上抖动
					cnt3:=cnt3+1;
					if rxd_i='0' then
						if cnt=baud_div_i(15 downto 1) then
							s1<=2;
							cnt:=cnt+1;
							rx_data<=rxd_temp;		----锁存数据
							rx_data_vld<=rxd_temp_vld;
							rx_data_last<='0';	
							rxd_temp_vld<='0';
						else
							cnt:=cnt+1;
						end if;
						cnt1:=0;
					else
						cnt:=cnt+1;
						if cnt1>=5 then
							cnt1:=0;
							s1<=0;
						else
							s1<=s1;
						end if;
					end if;

				when 2=>	------开始位结束
					rx_data_vld<='0';
					if cnt>=baud_div_i then
						cnt:=0;
						s1<=3;
						check_bit<=check_ini_bit;
					else
						cnt:=cnt+1;
					end if;
					
				when 3=>			---------------数据接收
					if cnt>=baud_div_i then
						if cnt_pos>=cnt_neg then
							rxd_temp(cnt2)<='1';
							if cnt2<=7 then
								check_bit<=check_bit xor '1';
							else
								check_bit<=check_bit;
							end if;
						else
							rxd_temp(cnt2)<='0';
							if cnt2<=7 then
								check_bit<=check_bit xor '0';
							else
								check_bit<=check_bit;
							end if;
						end if;
						
						if cnt2>=num_bit then
							s1<=4;
							cnt2:=0;
						else
							cnt2:=cnt2+1;
							s1<=s1;
						end if;
						cnt_pos<=(others=>'0');
						cnt_neg<=(others=>'0');
						cnt:=0;
						rx_en<='1';
					else
						rx_en<='0';
						if rxd_i='1' then
							cnt_pos<=cnt_pos+1;
						else
							cnt_neg<=cnt_neg+1;
						end if;
						cnt:=cnt+1;
					end if;
				
				when 4=>
					s1<=0;
					rxd_temp_vld<='1';
					cnt3:=0;
					rx_en<='0';
				when others=>
					s1<=0;
			end case;
		end if;
	end if;
end process;
				
				
-----------数据输出-------------------------------
process(clkin)
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			m_axis_tvalid<='0';
			m_axis_tlast<='0';
			rx_data_num_i<=(others=>'0');
		else
			if rx_data_vld ='1' then
				m_axis_tdata<=rx_data(7 downto 0);
				m_axis_tvalid<='1';
				m_axis_tlast <=rx_data_last;
				if num_bit=8 then
					m_axis_tuser <= check_bit xor rx_data(8);		---校验成功为0 校验失败为1
				else
					m_axis_tuser<='0';
				end if;
			else
				m_axis_tuser<='0';
				m_axis_tvalid<='0';
				m_axis_tlast<='0';
			end if;
			
			if rx_data_vld='1' and rx_data_last='1' then
				rx_data_num<=rx_data_num_i+1;
				rx_data_num_i<=(others=>'0');
			elsif rx_data_vld='1' then
				rx_data_num_i<=rx_data_num_i+1;
			else
				rx_data_num_i<=rx_data_num_i;
			end if;
				
			if rx_data_vld='1' and rx_data_last='1' then
				rx_data_num_vld<='1';
			else
				rx_data_num_vld<='0';
			end if;
			
		end if;
	end if;
end process;










end Behavioral;
