----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/12/19 09:49:38
-- Design Name: 
-- Module Name: UART_TOP_H_V2 - Behavioral
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
-- ins_uart_top:UART_TOP_H_V2 
-- generic map(

  -- ini_baud_div      	=>X"01b1"      ,
  -- ini_parity	        =>"00"	       ,
  -- ini_stop_bit          =>"01"         ,
  ------------    =>---------        ,
  -- fiforx_fifo_depth     =>0            ,
  -- fifotx_fifo_depth     =>0 
-- )
-- port map(
  -- clkin					=>	clkin			        ,	
  -- rst_n			        =>	rst_n			        ,
  -- cfg_data		        =>	uart_cfg_data		    ,
  -- cfg_vld			    =>	uart_cfg_vld			,
  ----------      =>	----------------            ,
  -- rxd				    =>	rxd				        ,
  -- txd				    =>	txd				        ,
  ----------      =>	----------------            ,
  -- s_axis_tvalid	        =>	s_axis_uart_tx_tvalid	,
  -- s_axis_tready	        =>	s_axis_uart_tx_tready	,
  -- s_axis_tdata	        =>	s_axis_uart_tx_tdata	,
  ----------      =>	----------------            ,
  -- rx_data_num		    =>	uart_rx_data_num		,
  -- rx_data_num_vld	    =>	uart_rx_data_num_vld	,
  -- m_axis_tvalid	        =>	m_axis_uart_rx_tvalid	,
  -- m_axis_tready	        =>	m_axis_uart_rx_tready	,
  -- m_axis_tdata	        =>	m_axis_uart_rx_tdata	,
  -- m_axis_tuser	        =>	m_axis_uart_rx_tuser	,
  -- m_axis_tkeep	        =>	m_axis_uart_rx_tkeep	,
  -- m_axis_tlast	        =>	m_axis_uart_rx_tlast	
-- );

-- signal	uart_cfg_data		    :std_logic_vector(31 downto 0);	--串口参数配置
-- signal	uart_cfg_vld			:std_logic:='0';	
-- signal	s_axis_uart_tx_tvalid	:std_logic;
-- signal	s_axis_uart_tx_tready	:std_logic;
-- signal	s_axis_uart_tx_tdata	:std_logic_vector(7 downto 0);
-- signal	uart_rx_data_num		:std_logic_vector(15 downto 0);
-- signal	uart_rx_data_num_vld	:std_logic;
-- signal	m_axis_uart_rx_tvalid	:std_logic;
-- signal	m_axis_uart_rx_tready	:std_logic;
-- signal	m_axis_uart_rx_tdata	:std_logic_vector(7 downto 0);
-- signal	m_axis_uart_rx_tuser	:std_logic;
-- signal	m_axis_uart_rx_tkeep	:std_logic;
-- signal	m_axis_uart_rx_tlast	:std_logic;

-------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_TOP_H_V2 is
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
end UART_TOP_H_V2;

architecture Behavioral of UART_TOP_H_V2 is

component UART_RX_H is
generic (
	ini_baud_div:std_logic_vector(15 downto 0):=X"01b1";	----时钟分频比 =主时频率/波特率-1
	ini_parity	:std_logic_vector(1 downto 0) :="01"        
);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
------------------------------
	rxd	 			:in std_logic;
	baud_div		:in std_logic_vector(15 downto 0);
	parity			:in std_logic_vector(1 downto 0);
	cfg_vld			:in std_logic;							--配置数据有效
	rx_data_num		:out std_logic_vector(15 downto 0);
	rx_data_num_vld	:out std_logic;	
	m_axis_tvalid	:out std_logic;
    m_axis_tready   :in  std_logic;
    m_axis_tdata    :out std_logic_vector(7 downto 0);
    m_axis_tlast	:out std_logic;							-- 表示串口接收到的朿后一个字
    m_axis_tuser	:out std_logic							--0表示数据校验正确 1表示数据校验错误

 );
end component;



component UART_TX_H is
generic (
	ini_baud_div:std_logic_vector(15 downto 0):=X"01b1";  
	ini_parity	:std_logic_vector(1 downto 0) :="01";	  
	ini_stop_bit:std_logic_vector(1 downto 0) :="01"	  
);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
---------------------------	
	txd	 			:out std_logic;
	baud_div		:in std_logic_vector(15 downto 0);
	parity			:in std_logic_vector(1 downto 0);
	stop_bit		:in std_logic_vector(1 downto 0);
	cfg_vld			:in std_logic;
	s_axis_tvalid	:in std_logic;
    s_axis_tready   :out  std_logic;
    s_axis_tdata    :in std_logic_vector(7 downto 0)
 );
end component;


signal	baud_div		: std_logic_vector(15 downto 0);
signal	parity			: std_logic_vector(1 downto 0);
signal	stop_bit		: std_logic_vector(1 downto 0);
------------------------------------------------------------------------------

component FIFO_SYNC_H_V1 is
generic(
	data_width:integer:=8;
	user_width:integer:=1;
	fifo_depth:integer:=8
);
 Port (
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


signal m_axis_uart_rx_tvalid	:std_logic;
signal m_axis_uart_rx_tready    :std_logic;
signal m_axis_uart_rx_tdata     :std_logic_vector(7 downto 0);
signal m_axis_uart_rx_tlast	    :std_logic;
signal m_axis_uart_rx_tuser	    :std_logic;



signal m_axis_fifo_tx_tvalid	:std_logic;
signal m_axis_fifo_tx_tready    :std_logic;
signal m_axis_fifo_tx_tdata     :std_logic_vector(7 downto 0);
signal m_axis_fifo_tx_tlast	    :std_logic;
signal m_axis_fifo_tx_tuser	    :std_logic;








begin


baud_div<=cfg_data(15 downto 0);
parity<=cfg_data(17 downto 16);
stop_bit<=cfg_data(19 downto 18);

---------------------------------------------------------
ins_uart_rx:UART_RX_H 
generic map(

	ini_baud_div	=>	ini_baud_div,
    ini_parity	    =>	ini_parity	
)
port map(
	clkin				=>	clkin				        ,
    rst_n			    =>	rst_n			            ,
    ----------------    =>	----------------            ,
    rxd	 			    =>	rxd	 			            ,
    baud_div		    =>	baud_div		            ,
    parity			    =>	parity			            ,
    cfg_vld			    =>	cfg_vld			            ,
    rx_data_num			=>	rx_data_num			        ,
    rx_data_num_vld		=>	rx_data_num_vld		        ,
    m_axis_tvalid	    =>	m_axis_uart_rx_tvalid	    ,
    m_axis_tready       =>	m_axis_uart_rx_tready     	,
    m_axis_tdata        =>	m_axis_uart_rx_tdata      	,
    m_axis_tlast	    =>	m_axis_uart_rx_tlast	    ,
    m_axis_tuser	    =>	m_axis_uart_rx_tuser	
);
m_axis_tkeep<='1';

fiforx_g1:if fiforx_fifo_depth>0 generate
begin

ins_rx_fifo:FIFO_SYNC_H_V1 
generic map(

	data_width	=>8					,
    user_width  =>1 			    ,
    fifo_depth  =>fiforx_fifo_depth
)
port map(
	s_aclk       	=>	clkin         			,
    s_aresetn       =>	rst_n                   ,
    s_axis_tvalid   =>	m_axis_uart_rx_tvalid	, 
    s_axis_tready   =>	m_axis_uart_rx_tready   , 
    s_axis_tdata    =>	m_axis_uart_rx_tdata    , 
    s_axis_tlast    =>	m_axis_uart_rx_tlast	, 
    s_axis_tuser(0) =>	m_axis_uart_rx_tuser	, 
    m_axis_tvalid   =>	m_axis_tvalid           ,
    m_axis_tready   =>	m_axis_tready           ,
    m_axis_tdata    =>	m_axis_tdata            ,
    m_axis_tlast    =>	m_axis_tlast            ,
    m_axis_tuser(0) =>	m_axis_tuser  
);

end generate;

fiforx_g2:if fiforx_fifo_depth=0 generate
begin
	m_axis_tvalid	<=m_axis_uart_rx_tvalid		;	
	m_axis_uart_rx_tready   <=m_axis_tready     ;
	m_axis_tdata    <=m_axis_uart_rx_tdata      ;
	m_axis_tlast    <=m_axis_uart_rx_tlast	    ;
	m_axis_tuser    <=m_axis_uart_rx_tuser	    ;

end generate;
-------------------------------------------------------------------

fifotx_g1:if fifotx_fifo_depth>0 generate
begin

ins_tx_fifo:FIFO_SYNC_H_V1 
generic map(

	data_width	=>8					,
    user_width  =>1 			    ,
    fifo_depth  =>fifotx_fifo_depth
)
port map(
	s_aclk       	=>	clkin         			        ,
    s_aresetn       =>	rst_n                           ,
    s_axis_tvalid   =>	s_axis_tvalid	                , 
    s_axis_tready   =>	s_axis_tready	                , 
    s_axis_tdata    =>	s_axis_tdata	                , 
    s_axis_tlast    =>	'1'	                            , 
    s_axis_tuser    =>	"1"	                            , 
    m_axis_tvalid   =>	m_axis_fifo_tx_tvalid           ,
    m_axis_tready   =>	m_axis_fifo_tx_tready           ,
    m_axis_tdata    =>	m_axis_fifo_tx_tdata            ,
    m_axis_tlast    =>	m_axis_fifo_tx_tlast            ,
    m_axis_tuser(0) =>	m_axis_fifo_tx_tuser  
);

end generate;

fifotx_g2:if fifotx_fifo_depth=0 generate
begin

m_axis_fifo_tx_tvalid	<=	s_axis_tvalid	;
s_axis_tready   <=  m_axis_fifo_tx_tready	;
m_axis_fifo_tx_tdata    <=  s_axis_tdata	;

end generate;

ins_uart_tx:UART_TX_H 
generic map(

ini_baud_div	=>	ini_baud_div	,
ini_parity	    =>	ini_parity	    ,
ini_stop_bit    =>	ini_stop_bit
)

port map(

	clkin				=>	clkin				        ,
    rst_n			    =>	rst_n			            ,
    ----------------    =>	----------------            ,
    txd	 			    =>	txd	 			            ,
    baud_div		    =>	baud_div		            ,
    parity			    =>	parity			            ,
    stop_bit		    =>	stop_bit		            ,
    cfg_vld			    =>	cfg_vld			            ,
    s_axis_tvalid	    =>	m_axis_fifo_tx_tvalid	    ,
    s_axis_tready       =>	m_axis_fifo_tx_tready     	,
    s_axis_tdata        =>	m_axis_fifo_tx_tdata    
);


















end Behavioral;
