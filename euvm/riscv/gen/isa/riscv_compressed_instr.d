/*
 * Copyright 2020 Google LLC
 * Copyright 2022 Coverify Systems Technology
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module riscv.gen.isa.riscv_compressed_instr;

import riscv.gen.riscv_instr_pkg: riscv_instr_name_t, MAX_INSTR_STR_LEN,
  riscv_instr_format_t, riscv_reg_t, riscv_instr_category_t, imm_t;
import riscv.gen.target: XLEN;
import riscv.gen.isa.riscv_instr: riscv_instr;
import std.format: format;

import esdl.rand: constraint, rand;
import esdl.data.bvec: ubvec, UBVEC;

import uvm;

class riscv_compressed_instr: riscv_instr
{
  mixin uvm_object_utils;

  int imm_align;

  // constraint! q{
  //   //  Registers specified by the three-bit rs1’, rs2’, and rd’
  //   if (instr_format inside [riscv_instr_format_t.CIW_FORMAT,
  // 			     riscv_instr_format_t.CL_FORMAT,
  // 			     riscv_instr_format_t.CS_FORMAT,
  // 			     riscv_instr_format_t.CB_FORMAT,
  // 			     riscv_instr_format_t.CA_FORMAT]) {
  //     if (has_rs1) {
  // 	rs1 inside [riscv_reg_t.S0:riscv_reg_t.A5];
  //     }
  //     if (has_rs2) {
  // 	rs2 inside [riscv_reg_t.S0:riscv_reg_t.A5];
  //     }
  //     if (has_rd) {
  // 	rd inside [riscv_reg_t.S0:riscv_reg_t.A5];
  //     }
  //   }
  //   // C_ADDI16SP is only valid when rd == SP
  //   // if (instr_name == riscv_instr_name_t.C_ADDI16SP) {
  //   //   rd  == riscv_reg_t.SP;
  //   // }
  //   // if (instr_name inside [riscv_instr_name_t.C_JR, riscv_instr_name_t.C_JALR]) {
  //   //   rs2 == riscv_reg_t.ZERO;
  //   //   rs1 != riscv_reg_t.ZERO;
  //   // }
  // } rvc_csr_c ;

  // constraint! q{
  //   if(imm_type inside [imm_t.NZIMM, imm_t.NZUIMM]) {
  //     imm[0..6] != 0;
  //     if (instr_name == riscv_instr_name_t.C_LUI) {
  //       // TODO(taliu) Check why bit 6 cannot be zero
  //       imm[5..32] == 0;
  //     }
  //     if (instr_name inside [riscv_instr_name_t.C_SRAI,
  // 			     riscv_instr_name_t.C_SRLI,
  // 			     riscv_instr_name_t.C_SLLI]) {
  // 	imm[5..32] == 0;
  //     }
  //   }
  //   if (instr_name == riscv_instr_name_t.C_ADDI4SPN) {
  //     imm[0..2] == 0;
  //   }
  // } imm_val_c ;

  // C_JAL is RV32C only instruction
  // constraint! q{
  //   if (XLEN != 32) {
  //     instr_name != riscv_instr_name_t.C_JAL;
  //   }
  // } jal_c ;

  // Avoid generating HINT or illegal instruction by default as it's not supported by the compiler
  // constraint! q{
  //   if (instr_name inside [riscv_instr_name_t.C_ADDI, riscv_instr_name_t.C_ADDIW,
  // 			   riscv_instr_name_t.C_LI, riscv_instr_name_t.C_LUI,
  // 			   riscv_instr_name_t.C_SLLI, riscv_instr_name_t.C_SLLI64,
  //                          riscv_instr_name_t.C_LQSP, riscv_instr_name_t.C_LDSP,
  // 			   riscv_instr_name_t.C_MV, riscv_instr_name_t.C_ADD,
  // 			   riscv_instr_name_t.C_LWSP]) {
  //     rd != riscv_reg_t.ZERO;
  //   }
  //   if (instr_name == riscv_instr_name_t.C_JR) {
  //     rs1 != riscv_reg_t.ZERO;
  //   }
  //   if (instr_name inside [riscv_instr_name_t.C_ADD, riscv_instr_name_t.C_MV]) {
  //     rs2 != riscv_reg_t.ZERO;
  //   }
  //   (instr_name == riscv_instr_name_t.C_LUI) -> (rd != riscv_reg_t.SP);
  // } no_hint_illegal_instr_c ;

  this(string name = "") {
    super(name);
    rs1 = riscv_reg_t.S0;
    rs2 = riscv_reg_t.S0;
    rd  = riscv_reg_t.S0;
    is_compressed = true;
  }


  override void set_imm_len() {
    if ( instr_format.inside(riscv_instr_format_t.CI_FORMAT, riscv_instr_format_t.CSS_FORMAT)) {
      imm_len = UBVEC!(5, 6);
    }
    else if (instr_format.inside(riscv_instr_format_t.CL_FORMAT, riscv_instr_format_t.CS_FORMAT)) {
      imm_len = UBVEC!(5, 5);
    }
    else if (instr_format == riscv_instr_format_t.CJ_FORMAT) {
      imm_len = UBVEC!(5, 11);
    }
    else if (instr_format == riscv_instr_format_t.CB_FORMAT) {
      if (instr_name == riscv_instr_name_t.C_ANDI) {
        imm_len = UBVEC!(5, 6);
      }
      else {
        imm_len = UBVEC!(5, 7);
      }
    }
    else if (instr_format.inside(riscv_instr_format_t.CB_FORMAT, riscv_instr_format_t.CIW_FORMAT)) {
      imm_len = UBVEC!(5, 8);
    }
    if (instr_name.inside(riscv_instr_name_t.C_SQ, riscv_instr_name_t.C_LQ,
			  riscv_instr_name_t.C_LQSP, riscv_instr_name_t.C_SQSP,
			  riscv_instr_name_t.C_ADDI16SP)) {
      imm_align = 4;
    }
    else if (instr_name.inside(riscv_instr_name_t.C_SD, riscv_instr_name_t.C_LD,
			       riscv_instr_name_t.C_LDSP, riscv_instr_name_t.C_SDSP)) {
      imm_align = 3;
    }
    else if (instr_name.inside(riscv_instr_name_t.C_SW, riscv_instr_name_t.C_LW,
			       riscv_instr_name_t.C_LWSP, riscv_instr_name_t.C_SWSP,
			       riscv_instr_name_t.C_ADDI4SPN))  {
      imm_align = 2;
    }
    else if (instr_name == riscv_instr_name_t.C_LUI) {
      imm_align = 12;
    }
    else if (instr_name.inside(riscv_instr_name_t.C_J, riscv_instr_name_t.C_JAL,
			       riscv_instr_name_t.C_BNEZ, riscv_instr_name_t.C_BEQZ)) {
      imm_align = 1;
    }
  }

  override void do_copy(uvm_object rhs) {
    riscv_compressed_instr rhs_;
    super.copy(rhs);
    rhs_ = cast(riscv_compressed_instr) rhs;
    assert (rhs_ !is null);
    this.imm_align = rhs_.imm_align;
  }

  override void extend_imm() {
    if (instr_name != riscv_instr_name_t.C_LUI) {
      super.extend_imm();
      imm = imm << imm_align;
    }
  }

  override void set_rand_mode() {
    switch (instr_format) {
    case riscv_instr_format_t.CR_FORMAT :
      if (category == riscv_instr_category_t.JUMP) {
	has_rd = false;
      }
      else {
	has_rs1 = false;
      }
      has_imm = false;
      break;
    case riscv_instr_format_t.CSS_FORMAT :
      has_rs1 = false;
      has_rd  = false;
      break;
    case riscv_instr_format_t.CL_FORMAT :
      has_rs2 = false;
      break;
    case riscv_instr_format_t.CS_FORMAT :
      has_rd = false;
      break;
    case riscv_instr_format_t.CA_FORMAT :
      has_rs1 = false;
      has_imm = false;
      break;
    case riscv_instr_format_t.CI_FORMAT, riscv_instr_format_t.CIW_FORMAT:
      has_rs1 = false;
      has_rs2 = false;
      break;
    case riscv_instr_format_t.CJ_FORMAT :
      has_rs1 = false;
      has_rs2 = false;
      has_rd  = false;
      break;
    case riscv_instr_format_t.CB_FORMAT :
      if (instr_name != riscv_instr_name_t.C_ANDI) has_rd = false;
      has_rs2 = false;
      break;
    default : break;
    }
  }

  // Convert the instruction to assembly code
  override string convert2asm(string prefix = "") {
    import std.string: toLower;
    enum string FMT = "%-" ~ MAX_INSTR_STR_LEN.stringof ~ "s";
    string asm_str = format!FMT(get_instr_name());
    if (category != riscv_instr_category_t.SYSTEM) {
      switch(instr_format) {
      case riscv_instr_format_t.CI_FORMAT,
	riscv_instr_format_t.CIW_FORMAT :
	if (instr_name == riscv_instr_name_t.C_NOP)
	  asm_str = "c.nop";
	else if (instr_name == riscv_instr_name_t.C_ADDI16SP)
	  asm_str = format("%0ssp, %0s", asm_str, get_imm());
	else if (instr_name == riscv_instr_name_t.C_ADDI4SPN)
	  asm_str = format("%0s%0s, sp, %0s", asm_str, rd, get_imm());
	else if (instr_name.inside(riscv_instr_name_t.C_LDSP, riscv_instr_name_t.C_LWSP,
				   riscv_instr_name_t.C_LQSP))
	  asm_str = format("%0s%0s, %0s(sp)", asm_str, rd, get_imm());
	else
	  asm_str = format("%0s%0s, %0s", asm_str, rd, get_imm());
	break;
      case riscv_instr_format_t.CL_FORMAT :
	asm_str = format("%0s%0s, %0s(%0s)", asm_str, rd, get_imm(), rs1);
	break;
      case riscv_instr_format_t.CS_FORMAT:
	if (category == riscv_instr_category_t.STORE)
	  asm_str = format("%0s%0s, %0s(%0s)", asm_str, rs2, get_imm(), rs1);
	else
	  asm_str = format("%0s%0s, %0s", asm_str, rs1, rs2);
	break;
      case riscv_instr_format_t.CA_FORMAT :
	asm_str = format("%0s%0s, %0s", asm_str, rd, rs2);
	break;
      case riscv_instr_format_t.CB_FORMAT:
	asm_str = format("%0s%0s, %0s", asm_str, rs1, get_imm());
	break;
      case riscv_instr_format_t.CSS_FORMAT:
	if (category == riscv_instr_category_t.STORE)
	  asm_str = format("%0s%0s, %0s(sp)", asm_str, rs2, get_imm());
	else
	  asm_str = format("%0s%0s, %0s", asm_str, rs2, get_imm());
	break;
      case riscv_instr_format_t.CR_FORMAT:
	if (instr_name.inside(riscv_instr_name_t.C_JR, riscv_instr_name_t.C_JALR)) {
	  asm_str = format("%0s%0s", asm_str, rs1);
	}
	else {
	  asm_str = format("%0s%0s, %0s", asm_str, rd, rs2);
	}
	break;
      case riscv_instr_format_t.CJ_FORMAT:
	asm_str = format("%0s%0s", asm_str, get_imm());
	break;
      default: uvm_info(get_full_name(),
			format("Unsupported format %0s", instr_format), UVM_LOW);
	break;
      }
    }
    else {
      // For EBREAK,C.EBREAK, making sure pc+4 is a valid instruction boundary
      // This is needed to resume execution from epc+4 after ebreak handling
      if (instr_name == riscv_instr_name_t.C_EBREAK) {
	asm_str = "c.ebreak; c.nop;";
      }
    }
    if (comment != "")
      asm_str = asm_str ~ " #" ~ comment ;
    return asm_str.toLower();
  }

  override char[] convert2asm(char[] buf, string prefix = "") {
    import std.string: toLower, toLowerInPlace;
    import std.format: sformat;

    char[32] instr_buf;
    char[MAX_INSTR_STR_LEN+8] instr_name_buf;

    string asm_str;
    char[] asm_buf;

    enum string FMT = "%-" ~ MAX_INSTR_STR_LEN.stringof ~ "s";
    char[] instr_name_str = sformat!FMT(instr_name_buf, get_instr_name(instr_buf));

    if (category != riscv_instr_category_t.SYSTEM) {
      switch(instr_format) {
      case riscv_instr_format_t.CI_FORMAT,
	riscv_instr_format_t.CIW_FORMAT :
	if (instr_name == riscv_instr_name_t.C_NOP)
	  asm_str = "c.nop";
	else if (instr_name == riscv_instr_name_t.C_ADDI16SP)
	  asm_buf = sformat!("%0ssp, %0s")(buf, instr_name_str, get_imm());
	else if (instr_name == riscv_instr_name_t.C_ADDI4SPN)
	  asm_buf = sformat!("%0s%0s, sp, %0s")(buf, instr_name_str, rd, get_imm());
	else if (instr_name.inside(riscv_instr_name_t.C_LDSP, riscv_instr_name_t.C_LWSP,
				   riscv_instr_name_t.C_LQSP))
	  asm_buf = sformat!("%0s%0s, %0s(sp)")(buf, instr_name_str, rd, get_imm());
	else
	  asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rd, get_imm());
	break;
      case riscv_instr_format_t.CL_FORMAT :
	asm_buf = sformat!("%0s%0s, %0s(%0s)")(buf, instr_name_str, rd, get_imm(), rs1);
	break;
      case riscv_instr_format_t.CS_FORMAT:
	if (category == riscv_instr_category_t.STORE)
	  asm_buf = sformat!("%0s%0s, %0s(%0s)")(buf, instr_name_str, rs2, get_imm(), rs1);
	else
	  asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rs1, rs2);
	break;
      case riscv_instr_format_t.CA_FORMAT :
	asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rd, rs2);
	break;
      case riscv_instr_format_t.CB_FORMAT:
	asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rs1, get_imm());
	break;
      case riscv_instr_format_t.CSS_FORMAT:
	if (category == riscv_instr_category_t.STORE)
	  asm_buf = sformat!("%0s%0s, %0s(sp)")(buf, instr_name_str, rs2, get_imm());
	else
	  asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rs2, get_imm());
	break;
      case riscv_instr_format_t.CR_FORMAT:
	if (instr_name.inside(riscv_instr_name_t.C_JR, riscv_instr_name_t.C_JALR)) {
	  asm_buf = sformat!("%0s%0s")(buf, instr_name_str, rs1);
	}
	else {
	  asm_buf = sformat!("%0s%0s, %0s")(buf, instr_name_str, rd, rs2);
	}
	break;
      case riscv_instr_format_t.CJ_FORMAT:
	asm_buf = sformat!("%0s%0s")(buf, instr_name_str, get_imm());
	break;
      default: uvm_info(get_full_name(),
			format("Unsupported format %0s", instr_format), UVM_LOW);
	break; 
      }
    }
    else {
      // For EBREAK,C.EBREAK, making sure pc+4 is a valid instruction boundary
      // This is needed to resume execution from epc+4 after ebreak handling
      if (instr_name == riscv_instr_name_t.C_EBREAK) {
	asm_str = "c.ebreak; c.nop;";
      }
    }

    if (asm_str.length > 0) {
      assert (asm_buf.length == 0);
      buf[0..asm_str.length] = asm_str;
      asm_buf = buf[0..asm_str.length];
    }

    
    if (comment != "") {
      buf[asm_buf.length..asm_buf.length+2] = " #";
      buf[asm_buf.length+2..asm_buf.length+2+comment.length] = comment;
      asm_buf = buf[0..asm_buf.length+2+comment.length];
    }

    toLowerInPlace(asm_buf);

    assert(asm_buf.ptr is buf.ptr);
    return asm_buf;
  }

  // Convert the instruction to assembly code
  override string convert2bin(string prefix = "") {
    string binary;
    switch (instr_name) {
    case riscv_instr_name_t.C_ADDI4SPN :
      binary = format("%4h", (get_func3() ~ cast(ubvec!2) imm[4..6] ~ cast(ubvec!4) imm[6..10] ~
			      imm[2] ~ imm[3] ~ get_c_gpr(rd) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LQ:
      binary = format("%4h", (get_func3() ~ cast(ubvec!2) imm[4..6] ~ imm[8] ~
			      get_c_gpr(rs1) ~ cast(ubvec!2) imm[6..8] ~ get_c_gpr(rd) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LD:
      binary = format("%4h", (get_func3() ~ cast(ubvec!3) imm[3..6] ~ get_c_gpr(rs1) ~
			      cast(ubvec!2) imm[6..8] ~ get_c_gpr(rd) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LW:
      binary = format("%4h", (get_func3() ~ cast(ubvec!3) imm[3..6] ~ get_c_gpr(rs1) ~
			      imm[2] ~ imm[6] ~ get_c_gpr(rd) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SQ:
      binary = format("%4h", (get_func3() ~ cast(ubvec!2) imm[4..6] ~ imm[8] ~
			      get_c_gpr(rs1) ~ cast(ubvec!2) imm[6..8] ~ get_c_gpr(rs2) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SD:
      binary = format("%4h", (get_func3() ~ cast(ubvec!3) imm[3..6] ~ get_c_gpr(rs1) ~
			      cast(ubvec!2) imm[6..8] ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SW:
      binary = format("%4h", (get_func3() ~ cast(ubvec!3) imm[3..6] ~ get_c_gpr(rs1) ~
			      imm[2] ~ imm[6] ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_NOP, riscv_instr_name_t.C_ADDI,
      riscv_instr_name_t.C_LI, riscv_instr_name_t.C_ADDIW:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ cast(ubvec!5) imm[0..5] ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_JAL, riscv_instr_name_t.C_J:
      binary = format("%4h", (get_func3() ~ imm[11] ~ imm[4] ~ cast(ubvec!2) imm[8..10] ~
			      imm[10] ~ imm[6] ~ imm[7] ~ cast(ubvec!3) imm[1..4] ~ imm[5] ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_ADDI16SP:
      binary = format("%4h", (get_func3() ~ imm[9] ~ UBVEC!(5, 0b10) ~
			      imm[4] ~ imm[6] ~ cast(ubvec!2) imm[7..9] ~ imm[5] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LUI:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ cast(ubvec!5) imm[0..5] ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SRLI:
      binary = format("%4h", (get_func3() ~ imm[5] ~ UBVEC!(2, 0b0) ~ get_c_gpr(rd) ~
			      cast(ubvec!5) imm[0..5] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SRLI64:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b0) ~ get_c_gpr(rd) ~ UBVEC!(5, 0b0) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SRAI:
      binary = format("%4h", (get_func3() ~ imm[5] ~ UBVEC!(2, 0b01) ~ get_c_gpr(rd) ~
			      cast(ubvec!5) imm[0..5] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SRAI64:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b001) ~
			      get_c_gpr(rd) ~ UBVEC!(5, 0b0) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_ANDI:
      binary = format("%4h", (get_func3() ~ imm[5] ~ UBVEC!(2, 0b10) ~ get_c_gpr(rd) ~
			      cast(ubvec!5) imm[0..5] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SUB:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b011) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b00) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_XOR:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b011) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b01) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_OR:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b011) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b10) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_AND:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b011) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b11) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SUBW:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b111) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b00) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_ADDW:
      binary = format("%4h", (get_func3() ~ UBVEC!(3, 0b111) ~ get_c_gpr(rd) ~
			      UBVEC!(2, 0b01) ~ get_c_gpr(rs2) ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_BEQZ, riscv_instr_name_t.C_BNEZ:
      binary = format("%4h", (get_func3() ~ imm[8] ~ cast(ubvec!2) imm[3..5] ~
			      get_c_gpr(rs1) ~ cast(ubvec!2) imm[6..8] ~ cast(ubvec!2) imm[1..3] ~
			      imm[5] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SLLI:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ cast(ubvec!5) imm[0..5] ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SLLI64:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b0) ~ rd ~ UBVEC!(5, 0b00000) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LDSP:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ cast(ubvec!2) imm[3..5] ~
			      cast(ubvec!3) imm[6..9] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LQSP:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ imm[4] ~
			      cast(ubvec!4) imm[6..10] ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_LWSP:
      binary = format("%4h", (get_func3() ~ imm[5] ~ rd ~ cast(ubvec!3) imm[2..5] ~
			      cast(ubvec!2) imm[6..8]  ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_JR:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b0) ~ rs1 ~ UBVEC!(5, 0b0) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_MV:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b0) ~ rd ~ rs2 ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_EBREAK:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b1) ~ rs1 ~ UBVEC!(5, 0b0) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_JALR:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b1) ~ UBVEC!(5, 0b0) ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_ADD:
      binary = format("%4h", (get_func3() ~ UBVEC!(1, 0b1) ~ rd ~ rs2 ~
			      get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SDSP:
      binary = format("%4h", (get_func3() ~ cast(ubvec!3) imm[3..6] ~ cast(ubvec!3) imm[6..9]  ~
			      rs2 ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SQSP:
      binary = format("%4h", (get_func3() ~ cast(ubvec!2) imm[4..6] ~ cast(ubvec!4) imm[6..10] ~
			      rs2 ~ get_c_opcode()));
      break;
    case riscv_instr_name_t.C_SWSP:
      binary = format("%4h", (get_func3() ~ cast(ubvec!4) imm[2..6] ~ cast(ubvec!2) imm[6..8] ~
			      rs2 ~ get_c_opcode()));
      break;
    default : uvm_fatal(get_full_name(),
			format("Unsupported instruction %0s", instr_name));
    }
    return prefix ~ binary;
  }

  // Get opcode for compressed instruction
  // ubvec!2  get_c_opcode()
  ubvec!2 get_c_opcode() {
    switch(instr_name) {
    case riscv_instr_name_t.C_ADDI4SPN,
      riscv_instr_name_t.C_LQ,
      riscv_instr_name_t.C_LW,
      riscv_instr_name_t.C_LD,
      riscv_instr_name_t.C_FSD,
      riscv_instr_name_t.C_SQ,
      riscv_instr_name_t.C_SW,
      riscv_instr_name_t.C_SD : return UBVEC!(2, 0b00);
    case riscv_instr_name_t.C_NOP,
      riscv_instr_name_t.C_ADDI,
      riscv_instr_name_t.C_JAL,
      riscv_instr_name_t.C_ADDIW,
      riscv_instr_name_t.C_LI,
      riscv_instr_name_t.C_ADDI16SP,
      riscv_instr_name_t.C_LUI,
      riscv_instr_name_t.C_SRLI,
      riscv_instr_name_t.C_SRLI64,
      riscv_instr_name_t.C_SRAI,
      riscv_instr_name_t.C_SRAI64,
      riscv_instr_name_t.C_ANDI,
      riscv_instr_name_t.C_SUB,
      riscv_instr_name_t.C_XOR,
      riscv_instr_name_t.C_OR,
      riscv_instr_name_t.C_AND,
      riscv_instr_name_t.C_SUBW,
      riscv_instr_name_t.C_ADDW,
      riscv_instr_name_t.C_J,
      riscv_instr_name_t.C_BEQZ,
      riscv_instr_name_t.C_BNEZ : return UBVEC!(2, 0b01);
    case riscv_instr_name_t.C_SLLI,
      riscv_instr_name_t.C_SLLI64,
      riscv_instr_name_t.C_LQSP,
      riscv_instr_name_t.C_LWSP,
      riscv_instr_name_t.C_LDSP,
      riscv_instr_name_t.C_JR,
      riscv_instr_name_t.C_MV,
      riscv_instr_name_t.C_EBREAK,
      riscv_instr_name_t.C_JALR,
      riscv_instr_name_t.C_ADD,
      riscv_instr_name_t.C_SQSP,
      riscv_instr_name_t.C_SWSP,
      riscv_instr_name_t.C_SDSP : return UBVEC!(2, 0b10);
    default :
      uvm_fatal(get_full_name(), format("Unsupported instruction %0s", instr_name));
      assert (false);
    }
  }

  //ubvec!3 get_func3()
  override ubvec!3 get_func3() {
    switch(instr_name) {
    case riscv_instr_name_t.C_ADDI4SPN : return UBVEC!(3, 0b000);
    case riscv_instr_name_t.C_LQ       : return UBVEC!(3, 0b001);
    case riscv_instr_name_t.C_LW       : return UBVEC!(3, 0b010);
    case riscv_instr_name_t.C_LD       : return UBVEC!(3, 0b011);
    case riscv_instr_name_t.C_SQ       : return UBVEC!(3, 0b101);
    case riscv_instr_name_t.C_SW       : return UBVEC!(3, 0b110);
    case riscv_instr_name_t.C_SD       : return UBVEC!(3, 0b111);
    case riscv_instr_name_t.C_NOP      : return UBVEC!(3, 0b000);
    case riscv_instr_name_t.C_ADDI     : return UBVEC!(3, 0b000);
    case riscv_instr_name_t.C_JAL      : return UBVEC!(3, 0b001);
    case riscv_instr_name_t.C_ADDIW    : return UBVEC!(3, 0b001);
    case riscv_instr_name_t.C_LI       : return UBVEC!(3, 0b010);
    case riscv_instr_name_t.C_ADDI16SP : return UBVEC!(3, 0b011);
    case riscv_instr_name_t.C_LUI      : return UBVEC!(3, 0b011);
    case riscv_instr_name_t.C_SRLI     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SRLI64   : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SRAI     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SRAI64   : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_ANDI     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SUB      : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_XOR      : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_OR       : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_AND      : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SUBW     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_ADDW     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_J        : return UBVEC!(3, 0b101);
    case riscv_instr_name_t.C_BEQZ     : return UBVEC!(3, 0b110);
    case riscv_instr_name_t.C_BNEZ     : return UBVEC!(3, 0b111);
    case riscv_instr_name_t.C_SLLI     : return UBVEC!(3, 0b000);
    case riscv_instr_name_t.C_SLLI64   : return UBVEC!(3, 0b000);
    case riscv_instr_name_t.C_LQSP     : return UBVEC!(3, 0b001);
    case riscv_instr_name_t.C_LWSP     : return UBVEC!(3, 0b010);
    case riscv_instr_name_t.C_LDSP     : return UBVEC!(3, 0b011);
    case riscv_instr_name_t.C_JR       : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_MV       : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_EBREAK   : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_JALR     : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_ADD      : return UBVEC!(3, 0b100);
    case riscv_instr_name_t.C_SQSP     : return UBVEC!(3, 0b101);
    case riscv_instr_name_t.C_SWSP     : return UBVEC!(3, 0b110);
    case riscv_instr_name_t.C_SDSP     : return UBVEC!(3, 0b111);
    default : uvm_fatal(get_full_name(), format("Unsupported instruction %0s", instr_name));
      assert (false);
    }
  }
}
