----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/09/25 15:24:08
-- Design Name: 
-- Module Name: jl_cfg_top - Behavioral
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
use work.my_package.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity jl_cfg_top is   ---配置同步作用
 Port (
    clkin               :in std_logic;
    rst_n               :in std_logic;
------------------------
    work_mod            :in std_logic_vector(7 downto 0);
------------------------    
    spi_clk             :inout std_logic;
    spi_cs              :inout std_logic;
    spi_data            :inout std_logic;
--------------------------------------------
    cfg_data_in         :in cfg_data_t;
    cfg_data_in_vld     :in std_logic;

    cfg_data_o          :out cfg_data_t;
    cfg_data_o_vld      :out std_logic
 );
end jl_cfg_top;

architecture Behavioral of jl_cfg_top is

component spi_master_sample is
generic(
	DW_DIN:INTEGER:=8;
	SPI_DIV:INTEGER:=4;			---最小分频比为2
	T_WAITE:INTEGER:=10;
	DEV_NUM:INTEGER:=1
);
port(
	clkin			:in std_logic;
	rst_n			:in std_logic;
------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata 	:in std_logic_vector(DEV_NUM*DW_DIN-1 downto 0);
------------------------------
	spi_cs			:out std_logic;
	spi_clk			:out std_logic;
	spi_sdo			:out std_logic_vector(DEV_NUM-1 downto 0)	
);
end component;

begin

-----------------------发送配置------------------------

ins_spi_tx:spi_master_sample port map(

    clkin			    =>  clkin			    ,
    rst_n			    =>  rst_n			    ,
    ----------------    =>  ----------------    ,
    s_axis_tvalid	    =>  s_axis_tvalid	    ,
    s_axis_tready	    =>  s_axis_tready	    ,
    s_axis_tdata 	    =>  s_axis_tdata 	    ,
    ----------------    =>  ----------------    ,
    spi_cs			    =>  spi_cs			    ,
    spi_clk			    =>  spi_clk			    ,
    spi_sdo(0)			=>  spi_sdo			
);

process(clkin,rst_n)
begin
    if rst_n='0' then
        s1<=0;
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    if cfg_data_in_vld='1' or tx_en='1' then
                        s1<=1;
                    else
                        s1<=s1;
                    end if;
                
                
                when 1=>
                    s_axis_tdata<=X"55";
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        s1<=2;
                    else
                        s_axis_tvalid<='1';
                    end if;
                
                
                when 2=>
                    s_axis_tdata<=X"AA";
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        s1<=3;
                    else
                        s_axis_tvalid<='1';
                    end if;                    
                        
                when 3=>
                    s_axis_tdata<=cfg_data_in(cnt_tx);
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        cnt_tx<=cnt_tx+1;
                    else
                        s_axis_tvalid<='1';
                    end if; 
                    
                    if s_axis_tvalid='1' and s_axis_tready='1' and cnt_tx>=35 then
                        s1<=4;
                    end if;
                
                
                when 4=>    
                    s_axis_tdata<=X"A3";
                    if s_axis_tvalid='1' and s_axis_tready='1' then
                        s_axis_tvalid<='0';
                        s1<=0;
                    else
                        s_axis_tvalid<='1';
                    end if;

                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;

-----------------------------------------------------------------------------------------------------------
















end Behavioral;
