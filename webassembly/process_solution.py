import re
import json
import sys
import pandas as pd
from pathlib import Path
from glob import glob
from typing import List, Dict, Any, Tuple
from symbolic_execution import check_execution_from_ids

### Methods to process the output from Minizinc

def mzn_id_to_instr_id(mzn_id: str) -> str:
    if mzn_id == 'POP' or mzn_id == 'NOP':
        return mzn_id
    matches = re.findall(re.compile('[a-zA-Z]+\((.+)\)'), mzn_id)
    if len(matches) > 0:
        op = matches[0]
        
        # PUSH tags and other opcodes with spaces must be treated separately,
        # as they start and end with ' symbol
        if len(op) > 2 and op[0] == op[-1] == "'":
            return op[1:-1]
        else:
           return op 
    raise ValueError(f'{mzn_id} does not match any of the mzn id possibilities')


def find_best_seq(output: str) -> List[str]:
    rev_lines = reversed(output.splitlines())
    seq_re = re.compile('program = \[(.*)];')
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


def process_output_from_minizinc(output, sfs) -> Tuple[List[str], str, float]:
    # Process minizinc output
    found_seq, outcome, time_elapsed = process_msg(output)
    return found_seq, outcome, time_elapsed


def load_from_minizinc(json_path, output_path):
    with open(json_path, 'r') as f:
        sfs = json.load(f)

    with open(output_path, 'r') as f:
        output = f.read()

    return sfs, output

def verify_solution(sfs: Dict, instr_ids: List[str], outcome: str) -> Tuple[bool, str]:
    if "optimal" in outcome:
        verification_output = check_execution_from_ids(sfs, instr_ids)
    else:
        # If there is no block to check with, then it is true
        verification_output = True, ""

    return verification_output


def generate_statistics_info(original_block: List[str], optimized_block: List[str], outcome: str, solver_time: float,
                             tout: int, initial_bound: int, used_bound: int, block_name: str,
                             rules_repr: str, is_correct: bool, final_solution_tag: str) -> Dict:

    statistics_row = {"block_id": block_name,  "previous_solution": ' '.join(original_block), "timeout": tout,
                      "solver_time_in_sec": round(solver_time, 3), "outcome": outcome,
                      "initial_n_instrs": initial_bound, "model_found": False, "shown_optimal": False,
                      "initial_length": len(original_block), "used_bound": used_bound, "saved_length": 0,
                      "checker": is_correct, "final_solution_tag": final_solution_tag}

    # The solver has returned a valid model
    if outcome in ["optimal", "non_optimal"] or final_solution_tag == "greedy":
        shown_optimal = outcome == "optimal"

        statistics_row.update({"model_found": True, "shown_optimal": shown_optimal,
                               "solution_found": ' '.join(optimized_block),
                               "optimized_n_instrs": len(optimized_block), 'optimized_length': len(optimized_block),
                               'saved_length': len(original_block) - len(optimized_block),
                               "rules": rules_repr})

    return statistics_row


def generate_statistics_info(original_block: List[str], optimized_block: List[str], outcome: str, solver_time: float,
                             tout: int, initial_bound: int, block_name: str, is_correct: bool, reason: str) -> Dict:

    statistics_row = {"block_id": block_name,  "previous_solution": ' '.join(original_block), "timeout": tout,
                      "solver_time_in_sec": round(solver_time, 3), "outcome": outcome,
                      "initial_n_instrs": initial_bound, "model_found": False, "shown_optimal": False,
                      "initial_length": len(original_block), "saved_length": 0,
                      "checker": is_correct, "reason": reason}

    # The solver has returned a valid model
    if outcome in ["optimal", "non_optimal"]:
        shown_optimal = outcome == "optimal"

        statistics_row.update({"model_found": True, "shown_optimal": shown_optimal,
                               "solution_found": ' '.join(optimized_block),
                               "optimized_n_instrs": len(optimized_block), 'optimized_length': len(optimized_block),
                               'saved_length': len(original_block) - len(optimized_block)})

    return statistics_row


def run_and_verify_solution(json_path, output_path):
    # Name corresponds to the 
    block_name = Path(json_path).name.split(".")[0]
    print(json_path)
    sfs, output = load_from_minizinc(json_path, output_path)
    instr_ids, outcome, time_elapsed = process_output_from_minizinc(output, sfs)
    is_equivalent, reason = verify_solution(sfs, instr_ids, outcome)
    original_instrs = sfs["original_instrs"].split(' ')
    csv_info = generate_statistics_info(original_instrs, instr_ids, outcome, time_elapsed, 10, len(original_instrs), block_name, is_equivalent, reason)
    return csv_info


def verify_solution_from_files(json_folder, output_folder, csv_file: str = "evaluation.csv"):
    csv_rows = []
    for output_file in glob(output_folder + "/*.txt"):
        output_path = Path(output_file)
        basename = output_path.name.split(".")[0]
        json_file = Path(json_folder).joinpath(basename + ".json")
        csv_rows.append(run_and_verify_solution(json_file, output_file))
    pd.DataFrame(csv_rows).to_csv(csv_file)

### MAIN

if __name__ == "__main__":
    json_dir, output_dir = sys.argv[1:]
    verify_solution_from_files(json_dir, output_dir)