library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity breath_led is
generic(
	freq:integer:=50*10**6
);
port(
	clkin:in std_logic;
	rst_n:in std_logic;
--------------------------------
	led_o:out std_logic
);
end breath_led;

architecture behav of breath_led is



signal cnt_1:std_logic_vector(31 downto 0);
signal cnt_2:std_logic_vector(31 downto 0);

constant freq1:integer:=freq/100;	--计算宽度（100hz）

constant step:integer:=freq1/100;	--调节呼吸时间


signal led_s:std_logic;
signal led:std_logic;



begin

led_o<=led;

process(clkin,rst_n)
begin
	if rst_n='0' then
		led_s<='0';
		led<='0';
		cnt_1<=(others=>'0');
		cnt_2<=(others=>'0');
	
	else
		if rising_edge(clkin) then
			if cnt_1>=freq1-1 then
				cnt_1<=(others=>'0');
			else
				cnt_1<=cnt_1+1;
			end if;
			
			if cnt_1<=cnt_2 then
				led<=led_s;
			else
				led<=not led_s;
			end if;

			if cnt_1>=freq1-1 then
				if cnt_2>=freq1-1 then
					cnt_2<=(others=>'0');
					led_s<= not led_s;
				else
					cnt_2<=cnt_2+step;
				end if;
			else
				cnt_2<=cnt_2;
			end if;
		end if;
	end if;
end process;
		














end behav;