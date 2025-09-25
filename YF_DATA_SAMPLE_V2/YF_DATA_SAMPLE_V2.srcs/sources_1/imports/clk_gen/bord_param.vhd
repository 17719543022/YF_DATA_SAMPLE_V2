----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Huh
-- 
-- Create Date: 2022/12/19 10:02:16
-- Design Name: 
-- Module Name: bord_param - Behavioral
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

entity bord_param is
generic(
	sys_clk_freq:integer:=50*10**6
);
 Port (
	clkin		:in std_logic;
	hard_rst_n	:in std_logic;
----------------------------------	
	soft_rst_n	:in std_logic;
---------------------------------
	sys_led1	:out std_logic;	---秒闪的系统指示灯
    sys_led2	:out std_logic;
	sys_rst_n	:out std_logic;
	sys_locked	:out std_logic;
	sys_clk_out1:out std_logic
 );
end bord_param;

architecture Behavioral of bord_param is

component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  -- Status and control signals
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;


signal		clk_out1			:  STD_LOGIC:='0' ;
signal		clk16m				:  STD_LOGIC:='0' ;
signal		locked				:  STD_LOGIC:='0' ;
signal		rst_n_s1			:  STD_LOGIC:='0' ;
signal		sys_led_buf1		:  STD_LOGIC:='0' ;
signal		sys_led_buf2		:  STD_LOGIC:='0' ;
signal		rst_n_s2			:  STD_LOGIC:='0' ;



begin

sys_locked<=locked;

clkgen : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk_out1 => clk_out1,
  -- Status and control signals                
   locked => locked,
   -- Clock in ports
   clk_in1 => clkin
 );

sys_clk_out1<=clk_out1;

process(clk_out1,locked)				---系统复位逻辑，异步复位，同步释放
begin
	if locked='0' then
		rst_n_s1<='0';
		rst_n_s2<='0';
	else
		if rising_edge(clk_out1) then
			rst_n_s1	<='1' and hard_rst_n and soft_rst_n;
			rst_n_s2	<=rst_n_s1;
		end if;
	end if;
end process;



process(clk_out1,rst_n_s2)
variable cnt:integer:=0;
begin
	if rst_n_s2='0' then
		sys_rst_n<='0';
		cnt:=0;
	else
		if rising_edge(clk_out1) then
			if cnt>=500 then
				sys_rst_n<='1';
			else
				sys_rst_n<='0';
				cnt:=cnt+1;
			end if;
		end if;
	end if;
end process;


sys_led1<=sys_led_buf1;
sys_led2<=sys_led_buf2;


process(clk_out1,rst_n_s2)
variable cnt:integer:=0;
begin
	if rst_n_s2='0' then
		sys_led_buf1<='0';
        sys_led_buf2<='0';
		cnt:=0;
	else
		if rising_edge(clk_out1) then
			if cnt>=(sys_clk_freq/2-1) then
				cnt:=0;
				sys_led_buf1<=not sys_led_buf1;
				sys_led_buf2<=not sys_led_buf2;
			else
				cnt:=cnt+1;
			end if;
		end if;
	end if;
end process;
	





end Behavioral;
