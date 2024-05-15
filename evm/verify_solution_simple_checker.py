import collections
from typing import List, Tuple, Dict, Set

var_T = str
instr_T = Dict 
id_T = str

DEBUG_MODE=True

def flattened_expression(instr_id: str, user_instrs: Dict[id_T, instr_T], name: str):
    current_instr = user_instrs[instr_id]
    # If the field disasm matches, we flattened the expressions
    if current_instr["disasm"] == name:
        [instr for instr in user_instrs if instr['id'] == instr_id][0]

    instr = [instr for instr in user_instrs if instr['id'] == instr_id][0]

class SymbolicChecker:

    def __init__(self) -> None:
        self.flattened = False 
        self.fixed_stack = True

    def execute_instr_id(self, instr_id: str, cstack: List[var_T], user_instr: Dict[id_T, instr_T]) -> Tuple[bool, str]:
        """
        Executes the instr id according to user_instr. Returns if the execution is correct and the reason it may fail
        """

        # Drop the value
        if instr_id == 'POP':
            cstack.pop(0)

        elif 'DUP' in instr_id:
            idx = int(instr_id[3:])
            cstack.insert(0, cstack[idx-1])

        elif 'SWAP' in instr_id:
            idx = int(instr_id[4:])
            cstack[0], cstack[idx] = cstack[idx], cstack[0]

        else:
            instr = user_instr[instr_id]

            if instr["commutative"]:
                # We sort the elements to check if they match
                input_vars = sorted(instr['inpt_sk'])
                consumed_vars = sorted(cstack.pop(0) for _ in range(len(input_vars)))              
                
                if input_vars != consumed_vars:
                    return False, f"Args don't match in commutative instr {instr_id}. \
                    Produced (sorted by name): {input_vars}. Consumed (sorted by name): {consumed_vars}"
                
                # We introduce the new elements
                for output_var in reversed(instr['outpt_sk']):
                    cstack.insert(0, output_var)

            else:
                # We consume the elements
                for input_var in instr['inpt_sk']:
                    if cstack[0] != input_var: 
                        return False, f"Args don't match in non-commutative instr {instr_id}"
                    cstack.pop(0)

                # We introduce the new elements
                for output_var in reversed(instr['outpt_sk']):
                    cstack.insert(0, output_var)

        return True, ""

    def check_deps(self, instr_ids: List[id_T], dependencies: List[Tuple[id_T, id_T]]) -> Tuple[bool, str]:
        """
        Check the ids from the final instructions satisfy the dependencies
        """
        pos_by_id = collections.defaultdict(lambda: [])
        for i, instr in enumerate(instr_ids):
            pos_by_id[instr].append(i)
        if DEBUG_MODE:
            for dep in dependencies:
                print(dep, max(pos_by_id[dep[0]]) < min(pos_by_id[dep[1]]))
        for dep in dependencies:
            if max(pos_by_id[dep[0]]) >= min(pos_by_id[dep[1]]):
                return False, f"Dependency {dep} is not satisfied in the model"
        
        return True, ""


    def verify_output_minizinc(self, sfs: Dict, seq_ids: List[id_T], fixed_final_stack: bool=True) -> Tuple[bool, str]:
        user_instr: Dict[instr_T, instr_T] = {instr["id"]: instr for instr in sfs['user_instrs']}
        dependencies: List[Tuple[id_T, id_T]] = [*sfs['memory_dependences'], *sfs["storage_dependences"]]

        cstack, fstack = sfs['src_ws'].copy(), sfs['tgt_ws']

        for instr_id in seq_ids:
            if instr_id == "NOP":
                break
            correct, reason = self.execute_instr_id(instr_id, cstack, user_instr)
            if not correct:
                return False, reason

        # assert ensure_ids_are_unique(user_instr), 'Ids are not unique'
        # assert ensure_stack_vars_are_unique(user_instr), 'Stack vars are not unique'
        if fixed_final_stack:
            if cstack != fstack:
                return False, f"Final stack after symbolic execution do not match. \
                Expected: {fstack}. Computed: {cstack}"
        else:
            sorted_cstack = sorted(cstack)
            sorted_fstack = sorted(fstack)

            if sorted_cstack != sorted_fstack:
                return False, f"Final stack does not contain the elements expected: \
                Expected: {fstack}. Computed: {cstack}"
        
        correct, reason = self.check_deps(seq_ids, dependencies)
        if not correct:
            return False, reason
        
        return True, ""