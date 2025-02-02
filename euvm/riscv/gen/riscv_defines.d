/*
 * Copyright 2018 Google LLC
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

module riscv.gen.riscv_defines;
import riscv.gen.riscv_opcodes_pkg;

public import riscv.gen.riscv_instr_pkg: riscv_instr_name_t, riscv_instr_group_t,
  riscv_instr_category_t, riscv_instr_format_t, va_variant_t, imm_t;

mixin(declareEnums!riscv_instr_name_t());
mixin(declareEnums!riscv_instr_group_t());
mixin(declareEnums!riscv_instr_category_t());
mixin(declareEnums!riscv_instr_format_t());
mixin(declareEnums!va_variant_t());
mixin(declareEnums!imm_t());


public import riscv.gen.isa.riscv_instr: riscv_instr;
public import riscv.gen.isa.riscv_csr_instr: riscv_csr_instr;
public import riscv.gen.isa.riscv_floating_point_instr: riscv_floating_point_instr;
public import riscv.gen.isa.riscv_compressed_instr: riscv_compressed_instr;
public import riscv.gen.isa.riscv_amo_instr: riscv_amo_instr;
public import riscv.gen.isa.riscv_b_instr: riscv_b_instr;
public import riscv.gen.isa.riscv_vector_instr: riscv_vector_instr;
public import riscv.gen.isa.custom.riscv_custom_instr: riscv_custom_instr;

public import riscv.gen.isa.riscv_zba_instr: riscv_zba_instr;
public import riscv.gen.isa.riscv_zbb_instr: riscv_zbb_instr;
public import riscv.gen.isa.riscv_zbc_instr: riscv_zbc_instr;
public import riscv.gen.isa.riscv_zbs_instr: riscv_zbs_instr;

// enum aliases

static string declareEnums (alias E)()
{
  import std.traits;
  import std.conv;
  string res;

  foreach(e; __traits(allMembers, E))
    {
      res ~= "enum " ~ E.stringof ~ " " ~ e ~ " = " ~
	E.stringof ~ "." ~ e ~ ";\n";
    }
  return res;
}

string riscv_instr_mixin_tmpl(BASE_TYPE)(riscv_instr_name_t instr_name,
					 riscv_instr_format_t instr_format,
					 riscv_instr_category_t instr_category,
					 riscv_instr_group_t instr_group,
					 imm_t imm_tp = imm_t.IMM) {
  import std.conv: to;
  string class_str = "class riscv_" ~ instr_name.to!string() ~ "_instr: " ~ BASE_TYPE.stringof;
  class_str ~= "\n{\n";
  class_str ~= "  enum riscv_instr_name_t RISCV_INSTR_NAME_T = \n";
  class_str ~= "       riscv_instr_name_t." ~ instr_name.to!string() ~ ";\n";
  class_str ~= "  mixin uvm_object_utils;\n";
  class_str ~= "  this(string name = \"\") {\n";
  class_str ~= "    super(name);\n";
  class_str ~= "    this.instr_name = riscv_instr_name_t." ~ instr_name.to!string() ~ ";\n";
  class_str ~= "    this.instr_format = riscv_instr_format_t." ~ instr_format.to!string() ~ ";\n";
  class_str ~= "    this.group = riscv_instr_group_t." ~ instr_group.to!string() ~ ";\n";
  class_str ~= "    this.category = riscv_instr_category_t." ~ instr_category.to!string() ~ ";\n";
  class_str ~= "    this.imm_type = imm_t." ~ imm_tp.to!string() ~ ";\n";
  class_str ~= "    set_imm_len();\n";
  class_str ~= "    set_rand_mode();\n";
  class_str ~= "  }\n";
  class_str ~= "}\n";
  return class_str;
}

string riscv_va_instr_mixin_tmpl(BASE_TYPE)(riscv_instr_name_t instr_name,
					    riscv_instr_format_t instr_format,
					    riscv_instr_category_t instr_category,
					    riscv_instr_group_t instr_group,
					    va_variant_t[] vavs = [],
					    string ext = "") {
  import std.conv: to;
  string class_str = "class riscv_" ~ instr_name.to!string() ~ "_instr: " ~ BASE_TYPE.stringof;
  class_str ~= "\n{\n";
  class_str ~= "  enum riscv_instr_name_t RISCV_INSTR_NAME_T = \n";
  class_str ~= "       riscv_instr_name_t." ~ instr_name.to!string() ~ ";\n";
  class_str ~= "  mixin uvm_object_utils;\n";
  class_str ~= "  this(string name = \"\") {\n";
  class_str ~= "    super(name);\n";
  class_str ~= "    this.instr_name = riscv_instr_name_t." ~ instr_name.to!string() ~ ";\n";
  class_str ~= "    this.instr_format = riscv_instr_format_t." ~ instr_format.to!string() ~ ";\n";
  class_str ~= "    this.group = riscv_instr_group_t." ~ instr_group.to!string() ~ ";\n";
  class_str ~= "    this.category = riscv_instr_category_t." ~ instr_category.to!string() ~ ";\n";
  class_str ~= "    this.imm_type = imm_t.IMM;\n";
  class_str ~= "    this.allowed_va_variants = [";
  foreach (vav; vavs) {
    class_str ~= "       va_variant_t." ~ vav.to!string() ~ ",\n";
  }
  class_str ~= "    ];\n";
  class_str ~= "    this.sub_extension = \"" ~ ext ~ "\";\n";
  class_str ~= "    set_imm_len();\n";
  class_str ~= "    set_rand_mode();\n";
  class_str ~= "  }\n";
  class_str ~= "}\n";
  return class_str;
}

// class RISCV_INSTR_TMPL(riscv_instr_name_t instr_n,
// 		       riscv_instr_format_t instr_format,
// 		       riscv_instr_category_t instr_category,
// 		       riscv_instr_group_t instr_group,
// 		       imm_t imm_tp,
// 		       BASE_TYPE): BASE_TYPE
// {
//   enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
//   mixin uvm_object_utils;
//   this(string name="") {
//     super(name);
//     this.instr_name = instr_n;
//     this.instr_format = instr_format;
//     this.group = instr_group;
//     this.category = instr_category;
//     this.imm_type = imm_tp;
//     set_imm_len();
//     set_rand_mode();
//   }
// }

void print_class_info(T)(T inst) {
  static if (is (T B == super)) {
    // pragma(msg, B.stringof);
    import std.stdio: writeln;
    writeln("Randomized ", B[0].stringof);
  }
}

// string riscv_instr_var_return_mixin(riscv_instr_var_t VAR) {
//   import std.format: format;
//   return format("return _%s;\n", VAR);
// }

string riscv_instr_var_mixin(riscv_instr_var_t[] vars)
{
  import std.format: format;
  string var_decls;
  foreach (var; vars) {
    riscv_instr_var_params_s params = riscv_instr_var_params[var];
    assert (params._arg == var);
    var_decls ~= (format("@rand ubvec!%s _%s;\n",
			 params._msb - params._lsb, var));
  }
  return var_decls;
}

mixin template RISCV_INSTR_MIXIN(riscv_instr_name_t instr_n,
				 riscv_instr_format_t instr_format,
				 riscv_instr_category_t instr_category,
				 riscv_instr_group_t instr_group,
				 imm_t imm_tp=imm_t.IMM)
{
  import riscv.gen.riscv_opcodes_pkg;
  import esdl: rand, ubvec;

  static bool hasReg(riscv_instr_var_t r, riscv_instr_var_t[] vars) {
    foreach (var; vars) if (var is r) return true;
      else continue;
    return false;
  }

  static bool hasReg(riscv_instr_var_t[] regs, riscv_instr_var_t[] vars) {
    foreach (r; regs) if (hasReg(r, vars)) return true;
      else continue;
    return false;
  }

  auto get_var_value(riscv_instr_var_t VAR)() {
    import std.format: format;
    return __traits(getMember, this, format("_%s", VAR));
  }

  void fill_var_val(riscv_instr_var_t[] VL)(ref ubvec!32 match) {
    static if (VL.length == 0) return;
    else {
      enum VAR = VL[0];
      enum lsb = riscv_instr_var_params[VAR]._lsb;
      enum msb = riscv_instr_var_params[VAR]._msb;
      // pragma(msg, "lsb: ", lsb, ", msb: ", msb);
      match[lsb..msb] = get_var_value!VAR;
      fill_var_val!(VL[1..$])(match);
    }
  }

  override ubvec!32 get_bin() {
    enum params = riscv_instr_params[instr_n];
    ubvec!32 mask = params._mask;
    ubvec!32 match = params._match;

    ubvec!32 retval = match;
    
    
    enum var_list = params._var_list;

    fill_var_val!(var_list)(retval);
    
    return retval;
  }

  // static if (hasReg(riscv_instr_var_t.rs1)) {
  //   @rand ubvec!5 rs1;
  // }

  
  enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
  // enum RISCV_INSTR_VAR_T = riscv_opcode_params_list[instr_n]._var_t;
  // pragma (msg, riscv_opcode_params_list[instr_n]);
  // enum RISCV_VAR = riscv_instr_variables[instr_n];
  // enum HAS_RS1 = hasReg(riscv_instr_var_t.rs1, RISCV_VAR);

  enum RISCV_PARAMS = riscv_instr_params[instr_n];
  static assert (RISCV_PARAMS._name == instr_n);
  enum HAS_RS1 = hasReg(riscv_instr_var_t.rs1, RISCV_PARAMS._var_list);

  // pragma(msg, riscv_instr_var_mixin(RISCV_PARAMS._var_list));
  mixin(riscv_instr_var_mixin(RISCV_PARAMS._var_list));

  // pragma(msg, instr_n.stringof ~ " " ~ HAS_RS1.stringof);
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
    this.instr_name = instr_n;
    this.instr_format = instr_format;
    this.group = instr_group;
    this.category = instr_category;
    this.imm_type = imm_tp;
    set_imm_len();
    set_rand_mode();
  }

  // override void post_randomize() {
  //   print_class_info(this);
  // }

  static if (instr_n == riscv_instr_name_t.SLLIW ||
	     instr_n == riscv_instr_name_t.SRLIW ||
	     instr_n == riscv_instr_name_t.SRAIW) {
    import esdl.rand: constraint;
    constraint!q{
      imm[5..12] == 0;
    } imm_sw_cstr;
  }

  static if (instr_n == riscv_instr_name_t.SLLI ||
	     instr_n == riscv_instr_name_t.SRLI ||
	     instr_n == riscv_instr_name_t.SRAI) {
    import riscv.gen.target: XLEN;
    import esdl.rand: constraint;
    static if (XLEN) {
      constraint!q{
	imm[5..12] == 0;
      }  imm_s_cstr;
    }
    else {
    import esdl.rand: constraint;
      constraint!q{
	imm[6:0] == 0;
      } imm_s_cstr;
    }
  }

}

mixin template RISCV_C_INSTR_MIXIN(riscv_instr_name_t instr_n,
				   riscv_instr_format_t instr_format,
				   riscv_instr_category_t instr_category,
				   riscv_instr_group_t instr_group,
				   imm_t imm_tp=imm_t.IMM)
{
  import riscv.gen.riscv_opcodes_pkg;
  import esdl.rand: constraint;
  import riscv.gen.riscv_instr_pkg: riscv_reg_t;

  static bool hasReg(riscv_instr_var_t r, riscv_instr_var_t[] vars) {
    foreach (var; vars) if (var is r) return true;
      else continue;
    return false;
  }

  static bool hasReg(riscv_instr_var_t[] regs, riscv_instr_var_t[] vars) {
    foreach (r; regs) if (hasReg(r, vars)) return true;
      else continue;
    return false;
  }

  enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
  // enum RISCV_INSTR_VAR_T = riscv_opcode_params_list[instr_n]._var_t;
  // pragma (msg, riscv_opcode_params_list[instr_n]);
  // enum RISCV_VAR = riscv_instr_variables[instr_n];
  // enum HAS_RS1 = hasReg(riscv_instr_var_t.rs1, RISCV_VAR);

  enum RISCV_PARAMS = riscv_instr_params[instr_n];
  static assert (RISCV_PARAMS._name == instr_n);
  enum HAS_RS1 = hasReg(riscv_instr_var_t.rs1, RISCV_PARAMS._var_list);

  // pragma(msg, instr_n.stringof ~ " " ~ HAS_RS1.stringof);
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
    this.instr_name = instr_n;
    this.instr_format = instr_format;
    this.group = instr_group;
    this.category = instr_category;
    this.imm_type = imm_tp;
    set_imm_len();
    set_rand_mode();
  }

  // override void post_randomize() {
  //   print_class_info(this);
  // }

  static if (imm_tp == imm_t.NZIMM || imm_tp == imm_t.NZUIMM) {
    constraint! q{
      imm[0..6] != 0;
    } c_imm_val_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_LUI) {
    // TODO(taliu) Check why bit 6 cannot be zero
    constraint! q{
      imm[5..32] == 0;
    } c_lui_imm_val_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_SRAI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_SRLI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_SLLI) {
    constraint! q{
      imm[5..32] == 0;
    } c_sh_imm_val_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_ADDI4SPN) {
    constraint! q{
      imm[0..2] == 0;
    } imm_addi4spn_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_ADDI16SP) {
    constraint! q{
      rd  == riscv_reg_t.SP;
    } c_addi16sp_sp_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_JR ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_JALR) {
    constraint! q{
      rs2 == riscv_reg_t.ZERO;
      rs1 != riscv_reg_t.ZERO;
    } c_j_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_ADDI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_ADDIW ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_LI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_LUI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_SLLI ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_SLLI64 ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_LQSP ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_LDSP ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_MV ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_ADD ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_LWSP) {
    constraint! q{
      rd != riscv_reg_t.ZERO;
    } c_rdn0_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_JR) {
    constraint! q{
      rs1 != riscv_reg_t.ZERO;
    } c_rs1n0_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_ADD ||
	     RISCV_INSTR_NAME == riscv_instr_name_t.C_MV) {
    constraint! q{
      rs2 != riscv_reg_t.ZERO;
    } c_rs2n0_cst;
  }

  static if (RISCV_INSTR_NAME == riscv_instr_name_t.C_LUI) {
    constraint! q{
      rd != riscv_reg_t.SP;
    } c_rdnsp_cst;
  }
  
  static if (hasReg(riscv_instr_var_t.rs1_p, RISCV_PARAMS._var_list) ||
	     hasReg(riscv_instr_var_t.rd_rs1_p, RISCV_PARAMS._var_list) ||
	     hasReg(riscv_instr_var_t.c_sreg1, RISCV_PARAMS._var_list)) {
    constraint! q{
      rs1 inside [riscv_reg_t.S0:riscv_reg_t.A5];
    } c_rs1_cst;
  }

  static if (hasReg(riscv_instr_var_t.rs2_p, RISCV_PARAMS._var_list) ||
	     hasReg(riscv_instr_var_t.c_sreg2, RISCV_PARAMS._var_list)) {
    constraint! q{
      rs2 inside [riscv_reg_t.S0:riscv_reg_t.A5];
    } c_rs2_cst;
  }

  static if (hasReg(riscv_instr_var_t.rd_p, RISCV_PARAMS._var_list) ||
	     hasReg(riscv_instr_var_t.rd_rs1_p, RISCV_PARAMS._var_list)) {
    constraint! q{
      rd inside [riscv_reg_t.S0:riscv_reg_t.A5];
    } c_rd_cst;
  }

  
  


}
// class RISCV_VA_INSTR_TMPL(string ext, riscv_instr_name_t instr_n,
// 			  riscv_instr_format_t instr_format,
// 			  riscv_instr_category_t instr_category,
// 			  riscv_instr_group_t instr_group,
// 			  imm_t imm_tp,
// 			  BASE_TYPE,
// 			  vav...): BASE_TYPE
// {
//   enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
//   mixin uvm_object_utils;
//   this(string name="") {
//     super(name);
//     this.instr_name = instr_n;
//     this.instr_format = instr_format;
//     this.group = instr_group;
//     this.category = instr_category;
//     this.imm_type = imm_tp;
//     this.allowed_va_variants = [vav];
//     this.sub_extension = ext;
//     set_imm_len();
//     set_rand_mode();
//   }
// }

mixin template RISCV_VA_INSTR_MIXIN(string ext, riscv_instr_name_t instr_n,
				    riscv_instr_format_t instr_format,
				    riscv_instr_category_t instr_category,
				    riscv_instr_group_t instr_group)
{
  enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
    this.instr_name = instr_n;
    this.instr_format = instr_format;
    this.group = instr_group;
    this.category = instr_category;
    this.imm_type = imm_t.IMM;
    this.allowed_va_variants = [];
    this.sub_extension = ext;
    set_imm_len();
    set_rand_mode();
  }
  override void post_randomize() {
    print_class_info(this);
  }

}

mixin template RISCV_VA_INSTR_MIXIN(riscv_instr_name_t instr_n,
				    riscv_instr_format_t instr_format,
				    riscv_instr_category_t instr_category,
				    riscv_instr_group_t instr_group)
{
  enum riscv_instr_name_t RISCV_INSTR_NAME = instr_n;
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
    this.instr_name = instr_n;
    this.instr_format = instr_format;
    this.group = instr_group;
    this.category = instr_category;
    this.imm_type = imm_t.IMM;
    this.allowed_va_variants = [];
    this.sub_extension = "";
    set_imm_len();
    set_rand_mode();
  }
  override void post_randomize() {
    print_class_info(this);
  }

}

alias riscv_instr_mixin = riscv_instr_mixin_tmpl!riscv_instr;

// alias RISCV_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		  riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		  imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_instr);

// alias RISCV_CSR_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		  riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		  imm_t imm_tp = imm_t.IMM) =
//   RISCV_CSR_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_csr_instr);

// alias riscv_csr_instr_mixin = riscv_instr_mixin_tmpl!riscv_csr_instr;

// alias riscv_fp_instr_mixin = riscv_instr_mixin_tmpl!riscv_floating_point_instr;

// alias RISCV_FP_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		     riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		     imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_floating_point_instr);

// alias riscv_amo_instr_mixin = riscv_instr_mixin_tmpl!riscv_amo_instr;

// alias RISCV_AMO_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		      riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		      imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_amo_instr);

// alias riscv_c_instr_mixin = riscv_instr_mixin_tmpl!riscv_compressed_instr;

// alias RISCV_C_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		    riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		    imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_compressed_instr);

// alias riscv_fc_instr_mixin = riscv_instr_mixin_tmpl!riscv_floating_point_instr;

// alias RISCV_FC_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		     riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		     imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_floating_point_instr);

// alias riscv_va_instr_mixin = riscv_va_instr_mixin_tmpl!riscv_vector_instr;

// alias RISCV_VA_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		     riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		     vav...) =
//   RISCV_VA_INSTR_TMPL!("", instr_n, instr_format, instr_category, instr_group, imm_t.IMM,
// 		       riscv_vector_instr, vav);

// alias RISCV_VA_INSTR(string ext, riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		     riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		     vav...) =
//   RISCV_VA_INSTR_TMPL!(ext, instr_n, instr_format, instr_category, instr_group, imm_t.IMM,
// 		       riscv_vector_instr, vav);

// alias riscv_custom_instr_mixin = riscv_instr_mixin_tmpl!riscv_custom_instr;

// alias RISCV_CUSTOM_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 			 riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 			 imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_custom_instr);

// alias riscv_b_instr_mixin = riscv_instr_mixin_tmpl!riscv_b_instr;

// alias RISCV_B_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		    riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		    imm_t imm_tp = imm_t.IMM) =
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_b_instr);

// //Zba-extension instruction
// alias riscv_zba_instr_mixin = riscv_instr_mixin_tmpl!riscv_zba_instr;

// alias RISCV_ZBA_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		      riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		      imm_t imm_tp = imm_t.IMM)	=
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_zba_instr);

// //Zbb-extension instruction
// alias riscv_zbb_instr_mixin = riscv_instr_mixin_tmpl!riscv_zbb_instr;

// alias RISCV_ZBB_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		      riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		      imm_t imm_tp = imm_t.IMM)	=
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_zbb_instr);

// //Zbc-extension instruction
// alias riscv_zbc_instr_mixin = riscv_instr_mixin_tmpl!riscv_zbc_instr;

// alias RISCV_ZBC_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		      riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		      imm_t imm_tp = imm_t.IMM)	=
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_zbc_instr);

// //Zbs-extension instruction
// alias riscv_zbs_instr_mixin = riscv_instr_mixin_tmpl!riscv_zbs_instr;

// alias RISCV_ZBS_INSTR(riscv_instr_name_t instr_n, riscv_instr_format_t instr_format,
// 		      riscv_instr_category_t instr_category, riscv_instr_group_t instr_group,
// 		      imm_t imm_tp = imm_t.IMM)	=
//   RISCV_INSTR_TMPL!(instr_n, instr_format, instr_category, instr_group, imm_tp,
// 		    riscv_zbs_instr)
  ;
