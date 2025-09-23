// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Sun Feb 16 18:31:37 2025
// Host        : SB-BJB-003 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               H:/YF/YF_DATA_SAMPLE_V2/YF_DATA_SAMPLE_V2.srcs/sources_1/ip/ila_FPGA_DNA/ila_FPGA_DNA_stub.v
// Design      : ila_FPGA_DNA
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a75tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2017.4" *)
module ila_FPGA_DNA(clk, probe0, probe1)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[56:0],probe1[0:0]" */;
  input clk;
  input [56:0]probe0;
  input [0:0]probe1;
endmodule
