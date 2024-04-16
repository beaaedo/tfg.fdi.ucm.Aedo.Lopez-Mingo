import re
import json
import sys
import pandas as pd
from pathlib import Path
from glob import glob
from asm_block import AsmBlock, generate_block_from_plain_instructions
from asm_bytecode import AsmBytecode
from typing import List, Dict, Any, Tuple
from verify_solution import verify_output_minizinc
from evm_statistics import generate_statistics_info

### Methods to transform a sequence of ids to AsmBytecode

def id_to_asm_bytecode(uf_instrs: Dict[str, Dict[str, Any]], instr_id: str) -> AsmBytecode:
    # AsmBytecode(-1, -1, -1, , )
    if instr_id in uf_instrs:
        associated_instr = uf_instrs[instr_id]

        # Special case: reconstructing PUSH0 (see sfs_generator/parser_asm.py)
        if associated_instr["disasm"] == "PUSH0":
            return AsmBytecode(-1, -1, -1, "PUSH", "0")
        # Special PUSH cases that were transformed to decimal are analyzed separately
        elif associated_instr['disasm'] == "PUSH" or associated_instr['disasm'] == "PUSH data" \
                or associated_instr['disasm'] == "PUSHIMMUTABLE":
            value = hex(int(associated_instr['value'][0]))[2:]
            return AsmBytecode(-1, -1, -1, associated_instr['disasm'], value)
        else:
            return AsmBytecode(-1, -1, -1, associated_instr['disasm'],
                               None if 'value' not in associated_instr else str(associated_instr['value'][0]))

    else:
        # The id is the instruction itself
        return AsmBytecode(-1, -1, -1, instr_id, None)


def id_seq_to_asm_bytecode(uf_instrs: Dict[str, Dict[str, Any]], id_seq: List[str]) -> List[AsmBytecode]:
    return [id_to_asm_bytecode(uf_instrs, instr_id) for instr_id in id_seq if instr_id != 'NOP']


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


def process_output_from_minizinc(output, sfs) -> Tuple[List[AsmBytecode], str, float]:
    # Process minizinc output
    found_seq, outcome, time_elapsed = process_msg(output)
    optimized_instrs = asm_from_ids(sfs, found_seq)
    return optimized_instrs, outcome, time_elapsed


def load_from_minizinc(json_path, output_path):
    with open(json_path, 'r') as f:
        sfs = json.load(f)

    with open(output_path, 'r') as f:
        output = f.read()

    return sfs, output

def verify_solution(sfs: Dict, optimized_asm_seq: List[AsmBytecode], outcome: str) -> str:
    if "optimal" in outcome:
        plain_seq =  ' '.join(bytecode.to_plain() for bytecode in optimized_asm_seq)
        print(plain_seq)
        verification_output = verify_output_minizinc(sfs["original_instrs"], plain_seq)
    else:
        # If there is no block to check with, then it is true
        verification_output = "true"

    return verification_output


def statistics_from_solution(block_name: str, optimized_asm: List[AsmBytecode], outcome: str, solver_time: float, original_instrs: str, tout: int) -> Dict:
    # We need to wrap the optimal solution and the initial one in a block to generate the statistics
    optimal_block = AsmBlock('optimized', 0, block_name, False)
    optimal_block.instructions = optimized_asm

    # The initial block is parsed directly, as we only have the plain representation
    initial_block = generate_block_from_plain_instructions(original_instrs, block_name, False)

    return generate_statistics_info(initial_block, outcome, solver_time, optimal_block, tout)


def run_and_verify_solution(json_path, output_path):
    # Name corresponds to the 
    block_name = Path(json_path).name.split(".")[0]
    sfs, output = load_from_minizinc(json_path, output_path)
    optimized_asm_seq, outcome, time_elapsed = process_output_from_minizinc(output, sfs)
    is_equivalent = verify_solution(sfs, optimized_asm_seq, outcome)
    csv_info = statistics_from_solution(block_name, optimized_asm_seq, outcome, time_elapsed, sfs["original_instrs"], 10)
    csv_info["forves_checker"] = is_equivalent
    return csv_info


def verify_solution_from_files(json_folder, output_folder, csv_file: str = "evaluation.csv"):
    csv_rows = []
    for json_file in glob(json_folder + "/*.json"):
        json_path = Path(json_file)
        basename = json_path.name.split(".")[0]
        output_file = Path(output_folder).joinpath(basename + ".txt")
        csv_rows.append(run_and_verify_solution(json_file, output_file))
    pd.DataFrame(csv_rows).to_csv(csv_file)

### MAIN

if __name__ == "__main__":
    json_dir, output_dir = sys.argv[1:]
    verify_solution_from_files(json_dir, output_dir)