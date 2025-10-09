----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 8:54 2024/10/23
-- Design Name: 
-- Module Name: CTRL_EEPROM - Behavioral
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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CTRL_EEPROM is
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
end CTRL_EEPROM;

architecture Behavioral of CTRL_EEPROM is


component I2C_MASTER_SOP1 is
generic(
	CLK_FREQ	:INTEGER:=50*10**6;		-------主时钟频率（hz）
	SCL_FREQ	:INTEGER:=200*10**3;	-------I2C频率（hz）
	T_WR		:INTEGER:=5*10**6;		-------ns(两次数据写入的时间间隔）	--5ms
	T_RE		:INTEGER:=5*10**3;		-------ns(两次数据读取的时间间隔）	--5us
	DATA_SEQ	:STD_LOGIC:='0';		-------数据的发送顺序	0=>MSB->LSB  1=>LSB-MSB
-----------------------------------------------------------------------------------
	SEND_BYTE	:integer :=4;			-------发送的字节数(I2C写入)
-------------------------------------------------------------	
	ADDR_BYTE	:integer :=2;			-------地址的字节数（I2C读取）
	HEAD_BYTE	:integer :=1			-------I2C头的字节数（I2C读取）
);
 Port (
	clkin					:in std_logic;
	rst_n					:in std_logic;
----------------------------
	s_axis_tvalid			:in  std_logic;
	s_axis_tready			:out std_logic;
	s_axis_tdata			:in  std_logic_vector(8*SEND_BYTE-1 downto 0);
	s_axis_tuser			:in  std_logic_vector(7 downto 0);					------------操作类型（随机读(AA)，随机写(55)）
----------------------------------------------------------
	rd_data_vld				:out std_logic;
	rd_data_rdy				:in std_logic;
	rd_data					:out std_logic_vector((ADDR_BYTE+1)*8-1 downto 0);
	head_data				:out std_logic_vector(8*HEAD_BYTE-1 downto 0);
-----------------------------------------------
	sda						:inout std_logic;
	scl						:out std_logic;
------------------------------------------
	io_ctrl					:out std_logic
 );
end component;


signal	io_ctrl					: std_logic;
signal	s_axis_tvalid			: std_logic;
signal	s_axis_tready			: std_logic;
signal	s_axis_tdata			: std_logic_vector(8*4-1 downto 0);
signal	s_axis_tuser			: std_logic_vector(7 downto 0);		
signal	addr					: std_logic_vector(15 downto 0);		
signal	head_data			    : std_logic_vector(7 downto 0);		

signal	cfg_data_vld		    : std_logic;
signal	rd_data_vld				: std_logic;
signal	rd_data_rdy				:std_logic;
signal	rd_data					: std_logic_vector((2+1)*8-1 downto 0);




constant cmd_wr:std_logic_vector(7 downto 0):=X"55";
constant cmd_rd:std_logic_vector(7 downto 0):=X"AA";




------------------------------------------------------------------------
constant at24lc64:std_logic_vector(3 downto 0):="1010";
constant at24lc64_wr:std_logic:='0';
constant at24lc64_rd:std_logic:='1';
constant at24lc64_addr:std_logic_vector(2 downto 0):="000";

constant at24lc64_head_wr:std_logic_vector(7 downto 0):=B"1010_000_0";
constant at24lc64_head_rd:std_logic_vector(7 downto 0):=B"1010_000_1";

signal shift_reg:std_logic_vector(15 downto 0);

signal s3:integer range 0 to 7:=0;
signal s1:integer range 0 to 7:=0;
signal s2:integer range 0 to 7:=0;

signal cnt_rx:integer range 0 to 63:=0;


signal	write_over		    : std_logic;
signal	rx_buf_vld		    : std_logic;
signal	tx_en_vio		    : std_logic;
type t1 is array(0 to 15) of std_logic_vector(7 downto 0);

signal rx_buf:t1;
constant rx_buf1:t1:=(
X"00",
X"00",
X"20",
X"24",
X"10",
X"26",
X"00",
X"01",
X"00",
X"00",
X"00",
X"00",
X"00",
X"00",
X"00",
X"00"
);


-----------debug signal ----------------------------------------
attribute mark_debug : string;
attribute mark_debug of rx_buf_vld   : signal is "true";
attribute mark_debug of s_axis_uart_tvalid: signal is "true";
attribute mark_debug of s_axis_uart_tdata: signal is "true";


-- COMPONENT vio_0
  -- PORT (
    -- clk : IN STD_LOGIC;
    -- probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  -- );
-- END COMPONENT;

begin

process(clkin,rst_n)
begin
    if rst_n='0' then
        shift_reg<=(others=>'0');
    else
        if rising_edge(clkin) then
            if s_axis_uart_tvalid='1' then
                shift_reg<=shift_reg(7 downto 0)&s_axis_uart_tdata;
            else
                shift_reg<=shift_reg;
            end if;
        end if;
    end if;
end process;

s_axis_uart_tready<='1';

process(clkin,rst_n)
begin
    if rst_n='0' then
        rx_buf_vld<='0';
        s1<=0;
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>    
                    if s_axis_uart_tvalid='1' and shift_reg(7 downto 0)=X"AA" and s_axis_uart_tdata=X"55" then
                        s1<=1;
                    else
                        s1<=s1;
                    end if;
                    cnt_rx<=2;
                    rx_buf(0)<=X"AA";
                    rx_buf(1)<=X"55";
                    rx_buf_vld<='0';
                
                
                when 1=>
                    if s_axis_uart_tvalid='1' then
                        rx_buf(cnt_rx)<=s_axis_uart_tdata;
                        if cnt_rx>=8 then
                            cnt_rx<=0;
                            s1<=2;
                        else
                            cnt_rx<=cnt_rx+1;
                        end if;
                    else
                        s1<=s1;
                    end if;
                
                when 2=>
                    if rx_buf(8)=X"A3" then
                        rx_buf_vld<='1';
                    else
                        rx_buf_vld<='0';
                    end if;
                    s1<=0;
                
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;

ins_i2c:I2C_MASTER_SOP1 PORT MAP(

	clkin				=>	clkin				,
    rst_n			    =>	rst_n			    ,
    ----------------    =>	----------------    ,
    s_axis_tvalid	    =>	s_axis_tvalid	    ,
    s_axis_tready	    =>	s_axis_tready	    ,
    s_axis_tdata	    =>	s_axis_tdata	    ,
    s_axis_tuser	    =>	s_axis_tuser	    ,
    ----------------    =>	----------------    ,
    rd_data_vld		    =>	rd_data_vld		    ,
    rd_data_rdy		    =>	'1'		            ,
    rd_data			    =>	rd_data			    ,
    head_data			=>	head_data			,
    ----------------    =>	----------------    ,
    sda				    =>	sda				    ,
    scl				    =>	scl				    ,
    ----------------    =>	----------------    ,
    io_ctrl			    =>	io_ctrl			    
);
-----------------------------------------------------------------------


process(clkin,rst_n)
variable cnt:integer:=0;
begin
	if rst_n='0' then
		s2<=0;
		cnt:=0;
        write_over<='0';
	else
		if rising_edge(clkin) then
            case s2 is
                when 0=>
                    if cnt>=10000 then
                        cnt:=0;
                        s2<=1;
                    else
                        cnt:=cnt+1;
                    end if;
                    addr<=(others=>'0');
                    write_over<='0';
                when 1=>	        --读取命令
                    s_axis_tdata<=at24lc64_head_wr&addr&at24lc64_head_rd;
                    s_axis_tuser<=cmd_rd;
                    if s_axis_tready='1' and s_axis_tvalid='1' then
                        if addr>=5  then	
                            s2			<=2;
                        else
                            addr		 <=addr+1;
                        end if;
                        s_axis_tvalid<='0';
                    else
                        s_axis_tvalid<='1';
                    end if;
						
                when 2=>
                    if rx_buf_vld='1' then
                        addr		<=conv_std_logic_vector(0,16);
                        s2<=3;
                    else
                        s2<=s2;
                    end if;
                    cnt:=2;
                    s_axis_tvalid<='0';
                    s_axis_tuser<=cmd_wr;
                
                when 3=>                ---写入命令
  					s_axis_tdata<=at24lc64_head_wr&addr&rx_buf(cnt);
					if s_axis_tready='1' and s_axis_tvalid='1' then
						if addr>=5  then
							addr		<=conv_std_logic_vector(0,16);
							s2			<=0;
                            write_over<='1';
						else
							cnt:=cnt+1;
							addr		 <=addr+1;
						end if;
						s_axis_tvalid<='0';
					else
						s_axis_tvalid<='1';
					end if;	                  
					
					
                when others=>
                    s2<=0;
                
            end case;
		end if;
	end if;
end process;



process(clkin,rst_n)
variable cnt:integer:=0;
begin
    if rst_n='0' then
        tx_en_vio<='0';
        cnt:=0;
    else
        if rising_edge(clkin) then
            if cnt>=50*10**6-1 then
                tx_en_vio<='1';
                cnt:=0;
            else
                tx_en_vio<='0';
                cnt:=cnt+1;
            end if;
        end if;
    end if;
end process;
        


process(clkin,rst_n)
variable cnt:integer range 0 to 15;
begin
    if rst_n='0' then
        m_axis_uart_tvalid<='0';
        s3<=0;
    else
        if rising_edge(clkin) then
            case s3 is
                when 0=>
                    if write_over='1' then
                        s3<=1;
                    else
                        s3<=0;
                    end if;
                     m_axis_uart_tvalid<='0';
                     cnt:=0;
                
                when 1=>
                    m_axis_uart_tvalid<='1';
                    m_axis_uart_tdata<=X"55";
                    if cnt>=3 then
                        cnt:=0;
                        s3<=0;
                    else
                        cnt:=cnt+1;
                    end if;
                
                when others=>
                    s3<=0;
            end case;
        end if;
    end if;
end process;
                







---------------------获取数据解析------------------------------------------------------------------------------
process(clkin,rst_n)
begin
	if rst_n='0' then
        cfg_data_vld<='0';
        factor_num<=(others=>'0');
	else
		if rising_edge(clkin) then
			if rd_data_vld='1' then
				for i in 0 to 5 loop				
					if rd_data(23 downto 8)=i then
						factor_num(8*i+7 downto 0+8*i)<=rd_data(7 downto 0);
					end if;
				end loop;
			end if;
            
            if rd_data_vld='1'  and rd_data(7 downto 0)/=X"ff" and  rd_data(23 downto 8)<=5 then
                cfg_data_vld<='1';
            end if;


			if rd_data_vld='1' and cfg_data_vld='1'then
				if rd_data(23 downto 8)=5 then		
                    factor_num_vld<='1';
                else
                    factor_num_vld<='0';
				end if;
			else
				factor_num_vld<='0';
			end if;
		end if;
	end if;
end process;












end Behavioral;
