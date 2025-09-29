----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/02/08 13:54:58
-- Design Name: 
-- Module Name: DNA_READ_TOP - Behavioral
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

Library UNISIM;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DNA_READ_TOP is
generic(
    dna_len:integer:=57
);
 Port (
    clkin      :in std_logic;
    rst_n      :in std_logic;
    start_rd_en:in std_logic;
-------------------------------
    device_id  :out std_logic_vector(dna_len-1 downto 0);
    fpga_check :out std_logic
 );
end DNA_READ_TOP;

architecture Behavioral of DNA_READ_TOP is

signal cnt:integer range 0 to 255;
signal s1:integer range 0 to 7;

signal fpga_check_i:std_logic;
signal device_id_i:std_logic_vector(dna_len-1 downto 0);
signal DOUT:std_logic;
signal SHIFT:std_logic;
signal rd_en:std_logic;
signal SHIFT_d1:std_logic;
signal SHIFT_neg:std_logic;
signal shift_reg:std_logic_vector(dna_len-1 downto 0);



constant fpga_id0:std_logic_vector(59 downto 0):=X"058D50279E9685C";
constant fpga_id1:std_logic_vector(59 downto 0):=X"058D50279E96854";
constant fpga_id2:std_logic_vector(59 downto 0):=X"058D50279E96854";


begin

   DNA_PORT_inst : DNA_PORT
   generic map (
    --  SIM_DNA_VALUE => X"0000_0000_0000_000"  -- Specifies a sample 57-bit DNA value for simulation
      SIM_DNA_VALUE => X"ef22_3344_5566_7ff"  -- Specifies a sample 57-bit DNA value for simulation
   )
   port map (
      DOUT => DOUT,   -- 1-bit output: DNA output data.
      CLK => clkin,     -- 1-bit input: Clock input.
      DIN => '0',     -- 1-bit input: User data input pin.
      READ => rd_en,   -- 1-bit input: Active high load DNA, active low read input.
      SHIFT => SHIFT  -- 1-bit input: Active high shift enable input.
   );

process(clkin,rst_n)
begin
    if rst_n='0' then
        SHIFT<='0';
        rd_en<='0';
        s1<=0;
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    SHIFT<='0';
                    rd_en<='1';
                    if cnt>=dna_len-1 then
                        s1<=1;
                        cnt<=0;
                    else
                        s1<=s1;
                        cnt<=cnt+1;
                    end if;
                
                when 1=>
                    SHIFT<='0';
                    rd_en<='0';
                    if cnt>=10 then
                        s1<=2;
                        cnt<=0;
                    else
                        cnt<=cnt+1;
                    end if;
                
                
                when 2=>
                    SHIFT<='1';
                    if cnt>=dna_len-1 then
                        s1<=3;
                        cnt<=0;
                    else
                        s1<=s1;
                        cnt<=cnt+1;
                    end if;
                
                when 3=>
                    SHIFT<='0';
                    rd_en<='0';
                    if start_rd_en='1' then
                        s1<=0;
                    end if;
                    cnt<=0;   
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;

process(clkin,rst_n) 
begin
    if rst_n='0' then
        device_id_i<=(others=>'0');
        shift_reg<=(others=>'0');
        SHIFT_d1<='0';
    else
        if rising_edge(clkin) then
            SHIFT_d1<=SHIFT;
            if SHIFT='1' then
                shift_reg<=shift_reg(dna_len-2 downto 0)&DOUT;
            end if;
            
            if SHIFT_neg='1' then
                device_id_i<=shift_reg;
            end if;
        end if;
    end if;
end process;
                

SHIFT_neg<=not SHIFT and SHIFT_d1;


process(clkin,rst_n)
begin
    if rst_n='0' then
        fpga_check_i<='0';
    else
        if rising_edge(clkin) then
            if device_id_i=fpga_id0(56 downto 0) or device_id_i=fpga_id1(56 downto 0) then
                fpga_check_i<='1';
            else
                fpga_check_i<='0';
            end if;
        end if;
    end if;
end process;

device_id<=device_id_i;
fpga_check<=fpga_check_i;




end Behavioral;
