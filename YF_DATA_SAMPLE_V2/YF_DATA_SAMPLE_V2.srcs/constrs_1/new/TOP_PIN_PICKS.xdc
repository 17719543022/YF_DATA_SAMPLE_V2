set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property IOSTANDARD LVCMOS33 [get_ports {fx2_faddr[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_faddr[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fx2_fdata[15]}]
set_property PACKAGE_PIN C17 [get_ports {fx2_faddr[0]}]
set_property PACKAGE_PIN D17 [get_ports {fx2_faddr[1]}]
set_property PACKAGE_PIN G21 [get_ports {fx2_fdata[0]}]
set_property PACKAGE_PIN E21 [get_ports {fx2_fdata[1]}]
set_property PACKAGE_PIN F20 [get_ports {fx2_fdata[2]}]
set_property PACKAGE_PIN F19 [get_ports {fx2_fdata[3]}]
set_property PACKAGE_PIN A20 [get_ports {fx2_fdata[4]}]
set_property PACKAGE_PIN B20 [get_ports {fx2_fdata[5]}]
set_property PACKAGE_PIN A21 [get_ports {fx2_fdata[6]}]
set_property PACKAGE_PIN B21 [get_ports {fx2_fdata[7]}]
set_property PACKAGE_PIN E16 [get_ports {fx2_fdata[8]}]
set_property PACKAGE_PIN C19 [get_ports {fx2_fdata[9]}]
set_property PACKAGE_PIN E17 [get_ports {fx2_fdata[10]}]
set_property PACKAGE_PIN C20 [get_ports {fx2_fdata[11]}]
set_property PACKAGE_PIN D19 [get_ports {fx2_fdata[12]}]
set_property PACKAGE_PIN F18 [get_ports {fx2_fdata[13]}]
set_property PACKAGE_PIN E19 [get_ports {fx2_fdata[14]}]
set_property PACKAGE_PIN E18 [get_ports {fx2_fdata[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN F16 [get_ports fx2_pkt_end]
set_property PACKAGE_PIN C18 [get_ports fx2_slcs]
set_property PACKAGE_PIN D15 [get_ports fx2_sloe]
set_property PACKAGE_PIN D22 [get_ports fx2_slrd]
set_property PACKAGE_PIN D21 [get_ports fx2_slwr]
set_property PACKAGE_PIN C22 [get_ports fx2_flagb]
set_property PACKAGE_PIN B22 [get_ports fx2_flagc]
set_property PACKAGE_PIN G22 [get_ports fx2_ifclk]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_flagb]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_flagc]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_ifclk]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_pkt_end]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_slcs]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_sloe]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_slrd]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_slwr]
set_property IOSTANDARD LVCMOS33 [get_ports rxd]
set_property IOSTANDARD LVCMOS33 [get_ports sys_led]
set_property IOSTANDARD LVCMOS33 [get_ports txd]
set_property IOSTANDARD LVCMOS33 [get_ports fx2_rst_n]
set_property PACKAGE_PIN Y18 [get_ports clk]
set_property PACKAGE_PIN AA5 [get_ports txd]
set_property PACKAGE_PIN AA4 [get_ports rxd]
set_property PACKAGE_PIN P16 [get_ports sys_led]
set_property PACKAGE_PIN C15 [get_ports fx2_rst_n]


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets fx2_ifclk_IBUF]


set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_miso[17]}]
set_property PACKAGE_PIN K6 [get_ports {spi_miso[17]}]
set_property PACKAGE_PIN M3 [get_ports {spi_miso[16]}]
set_property PACKAGE_PIN M5 [get_ports {spi_miso[15]}]
set_property PACKAGE_PIN M6 [get_ports {spi_miso[14]}]
set_property PACKAGE_PIN N5 [get_ports {spi_miso[13]}]
set_property PACKAGE_PIN P4 [get_ports {spi_miso[12]}]
set_property PACKAGE_PIN P6 [get_ports {spi_miso[10]}]
set_property PACKAGE_PIN P5 [get_ports {spi_miso[11]}]
set_property PACKAGE_PIN H4 [get_ports {spi_miso[9]}]
set_property PACKAGE_PIN H3 [get_ports {spi_miso[8]}]
set_property PACKAGE_PIN H5 [get_ports {spi_miso[7]}]
set_property PACKAGE_PIN J4 [get_ports {spi_miso[6]}]
set_property PACKAGE_PIN J5 [get_ports {spi_miso[5]}]
set_property PACKAGE_PIN K4 [get_ports {spi_miso[4]}]
set_property PACKAGE_PIN J6 [get_ports {spi_miso[3]}]
set_property PACKAGE_PIN L3 [get_ports {spi_miso[2]}]
set_property PACKAGE_PIN L4 [get_ports {spi_miso[1]}]
set_property PACKAGE_PIN L5 [get_ports {spi_miso[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports spi_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports sr_oe]
set_property IOSTANDARD LVCMOS33 [get_ports sr_rclk]
set_property IOSTANDARD LVCMOS33 [get_ports sr_ser]
set_property IOSTANDARD LVCMOS33 [get_ports sr_srclk]
set_property IOSTANDARD LVCMOS33 [get_ports sr_srclr]
set_property PACKAGE_PIN R1 [get_ports spi_clk]
set_property PACKAGE_PIN G3 [get_ports spi_cs]
set_property PACKAGE_PIN P2 [get_ports spi_mosi]
set_property PACKAGE_PIN T1 [get_ports sr_oe]
set_property PACKAGE_PIN R4 [get_ports sr_rclk]
set_property PACKAGE_PIN W1 [get_ports sr_ser]
set_property PACKAGE_PIN U1 [get_ports sr_srclk]
set_property PACKAGE_PIN U2 [get_ports sr_srclr]

set_property MARK_DEBUG true [get_nets ins_drv/clkin]









set_property PACKAGE_PIN V19 [get_ports at24lc64_scl]
set_property PACKAGE_PIN U17 [get_ports at24lc64_sda]
set_property IOSTANDARD LVCMOS33 [get_ports at24lc64_scl]
set_property IOSTANDARD LVCMOS33 [get_ports at24lc64_sda]

#级联管脚定义
set_property PACKAGE_PIN B2 [get_ports spi3cfg_clk]
set_property PACKAGE_PIN C2 [get_ports spi3cfg_cs]
set_property PACKAGE_PIN D2 [get_ports spi3cfg_data]
set_property PACKAGE_PIN K1 [get_ports spi2cfg_cs]
set_property PACKAGE_PIN L1 [get_ports spi2cfg_data]
set_property PACKAGE_PIN J1 [get_ports spi2cfg_clk]
set_property PACKAGE_PIN W2 [get_ports spi1cfg_clk]
set_property PACKAGE_PIN V2 [get_ports spi1cfg_cs]
set_property PACKAGE_PIN T5 [get_ports spi1cfg_data]
set_property PACKAGE_PIN E2 [get_ports spi3_clk]
set_property PACKAGE_PIN B1 [get_ports spi3_cs]
set_property PACKAGE_PIN M1 [get_ports spi2_clk]
set_property PACKAGE_PIN AB2 [get_ports spi2_cs]
set_property PACKAGE_PIN T6 [get_ports spi1_clk]
set_property PACKAGE_PIN AB8 [get_ports spi1_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi1_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi1_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi1cfg_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi1cfg_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi1cfg_data]
set_property IOSTANDARD LVCMOS33 [get_ports spi2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi2_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi2cfg_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi2cfg_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi2cfg_data]
set_property IOSTANDARD LVCMOS33 [get_ports spi3_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi3_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi3cfg_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi3cfg_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi3cfg_data]
set_property IOSTANDARD LVCMOS33 [get_ports {spi1_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi1_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi1_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi1_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi2_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi2_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi2_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi2_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi3_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi3_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi3_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi3_data[0]}]
set_property PACKAGE_PIN A1 [get_ports {spi3_data[0]}]
set_property PACKAGE_PIN E1 [get_ports {spi3_data[1]}]
set_property PACKAGE_PIN D1 [get_ports {spi3_data[2]}]
set_property PACKAGE_PIN G1 [get_ports {spi3_data[3]}]
set_property PACKAGE_PIN AB3 [get_ports {spi2_data[0]}]
set_property PACKAGE_PIN AA1 [get_ports {spi2_data[1]}]
set_property PACKAGE_PIN AB1 [get_ports {spi2_data[2]}]
set_property PACKAGE_PIN Y1 [get_ports {spi2_data[3]}]
set_property PACKAGE_PIN AA8 [get_ports {spi1_data[0]}]
set_property PACKAGE_PIN T4 [get_ports {spi1_data[1]}]
set_property PACKAGE_PIN AB7 [get_ports {spi1_data[2]}]
set_property PACKAGE_PIN AB6 [get_ports {spi1_data[3]}]





#电源管理管脚定义
set_property IOSTANDARD LVCMOS33 [get_ports led_r]
set_property IOSTANDARD LVCMOS33 [get_ports led_g]
set_property IOSTANDARD LVCMOS33 [get_ports led_b]
set_property IOSTANDARD LVCMOS33 [get_ports power_key0]
set_property IOSTANDARD LVCMOS33 [get_ports power_key1]
set_property IOSTANDARD LVCMOS33 [get_ports STAT1]
set_property IOSTANDARD LVCMOS33 [get_ports STAT2]

set_property IOSTANDARD LVCMOS33 [get_ports ads1110_sda]
set_property IOSTANDARD LVCMOS33 [get_ports ads1110_scl]


set_property PACKAGE_PIN L19 [get_ports led_r]
set_property PACKAGE_PIN L18 [get_ports led_g]
set_property PACKAGE_PIN K19 [get_ports led_b]

set_property PACKAGE_PIN K17 [get_ports power_key0]
set_property PACKAGE_PIN N22 [get_ports power_key1]

set_property PACKAGE_PIN E14 [get_ports STAT1]
set_property PACKAGE_PIN E13 [get_ports STAT2]


set_property PACKAGE_PIN F14 [get_ports ads1110_sda]
set_property PACKAGE_PIN F13 [get_ports ads1110_scl]



















create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 32768 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list ins_clk_gen/clkgen/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ins_drv/ins_ad_drv/s1[0]} {ins_drv/ins_ad_drv/s1[1]} {ins_drv/ins_ad_drv/s1[2]} {ins_drv/ins_ad_drv/s1[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 18 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {ins_drv/ins_ad_drv/spi_miso[0]} {ins_drv/ins_ad_drv/spi_miso[1]} {ins_drv/ins_ad_drv/spi_miso[2]} {ins_drv/ins_ad_drv/spi_miso[3]} {ins_drv/ins_ad_drv/spi_miso[4]} {ins_drv/ins_ad_drv/spi_miso[5]} {ins_drv/ins_ad_drv/spi_miso[6]} {ins_drv/ins_ad_drv/spi_miso[7]} {ins_drv/ins_ad_drv/spi_miso[8]} {ins_drv/ins_ad_drv/spi_miso[9]} {ins_drv/ins_ad_drv/spi_miso[10]} {ins_drv/ins_ad_drv/spi_miso[11]} {ins_drv/ins_ad_drv/spi_miso[12]} {ins_drv/ins_ad_drv/spi_miso[13]} {ins_drv/ins_ad_drv/spi_miso[14]} {ins_drv/ins_ad_drv/spi_miso[15]} {ins_drv/ins_ad_drv/spi_miso[16]} {ins_drv/ins_ad_drv/spi_miso[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list ins_usb_pro_deal/ad_data_buf_vld]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list ins_drv/ins_ad_drv/spi_clk]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list ins_drv/ins_ad_drv/spi_cs_i]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list ins_drv/ins_ad_drv/spi_mosi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list ins_drv/ins_ad_drv/spi_rd_vld]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list ins_drv/ins_ad_drv/m0_num_change]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list ins_drv/ins_ad_drv/sample_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 4 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {ins_drv/ins_ad_drv/rx_num[0]} {ins_drv/ins_ad_drv/rx_num[1]} {ins_drv/ins_ad_drv/rx_num[2]} {ins_drv/ins_ad_drv/rx_num[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list ins_drv/ins_ad_drv/s_axis_tready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list ins_drv/ins_ad_drv/s_axis_tvalid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list ins_usb_pro_deal/usb_rx_buf_vld]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 8 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {ins_usb_pro_deal/usb_rx_buf_type[0]} {ins_usb_pro_deal/usb_rx_buf_type[1]} {ins_usb_pro_deal/usb_rx_buf_type[2]} {ins_usb_pro_deal/usb_rx_buf_type[3]} {ins_usb_pro_deal/usb_rx_buf_type[4]} {ins_usb_pro_deal/usb_rx_buf_type[5]} {ins_usb_pro_deal/usb_rx_buf_type[6]} {ins_usb_pro_deal/usb_rx_buf_type[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 8 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {ins_usb_pro_deal/work_mod_i[0]} {ins_usb_pro_deal/work_mod_i[1]} {ins_usb_pro_deal/work_mod_i[2]} {ins_usb_pro_deal/work_mod_i[3]} {ins_usb_pro_deal/work_mod_i[4]} {ins_usb_pro_deal/work_mod_i[5]} {ins_usb_pro_deal/work_mod_i[6]} {ins_usb_pro_deal/work_mod_i[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 32 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {ins_usb_pro_deal/cnt_cycle[0]} {ins_usb_pro_deal/cnt_cycle[1]} {ins_usb_pro_deal/cnt_cycle[2]} {ins_usb_pro_deal/cnt_cycle[3]} {ins_usb_pro_deal/cnt_cycle[4]} {ins_usb_pro_deal/cnt_cycle[5]} {ins_usb_pro_deal/cnt_cycle[6]} {ins_usb_pro_deal/cnt_cycle[7]} {ins_usb_pro_deal/cnt_cycle[8]} {ins_usb_pro_deal/cnt_cycle[9]} {ins_usb_pro_deal/cnt_cycle[10]} {ins_usb_pro_deal/cnt_cycle[11]} {ins_usb_pro_deal/cnt_cycle[12]} {ins_usb_pro_deal/cnt_cycle[13]} {ins_usb_pro_deal/cnt_cycle[14]} {ins_usb_pro_deal/cnt_cycle[15]} {ins_usb_pro_deal/cnt_cycle[16]} {ins_usb_pro_deal/cnt_cycle[17]} {ins_usb_pro_deal/cnt_cycle[18]} {ins_usb_pro_deal/cnt_cycle[19]} {ins_usb_pro_deal/cnt_cycle[20]} {ins_usb_pro_deal/cnt_cycle[21]} {ins_usb_pro_deal/cnt_cycle[22]} {ins_usb_pro_deal/cnt_cycle[23]} {ins_usb_pro_deal/cnt_cycle[24]} {ins_usb_pro_deal/cnt_cycle[25]} {ins_usb_pro_deal/cnt_cycle[26]} {ins_usb_pro_deal/cnt_cycle[27]} {ins_usb_pro_deal/cnt_cycle[28]} {ins_usb_pro_deal/cnt_cycle[29]} {ins_usb_pro_deal/cnt_cycle[30]} {ins_usb_pro_deal/cnt_cycle[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list ins_usb_pro_deal/lock_data_en_pos]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list ins_usb_pro_deal/lock_data_en]]



set_property PACKAGE_PIN G2 [get_ports audi_in]
set_property IOSTANDARD LVCMOS33 [get_ports audi_in]

create_clock -period 20.833 -name usb_clk -waveform {0.000 10.417} [get_ports fx2_ifclk]
set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks usb_clk]
set_input_delay -clock [get_clocks usb_clk] 2.000 [get_ports {fx2_flagb fx2_flagc fx2_ifclk}]
set_input_delay -clock [get_clocks usb_clk] 2.000 [get_ports {{fx2_fdata[0]} {fx2_fdata[1]} {fx2_fdata[2]} {fx2_fdata[3]} {fx2_fdata[4]} {fx2_fdata[5]} {fx2_fdata[6]} {fx2_fdata[7]} {fx2_fdata[8]} {fx2_fdata[9]} {fx2_fdata[10]} {fx2_fdata[11]} {fx2_fdata[12]} {fx2_fdata[13]} {fx2_fdata[14]} {fx2_fdata[15]}}]



set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clkin]
