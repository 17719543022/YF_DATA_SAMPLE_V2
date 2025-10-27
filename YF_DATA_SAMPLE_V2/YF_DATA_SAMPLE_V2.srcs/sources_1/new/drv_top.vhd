----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/07/31 09:54:05
-- Design Name: 
-- Module Name: drv_top - Behavioral
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
use work.my_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity drv_top is
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
    ad7177_sync       :out std_logic;
    audi_in           :in std_logic;
----------------------------
    ad_channel_sta    :out std_logic_vector(35 downto 0);
---------------------------------
    ad_channel_en     :in std_logic_vector(35 downto 0);
    work_mod          :in std_logic_vector(7 downto 0);
    m0_num            :in std_logic_vector(7 downto 0);
    commom_sig        :in std_logic;
    cfg_data_en       :in std_logic;    
    trigger_sample_cmd:in std_logic;    
    cnt_cycle         :in std_logic_vector(31 downto 0);
    cnt_cycle_ov      :in std_logic;
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
end drv_top;

architecture Behavioral of drv_top is


component ctrl_ad7177 is
generic(device_num:integer:=18);
 Port (
    clkin         :in std_logic;
    rst_n         :in std_logic;
----------------------------
    spi_clk       :out std_logic;
    spi_cs        :out std_logic;
    spi_mosi      :out std_logic;
    spi_miso      :in std_logic_vector(device_num-1 downto 0);
    ad7177_sync   :out std_logic;
    audi_in       :in std_logic;
    adc_check_sus :out std_logic_vector(device_num-1 downto 0); 
    err_num       :out std_logic_vector(device_num-1 downto 0); 
    work_mod        :in std_logic_vector(7 downto 0);
    m0_num          :in std_logic_vector(7 downto 0);
    sample_start    :in std_logic;
    cnt_cycle       :in std_logic_vector(31 downto 0);
    cnt_cycle_ov    :in std_logic;
----------------------------
    ad_data_buf     :out ad_buf_t;
    ad_data_buf_vld :out std_logic;
    adui_data       :out std_logic_vector(24-1 downto 0);
----------------------------
    m_axis_tvalid :out std_logic;
    m_axis_tdata  :out std_logic_vector(2*device_num*32-1 downto 0)
 );
end component;

signal	adc_check_sus   : std_logic_vector(device_num-1 downto 0);	

component ctrl_74hc595 is
generic(
    device_num:integer:=5;      --级联个数
    clk_div   :integer:=4       --时钟分频比
    );
port(
    clkin                   :in std_logic;
    rst_n                   :in std_logic;
----------------------------------------------------    
    s_axis_tvalid           :in std_logic;
    s_axis_tready           :out std_logic;
    s_axis_tdata            :in std_logic_vector(device_num*8-1 downto 0);
-----------------------------------------------------    
    mr_n                    :out std_logic;             ---复位信号
    shcp                    :out std_logic;             ---移位寄存器时钟输入
    stcp                    :out std_logic;             ---锁存器锁存时钟
    oe_n                    :out std_logic;             ---输出使能
    ds                      :out std_logic              ---串行数据输入
);
end component;

signal   s_axis_tvalid           :std_logic;
signal   s_axis_tready           :std_logic;

signal   s_axis_tdata            :std_logic_vector(5*8-1 downto 0);
signal   shift_reg_data            :std_logic_vector(5*8-1 downto 0);

signal s1:integer range 0 to 7;

signal   tx_en_pos           :std_logic;
signal   tx_en               :std_logic;
signal   tx_en_d1            :std_logic;
signal   rst_n_spi            :std_logic;
signal   sample_start            :std_logic;



COMPONENT vio_0
  PORT (
    clk : IN STD_LOGIC;
    probe_out0 : OUT STD_LOGIC;
    probe_out1 : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    probe_out2 : OUT STD_LOGIC
  );
END COMPONENT;




COMPONENT ila_ad

PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC; 
	probe1 : IN STD_LOGIC; 
	probe2 : IN STD_LOGIC; 
	probe3 : IN STD_LOGIC_VECTOR(17 DOWNTO 0); 
	probe4 : IN STD_LOGIC; 
	probe5 : IN STD_LOGIC; 
	probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	probe8 : IN STD_LOGIC_VECTOR(17 DOWNTO 0)
    
);
END COMPONENT  ;


signal    spi_clk_i       : std_logic;
signal    spi_cs_i        : std_logic;
signal    spi_mosi_i      : std_logic;
-- signal    spi_miso      :std_logic_vector(device_num-1 downto 0);
signal    rx_ad_data_vld_i: std_logic;
signal    rx_ad_data_i    : std_logic_vector(2*device_num*32-1 downto 0);

signal    relay           :std_logic_vector(35 downto 0);
signal    shift_reg_data1 :std_logic_vector(5*8-1 downto 0);
signal    adui_data_i :std_logic_vector(24-1 downto 0);
signal    relay_common    :std_logic:='0';

signal    led0             :std_logic:='0';
signal    led1             :std_logic:='0';
signal    led2             :std_logic:='0';

signal    ad_data_buf_i:ad_buf_t;


-- attribute mark_debug:string;

-- attribute mark_debug of mr_n:signal is "true";
-- attribute mark_debug of shcp:signal is "true";
-- attribute mark_debug of stcp:signal is "true";
-- attribute mark_debug of oe_n:signal is "true";
-- attribute mark_debug of ds  :signal is "true";



begin


adc_spi_check(device_num-1 downto 0)<=adc_check_sus;

spi_clk<=spi_clk_i;
spi_cs<=spi_cs_i;
spi_mosi<=spi_mosi_i;


rst_n_spi<=rst_n_ad;


ins_ad_drv:ctrl_ad7177 port map(
    clkin           =>  clkin              ,   
    rst_n           =>  rst_n_spi          ,
    -------------   =>  -------------      ,
    spi_clk         =>  spi_clk_i          ,
    spi_cs          =>  spi_cs_i           ,
    spi_mosi        =>  spi_mosi_i         ,
    spi_miso        =>  spi_miso           ,
    ad7177_sync     =>  ad7177_sync        ,
    audi_in         =>  audi_in            ,
    adc_check_sus   =>  adc_check_sus      ,
    work_mod        =>  work_mod           ,
    m0_num          =>  m0_num             ,
    sample_start    =>  trigger_sample_cmd ,        ---触发命令
    cnt_cycle       =>  cnt_cycle          ,
    cnt_cycle_ov    =>  cnt_cycle_ov       ,
    -------------   =>  -------------      ,
    ad_data_buf     =>  ad_data_buf_i      ,
    ad_data_buf_vld =>  ad_data_buf_vld    ,
    err_num         =>   err_num           ,
    adui_data         =>   adui_data_i     ,
    m_axis_tvalid   =>  rx_ad_data_vld_i   ,
    m_axis_tdata    =>  rx_ad_data_i 
);

g1:for i in 0 to 2*device_num-1  generate
begin
ad_data_buf(i)<=(not ad_data_buf_i(i)(23))&ad_data_buf_i(i)(22 downto 0); --偏移二进制转换

-- ad_data_buf(i)<=ad_data_buf_i(i)(23 downto 0); 



end generate;

adui_data<=(not adui_data_i(23))&adui_data_i(22 downto 0); --偏移二进制转换







ins_drv_shift_reg:ctrl_74hc595 port map(
    clkin               =>  clkin               ,       
    rst_n               =>  rst_n               ,
    -----------------   =>  -----------------   ,
    s_axis_tvalid       =>  s_axis_tvalid       ,
    s_axis_tready       =>  s_axis_tready       ,
    s_axis_tdata        =>  s_axis_tdata        ,
    -----------------   =>  -----------------   ,
    mr_n                =>  mr_n                ,
    shcp                =>  shcp                ,
    stcp                =>  stcp                ,
    oe_n                =>  oe_n                ,
    ds                  =>  ds               
);

----------------------------------------------------------
process(clkin,rst_n)    ---初始化移位寄存器的状态
begin
    if rst_n='0' then
        s_axis_tdata<=(others=>'0');
        ad_channel_sta<=(others=>'0');
        s_axis_tvalid<='0';
        s1<=0;
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    s_axis_tdata<=shift_reg_data1;
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        s1<=1;
                    else
                        s_axis_tvalid<='1';
                    end if;
                
                when 1=>
                    s_axis_tvalid<='0';
                    ad_channel_sta<=relay;
                    if tx_en_pos='1' then
                        s1<=2;
                    end if;
                    
                when 2=>
                    s_axis_tdata<=shift_reg_data1;
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        s1<=1;
                    else
                        s_axis_tvalid<='1';
                    end if;                          

                when others=>
                    s1<=0;
                    s_axis_tvalid<='0';
            end case;
        end if;
    end if;
end process;



----------------------y译码 与595输出对应----------------------------------------------
-- shift_reg_data1(5*8-1 downto 4*8)<=relay(24 downto 20)&led0&led1&led2;
-- shift_reg_data1(4*8-1 downto 3*8)<=relay(32 downto 25);
-- shift_reg_data1(3*8-1 downto 2*8)<=relay(3 downto 0)&relay_common&relay(35 downto 33);
-- shift_reg_data1(2*8-1 downto 1*8)<=relay(11 downto 4);
-- shift_reg_data1(1*8-1 downto 0*8)<=relay(19 downto 12);


shift_reg_data1(5*8-1 downto 4*8)<=relay(24 downto 20)&relay(14 downto 12);
shift_reg_data1(4*8-1 downto 3*8)<=relay(32 downto 25);
shift_reg_data1(3*8-1 downto 2*8)<=relay(3 downto 0)&relay(15)&relay(35 downto 33);
shift_reg_data1(2*8-1 downto 1*8)<=relay(11 downto 4);
shift_reg_data1(1*8-1 downto 0*8)<=relay(19 downto 16)&relay_common&led0&led1&led2;

--relay_common在数据采集以及自检时都为高电平
--relay 在数据采集时为低，在自检时为高
process(clkin,rst_n)
variable cnt:integer:=0;
begin
    if rst_n='0' then
        relay_common<='0';
        relay<=(others=>'0');
        led0<='1';     
        led1<='1';
        led2<='1';
        sample_start<='0';
        cnt:=0;
    elsif rising_edge(clkin) then
        if channel_check_en='1' then
            relay<=channel_check(35 downto 0); 
            led0<='0';      ---自检时点亮3个led
            led1<='0';
            led2<='0';
            relay_common<=commom_sig;
        elsif cfg_data_en='1' then
            relay<=ad_channel_en(35 downto 0);   ---低电平启用采集功能
            led0<='1';      ---采集时熄灭
            led1<='1';
            led2<='1';   
            relay_common<=commom_sig;
        else
            relay<=relay;
            led0<=led0;
            led1<=led1;
            led2<=led2;
        end if;
        tx_en_pos<=channel_check_en or cfg_data_en;
        

    end if;
end process;

















end Behavioral;
