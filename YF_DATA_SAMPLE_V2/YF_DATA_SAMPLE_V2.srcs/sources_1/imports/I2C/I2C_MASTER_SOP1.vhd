----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/01/21 10:58:41
-- Design Name: 
-- Module Name: I2C_MASTER_SOP1 - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

entity I2C_MASTER_SOP1 is
generic(
	CLK_FREQ	:INTEGER:=50*10**6;		-------主时钟频率（hz）
	SCL_FREQ	:INTEGER:=400*10**3;	-------I2C频率（hz）
	T_WR		:INTEGER:=5*10**6;		-------ns(两次数据写入的时间间隔）	--5ms
	T_RE		:INTEGER:=5*10**3;		-------ns(两次数据读取的时间间隔）	--5us
	DATA_SEQ	:STD_LOGIC:='0';		-------数据的发送顺序	0=>MSB->LSB  1=>LSB-MSB
-----------------------------------------------------------------------------------
	SEND_BYTE	:integer :=3;			-------发送的字节数(I2C写入)
-------------------------------------------------------------	
	ADDR_BYTE	:integer :=1;			-------地址的字节数（I2C读取）
	HEAD_BYTE	:integer :=1			-------I2C头的字节数（I2C读取）
);
 Port (
	clkin:in std_logic;
	rst_n:in std_logic;
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
end I2C_MASTER_SOP1;

architecture Behavioral of I2C_MASTER_SOP1 is

constant unit_time:integer	 :=10**9/CLK_FREQ;----ns
constant wait_time_wr:integer:=T_WR/unit_time;	--5ms
constant wait_time_re:integer:=T_RE/unit_time;	--5000ns

constant i2c_div:integer:=CLK_FREQ/SCL_FREQ;
constant nuit_i2c_div:integer:=i2c_div/4;

constant time_neg:integer:=0;
constant time_neg_mid:integer:=time_neg+nuit_i2c_div;
constant time_pos:integer:=time_neg_mid+nuit_i2c_div;
constant time_pos_mid:integer:=time_pos+nuit_i2c_div;

--------------------20ns-----------------------
signal cnt_scl:integer:=0;


signal s1:integer range 0 to 10:=0;
signal s2:integer range 0 to 16:=0;

signal sda_in:std_logic:='0';
signal sda_out:std_logic:='0';
signal scl_i:std_logic:='0';


signal sda_out_buf:std_logic:='0';
signal ACK:std_logic:='0';
signal T:std_logic:='0';
signal s_axis_tready_buf:std_logic:='0';
signal tx_over:std_logic:='0';
signal rx_data_buf_vld:std_logic:='0';
signal rx_data_buf_vld_i:std_logic:='0';
signal rx_data_ing:std_logic:='0';


signal rx_data_buf:std_logic_vector(7 downto 0);
signal rx_data_buf_i:std_logic_vector((ADDR_BYTE+1)*8-1 downto 0);
signal data1:std_logic_vector(7 downto 0);
signal data2:std_logic_vector(7 downto 0);
signal data3:std_logic_vector(7 downto 0);
signal control_byte_read:std_logic_vector(7 downto 0);
signal control_byte:std_logic_vector(7 downto 0);
signal word_addr:std_logic_vector(8*ADDR_BYTE-1 downto 0);

type t1 is array(0 to SEND_BYTE-1) of std_logic_vector(7 downto 0);
signal data:t1;
signal tx_data:std_logic_vector(7 downto 0);




type i2c_mode is (idle,write_mode,read_mode);
signal i2c_mode_state:i2c_mode;
---------------------------------------------
signal scl_buf_pos		:std_logic:='0';
signal scl_buf_pos_mid	:std_logic:='0';
signal scl_buf_neg		:std_logic:='0';
signal scl_buf_neg_mid	:std_logic:='0';
signal i2c_working	    :std_logic:='0';


-------------------------------------------------------

COMPONENT ila_0

PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC; 
	probe1 : IN STD_LOGIC; 
	probe2 : IN STD_LOGIC; 
	probe3 : IN STD_LOGIC; 
	probe4 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
	probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	probe8 : IN STD_LOGIC
);
END COMPONENT  ;


signal s1_i:std_logic_vector(4 downto 0);
signal s2_i:std_logic_vector(4 downto 0);
signal tx_data1:std_logic_vector(8 downto 0);








begin


s1_i<= conv_std_logic_vector(s1,5);
s2_i<= conv_std_logic_vector(s2,5);


--UUT : ila_0
--PORT MAP (
--	clk    => clkin,
--	probe0 => scl_i, 
--	probe1 => sda_out, 
--	probe2 => sda_in, 
--	probe3 => T, 
--	probe4 => s1_i, 
--	probe5 => s2_i, 
--	probe6 => tx_data, 
--	probe7 => rx_data_buf_i,
--	probe8 => rx_data_buf_vld_i
--);
--------------------------------------------

process(clkin)
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			cnt_scl<=time_pos;
			scl_buf_neg<='0';
			scl_buf_neg_mid<='0';
			scl_buf_pos<='0';
			scl_buf_pos_mid<='0';
		else
			if i2c_working='1' then
				if cnt_scl>=i2c_div-1 then
					cnt_scl<=0;
				else
					cnt_scl<=cnt_scl+1;
				end if;
			else
				cnt_scl<=time_pos;
			end if;
			
			if cnt_scl=time_neg then
				scl_buf_neg<='1';
			else
				scl_buf_neg<='0';
			end if;

			if cnt_scl=time_neg_mid then
				scl_buf_neg_mid<='1';
			else
				scl_buf_neg_mid<='0';
			end if;
			
			if cnt_scl=time_pos then
				scl_buf_pos<='1';
			else
				scl_buf_pos<='0';
			end if;
			
			if cnt_scl=time_pos_mid then
				scl_buf_pos_mid<='1';
			else
				scl_buf_pos_mid<='0';
			end if;
			
			if i2c_working='1' then
				if scl_buf_pos='1' then
					scl_i<='1';
				elsif scl_buf_neg='1' then
					scl_i<='0';
				else
					scl_i<=scl_i;
				end if;
			else
				scl_i<='1';
			end if;
		end if;
	end if;
end process;

scl<=scl_i;

io_ctrl<=T;
--------------------------------------------------------

 IOBUF_inst : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "DEFAULT",
      SLEW => "SLOW")
   port map (
      O => sda_in,     -- Buffer output
      IO => sda,   -- Buffer inout port (connect directly to top-level port)
      I => sda_out,     -- Buffer input
      T => T      -- 3-state enable input, high=input, low=output 
   );
--------------------------------------------------------------------------------
sda_out<=sda_out_buf;

s_axis_tready<=s_axis_tready_buf;

rd_data_vld<=rx_data_buf_vld_i;
rd_data<=rx_data_buf_i;



process(clkin)
variable cnt:integer:=0;			------I2C的时序计数器
variable cnt1:integer:=0;			------数据读取时的状态寄存器
variable cnt2:integer:=0;			------控制发送字节数计数器
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			s_axis_tready_buf<='0';
			s1<=0;
			s2<=0;
			i2c_mode_state<=idle;
			rx_data_buf_vld<='0';
			rx_data_ing<='0';
			rx_data_buf<=(others=>'0');
			rx_data_buf_i<=(others=>'0');
		else
			case i2c_mode_state  is
				when idle =>
					if s_axis_tready_buf='1' and s_axis_tvalid='1'  then
						if s_axis_tuser=X"55" then
							i2c_mode_state<=write_mode;
							s_axis_tready_buf<='0';
						elsif s_axis_tuser=X"AA" then
							i2c_mode_state<=read_mode;
							s_axis_tready_buf<='0';
						else
							i2c_mode_state<=idle;
							s_axis_tready_buf<='1';
						end if;
						
						for i in 0 to SEND_BYTE-1 loop 
							data(i)<=s_axis_tdata(8*(SEND_BYTE-i)-1 downto 8*(SEND_BYTE-1-i));
						end loop;
						word_addr<=s_axis_tdata(8*(SEND_BYTE-HEAD_BYTE)-1 downto 8*(SEND_BYTE-ADDR_BYTE-HEAD_BYTE));
						head_data<=s_axis_tdata(8*(SEND_BYTE)-1 downto 8*(SEND_BYTE-HEAD_BYTE));
					else
						s_axis_tready_buf<='1';
					end if;
					T<='0';					------------输出
					sda_out_buf<='1';
					s1<=0;
					s2<=0;
					rx_data_buf_vld<='0';
					cnt:=0;
					cnt1:=0;
					cnt2:=0;
					rx_data_ing<='0';
					i2c_working<='0';
				when write_mode =>
					case s1 is
						when 0=>
							i2c_working<='1';
							T<='0';	
							s1<=1;
							sda_out_buf<='1';
							cnt2:=0;
							
						when 1=>
							if scl_buf_pos_mid='1' then
								sda_out_buf<='0';
								s1<=2;
							else
								sda_out_buf<=sda_out_buf;
							end if;
			
						when 2=>
							s1<=3;
							T<='0';
							cnt1:=0;
							tx_over<='0';
							tx_data<=data(cnt2);
							
							
						when 3=>
							if scl_buf_neg_mid='1' then
								if  DATA_SEQ='0' then
									sda_out_buf<=tx_data(7-cnt1);
								else
									sda_out_buf<=tx_data(cnt1);
								end if;
								
								if cnt1=7 then
									cnt1:=cnt1;
									tx_over<='1';
								else
									cnt1:=cnt1+1;
									tx_over<='0';
								end if;
							else
								tx_over<=tx_over;
							end if;

							if tx_over='1' and scl_buf_pos_mid='1' then
								s1<=4;
								tx_over<='0';
							else
								s1<=s1;
							end if;	
							
						when 4=>		-------ACK 检查
							T<='1';
							if scl_buf_pos_mid='1' then
								ACK<= NOT sda_in;
								s1<=5;
							else
								ACK<=ACK;
							end if;
							
							if scl_buf_neg_mid ='1' then
								T<='1';
							else
								T<=T;
							end if;
							
							if scl_buf_neg_mid='1' then
								sda_out_buf<='0';
							else
								sda_out_buf<=sda_out_buf;
							end if; 
							

						when 5=>
							T<='0';
							cnt:=0;
							if ACK='1'  and  cnt2=SEND_BYTE-1 then
								s1<=6;
							else
								s1<=2;
								if ACK='1' then
									cnt2:=cnt2+1;
								else
									cnt2:=cnt2;
								end if;
							end if;

						when 6=>
							T<='0';
                            if scl_buf_pos_mid='1' then        -------停止
                                sda_out_buf<='1';
                                s1<=7;
                            else
                                sda_out_buf<='0';
                            end if;
	
						when 7=>
							i2c_working<='0';
							if cnt=wait_time_wr then
								i2c_mode_state<=idle;
								s1<=0;
								cnt:=0;
							else
								cnt:=cnt+1;
							end if;
						
						when others=>
							s1<=0;
					end case;
			
				when read_mode =>
					case s2 is
						when 0=>
							sda_out_buf<='1';
							T<='0';	
							cnt2:=0;
							if rd_data_rdy='1' then
								i2c_working<='1';
								s2<=1;
							else
								i2c_working<='0';
								s2<=s2;
							end if;
							
							
						when 1=>
							if scl_buf_pos_mid='1' then
								sda_out_buf<='0';
								s2<=2;
							else
								sda_out_buf<=sda_out_buf;
							end if;
			

						when 2=>
							T<='0';
							s2<=3;
							tx_data<=data(cnt2);
							cnt1:=0;
							tx_over<='0';


						when 3=>
							if scl_buf_neg_mid='1' then
								if  DATA_SEQ='0' then
									sda_out_buf<=tx_data(7-cnt1);
								else
									sda_out_buf<=tx_data(cnt1);
								end if;
								if cnt1=7 then
									cnt1:=cnt1;
									tx_over<='1';
								else
									cnt1:=cnt1+1;
									tx_over<='0';
								end if;
							else
								s2<=s2;
							end if;
							
							if tx_over='1' and scl_buf_pos_mid='1' then
								s2<=4;
								tx_over<='0';
							else
								s2<=s2;
							end if;
							
						
						when 4=>
						
							if scl_buf_pos_mid='1' then
								ACK<= NOT sda_in;
								s2<=5;
							else
								ACK<=ACK;
							end if;
							
							if scl_buf_neg_mid='1' then
								sda_out_buf<='0';
							else
								sda_out_buf<=sda_out_buf;
							end if;
							
							if scl_buf_neg_mid='1' then
								T<='1';
							else
								T<=T;
							end if;
							

						when 5=>
							T<='0';
							cnt:=0;
							if ACK='1'  and  cnt2 =ADDR_BYTE+HEAD_BYTE-1 then
								s2<=6;
								cnt2:=cnt2+1;
							else
								s2<=2;
								if ACK='1' then
									cnt2:=cnt2+1;
								else
									cnt2:=cnt2;
								end if;
							end if;

						when 6=>
							T<='0';	
							s2<=7;
							
						when 7=>
							if scl_buf_pos_mid='1' then		------开始
								sda_out_buf<='0';
								s2<=8;
							elsif scl_buf_neg_mid='1' then
								sda_out_buf<='1';
							else
								sda_out_buf<=sda_out_buf;
							end if;
							
							
						when 8=>
							T<='0';
							tx_data<=data(cnt2);
							s2<=9;
							cnt1:=0;
							tx_over<='0';			
						
						when 9=>
							if scl_buf_neg_mid='1' then
								if  DATA_SEQ='0' then
									sda_out_buf<=tx_data(7-cnt1);
								else
									sda_out_buf<=tx_data(cnt1);
								end if;
								
								if cnt1=7 then
									cnt1:=cnt1;
									tx_over<='1';
								else
									cnt1:=cnt1+1;
									tx_over<='0';
								end if;
							else
								cnt1:=cnt1;
							end if;
							
							
							if tx_over='1' and scl_buf_pos_mid='1' then
								s2<=10;
								tx_over<='0';
							else
								s2<=s2;
							end if;
			
						when 10=>
							if scl_buf_pos_mid='1' then
								ACK<= NOT sda_in;
								s2<=11;
							else
								ACK<=ACK;
							end if;
							
							if scl_buf_neg_mid='1' then
								sda_out_buf<='0';
							else
								sda_out_buf<=sda_out_buf;
							end if;
							
							if scl_buf_neg_mid='1' then
								T<='1';
							else
								T<=T;
							end if;
		

						when 11=>
							T<='1';
							cnt:=0;
							cnt1:=0;
							sda_out_buf<='0';
							if ACK='1'  and  cnt2=HEAD_BYTE+ADDR_BYTE+HEAD_BYTE-1 then
								s2<=12;
							else
								s2<=8;
								if ACK='1' then
									cnt2:=cnt2+1;
								else
									cnt2:=cnt2;
								end if;
							end if;				
--------------------------------------RX DATA----------------------------------------------------
						when 12=>
							rx_data_ing<='1';
							T<='1';
							if scl_buf_pos_mid='1' then
								if DATA_SEQ='0' then
									rx_data_buf(7- cnt)<=sda_in;
								else
									rx_data_buf(cnt)<=sda_in;
								end if;
								if cnt=7 then
									rx_data_buf_vld<='1';
								else
									cnt:=cnt+1;
									rx_data_buf_vld<='0';
								end if;
							else
								cnt:=cnt;
							end if;
							
							if rx_data_buf_vld='1' and scl_buf_neg='1' then
								s2<=13;
								rx_data_buf_vld_i<='1';
								rx_data_buf_i<=word_addr&rx_data_buf;
							else
								rx_data_buf_vld_i<='0';
								s2<=s2;
							end if;
						
						when 13=>				---------发送NCK
							rx_data_ing<='0';
							T<='0';
							rx_data_buf_vld_i<='0';
							rx_data_buf_vld	 <='0';
							if scl_buf_neg_mid='1' then
								sda_out_buf<='1' ;
							elsif scl_buf_pos_mid='1' then
								s2<=14;
							else
								s2<=s2;
							end if;			
----------------------------------------产生停止条件----------------------------			
						when 14=>
							T<='0';	
							if scl_buf_pos_mid='1' then		-------停止
								sda_out_buf<='1';
								s2<=15;
							else
								sda_out_buf<='0';
							end if;
						
						when 15=>
							i2c_working<='0';
							if cnt=wait_time_re then
								cnt:=0;
								i2c_mode_state<=idle;
								s2<=0;
							else
								cnt:=cnt+1;
							end if;
						
						when others=>
							s2<=0;
					end case;
				when others=>
					i2c_mode_state<=idle;
			end case;
		end if;
	end if;
end process;


end Behavioral;


