----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/07/19 19:28:23
-- Design Name: 
-- Module Name: pwr_manage - Behavioral
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
--充电状态：
--当适配器输入12V(ADAPTER+)时，三极管Q44的引脚1通过R501加正压电压，三极管大于导通电压，使得Q43
--导通，同时检测B16_E13_L4P，B16_E14_L4N，RGB充电指示
--按键开机（按2S）：
--当SW1按下，检测IO口B15L_21P为低电平时，将B15_L15P上拉，Q43导通，系统通电
--按键关机：(按2S)
--在B15_L15P上拉情况下，检测到B15L_21P为低电平，将B15_L15P下拉，Q43关断，系统断电

--STAT1:当正在充电IO低电平
--STAT2:当有源输入IO低电平
--PG: 当充电完成IO低电平
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

entity pwr_manage is
 Port (
	clkin              :in  STD_LOGIC;        -- 系统时钟输入 (50MHz)
	rst_n              :in  STD_LOGIC;        -- 异步低电平有效复位信号 (0=复位)
	power_key0	       :in std_logic;					---按键开机  --B15L_21P
	power_key1	       :out std_logic;					---保持开机 B15_L15P
	STAT1		       :in std_logic;
	STAT2		       :in std_logic;
--------------------------------------------
	led_r				:out std_logic;
	led_g				:out std_logic;
	led_b				:out std_logic;
-------------------------------------------------
    pwr_state           :out std_logic_vector(7 downto 0);
    pwr_adc_data        :out std_logic_vector(15 downto 0);
    pwr_data_vld        :out std_logic;
-------------------------------------------------
	ads1110_sda         :inout STD_LOGIC;      -- I2C 数据线 (双向，需外部上拉)
	ads1110_scl         :out STD_LOGIC        -- I2C 时钟线 (输出，需外部上拉)
 );
end pwr_manage;

architecture Behavioral of pwr_manage is

constant vlotage1:std_logic_vector(15 downto 0):=conv_std_logic_vector(11636,16);---5格电
constant vlotage2:std_logic_vector(15 downto 0):=conv_std_logic_vector(10909,16);---4格电
constant vlotage3:std_logic_vector(15 downto 0):=conv_std_logic_vector(10327,16);---3格电
constant vlotage4:std_logic_vector(15 downto 0):=conv_std_logic_vector(9745,16);---2格电
constant vlotage5:std_logic_vector(15 downto 0):=conv_std_logic_vector(9455,16);---关机
constant vlotage_lpr:std_logic_vector(15 downto 0):=conv_std_logic_vector(9891,16);---低电量提示


component ADS1110_Reader is
	generic(device_addr:std_logic_vector(2 downto 0):="000");
    Port (
        clkin       : in  STD_LOGIC;        -- 系统时钟输入 (50MHz)
        rst_n       : in  STD_LOGIC;        -- 异步低电平有效复位信号 (0=复位)
        start_read  : in  STD_LOGIC;        -- 启动读取信号 (高电平触发，单脉冲)
        sda         : inout STD_LOGIC;      -- I2C 数据线 (双向，需外部上拉)
        scl         : out STD_LOGIC;        -- I2C 时钟线 (输出，需外部上拉)
        data_out    : out STD_LOGIC_VECTOR(15 downto 0); -- 读取的16位ADC值
        data_ready  : out STD_LOGIC;        -- 数据就绪信号 (高电平单时钟脉冲)
        error_flag  : out STD_LOGIC         -- 通信错误指示 (高电平有效，保持到下次操作)
    );
end component;

component breath_led is
generic(
	freq:integer:=50*10**6
);
port(
	clkin:in std_logic;
	rst_n:in std_logic;
--------------------------------
	led_o:out std_logic
);
end component;

signal charge_c:std_logic;
signal charge_p:std_logic;
signal led_r_buf:std_logic;
signal led_g_buf:std_logic;
signal led_b_buf:std_logic;
signal start_read:std_logic;
signal led_bre:std_logic;
signal low_pwr:std_logic;
signal kj_en:std_logic;
signal voltage_level:std_logic_vector(3 downto 0);
signal close_device_en:std_logic;


signal cnt_check:integer ;
signal cnt_check1:integer ;

signal        data_out    :  STD_LOGIC_VECTOR(15 downto 0); -- 读取的16位ADC值
signal        data_ready  :  STD_LOGIC;        -- 数据就绪信号 (高电平单时钟脉冲)
signal        error_flag  :  STD_LOGIC;         -- 通信错误指示 (高电平有效，保持到下次操作)

begin

ins_pwr_sample: ADS1110_Reader
	port map (
		clkin => clkin,         -- 50MHz系统时钟
		rst_n => rst_n,         -- 复位信号
		start_read => start_read, -- 启动读取信号
		sda => ads1110_sda,             -- I2C数据线
		scl => ads1110_scl,             -- I2C时钟线
		data_out => data_out,   -- ADC输出数据
		data_ready => data_ready, -- 数据就绪信号
		error_flag => error_flag  -- 错误指示
);



ins_led:breath_led port map(

    clkin  =>clkin   ,
    rst_n  =>rst_n   ,
    -----  =>-----
    led_o  =>led_bre
);

process(clkin,rst_n)        ---1秒读取一次电压
variable cnt:integer:=0;
begin
    if rst_n='0' then
        cnt:=0;
        start_read<='0';
    else
        if rising_edge(clkin) then
            if cnt>=50*10**6-1 then
                cnt:=0;
            else
                cnt:=cnt+1;
            end if;
            
            if cnt=10000 then
                start_read<='1';
            else
                start_read<='0';
            end if;
            
            if cnt=50*10**6-1/10-1 then
                pwr_adc_data<=data_out;
                pwr_data_vld<='1';
            else
                pwr_data_vld<='0';
            end if;
        end if;
    end if;
end process;




-----------------------------------------------------------------
power_key1<=kj_en;
process(clkin,rst_n)   --按键开关机
begin
	if rst_n='0' then
		cnt_check<=0;
		cnt_check1<=0;
		kj_en<='0';
	else
		if rising_edge(clkin) then
			-- if power_key0='0' then
				-- if cnt_check>=50*10**6-1 then
					-- kj_en<='1';
				-- else
					-- kj_en<='0';
					-- cnt_check<=cnt_check+1;
				-- end if;
			-- else
				-- cnt_check<=0;
			-- end if;
			
			
			-- if kj_en='1' then
				-- if power_key0='0' then
					-- if cnt_check1>=50*10**6*2-1 then
						-- kj_en<='0';
					-- else
						-- kj_en<='1';
						-- cnt_check1<=cnt_check1+1;
					-- end if;
				-- else
					-- cnt_check1<=0;
				-- end if;
			-- end if;
            
            
            if close_device_en='1' then
                kj_en<='0';
            else
                if power_key0='0' then
                    if cnt_check>=50*10**6 then
                        null;
                    else
                        cnt_check<=cnt_check+1;
                    end if;
                    
                    if cnt_check=50*10**6-1 then
                        kj_en<=not kj_en;
                    end if;
                else    
                    cnt_check<=0;
                end if;
            end if;
            
		end if;
	end if;
end process;
--------------------------------------------------------------------------------------

process(clkin,rst_n)
begin
    if rst_n='0' then
        charge_c<='0';
        charge_p<='0';     
    else
		if rising_edge(clkin) then
			if STAT1='0' and STAT2='1' then
				charge_p<='1';
				charge_c<='0';
			elsif STAT1='1' and STAT2='0' then
				charge_c<='1';
				charge_p<='0';
			else
				charge_c<='0';
				charge_p<='0';  
			end if;
		end if;
    end if;
end process;
-------------led控制--------------------------------------
led_r<=led_r_buf;
led_g<=led_bre when charge_p='1' else led_g_buf;   ---呼吸灯
led_b<=led_b_buf;

process(clkin,rst_n)
variable cnt_r:integer:=0;
begin
	if rst_n='0' then
        led_r_buf<='0';
        led_g_buf<='0'; 
        led_b_buf<='0'; 
        cnt_r:=0;
	else
		if rising_edge(clkin) then
            if charge_p='1' then    ---充电状态
                led_r_buf<='0';
                led_b_buf<='0';
            elsif charge_c='1' then ---充电完成
                led_g_buf<='1';
                led_r_buf<='0';
                led_b_buf<='0';                
			elsif low_pwr='1' then  ---低电压模式
				if cnt_r>=50*10**6/2-1 then
					led_r_buf<=not led_r_buf;
					cnt_r:=0;
				else
					cnt_r:=cnt_r+1;
				end if;
                led_b_buf<='0';
                led_g_buf<='0';     ---正常工作模式
            else
 				if cnt_r>=50*10**6/2-1 then
					led_b_buf<=not led_b_buf;
					cnt_r:=0;
				else
					cnt_r:=cnt_r+1;
				end if;    
                led_r_buf<='0';
                led_g_buf<='0';                    
			end if;
		end if;
	end if;
end process;


--------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
         close_device_en<='0';
         low_pwr<='0';
    else
        if rising_edge(clkin) then
            if data_ready='1' then
                if data_out>=vlotage1 then
                    voltage_level<=X"4";  ---5格电;
                elsif data_out>=vlotage2 then
                    voltage_level<=X"3";  ---4格电;
                elsif data_out>=vlotage3 then
                    voltage_level<=X"2";  ---3格电;                
                elsif data_out>=vlotage4 then
                    voltage_level<=X"1";  ---2格电;
                else
                    voltage_level<=X"0";  ---1格电;   
                end if;
            end if;
            
            
            if data_ready='1' then 
                if data_out<=vlotage5 then   --关机
                    close_device_en<='1';
                else
                    close_device_en<='0';
                end if;
            end if;
            
            
            if data_ready='1' then 
                if data_out<=vlotage_lpr then   --低电量提示
                    low_pwr<='1';
                else
                    low_pwr<='0';
                end if;
            end if;
        end if;
    end if;
end process;

pwr_state(0)<=STAT1;
pwr_state(1)<=STAT2;
pwr_state(5 downto 2)<=voltage_level(3 downto 0);
pwr_state(7 downto 5)<=(others=>'0');








end Behavioral;
