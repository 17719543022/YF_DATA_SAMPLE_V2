----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/17 12:27:06
-- Design Name: 
-- Module Name: usb_pro_deal - Behavioral
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

entity usb_pro_deal is
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
    ad_channel_sta0   :in std_logic_vector(35 downto 0);
    seq_ver           :in std_logic_vector(47 downto 0);
    err_num           :in std_logic_vector(18-1 downto 0);  
    adui_data         :in std_logic_vector(24-1 downto 0);  

    pwr_state         :in std_logic_vector(7 downto 0);
    pwr_adc_data      :in std_logic_vector(15 downto 0);
    pwr_data_vld      :in std_logic;
-----------------配置命令----------------
    ad_channel_en0    :out std_logic_vector(35 downto 0);
    work_mod          :out std_logic_vector(7 downto 0);
    m0_num            :out std_logic_vector(7 downto 0); --18导联36导联切换专用
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
----------------------------------


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
end usb_pro_deal;

architecture Behavioral of usb_pro_deal is
constant freq:integer :=50*10**6;
constant sps :integer:=2000;
constant ini_sample_rate:integer:=freq/sps;


signal cnt_trigger:integer range 0 to 2047;
signal cnt_rx:integer range 0 to 2047;
signal cnt_tx:integer range 0 to 2047;
signal cnt_cycle:integer;
signal s1    :integer range 0 to 3;
signal s2    :integer range 0 to 7;


signal shift_reg:std_logic_vector(31 downto 0);
signal s_axis_tdata_d1:std_logic_vector(15 downto 0);
signal s_axis_tvalid_d1:std_logic;

signal sync:std_logic;
signal usb_rx_buf_vld:std_logic;
type t1 is array(0 to 63) of std_logic_vector(7 downto 0);
signal usb_rx_buf:t1;
signal usb_door_bell_buf:t1;
type t2 is array(0 to 511) of std_logic_vector(7 downto 0);
signal usb_tx_buf:t2;
type t3 is array(0 to 9) of std_logic_vector(7 downto 0);
signal usb_pwrma_buf:t3;

signal work_mod_i               :std_logic_vector(7 downto 0);
signal m0_num_t                 :std_logic_vector(7 downto 0);
signal usb_rx_buf_type          :std_logic_vector(7 downto 0);
signal sum_data                 :std_logic_vector(7 downto 0);

signal up_data_freq             :std_logic_vector(31 downto 0);
signal frame_data_cnt           :std_logic_vector(31 downto 0);
signal frame_self_cnt           :std_logic_vector(31 downto 0);
signal lock_data_en             :std_logic;
signal master_en                :std_logic;
signal jl_en                    :std_logic;
signal self_check_sta           :std_logic;
signal lock_data_en_pos           :std_logic;
signal lock_data_en_d1           :std_logic;



signal door_bell_cmd            :std_logic;
signal trigger_sample_cmd_auto  :std_logic;
signal rst_n_ad_1            :std_logic;

signal trigger_data:std_logic_vector(23 downto 0);
signal trigger_data1:std_logic_vector(23 downto 0);


signal rst_n_buf:std_logic_vector(7 downto 0);

signal channel_check:std_logic_vector(143 downto 0);        ---自检
signal ad_channel_en:std_logic_vector(143 downto 0);        ---工作
signal act_dl_num:std_logic_vector(7 downto 0):=X"24";
signal ad_channel_sta:std_logic_vector(143 downto 0);
signal ad_channel_sta1:std_logic_vector(35 downto 0);
signal ad_channel_sta2:std_logic_vector(35 downto 0);
signal ad_channel_sta3:std_logic_vector(35 downto 0);


constant fpga_ver:std_logic_vector(47 downto 0):=X"2025_0216_0102";


signal ad_data_buf_r1: ad_buf_t:=(others=>X"010101");
signal ad_data_buf_r2: ad_buf_t:=(others=>X"020202");
signal ad_data_buf_r3: ad_buf_t:=(others=>X"030303");

attribute mark_debug:string;
attribute mark_debug of ad_data_buf_vld  :signal is "true";



signal ad_data_23:std_logic_vector(23 downto 0);

---------------------------------------------
component jl_top is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------数据传输SPI---------------------
    spi_clk             :inout std_logic;
    spi_cs              :inout std_logic;
    spi_data            :inout std_logic_vector(3 downto 0);
--------------配置SPI--------------------
    spicfg_clk          :inout std_logic;
    spicfg_cs           :inout std_logic;
    spicfg_data         :inout std_logic;
----------------------------------
    master_en           :in std_logic;
    work_mod            :in std_logic_vector(7 downto 0);
    self_check_sta      :in std_logic;
    up_freq             :in std_logic_vector(31 downto 0);

    o_master_en         :out std_logic;
    o_work_mod          :out std_logic_vector(7 downto 0);
    o_self_check_sta    :out std_logic;
    o_up_freq           :out std_logic_vector(31 downto 0); 
    cfg_data_vld        :out std_logic;
----------------------------------
    ad_data_buf_in      :in ad_buf_t;
    ad_data_buf_in_vld  :in std_logic;
    adc_spi_inf_in      :in std_logic_vector(40-1 downto 0);    
    
    adui_data_in        :in std_logic_vector(23 downto 0);
    adui_data_out       :out std_logic_vector(23 downto 0);
    
    rst_n_ad_i          :in std_logic;
    rst_n_ad_o          :out std_logic;
------------------------------------
    link_sta            :out std_logic;
    adc_spi_inf_o       :out std_logic_vector(40-1 downto 0);
    ad_data_buf_out     :out ad_buf_t;
    ad_data_buf_o_vld   :out std_logic
 );
end component;


------------------------------------------------------------------
signal    m1_master_en           :std_logic;
signal    m1_work_mod            :std_logic_vector(7 downto 0);
signal    m1_self_check_sta      :std_logic;
signal    m1_up_freq             :std_logic_vector(31 downto 0);
signal    m1_o_master_en         :std_logic;
signal    m1_o_work_mod          :std_logic_vector(7 downto 0);
signal    m1_o_self_check_sta    :std_logic;
signal    m1_o_up_freq           :std_logic_vector(31 downto 0); 
signal    m1_cfg_data_vld        :std_logic;
signal    m1_ad_data_buf_in      :ad_buf_t;
signal    m1_ad_data_buf_in_vld  :std_logic;
signal    m1_adc_spi_inf_in      :std_logic_vector(40-1 downto 0);    
signal    m1_link_sta            :std_logic;
signal    m1_adc_spi_inf_o       :std_logic_vector(40-1 downto 0);
signal    m1_ad_data_buf_out     :ad_buf_t;
signal    m1_ad_data_buf_o_vld   :std_logic;



signal    m2_master_en           :std_logic;
signal    m2_work_mod            :std_logic_vector(7 downto 0);
signal    m2_self_check_sta      :std_logic;
signal    m2_up_freq             :std_logic_vector(31 downto 0);
signal    m2_o_master_en         :std_logic;
signal    m2_o_work_mod          :std_logic_vector(7 downto 0);
signal    m2_o_self_check_sta    :std_logic;
signal    m2_o_up_freq           :std_logic_vector(31 downto 0); 
signal    m2_cfg_data_vld        :std_logic;
signal    m2_ad_data_buf_in      :ad_buf_t;
signal    m2_ad_data_buf_in_vld  :std_logic;
signal    m2_adc_spi_inf_in      :std_logic_vector(40-1 downto 0);    
signal    m2_link_sta            :std_logic;
signal    m2_adc_spi_inf_o       :std_logic_vector(40-1 downto 0);
signal    m2_ad_data_buf_out     :ad_buf_t;
signal    m2_ad_data_buf_o_vld   :std_logic;





signal    m3_master_en           :std_logic;
signal    m3_work_mod            :std_logic_vector(7 downto 0);
signal    m3_self_check_sta      :std_logic;
signal    m3_up_freq             :std_logic_vector(31 downto 0);
signal    m3_o_master_en         :std_logic;
signal    m3_o_work_mod          :std_logic_vector(7 downto 0);
signal    m3_o_self_check_sta    :std_logic;
signal    m3_o_up_freq           :std_logic_vector(31 downto 0); 
signal    m3_cfg_data_vld        :std_logic;
signal    m3_ad_data_buf_in      :ad_buf_t;
signal    m3_ad_data_buf_in_vld  :std_logic;
signal    m3_adc_spi_inf_in      :std_logic_vector(40-1 downto 0);    
signal    m3_link_sta            :std_logic;
signal    m3_adc_spi_inf_o       :std_logic_vector(40-1 downto 0);
signal    m3_ad_data_buf_out     :ad_buf_t;
signal    m3_ad_data_buf_o_vld   :std_logic;




signal    m1_num:std_logic_vector(7 downto 0);
signal    m2_num:std_logic_vector(7 downto 0);
signal    m3_num:std_logic_vector(7 downto 0);
signal    m1_adui_data_out:std_logic_vector(23 downto 0);
signal    m2_adui_data_out:std_logic_vector(23 downto 0);
signal    m3_adui_data_out:std_logic_vector(23 downto 0);

signal    m1_adui_data_in:std_logic_vector(23 downto 0);
signal    m2_adui_data_in:std_logic_vector(23 downto 0);
signal    m3_adui_data_in:std_logic_vector(23 downto 0);

signal    m1_rst_n_ad_i   :std_logic;
signal    m2_rst_n_ad_i   :std_logic;
signal    m3_rst_n_ad_i   :std_logic;

signal    m1_rst_n_ad_o   :std_logic;
signal    m2_rst_n_ad_o   :std_logic;
signal    m3_rst_n_ad_o   :std_logic;
signal    rst_n_ad_i      :std_logic;

signal    pwr_send_data_en:std_logic;
signal    usb_rx_buf_vld_locked:std_logic;

begin
---------------------数据接收-----------------------------------
s_axis_tready<='1';

process(clkin,rst_n)
begin
    if rst_n='0' then
        shift_reg<=(others=>'0');
    elsif rising_edge(clkin) then
        if s_axis_tvalid='1'  then
            shift_reg<=shift_reg(15 downto 0)&s_axis_tdata(7 downto 0)&s_axis_tdata(15 downto 8);
        else
            shift_reg<=shift_reg;
        end if;
        s_axis_tvalid_d1<=s_axis_tvalid;
        s_axis_tdata_d1<=s_axis_tdata;
        
    end if;
end process;

sync<='1' when shift_reg=X"55AACBCD" else '0';

process(clkin,rst_n)
begin
    if rst_n='0' then
         s1<=0;
         usb_rx_buf_vld<='0';
         cnt_rx<=0;
    elsif rising_edge(clkin) then
        case s1 is
            when 0=>
                if sync='1' then
                    s1<=1;
                else
                    s1<=s1;
                end if;
                cnt_rx<=4;
                usb_rx_buf_vld<='0';
            
            when 1=>
                if s_axis_tvalid_d1='1' then
                    usb_rx_buf(cnt_rx)<=s_axis_tdata_d1(7 downto 0);
                    usb_rx_buf(cnt_rx+1)<=s_axis_tdata_d1(15 downto 8);
                    cnt_rx<=cnt_rx+2;
                else
                    cnt_rx<=cnt_rx;
                end if;
                
                if s_axis_tvalid_d1='1' and cnt_rx>=38 then
                    s1<=2;
                end if;
                
            
            when 2=>    
                if usb_rx_buf(39)=X"a3" then
                    usb_rx_buf_vld<='1';
                    usb_rx_buf_type<=usb_rx_buf(4);
                else
                    usb_rx_buf_vld<='0';
                end if;
                s1<=0;
            
            when others=>
                s1<=0;
        end case;
    end if;
end process;


process(clkin,rst_n)
begin
    if rst_n='0' then
        usb_rx_buf_vld_locked<='0';
    else
        if rising_edge(clkin) then
            if usb_rx_buf_vld='1' and (usb_rx_buf_type=X"11" or usb_rx_buf_type=X"10" or usb_rx_buf_type=X"15")  then
                usb_rx_buf_vld_locked<='1';
            end if;
        end if;
    end if;
end process;





---------------------数据接收--------------------------------------------------------------------------------
---------------------协议处理--------------------------------------------------------------------------------
ad_channel_en0<=ad_channel_en(35 downto 0);
work_mod      <=work_mod_i;
m0_num        <=m0_num_t;
rst_n_usb     <=rst_n;

rst_n_ad<=rst_n_ad_i;

process(clkin,rst_n)
begin
    if rst_n='0' then
        work_mod_i<=X"51";            ----问询上传
        up_data_freq<=conv_std_logic_vector(ini_sample_rate,32); 
        ad_channel_en<=(others=>'0');
        m0_num_t<=X"24";
        master_en<='0';                     ---从机
        jl_en    <='0';
        rst_n_ad_i <='0';
        rst_n_ad_1 <='0';
        
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"10" then        ---配置命令
            -- work_mod_i<=usb_rx_buf(5);
            for i in 0 to 3 loop 
                up_data_freq(i*8+7 downto i*8)<=usb_rx_buf(i+6);
            end loop;
            -- for i in 0 to 17 loop 
                -- ad_channel_en(i*8+7 downto i*8)<=usb_rx_buf(i+10);
            -- end loop;
            
            if usb_rx_buf(10)=X"00" then
                ad_channel_en<=(others=>'1');       ---阻抗模式
               
            elsif usb_rx_buf(10)=X"01" then
                ad_channel_en<=(others=>'0');       ---采集模式
                
            else
                ad_channel_en<=ad_channel_en;
            end if;
            
            if usb_rx_buf(11)=X"24" then
                m0_num_t(7 downto 0)<=usb_rx_buf(11);
            
            elsif usb_rx_buf(11)=X"12" then
                m0_num_t(7 downto 0)<=usb_rx_buf(11);
            
            else
                m0_num_t(7 downto 0)<=m0_num_t(7 downto 0);
            end if;
            
            master_en<=not usb_rx_buf(28)(1);
            jl_en    <=usb_rx_buf(28)(0);
           -- rst_n_usb<=usb_rx_buf(29)(0);
            -- rst_n_ad <=usb_rx_buf(29)(1);
            
            -- commom_sig<=usb_rx_buf(38)(0);
            
            cfg_data_en<='1';
        elsif m1_cfg_data_vld='1' then
            up_data_freq<=m1_o_up_freq;
            ad_channel_en<=(others=>m1_self_check_sta);
        else
            cfg_data_en<='0';
        end if;
        
        rst_n_ad_1<='1';
        
        
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"10" then
            rst_n_ad_i <=usb_rx_buf(29)(1);
        elsif rst_n_ad_1='0' then
            rst_n_ad_i<='1';
        elsif m1_cfg_data_vld='1'  then
            rst_n_ad_i <=m1_rst_n_ad_o;
        end if;
            
 --------------------新增加开始采集与停止采集命令------------------------------
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"15" then
            work_mod_i<=usb_rx_buf(5);
        elsif usb_rx_buf_vld='1' and usb_rx_buf_type=X"10" then
            work_mod_i<=usb_rx_buf(5);
        elsif m1_cfg_data_vld='1' then
            work_mod_i<=m1_o_work_mod;
        else 
            work_mod_i<=work_mod_i;
        end if;
        
        
        
        
        
        
        
        
    end if;
end process;




process(clkin,rst_n)
begin
    if rst_n='0' then
        commom_sig<='0'; 
        self_check_sta<='0';
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"10" then        ---配置命令 
            if usb_rx_buf(10)=X"00" then
                commom_sig<='1';      ---阻抗模式
                self_check_sta<='1';
            elsif usb_rx_buf(10)=X"01" then
                commom_sig<='0';       ---采集模式
                self_check_sta<='0';
            end if;
        elsif usb_rx_buf_vld='1' and usb_rx_buf_type=X"11" then
            if usb_rx_buf(5)=X"00" then
                 commom_sig<='1';      ---阻抗模式
                 self_check_sta<='1';
            elsif usb_rx_buf(5)=X"01" then
                commom_sig<='0';       ---采集模式
                self_check_sta<='0';
            end if;
        elsif m1_cfg_data_vld='1' then
            self_check_sta<=m1_o_self_check_sta;
            commom_sig    <=m1_o_self_check_sta;
        end if;
    end if;
end process;








-----------------------------------------------------------------------------------
channel_check0<=channel_check(35 downto 0);
process(clkin,rst_n)
begin
    if rst_n='0' then
        channel_check<=(others=>'0');
        channel_check_en<='0';
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"11" then        ---自检命令
            -- for i in 0 to 17 loop 
                -- channel_check(i*8+7 downto i*8)<=usb_rx_buf(i+5);
            -- end loop;
            
            if usb_rx_buf(5)=X"00" then
                channel_check<=(others=>'1');       ---阻抗模式
            elsif usb_rx_buf(5)=X"01" then
                channel_check<=(others=>'0');       ---采集模式
            else
                channel_check<=channel_check;
            end if;
            channel_check_en<='1';
        elsif m1_cfg_data_vld='1' then
            if m1_o_self_check_sta='1' then
                channel_check<=(others=>'1'); 
            else
                channel_check<=(others=>'0'); 
            end if;
            channel_check_en<='1';
        else
        
            channel_check_en<='0';
        end if;
    end if;
end process;


-- process(clkin,rst_n)    --设定自检状态
-- begin
    -- if rst_n='0' then
        -- self_check_sta<='0';
    -- else
        -- if rising_edge(clkin) then
            -- if usb_rx_buf_vld='1' and usb_rx_buf_type=X"11" then        ---自检命令
                -- self_check_sta<='1';
            -- elsif usb_rx_buf_vld='1' and usb_rx_buf_type=X"10" then     ---配置命令
                -- self_check_sta<='0';
            -- else
                -- self_check_sta<=self_check_sta;
            -- end if;
        -- end if;
    -- end if;
-- end process;
            
-----------------------查询命令------------------------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        door_bell_cmd<='0';
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"12" then
            door_bell_cmd<='1';
        elsif s2=3 then             ----已经进行回复
            door_bell_cmd<='0';
        else
            door_bell_cmd<=door_bell_cmd;
        end if;
    end if;
end process;
-----------------------触发采集命令------------------------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
       trigger_sample_cmd<='0';
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"13" then
            trigger_sample_cmd<='1';
        elsif work_mod_i=X"50" then
            if cnt_cycle=10 then
                trigger_sample_cmd<='1';    ---发送采集命令    --
            else
                trigger_sample_cmd<='0';
            end if;
        else
            trigger_sample_cmd<='0';
        end if;
    end if;
end process;



process(clkin,rst_n)
begin
    if rst_n='0' then
       trigger_sample_cmd_auto<='0';
       trigger_data<=(others=>'0');
       trigger_data1<=(others=>'0');
       cnt_trigger<=11;
    elsif rising_edge(clkin) then
        if usb_rx_buf_vld='1' and usb_rx_buf_type=X"14" then
            trigger_sample_cmd_auto<='1';
            trigger_data<=usb_rx_buf(7)&usb_rx_buf(6)&usb_rx_buf(5);
        else
            trigger_sample_cmd_auto<='0';
        end if;
        
        if trigger_sample_cmd_auto='1' then
            cnt_trigger<=0;
        elsif self_check_sta='0' and lock_data_en_pos='1' then
            if cnt_trigger>=11 then
                cnt_trigger<=cnt_trigger;
            else
                cnt_trigger<=cnt_trigger+1;
            end if;
        else
            cnt_trigger<=cnt_trigger;
        end if;
        
        if cnt_trigger<=9 then             --触发导联数据
            trigger_data1<=trigger_data;
        else
            trigger_data1<=(others=>'0');
        end if;

    end if;
end process;
-----------------------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt_cycle<=1;
        lock_data_en<='0';
    elsif rising_edge(clkin) then            
        if work_mod_i=X"50" then          --自动上传
            if cnt_cycle>=up_data_freq-1 then
                cnt_cycle<=0;
            else
                cnt_cycle<=cnt_cycle+1;
            end if;
            
            if cnt_cycle=up_data_freq-1 then
                lock_data_en<='1';
            elsif s2=1 then
                lock_data_en<='0';
            else
                lock_data_en<=lock_data_en;
            end if;

        else                    ----手动上传
            cnt_cycle<=1;
            if ad_data_buf_vld='1' then
                lock_data_en<='1';
            elsif s2=1 then
                lock_data_en<='0';
            else
                lock_data_en<=lock_data_en;
            end if;
        end if;
    end if;
end process;

process(clkin)
begin
    if rising_edge(clkin) then
        lock_data_en_d1<=lock_data_en;
    end if;
end process;
lock_data_en_pos<=lock_data_en and not lock_data_en_d1;


-----------------数据上传回复/自检回复------------------------------------------------------------------
process(clkin,rst_n)
begin
    if rising_edge(clkin) then
        usb_tx_buf(0)<=X"AA";
        usb_tx_buf(1)<=X"55";
        usb_tx_buf(2)<=X"CD";
        usb_tx_buf(3)<=X"CB";
        if lock_data_en_pos='1' then
            if self_check_sta='0' then
                usb_tx_buf(4)<=X"10";       ---数据上传协议
                usb_tx_buf(5)<=frame_data_cnt(1*8-1 downto 0*8);
                usb_tx_buf(6)<=frame_data_cnt(2*8-1 downto 1*8);
                usb_tx_buf(7)<=frame_data_cnt(3*8-1 downto 2*8);
                usb_tx_buf(8)<=frame_data_cnt(4*8-1 downto 3*8); 
            else           
                usb_tx_buf(4)<=X"11";       ---自检协议
                usb_tx_buf(5)<=frame_self_cnt(1*8-1 downto 0*8);
                usb_tx_buf(6)<=frame_self_cnt(2*8-1 downto 1*8);
                usb_tx_buf(7)<=frame_self_cnt(3*8-1 downto 2*8);
                usb_tx_buf(8)<=frame_self_cnt(4*8-1 downto 3*8); 
            end if;
            
        
            for i in 0 to 35 loop           --1~36 
                usb_tx_buf(i*3+9)<=ad_data_buf(i)(1*8-1 downto 0*8);       ---本板
                usb_tx_buf(i*3+10)<=ad_data_buf(i)(2*8-1 downto 1*8);
                usb_tx_buf(i*3+11)<=ad_data_buf(i)(3*8-1 downto 2*8);
            end loop;
            
            for i in 0 to 35 loop           --37~72 
                usb_tx_buf(i*3+117)<=ad_data_buf_r1(i)(1*8-1 downto 0*8);    --级联口1
                usb_tx_buf(i*3+118)<=ad_data_buf_r1(i)(2*8-1 downto 1*8);
                usb_tx_buf(i*3+119)<=ad_data_buf_r1(i)(3*8-1 downto 2*8);
            end loop;            
            
            for i in 0 to 35 loop           --73~108 
                usb_tx_buf(i*3+225)<=ad_data_buf_r2(i)(1*8-1 downto 0*8);   --级联口2
                usb_tx_buf(i*3+226)<=ad_data_buf_r2(i)(2*8-1 downto 1*8);
                usb_tx_buf(i*3+227)<=ad_data_buf_r2(i)(3*8-1 downto 2*8);
            end loop;               
            
            for i in 0 to 35 loop           --109~144 
                usb_tx_buf(i*3+333)<=ad_data_buf_r3(i)(1*8-1 downto 0*8);   --级联口3
                usb_tx_buf(i*3+334)<=ad_data_buf_r3(i)(2*8-1 downto 1*8);
                usb_tx_buf(i*3+335)<=ad_data_buf_r3(i)(3*8-1 downto 2*8);
            end loop;              
            
            for i in 0 to 2 loop           --145
                usb_tx_buf(i+441)<=trigger_data1(8*i+7 downto 8*i);          --触发数据(接收到触发数据后连续发送10次，然后置0)
            end loop; 
            
            for i in 0 to 2 loop           --145
                usb_tx_buf(i+444)<=adui_data(8*i+7 downto 8*i);          --音频数据
            end loop; 
            
            for i in 0 to 2 loop           --145
                usb_tx_buf(i+447)<=m1_adui_data_out(8*i+7 downto 8*i);          --音频数据
            end loop; 

            for i in 0 to 2 loop           --145
                usb_tx_buf(i+450)<=m2_adui_data_out(8*i+7 downto 8*i);          --音频数据
            end loop;   

            for i in 0 to 2 loop           --145
                usb_tx_buf(i+453)<=m3_adui_data_out(8*i+7 downto 8*i);          --音频数据
            end loop;                  
            
             usb_tx_buf(495)<=err_num(7 downto 0);               --adc状态上传（新增，不影响数据传输）
             usb_tx_buf(496)<=err_num(15 downto 8);
             usb_tx_buf(497)<="000000"&err_num(17 downto 16);
        end if;        
        
        usb_tx_buf(499)<=X"5C";
    end if;
end process;

-----------------查询消息准备------------------------------------------------
ad_channel_sta<=ad_channel_sta3&ad_channel_sta2&ad_channel_sta1&ad_channel_sta0;
process(clkin)
begin
    if rising_edge(clkin) then
        usb_door_bell_buf(0)<=X"AA";
        usb_door_bell_buf(1)<=X"55";
        usb_door_bell_buf(2)<=X"CD";
        usb_door_bell_buf(3)<=X"CB";
        usb_door_bell_buf(4)<=X"12";
        usb_door_bell_buf(5)<=work_mod_i;
        --------------------------
        usb_door_bell_buf(6)<=up_data_freq(1*8-1 downto 0*8);
        usb_door_bell_buf(7)<=up_data_freq(2*8-1 downto 1*8);
        usb_door_bell_buf(8)<=up_data_freq(3*8-1 downto 2*8);
        usb_door_bell_buf(9)<=up_data_freq(4*8-1 downto 3*8);
        -- for i in 0 to 17 loop
            -- usb_door_bell_buf(i+10)<=ad_channel_sta(i*8+7 downto i*8);          ----指的移位寄存器的状态（主机以及3个从机）
        -- end loop;
        if   ad_channel_sta0(0)='1' then
            usb_door_bell_buf(10)<=X"00";
        else
            usb_door_bell_buf(10)<=X"01";
        end if;

        for i in 0 to 5 loop
            usb_door_bell_buf(11+i)<=fpga_ver(7+8*i downto 0+8*i);
        end loop;
        
        for i in 0 to 5 loop
            usb_door_bell_buf(22-i)<=seq_ver(7+8*i downto 0+8*i);
        end loop;
        
        usb_door_bell_buf(23)<=act_dl_num;
        usb_door_bell_buf(24)<=B"0000_00"&(not master_en)&jl_en;
        
        usb_door_bell_buf(39)<=X"5c";     ---帧尾

    end if;
end process;
   
-------------发送过程-------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        m_axis_tvalid<='0';
        s2<=0;
        frame_data_cnt<=(others=>'0');
        frame_self_cnt<=(others=>'0');
        cnt_tx<=0;
    else
        if rising_edge(clkin) then

            case s2 is
                when 0=>
                    if door_bell_cmd='1' then           ---响应回复命令
                        s2<=3;
                    elsif self_check_sta='1' and master_en='1' then          ---发送自检数据
                        if lock_data_en='1' then
                            frame_self_cnt<=frame_self_cnt+1;
                            s2<=1;
                        else
                            frame_self_cnt<=frame_self_cnt;
                        end if;
                    elsif lock_data_en='1' and master_en='1' then            ---发送正常数据
                        s2<=1;
                        frame_data_cnt<=frame_data_cnt+1;
                    elsif pwr_send_data_en='1' and usb_rx_buf_vld_locked='1'  then
                        s2<=5;
                    else
                        s2<=s2;
                    end if;
                    m_axis_tvalid<='0';
                    m_axis_tlast<='0';
                    cnt_tx<=0;
                    sum_data<=(others=>'0');
--------------------------自检回复/正常数据回复-------------------------------------------                    
                when 1=>
                    m_axis_tdata(7 downto 0)<=usb_tx_buf(cnt_tx);
                    m_axis_tdata(15 downto 8)<=usb_tx_buf(cnt_tx+1);
                    sum_data<=sum_data+usb_tx_buf(cnt_tx)+usb_tx_buf(cnt_tx+1);
                    m_axis_tvalid<='1';
                    if cnt_tx>=496 then    
                        s2<=2;
                        cnt_tx<=0;
                    else
                        cnt_tx<=cnt_tx+2;
                    end if;
                    
                
                when 2=>
                    m_axis_tdata(7 downto 0)<=sum_data;
                    m_axis_tdata(15 downto 8)<=usb_tx_buf(499);                    
                    m_axis_tvalid<='1';
                    m_axis_tlast<='1';
                    s2<=0;
---------------------------------查询命令回复------------------------------------------------------------------------                    
                 when 3=>
                    m_axis_tdata(7 downto 0)<=usb_door_bell_buf(cnt_tx);
                    m_axis_tdata(15 downto 8)<=usb_door_bell_buf(cnt_tx+1);
                    sum_data<=sum_data+usb_door_bell_buf(cnt_tx)+usb_door_bell_buf(cnt_tx+1);
                    m_axis_tvalid<='1';
                    if cnt_tx>=36 then    
                        s2<=4;
                        cnt_tx<=0;
                    else
                        cnt_tx<=cnt_tx+2;
                    end if;
                    
                when 4=>                ---发送校验位与帧尾
                    m_axis_tdata(7 downto 0)<=sum_data;
                    m_axis_tdata(15 downto 8)<=usb_door_bell_buf(39);                    
                    m_axis_tvalid<='1';
                    m_axis_tlast<='1';
                    s2<=0;    
--------------------------------电源管理状态上传-------------------------------------------------------------------
--                 when 5=>
--                    m_axis_tdata(7 downto 0)<=usb_pwrma_buf(cnt_tx);
--                    m_axis_tdata(15 downto 8)<=usb_pwrma_buf(cnt_tx+1);
--                    sum_data<=sum_data+usb_pwrma_buf(cnt_tx)+usb_pwrma_buf(cnt_tx+1);
--                    m_axis_tvalid<='1';
--                    if cnt_tx>=6 then    
--                        s2<=6;
--                        cnt_tx<=0;
--                    else
--                        cnt_tx<=cnt_tx+2;
--                    end if;
--                    
--                when 6=>                ---发送校验位与帧尾
--                    m_axis_tdata(7 downto 0)<=sum_data;
--                    m_axis_tdata(15 downto 8)<=usb_pwrma_buf(9);                    
--                    m_axis_tvalid<='1';
--                    m_axis_tlast<='1';
--                    s2<=0;       
                    
                
                when others=>
                    s2<=0;
            end case;
        end if;
    end if;
end process;
----------------------电源管理数据组帧处理-------------------------------------------------------------------------------------
usb_pwrma_buf(0)<=X"AA";
usb_pwrma_buf(1)<=X"55";
usb_pwrma_buf(2)<=X"CD";
usb_pwrma_buf(3)<=X"CB";
usb_pwrma_buf(4)<=X"20";
usb_pwrma_buf(5)<=pwr_state;
usb_pwrma_buf(6)<=pwr_adc_data(7 downto 0);
usb_pwrma_buf(7)<=pwr_adc_data(15 downto 8);
usb_pwrma_buf(8)<=(others=>'0');
usb_pwrma_buf(9)<=X"5C";

process(clkin,rst_n)
begin
    if rst_n='0' then
        pwr_send_data_en<='0';
    else
        if rising_edge(clkin) then
            if pwr_data_vld='1' then
                pwr_send_data_en<='1';
            elsif s2=5 then
                pwr_send_data_en<='0';
            else
                pwr_send_data_en<=pwr_send_data_en;
            end if;
        end if;
    end if;
end process;
                

-----------------------------------------------------------------------------------------------------------

process(clkin,rst_n)
begin
    if rst_n='0' then
        ad_data_23<=(others=>'0');
    else
        if rising_edge(clkin) then
            if ad_data_buf_vld='1' then
                -- if ad_data_buf(23)>=X"80_0000" then
                   -- ad_data_23<= ad_data_buf(23)-X"80_0000";
                -- else
                   -- ad_data_23<= not ad_data_buf(23)+1;
                -- end if;
                ad_data_23<=(not ad_data_buf(23)(23))&ad_data_buf(23)(22 downto 0);
                
            else
                ad_data_23<=ad_data_23;
            end if;
        end if;
    end if;
end process;



-------------------------------------------------------------------------------------

----配置级联模块的主机/从机状态-----
m1_master_en<=master_en;
m2_master_en<=master_en;
m3_master_en<=master_en;

----作为主机时，配置从机状态态-----
m1_self_check_sta<=self_check_sta;
m2_self_check_sta<=self_check_sta;
m3_self_check_sta<=self_check_sta;

m1_work_mod<=work_mod_i;
m2_work_mod<=work_mod_i;
m3_work_mod<=work_mod_i;
m1_up_freq<=up_data_freq;
m2_up_freq<=up_data_freq;
m3_up_freq<=up_data_freq;

m1_rst_n_ad_i<=rst_n_ad_i;
m2_rst_n_ad_i<=rst_n_ad_i;
m3_rst_n_ad_i<=rst_n_ad_i;
--------作为主机时 接收从机上传的AD采集信息------------
ad_data_buf_r1<=m1_ad_data_buf_out;
ad_data_buf_r2<=m2_ad_data_buf_out;
ad_data_buf_r3<=m3_ad_data_buf_out;



--------------------------------
----作为从机时 给主机上传信息----------------

m1_ad_data_buf_in<=ad_data_buf;
m1_ad_data_buf_in_vld<=ad_data_buf_vld;
m2_ad_data_buf_in<=ad_data_buf;
m2_ad_data_buf_in_vld<=ad_data_buf_vld;
m3_ad_data_buf_in<=ad_data_buf;
m3_ad_data_buf_in_vld<=ad_data_buf_vld;

m1_adui_data_in<=adui_data;
m2_adui_data_in<=adui_data;
m3_adui_data_in<=adui_data;







JL_1:jl_top port map(

    clkin               =>  clkin                          ,
    rst_n               =>  rst_n                          ,
    spi_clk             =>  spi1_clk                       ,
    spi_cs              =>  spi1_cs                        ,
    spi_data            =>  spi1_data                      ,
    spicfg_clk          =>  spi1cfg_clk                    ,
    spicfg_cs           =>  spi1cfg_cs                     ,
    spicfg_data         =>  spi1cfg_data                   ,
    master_en           =>  m1_master_en                    ,
    work_mod            =>  m1_work_mod                     ,
    self_check_sta      =>  m1_self_check_sta               ,
    up_freq             =>  m1_up_freq                      ,
    o_master_en         =>  m1_o_master_en                  ,
    o_work_mod          =>  m1_o_work_mod                   ,
    o_self_check_sta    =>  m1_o_self_check_sta             ,
    o_up_freq           =>  m1_o_up_freq                    ,
    cfg_data_vld        =>  m1_cfg_data_vld                 ,
    ad_data_buf_in      =>  m1_ad_data_buf_in               ,
    ad_data_buf_in_vld  =>  m1_ad_data_buf_in_vld           ,
    adc_spi_inf_in      =>  m1_adc_spi_inf_in               ,
    link_sta            =>  m1_link_sta                     ,
    adc_spi_inf_o       =>  m1_adc_spi_inf_o                ,
    ad_data_buf_out     =>  m1_ad_data_buf_out              ,
    ad_data_buf_o_vld   =>  m1_ad_data_buf_o_vld            ,
    rst_n_ad_i          =>  m1_rst_n_ad_i                   ,
    rst_n_ad_o          =>  m1_rst_n_ad_o                   ,
    adui_data_in        =>  m1_adui_data_in                 ,
    adui_data_out       =>  m1_adui_data_out                    
);

JL_2:jl_top port map(


    clkin               =>  clkin                          ,
    rst_n               =>  rst_n                          ,
    spi_clk             =>  spi2_clk                       ,
    spi_cs              =>  spi2_cs                        ,
    spi_data            =>  spi2_data                      ,
    spicfg_clk          =>  spi2cfg_clk                    ,
    spicfg_cs           =>  spi2cfg_cs                     ,
    spicfg_data         =>  spi2cfg_data                   ,
    master_en           =>  m2_master_en                    ,
    work_mod            =>  m2_work_mod                     ,
    self_check_sta      =>  m2_self_check_sta               ,
    up_freq             =>  m2_up_freq                      ,
    o_master_en         =>  m2_o_master_en                  ,
    o_work_mod          =>  m2_o_work_mod                   ,
    o_self_check_sta    =>  m2_o_self_check_sta             ,
    o_up_freq           =>  m2_o_up_freq                    ,
    cfg_data_vld        =>  m2_cfg_data_vld                 ,
    ad_data_buf_in      =>  m2_ad_data_buf_in               ,
    ad_data_buf_in_vld  =>  m2_ad_data_buf_in_vld           ,
    adc_spi_inf_in      =>  m2_adc_spi_inf_in               ,
    link_sta            =>  m2_link_sta                     ,
    adc_spi_inf_o       =>  m2_adc_spi_inf_o                ,
    ad_data_buf_out     =>  m2_ad_data_buf_out              ,
    ad_data_buf_o_vld   =>  m2_ad_data_buf_o_vld            ,
    rst_n_ad_i          =>  m2_rst_n_ad_i                   ,
    rst_n_ad_o          =>  m2_rst_n_ad_o                   ,
    adui_data_in        =>  m2_adui_data_in                 ,
    adui_data_out       =>  m2_adui_data_out                    
);


JL_3:jl_top port map(


    clkin               =>  clkin                          ,
    rst_n               =>  rst_n                          ,
    spi_clk             =>  spi3_clk                       ,
    spi_cs              =>  spi3_cs                        ,
    spi_data            =>  spi3_data                      ,
    spicfg_clk          =>  spi3cfg_clk                    ,
    spicfg_cs           =>  spi3cfg_cs                     ,
    spicfg_data         =>  spi3cfg_data                   ,
    master_en           =>  m3_master_en                    ,
    work_mod            =>  m3_work_mod                     ,
    self_check_sta      =>  m3_self_check_sta               ,
    up_freq             =>  m3_up_freq                      ,
    o_master_en         =>  m3_o_master_en                  ,
    o_work_mod          =>  m3_o_work_mod                   ,
    o_self_check_sta    =>  m3_o_self_check_sta             ,
    o_up_freq           =>  m3_o_up_freq                    ,
    cfg_data_vld        =>  m3_cfg_data_vld                 ,
    ad_data_buf_in      =>  m3_ad_data_buf_in               ,
    ad_data_buf_in_vld  =>  m3_ad_data_buf_in_vld           ,
    adc_spi_inf_in      =>  m3_adc_spi_inf_in               ,
    link_sta            =>  m3_link_sta                     ,
    adc_spi_inf_o       =>  m3_adc_spi_inf_o                ,
    ad_data_buf_out     =>  m3_ad_data_buf_out              ,
    ad_data_buf_o_vld   =>  m3_ad_data_buf_o_vld            ,
    rst_n_ad_i          =>  m3_rst_n_ad_i                   ,
    rst_n_ad_o          =>  m3_rst_n_ad_o                   ,
    adui_data_in        =>  m3_adui_data_in                 ,
    adui_data_out       =>  m3_adui_data_out                    
);



-- act_devic_num<=('0'&m1_link_sta)+('0'&m2_link_sta)+('0'&m3_link_sta);

process(clkin)
begin
    if rising_edge(clkin) then
        if m1_link_sta='1' then
            m1_num<=X"24";
        else
            m1_num<=X"00";
        end if;
        
        if m2_link_sta='1' then
            m2_num<=X"24";
        else
            m2_num<=X"00";
        end if;        
        
         if m3_link_sta='1' then
            m3_num<=X"24";
        else
            m3_num<=X"00";
        end if;        
               
        act_dl_num<=m0_num_t+m1_num+m2_num+m3_num;
        
    end if;
end process;







                    
                  








end Behavioral;
