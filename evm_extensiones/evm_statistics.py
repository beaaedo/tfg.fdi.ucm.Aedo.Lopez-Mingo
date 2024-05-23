from asm_block import AsmBlock
from typing import List, Dict

def generate_statistics_info(original_block: AsmBlock, outcome: str, solver_time: float,
                             optimized_block: AsmBlock, tout: int) -> Dict:
    block_name = original_block.block_name
    original_instr = ' '.join(original_block.instructions_to_optimize_plain())

    statistics_row = {"block_id": block_name, "previous_solution": original_instr, "timeout": tout, "model_found": False, "shown_optimal": False, "outcome": outcome,
                      "solver_time_in_sec": round(solver_time, 3), "initial_n_instrs": original_block.length, 'initial_estimated_size': original_block.bytes_required,
                      'initial_estimated_gas': original_block.gas_spent, 'initial_length': original_block.length, 'saved_length': 0, "saved_size": 0, "saved_gas": 0}

    # The solver has returned a valid model
    if "optimal" in outcome:
        shown_optimal = outcome == "optimal"
        optimized_size = optimized_block.bytes_required
        optimized_gas = optimized_block.gas_spent
        optimized_length = len(optimized_block.instructions_to_optimize_plain())
        initial_size = original_block.bytes_required
        initial_gas = original_block.gas_spent
        initial_length = len(original_block.instructions_to_optimize_plain())

        statistics_row.update({"solver_time_in_sec": round(solver_time, 3), "saved_size": initial_size - optimized_size,
                               "saved_gas": initial_gas - optimized_gas, "model_found": True,
                               "shown_optimal": shown_optimal,
                               "solution_found": ' '.join([instr.to_plain() for instr in optimized_block.instructions]),
                               "optimized_n_instrs": optimized_length, 'optimized_length': optimized_length,
                               'optimized_estimated_size': optimized_size, 'optimized_estimated_gas': optimized_gas,
                               'outcome': 'model', 'saved_length': initial_length - optimized_length})

    return statistics_row
