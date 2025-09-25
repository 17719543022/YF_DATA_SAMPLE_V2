----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/02/14 09:05:08
-- Design Name: 
-- Module Name: SPI_MASTER_V1 - Behavioral
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
-- spi_mode=cpol&cpha
-- 00->时钟初始为0，下降沿发送数据，上升沿采集
-- 01->时钟初始为0，上升沿发送数据，下降沿采集
-- 10->时钟初始为1，上升沿发送数据，下降沿采集
-- 11->时钟初始为1，下降沿发送数据，上升沿采集
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_MASTER_V1 is
generic(
	spi_div			:integer:=8;	---最小分频比为2
	cpol			:std_logic:='0';
	cpha			:std_logic:='0';
	tecs			:integer:=1;	--------CS下降沿后距离第一个有效时钟的时间（时间=（tecs+2）*time_step）估计值
	tce				:integer:=2;	--------最后一个SPI CLK下降沿后距离CSbuf上升沿的时间（时间=（tce-1）*clkin）
	tewh			:integer:=5;	--------两次CS启动的最小时间间隔（时间=（tewh+3）*clkin）
-----------------------------------
	tx_data_width	:integer:=24;
	rx_data_width	:integer:=16;
	rx_addr_width	:integer:=8;
--------------------------------
    sdi_num         :integer:=18;
--------------------------------
	data_seq		:std_logic:='0'			------- 0=>MSB->LSB 1=>LSB->MSB
);
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
---------------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata	:in std_logic_vector(tx_data_width-1 downto 0);	--地址总是放在高位
	s_axis_tuser	:in std_logic;					---表示读写信号的表示	(1=》写 ，0=》读)
	s_axis_trst	    :in std_logic;					---专门用于产生AD的复位逻辑    
	s_axis_tnum		:in std_logic_vector(15 downto 0);	--接收与发送总bit数（一次SPI工作过程中总时钟数）
----------------------------------------
	spi_rd_data		:out std_logic_vector(sdi_num*(rx_data_width+rx_addr_width)-1 downto 0);	
	spi_rd_vld		:out std_logic;	
----------------------------------------
	sdo				:out std_logic;
	cs				:out std_logic;
	sck				:out std_logic;
	sdi				:in std_logic_vector(sdi_num-1 downto 0)
 );
end SPI_MASTER_V1;

architecture Behavioral of SPI_MASTER_V1 is

constant spi_div_half:integer:=spi_div/2;
------------------------------------------------
signal cnt_rx		:integer:=0;
signal cnt_tx		:integer:=0;
signal cnt_spi_clk	:integer:=0;
signal s1			:integer range 0 to 7:=0;

signal cpol_p			:std_logic:=cpol;
signal sclk				:std_logic:=cpol;
signal tx_en_c			:std_logic:='0';
signal tx_en			:std_logic:='0';
signal rx_en			:std_logic:='0';
signal s_axis_tready_buf:std_logic:='0';
signal rw_flag			:std_logic:='0';
signal cs_buf			:std_logic:='0';
signal sdo_buf			:std_logic:='0';
signal spi_woking_i		:std_logic:='0';
signal addr_tx_over		:std_logic:='0';
signal tx_data_over		:std_logic:='0';
signal edge_en			:std_logic:='0';
signal rx_data_temp_vld	:std_logic_vector(sdi_num-1 downto 0);
type t1 is array(0 to sdi_num-1) of std_logic_vector(tx_data_width-1 downto 0);

signal rx_data_temp		:t1;
signal tx_data			:std_logic_vector(tx_data_width-1 downto 0):=(others=>'0');
signal read_addr		:std_logic_vector(rx_addr_width-1 downto 0):=(others=>'0');
signal tx_data_num		:std_logic_vector(16-1 downto 0):=(others=>'0');


begin

process(clkin,rst_n)
begin
	if rst_n='0' then
		cnt_spi_clk	<=spi_div-1;
		sclk		<=cpol;
		tx_en		<='0';
		rx_en		<='0';
		tx_en_c		<='0';
	else
		if rising_edge(clkin) then
			if spi_woking_i='1' then
				if cnt_spi_clk>=spi_div-1 then
					cnt_spi_clk<=0;
				else
					cnt_spi_clk<=cnt_spi_clk+1;
				end if;
				
				if cnt_spi_clk=0 then
					sclk<=cpol xor cpol_p;
				elsif cnt_spi_clk=spi_div_half then
					if edge_en='1' then
						sclk<=not (cpol xor cpol_p);
					else
						edge_en<='1';
					end if;
				else
					sclk<=sclk;
				end if;
				
				if cnt_spi_clk=spi_div-1 then	--	
					tx_en<='1';
				else
					tx_en<='0';
				end if;
				
				if cnt_spi_clk=spi_div-2 then	--	
					tx_en_c<='1';
				else
					tx_en_c<='0';
				end if;
				
				if cnt_spi_clk=spi_div_half then
					rx_en<='1';
				else
					rx_en<='0';
				end if;

			else
				sclk		<=cpol;
				tx_en		<='0';
				rx_en		<='0';
				if cpol='0' and cpha='0' then
					cnt_spi_clk	<=spi_div-1;	
				elsif cpol='0' and cpha='1' then
					cnt_spi_clk	<=spi_div_half-1;
				elsif cpol='1' and cpha='0' then
					cnt_spi_clk	<=spi_div-1;
				elsif cpol='1' and cpha='1' then
					cnt_spi_clk	<=spi_div_half-1;
				end if;
				
				if spi_div<=3 then
					edge_en<='0';
				else
					edge_en<='1';
				end if;
			end if;
		end if;
	end if;
end process;



cpol_p<='0' when  (cpol='0' and cpha='0') or (cpol='1' and cpha='0') else '1';	--判断sck的时钟沿
-------------------------------------------------------------------------------------------

sdo	 			<=sdo_buf;	
cs	 			<=cs_buf;	
sck	 			<=sclk	;
s_axis_tready	<=s_axis_tready_buf;

process(clkin,rst_n)
begin
	if rst_n='0' then
		s1<=0;
		cs_buf		<='1';
		spi_woking_i<='0';
		cnt_tx		<=0;
		s_axis_tready_buf<='0';
		rx_data_temp_vld<=(others=>'0');
	else
		if rising_edge(clkin) then
			case s1 is
				when 0=>
                    if s_axis_tready_buf='1' and s_axis_tvalid='1' and s_axis_trst='1' then      --复位操作
                        s_axis_tready_buf<='0';
                        s1<=6;
					elsif s_axis_tready_buf='1' and s_axis_tvalid='1' then
						tx_data		<=s_axis_tdata;
						rw_flag		<=s_axis_tuser;
						read_addr	<=s_axis_tdata(tx_data_width-1 downto tx_data_width-rx_addr_width);
						s_axis_tready_buf<='0';
						tx_data_num<=s_axis_tnum;
						s1			<=1;
					else
						s_axis_tready_buf<='1';
					end if;
					cs_buf		<='1';
					spi_woking_i<='0';
					cnt_tx		<=0;
					addr_tx_over<='0';
					rx_data_temp_vld<=(others=>'0');
					-- tx_data_over<='0';
					cnt_rx			<=0;
				when 1=>
					cs_buf<='0';
					if cnt_tx>=tecs-1 then
						cnt_tx<=0;
						spi_woking_i<='1';
						s1<=2;
					else
						cnt_tx<=cnt_tx+1;
					end if;
				
				
				when 2=>
					-- if rw_flag='1' then   ---写数据
					if tx_en='1' then
						if rw_flag='1' then   ---写数据
							if data_seq='0' then
								sdo_buf<=tx_data(tx_data_width-1-cnt_tx);
							else
								sdo_buf<=tx_data(cnt_tx);
							end if;
						else
							if cnt_tx<=rx_addr_width-1 then
								if data_seq='0' then
									sdo_buf<=tx_data(tx_data_width-1-cnt_tx);
								else
									sdo_buf<=tx_data(cnt_tx);
								end if;
							else
								sdo_buf<=sdo_buf;
							end if;
						end if;
								
						if cnt_tx>=tx_data_num-1 then
							cnt_tx<=0;
							s1<=3;
						else
							cnt_tx<=cnt_tx+1;
						end if;
					else
						cnt_tx<=cnt_tx;
					end if;


--------------------------------------------------------------------
					if tx_en='1' and cnt_tx>=rx_addr_width then
						addr_tx_over<='1';
					end if;
                    for i in 0 to sdi_num-1  loop
                        if rw_flag='0' and cnt_tx>=rx_addr_width and rx_en='1' and addr_tx_over='1'then
                            rx_data_temp(i)(tx_data_width-1 downto tx_data_width-rx_addr_width)<=read_addr;
                            if data_seq='0' then
                                rx_data_temp(i)(rx_data_width-1 -cnt_rx)<=sdi(i);
                            else
                                rx_data_temp(i)(cnt_rx)<=sdi(i);
                            end if;
                           -- cnt_rx<=cnt_rx+1;
                        else
                            rx_data_temp_vld(i)<='0';
                        end if;
                    end loop;
                    
                    if rw_flag='0' and cnt_tx>=rx_addr_width and rx_en='1' and addr_tx_over='1'then
                        cnt_rx<=cnt_rx+1;
                    end if;
					
				when 3=>
                    for i in 0 to sdi_num-1  loop
                        if spi_div>=3 then
                            if rw_flag='0' and rx_en='1' and addr_tx_over='1'then
                                rx_data_temp(i)(tx_data_width-1 downto tx_data_width-rx_addr_width)<=read_addr;
                                if data_seq='0' then
                                    rx_data_temp(i)(rx_data_width-1 -cnt_rx)<=sdi(i);
                                else
                                    rx_data_temp(i)(cnt_rx)<=sdi(i);
                                end if;
                                --cnt_rx			<=cnt_rx+1;
                                rx_data_temp_vld(i)<='1';
                            else
                                rx_data_temp_vld(i)<='0';
                            end if;	
                        else
                            rx_data_temp_vld(i)<='0';
                        end if;
                    end loop;
                    
                    if spi_div>=3 and rw_flag='0' and rx_en='1' and addr_tx_over='1' then
                         cnt_rx<=cnt_rx+1;
                    end if;
                    
                    
					if tx_en_c='1' then
						if cpol='1' and cpha='0' then
							cs_buf<='1';
						else
							cs_buf<='0';
						end if;
						spi_woking_i<='0';
						s1<=4;
					else
						s1<=s1;
					end if;


				
				when 4=>
                    for i in 0 to sdi_num-1  loop
                        if spi_div<=2 then
                            if rw_flag='0' and rx_en='1' and addr_tx_over='1'then
                                rx_data_temp(i)(tx_data_width-1 downto tx_data_width-rx_addr_width)<=read_addr;
                                if data_seq='0' then
                                    rx_data_temp(i)(rx_data_width-1 -cnt_rx)<=sdi(i);
                                else
                                    rx_data_temp(i)(cnt_rx)<=sdi(i);
                                end if;
                                --cnt_rx			<=cnt_rx+1;
                                rx_data_temp_vld(i)<='1';
                            else
                                rx_data_temp_vld(i)<='0';
                            end if;	
                        else
                            rx_data_temp_vld(i)<='0';
                        end if;
					end loop;
                    
                    
                    if spi_div<=2 and rw_flag='0' and rx_en='1' and addr_tx_over='1' then
                         cnt_rx<=cnt_rx+1;
                    end if;
                    
                    
                    
                    
					if cnt_tx>=tce-1 then
						cnt_tx<=0;
						cs_buf<='1';
						s1<=5;
					else
						cnt_tx<=cnt_tx+1;
					end if;
				
				
				when 5=>
					rx_data_temp_vld<=(others=>'0');
					if cnt_tx>=tewh-1 then
						cnt_tx<=0;
						s1<=0;
					else
						cnt_tx<=cnt_tx+1;
					end if;
				
------------------------针对AD7177的复位操作--------------------------------------------                
                when 6=>
					cs_buf<='0';
					if cnt_tx>=tecs-1 then
						cnt_tx<=0;
						spi_woking_i<='1';
						s1<=7;
					else
						cnt_tx<=cnt_tx+1;
					end if;
                    
                when 7=>
                    cs_buf<='0';
                    sdo_buf<='1';
                    if tx_en='1' then
                        cnt_tx<=cnt_tx+1;
                    end if;
                    
                    if cnt_tx>=66 then
                        s1<=0;
                    end if;
					
				
				when others=>
					s1<=0;
			end case;
		end if;
	end if;
end process;						



process(clkin,rst_n)
begin
	if rst_n='0' then
		spi_rd_vld<='0';
		spi_rd_data<=(others=>'0');
	else
		if rising_edge(clkin) then
			if rx_data_temp_vld(0)='1' then
                for i in 0 to sdi_num-1 loop
                    spi_rd_data((i+1)*(rx_data_width+rx_addr_width)-1 downto (i+0)*(rx_data_width+rx_addr_width))<=rx_data_temp(i);
                end loop;
				spi_rd_vld<='1';
			else
				spi_rd_vld<='0';
			end if;
		end if;
	end if;
end process;



















end Behavioral;
