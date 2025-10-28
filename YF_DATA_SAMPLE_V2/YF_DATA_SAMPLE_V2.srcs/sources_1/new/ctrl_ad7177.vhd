----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/05/22 19:58:06
-- Design Name: 
-- Module Name: ctrl_ad7177 - Behavioral
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

entity ctrl_ad7177 is
generic(device_num:integer:=18);
 Port (
    clkin           :in std_logic;
    rst_n           :in std_logic;
----------------------------
    spi_clk         :out std_logic;
    spi_cs          :out std_logic;
    spi_mosi        :out std_logic;
    spi_miso        :in std_logic_vector(device_num-1 downto 0);
    ad7177_sync     :out std_logic;
    audi_in         :in std_logic;
    adc_check_sus   :out std_logic_vector(device_num-1 downto 0);
    work_mod        :in std_logic_vector(7 downto 0);
    m0_num          :in std_logic_vector(7 downto 0);
    sample_start    :in std_logic;
    cnt_cycle       :in std_logic_vector(31 downto 0);
    cnt_cycle_ov    :in std_logic;
----------------------------
    ad_data_buf     :out ad_buf_t;
    ad_data_buf_vld :out std_logic;
    err_num         :out std_logic_vector(device_num-1 downto 0);
    adui_data       :out std_logic_vector(24-1 downto 0);
----------------------------
    m_axis_tvalid   :out std_logic;
    m_axis_tdata    :out std_logic_vector(2*device_num*32-1 downto 0)
 );
end ctrl_ad7177;

architecture Behavioral of ctrl_ad7177 is
constant resv_data:std_logic_vector(39 downto 0):=X"0000_0000_00";
constant spi_rd_cmd:std_logic:='0';
constant spi_wr_cmd:std_logic:='1';

component SPI_MASTER_V1 is
generic(
	spi_div			:integer:=8;	---最小分频比为2
	cpol			:std_logic:='1';
	cpha			:std_logic:='1';
	tecs			:integer:=1;	--------CS下降沿后距离第一个有效时钟的时间（时间=（tecs+2）*time_step）估计值
	tce				:integer:=2;	--------最后一个SPI CLK下降沿后距离CSbuf上升沿的时间（时间=（tce-1）*clkin）
	tewh			:integer:=5;	--------两次CS启动的最小时间间隔（时间=（tewh+3）*clkin）
-----------------------------------
	tx_data_width	:integer:=40;
	rx_data_width	:integer:=32;
	rx_addr_width	:integer:=8;
--------------------------------
    sdi_num         :integer:=device_num+1;
--------------------------------
	data_seq		:std_logic:='0'			------- 0=>MSB->LSB 1=>LSB->MSB
);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
---------------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata	:in std_logic_vector(tx_data_width-1 downto 0);	--地址总是放在高位
	s_axis_tuser	:in std_logic;					---表示读写信号的表示	(1=》写 ，0=》读)
	s_axis_trst	    :in std_logic;					---专门用于产生AD的复位逻辑
	s_axis_tnum		:in std_logic_vector(15 downto 0);	--接收与发送总bit数（一次SPI工作过程中总时钟数）
----------------------------------------
	spi_rd_data		:out std_logic_vector(sdi_num*(rx_data_width+rx_addr_width)-1 downto 0);	
	spi_rd_vld		:out std_logic;	
----------------------------------------
	sdo				:out std_logic;
	cs				:out std_logic;
	sck				:out std_logic;
	sdi				:in std_logic_vector(sdi_num-1 downto 0)
 );
end component;
signal	s_axis_tvalid	:std_logic;
signal	s_axis_tready	: std_logic;
signal	s_axis_tdata	:std_logic_vector(40-1 downto 0);	--地址总是放在高位
signal	s_axis_tuser	:std_logic;					---表示读写信号的表示	(1=》写 ，0=》读)
signal	s_axis_tnum		:std_logic_vector(15 downto 0);	--接收与发送总bit数（一次SPI工作过程中总时钟数）
signal	spi_rd_data		:std_logic_vector((device_num+1)*(32+8)-1 downto 0);	
signal	spi_rd_vld		: std_logic;	
signal	s_axis_trst		: std_logic;	

component adc_7177_result_process is
generic(
    channel_num         : integer:=19;
    rx_data_width       : integer:=32;
    rx_addr_width       : integer:=8
);
Port(
    clkin               : in std_logic;
    rst_n               : in std_logic;
    read_trigger        : in std_logic;
    read_period         : in std_logic;
    spi_state_cnt       : in std_logic_vector(15 downto 0);
    ad7177_dout         : in std_logic_vector(channel_num-1 downto 0);
    adc_result_data	    : out std_logic_vector(channel_num*(rx_data_width+rx_addr_width)-1 downto 0);
    adc_result_valid    : out std_logic
);
end component;
signal adc_result_data  : std_logic_vector((device_num+1)*(32+8)-1 downto 0);
signal adc_result_valid : std_logic;

constant wen_n:std_logic:='0';
constant wr_en:std_logic:='0';
constant rd_en:std_logic:='1';


constant id_reg:std_logic_vector(7 downto 0):=X"07";
constant data_reg:std_logic_vector(7 downto 0):=X"04";



signal	sample_en		: std_logic;	
signal m0_num_d                 : std_logic_vector(7 downto 0);
signal m0_num_change            : std_logic;
signal	ad_cfg_over		: std_logic;	
signal	data_lock		: std_logic;	
signal	check_data_n		: std_logic;	
signal	spi_cs_i		: std_logic;	


signal cnt_tx:integer range 0 to 15;
signal s1:integer range 0 to 31;
signal rx_num:integer range 0 to 15;




signal m_axis_tdata_temp0:std_logic_vector(1*device_num*32-1 downto 0);
signal m_axis_tdata_temp1:std_logic_vector(1*device_num*32-1 downto 0);
signal	rx_ad_data_temp_vld		: std_logic;	
signal	ad_data_buf_vld_i		: std_logic;	


signal  fp1_data                : std_logic_vector(23 downto 0);
signal  ad7177_dout_7_d1        : std_logic;
signal  ad7177_dout_7_d2        : std_logic;
signal  trigger_wait_cnt        : integer range 0 to 255;
signal  adc_data_read_trigger   : std_logic;
signal  adc_result_read_period  : std_logic;
signal  spi_state_cnt           : std_logic_vector(15 downto 0);
signal  ad7177_sck_initial      : std_logic;
signal  spi_clk_i               : std_logic;

attribute mark_debug:string;
attribute mark_debug of spi_mosi:signal is "true";
attribute mark_debug of spi_cs  :signal is "true";
attribute mark_debug of spi_clk	:signal is "true";
attribute mark_debug of s1                :signal is "true";
attribute mark_debug of ad7177_dout_7_d1  :signal is "true";
attribute mark_debug of ad7177_dout_7_d2  :signal is "true";
attribute mark_debug of trigger_wait_cnt  :signal is "true";
attribute mark_debug of ad7177_sck_initial:signal is "true";
attribute mark_debug of cnt_cycle_ov      :signal is "true";
attribute mark_debug of ad7177_sync       :signal is "true";


begin

INS_SPI_DRV:SPI_MASTER_V1 PORT MAP(
    clkin			    =>  clkin			    ,
    rst_n		    	=>  rst_n			    ,
    ----------------    =>  ----------------    ,
    s_axis_tvalid	    =>  s_axis_tvalid	    ,
    s_axis_tready	    =>  s_axis_tready	    ,
    s_axis_tdata	    =>  s_axis_tdata	    ,
    s_axis_tuser	    =>  s_axis_tuser	    ,
    s_axis_trst	        =>  s_axis_trst	        ,
    s_axis_tnum		    =>  s_axis_tnum		    ,
    ----------------    =>  ----------------    ,
    spi_rd_data		    =>  spi_rd_data		    ,
    spi_rd_vld		    =>  spi_rd_vld		    ,
    ----------------    =>  ----------------    ,
    sdo				    =>  spi_mosi		    ,
    cs				    =>  spi_cs_i	        ,
    sck				    =>  spi_clk_i			,
    sdi(device_num-1 downto 0)=>  spi_miso		,	
    sdi(device_num)			  =>  audi_in			
);

adc_result_inst:adc_7177_result_process PORT MAP(
    clkin               =>  clkin                   ,
    rst_n               =>  rst_n                   ,
    read_trigger        =>  adc_data_read_trigger   ,
    read_period         =>  adc_result_read_period  ,
    spi_state_cnt       =>  spi_state_cnt           ,
    ad7177_dout(device_num-1 downto 0)      =>  spi_miso                ,
    ad7177_dout(device_num)                 =>  audi_in                 ,
 	adc_result_data	    =>  adc_result_data         ,
	adc_result_valid    =>  adc_result_valid
);

-------------------------------------------------------------------

--spi_cs<=spi_cs_i and check_data_n;
spi_cs<='0' when (m0_num=X"12" and (s1=16 or s1=17)) else spi_cs_i when (m0_num=X"12") else (spi_cs_i and check_data_n);
spi_clk<=ad7177_sck_initial when (s1=17) else spi_clk_i;

process(clkin,rst_n)
variable cnt:integer;
begin
    if rst_n='0' then
         s1<=0;
         adc_check_sus<=(others=>'0');
         err_num<=(others=>'0');
         ad_cfg_over<='0';
         s_axis_trst<='0';
         cnt:=0;
         check_data_n<='1';
         ad_data_buf_vld_i<='0';
    else
        if rising_edge(clkin) then  
            if m0_num_change='1' then
                s1<=0;
                adc_check_sus<=(others=>'0');
                err_num<=(others=>'0');
                ad_cfg_over<='0';
                s_axis_trst<='0';
                cnt:=0;
                check_data_n<='1';
                ad_data_buf_vld_i<='0';
            elsif m0_num=X"24" then
                case s1 is
                    when 0=>
                        s_axis_trst<='1';
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=1;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;
                        cnt:=0;
                    
                    
                    when 1=>                            --等待1ms;
                        if cnt>=48*10**3-1 then
                            cnt:=0;
                            s1<=2;
                        else
                            cnt:=cnt+1;
                        end if;
                    
                        
                    when 2=>
                        s_axis_trst<='0';
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=wen_n&rd_en&id_reg(5 downto 0)&resv_data(31 downto 0);
                        s_axis_tuser<=spi_rd_cmd;
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=3;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;
                        adc_check_sus<=(others=>'0');
                        
                    when 3=>
                        -- if spi_rd_vld='1' and spi_rd_data(24-1 downto 8)=X"4fd" then      --ADC通信正常
                            -- s1<=2;
                            -- adc_check_sus<='1';
                        -- else
                            -- s1<=0;
                        -- end if;
                        if spi_rd_vld='1' then
                            for i in 0 to device_num-1 loop
                                if spi_rd_data(40*(i+1)-1-8 downto 20+40*i)=X"4FD" then
                                    adc_check_sus(i)<='1';
                                else
                                    adc_check_sus(i)<='0';
                                end if;
                            end loop;
                            s1<=14;
                        end if;
                        cnt_tx<=0;
    ----------------------配置过程，速率为10000sps 24位模式默认---------------------------------------
                    when 14=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        if cnt_tx=0 then
                            s_axis_tdata<=X"01_0000"&resv_data(15 downto 0); --配置使用外部基准源 
                        elsif cnt_tx=1 then
                            s_axis_tdata<=X"20_1f00"&resv_data(15 downto 0); --配置使用外部基准源 
                        elsif cnt_tx=2 then
                            s_axis_tdata<=X"21_1f00"&resv_data(15 downto 0); --配置使用外部基准源 
                        elsif cnt_tx=3 then
                            s_axis_tdata<=X"22_1f00"&resv_data(15 downto 0); --配置使用外部基准源  
                        elsif cnt_tx=4 then
                            s_axis_tdata<=X"23_1f00"&resv_data(15 downto 0); --配置使用外部基准源  
                        end if;
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s_axis_tvalid<='0';
                            if cnt_tx>=4 then
                                cnt_tx<=0;
                                s1<=15;
                            else
                                cnt_tx<=cnt_tx+1;
                            end if;
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;  
                    
                    when 15=>
                        s_axis_tnum<=conv_std_logic_vector(32,16);
                        if cnt_tx=0 then
                            s_axis_tdata<=X"38_55_5555"&resv_data(7 downto 0); --配置增益寄存器 
                        elsif cnt_tx=1 then
                            s_axis_tdata<=X"39_55_5555"&resv_data(7 downto 0); --配置增益寄存器 
                        end if; 
                        s_axis_tuser<=spi_wr_cmd;                    
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s_axis_tvalid<='0';
                            if cnt_tx>=1 then
                                cnt_tx<=0;
                                s1<=4;
                            else
                                cnt_tx<=cnt_tx+1;
                            end if;
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;                 
                    
                    when 4=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"02_0040"&resv_data(15 downto 0); --使能data_stat模式 24位转换结果    
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=11;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;  
    ----------------------多通道使能-----------------------------------------------------                    
                    when 11=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"10_8001"&resv_data(15 downto 0); --使能data_stat模式 24位转换结果    
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=12;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;                      
                        
                    when 12=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"11_8043"&resv_data(15 downto 0); --使能data_stat模式 24位转换结果    
                        s_axis_tuser<=spi_wr_cmd;  
                        ad_cfg_over<='1';
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=13;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;     
                        rx_num<=0;

                    -- when 13=>
                        -- s_axis_tnum<=conv_std_logic_vector(24,16);
                        -- s_axis_tdata<=X"12_8001"&resv_data(15 downto 0); --使能data_stat模式 24位转换结果    
                        -- s_axis_tuser<=spi_wr_cmd;  
                        -- if s_axis_tvalid='1' and s_axis_tready='1' then
                            -- s1<=14;
                            -- s_axis_tvalid<='0';
                        -- else
                            -- s1<=s1;
                            -- s_axis_tvalid<='1';
                        -- end if;   

                    -- when 14=>
                        -- s_axis_tnum<=conv_std_logic_vector(24,16);
                        -- s_axis_tdata<=X"13_8001"&resv_data(15 downto 0); --使能data_stat模式 24位转换结果    
                        -- s_axis_tuser<=spi_wr_cmd;  
                        -- if s_axis_tvalid='1' and s_axis_tready='1' then
                            -- s1<=5;
                            -- s_axis_tvalid<='0';
                        -- else
                            -- s1<=s1;
                            -- s_axis_tvalid<='1';
                        -- end if;   
                        
                        
     
                    when 5=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"01_8010"&resv_data(15 downto 0); --配置为单次转换模式 
                        s_axis_tuser<=spi_wr_cmd;                    
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=6;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;  
                        check_data_n<='1';
                        rx_num<=0;
    -------------------------------------------------------------------
                    when 6=>
                        ad_cfg_over<='1';
                        check_data_n<='0';
                        cnt:=0;
                        s1<=7;
                    
                    when 7=>
                        if cnt>=10 then
                            s1<=8;
                            cnt:=0;
                        else
                            cnt:=cnt+1;
                        end if;
                        
                    when 8=>
                        if spi_miso=resv_data(device_num-1 downto 0) then  ---miso='0'
                            s1<=9;
                            err_num<=(others=>'0');
                        elsif sample_en='1' then                        ---出现采集错误，ADC不能进行正常的通信，给出错误标识
                            s1<=9;
                            rx_num<=4;
                            err_num<=spi_miso;
                        end if;

                    when 9=>
                        s_axis_tnum<=conv_std_logic_vector(40,16);
                        s_axis_tdata<=wen_n&rd_en&data_reg(5 downto 0)&resv_data(31 downto 0);  
                        s_axis_tuser<=spi_rd_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=10;
                            rx_num<=rx_num+1;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if; 
                        ad_data_buf_vld_i<='0';
                    
                    when 10=>
                        if spi_rd_vld='1' then
                            if rx_num>=2 then
                                s1<=13;
                                ad_data_buf_vld_i<='1';
                            else
                                s1<=6;
                            end if;
                        else
                            s1<=s1;
                        end if;
                    
                        
                    when 13=>
                        rx_num<=0;
                        ad_data_buf_vld_i<='0';
                        if sample_en='1' or rx_num>=4 then
                            s1<=5;
                        else
                            s1<=s1;
                        end if;
                    
                    when others=>
                        s1<=0;
                end case;
            elsif m0_num=X"12" then
                case s1 is
                    when 0=>
                        s_axis_trst<='1';
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=1;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;
                        cnt:=0;
                    
                    when 1=>
                        if cnt>=48*10**3-1 then
                            cnt:=0;
                            s1<=2;
                        else
                            cnt:=cnt+1;
                        end if;
                        
                    when 2=>
                        s_axis_trst<='0';
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=wen_n&rd_en&id_reg(5 downto 0)&resv_data(31 downto 0);
                        s_axis_tuser<=spi_rd_cmd;
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=3;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;
                        adc_check_sus<=(others=>'0');
                        
                    when 3=>
                        if spi_rd_vld='1' then
                            for i in 0 to device_num-1 loop
                                if spi_rd_data(40*(i+1)-1-8 downto 20+40*i)=X"4FD" then
                                    adc_check_sus(i)<='1';
                                else
                                    adc_check_sus(i)<='0';
                                end if;
                            end loop;
                            s1<=14;
                        end if;
                        cnt_tx<=0;

                    when 14=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        if cnt_tx=0 then
                            s_axis_tdata<=X"01_8000"&resv_data(15 downto 0);
                        elsif cnt_tx=1 then
                            s_axis_tdata<=X"20_1f00"&resv_data(15 downto 0);
                        elsif cnt_tx=2 then
                            s_axis_tdata<=X"21_1f00"&resv_data(15 downto 0);
                        elsif cnt_tx=3 then
                            s_axis_tdata<=X"22_1f00"&resv_data(15 downto 0);
                        elsif cnt_tx=4 then
                            s_axis_tdata<=X"23_1f00"&resv_data(15 downto 0);
                        end if;
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s_axis_tvalid<='0';
                            if cnt_tx>=4 then
                                cnt_tx<=0;
                                s1<=15;
                            else
                                cnt_tx<=cnt_tx+1;
                            end if;
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;  
                    
                    when 15=>
                        s_axis_tnum<=conv_std_logic_vector(32,16);
                        if cnt_tx=0 then
                            s_axis_tdata<=X"38_55_5555"&resv_data(7 downto 0);
                        elsif cnt_tx=1 then
                            s_axis_tdata<=X"39_55_5555"&resv_data(7 downto 0);
                        end if; 
                        s_axis_tuser<=spi_wr_cmd;                    
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s_axis_tvalid<='0';
                            if cnt_tx>=1 then
                                cnt_tx<=0;
                                s1<=11;
                            else
                                cnt_tx<=cnt_tx+1;
                            end if;
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;                 
                    
                    when 11=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"10_8001"&resv_data(15 downto 0);
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=12;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;                      
                        
                    when 12=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"11_0043"&resv_data(15 downto 0);
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=13;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;     

                    ------------------------------------------------------------------
                    ------------------------------------------------------------------
                    --when 6=>
                    --    ad_data_buf_vld_i<='0';
                    --    s1<=8;
                    --
                    --when 8=>
                    --    if sample_en='1' then
                    --        s1<=9;
                    --        err_num<=spi_miso;
                    --    end if;
                    --
                    --when 9=>
                    --    s_axis_tnum<=conv_std_logic_vector(40,16);
                    --    s_axis_tdata<=wen_n&rd_en&data_reg(5 downto 0)&resv_data(31 downto 0);  
                    --    s_axis_tuser<=spi_rd_cmd;  
                    --    if s_axis_tvalid='1' and s_axis_tready='1' then
                    --        s1<=10;
                    --        s_axis_tvalid<='0';
                    --    else
                    --        s1<=s1;
                    --        s_axis_tvalid<='1';
                    --    end if; 
                    --    ad_data_buf_vld_i<='0';
                    --
                    --when 10=>
                    --    if spi_rd_vld='1' then
                    --        s1<=6;
                    --        ad_data_buf_vld_i<='1';
                    --    else
                    --        s1<=s1;
                    --    end if;
                    when 16=>
                        if cnt_cycle_ov='1' then
                            s1<=17;
                        end if;
                        
                    when 17=>
                        s1<=s1;
                    ------------------------------------------------------------------
                    ------------------------------------------------------------------
                    
                    when 13=>
                        s_axis_tnum<=conv_std_logic_vector(24,16);
                        s_axis_tdata<=X"02_10c0"&resv_data(15 downto 0);
                        s_axis_tuser<=spi_wr_cmd;  
                        if s_axis_tvalid='1' and s_axis_tready='1' then
                            s1<=16;
                            s_axis_tvalid<='0';
                        else
                            s1<=s1;
                            s_axis_tvalid<='1';
                        end if;
                    
                    when others=>
                        s1<=0;
                end case;
            end if;
        end if;
    end if;
end process;

sample_en<=sample_start;
process(clkin,rst_n)
begin
    if rst_n='0' then
        m0_num_change<='0';
        m0_num_d<=X"24";
    else
        if rising_edge(clkin) then
            m0_num_d<=m0_num;
            if m0_num=X"12" and m0_num_d=X"24" then
                m0_num_change<='1';
            elsif m0_num=X"24" and m0_num_d=X"12" then
                m0_num_change<='1';
            else
                m0_num_change<='0';
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad7177_sync<='0';
    else
        if rising_edge(clkin) then
            if cnt_cycle=X"000000C8" and s1=17 then
                ad7177_sync<='1';
            elsif cnt_cycle=X"000003E8" and s1=17 then
                ad7177_sync<='0';
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad7177_dout_7_d1<='1';
        ad7177_dout_7_d2<='1';
    else
        if rising_edge(clkin) then
            ad7177_dout_7_d1<=spi_miso(7);
            ad7177_dout_7_d2<=ad7177_dout_7_d1;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        trigger_wait_cnt<=0;
    else
        if rising_edge(clkin) then
            if ad7177_dout_7_d2='1' and ad7177_dout_7_d1='0' and spi_state_cnt=X"0000" and s1=17 then
                trigger_wait_cnt<=32;
            elsif not(trigger_wait_cnt=0) then
                trigger_wait_cnt<=trigger_wait_cnt-1;
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        adc_data_read_trigger<='0';
    else
        if rising_edge(clkin) then
            if trigger_wait_cnt=1 then
                adc_data_read_trigger<='1';
            else
                adc_data_read_trigger<='0';
            end if;
         end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        spi_state_cnt<=X"0000";
    else
        if rising_edge(clkin) then
            if adc_data_read_trigger='1' then
                spi_state_cnt<=X"0400";
            elsif not(spi_state_cnt=X"0000") then
                spi_state_cnt<=spi_state_cnt-'1';
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        adc_result_read_period<='0';
    else
        if rising_edge(clkin) then
            if adc_data_read_trigger='1' then
                adc_result_read_period<='1';
            elsif spi_state_cnt=X"0001" then
                adc_result_read_period<='0';
            end if;
        end if;
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad7177_sck_initial<='1';
    else
        if rising_edge(clkin) then
            if spi_state_cnt(4 downto 0)=31 then
                ad7177_sck_initial<='0';
            elsif spi_state_cnt(4 downto 0)=15 then
                ad7177_sck_initial<='1';
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------------------------
--------------------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        data_lock<='0';
        rx_ad_data_temp_vld<='0';
    else
        if rising_edge(clkin) then
            for i in 0 to device_num-1 loop     ---锁存数据
                if spi_rd_vld='1' and data_lock='0' and spi_rd_data(37 downto 32)=data_reg(5 downto 0) then
                    m_axis_tdata_temp0(32*(i+1)-1 downto 32*i)<=spi_rd_data(40*(i+1)-8-1 downto 40*i);
                end if;
            end loop;
            
            for i in 0 to device_num-1 loop    ---锁存数据
                if spi_rd_vld='1' and data_lock='1' and  spi_rd_data(37 downto 32)=data_reg(5 downto 0) then
                    m_axis_tdata_temp1(32*(i+1)-1 downto 32*i)<=spi_rd_data(40*(i+1)-8-1 downto 40*i);
                end if;
            end loop;
            
            
            if spi_rd_vld='1' and  spi_rd_data(37 downto 32)=data_reg(5 downto 0) then  ---进行双通道数据匹配
                data_lock<= not data_lock;
            else
                data_lock<=data_lock;
            end if;
            
            if spi_rd_vld='1' and data_lock='1' then            --锁存标识
                rx_ad_data_temp_vld<='1';
            else
                rx_ad_data_temp_vld<='0';
            end if;
            
            if rx_ad_data_temp_vld='1' then     ---数据输出
                m_axis_tdata<=m_axis_tdata_temp0&m_axis_tdata_temp1;
                m_axis_tvalid<='1';
            else
                m_axis_tvalid<='0';
            end if;
        end if;
    end if;
end process;
---------------------------数据锁存----------------------------------------
g1:for i in 0 to device_num-1 generate

begin
 
process(clkin,rst_n)
begin
    if rst_n='0' then
            
    elsif rising_edge(clkin) then
        if spi_rd_vld='1' and spi_rd_data(37+40*i downto 32+40*i)=data_reg(5 downto 0)  then
            if  spi_rd_data(1+40*i downto 0+40*i)="00" then
                ad_data_buf(0+2*i)<=spi_rd_data(31+40*i downto 8+40*i);
            elsif spi_rd_data(1+40*i downto 0+40*i)="01" then
                ad_data_buf(1+2*i)<=spi_rd_data(31+40*i downto 8+40*i);
            end if;
        end if;  
    end if;
end process;

end generate;

process(clkin,rst_n)    ---音频数据接收
begin
    if rst_n='0' then
        adui_data<=(others=>'0');    
    elsif rising_edge(clkin) then
        if spi_rd_vld='1' and spi_rd_data(37+40*device_num downto 32+40*device_num)=data_reg(5 downto 0)  then
            if  spi_rd_data(1+40*device_num downto 0+40*device_num)="00" then
                adui_data<=spi_rd_data(31+40*device_num downto 8+40*device_num);
            end if;
        end if;  
    end if;
end process;

process(clkin,rst_n)
begin
    if rst_n='0' then
        fp1_data<=(others=>'0');
    elsif rising_edge(clkin) then
        if spi_rd_vld='1' and spi_rd_data(37 downto 32)=data_reg(5 downto 0)  then
            if spi_rd_data(1 downto 0)="00" then
                fp1_data<=spi_rd_data(31 downto 8);
            end if;
        end if;
    end if;
end process;

ad_data_buf_vld<=ad_data_buf_vld_i;


end Behavioral;
