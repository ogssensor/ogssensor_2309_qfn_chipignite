# Global
# ------

set script_dir [file dirname [file normalize [info script]]]
# Name
set ::env(DESIGN_NAME) uart_core



# Timing configuration
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "app_clk"


# Sources
# -------

# Local sources + no2usb sources
set ::env(VERILOG_FILES) "\
    $script_dir/../../verilog/rtl/uart/src/uart_core.sv  \
    $script_dir/../../verilog/rtl/uart/src/uart_cfg.sv   \
    $script_dir/../../verilog/rtl/uart/src/uart_rxfsm.sv \
    $script_dir/../../verilog/rtl/uart/src/uart_txfsm.sv \
    $script_dir/../../verilog/rtl/lib/async_fifo_th.sv   \
    $script_dir/../../verilog/rtl/lib/reset_sync.sv      \
    $script_dir/../../verilog/rtl/lib/double_sync_low.v  \
    $script_dir/../../verilog/rtl/lib/clk_ctl.v          \
    $script_dir/../../verilog/rtl/lib/registers.v        \
    "

#set ::env(VERILOG_INCLUDE_DIRS) [glob $script_dir/../../verilog/rtl/sdram_ctrl/src/defs ]

set ::env(SDC_FILE) "$script_dir/base.sdc"
set ::env(BASE_SDC_FILE) "$script_dir/base.sdc"

set ::env(LEC_ENABLE) 0

set ::env(VDD_PIN) [list {vccd1}]
set ::env(GND_PIN) [list {vssd1}]


# Floorplanning
# -------------

set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) [list 0.0 0.0 300.0 400.0]



# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 0

#set ::env(PDN_CFG) $script_dir/pdn.tcl


set ::env(PL_ROUTABILITY_DRIVEN) 1

set ::env(FP_IO_VEXTEND) 4
set ::env(FP_IO_HEXTEND) 4


set ::env(GLB_RT_MAXLAYER) 4
set ::env(GLB_RT_MAX_DIODE_INS_ITERS) 10

