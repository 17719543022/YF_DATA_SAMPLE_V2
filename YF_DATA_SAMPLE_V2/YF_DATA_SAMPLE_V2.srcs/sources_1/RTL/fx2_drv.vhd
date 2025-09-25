library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----CY7C68013A USB芯片

entity fx2_drv is
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

end fx2_drv;


architecture behav of fx2_drv is


component fifo_asyn_altera is
generic(
	data_width:integer:=16;
	user_width:integer:=1;
	fifo_depth:integer:=12
);
 Port (
    m_aclk           : IN STD_LOGIC;
    s_aclk           : IN STD_LOGIC;
    s_aresetn        : IN STD_LOGIC;
    s_axis_tvalid    : IN STD_LOGIC;
    s_axis_tready    : OUT STD_LOGIC;
    s_axis_tdata     : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
    s_axis_tlast     : IN STD_LOGIC;
    s_axis_tuser     : IN STD_LOGIC_VECTOR(user_width-1 DOWNTO 0);
    m_axis_tvalid    : OUT STD_LOGIC;
    m_axis_tready    : IN STD_LOGIC;
    m_axis_tdata     : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
    m_axis_tlast     : OUT STD_LOGIC;
    m_axis_tuser     : OUT STD_LOGIC_VECTOR(user_width-1 DOWNTO 0)
 );
end component;



component FIFO_ASYNC_H_V1 is
generic(
	data_width:integer:=16;
	user_width:integer:=1;
	fifo_depth:integer:=12
);
 Port (
    m_aclk           : IN STD_LOGIC;
    s_aclk           : IN STD_LOGIC;
    s_aresetn        : IN STD_LOGIC;
    s_axis_tvalid    : IN STD_LOGIC;
    s_axis_tready    : OUT STD_LOGIC;
    s_axis_tdata     : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
    s_axis_tlast     : IN STD_LOGIC;
    s_axis_tuser     : IN STD_LOGIC_VECTOR(user_width-1 DOWNTO 0);
    m_axis_tvalid    : OUT STD_LOGIC;
    m_axis_tready    : IN STD_LOGIC;
    m_axis_tdata     : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
    m_axis_tlast     : OUT STD_LOGIC;
    m_axis_tuser     : OUT STD_LOGIC_VECTOR(user_width-1 DOWNTO 0)
 );
end component;

















signal usb_rst_n0:std_logic;
signal usb_rst_n:std_logic;
signal wr_st:std_logic;
signal usb_rx_vld:std_logic;

signal usb_rx_data:std_logic_vector(15 downto 0);


signal m_axis_usb_tx_tdata:std_logic_vector(15 downto 0);
signal m_axis_usb_tx_tvalid:std_logic;
signal fx2_flagb_d1:std_logic;
signal fx2_flagb_d2:std_logic;
signal m_axis_usb_tx_tready:std_logic;
signal m_axis_usb_tx_tlast:std_logic;
signal fx2_drv_st:std_logic_vector(1 downto 0);
signal s1 :integer range 0 to 3;
signal cnt :integer range 0 to 3;

begin

fx2_slcs<='0';


process(fx2_ifclk,rst_n)
begin
    if rst_n='0' then
        usb_rst_n0<='0';
        usb_rst_n<='0';
    else
        if rising_edge(fx2_ifclk) then
            usb_rst_n0<='1';
            usb_rst_n<=usb_rst_n0;
        end if;
    end if;
end process;
-----------------------数据接收--------------------------------
process(fx2_flagb,s1,fx2_flagb_d1)              ------产生读命令
begin
    if s1=3 and  fx2_flagb='1' and fx2_flagb_d1='1' then
        fx2_sloe<='0';
        fx2_slrd<='0';
    else
        fx2_sloe<='1';
        fx2_slrd<='1'; 
    end if;
end process;

process(fx2_ifclk)
begin
    if rising_edge(fx2_ifclk) then
        fx2_flagb_d1<=fx2_flagb;
        -- fx2_flagb_d2<=fx2_flagb_d1;
        if  s1=3 and fx2_flagb='1' and fx2_flagb_d1='1' then
            usb_rx_data<=fx2_fdata;
            usb_rx_vld <='1';
        else
            usb_rx_vld <='0';
        end if;
    end if;
end process;

ins_fifo_usb_rx:FIFO_ASYNC_H_V1 port map(
     m_aclk             =>       clkin                      ,
     s_aclk             =>       fx2_ifclk                  ,
     s_aresetn          =>       '1'                        ,
     s_axis_tvalid      =>       usb_rx_vld                 ,
--     s_axis_tready      =>       s_axis_tready            ,
     s_axis_tdata       =>       usb_rx_data                ,
     s_axis_tlast       =>       '0'                        ,
     s_axis_tuser       =>       "0"                        ,
     m_axis_tvalid      =>       m_axis_usb_rx_tvalid       ,
     m_axis_tready      =>       '1'                        ,
     m_axis_tdata       =>       m_axis_usb_rx_tdata   
     -- m_axis_tlast       =>       m_axis_tlast   
     -- m_axis_tuser       =>       m_axis_tuser   
);
-----------------------------------------------------------
  ins_fifo_usb_tx:FIFO_ASYNC_H_V1 port map(
     m_aclk             =>       fx2_ifclk                  ,
     s_aclk             =>       clkin                      ,
     s_aresetn          =>       '1'                        ,
     s_axis_tvalid      =>       s_axis_usb_tx_tvalid       ,
--     s_axis_tready      =>       s_axis_tready            ,
     s_axis_tdata       =>       s_axis_usb_tx_tdata        ,
     s_axis_tlast       =>       s_axis_usb_tx_tlast        ,
     s_axis_tuser       =>       "0"                        ,
     m_axis_tvalid      =>       m_axis_usb_tx_tvalid       ,
     m_axis_tready      =>       m_axis_usb_tx_tready       ,   --fifo取数据标志
     m_axis_tdata       =>       m_axis_usb_tx_tdata        ,
     m_axis_tlast       =>       m_axis_usb_tx_tlast   
     -- m_axis_tuser       =>       m_axis_tuser   
);  
----------------------读写状态控制-----------------------------
process(fx2_ifclk,usb_rst_n)
begin
    if usb_rst_n='0' then
        s1<=0;
        fx2_slwr<='1';
        m_axis_usb_tx_tready<='0';
        fx2_pkt_end<='1';
    else
        if rising_edge(fx2_ifclk) then
            case s1 is
                when 0=>            ---空闲状态
                    if m_axis_usb_tx_tvalid='1' then
                        s1<=1;
                    elsif fx2_flagb_d1='1' then
                        s1<=3;
                    else
                        s1<=s1;
                    end if;
                    fx2_faddr<="00";
                    fx2_fdata<=(others=>'Z');
                    fx2_slwr<='1';
                    m_axis_usb_tx_tready<='0';
                    fx2_pkt_end<='1';
                    cnt<=0;
                
                when 1=>            ---写数据状态
                    fx2_faddr<="10";
                    m_axis_usb_tx_tready<='1' and fx2_flagc;        ---检查USB端点6的FIFO状态
                    if m_axis_usb_tx_tlast='1' and m_axis_usb_tx_tready='1' and m_axis_usb_tx_tvalid='1' then
                        fx2_fdata  <=m_axis_usb_tx_tdata;
                        fx2_slwr<='0';
                    elsif m_axis_usb_tx_tready='1' and m_axis_usb_tx_tvalid='1' then
                        fx2_fdata  <=m_axis_usb_tx_tdata;
                        fx2_slwr<='0';
                    else
                        fx2_slwr<='1';
                    end if;
                
                    if m_axis_usb_tx_tvalid='0' or (m_axis_usb_tx_tlast='1' and m_axis_usb_tx_tready='1' and m_axis_usb_tx_tvalid='1') then
                        s1<=2;
                        m_axis_usb_tx_tready<='0';
                    end if;
                    cnt<=0;
                
                when 2=>               
                    fx2_slwr<='1';
                    cnt<=cnt+1;
                    if cnt>=2 then
                        s1<=0;
                    else
                        s1<=s1;
                    end if;
                    
                    if cnt=0 then
                        fx2_pkt_end<='0';    ---产生包结束命令针对的是每包不超过512字节设定的 每包数据如果超过512字则需要分次发送，或者是不使用fx2_pkt_end命令
                    else
                        fx2_pkt_end<='1';
                    end if;
                
                
                
                when 3=>        ---读数据状态
                    if fx2_flagb_d1='0' then
                        s1<=0;
                    end if; 
                
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;
                









end behav;