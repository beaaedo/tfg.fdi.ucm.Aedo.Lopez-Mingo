import re
import json
import sys
import argparse
import pandas as pd
from pathlib import Path
from glob import glob
from asm_block import AsmBlock, generate_block_from_plain_instructions
from asm_bytecode import AsmBytecode
from typing import List, Dict, Any, Tuple
# from verify_solution import verify_output_minizinc
from dzn_generation import asociatividad
from verify_solution_simple_checker import SymbolicChecker
from evm_statistics import generate_statistics_info

### Methods to transform a sequence of ids to AsmBytecode

def id_to_asm_bytecode(uf_instrs: Dict[str, Dict[str, Any]], instr_id: str) -> List[AsmBytecode]:
    # AsmBytecode(-1, -1, -1, , )
    if instr_id in uf_instrs:
        associated_instr = uf_instrs[instr_id]

        # Special case: reconstructing PUSH0 (see sfs_generator/parser_asm.py)
        if associated_instr["disasm"] == "PUSH0":
            return [AsmBytecode(-1, -1, -1, "PUSH", "0")]
        
        # Special PUSH cases that were transformed to decimal are analyzed separately
        elif associated_instr['disasm'] == "PUSH" or associated_instr['disasm'] == "PUSH data" \
                or associated_instr['disasm'] == "PUSHIMMUTABLE":
            value = hex(int(associated_instr['value'][0]))[2:]
            return [AsmBytecode(-1, -1, -1, associated_instr['disasm'], value)]
        
        # Commutative instructions
        elif "PUSH" not in associated_instr["disasm"] and len(associated_instr["disasm"].split(' ')) > 1:
            return [AsmBytecode(-1, -1, -1, disasm_name, None) for disasm_name in associated_instr["disasm"].split(' ')]
                                
        else:
            return [AsmBytecode(-1, -1, -1, associated_instr['disasm'], 
                                None if 'value' not in associated_instr else str(associated_instr['value'][0]))]

    else:
        # The id is the instruction itself
        return [AsmBytecode(-1, -1, -1, instr_id, None)]


def id_seq_to_asm_bytecode(uf_instrs: Dict[str, Dict[str, Any]], id_seq: List[str]) -> List[AsmBytecode]:
    return [asm_bytecode for instr_id in id_seq if instr_id != 'NOP' for asm_bytecode in id_to_asm_bytecode(uf_instrs, instr_id)]


def asm_from_ids(sms, id_seq: List[str]) -> List[AsmBytecode]:
    instr_id_to_instr = {instr['id']: instr for instr in sms['user_instrs']}
    return id_seq_to_asm_bytecode(instr_id_to_instr, id_seq)



### Methods to process the output from Minizinc

def mzn_id_to_instr_id(mzn_id: str) -> str:
    if mzn_id == 'POP' or mzn_id == 'NOP':
        return mzn_id
    other_op_match = re.match(re.compile('.+\((.+)\)'), mzn_id)
    if other_op_match is not None:
        op = other_op_match.group(1)
        
        # PUSH tags and other opcodes with spaces must be treated separately,
        # as they start and end with ' symbol
        if len(op) > 2 and op[0] == op[-1] == "'":
            return op[1:-1]
        else:
           return op 
    raise ValueError(f'{mzn_id} does not match any of the mzn id possibilities')


def find_best_seq(output: str) -> List[str]:
    rev_lines = reversed(output.splitlines())
    seq_re = re.compile('program = \[(.*)]')
    for line in rev_lines:
        solution_mzn = re.match(seq_re, line)
        if solution_mzn is not None:
            mzn_ids = solution_mzn.group(1).split(', ')
            instr_ids = []
            for mzn_id in mzn_ids:
                instr_id = mzn_id_to_instr_id(mzn_id)
                if instr_id == 'NOP':
                    return instr_ids
                else:
                    instr_ids.append(instr_id)
            return instr_ids
    return []


def time_elapsed_from_output(output: str) -> float:
    rev_lines = reversed(output.splitlines())
    seq_re = re.compile('% time elapsed: (\d+\.?\d*) s')

    for line in rev_lines:
        elapsed_time_match = re.match(seq_re, line)
        if elapsed_time_match is not None:
            return float(elapsed_time_match.group(1))
    
    raise ValueError("Time elapsed not found")


def process_msg(msg: str) -> Tuple[List[str], str]:
    if '=====UNKNOWN=====' in msg:
        optimization_outcome = 'no_model'
    elif 'Error' in msg:
        optimization_outcome = 'error'
    elif '=====UNSATISFIABLE=====' in msg:
        optimization_outcome = 'unsat'
    elif '% Time limit exceeded!' in msg:
        optimization_outcome = 'non_optimal'
    else:
        optimization_outcome = 'optimal'

    seq = find_best_seq(msg)
    time_elapsed = time_elapsed_from_output(msg)

    return seq, optimization_outcome, time_elapsed


def process_output_from_minizinc(output, sfs) -> Tuple[List[AsmBytecode], List[str], str, float]:
    # Process minizinc output
    found_seq, outcome, time_elapsed = process_msg(output)
    optimized_instrs = asm_from_ids(sfs, found_seq)
    return optimized_instrs, found_seq, outcome, time_elapsed


def load_from_minizinc(json_path, output_path):
    with open(json_path, 'r') as f:
        sfs = json.load(f)

    with open(output_path, 'r') as f:
        output = f.read()

    return sfs, output

def verify_solution(sfs: Dict, optimized_ids: List[str], outcome: str, stack_deps: bool) -> Tuple[bool, str]:
    if "optimal" in outcome:
        verification_output, reason = SymbolicChecker(stack_deps).verify_output_minizinc(sfs, optimized_ids)
    else:
        # If there is no block to check with, then it is true
        verification_output, reason = True, ""

    return verification_output, reason


def statistics_from_solution(block_name: str, optimized_asm: List[AsmBytecode], outcome: str, solver_time: float, original_instrs: str, tout: int) -> Dict:
    # We need to wrap the optimal solution and the initial one in a block to generate the statistics
    optimal_block = AsmBlock('optimized', 0, block_name, False)
    optimal_block.instructions = optimized_asm

    # The initial block is parsed directly, as we only have the plain representation
    initial_block = generate_block_from_plain_instructions(original_instrs, block_name, False)

    return generate_statistics_info(initial_block, outcome, solver_time, optimal_block, tout)


def run_and_verify_solution(json_path, output_path, options):
    # Name corresponds to the 
    block_name = Path(json_path).name.split(".")[0]
    sfs, output = load_from_minizinc(json_path, output_path)
    
    # Flatten args if needed
    if options.ac:
        asociatividad(sfs["user_instrs"])
    
    optimized_asm_seq, seq_ids, outcome, time_elapsed = process_output_from_minizinc(output, sfs)
    is_equivalent, reason = verify_solution(sfs, seq_ids, outcome, options.stack_deps)
    csv_info = statistics_from_solution(block_name, optimized_asm_seq, outcome, time_elapsed, sfs["original_instrs"], 10)
    csv_info["checker"] = is_equivalent
    csv_info["reason"] = reason
    return csv_info


def verify_solution_from_files(json_folder, output_folder, options, csv_file: str = "evaluation.csv"):
    csv_rows = []
    for output_file in glob(output_folder + "/*.txt"):
        output_path = Path(output_file)
        basename = output_path.name.split(".")[0]
        json_file = Path(json_folder).joinpath(basename + ".json")
        csv_rows.append(run_and_verify_solution(json_file, output_file, options))
    pd.DataFrame(csv_rows).to_csv(csv_file)


def parse_arguments():
    parser = argparse.ArgumentParser(
                    prog='Process solution',
                    description='Program to validate the solutions produced by MiniZinc and produce the corresponding statistics')
    parser.add_argument('json_dir')
    parser.add_argument('output_dir')
    parser.add_argument('-ac', '--ac', action='store_true')
    parser.add_argument('-stack-deps', '--stack-deps', action='store_true')
    return parser.parse_args()

### MAIN

if __name__ == "__main__":
    args = parse_arguments()
    verify_solution_from_files(args.json_dir, args.output_dir, args)