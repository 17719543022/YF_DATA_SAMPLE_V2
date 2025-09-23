----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/12/19 09:03:09
-- Design Name: 
-- Module Name: FIFO_ASYNC_H_V1 - Behavioral
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
Library xpm;
use xpm.vcomponents.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIFO_ASYNC_H_V1 is
generic(
	data_width:integer:=8;
	user_width:integer:=1;
	fifo_depth:integer:=8
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
end FIFO_ASYNC_H_V1;

architecture Behavioral of FIFO_ASYNC_H_V1 is

signal din:std_logic_vector(data_width+user_width+1-1 downto 0);
signal dout:std_logic_vector(data_width+user_width+1-1 downto 0);
signal full:std_logic;
signal rd_en:std_logic;
signal empty:std_logic;
signal fifo_rst:std_logic;

begin


fifo_rst<=not s_aresetn;

xpm_fifo_async_inst : xpm_fifo_async
  generic map (

    FIFO_MEMORY_TYPE        => "auto",           --string; "auto", "block", or "distributed";
    ECC_MODE                => "no_ecc",         --string; "no_ecc" or "en_ecc";
    RELATED_CLOCKS          => 0,                --positive integer; 0 or 1
    FIFO_WRITE_DEPTH        => 2**fifo_depth,               --positive integer
    WRITE_DATA_WIDTH        => data_width+user_width+1,               --positive integer
    WR_DATA_COUNT_WIDTH     => fifo_depth+1  ,               --positive integer
    PROG_FULL_THRESH        => 10,               --positive integer
    FULL_RESET_VALUE        => 1,                --positive integer; 0 or 1;
    USE_ADV_FEATURES        => "0707",           --string; "0000" to "1F1F"; --default "0707"
    READ_MODE               => "fwft",            --string; "std" or "fwft";
    FIFO_READ_LATENCY       => 1,                --positive integer;
    READ_DATA_WIDTH         => data_width+user_width+1,               --positive integer
    RD_DATA_COUNT_WIDTH     => fifo_depth+1,               --positive integer
    PROG_EMPTY_THRESH       => 10,               --positive integer
    DOUT_RESET_VALUE        => "0",              --string
    CDC_SYNC_STAGES         => 2,                --positive integer
    WAKEUP_TIME             => 0                 --positive integer; 0 or 2;
  )
  port map (
    sleep            => '0',
    rst              => fifo_rst,
    wr_clk           => s_aclk,
    wr_en            => s_axis_tvalid,
    din              => din,
    full             => full,
    almost_full      => open,
    wr_ack           => open,
    rd_clk           => m_aclk,
    rd_en            => rd_en,
    dout             => dout,
    empty            => empty,
    -- underflow        => underflow,
    -- rd_rst_busy      => rd_rst_busy,
    -- prog_empty       => prog_empty,
    -- rd_data_count    => rd_data_count,
    almost_empty     => open,
    data_valid       => open,
    injectsbiterr    => '0',
    injectdbiterr    => '0',
    sbiterr          => open,
    dbiterr          => open
  );

din	         <=s_axis_tdata&s_axis_tuser&s_axis_tlast;
s_axis_tready<=not full;

rd_en		 <=m_axis_tready;
m_axis_tvalid<= not empty;


m_axis_tdata<=dout(data_width+user_width downto user_width+1);
m_axis_tuser<=dout(user_width downto 1);
m_axis_tlast<=dout(0);







end Behavioral;
