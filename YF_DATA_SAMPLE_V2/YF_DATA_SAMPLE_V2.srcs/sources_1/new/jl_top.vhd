----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/25 09:11:39
-- Design Name: 
-- Module Name: jl_top - Behavioral
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

entity jl_top is
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
    adui_data_in        :in std_logic_vector(23 downto 0);
    
    o_master_en         :out std_logic;
    o_work_mod          :out std_logic_vector(7 downto 0);
    o_self_check_sta    :out std_logic;
    o_up_freq           :out std_logic_vector(31 downto 0); 
    adui_data_out       :out std_logic_vector(23 downto 0); 
    cfg_data_vld        :out std_logic;
----------------------------------
    ad_data_buf_in      :in ad_buf_t;
    ad_data_buf_in_vld  :in std_logic;
    adc_spi_inf_in      :in std_logic_vector(40-1 downto 0);   

    rst_n_ad_i          :in std_logic;
    rst_n_ad_o          :out std_logic;
------------------------------------
    link_sta            :out std_logic;
    adc_spi_inf_o       :out std_logic_vector(40-1 downto 0);
    ad_data_buf_out     :out ad_buf_t;
    ad_data_buf_o_vld   :out std_logic
 );
end jl_top;

architecture Behavioral of jl_top is

component SPI_RX_JL_V2 is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
---------------------------------
    spi_clk             :in std_logic;
    spi_cs              :in std_logic;
    spi_data            :in std_logic_vector(3 downto 0);
---------------------------------------------
    link_sta            :out std_logic;
    adc_spi_inf         :out std_logic_vector(40-1 downto 0);
    ad_data_buf_out     :out ad_buf_t;
    adui_data_out       :out std_logic_vector(23 downto 0);
    frame_cnt           :out std_logic_vector(7 downto 0);        
    ad_data_buf_o_vld   :out std_logic
 );
end component;



component SPI_TX_JL_V2 is
  Port ( 
    clkin               :in std_logic;
    rst_n               :in std_logic;
--------------------------------
    spi_clk             :out std_logic;
    spi_cs              :out std_logic;
    spi_data            :out std_logic_vector(3 downto 0);
---------------------------------------------
    ad_data_buf_in      :in ad_buf_t;
    ad_data_buf_in_vld  :in std_logic;
    adui_data_in        :in std_logic_vector(23 downto 0);
---------------------------------------------    
    adc_spi_inf         :in std_logic_vector(40-1 downto 0)
  );
end component;

signal    spi_clk_o             : std_logic;
signal    spi_cs_o              : std_logic;
signal    spi_data_o            : std_logic_vector(3 downto 0);
signal    frame_cnt            : std_logic_vector(7 downto 0);


component spi_txcfg_jl is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
    spi_clk             :out std_logic;
    spi_cs              :out std_logic;
    spi_mosi            :out std_logic;
---------------------------------------------------------
    rst_n_ad_i          :in std_logic;
    master_en           :in std_logic;
    work_mod            :in std_logic_vector(7 downto 0);
    self_check_sta      :in std_logic;
    ad_channel_en       :in std_logic_vector(35 downto 0);
    up_freq             :in std_logic_vector(31 downto 0)
---------------------------------------------------------    
 );
end component;




component spi_rxcfg_jl is
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
    spi_clk             :in std_logic;
    spi_cs              :in std_logic;
    spi_mosi            :in std_logic;
---------------------------------------------------------
    rst_n_ad_o          :out std_logic;
    master_en           :out std_logic;
    work_mod            :out std_logic_vector(7 downto 0);
    self_check_sta      :out std_logic;
    ad_channel_en       :out std_logic_vector(35 downto 0);
    up_freq             :out std_logic_vector(31 downto 0); 
    cfg_data_vld        :out std_logic
---------------------------------------------------------    
 );
end component;




-----------------------------------------------------------------
-- signal spi_clk_o:std_logic;
-- signal spi_cs_o:std_logic;
-- signal spi_data_o:std_logic_vector(3 downto 0);



signal spicfg_clk_o:std_logic;
signal spicfg_cs_o:std_logic;
signal spicfg_data_o:std_logic;


signal rst_n_m:std_logic;
signal rst_n_s:std_logic;


signal    t_spi_clk             : std_logic;
signal    t_spi_cs              : std_logic;
signal    t_spi_data            : std_logic_vector(3 downto 0);
signal    t_spicfg_clk          : std_logic;
signal    t_spicfg_cs           : std_logic;
signal    t_spicfg_data         : std_logic;
signal    link_sta_i            : std_logic;
signal    ad_data_buf_o_vld_i   : std_logic;




COMPONENT ila_jl

PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC; 
	probe1 : IN STD_LOGIC; 
	probe2 : IN STD_LOGIC; 
	probe3 : IN STD_LOGIC; 
	probe4 : IN STD_LOGIC; 
	probe5 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
	probe6 : IN STD_LOGIC;
	probe7 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	probe8 : IN STD_LOGIC
);
END COMPONENT  ;





begin

----------------------------------
t_spicfg_clk    <=spicfg_clk   ;
t_spicfg_cs     <=spicfg_cs    ;
t_spicfg_data   <=spicfg_data  ;
t_spi_clk       <=spi_clk      ;
t_spi_cs        <=spi_cs       ;
t_spi_data      <=spi_data     ;



u_ila : ila_jl
PORT MAP (
	clk => clkin,
	probe0 => t_spicfg_clk , 
	probe1 => t_spicfg_cs  , 
	probe2 => t_spicfg_data, 
	probe3 => t_spi_clk    , 
	probe4 => t_spi_cs     , 
	probe5 => t_spi_data   ,
	probe6 => link_sta_i   ,
	probe7 => frame_cnt    ,
	probe8 => ad_data_buf_o_vld_i   
);


ad_data_buf_o_vld<=ad_data_buf_o_vld_i;

----------------------------------

spi_clk<= spi_clk_o  when master_en='0' else 'Z';           ---从机发数据
spi_cs <= spi_cs_o   when master_en='0' else 'Z';
spi_data<=spi_data_o when master_en='0' else "ZZZZ";


spicfg_clk  <= spicfg_clk_o  when master_en='1' else 'Z';   --主机发数据
spicfg_cs   <= spicfg_cs_o   when master_en='1' else 'Z';
spicfg_data <= spicfg_data_o when master_en='1' else 'Z';

rst_n_m<=master_en and rst_n;
rst_n_s<=not master_en and rst_n;

link_sta<=link_sta_i;

-----------------------数据传输过程--------------------------------

-----------------------只有主机具备-------------------------------------------
ins_spi_rx_jl:SPI_RX_JL_V2 port map(                           ----主机收数据
    clkin               =>  clkin                   ,
    rst_n               =>  rst_n_m                   ,
    ------------------  =>  ------------------      ,
    spi_clk             =>  spi_clk                 ,
    spi_cs              =>  spi_cs                  ,
    spi_data            =>  spi_data                ,
    ------------------  =>  ------------------      ,
    link_sta            =>  link_sta_i              ,
    adc_spi_inf         =>  adc_spi_inf_o           ,
    ad_data_buf_out     =>  ad_data_buf_out         ,
    adui_data_out       =>  adui_data_out           ,
    frame_cnt           =>  frame_cnt               ,
    ad_data_buf_o_vld   =>  ad_data_buf_o_vld_i 
);


ins_spi_txcfg_jl:spi_txcfg_jl port map(                   ---主机发配置信息
    clkin               =>  clkin                   ,             
    rst_n               =>  rst_n_m                 ,
    spi_clk             =>  spicfg_clk_o            ,
    spi_cs              =>  spicfg_cs_o             ,
    spi_mosi            =>  spicfg_data_o           ,
    --------------------=>  --------------------    ,
    rst_n_ad_i          =>  rst_n_ad_i               ,
    master_en           =>  master_en               ,
    work_mod            =>  work_mod                ,
    self_check_sta      =>  self_check_sta          ,
    ad_channel_en       =>  (others=>'1')           ,
    up_freq             =>  up_freq             
);


-----------------------只有从机具备------------------------------------------------------------

ins_spi_tx_jl:SPI_TX_JL_V2 port map(
    clkin                => clkin                   ,        ---从机发数据    
    rst_n                => rst_n_s                 ,
    -------------------  => -------------------     ,
    spi_clk              => spi_clk_o               ,
    spi_cs               => spi_cs_o                ,
    spi_data             => spi_data_o              ,
    -------------------  => -------------------     ,
    ad_data_buf_in       => ad_data_buf_in          ,
    ad_data_buf_in_vld   => ad_data_buf_in_vld      ,
    adui_data_in         => adui_data_in            ,
    -------------------  => -------------------
    adc_spi_inf          => adc_spi_inf_in        
);


ins_spi_rxcfg_jl:spi_rxcfg_jl port map(                     ---从机收配置

    clkin               =>  clkin                   ,     
    rst_n               =>  rst_n_s                 ,
    spi_clk             =>  spicfg_clk              ,
    spi_cs              =>  spicfg_cs               ,
    spi_mosi            =>  spicfg_data             ,
    ------------------  =>  ------------------      ,
    rst_n_ad_o          =>  rst_n_ad_o              ,
    master_en           =>  o_master_en             ,
    work_mod            =>  o_work_mod              ,
    self_check_sta      =>  o_self_check_sta        ,
--    ad_channel_en       =>  o_ad_channel_en           ,
    up_freq             =>  o_up_freq               ,
    cfg_data_vld        =>  cfg_data_vld        

);
--------------------------------------------------------------------



















-------------------------------------------------------



                        

























end Behavioral;
