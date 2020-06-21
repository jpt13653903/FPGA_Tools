//==============================================================================
// Copyright (C) John-Philip Taylor
// jpt13653903@gmail.com
//
// This file is part of S/PDIF Radio
//
// This file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>
//==============================================================================

// Commands
localparam GO_IDLE_STATE          = 6'd00;
localparam ALL_SEND_CID           = 6'd02;
localparam SEND_RELATIVE_ADDR     = 6'd03;
localparam SET_DSR                = 6'd04;
localparam SWITCH_FUNC            = 6'd06;
localparam SELECT_CARD            = 6'd07;
localparam DESELECT_CARD          = 6'd07;
localparam SEND_IF_COND           = 6'd08;
localparam SEND_CSD               = 6'd09;
localparam SEND_CID               = 6'd10;
localparam VOLTAGE_SWITCH         = 6'd11;
localparam STOP_TRANSMISSION      = 6'd12;
localparam SEND_STATUS            = 6'd13;
localparam GO_INACTIVE_STATE      = 6'd15;
localparam SET_BLOCKLEN           = 6'd16;
localparam READ_SINGLE_BLOCK      = 6'd17;
localparam READ_MULTIPLE_BLOCK    = 6'd18;
localparam SEND_TUNING_BLOCK      = 6'd19;
localparam SPEED_CLASS_CONTROL    = 6'd20;
localparam SET_BLOCK_COUNT        = 6'd23;
localparam WRITE_BLOCK            = 6'd24;
localparam WRITE_MULTIPLE_BLOCK   = 6'd25;
localparam PROGRAM_CSD            = 6'd27;
localparam SET_WRITE_PROT         = 6'd28;
localparam CLR_WRITE_PROT         = 6'd29;
localparam SEND_WRITE_PROT        = 6'd30;
localparam ERASE_WR_BLK_START     = 6'd32;
localparam ERASE_WR_BLK_END       = 6'd33;
localparam ERASE                  = 6'd38;
localparam LOCK_UNLOCK            = 6'd42;
localparam APP_CMD                = 6'd55;
localparam GEN_CMD                = 6'd56;

localparam READ_EXTR_SINGLE       = 6'd48;
localparam WRITE_EXTR_SINGLE      = 6'd49;
localparam READ_EXTR_MULTI        = 6'd58;
localparam WRITE_EXTR_MULTI       = 6'd59;
        
// Application Specific Commands
localparam SET_BUS_WIDTH          = 6'd06;
localparam SD_STATUS              = 6'd13;
localparam SEND_NUM_WR_BLOCKS     = 6'd22;
localparam SET_WR_BLK_ERASE_COUNT = 6'd23;
localparam SD_SEND_OP_COND        = 6'd41;
localparam SET_CLR_CARD_DETECT    = 6'd42;
localparam SEND_SCR               = 6'd51;

// Responses
localparam R1   = 2'd1;
localparam R1b  = 2'd1;
localparam R2   = 2'd2;
localparam R3   = 2'd3;
localparam R6   = 2'd1;
localparam R7   = 2'd1;

