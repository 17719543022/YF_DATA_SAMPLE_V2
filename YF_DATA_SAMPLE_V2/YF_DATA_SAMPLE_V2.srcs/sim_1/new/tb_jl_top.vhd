----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/25 11:04:53
-- Design Name: 
-- Module Name: tb_jl_top - Behavioral
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

entity tb_jl_top is
--  Port ( );
end tb_jl_top;

architecture Behavioral of tb_jl_top is
constant freq:integer:=50*10**6;
constant sps:integer:=2*10**3;
constant cnt_num:integer:=freq/sps;

component jl_top is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------ ˝æ›¥´ ‰SPI---------------------
    spi_clk             :inout std_logic;
    spi_cs              :inout std_logic;
    spi_data            :inout std_logic_vector(3 downto 0);
--------------≈‰÷√SPI--------------------
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
------------------------------------
    link_sta            :out std_logic;
    adc_spi_inf_o       :out std_logic_vector(40-1 downto 0);
    ad_data_buf_out     :out ad_buf_t;
    ad_data_buf_o_vld   :out std_logic
 );
end component;


signal    clkin               :std_logic:='0';
signal    rst_n               :std_logic:='0';
signal    spi_clk             :std_logic;
signal    spi_cs              :std_logic;
signal    spi_data            :std_logic_vector(3 downto 0);
signal    spicfg_clk          :std_logic;
signal    spicfg_cs           :std_logic;
signal    spicfg_data         :std_logic;
signal    m_master_en           :std_logic;
signal    m_work_mod            :std_logic_vector(7 downto 0);
signal    m_self_check_sta      :std_logic;
signal    m_up_freq             :std_logic_vector(31 downto 0);
signal    m_o_master_en         :std_logic;
signal    m_o_work_mod          :std_logic_vector(7 downto 0);
signal    m_o_self_check_sta    :std_logic;
signal    m_o_up_freq           :std_logic_vector(31 downto 0); 
signal    m_cfg_data_vld        :std_logic;
signal    m_ad_data_buf_in      :ad_buf_t;
signal    m_ad_data_buf_in_vld  :std_logic;
signal    m_adc_spi_inf_in      :std_logic_vector(40-1 downto 0);    
signal    m_link_sta            :std_logic;
signal    m_adc_spi_inf_o       :std_logic_vector(40-1 downto 0);
signal    m_ad_data_buf_out     :ad_buf_t;
signal    m_ad_data_buf_o_vld   :std_logic;

signal    s_master_en           :std_logic;
signal    s_work_mod            :std_logic_vector(7 downto 0);
signal    s_self_check_sta      :std_logic;
signal    s_up_freq             :std_logic_vector(31 downto 0);
signal    s_o_master_en         :std_logic;
signal    s_o_work_mod          :std_logic_vector(7 downto 0);
signal    s_o_self_check_sta    :std_logic;
signal    s_o_up_freq           :std_logic_vector(31 downto 0); 
signal    s_cfg_data_vld        :std_logic;
signal    s_ad_data_buf_in      :ad_buf_t;
signal    s_ad_data_buf_in_vld  :std_logic;
signal    s_adc_spi_inf_in      :std_logic_vector(40-1 downto 0);    
signal    s_link_sta            :std_logic;
signal    s_adc_spi_inf_o       :std_logic_vector(40-1 downto 0);
signal    s_ad_data_buf_out     :ad_buf_t;
signal    s_ad_data_buf_o_vld   :std_logic;



begin

clkin<= not clkin after 10ns;
rst_n<= '1'  after 100ns;

m_ad_data_buf_in(0)<=X"123456";
m_ad_data_buf_in(1)<=X"abcdef";

--------------------------------------------------------------

m_master_en<='1';

m_work_mod<=X"55";

m_self_check_sta<='1';

m_up_freq<=X"0000_61a9";


uut_m:jl_top port map(


    clkin               =>  clkin                        ,
    rst_n               =>  rst_n                        ,
    spi_clk             =>  spi_clk                      ,
    spi_cs              =>  spi_cs                       ,
    spi_data            =>  spi_data                     ,
    spicfg_clk          =>  spicfg_clk                   ,
    spicfg_cs           =>  spicfg_cs                    ,
    spicfg_data         =>  spicfg_data                  ,
    master_en           =>  m_master_en                    ,
    work_mod            =>  m_work_mod                     ,
    self_check_sta      =>  m_self_check_sta               ,
    up_freq             =>  m_up_freq                      ,
    o_master_en         =>  m_o_master_en                  ,
    o_work_mod          =>  m_o_work_mod                   ,
    o_self_check_sta    =>  m_o_self_check_sta             ,
    o_up_freq           =>  m_o_up_freq                    ,
    cfg_data_vld        =>  m_cfg_data_vld                 ,
    ad_data_buf_in      =>  m_ad_data_buf_in               ,
    ad_data_buf_in_vld  =>  m_ad_data_buf_in_vld           ,
    adc_spi_inf_in      =>  m_adc_spi_inf_in               ,
    link_sta            =>  m_link_sta                     ,
    adc_spi_inf_o       =>  m_adc_spi_inf_o                ,
    ad_data_buf_out     =>  m_ad_data_buf_out              ,
    ad_data_buf_o_vld   =>  m_ad_data_buf_o_vld  
);
----------------------------------------------------------------------

s_ad_data_buf_in(0)<=X"0123_45";
s_ad_data_buf_in(1)<=X"1123_45";
s_ad_data_buf_in(2)<=X"2123_45";
s_master_en<='0';

uut_s:jl_top port map(

    clkin               =>  clkin                        ,
    rst_n               =>  rst_n                        ,
    spi_clk             =>  spi_clk                      ,
    spi_cs              =>  spi_cs                       ,
    spi_data            =>  spi_data                     ,
    spicfg_clk          =>  spicfg_clk                   ,
    spicfg_cs           =>  spicfg_cs                    ,
    spicfg_data         =>  spicfg_data                  ,
    master_en           =>  s_master_en                    ,
    work_mod            =>  s_work_mod                     ,
    self_check_sta      =>  s_self_check_sta               ,
    up_freq             =>  s_up_freq                      ,
    o_master_en         =>  s_o_master_en                  ,
    o_work_mod          =>  s_o_work_mod                   ,
    o_self_check_sta    =>  s_o_self_check_sta             ,
    o_up_freq           =>  s_o_up_freq                    ,
    cfg_data_vld        =>  s_cfg_data_vld                 ,
    ad_data_buf_in      =>  s_ad_data_buf_in               ,
    ad_data_buf_in_vld  =>  s_ad_data_buf_in_vld           ,
    adc_spi_inf_in      =>  s_adc_spi_inf_in               ,
    link_sta            =>  s_link_sta                     ,
    adc_spi_inf_o       =>  s_adc_spi_inf_o                ,
    ad_data_buf_out     =>  s_ad_data_buf_out              ,
    ad_data_buf_o_vld   =>  s_ad_data_buf_o_vld  
);















process(clkin,rst_n)
variable cnt:integer:=0;
begin
    if rst_n='0' then
        cnt:=0;
        s_ad_data_buf_in_vld<='0';
    else
        if rising_edge(clkin) then
            if cnt>=cnt_num-1 then
                cnt:=0;
            else
                cnt:=cnt+1;
            end if;

            if cnt=10 then
                s_ad_data_buf_in_vld<='1';
            else
                s_ad_data_buf_in_vld<='0';
            end if;
        end if;
    end if;
end process;























end Behavioral;
