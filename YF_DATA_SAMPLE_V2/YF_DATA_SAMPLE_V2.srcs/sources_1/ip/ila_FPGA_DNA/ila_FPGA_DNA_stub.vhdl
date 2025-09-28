-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
-- Date        : Sun Feb 16 18:31:37 2025
-- Host        : SB-BJB-003 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               H:/YF/YF_DATA_SAMPLE_V2/YF_DATA_SAMPLE_V2.srcs/sources_1/ip/ila_FPGA_DNA/ila_FPGA_DNA_stub.vhdl
-- Design      : ila_FPGA_DNA
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a75tfgg484-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_FPGA_DNA is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 56 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 0 to 0 )
  );

end ila_FPGA_DNA;

architecture stub of ila_FPGA_DNA is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[56:0],probe1[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "ila,Vivado 2017.4";
begin
end;
