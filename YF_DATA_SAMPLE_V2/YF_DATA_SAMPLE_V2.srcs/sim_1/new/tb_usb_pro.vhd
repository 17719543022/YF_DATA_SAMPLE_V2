----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/23 15:10:11
-- Design Name: 
-- Module Name: tb_usb_pro - Behavioral
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

entity tb_usb_pro is
--  Port ( );
end tb_usb_pro;

architecture Behavioral of tb_usb_pro is

type t1 is array(0 to 19) of std_logic_vector(15 downto 0);
signal usb_door_bell:t1:=(
X"AA55",
X"CDCB",
X"0012",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"A300"
);


signal cfg_data_buf:t1:=(
X"AA55",
X"CDCB",
-- X"5110",            ---手动模式
X"5010",            ---自动模式
X"61A8",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"A300"
);


signal self_check_buf:t1:=(
X"AA55",
X"CDCB",
X"5011",
X"61A8",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"A300"
);




signal trigger_buf:t1:=(
X"AA55",
X"CDCB",
X"5014",
X"61A8",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"0000",
X"A300"
);




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
    ad_channel_sta0   :in std_logic_vector(35 downto 0);
    seq_ver           :in std_logic_vector(47 downto 0);
-----------------配置命令----------------
    up_data_freq_o    :out std_logic_vector(31 downto 0);
    ad_channel_en0    :out std_logic_vector(35 downto 0);
    work_mod          :out std_logic_vector(7 downto 0);
    commom_sig        :out std_logic;
    cfg_data_en       :out std_logic;    
    trigger_sample_cmd:out std_logic;    
---------------自检命令---------------------------    
    channel_check_en  :out std_logic;
    channel_check0    :out std_logic_vector(35 downto 0);
---------------------------------
    rst_n_usb         :out std_logic;    
    rst_n_ad          :out std_logic
 );
end component;

SIGNAL    clkin               :std_logic:='0';
SIGNAL    rst_n               :std_logic:='0';


signal    s_axis_tvalid     :std_logic;
signal    s_axis_tready     : std_logic;
signal    s_axis_tdata      :std_logic_vector(15 downto 0);
signal    m_axis_tvalid     : std_logic;
signal    m_axis_tready     :std_logic;
signal    m_axis_tdata      : std_logic_vector(15 downto 0);
signal    m_axis_tlast      : std_logic;
signal    ad_data_buf       :ad_buf_t:=(others=>X"000000");
signal    ad_data_buf_vld   :std_logic;
signal    ad_channel_sta0   :std_logic_vector(35 downto 0);
signal    up_data_freq_o    : std_logic_vector(31 downto 0);
signal    ad_channel_en0    : std_logic_vector(35 downto 0);
signal    work_mod          : std_logic_vector(7 downto 0);
signal    commom_sig        : std_logic;
signal    cfg_data_en       : std_logic;    
signal    trigger_sample_cmd: std_logic;    
signal    channel_check_en  : std_logic;
signal    channel_check0    : std_logic_vector(35 downto 0);
signal    seq_ver           : std_logic_vector(47 downto 0):=X"20241016_0102";
signal    rst_n_usb         : std_logic;    
signal    rst_n_ad          : std_logic;

















signal tx_en:std_logic:='0';
signal cnt_tx:integer:=0;
signal s1:integer range 0 to 15:=0;

begin


clkin<= not clkin after 10ns;
rst_n<='1' after 100ns;

ins_usb_pro_deal:usb_pro_deal port map(


    clkin                   =>  clkin                    ,
    rst_n                   =>  rst_n                    ,
    -------------------     =>  -------------------      ,
    s_axis_tvalid           =>  s_axis_tvalid            ,
    s_axis_tready           =>  s_axis_tready            ,
    s_axis_tdata            =>  s_axis_tdata             ,
    -------------------     =>  -------------------      ,
    m_axis_tvalid           =>  m_axis_tvalid            ,
    m_axis_tready           =>  m_axis_tready            ,
    m_axis_tdata            =>  m_axis_tdata             ,
    m_axis_tlast            =>  m_axis_tlast             ,
    -------------------     =>  -------------------      ,
    ad_data_buf            =>   ad_data_buf              ,
    ad_data_buf_vld        =>   ad_data_buf_vld          ,
    ad_channel_sta0        =>   ad_channel_sta0          ,
    seq_ver                =>   seq_ver                  ,
    up_data_freq_o         =>   up_data_freq_o           ,
    ad_channel_en0         =>   ad_channel_en0           ,
    work_mod               =>   work_mod                 ,
    commom_sig             =>   commom_sig               ,
    cfg_data_en            =>   cfg_data_en              ,
    trigger_sample_cmd     =>   trigger_sample_cmd       ,
    channel_check_en       =>   channel_check_en         ,
    channel_check0         =>   channel_check0           ,
    rst_n_usb              =>   rst_n_usb                ,
    rst_n_ad               =>   rst_n_ad          


);


----------------------------------------------
process(clkin,rst_n)
begin
    if rst_n='0' then
        s_axis_tvalid<='0';
        cnt_tx<=0;
        s1<=0;
    elsif rising_edge(clkin) then
        case s1 is
            when 0=>
                if tx_en='1' then
                    s1<=1;
                else
                    s1<=0;
                end if;
                s_axis_tvalid<='0';
                cnt_tx<=0;
                
            
            when 1=>
                cnt_tx<= cnt_tx+1;
                s_axis_tvalid<='1';
                s_axis_tdata<=usb_door_bell(cnt_tx);
                if cnt_tx>=19 then
                    s1<=2;
                end if;
            
            
            
            when 2=>
                s_axis_tvalid<='0';
                cnt_tx<=0;
                if tx_en='1' then
                    s1<=3;
                else
                    s1<=s1;
                end if;
            
            when 3=>
                s_axis_tdata<=cfg_data_buf(cnt_tx);
                s_axis_tvalid<='1';
                cnt_tx<= cnt_tx+1;
                if cnt_tx>=19 then
                    s1<=4;
                end if; 
            
            when 4=>
                s_axis_tvalid<='0';
                cnt_tx<=0;               
                if tx_en='1' then
                    s1<=5;
                else
                    s1<=s1;
                end if;  
            
            
            
            

            when 5=>    
                s_axis_tdata<=trigger_buf(cnt_tx);
                s_axis_tvalid<='1';
                cnt_tx<= cnt_tx+1;
                if cnt_tx>=19 then
                    s1<=6;
                end if; 
            
            
            -- when 5=>
                -- s_axis_tdata<=self_check_buf(cnt_tx);
                -- s_axis_tvalid<='1';
                -- cnt_tx<= cnt_tx+1;
                -- if cnt_tx>=19 then
                    -- s1<=6;
                -- end if; 
            
            
            
            when 6=>
                s_axis_tvalid<='0';
                cnt_tx<=0;             
            
            
            
            
            
            when others=>
                s1<=0;
        end case;
    end if;
end process;


process(clkin,rst_n)
variable cnt:integer:=0;
begin
    if rst_n='0' then
        cnt:=0;
        tx_en<='0';
    elsif rising_edge(clkin) then
        if cnt>=10**5 then
            cnt:=0;
        else
            cnt:=cnt+1;
        end if;
       
        if cnt=10 then
            tx_en<='1';
        else
            tx_en<='0';
        end if;
    end if;
end process;
          



process(clkin,rst_n)
variable cnt:integer:=101;
begin
    if rst_n='0' then
        ad_data_buf_vld<='0';
        cnt:=101;
    elsif rising_edge(clkin) then
        if channel_check_en='1' then
            cnt:=0;
        else
            if cnt>=100 then
                cnt:=cnt;
            else
                cnt:=cnt+1;
            end if;
        end if;
        
        if cnt=98 then
            ad_data_buf_vld<='1';
        else
            ad_data_buf_vld<='0';
        end if;
    end if;
end process;










end Behavioral;
