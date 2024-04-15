import json
import os
from pathlib import Path
import re
import sys
import subprocess 
import shlex
import tempfile
from typing import List, Tuple

# Path to the forves executable
forves_exec = Path("forves-checker")
include_identical = False


def run_command(cmd):
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE,
                              stderr=FNULL)
    return solc_p.communicate()[0].decode()


#
#
bytecode_vocab = ['ADD', 'MUL', 'NOT', 'SUB', 'DIV', 'SDIV', 'MOD', 'SMOD', 'ADDMOD', 'MULMOD', 'EXP', 'SIGNEXTEND',
                  'LT', 'GT', 'SLT', 'SGT', 'EQ', 'ISZERO', 'AND', 'OR', 'XOR', 'BYTE', 'SHL', 'SHR', 'SAR', 'SHA3',
                  'KECCAK256', 'ADDRESS', 'BALANCE', 'ORIGIN', 'CALLER', 'CALLVALUE', 'CALLDATALOAD', 'CALLDATASIZE ',
                  'CODESIZE', 'GASPRICE', 'EXTCODESIZE', 'RETURNDATASIZE', 'EXTCODEHASH', 'BLOCKHASH', 'COINBASE',
                  'TIMESTAMP', 'NUMBER', 'DIFFICULTY', 'GASLIMIT', 'CHAINID', 'SELFBALANCE', 'BASEFEE', 'SLOAD',
                  'MLOAD', 'MSTORE', 'MSTORE8', 'SSTORE', 'PC', 'MSIZE', 'GAS', 'CREATE', 'CREATE2', 'CALLDATASIZE',
                  'CALLDATALOAD', 'JUMPI', 'JUMPDEST', 'METAPUSH', 'PREVRANDAO',
                  'POP',
                  'DUP1', 'DUP2', 'DUP3', 'DUP4', 'DUP5', 'DUP6', 'DUP7', 'DUP8', 'DUP9', 'DUP10', 'DUP11', 'DUP12',
                  'DUP13', 'DUP14', 'DUP15', 'DUP16',
                  'SWAP1', 'SWAP2', 'SWAP3', 'SWAP4', 'SWAP5', 'SWAP6', 'SWAP7', 'SWAP8', 'SWAP9', 'SWAP10', 'SWAP11',
                  'SWAP12', 'SWAP13', 'SWAP14', 'SWAP15', 'SWAP16',
                  ]


#
#
def is_pseudo_keyword(opcode: str) -> bool:
    if opcode.find("tag") == -1 and opcode.find("#") == -1 and opcode.find("$") == -1 \
            and opcode.find("data") == -1:
        return False
    else:
        return True


def keyword_to_id(keyword):
    if keyword == "PUSHDEPLOYADDRESS":
        return 0
    elif keyword == "PUSHSIZE":
        return 1
    elif keyword == "PUSHLIB":
        return 2
    elif keyword == "PUSHIMMUTABLE":
        return 3
    elif keyword == "data":
        return 4
    elif keyword == "[tag]":
        return 5
    elif keyword == "[$]":
        return 6
    elif keyword == "#[$]":
        return 7
    else:
        raise Exception(f'uknown meta push keyword: {keyword}')


def split_bytecode(raw_instruction_str: str) -> List[str]:
    ops = raw_instruction_str.split(' ')
    opcodes = []
    i = 0
    operand = None
    meta_operand = None
    while i < len(ops):
        op = ops[i]

        # JUMPDEST is removed from the block - later maybe we should support
        if op.startswith("JUMPDEST"):
            i += 1

        # In theory, they should not appear inside a block, as they are removed beforehand.
        # Nevertheless, we include them just in case
        elif op.startswith("ASSIGNIMMUTABLE") or op.startswith("tag"):
            opcodes.append(op)
            i += 1

        # if it does not start with PUSH, then its an opcode with no operands
        elif not op.startswith("PUSH"):
            final_op = op

        # op starts with PUSH
        else:
            # Just in case PUSHx instructions are included, we translate them to "PUSH x" name instead
            if re.fullmatch("PUSH([0-9]+)", op) is not None:
                final_op = op
                operand = f'0x{ops[i + 1]}'
                i = i + 1
            elif op == "PUSHDEPLOYADDRESS" or op == "PUSHSIZE":
                final_op = "METAPUSH"
                meta_operand = f'{keyword_to_id(op)}'
                operand = f'0x0'
            elif op == "PUSHLIB" or op == "PUSHIMMUTABLE":
                final_op = "METAPUSH"
                meta_operand = f'{keyword_to_id(op)}'
                operand = f'0x{ops[i + 1]}'
                i = i + 1
            #            elif op == "PUSH" and ops[i+1] == "[tag]":  # splitted fom the next case due to a bug in PUSH [tag]
            #                final_op = "METAPUSH"
            #                meta_operand = f'{keyword_to_id(ops[i+1])}'
            #                operand = f'0x0'
            #                i = i + 2
            elif op == "PUSH" and is_pseudo_keyword(ops[i + 1]):
                final_op = "METAPUSH"
                meta_operand = f'{keyword_to_id(ops[i + 1])}'
                operand = f'0x{ops[i + 2]}'
                i = i + 2
            # A  PUSH 
            elif op == "PUSH":
                n = (len(ops[i + 1]) + 1) // 2
                assert n >= 1 and n <= 32
                final_op = f'PUSH{n}'
                operand = f'0x{ops[i + 1]}'
                i = i + 1

            # Something that we don't handle, will just leave it and an exception will be thrown    
            else:
                raise Exception("...")

        opcodes.append(final_op)
        if meta_operand is not None:
            opcodes.append(meta_operand)
            meta_operand = None
        if operand is not None:
            opcodes.append(operand)
            operand = None

        i += 1

    return opcodes


def bin_to_word(b: str):
    word = 'WO'
    for d in b:
        if d == '0':
            word = f'(WS false {word})'
        else:
            word = f'(WS true {word})'
    return word


def encode_num(n_hex: str):
    return f'(NToWord WLen {n_hex}%N)'


def str_to_list(bytecode_str):
    bytecode_seq = split_bytecode(bytecode_str)
    n = len(bytecode_seq)
    if n == 0:
        raise Exception("zero length")

    out_seq = []
    i = 0
    while i < n:
        instr = bytecode_seq[i]
        if re.fullmatch("PUSH([0-9]+)", instr) is not None:
            out_seq.append(bytecode_seq[i])
            out_seq.append(bytecode_seq[i + 1])
            i = i + 2
        elif instr == "METAPUSH":
            out_seq.append(bytecode_seq[i])
            out_seq.append(bytecode_seq[i + 1])
            out_seq.append(bytecode_seq[i + 2])
            i = i + 3
        else:
            idx = bytecode_vocab.index(instr)  # just check the instruction is supported
            out_seq.append(instr)
            i = i + 1

    return out_seq


def forves_format(bstr1, bstr2, i=0, contract=""):
    try:
        bytecode_as_list = str_to_list(bstr1)
        opt_bytecode_as_list = str_to_list(bstr2)

        bytecode = ' '.join(bytecode_as_list)
        opt_bytecode = ' '.join(opt_bytecode_as_list)
        stack_size = 500

        return f'# Smart contract {contract}\n# Block {i}\n{opt_bytecode}\n{bytecode}\n{stack_size}\n\n'
    except Exception as e:
        print(f'>>>> {e}',file=sys.stderr)
        return ""

def compare_forves(previous_block: str, new_solution: str, criteria: str = "size", enabled: bool = True):
    if not enabled:
        return "disabled"

    # Check if the bin for forves is present
    if not forves_exec.exists():
        raise ValueError("Forves-checker is not found in the specified path")

    criteria_flag = "all" if criteria == "gas" else "all_size"
    fd, tmp_file = tempfile.mkstemp()

    with open(tmp_file, 'w') as f:
        forves_input = forves_format(previous_block, new_solution)
        f.write(forves_input)

    command = f"./{forves_exec} -i {tmp_file} " \
              f"-opt_rep 20 -pipeline_rep 20 -opt {criteria_flag} -mu basic -su basic -ms basic -ss basic " \
              f"-ssv_c basic -mem_c po -strg_c po -sha3_c trivial "

    output = run_command(command)

    os.close(fd)
    os.remove(tmp_file)

    if "false" in output:
        return "false"
    elif "parsing error" in output:
        return "parsing"
    elif "true" in output:
        return "true"
    else:
        raise ValueError("Not recognized option in output:", output)


def verify_output_minizinc(initial_seq_plain: str, optimized_seq_plain: str):
    """
    There are three possible outcomes: false, true and parsing (if there is a parsing error)
    """
    return compare_forves(initial_seq_plain, optimized_seq_plain)