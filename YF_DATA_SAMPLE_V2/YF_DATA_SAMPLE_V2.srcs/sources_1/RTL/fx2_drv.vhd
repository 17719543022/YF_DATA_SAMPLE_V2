library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----CY7C68013A USBоƬ

entity fx2_drv is
port(
    clkin                   :in std_logic;
    rst_n                   :in std_logic;
    m_axis_usb_rx_tdata     :out std_logic_vector(15 downto 0);
    m_axis_usb_rx_tvalid    :out std_logic;
    s_axis_usb_tx_tdata     :in std_logic_vector(15 downto 0);
    s_axis_usb_tx_tvalid    :in std_logic;
    s_axis_usb_tx_tlast     :in std_logic;                                 ---ÿһ��������ʶ
-------------------------------------------------------------------------    
    fx2_fdata               :inout std_logic_vector(15 downto 0);          --FX2��USB2.0оƬ��SlaveFIFO��������
    fx2_flagb               :in std_logic;                                 --FX2��USB2.0оƬ�Ķ˵�2�ձ�־   0=>��  1=>�ǿ� ˵��usb���յ�����
    fx2_flagc               :in std_logic;                                 --FX2��USB2.0оƬ�Ķ˵�6����־
    fx2_ifclk               :in std_logic;                                 --FX2��USB2.0оƬ�Ľӿ�ʱ���ź�
    fx2_faddr               :out std_logic_vector(1 downto 0);             --FX2��USB2.0оƬ��SlaveFIFO��FIFO��ַ��
    fx2_sloe                :out std_logic;                                --FX2��USB2.0оƬ��SlaveFIFO�����ʹ���źţ��͵�ƽ��Ч
    fx2_slwr                :out std_logic;                                --FX2��USB2.0оƬ��SlaveFIFO��д�����źţ��͵�ƽ��Ч
    fx2_slrd                :out std_logic;                                --FX2��USB2.0оƬ��SlaveFIFO�Ķ������źţ��͵�ƽ��Ч 
    fx2_pkt_end             :out std_logic;                                --���ݰ�������־�ź�
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
-----------------------���ݽ���--------------------------------
process(fx2_flagb,s1,fx2_flagb_d1)              ------����������
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
     m_axis_tready      =>       m_axis_usb_tx_tready       ,   --fifoȡ���ݱ�־
     m_axis_tdata       =>       m_axis_usb_tx_tdata        ,
     m_axis_tlast       =>       m_axis_usb_tx_tlast   
     -- m_axis_tuser       =>       m_axis_tuser   
);  
----------------------��д״̬����-----------------------------
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
                when 0=>            ---����״̬
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
                
                when 1=>            ---д����״̬
                    fx2_faddr<="10";
                    m_axis_usb_tx_tready<='1' and fx2_flagc;        ---���USB�˵�6��FIFO״̬
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
                        fx2_pkt_end<='0';    ---����������������Ե���ÿ��������512�ֽ��趨�� ÿ�������������512������Ҫ�ִη��ͣ������ǲ�ʹ��fx2_pkt_end����
                    else
                        fx2_pkt_end<='1';
                    end if;
                
                
                
                when 3=>        ---������״̬
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