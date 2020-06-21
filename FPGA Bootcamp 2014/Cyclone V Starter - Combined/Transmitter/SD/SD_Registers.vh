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

// Operating Conditions Register
`define OCR_16_17     Response[12] //  4
`define OCR_17_18     Response[13] //  5
`define OCR_18_19     Response[14] //  6
`define OCR_19_20     Response[15] //  7
`define OCR_20_21     Response[16] //  8
`define OCR_21_22     Response[17] //  9
`define OCR_22_23     Response[18] // 10
`define OCR_23_24     Response[19] // 11
`define OCR_24_25     Response[20] // 12
`define OCR_25_26     Response[21] // 13
`define OCR_26_27     Response[22] // 14
`define OCR_27_28     Response[23] // 15
`define OCR_28_29     Response[24] // 16
`define OCR_29_30     Response[25] // 17
`define OCR_30_31     Response[26] // 18
`define OCR_31_32     Response[27] // 19
`define OCR_32_33     Response[28] // 20
`define OCR_33_34     Response[29] // 21
`define OCR_34_35     Response[30] // 22
`define OCR_35_36     Response[31] // 23
`define OCR_18_Switch Response[32] // 24
`define OCR_UHS_II    Response[37] // 29
`define OCR_Capacity  Response[38] // 30
`define OCR_Powerup   Response[39] // 31

// Card Identification Register
`define MID Response[127:120] // Manufacturer ID
`define OID Response[119:104] // OEM / Application ID
`define PNM Response[103: 64] // Product name
`define PRV Response[ 63: 56] // Product revision
`define PSN Response[ 55: 24] // Product serial number
`define MDT Response[ 19:  8] // Manufacturing date

// Card Specific Data Register
`define CSD_STRUCTURE      Response[127:126]
`define TAAC               Response[119:112]
`define NSAC               Response[111:104]
`define TRAN_SPEED         Response[103: 96]
`define CCC                Response[ 95: 84]
`define READ_BL_LEN        Response[ 83: 80]
`define READ_BL_PARTIAL    Response[     79]
`define WRITE_BLK_MISALIGN Response[     78]
`define READ_BLK_MISALIGN  Response[     77]
`define DSR_IMP            Response[     76]
`define ERASE_BLK_EN       Response[     46]
`define SECTOR_SIZE        Response[ 45: 39]
`define WP_GRP_SIZE        Response[ 38: 32]
`define WP_GRP_ENABLE      Response[     31]
`define R2W_FACTOR         Response[ 28: 26]
`define WRITE_BL_LEN       Response[ 25: 22]
`define WRITE_BL_PARTIAL   Response[     21]
`define FILE_FORMAT_GRP    Response[     15]
`define COPY               Response[     14]
`define PERM_WRITE_PROTECT Response[     13]
`define TMP_WRITE_PROTECT  Response[     12]
`define FILE_FORMAT        Response[ 11: 10]

`define C_SIZE_1           Response[ 73: 62]
`define VDD_R_CURR_MIN     Response[ 61: 59]
`define VDD_R_CURR_MAX     Response[ 58: 56]
`define VDD_W_CURR_MIN     Response[ 55: 53]
`define VDD_W_CURR_MAX     Response[ 52: 50]
`define C_SIZE_MULT        Response[ 49: 47]

`define C_SIZE_2           Response[ 69: 48]

// SD Card Configuration Register
`define SCR_STRUCTURE         Response[63:60]
`define SD_SPEC               Response[59:56]
`define DATA_STAT_AFTER_ERASE Response[   55]
`define SD_SECURITY           Response[54:52]
`define SD_BUS_WIDTHS         Response[51:48]
`define SD_SPEC3              Response[   47]
`define EX_ SECURITY          Response[46:43]
`define SD_SPEC4              Response[   42]
`define CMD_SUPPORT           Response[35:32]

// SD Status Register
`define DAT_BUS_WIDTH          Response[511:510]
`define SECURED_MODE           Response[    509]
`define SD_CARD_TYPE           Response[495:480]
`define SIZE_OF_PROTECTED_AREA Response[479:448]
`define SPEED_CLASS            Response[447:440]
`define PERFORMANCE_MOVE       Response[439:432]
`define AU_SIZE                Response[431:428]
`define ERASE_SIZE             Response[423:408]
`define ERASE_TIMEOUT          Response[407:402]
`define ERASE_OFFSET           Response[401:400]
`define UHS_SPEED_GRADE        Response[399:396]
`define UHS_AU_SIZE            Response[395:392]

// Card Status Register
`define OUT_OF_RANGE       Response[   39] // 31
`define ADDRESS_ERROR      Response[   38] // 30
`define BLOCK_LEN_ERROR    Response[   37] // 29
`define ERASE_SEQ_ERROR    Response[   36] // 28
`define ERASE_PARAM        Response[   35] // 27
`define WP_VIOLATION       Response[   34] // 26
`define CARD_IS_LOCKED     Response[   33] // 25
`define LOCK_UNLOCK_FAILED Response[   32] // 24
`define COM_CRC_ERROR      Response[   31] // 23
`define ILLEGAL_COMMAND    Response[   30] // 22
`define CARD_ECC_FAILED    Response[   29] // 21
`define CC_ERROR           Response[   28] // 20
`define ERROR              Response[   27] // 19
`define CSD_OVERWRITE      Response[   24] // 16
`define WP_ERASE_SKIP      Response[   23] // 15
`define CARD_ECC_DISABLED  Response[   22] // 14
`define ERASE_RESET        Response[   21] // 13
`define CURRENT_STATE      Response[20:17] // 12:9
`define READY_FOR_DATA     Response[   16] //  8
`define APP_CMD            Response[   13] //  5
`define AKE_SEQ_ERROR      Response[   11] //  3

