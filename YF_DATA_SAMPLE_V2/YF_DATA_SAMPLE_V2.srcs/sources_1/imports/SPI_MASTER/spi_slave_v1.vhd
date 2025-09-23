----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/11/15 09:19:35
-- Design Name: 
-- Module Name: spi_slave_v1 - Behavioral
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
use ieee.std_Logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave_v1 is
 Port (
	clkin			:in std_logic;
	rst_n			:in std_logic;
----------------------------
	spi_cs			:in std_logic;
	spi_clk			:in std_logic;
	spi_sdo 		:inout std_logic;
	spi_sdi			:in std_logic;
-----------------------------
	rx_addr			:out std_logic_vector(7 downto 0);
	rx_data			:out std_logic_vector(31 downto 0);
	rx_vld			:out std_logic;
-------------------------------	
	spi_rd_reg_data :in std_logic_vector(31 downto 0);
	spi_rd_reg_addr :out std_logic_vector(7 downto 0);
	spi_rd_reg_vld 	:out std_logic
 );
end spi_slave_v1;

architecture Behavioral of spi_slave_v1 is


signal spi_cs_d0:std_logic;
signal spi_clk_d0:std_logic;
signal spi_sdi_d0:std_logic;

signal spi_cs_d1:std_logic;
signal spi_clk_d1:std_logic;
signal spi_sdi_d1:std_logic;

signal spi_cs_d2:std_logic;
signal spi_clk_d2:std_logic;
signal spi_sdi_d2:std_logic;

signal spi_cs_neg:std_logic;
signal spi_clk_pos:std_logic;
signal spi_clk_neg:std_logic;
signal spi_rx_vld:std_logic;
signal spi_sdo_oen:std_logic;
signal spi_sdo_obuf:std_logic;
signal rst_st		:std_logic;
signal err_flag		:std_logic;
signal spi_rx_data:std_logic_vector(38 downto 0);


signal s1 	:integer range 0 to 7;


-- attribute mark_debug:string;
-- attribute mark_debug of spi_cs_neg					:signal is "true";
-- attribute mark_debug of spi_clk_pos					:signal is "true";
-- attribute mark_debug of spi_clk_neg					:signal is "true";
-- attribute mark_debug of spi_sdi_d1 					:signal is "true";
-- attribute mark_debug of s1 							:signal is "true";
-- attribute mark_debug of err_flag 					:signal is "true";








begin

spi_sdo<=spi_sdo_obuf when spi_sdo_oen='1' else 'Z';	--三态门

process(clkin,rst_n)
begin
	if rst_n='0' then
		spi_cs_d0<='0';
		spi_cs_d1<='0';
		spi_cs_d2<='0';
		spi_clk_d0<='0';
		spi_clk_d1<='0';
		spi_clk_d2<='0';
		spi_sdi_d0<='0';
		spi_sdi_d1<='0';
		spi_sdi_d2<='0';
	elsif rising_edge(clkin) then
		spi_cs_d0	<=spi_cs;
		spi_cs_d1	<=spi_cs_d0;
		spi_clk_d0	<=spi_clk;
		spi_clk_d1	<=spi_clk_d0;
		spi_sdi_d0	<=spi_sdi;
		spi_sdi_d1	<=spi_sdi_d0;
		spi_cs_d2	<=spi_cs_d1;
		spi_clk_d2	<=spi_clk_d1;
		spi_sdi_d2	<=spi_sdi_d1;		
	end if;
end process;

spi_cs_neg <=not spi_cs_d1 and spi_cs_d2  ;
spi_clk_pos<=spi_clk_d1 and not spi_clk_d2;
spi_clk_neg<=(not spi_clk_d1) and (spi_clk_d2);

-----------------------------------------------------------

process(clkin,rst_n)
variable cnt0:integer range 0 to 7;
begin
	if rst_n='0' then
		rst_st<='0';
		cnt0:=0;
	else
		if rising_edge(clkin) then
			if spi_cs_d1='1' then
				if cnt0>=5 then
					cnt0:=cnt0;
				else
					cnt0:=cnt0+1;
				end if;
				if cnt0=4 then
					rst_st<='1';
				else
					rst_st<='0';
				end if;
				
			else
				rst_st<='0';
				cnt0:=0;
			end if;
		end if;
	end if;
end process;




-- process(clkin)
-- begin
	-- if rising_edge(clkin) then
		-- if spi_cs_neg='1' and s1/=0 then
			-- err_flag<='1';
		-- else
			-- err_flag<='0';
		-- end if;
	-- end if;
-- end process;




process(clkin,rst_n)
variable cnt1:integer range 0  to 63;
begin
	if rst_n='0' then
		spi_rx_vld<='0';
		spi_sdo_oen<='0';
		spi_rd_reg_vld<='0';
		s1<=0;
	else
		if rising_edge(clkin) then
			if rst_st='1' then
				spi_rx_vld<='0';
				spi_sdo_oen<='0';
				cnt1:=0;
				s1<=0;
			else
				case s1 is
					when 0=>
						if spi_cs_neg='1' then
							s1<=1;
						else
							s1<=0;
						end if;
						spi_rx_vld<='0';
						spi_sdo_oen<='0';
						cnt1:=0;
					
					when 1=>
						if spi_clk_pos='1' then
							if spi_sdi_d2='0' then	--写
								s1<=2;
							else
								s1<=3;
							end if;
						else
							s1<=s1;
						end if;
					
					when 2=>
						if spi_clk_pos='1' then
							spi_rx_data(38-cnt1)<=spi_sdi_d2;
							if cnt1>=38 then
								cnt1:=0;
								s1<=0;
								spi_rx_vld<='1';
							else
								cnt1:=cnt1+1;
							end if;
						else
							s1<=s1;
						end if;
					
					when 3=>
						if spi_clk_pos='1' then
							spi_rx_data(6-cnt1)<=spi_sdi_d2;
							if cnt1>=6 then
								s1<=4;
								cnt1:=0;
								spi_rd_reg_vld<='1';
								spi_rd_reg_addr<='0'&spi_rx_data(6 downto 1)&spi_sdi_d2;
							else
								cnt1:=cnt1+1;
							end if;					
						end if;	
					
					when 4=>		--等待数据有效（2个时钟后给出）
						spi_rd_reg_vld<='0';
						if cnt1=1 then
							spi_sdo_obuf<=spi_rd_reg_data(31);
							s1<=5;
							spi_sdo_oen<='1';
						else
							s1<=s1;
						end if;
						cnt1:=1;
						
					
					when 5=>
						spi_rd_reg_vld<='0';
						if spi_clk_pos='1' then 
							spi_sdo_obuf<=spi_rd_reg_data(31-cnt1);
							spi_sdo_oen<='1';
							if cnt1>=31 then
								s1<=6;
								cnt1:=0;
							else
								cnt1:=cnt1+1;
							end if;	
						else
							s1<=s1;
						end if;
					
					when 6=>
						if spi_cs='1' then
							s1<=0;
						else
							s1<=s1;
						end if;
						
					
					when others=>
						s1<=0;
				end case;
			end if;
		end if;
	end if;
end process;



-----------------------------------------
process(clkin,rst_n)
begin
	if rst_n='0' then
		rx_vld<='0';
	else
		if rising_edge(clkin) then
			if spi_rx_vld='1' then	
				rx_addr<='0'&spi_rx_data(38 downto 32);
				rx_data<=spi_rx_data(31 downto 0);
				rx_vld<='1';
			else
				rx_vld<='0';
			end if;
		end if;
	end if;
end process;


























end Behavioral;
