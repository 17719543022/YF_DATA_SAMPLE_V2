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
--���״̬��
--������������12V(ADAPTER+)ʱ��������Q44������1ͨ��R501����ѹ��ѹ�������ܴ��ڵ�ͨ��ѹ��ʹ��Q43
--��ͨ��ͬʱ���B16_E13_L4P��B16_E14_L4N��RGB���ָʾ
--������������2S����
--��SW1���£����IO��B15L_21PΪ�͵�ƽʱ����B15_L15P������Q43��ͨ��ϵͳͨ��
--�����ػ���(��2S)
--��B15_L15P��������£���⵽B15L_21PΪ�͵�ƽ����B15_L15P������Q43�ضϣ�ϵͳ�ϵ�

--STAT1:�����ڳ��IO�͵�ƽ
--STAT2:����Դ����IO�͵�ƽ
--PG: ��������IO�͵�ƽ
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
	clkin              :in  STD_LOGIC;        -- ϵͳʱ������ (50MHz)
	rst_n              :in  STD_LOGIC;        -- �첽�͵�ƽ��Ч��λ�ź� (0=��λ)
	power_key0	       :in std_logic;					---��������  --B15L_21P
	power_key1	       :out std_logic;					---���ֿ��� B15_L15P
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
	ads1110_sda         :inout STD_LOGIC;      -- I2C ������ (˫�����ⲿ����)
	ads1110_scl         :out STD_LOGIC        -- I2C ʱ���� (��������ⲿ����)
 );
end pwr_manage;

architecture Behavioral of pwr_manage is

constant vlotage1:std_logic_vector(15 downto 0):=conv_std_logic_vector(11636,16);---5���
constant vlotage2:std_logic_vector(15 downto 0):=conv_std_logic_vector(10909,16);---4���
constant vlotage3:std_logic_vector(15 downto 0):=conv_std_logic_vector(10327,16);---3���
constant vlotage4:std_logic_vector(15 downto 0):=conv_std_logic_vector(9745,16);---2���
constant vlotage5:std_logic_vector(15 downto 0):=conv_std_logic_vector(9455,16);---�ػ�
constant vlotage_lpr:std_logic_vector(15 downto 0):=conv_std_logic_vector(9891,16);---�͵�����ʾ


component ADS1110_Reader is
	generic(device_addr:std_logic_vector(2 downto 0):="000");
    Port (
        clkin       : in  STD_LOGIC;        -- ϵͳʱ������ (50MHz)
        rst_n       : in  STD_LOGIC;        -- �첽�͵�ƽ��Ч��λ�ź� (0=��λ)
        start_read  : in  STD_LOGIC;        -- ������ȡ�ź� (�ߵ�ƽ������������)
        sda         : inout STD_LOGIC;      -- I2C ������ (˫�����ⲿ����)
        scl         : out STD_LOGIC;        -- I2C ʱ���� (��������ⲿ����)
        data_out    : out STD_LOGIC_VECTOR(15 downto 0); -- ��ȡ��16λADCֵ
        data_ready  : out STD_LOGIC;        -- ���ݾ����ź� (�ߵ�ƽ��ʱ������)
        error_flag  : out STD_LOGIC         -- ͨ�Ŵ���ָʾ (�ߵ�ƽ��Ч�����ֵ��´β���)
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

signal        data_out    :  STD_LOGIC_VECTOR(15 downto 0); -- ��ȡ��16λADCֵ
signal        data_ready  :  STD_LOGIC;        -- ���ݾ����ź� (�ߵ�ƽ��ʱ������)
signal        error_flag  :  STD_LOGIC;         -- ͨ�Ŵ���ָʾ (�ߵ�ƽ��Ч�����ֵ��´β���)

begin

ins_pwr_sample: ADS1110_Reader
	port map (
		clkin => clkin,         -- 50MHzϵͳʱ��
		rst_n => rst_n,         -- ��λ�ź�
		start_read => start_read, -- ������ȡ�ź�
		sda => ads1110_sda,             -- I2C������
		scl => ads1110_scl,             -- I2Cʱ����
		data_out => data_out,   -- ADC�������
		data_ready => data_ready, -- ���ݾ����ź�
		error_flag => error_flag  -- ����ָʾ
);



ins_led:breath_led port map(

    clkin  =>clkin   ,
    rst_n  =>rst_n   ,
    -----  =>-----
    led_o  =>led_bre
);

process(clkin,rst_n)        ---1���ȡһ�ε�ѹ
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
process(clkin,rst_n)   --�������ػ�
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
-------------led����--------------------------------------
led_r<=led_r_buf;
led_g<=led_bre when charge_p='1' else led_g_buf;   ---������
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
            if charge_p='1' then    ---���״̬
                led_r_buf<='0';
                led_b_buf<='0';
            elsif charge_c='1' then ---������
                led_g_buf<='1';
                led_r_buf<='0';
                led_b_buf<='0';                
			elsif low_pwr='1' then  ---�͵�ѹģʽ
				if cnt_r>=50*10**6/2-1 then
					led_r_buf<=not led_r_buf;
					cnt_r:=0;
				else
					cnt_r:=cnt_r+1;
				end if;
                led_b_buf<='0';
                led_g_buf<='0';     ---��������ģʽ
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
                    voltage_level<=X"4";  ---5���;
                elsif data_out>=vlotage2 then
                    voltage_level<=X"3";  ---4���;
                elsif data_out>=vlotage3 then
                    voltage_level<=X"2";  ---3���;                
                elsif data_out>=vlotage4 then
                    voltage_level<=X"1";  ---2���;
                else
                    voltage_level<=X"0";  ---1���;   
                end if;
            end if;
            
            
            if data_ready='1' then 
                if data_out<=vlotage5 then   --�ػ�
                    close_device_en<='1';
                else
                    close_device_en<='0';
                end if;
            end if;
            
            
            if data_ready='1' then 
                if data_out<=vlotage_lpr then   --�͵�����ʾ
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
