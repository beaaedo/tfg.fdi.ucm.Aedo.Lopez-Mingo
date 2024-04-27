import collections
import json
from typing import List, Dict, Set, Tuple, Any
import re
import sys

id_T = str
var_T = str
instr_T = Dict[str, Any]

const_re = re.compile('\[(.*)]')
access_re = re.compile('_index\((.*)\)')

DEBUG_MODE = False


def idx_from_access(access: str) -> int:
    return int(re.search(access_re, access).group(1))


def execute_instr(instr_name: str, pos: int, cstack: List[var_T], clocals: Dict[var_T, var_T], ilocals: List[var_T],
                  vars_: Set[var_T], user_instr: List[instr_T]) -> id_T:
    """
    Executes the instruction and returns the id from the instruction according to user_instr
    """
    # Case const: filter the instruction that has introduces that value
    if 'const' in instr_name:
        const = int(re.search(const_re, instr_name).group(1))
        filtered_instrs = [instr for instr in user_instr if f'const' in instr['disasm'] and instr['value'] == const]
        assert len(filtered_instrs) == 1
        instr = filtered_instrs[0]
        const_var = instr['outpt_sk'][0]
        assigned_instr = instr["id"]
        cstack.insert(0, const_var)
        vars_.add(const_var)

    # Drop: just remove the instruction that introduced the value
    elif instr_name == 'drop':
        vars_.add(cstack.pop(0))
        assigned_instr = 'POP'

    # load.get: get the value from the corresponding local
    elif 'local.get' in instr_name:
        # Either it appears as an instruction in user_instr or the local variable belongs to clocals
        local_idx = idx_from_access(instr_name)
        local_name = f"local_{local_idx}"
        local_val = clocals.get(local_name, None)
        if local_val is not None:
            cstack.insert(0, local_val)
            vars_.add(clocals[local_name])
            assigned_instr = f'LGET_{ilocals.index(local_name)}'
        else:
            # Check it exists exactly one instruction for loading
            filtered_instrs = [instr for instr in user_instr if
                               len(instr['outpt_sk']) > 0 and instr['outpt_sk'][0] == local_name]
            assert len(filtered_instrs) == 1
            instr = filtered_instrs[0]
            local_val = instr['outpt_sk'][0]
            assigned_instr = instr["id"]
            cstack.insert(0, local_val)
            vars_.add(local_val)

    # load.set: store the value in the corresponding local
    elif 'local.set' in instr_name or 'local.tee' in instr_name:
        # The value must belong to local variables
        local = idx_from_access(instr_name)
        local_name = f"local_{local}"
        new_local_value = cstack[0]
        clocals[local_name] = new_local_value
        vars_.add(new_local_value)

        # If it is set instead of tee, we remove the value from the stack
        if 'local.set' in instr_name:
            cstack.pop(0)
            assigned_instr = f'LSET_{ilocals.index(local_name)}'
        else:
            assigned_instr = f'LTEE_{ilocals.index(local_name)}'

    # Remaining instructions: filter those instructions whose disasm matches the instr name and consumes the same
    # values. For call and global instructions, we also use the access position to filter the instruction
    else:
        # if 'call' in instr_name:
        #    # Call instructions are of the form call[]_pos(args)
        #    filtered_instrs = [instr for instr in user_instr
        #                        if instr['id'].startswith(f"{instr_name}_{pos}")]
        if any(instr in instr_name for instr in ['call', 'global', 'load', 'store']):
            # Remaining instructions are of the form instr_name(args)_pos
            filtered_instrs = [instr for instr in user_instr
                               if instr['disasm'] in instr_name and instr['id'].endswith(f'_{pos}')]
        else:
            filtered_instrs = [instr for instr in user_instr if instr['disasm'] in instr_name and
                               all(cstack[i] == input_var for i, input_var in enumerate(instr['inpt_sk']))]

        # print(instr_name, pos, *[(instr['id'], instr['disasm']) for instr in user_instr])
        # print(instr_name, pos, *[(instr['id'], instr['disasm']) for instr in filtered_instrs])
        assert len(filtered_instrs) == 1
        instr = filtered_instrs[0]

        # We consume the elements
        for input_var in instr['inpt_sk']:
            assert cstack[0] == input_var
            cstack.pop(0)

        # We introduce the new elements
        for output_var in reversed(instr['outpt_sk']):
            cstack.insert(0, output_var)
            vars_.add(output_var)

        assigned_instr = instr['id']

    return assigned_instr


def extract_idx_from_id(instr_id: str) -> int:
    return int(instr_id[3:])


def execute_instr_id(instr_id: str, cstack: List[var_T], clocals: List[var_T], user_instr: List[instr_T]) -> Tuple[bool, str]:
    """
    Executes the instr id according to user_instr. Returns a bool indicating the execution has succeed or not, and the reason
    why it fails (if any)
    """
    if DEBUG_MODE:
        print(instr_id, cstack, clocals)
    
    # Drop the value
    if instr_id == 'POP':
        cstack.pop(0)

    # load.get: get the value from the corresponding local
    elif 'GET' in instr_id:
        idx = extract_idx_from_id(instr_id)
        local_val = clocals[idx]
        cstack.insert(0, local_val)

    # load.set: store the value in the corresponding local
    elif 'SET' in instr_id:
        idx = extract_idx_from_id(instr_id)

        if idx >= len(clocals):
            clocals.append('')

        clocals[idx] = cstack.pop(0)

    # load.tee: store the value in the corresponding local without consuming the top of the stack
    elif 'TEE' in instr_id:
        idx = extract_idx_from_id(instr_id)

        if idx >= len(clocals):
            clocals.append('')

        clocals[idx] = cstack[0]

    else:
        instr = [instr for instr in user_instr if instr['id'] == instr_id][0]

        if instr["commutative"]:
            input_vars = instr['inpt_sk']
            if len(input_vars) != 2:
                return False, 'Commutative instructions with #args != 2'
            # We consume the elements
            s0, s1 = cstack.pop(0), cstack.pop(0)
            if (s0 != input_vars[0] or s1 != input_vars[1]) and (s0 != input_vars[1] or s1 != input_vars[0]):
                return False, f"Args don't match in commutative instr {instr_id}"

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

def check_deps(instr_ids: List[id_T], dependencies: List[Tuple[id_T, id_T]]) -> bool:
    """
    Check the ids from the final instructions satisfy the dependencies
    """
    pos_by_id = collections.defaultdict(lambda: [])
    for i, instr in enumerate(instr_ids):
        pos_by_id[instr].append(i)
    if DEBUG_MODE:
        for dep in dependencies:
            print(dep, max(pos_by_id[dep[0]]) < min(pos_by_id[dep[1]]))
    return all(max(pos_by_id[dep[0]]) < min(pos_by_id[dep[1]]) for dep in dependencies)


def ensure_ids_are_unique(user_instr: List[instr_T]) -> bool:
    accesses = set()
    for instr in user_instr:
        instr_id = instr['id']
        if instr_id in accesses:
            return False
        else:
            accesses.add(instr_id)
    return True


def ensure_stack_vars_are_unique(user_instr: List[instr_T]) -> bool:
    accesses = set()
    for instr in user_instr:
        stack_vars = instr['outpt_sk']
        for stack_var in stack_vars:
            if stack_var in accesses:
                return False
            else:
                accesses.add(stack_var)
    return True


def symbolic_execution_from_sfs(sfs: Dict) -> List[id_T]:
    original_instr: str = sfs['original_instrs']
    user_instr: List[instr_T] = sfs['user_instrs']
    # print(*(instr["disasm"] for instr in user_instr))
    instrs: List[str] = original_instr.split(' ')
    local_changes: List[Tuple[var_T, var_T]] = sfs['register_changes']
    dependencies: List[Tuple[id_T, id_T]] = sfs['dependencies']
    sfs_vars: Set[str] = set(sfs['vars'])

    # We split into two different dicts the initial values and final values in locals
    ilocals: List[var_T] = [local_repr[0] for local_repr in local_changes]
    clocals: Dict[var_T, var_T] = {local_repr[0]: local_repr[0] for local_repr in local_changes}
    flocals: Dict[var_T, var_T] = {local_repr[0]: local_repr[1] for local_repr in local_changes}
    cstack, fstack = sfs['src_ws'].copy(), sfs['tgt_ws']

    # We include directly the initial values in istack and ilocals
    vars_ = set(clocals.keys())
    vars_.update(cstack)

    final_instr_ids = [execute_instr(instr, i, cstack, clocals, ilocals, vars_, user_instr) for i, instr in
                       enumerate(instrs)]

    assert ensure_ids_are_unique(user_instr), 'Ids are not unique'
    assert ensure_stack_vars_are_unique(user_instr), 'Stack vars are not unique'
    assert cstack == fstack, 'Stack do not match'
    assert clocals == flocals, 'Locals do not match'
    assert vars_ == sfs_vars, 'Vars do not match'
    assert check_deps(final_instr_ids, dependencies), 'Dependencies are not coherent'

    # Check that the ids returned generate the final state
    cstack, clocals_list = sfs['src_ws'].copy(), ilocals.copy()
    flocal_list = [local_repr[1] for local_repr in local_changes]

    for instr_id in final_instr_ids:
        execute_instr_id(instr_id, cstack, clocals_list, user_instr)
    assert cstack == fstack, 'Ids - Stack do not match'
    assert clocals_list == flocal_list, 'Ids - Locals do not match'

    # print(final_instr_ids)
    # print("They match!")
    return final_instr_ids


def check_execution_from_ids(sfs: Dict, instr_ids: List[id_T]) -> Tuple[bool,str]:
    """
    Given a SFS and a sequence of ids, checks the ids indeed represent a valid solution
    """
    user_instr: List[instr_T] = sfs['user_instrs']
    local_changes: List[Tuple[var_T, var_T]] = sfs['register_changes']
    dependencies: List[Tuple[id_T, id_T]] = sfs['dependencies']

    # We split into two different dicts the initial values and final values in locals
    ilocals: List[var_T] = [local_repr[0] for local_repr in local_changes]
    cstack, fstack = sfs['src_ws'].copy(), sfs['tgt_ws']

    # Check that the ids returned generate the final state
    cstack, clocals_list = sfs['src_ws'].copy(), ilocals.copy()
    flocal_list = [local_repr[1] for local_repr in local_changes]

    for instr_id in instr_ids:
        correct, reason = execute_instr_id(instr_id, cstack, clocals_list, user_instr)
        if not correct:
            return correct, reason

    if DEBUG_MODE and 'original_instrs_with_ids' in sfs:
        print('Len initial', len(sfs['original_instrs_with_ids']))
        print('Len final', len(instr_ids))

    if cstack != fstack: 
        return False, 'Ids - Stack do not match'
    
    # Check only relevant locals
    if clocals_list[:len(flocal_list)] != flocal_list:
        return False, 'Ids - Locals do not match'
    
    if not check_deps(instr_ids, dependencies): 
        return False, 'Dependencies are not coherent'
    
    for instr in user_instr:
        if any(instr_name in instr["disasm"] for instr_name in ["call", "global.set", "store", "memory"]):
            if instr_ids.count(instr["id"]) != 1:
                return False, "Mem operation used more than once"

    return True, ""


if __name__ == "__main__":
    with open(sys.argv[1], 'r') as f:
        loaded_sfs = json.load(f)
    symbolic_execution_from_sfs(loaded_sfs)
