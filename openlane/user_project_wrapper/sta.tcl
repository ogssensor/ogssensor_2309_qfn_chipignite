# SPDX-FileCopyrightText:  2021 , Dinesh Annayya
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>


set ::env(LIB_FASTEST) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
set ::env(LIB_TYPICAL) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set ::env(LIB_SLOWEST) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"
set ::env(DESIGN_NAME) "user_project_wrapper"
set ::env(BASE_SDC_FILE) "base.sdc"
set ::env(SYNTH_DRIVING_CELL) "sky130_fd_sc_hd__inv_8"
set ::env(SYNTH_DRIVING_CELL_PIN) "Y"
set ::env(SYNTH_CAP_LOAD) "17.65"
set ::env(WIRE_RC_LAYER) "met1"

#To disable empty filler cell black box get created
#set link_make_black_boxes 0


set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um
define_corners wc bc tt
read_liberty -corner bc $::env(LIB_FASTEST)
read_liberty -corner wc $::env(LIB_SLOWEST)
read_liberty -corner tt $::env(LIB_TYPICAL)

read_lib  -corner tt   ../../lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib

read_verilog netlist/qspim.v
read_verilog netlist/syntacore.v  
read_verilog netlist/uart_i2cm_usb.v  
read_verilog netlist/wb_host.v  
read_verilog netlist/wb_interconnect.v
read_verilog netlist/pinmux.v
read_verilog netlist/sar_adc.v
read_verilog netlist/user_project_wrapper.v  

link_design  $::env(DESIGN_NAME)


read_spef -path u_riscv_top  ../../spef/scr1_top_wb.spef
read_spef -path u_pinmux ../../spef/pinmux.spef
read_spef -path u_qspi_master ../../spef/qspim_top.spef
read_spef -path u_uart_i2c_usb_spi  ../../spef/uart_i2c_usb_spi_top.spef
read_spef -path u_wb_host    ../../spef/wb_host.spef
read_spef -path u_intercon   ../../spef/wb_interconnect.spef
read_spef ../..//spef/user_project_wrapper.spef  


read_sdc -echo $::env(BASE_SDC_FILE)

# check for missing constraints
#check_setup  -verbose > unconstraints.rpt

set_operating_conditions -analysis_type single
# Propgate the clock
set_propagated_clock [all_clocks]

report_tns
report_wns
#report_power 

echo "################ CORNER : WC (SLOW) TIMING Report ###################" > timing_ss_max.rpt
report_checks -unique -path_delay max -slack_max -0.0 -group_count 100 -corner wc >> timing_ss_max.rpt
report_checks -group_count 100 -path_delay max  -path_group $::env(WBM_CLOCK_NAME)  -corner wc  >> timing_ss_max.rpt
report_checks -group_count 100 -path_delay max  -path_group $::env(WBS_CLOCK_NAME)  -corner wc  >> timing_ss_max.rpt
report_checks -group_count 100 -path_delay max  -path_group $::env(BIST_CLOCK_NAME) -corner wc  >> timing_ss_max.rpt
report_checks -path_delay max   -corner wc >> timing_ff_max.rpt

echo "################ CORNER : BC (SLOW) TIMING Report ###################" > timing_ff_min.rpt
report_checks -unique -path_delay min -slack_min -0.0 -group_count 100 -corner bc >> timing_ff_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(WBM_CLOCK_NAME)  -corner bc  >> timing_ff_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(WBS_CLOCK_NAME)  -corner bc  >> timing_ff_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(BIST_CLOCK_NAME) -corner bc  >> timing_ff_min.rpt
report_checks -path_delay min  -corner bc >> timing_min.rpt

echo "################ CORNER : TT (MAX) TIMING Report ###################" > timing_tt_max.rpt
report_checks -unique -path_delay min -slack_min -0.0 -group_count 100 -corner tt >> timing_tt_max.rpt
report_checks -group_count 100  -path_delay max -path_group $::env(WBM_CLOCK_NAME)  -corner tt  >> timing_tt_max.rpt
report_checks -group_count 100  -path_delay max -path_group $::env(WBS_CLOCK_NAME)  -corner tt  >> timing_tt_max.rpt
report_checks -group_count 100  -path_delay max -path_group $::env(BIST_CLOCK_NAME) -corner tt  >> timing_tt_max.rpt
report_checks -path_delay min  -corner tt >> timing_min.rpt

echo "################ CORNER : TT (MIN) TIMING Report ###################" > timing_tt_min.rpt
report_checks -unique -path_delay min -slack_min -0.0 -group_count 100 -corner tt >> timing_tt_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(WBM_CLOCK_NAME)  -corner tt  >> timing_tt_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(WBS_CLOCK_NAME)  -corner tt  >> timing_tt_min.rpt
report_checks -group_count 100  -path_delay min -path_group $::env(BIST_CLOCK_NAME) -corner tt  >> timing_tt_min.rpt
report_checks -path_delay min  -corner tt >> timing_min.rpt




report_checks -path_delay min_max 

#exit
