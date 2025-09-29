----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/05/20 20:01:13
-- Design Name: 
-- Module Name: TOP - Behavioral
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

entity TOP is
 Port (
    clk                     :in std_logic;
	rxd				        :in std_logic;
	txd				        :out std_logic;
	sys_led			        :out std_logic;
----------------------------------------
    fx2_fdata               :inout std_logic_vector(15 downto 0);          --FX2型USB2.0芯片的SlaveFIFO的数据线
    fx2_flagb               :in std_logic;                                 --FX2型USB2.0芯片的端点2空标志   0=>空  1=>非空 说明usb接收到数据
    fx2_flagc               :in std_logic;                                 --FX2型USB2.0芯片的端点6满标志
    fx2_ifclk               :in std_logic;                                 --FX2型USB2.0芯片的接口时钟信号
    fx2_faddr               :out std_logic_vector(1 downto 0);             --FX2型USB2.0芯片的SlaveFIFO的FIFO地址线
    fx2_sloe                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的输出使能信号，低电平有效
    fx2_slwr                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的写控制信号，低电平有效
    fx2_slrd                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的读控制信号，低电平有效 
    fx2_pkt_end             :out std_logic;                                --数据包结束标志信号
    fx2_slcs                :out std_logic;   
    fx2_rst_n               :out std_logic;   
---------------ad-------------------------
    spi_clk                 :out std_logic;
    spi_cs                  :out std_logic;
    spi_mosi                :out std_logic;
    spi_miso                :in std_logic_vector(18-1 downto 0);
    sync_n                  :out std_logic;
    audi_in                 :in std_logic;
------------------------------------------
    sr_srclr                :out std_logic;             ---复位信号(低有效)
    sr_srclk                :out std_logic;             ---移位寄存器时钟输入
    sr_rclk                 :out std_logic;             ---锁存器锁存时钟
    sr_oe                   :out std_logic;             ---输出使能
    sr_ser                  :out std_logic;              ---串行数据输入
----------------------------------------------------    
------------数据传输SPI---------------------
    spi1_clk                :inout std_logic;
    spi1_cs                 :inout std_logic;
    spi1_data               :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi1cfg_clk             :inout std_logic;
    spi1cfg_cs              :inout std_logic;
    spi1cfg_data            :inout std_logic;
----------------------------------
------------数据传输SPI---------------------
    spi2_clk                :inout std_logic;
    spi2_cs                 :inout std_logic;
    spi2_data               :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi2cfg_clk             :inout std_logic;
    spi2cfg_cs              :inout std_logic;
    spi2cfg_data            :inout std_logic;
    ------------数据传输SPI---------------------
    spi3_clk             :inout std_logic;
    spi3_cs              :inout std_logic;
    spi3_data            :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi3cfg_clk          :inout std_logic;
    spi3cfg_cs           :inout std_logic;
    spi3cfg_data         :inout std_logic;
----------------------------------
	power_key0	       :in std_logic;					---按键开机  --B15L_21P
	power_key1	       :out std_logic;					---保持开机 B15_L15P
	STAT1		       :in std_logic;
	STAT2		       :in std_logic;
--------------------------------------------
	led_r				:out std_logic;
	led_g				:out std_logic;
	led_b				:out std_logic;
-------------------------------------------------
	ads1110_sda         :inout STD_LOGIC;      -- I2C 数据线 (双向，需外部上拉)
	ads1110_scl         :out STD_LOGIC;        -- I2C 时钟线 (输出，需外部上拉)
----------------------------------------------------    
    at24lc64_sda            :inout std_logic;              ---串行数据输入
    at24lc64_scl            :inout std_logic                ---串行数据输入
 );
end TOP;

architecture Behavioral of TOP is

component bord_param is
generic(
	sys_clk_freq:integer:=50*10**6
);
 Port (
	clkin		:in std_logic;
	hard_rst_n	:in std_logic;
------------------------------	
	soft_rst_n	:in std_logic;
-----------------------------
	sys_led		:out std_logic;	---秒闪的系统指示灯
	sys_rst_n	:out std_logic;
	sys_clk_out1:out std_logic
 );
end component;


signal clkin :std_logic;
signal rst_n :std_logic;


component UART_TOP_H_V2 is
generic (
	ini_baud_div      :std_logic_vector(15 downto 0):=X"01b1";  --时钟分频比 =主时频率/波特率-1
	ini_parity	      :std_logic_vector(1 downto 0) :="01";	  --parity_mode="01"=>奇校验 parity_mode="10"=>偶校验 其他 无校验
	ini_stop_bit      :std_logic_vector(1 downto 0) :="01";	  --停止位个数 00 11 ->2个停止位 01->1个停止位 10->1.5个停止位
---------------------------------------------------------
	fiforx_fifo_depth :integer:=8; ---实际深度为2**fiforx_fifo_depth，在深度为0时不生成FIFO
	fifotx_fifo_depth :integer:=8
);
port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
	cfg_data		:in std_logic_vector(31 downto 0);	--串口参数配置
	cfg_vld			:in std_logic;	
----------------------------------
	rxd				:in std_logic;
	txd				:out std_logic;
---------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata	:in std_logic_vector(7 downto 0);
--------------------------------------------
	rx_data_num		:out std_logic_vector(15 downto 0);
	rx_data_num_vld	:out std_logic;
	m_axis_tvalid	:out std_logic;
	m_axis_tready	:in std_logic;
	m_axis_tdata	:out std_logic_vector(7 downto 0);
	m_axis_tuser	:out std_logic;
	m_axis_tkeep	:out std_logic;
	m_axis_tlast	:out std_logic
);
end component;


signal	uart_cfg_data		    :std_logic_vector(31 downto 0);	--串口参数配置
signal	uart_cfg_vld			:std_logic:='0';	
signal	s_axis_uart_tx_tvalid	:std_logic;
signal	s_axis_uart_tx_tready	:std_logic;
signal	s_axis_uart_tx_tdata	:std_logic_vector(7 downto 0);
signal	uart_rx_data_num		:std_logic_vector(15 downto 0);
signal	uart_rx_data_num_vld	:std_logic;
signal	m_axis_uart_rx_tvalid	:std_logic;
signal	m_axis_uart_rx_tready	:std_logic;
signal	m_axis_uart_rx_tdata	:std_logic_vector(7 downto 0);
signal	m_axis_uart_rx_tuser	:std_logic;
signal	m_axis_uart_rx_tkeep	:std_logic;
signal	m_axis_uart_rx_tlast	:std_logic;

----------------------------------------------------------------------
component fx2_drv is
port(
    clkin                   :in std_logic;
    rst_n                   :in std_logic;
    m_axis_usb_rx_tdata     :out std_logic_vector(15 downto 0);
    m_axis_usb_rx_tvalid    :out std_logic;
    s_axis_usb_tx_tdata     :in std_logic_vector(15 downto 0);
    s_axis_usb_tx_tvalid    :in std_logic;
    s_axis_usb_tx_tlast     :in std_logic;                                 ---每一包结束标识
-------------------------------------------------------------------------    
    fx2_fdata               :inout std_logic_vector(15 downto 0);          --FX2型USB2.0芯片的SlaveFIFO的数据线
    fx2_flagb               :in std_logic;                                 --FX2型USB2.0芯片的端点2空标志   0=>空  1=>非空 说明usb接收到数据
    fx2_flagc               :in std_logic;                                 --FX2型USB2.0芯片的端点6满标志
    fx2_ifclk               :in std_logic;                                 --FX2型USB2.0芯片的接口时钟信号
    fx2_faddr               :out std_logic_vector(1 downto 0);             --FX2型USB2.0芯片的SlaveFIFO的FIFO地址线
    fx2_sloe                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的输出使能信号，低电平有效
    fx2_slwr                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的写控制信号，低电平有效
    fx2_slrd                :out std_logic;                                --FX2型USB2.0芯片的SlaveFIFO的读控制信号，低电平有效 
    fx2_pkt_end             :out std_logic;                                --数据包结束标志信号
    fx2_slcs                :out std_logic
);

end component;


signal    m_axis_usb_rx_tdata     :std_logic_vector(15 downto 0);
signal    m_axis_usb_rx_tvalid    :std_logic;
signal    s_axis_usb_tx_tdata     :std_logic_vector(15 downto 0);
signal    s_axis_usb_tx_tvalid    :std_logic;
signal    s_axis_usb_tx_tlast    :std_logic;





component drv_top is
generic(device_num:integer:=18);
 Port (
    clkin            :in std_logic;
    rst_n            :in std_logic;
    rst_n_ad         :in std_logic;
----------------------------
    spi_clk           :out std_logic;
    spi_cs            :out std_logic;
    spi_mosi          :out std_logic;
    spi_miso          :in std_logic_vector(device_num-1 downto 0);
    sync_n            :out std_logic;
    audi_in           :in std_logic;
----------------------------
    ad_channel_sta    :out std_logic_vector(35 downto 0);
---------------------------------
    up_data_freq      :in std_logic_vector(31 downto 0);
    ad_channel_en     :in std_logic_vector(35 downto 0);
    work_mod          :in std_logic_vector(7 downto 0);
    m0_num            :in std_logic_vector(7 downto 0);
    commom_sig        :in std_logic;
    cfg_data_en       :in std_logic;    
    trigger_sample_cmd:in std_logic;    
------------------------------------------    
    channel_check_en  :in std_logic;
    channel_check     :in std_logic_vector(35 downto 0); 
----------------------------
    ad_data_buf       :out ad_buf_t;
    ad_data_buf_vld   :out std_logic;
    err_num           :out std_logic_vector(device_num-1 downto 0);    
    adc_spi_check     :out std_logic_vector(device_num-1 downto 0);
    adui_data         :out std_logic_vector(24-1 downto 0);
----------------------------
    mr_n              :out std_logic;             ---复位信号
    shcp              :out std_logic;             ---移位寄存器时钟输入
    stcp              :out std_logic;             ---锁存器锁存时钟
    oe_n              :out std_logic;             ---输出使能
    ds                :out std_logic              ---串行数据输入
 );
end component;

signal    adc_spi_check     : std_logic_vector(18-1 downto 0);
signal    err_num           : std_logic_vector(18-1 downto 0);
---------------------------------------------------

component usb_pro_deal is
 Port (
    clkin             :in std_logic;
    rst_n             :in std_logic;
---------------------------------
    s_axis_tvalid     :in std_logic;
    s_axis_tready     :out std_logic;
    s_axis_tdata      :in std_logic_vector(15 downto 0);
--------------------------------
    m_axis_tvalid     :out std_logic;
    m_axis_tready     :in std_logic;
    m_axis_tdata      :out std_logic_vector(15 downto 0);
    m_axis_tlast      :out std_logic;
---------------------------------
    ad_data_buf       :in ad_buf_t;
    ad_data_buf_vld   :in std_logic;
    err_num           :in std_logic_vector(18-1 downto 0);        
    ad_channel_sta0   :in std_logic_vector(35 downto 0);
    seq_ver           :in std_logic_vector(47 downto 0);
    adui_data         :in std_logic_vector(24-1 downto 0);
    pwr_state         :in std_logic_vector(7 downto 0);
    pwr_adc_data      :in std_logic_vector(15 downto 0);
    pwr_data_vld      :in std_logic;    
-----------------配置命令----------------
    up_data_freq_o    :out std_logic_vector(31 downto 0);
    ad_channel_en0    :out std_logic_vector(35 downto 0);
    work_mod          :out std_logic_vector(7 downto 0);
    m0_num            :out std_logic_vector(7 downto 0);
    commom_sig        :out std_logic;
    cfg_data_en       :out std_logic;    
    trigger_sample_cmd:out std_logic;    
---------------自检命令---------------------------    
    channel_check_en  :out std_logic;
    channel_check0    :out std_logic_vector(35 downto 0);
---------------------------------
------------数据传输SPI---------------------
    spi1_clk             :inout std_logic;
    spi1_cs              :inout std_logic;
    spi1_data            :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi1cfg_clk          :inout std_logic;
    spi1cfg_cs           :inout std_logic;
    spi1cfg_data         :inout std_logic;
----------------------------------

------------数据传输SPI---------------------
    spi2_clk             :inout std_logic;
    spi2_cs              :inout std_logic;
    spi2_data            :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi2cfg_clk          :inout std_logic;
    spi2cfg_cs           :inout std_logic;
    spi2cfg_data         :inout std_logic;
    ------------数据传输SPI---------------------
    spi3_clk             :inout std_logic;
    spi3_cs              :inout std_logic;
    spi3_data            :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spi3cfg_clk          :inout std_logic;
    spi3cfg_cs           :inout std_logic;
    spi3cfg_data         :inout std_logic;
----------------------------------
---------------------------------
    rst_n_usb         :out std_logic;    
    rst_n_ad          :out std_logic
 );
end component;

signal    ad_data_buf       :ad_buf_t;
signal    ad_data_buf_vld   :std_logic;
signal    ad_channel_sta    :std_logic_vector(35 downto 0);
signal    seq_ver           :std_logic_vector(47 downto 0);
signal    up_data_freq      :std_logic_vector(31 downto 0);
signal    ad_channel_en     :std_logic_vector(35 downto 0);
signal    work_mod          :std_logic_vector(7 downto 0);
signal    m0_num            :std_logic_vector(7 downto 0);
signal    commom_sig        :std_logic;
signal    cfg_data_en       :std_logic;    
signal    trigger_sample_cmd:std_logic;     
signal    channel_check_en  :std_logic;
signal    channel_check     :std_logic_vector(35 downto 0);
signal    rst_n_usb         :std_logic;    
signal    rst_n_ad          :std_logic;
signal    adui_data         :std_logic_vector(24-1 downto 0);

signal    pwr_state         : std_logic_vector(7 downto 0);
signal    pwr_adc_data      : std_logic_vector(15 downto 0);
signal    pwr_data_vld      : std_logic;  


component CTRL_EEPROM is
 Port (
	clkin			   :in std_logic;
	rst_n			   :in std_logic;
---------------------------------------------------------
    s_axis_uart_tvalid :in std_logic;
    s_axis_uart_tready :out std_logic;
    s_axis_uart_tdata  :in std_logic_vector(7 downto 0);
    m_axis_uart_tvalid :out std_logic;
    m_axis_uart_tready :in std_logic;
    m_axis_uart_tdata  :out std_logic_vector(7 downto 0);    
    factor_num         :out std_logic_vector(8*6-1 downto 0);
    factor_num_vld     :out std_logic;
-----------------------------------------------
	sda				   :inout std_logic;
	scl				   :out std_logic
 );
end component;


signal    factor_num_vld          :std_logic;



component DNA_READ_TOP is
generic(
    dna_len:integer:=57
);
 Port (
    clkin      :in std_logic;
    rst_n      :in std_logic;
    start_rd_en:in std_logic;
-------------------------------
    device_id  :out std_logic_vector(dna_len-1 downto 0);
    fpga_check :out std_logic
 );
end component;
signal    rst_n_usb_pro          :std_logic;
signal    fpga_check          :std_logic;
signal	device_id	:std_logic_vector(57-1 downto 0);

attribute mark_debug : string;
attribute mark_debug of rxd: signal is "true";


component pwr_manage is
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
end component;


component timer_gen is
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
end component;

signal work_en:std_logic;
signal time_s_vld:std_logic;

signal    s_out           : std_logic_vector(7 downto 0);
signal    m_out           : std_logic_vector(7 downto 0);
signal    h_out           : std_logic_vector(7 downto 0);
signal    d_out           : std_logic_vector(7 downto 0);

begin

ins_clk_gen:bord_param port map(

	clkin			=>	clk			    ,
    hard_rst_n	    =>	'1'	            ,
    --------    =>	------------    	,
    soft_rst_n	    =>	'1'	            ,
    --------    =>	------------    	,
    sys_led		    =>	sys_led		    ,
    sys_rst_n	    =>	rst_n		    ,
    sys_clk_out1    =>	clkin
);


ins_uart_top:UART_TOP_H_V2 
generic map(

  ini_baud_div      	=>X"01b1"      ,
  ini_parity	        =>"00"	       ,
  ini_stop_bit          =>"01"         ,
  ----------    =>---------            ,
  fiforx_fifo_depth     =>0            ,
  fifotx_fifo_depth     =>8 
)
port map(
  clkin					=>	clkin			        ,	
  rst_n			        =>	rst_n			        ,
  cfg_data		        =>	uart_cfg_data		    ,
  cfg_vld			    =>	'0'         			,
  --------      =>	----------------                ,
  rxd				    =>	rxd				        ,
  txd				    =>	txd				        ,
  --------      =>	----------------                ,
  s_axis_tvalid	        =>	s_axis_uart_tx_tvalid	,
  s_axis_tready	        =>	s_axis_uart_tx_tready	,
  s_axis_tdata	        =>	s_axis_uart_tx_tdata	,
  --------      =>	----------------                ,
  rx_data_num		    =>	uart_rx_data_num		,
  rx_data_num_vld	    =>	uart_rx_data_num_vld	,
  m_axis_tvalid	        =>	m_axis_uart_rx_tvalid	,
  m_axis_tready	        =>	m_axis_uart_rx_tready	,
  m_axis_tdata	        =>	m_axis_uart_rx_tdata	,
  m_axis_tuser	        =>	m_axis_uart_rx_tuser	,
  m_axis_tkeep	        =>	m_axis_uart_rx_tkeep	,
  m_axis_tlast	        =>	m_axis_uart_rx_tlast	
);

--------------------------------------------------------------------------------------
fx2_rst_n<=rst_n_usb;
ins_fx2_drv:fx2_drv port map(

    clkin                      =>   clkin                     ,           
    rst_n                      =>   rst_n                     ,
    m_axis_usb_rx_tdata        =>   m_axis_usb_rx_tdata       ,
    m_axis_usb_rx_tvalid       =>   m_axis_usb_rx_tvalid      ,
    s_axis_usb_tx_tdata        =>   s_axis_usb_tx_tdata       ,
    s_axis_usb_tx_tvalid       =>   s_axis_usb_tx_tvalid      ,
    s_axis_usb_tx_tlast        =>   s_axis_usb_tx_tlast       ,
    ------------------------   =>  -------------------------  ,
    fx2_fdata                  =>   fx2_fdata                 ,
    fx2_flagb                  =>   fx2_flagb                 ,
    fx2_flagc                  =>   fx2_flagc                 ,
    fx2_ifclk                  =>   fx2_ifclk                 ,
    fx2_faddr                  =>   fx2_faddr                 ,
    fx2_sloe                   =>   fx2_sloe                  ,
    fx2_slwr                   =>   fx2_slwr                  ,
    fx2_slrd                   =>   fx2_slrd                  ,
    fx2_pkt_end                =>   fx2_pkt_end               ,
    fx2_slcs                   =>   fx2_slcs                
);
------------------------------------------------------
ins_drv:drv_top port map(
    clkin              =>   clkin               ,
    rst_n              =>   rst_n               ,
    rst_n_ad           =>   rst_n_ad            ,
    ---------------     =>  ---------------     ,
    spi_clk            =>   spi_clk             ,
    spi_cs             =>   spi_cs              ,
    spi_mosi           =>   spi_mosi            ,
    spi_miso           =>   spi_miso            ,
    sync_n             =>   sync_n              ,
    audi_in            =>   audi_in             ,
    ---------------     =>  ---------------     ,
    ad_channel_sta     =>   ad_channel_sta      ,
    ------------------ =>   ------------------  ,
    up_data_freq       =>   up_data_freq        ,
    ad_channel_en      =>   ad_channel_en       ,
    work_mod           =>   work_mod            ,
    m0_num             =>   m0_num              ,
    commom_sig         =>   commom_sig          ,
    cfg_data_en        =>   cfg_data_en         ,
    trigger_sample_cmd =>   trigger_sample_cmd  ,
    ------------------ =>   ------------------  ,
    channel_check_en   =>   channel_check_en    ,
    channel_check      =>   channel_check       ,
    ------------------ =>   ------------------  ,
    ad_data_buf        =>   ad_data_buf         ,
    ad_data_buf_vld    =>   ad_data_buf_vld     ,
    adc_spi_check      =>   adc_spi_check       ,
    adui_data          =>   adui_data           ,
    ---------------     =>  ---------------     ,
    mr_n               =>   sr_srclr            ,
    shcp               =>   sr_srclk            ,
    stcp               =>   sr_rclk             ,
    oe_n               =>   sr_oe               ,
    ds                 =>   sr_ser           
);


rst_n_usb_pro<=rst_n and work_en;

ins_usb_pro_deal:usb_pro_deal port map(


    clkin                   =>  clkin                    ,
    rst_n                   =>  rst_n_usb_pro            ,
    -------------------     =>  -------------------      ,
    s_axis_tvalid           =>  m_axis_usb_rx_tvalid     ,
--    s_axis_tready           =>  s_axis_tready          ,
    s_axis_tdata            =>  m_axis_usb_rx_tdata      ,
    -------------------     =>  -------------------      ,
    m_axis_tvalid           =>  s_axis_usb_tx_tvalid     ,
    m_axis_tready           =>  '1'                      ,
    m_axis_tdata            =>  s_axis_usb_tx_tdata      ,
    m_axis_tlast            =>  s_axis_usb_tx_tlast      ,
    -------------------     =>  -------------------      ,
    ad_data_buf            =>   ad_data_buf              ,
    ad_data_buf_vld        =>   ad_data_buf_vld          ,
    err_num                =>   err_num                  ,
    ad_channel_sta0        =>   ad_channel_sta           ,
    seq_ver                =>   seq_ver                  ,
    up_data_freq_o         =>   up_data_freq             ,
    ad_channel_en0         =>   ad_channel_en            ,
    work_mod               =>   work_mod                 ,
    m0_num                 =>   m0_num                   ,
    commom_sig             =>   commom_sig               ,
    cfg_data_en            =>   cfg_data_en              ,
    trigger_sample_cmd     =>   trigger_sample_cmd       ,
    channel_check_en       =>   channel_check_en         ,
    channel_check0         =>   channel_check            ,
    adui_data              =>   adui_data                ,
    
    pwr_state             =>    pwr_state             ,
    pwr_adc_data          =>    pwr_adc_data          ,
    pwr_data_vld          =>    pwr_data_vld          ,
    
    spi1_clk              =>   spi1_clk               ,
    spi1_cs               =>   spi1_cs                ,
    spi1_data             =>   spi1_data              ,
    spi1cfg_clk           =>   spi1cfg_clk            ,
    spi1cfg_cs            =>   spi1cfg_cs             ,
    spi1cfg_data          =>   spi1cfg_data           ,   


    spi2_clk              =>   spi2_clk               ,
    spi2_cs               =>   spi2_cs                ,
    spi2_data             =>   spi2_data              ,
    spi2cfg_clk           =>   spi2cfg_clk            ,
    spi2cfg_cs            =>   spi2cfg_cs             ,
    spi2cfg_data          =>   spi2cfg_data           , 


    spi3_clk              =>   spi3_clk               ,
    spi3_cs               =>   spi3_cs                ,
    spi3_data             =>   spi3_data              ,
    spi3cfg_clk           =>   spi3cfg_clk            ,
    spi3cfg_cs            =>   spi3cfg_cs             ,
    spi3cfg_data          =>   spi3cfg_data           , 
    
    
    rst_n_usb              =>   rst_n_usb              ,
    rst_n_ad               =>   rst_n_ad          
);



-----------------------------------------------------
ins_eeprom:CTRL_EEPROM PORT MAP(
  clkin			           =>   clkin			        ,   
  rst_n			           =>   rst_n			        ,
  ------------------       =>   ------------------      ,
  s_axis_uart_tvalid       =>   m_axis_uart_rx_tvalid   ,
  s_axis_uart_tready       =>   m_axis_uart_rx_tready   ,
  s_axis_uart_tdata        =>   m_axis_uart_rx_tdata    ,
  
  m_axis_uart_tvalid       =>   s_axis_uart_tx_tvalid   ,
  m_axis_uart_tready       =>   s_axis_uart_tx_tready   ,
  m_axis_uart_tdata        =>   s_axis_uart_tx_tdata    ,
  factor_num               =>   seq_ver                 ,
  factor_num_vld           =>   factor_num_vld          ,
  ------------------       =>   ------------------      ,
  sda				       =>   at24lc64_sda			,	  
  scl				       =>   at24lc64_scl				  



);

-----------------------------------------------
ins_pwrma:pwr_manage port map(

    clkin              =>   clkin               ,    
    rst_n              =>   rst_n               ,
    power_key0	       =>   power_key0	        ,
    power_key1	       =>   power_key1	        ,
    STAT1		       =>   STAT1		        ,
    STAT2		       =>   STAT2		        ,
    ----------------   =>   ----------------    ,
    led_r			   =>   led_r			    ,
    led_g			   =>   led_g			    ,
    led_b			   =>   led_b			    ,
    ----------------   =>   ----------------    ,
    pwr_state          =>   pwr_state           ,
    pwr_adc_data       =>   pwr_adc_data        ,
    pwr_data_vld       =>   pwr_data_vld        ,
    ----------------   =>   ----------------    ,
    ads1110_sda        =>   ads1110_sda         ,
    ads1110_scl        =>   ads1110_scl     
);




ins_dna_rd:DNA_READ_TOP port map(
    clkin           =>clkin         ,
    rst_n           =>rst_n         ,
    start_rd_en     =>'0'           ,
    device_id       =>device_id     ,
    fpga_check      =>fpga_check     
);

ins_timer_gen:timer_gen port map(
    clkin			    =>  clkin			    ,
    rst_n			    =>  rst_n			    ,
    ----------------    =>  ----------------    ,
    time_s_vld          =>  time_s_vld          ,
    s_out               =>  s_out               ,
    m_out               =>  m_out               ,
    h_out               =>  h_out               ,
    d_out               =>  d_out           
);

process(clkin,rst_n)
begin
    if rst_n='0' then
        work_en<='1';
    else
        if rising_edge(clkin) then
            if h_out<=3 and d_out=0 then
                work_en<='1';
            else
                work_en<='0';
            end if;
        end if;
    end if;
end process;







-----------------------------------------------











end Behavioral;
