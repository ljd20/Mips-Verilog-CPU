import codes::*;

module alu (
    input logic clk,

    input opcode_t opcode_i,
    input func_t   funct_i,

    input logic [31:0] rs_i,
    input logic [31:0] rt_i,
    input logic [15:0] immediate_i,

    output logic [31:0] rd_o,
    output logic [31:0] rt_o,

    output logic [31:0] mfhi_o,
    output logic [31:0] mflo_o,
    output logic stall_o
);

  logic [63:0] mf_d;
  logic [63:0] mf_q;

  assign mfhi_o = mf_q[63:32];
  assign mflo_o = mf_q[31:0];

  function [31:0] signextend16to32(input [15:0] x);
    begin
      return (x >> 15) == 1 ? {16'b1, x} : {16'b0, x};
    end
  endfunction

  function [31:0] zeroextend16to32(input [15:0] x);
    begin
      return {16'b0, x};
    end
  endfunction

  logic [31:0] sign_extended_imm;
  logic [31:0] zero_extended_imm;

  assign sign_extended_imm = signextend16to32(immediate_i);
  assign zero_extended_imm = zeroextend16to32(immediate_i);

  logic [4:0] static_shift_amount;
  assign static_shift_amount = immediate_i[10:6];

  // Used for variable length shifts (register specified).
  // Obtained from the lower 5 bits of rs.
  logic [4:0] variable_shift_amount;
  assign variable_shift_amount = rs_i[4:0];

  // TODO: Remove this when DIV and DIVU are implemented.
  assign stall_o = 0;

  always_comb begin
    case (opcode_i)
      OP_SPECIAL: begin
        case (funct_i)
          FUNC_SLL:  rd_o = rt_i << static_shift_amount;
          FUNC_SRL:  rd_o = rt_i >> static_shift_amount;
          FUNC_SRA:  rd_o = rt_i >>> static_shift_amount;
          FUNC_SLLV: rd_o = rt_i << variable_shift_amount;
          FUNC_SRLV: rd_o = rt_i >> variable_shift_amount;
          FUNC_SRAV: rd_o = rt_i >>> variable_shift_amount;
          FUNC_ADD: begin
            // TODO: fire exception on overflow
            rd_o = rs_i + rt_i;
          end
          FUNC_ADDU: rd_o = rs_i + rt_i;
          FUNC_SUB: begin
            // TODO: fire exception on overflow
            rd_o = rs_i - rt_i;
          end
          FUNC_SUBU: rd_o = rs_i - rt_i;
          FUNC_AND:  rd_o = rs_i & rt_i;
          FUNC_OR:   rd_o = rs_i | rt_i;
          FUNC_XOR:  rd_o = rs_i ^ rt_i;
          FUNC_NOR:  rd_o = rs_i~|rt_i;
          FUNC_MULT: begin
            mf_d = $signed(rs_i) * $signed(rt_i);
          end
          FUNC_MULTU: begin
            mf_d = rs_i * rt_i;
          end
          FUNC_DIV: begin
            $fatal(1, "DIV instruction not implemented");
          end
          FUNC_DIVU: begin
            $fatal(1, "DIVU instruction not implemented");
          end
        endcase
      end
      OP_ADDI: begin
        // TODO: fire exception on overflow
        rt_o = rs_i + sign_extended_imm;
      end
      OP_ADDIU: rt_o = rs_i + sign_extended_imm;
      OP_SLTI: begin
        if ($signed(rs_i) < $signed(sign_extended_imm)) begin
          rt_o = 1;
        end else begin
          rt_o = 0;
        end
      end
      OP_SLTIU: begin
        // TODO: check the sign extension on this
        if (rs_i < sign_extended_imm) begin
          rt_o = 1;
        end else begin
          rt_o = 0;
        end
      end
      OP_ANDI:  rt_o = rs_i & zero_extended_imm;
      OP_ORI:   rt_o = rs_i | zero_extended_imm;
      OP_XORI:  rt_o = rs_i ^ zero_extended_imm;
      // TODO: LUI mentions something about sign extension but that doesn't make sense in this context.
      OP_LUI:   rt_o = {immediate_i << 16, 16'b0};
    endcase
  end

  always_ff @(posedge clk) begin
    if (opcode_i == OP_SPECIAL) begin
      if (funct_i == FUNC_MULT || funct_i == FUNC_MULTU) begin
        mf_q <= mf_d;
      end
    end
  end

endmodule