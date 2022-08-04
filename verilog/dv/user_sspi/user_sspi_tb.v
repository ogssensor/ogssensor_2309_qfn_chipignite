////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText:  2021 , Dinesh Annayya
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Standalone User validation Test bench                       ////
////                                                              ////
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   sspi interfaface through External WB i/F.                  ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 01 Oct 2021, Dinesh A                               ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`default_nettype wire

`timescale 1 ns/1 ps

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "is62wvs1288.v"

`define TB_GLBL    user_sspi_tb




module user_sspi_tb;
	reg clock;
	reg wb_rst_i;
	reg power1, power2;
	reg power3, power4;

        reg        wbd_ext_cyc_i;  // strobe/request
        reg        wbd_ext_stb_i;  // strobe/request
        reg [31:0] wbd_ext_adr_i;  // address
        reg        wbd_ext_we_i;  // write
        reg [31:0] wbd_ext_dat_i;  // data output
        reg [3:0]  wbd_ext_sel_i;  // byte enable

        wire [31:0] wbd_ext_dat_o;  // data input
        wire        wbd_ext_ack_o;  // acknowlegement
        wire        wbd_ext_err_o;  // error

	// User I/O
	wire [37:0] io_oeb;
	wire [37:0] io_out;
	wire [37:0] io_in;


	reg [1:0] spi_chip_no;

	wire gpio;
	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;
	reg        test_fail;
	reg [31:0] read_data;


	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
                wbd_ext_cyc_i ='h0;  // strobe/request
                wbd_ext_stb_i ='h0;  // strobe/request
                wbd_ext_adr_i ='h0;  // address
                wbd_ext_we_i  ='h0;  // write
                wbd_ext_dat_i ='h0;  // data output
                wbd_ext_sel_i ='h0;  // byte enable
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(5, user_sspi_tb);
	   end
       `endif

	initial begin
		$dumpon;

		#200; // Wait for reset removal
	        repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

		// Remove Wb Reset
		wb_user_core_write(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

                // Enable SPI Multi Functional Ports
                // wire        cfg_spim_enb         = cfg_multi_func_sel[10];
                // wire [3:0]  cfg_spim_cs_enb      = cfg_multi_func_sel[14:11];
                wb_user_core_write(`ADDR_SPACE_PINMUX+`PINMUX_GPIO_MULTI_FUNC,'h7C00);

	        repeat (2) @(posedge clock);
		#1;

                // Remove the reset
		// Remove WB and SPI/UART Reset, Keep CORE under Reset
                wb_user_core_write(`ADDR_SPACE_PINMUX+`PINMUX_GBL_CFG0,'h01F);


		test_fail = 0;
		sspi_init();
	        repeat (200) @(posedge clock);
                wb_user_core_write(`ADDR_SPACE_WBHOST+`WBHOST_BANK_SEL,'h1000); // Change the Bank Sel 1000
                $display("############################################");
                $display("   Testing IS62/65WVS1288GALL SSRAM[0] Read/Write Access       ");
                $display("############################################");
		// SSPI Indirect RAM READ ACCESS-
		// Byte Read Option
		// <Instr:0x3> <Addr:24Bit Address> <Read Data Out>
                spi_chip_no = 2'b00; // Select the Chip Select to zero
		sspi_dw_read_check(8'h03,24'h0000,32'h03020100);
		sspi_dw_read_check(8'h03,24'h0004,32'h07060504);
		sspi_dw_read_check(8'h03,24'h0008,32'h0b0a0908);
		sspi_dw_read_check(8'h03,24'h000C,32'h0f0e0d0c);
		sspi_dw_read_check(8'h03,24'h0010,32'h13121110);
		sspi_dw_read_check(8'h03,24'h0014,32'h17161514);
		sspi_dw_read_check(8'h03,24'h0018,32'h1B1A1918);
		sspi_dw_read_check(8'h03,24'h001C,32'h1F1E1D1C);

		sspi_dw_read_check(8'h03,24'h0040,32'h43424140);
		sspi_dw_read_check(8'h03,24'h0044,32'h47464544);
		sspi_dw_read_check(8'h03,24'h0048,32'h4B4A4948);
		sspi_dw_read_check(8'h03,24'h004C,32'h4F4E4D4C);

		sspi_dw_read_check(8'h03,24'h00a0,32'ha3a2a1a0);
		sspi_dw_read_check(8'h03,24'h00a4,32'ha7a6a5a4);
		sspi_dw_read_check(8'h03,24'h00a8,32'habaaa9a8);
		sspi_dw_read_check(8'h03,24'h00aC,32'hafaeadac);

		sspi_dw_read_check(8'h03,24'h0200,32'h11111111);
		sspi_dw_read_check(8'h03,24'h0204,32'h22222222);
		sspi_dw_read_check(8'h03,24'h0208,32'h33333333);
		sspi_dw_read_check(8'h03,24'h020C,32'h44444444);

		// SPI Write
		sspi_dw_write(8'h02,24'h0000,32'h00112233);
		sspi_dw_write(8'h02,24'h0004,32'h44556677);
		sspi_dw_write(8'h02,24'h0008,32'h8899AABB);
		sspi_dw_write(8'h02,24'h000C,32'hCCDDEEFF);

		sspi_dw_write(8'h02,24'h0200,32'h11223344);
		sspi_dw_write(8'h02,24'h0204,32'h55667788);
		sspi_dw_write(8'h02,24'h0208,32'h99AABBCC);
		sspi_dw_write(8'h02,24'h020C,32'hDDEEFF00);

		// SPI Read Check
		sspi_dw_read_check(8'h03,24'h0000,32'h00112233);
		sspi_dw_read_check(8'h03,24'h0004,32'h44556677);
		sspi_dw_read_check(8'h03,24'h0008,32'h8899AABB);
		sspi_dw_read_check(8'h03,24'h000C,32'hCCDDEEFF);

		sspi_dw_read_check(8'h03,24'h0200,32'h11223344);
		sspi_dw_read_check(8'h03,24'h0204,32'h55667788);
		sspi_dw_read_check(8'h03,24'h0208,32'h99AABBCC);
		sspi_dw_read_check(8'h03,24'h020C,32'hDDEEFF00);

                $display("############################################");
                $display("   Testing IS62/65WVS1288GALL SSRAM[1] Read/Write Access       ");
                $display("############################################");
		// SSPI Indirect RAM READ ACCESS-
		// Byte Read Option
		// <Instr:0x3> <Addr:24Bit Address> <Read Data Out>
                spi_chip_no = 2'b01; // Select the Chip Select to zero
		sspi_dw_read_check(8'h03,24'h0000,32'h13121110);
		sspi_dw_read_check(8'h03,24'h0004,32'h17161514);
		sspi_dw_read_check(8'h03,24'h0008,32'h1B1A1918);
		sspi_dw_read_check(8'h03,24'h000C,32'h1F1E1D1C);
		
		sspi_dw_read_check(8'h03,24'h0010,32'h23222120);
		sspi_dw_read_check(8'h03,24'h0014,32'h27262524);
		sspi_dw_read_check(8'h03,24'h0018,32'h2B2A2928);
		sspi_dw_read_check(8'h03,24'h001C,32'h2F2E2D2C);
		
		sspi_dw_read_check(8'h03,24'h0020,32'h33323130);
		sspi_dw_read_check(8'h03,24'h0024,32'h37363534);
		sspi_dw_read_check(8'h03,24'h0028,32'h3B3A3938);
		sspi_dw_read_check(8'h03,24'h002C,32'h3F3E3D3C);

		sspi_dw_read_check(8'h03,24'h0030,32'h43424140);
		sspi_dw_read_check(8'h03,24'h0034,32'h47464544);
		sspi_dw_read_check(8'h03,24'h0038,32'h4B4A4948);
		sspi_dw_read_check(8'h03,24'h003C,32'h4F4E4D4C);

		sspi_dw_read_check(8'h03,24'h00a0,32'hb3b2b1b0);
		sspi_dw_read_check(8'h03,24'h00a4,32'hb7b6b5b4);
		sspi_dw_read_check(8'h03,24'h00a8,32'hbbbab9b8);
		sspi_dw_read_check(8'h03,24'h00aC,32'hbfbebdbc);

		sspi_dw_read_check(8'h03,24'h0200,32'h22222222);
		sspi_dw_read_check(8'h03,24'h0204,32'h33333333);
		sspi_dw_read_check(8'h03,24'h0208,32'h44444444);
		sspi_dw_read_check(8'h03,24'h020C,32'h55555555);

		// SPI Write
		sspi_dw_write(8'h02,24'h0000,32'h00112233);
		sspi_dw_write(8'h02,24'h0004,32'h44556677);
		sspi_dw_write(8'h02,24'h0008,32'h8899AABB);
		sspi_dw_write(8'h02,24'h000C,32'hCCDDEEFF);

		sspi_dw_write(8'h02,24'h0200,32'h11223344);
		sspi_dw_write(8'h02,24'h0204,32'h55667788);
		sspi_dw_write(8'h02,24'h0208,32'h99AABBCC);
		sspi_dw_write(8'h02,24'h020C,32'hDDEEFF00);

		// SPI Read Check
		sspi_dw_read_check(8'h03,24'h0000,32'h00112233);
		sspi_dw_read_check(8'h03,24'h0004,32'h44556677);
		sspi_dw_read_check(8'h03,24'h0008,32'h8899AABB);
		sspi_dw_read_check(8'h03,24'h000C,32'hCCDDEEFF);

		sspi_dw_read_check(8'h03,24'h0200,32'h11223344);
		sspi_dw_read_check(8'h03,24'h0204,32'h55667788);
		sspi_dw_read_check(8'h03,24'h0208,32'h99AABBCC);
		sspi_dw_read_check(8'h03,24'h020C,32'hDDEEFF00);

                $display("############################################");
                $display("   Testing IS62/65WVS1288GALL SSRAM[2] Read/Write Access       ");
                $display("############################################");
		// SSPI Indirect RAM READ ACCESS-
		// Byte Read Option
		// <Instr:0x3> <Addr:24Bit Address> <Read Data Out>
                spi_chip_no = 2'b10; // Select the Chip Select to zero
		sspi_dw_read_check(8'h03,24'h0000,32'h23222120);
		sspi_dw_read_check(8'h03,24'h0004,32'h27262524);
		sspi_dw_read_check(8'h03,24'h0008,32'h2b2a2928);
		sspi_dw_read_check(8'h03,24'h000C,32'h2f2e2d2c);

		sspi_dw_read_check(8'h03,24'h0010,32'h33323130);
		sspi_dw_read_check(8'h03,24'h0014,32'h37363534);
		sspi_dw_read_check(8'h03,24'h0018,32'h3B3A3938);
		sspi_dw_read_check(8'h03,24'h001C,32'h3F3E3D3C);
		
		sspi_dw_read_check(8'h03,24'h0020,32'h43424140);
		sspi_dw_read_check(8'h03,24'h0024,32'h47464544);
		sspi_dw_read_check(8'h03,24'h0028,32'h4B4A4948);
		sspi_dw_read_check(8'h03,24'h002C,32'h4F4E4D4C);
		
		sspi_dw_read_check(8'h03,24'h0030,32'h53525150);
		sspi_dw_read_check(8'h03,24'h0034,32'h57565554);
		sspi_dw_read_check(8'h03,24'h0038,32'h5B5A5958);
		sspi_dw_read_check(8'h03,24'h003C,32'h5F5E5D5C);

		sspi_dw_read_check(8'h03,24'h0040,32'h63626160);
		sspi_dw_read_check(8'h03,24'h0044,32'h67666564);
		sspi_dw_read_check(8'h03,24'h0048,32'h6B6A6968);
		sspi_dw_read_check(8'h03,24'h004C,32'h6F6E6D6C);

		sspi_dw_read_check(8'h03,24'h00a0,32'hc3c2c1c0);
		sspi_dw_read_check(8'h03,24'h00a4,32'hc7c6c5c4);
		sspi_dw_read_check(8'h03,24'h00a8,32'hcbcac9c8);
		sspi_dw_read_check(8'h03,24'h00aC,32'hcfcecdcc);

		sspi_dw_read_check(8'h03,24'h0200,32'h33333333);
		sspi_dw_read_check(8'h03,24'h0204,32'h44444444);
		sspi_dw_read_check(8'h03,24'h0208,32'h55555555);
		sspi_dw_read_check(8'h03,24'h020C,32'h66666666);

		// SPI Write
		sspi_dw_write(8'h02,24'h0000,32'h00112233);
		sspi_dw_write(8'h02,24'h0004,32'h44556677);
		sspi_dw_write(8'h02,24'h0008,32'h8899AABB);
		sspi_dw_write(8'h02,24'h000C,32'hCCDDEEFF);

		sspi_dw_write(8'h02,24'h0200,32'h11223344);
		sspi_dw_write(8'h02,24'h0204,32'h55667788);
		sspi_dw_write(8'h02,24'h0208,32'h99AABBCC);
		sspi_dw_write(8'h02,24'h020C,32'hDDEEFF00);

		// SPI Read Check
		sspi_dw_read_check(8'h03,24'h0000,32'h00112233);
		sspi_dw_read_check(8'h03,24'h0004,32'h44556677);
		sspi_dw_read_check(8'h03,24'h0008,32'h8899AABB);
		sspi_dw_read_check(8'h03,24'h000C,32'hCCDDEEFF);

		sspi_dw_read_check(8'h03,24'h0200,32'h11223344);
		sspi_dw_read_check(8'h03,24'h0204,32'h55667788);
		sspi_dw_read_check(8'h03,24'h0208,32'h99AABBCC);
		sspi_dw_read_check(8'h03,24'h020C,32'hDDEEFF00);

                $display("############################################");
                $display("   Testing IS62/65WVS1288GALL SSRAM[3] Read/Write Access       ");
                $display("############################################");
		// SSPI Indirect RAM READ ACCESS-
		// Byte Read Option
		// <Instr:0x3> <Addr:24Bit Address> <Read Data Out>
                spi_chip_no = 2'b11; // Select the Chip Select to zero
		sspi_dw_read_check(8'h03,24'h0000,32'h33323130);
		sspi_dw_read_check(8'h03,24'h0004,32'h37363534);
		sspi_dw_read_check(8'h03,24'h0008,32'h3b3a3938);
		sspi_dw_read_check(8'h03,24'h000C,32'h3f3e3d3c);

		sspi_dw_read_check(8'h03,24'h0010,32'h43424140);
		sspi_dw_read_check(8'h03,24'h0014,32'h47464544);
		sspi_dw_read_check(8'h03,24'h0018,32'h4B4A4948);
		sspi_dw_read_check(8'h03,24'h001C,32'h4F4E4D4C);

		sspi_dw_read_check(8'h03,24'h0020,32'h53525150);
		sspi_dw_read_check(8'h03,24'h0024,32'h57565554);
		sspi_dw_read_check(8'h03,24'h0028,32'h5B5A5958);
		sspi_dw_read_check(8'h03,24'h002C,32'h5F5E5D5C);

		sspi_dw_read_check(8'h03,24'h00a0,32'hd3d2d1d0);
		sspi_dw_read_check(8'h03,24'h00a4,32'hd7d6d5d4);
		sspi_dw_read_check(8'h03,24'h00a8,32'hdbdad9d8);
		sspi_dw_read_check(8'h03,24'h00aC,32'hdfdedddc);

		sspi_dw_read_check(8'h03,24'h0200,32'h44444444);
		sspi_dw_read_check(8'h03,24'h0204,32'h55555555);
		sspi_dw_read_check(8'h03,24'h0208,32'h66666666);
		sspi_dw_read_check(8'h03,24'h020C,32'h77777777);

		// SPI Write
		sspi_dw_write(8'h02,24'h0000,32'h00112233);
		sspi_dw_write(8'h02,24'h0004,32'h44556677);
		sspi_dw_write(8'h02,24'h0008,32'h8899AABB);
		sspi_dw_write(8'h02,24'h000C,32'hCCDDEEFF);

		sspi_dw_write(8'h02,24'h0200,32'h11223344);
		sspi_dw_write(8'h02,24'h0204,32'h55667788);
		sspi_dw_write(8'h02,24'h0208,32'h99AABBCC);
		sspi_dw_write(8'h02,24'h020C,32'hDDEEFF00);

		// SPI Read Check
		sspi_dw_read_check(8'h03,24'h0000,32'h00112233);
		sspi_dw_read_check(8'h03,24'h0004,32'h44556677);
		sspi_dw_read_check(8'h03,24'h0008,32'h8899AABB);
		sspi_dw_read_check(8'h03,24'h000C,32'hCCDDEEFF);

		sspi_dw_read_check(8'h03,24'h0200,32'h11223344);
		sspi_dw_read_check(8'h03,24'h0204,32'h55667788);
		sspi_dw_read_check(8'h03,24'h0208,32'h99AABBCC);
		sspi_dw_read_check(8'h03,24'h020C,32'hDDEEFF00);
		repeat (100) @(posedge clock);
			// $display("+1000 cycles");

          	if(test_fail == 0) begin
		   `ifdef GL
	    	       $display("Monitor: SPI Master Mode (GL) Passed");
		   `else
		       $display("Monitor: SPI Master Mode (RTL) Passed");
		   `endif
	        end else begin
		    `ifdef GL
	    	        $display("Monitor: SPI Master Mode (GL) Failed");
		    `else
		        $display("Monitor: SPI Master Mode (RTL) Failed");
		    `endif
		 end
	    	$display("###################################################");
	        $finish;
	end

	initial begin
		wb_rst_i <= 1'b1;
		#100;
		wb_rst_i <= 1'b0;	    	// Release reset
	end
wire USER_VDD1V8 = 1'b1;
wire VSS = 1'b0;

user_project_wrapper u_top(
`ifdef USE_POWER_PINS
    .vccd1(USER_VDD1V8),	// User area 1 1.8V supply
    .vssd1(VSS),	// User area 1 digital ground
`endif
    .wb_clk_i        (clock),  // System clock
    .user_clock2     (1'b1),  // Real-time clock
    .wb_rst_i        (wb_rst_i),  // Regular Reset signal

    .wbs_cyc_i   (wbd_ext_cyc_i),  // strobe/request
    .wbs_stb_i   (wbd_ext_stb_i),  // strobe/request
    .wbs_adr_i   (wbd_ext_adr_i),  // address
    .wbs_we_i    (wbd_ext_we_i),  // write
    .wbs_dat_i   (wbd_ext_dat_i),  // data output
    .wbs_sel_i   (wbd_ext_sel_i),  // byte enable

    .wbs_dat_o   (wbd_ext_dat_o),  // data input
    .wbs_ack_o   (wbd_ext_ack_o),  // acknowlegement

 
    // Logic Analyzer Signals
    .la_data_in      ('1) ,
    .la_data_out     (),
    .la_oenb         ('0),
 

    // IOs
    .io_in          (io_in)  ,
    .io_out         (io_out) ,
    .io_oeb         (io_oeb) ,

    .user_irq       () 

);

`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
    initial begin

    end
`endif    

//------------------------------------------------------
//  Integrate the Serial flash with quad support to
//  user core using the gpio pads
//  ----------------------------------------------------
   wire flash_io1;
   wire flash_clk = io_out[16];
   tri  #1 flash_io0 = io_out[15];
   assign io_in[14] = flash_io1;

   tri  #1 flash_io2 = 1'b1;
   tri  #1 flash_io3 = 1'b1;


   wire spiram_csb0 = io_out[13];
   is62wvs1288 #(.mem_file_name("flash0.hex"))
	u_sfram_0 (
         // Data Inputs/Outputs
           .io0     (flash_io0),
           .io1     (flash_io1),
           // Controls
           .clk    (flash_clk),
           .csb    (spiram_csb0),
           .io2    (flash_io2),
           .io3    (flash_io3)
    );

   wire spiram_csb1 = io_out[12];
   is62wvs1288 #(.mem_file_name("flash1.hex"))
	u_sfram_1 (
         // Data Inputs/Outputs
           .io0     (flash_io0),
           .io1     (flash_io1),
           // Controls
           .clk    (flash_clk),
           .csb    (spiram_csb1),
           .io2    (flash_io2),
           .io3    (flash_io3)
    );

   wire spiram_csb2 = io_out[9];
is62wvs1288 #(.mem_file_name("flash2.hex"))
     u_sfram_2 (
      // Data Inputs/Outputs
	.io0     (flash_io0),
	.io1     (flash_io1),
	// Controls
	.clk    (flash_clk),
	.csb    (spiram_csb2),
	.io2    (flash_io2),
	.io3    (flash_io3)
 );

   wire spiram_csb3 = io_out[8];
is62wvs1288 #(.mem_file_name("flash3.hex"))
     u_sfram_3 (
      // Data Inputs/Outputs
	.io0     (flash_io0),
	.io1     (flash_io1),
	// Controls
	.clk    (flash_clk),
	.csb    (spiram_csb3),
	.io2    (flash_io2),
	.io3    (flash_io3)
 );

//----------------------------------------------------
//  Task
// --------------------------------------------------
task test_err;
begin
     test_fail = 1;
end
endtask

task wb_user_core_write;
input [31:0] address;
input [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h1;  // write
  wbd_ext_dat_i =data;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  $display("STATUS: WB USER ACCESS WRITE Address : 0x%x, Data : 0x%x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read;
input [31:0] address;
output [31:0] data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(negedge clock);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  //$display("STATUS: WB USER ACCESS READ  Address : 0x%x, Data : 0x%x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read_check;
input [31:0] address;
output [31:0] data;
input [31:0] cmp_data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(negedge clock);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  if(data !== cmp_data) begin
     $display("ERROR : WB USER ACCESS READ  Address : 0x%x, Exd: 0x%x Rxd: 0x%x ",address,cmp_data,data);
     user_sspi_tb.test_fail = 1;
  end else begin
     $display("STATUS: WB USER ACCESS READ  Address : 0x%x, Data : 0x%x",address,data);
  end
  repeat (2) @(posedge clock);
end
endtask


`ifdef GL

wire        wbd_spi_stb_i   = u_top.u_qspi_master.wbd_stb_i;
wire        wbd_spi_ack_o   = u_top.u_qspi_master.wbd_ack_o;
wire        wbd_spi_we_i    = u_top.u_qspi_master.wbd_we_i;
wire [31:0] wbd_spi_adr_i   = u_top.u_qspi_master.wbd_adr_i;
wire [31:0] wbd_spi_dat_i   = u_top.u_qspi_master.wbd_dat_i;
wire [31:0] wbd_spi_dat_o   = u_top.u_qspi_master.wbd_dat_o;
wire [3:0]  wbd_spi_sel_i   = u_top.u_qspi_master.wbd_sel_i;

wire        wbd_uart_stb_i  = u_top.u_uart_i2c_usb_spi.reg_cs;
wire        wbd_uart_ack_o  = u_top.u_uart_i2c_usb_spi.reg_ack;
wire        wbd_uart_we_i   = u_top.u_uart_i2c_usb_spi.reg_wr;
wire [8:0]  wbd_uart_adr_i  = u_top.u_uart_i2c_usb_spi.reg_addr;
wire [7:0]  wbd_uart_dat_i  = u_top.u_uart_i2c_usb_spi.reg_wdata;
wire [7:0]  wbd_uart_dat_o  = u_top.u_uart_i2c_usb_spi.reg_rdata;
wire        wbd_uart_sel_i  = u_top.u_uart_i2c_usb_spi.reg_be;

`endif

/**
`ifdef GL
//-----------------------------------------------------------------------------
// RISC IMEM amd DMEM Monitoring TASK
//-----------------------------------------------------------------------------

`define RISC_CORE  user_uart_tb.u_top.u_core.u_riscv_top

always@(posedge `RISC_CORE.wb_clk) begin
    if(`RISC_CORE.wbd_imem_ack_i)
          $display("RISCV-DEBUG => IMEM ADDRESS: %x Read Data : %x", `RISC_CORE.wbd_imem_adr_o,`RISC_CORE.wbd_imem_dat_i);
    if(`RISC_CORE.wbd_dmem_ack_i && `RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x Write Data: %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_o);
    if(`RISC_CORE.wbd_dmem_ack_i && !`RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x READ Data : %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_i);
end

`endif
**/
`include "sspi_task.v"

endmodule
`default_nettype wire
