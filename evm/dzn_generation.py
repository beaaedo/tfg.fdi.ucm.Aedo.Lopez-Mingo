#!/usr/bin/env python3

# use it with
# python3 dzn_generator file.json

# --solver = chuffed

import json
import os
import sys
from collections import defaultdict
sys.path.append(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

import itertools


def get_ops_map(instructions, op):
    res = {}
    for ins in instructions:
        if ins['disasm'] == op:
            res[ins['outpt_sk'][0]] = ins['id']
    return res


def get_ops_id(instructions, op):
    res = []
    for ins in instructions:
        if ins['disasm'] == op:
            res += [ins['id']]
    return res


def make_list(l):
    s = ""
    for e in l:
        s += str(e) + ", "
    return s[:-2]


def make_list_deps(l):
    return ', '.join(f"ST({elem})" if "STORE" in elem else f"U({elem})"for elem in l)


def count_subterms(user_instr): 
    occurrences = defaultdict(lambda: 0)
    for instr in user_instr:
        for input_var in instr["inpt_sk"]:
            occurrences[input_var] += 1
    return occurrences

def flatten_operation(instruction, flattened_repr, to_remove, var2instr):
    # Flattening operations
    var_count = count_subterms(var2instr.values())
    if instruction["id"] not in flattened_repr and instruction["commutative"]:
        input_vars = instruction["inpt_sk"]
        new_input_vars = []
        for input_var in input_vars:
            input_instr = var2instr.get(input_var, None)

            # Conditions for flattening
            if input_instr is not None and instruction["disasm"] == input_instr["disasm"] and var_count[input_var] == 1:

                # First flatten the subterm if it has not been flattened yet
                # We only flatten operations that appear once as a subterm, as it 
                # is unclear the behaviour when multiple occurrences happen
                if input_instr["id"] not in flattened_repr:
                    flatten_operation(input_instr, flattened_repr, to_remove, var2instr)

                # Afterwards, we combine the operations
                new_input_vars.extend(input_instr["inpt_sk"])

                # We update the disasm info
                instruction["disasm"] += " " + input_instr["disasm"]
                # Remove the instruction afterwards
                to_remove.add(input_instr["id"])
        
            else:
                new_input_vars.append(input_var) 
       
        flattened_repr.add(instruction["id"])
        instruction["inpt_sk"] = new_input_vars
    
def asociatividad(user_instr):
    flattened, to_remove = set(), set()
    var2instr = {out_var: instr for instr in user_instr for out_var in instr["outpt_sk"]}
    for instr in user_instr:
        flatten_operation(instr, flattened, to_remove, var2instr)

    final_user_instr = [instr for instr in user_instr if instr["id"] not in to_remove]
    return final_user_instr, len(to_remove), len([instr for instr in final_user_instr if instr["commutative"] and len(instr["input_sk"]) > 2])


class SMSgreedy:

    def __init__(self, json_format, file=sys.stdout):
        self._bs = json_format['max_sk_sz']
        self._user_instr = json_format['user_instrs']
        self._b0 = json_format["init_progr_len"]
        self._initial_stack = json_format['src_ws']
        self._final_stack = json_format['tgt_ws']
        self._variables = json_format['vars']
        self._current_cost = json_format['current_cost']
        self._mem_order = json_format['memory_dependences']
        self._sto_order = json_format['storage_dependences']
        if 'order_tgt_ws' in json_format:
            self._order_final_stack = json_format['order_tgt_ws']
            self._liberalize = True
        else:
            self._liberalize = False
        if 'min_length' in json_format:
            self._min_length = json_format['min_length']
        else:
            self._min_length = 0
        self._var_instr_map = {}
        self._f = file
        for ins in self._user_instr:
            if len(ins['outpt_sk']) == 1:
                self._var_instr_map[ins['outpt_sk'][0]] = ins
        self._opid_instr_map = {}
        for ins in self._user_instr:
            self._opid_instr_map[ins['id']] = ins
        if 'original_code_with_ids' in json_format:
            self._original_code_with_ids = json_format['original_code_with_ids']
        else:
            self._original_code_with_ids = []
        if 'lower_bounds' in json_format:
            self._lower_bounds = json_format['lower_bounds']
        else:
            self._lower_bounds = {}
        if 'upper_bounds' in json_format:
            self._upper_bounds = json_format['upper_bounds']
        else:
            self._upper_bounds = {}
    
    def generate_dzn(self):
        constants = []
        UNARYOP = []
        unin = []
        unout = []
        ungas = []
        unsz = []
        unlb = []
        unub = []
        ZEROARYOP = []
        zeout = []
        zegas = []
        zesz = []
        zelb = []
        zeub = []
        BINARYOP = []
        binin1 = []
        binin2 = []
        binout = []
        bincomm = []
        bingas = []
        binsz = []
        binlb = []
        binub = []
        PUSHOP = []
        pushout = []
        pushgas = []
        pushsz = []
        pushlb = []
        pushub = []
        STOROP = []
        storin1 = []
        storin2 = []
        storgas = []
        storsz = []
        storlb = []
        storub = []
        final_instr, n_combined, n_ins = asociatividad(self._user_instr)
        
        # Remove one per combined operation
        self._b0 -= n_combined

        self._user_instr = final_instr
        print(self._user_instr)
        ASSOCIATIVEADDOP = []
        addin = [["null"] * 10 for _ in range(n_ins)]
        naddin = []
        addout = []
        addcomm = []
        addgas = []
        addsz = []
        addlb = []
        addub = []
        
        nadds = 0
        for ins in self._user_instr:
            if "PUSH" in ins["id"]:
                if " " in ins["id"]:
                    PUSHOP += ["\'" + ins["id"] + "\'"]
                else:
                    PUSHOP += [ins["id"]]
                pushout += ["s" + ins["outpt_sk"][0][2:-1]]
                pushgas += [str(ins["gas"])]
                pushsz += [str(ins["size"])]
                if len(self._lower_bounds) > 0:
                    pushlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    pushub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    pushlb += [str(1)]
                    pushub += [str(self._b0)]
            elif "STORE" in ins["id"]:
                STOROP += [ins["id"]]
                storgas += [str(ins["gas"])]
                storsz += [str(ins["size"])]
                if isinstance(ins["inpt_sk"][0], int):
                    i = len(constants)
                    if ins["inpt_sk"][0] in constants:
                        i = constants.index(ins["inpt_sk"][0])
                    else:
                        constants += [ins["inpt_sk"][0]]
                    storin1 += ["c" + str(i)]
                else:
                    storin1 += ["s" + ins["inpt_sk"][0][2:-1]]
                if isinstance(ins["inpt_sk"][1], int):
                    i = len(constants)
                    if ins["inpt_sk"][1] in constants:
                        i = constants.index(ins["inpt_sk"][1])
                    else:
                        constants += [ins["inpt_sk"][1]]
                    storin2 += ["c" + str(i)]
                else:
                    storin2 += ["s" + ins["inpt_sk"][1][2:-1]]
                if len(self._lower_bounds) > 0:
                    storlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    storub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    storlb += [str(1)]
                    storub += [str(self._b0)]
            elif len(ins["inpt_sk"]) == 0 and len(ins["outpt_sk"]) == 1:
                ZEROARYOP += [ins["id"]]
                zeout += ["s" + ins["outpt_sk"][0][2:-1]]
                zegas += [str(ins["gas"])]
                zesz += [str(ins["size"])]
                if len(self._lower_bounds) > 0:
                    zelb += [str(self._lower_bounds[ins["id"]] + 1)]
                    zeub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    zelb += [str(1)]
                    zeub += [str(self._b0)]
            elif len(ins["inpt_sk"]) == 1 and len(ins["outpt_sk"]) == 1:
                UNARYOP += [ins["id"]]
                if isinstance(ins["inpt_sk"][0], int):
                    i = len(constants)
                    if ins["inpt_sk"][0] in constants:
                        i = constants.index(ins["inpt_sk"][0])
                    else:
                        constants += [ins["inpt_sk"][0]]
                    unin += ["c" + str(i)]
                else:
                    unin += ["s" + ins["inpt_sk"][0][2:-1]]
                unout += ["s" + ins["outpt_sk"][0][2:-1]]
                ungas += [str(ins["gas"])]
                unsz += [str(ins["size"])]
                if len(self._lower_bounds) > 0:
                    unlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    unub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    unlb += [str(1)]
                    unub += [str(self._b0)]
            elif ins["commutative"] and len(ins["inpt_sk"]) > 2:
                ASSOCIATIVEADDOP += [ins["id"]]
                x = 0
                for inp in ins["inpt_sk"]:
                    if isinstance(inp, int):
                        i = len(constants)
                        if inp in constants:
                            i = constants.index(inp)
                        else:
                            constants += [inp]
                        addin[nadds][x] = "c" + str(i)
                    else:
                        addin[nadds][x] = "s" + inp[2:-1]
                    x = x + 1
                naddin += str(x)
                nadds += 1
                addout += ["s" + ins["outpt_sk"][0][2:-1]]
                addcomm += [str(ins["commutative"]).lower()]
                addgas += [str(ins["gas"])]
                addsz += [str(ins["size"])]
                if len(self._lower_bounds) > 0:
                    addlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    addub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    addlb += [str(1)]
                    addub += [str(self._b0)]
            elif len(ins["inpt_sk"]) == 2 and len(ins["outpt_sk"]) == 1:   
                BINARYOP += [ins["id"]]
                if isinstance(ins["inpt_sk"][0], int):
                    i = len(constants)
                    if ins["inpt_sk"][0] in constants:
                        i = constants.index(ins["inpt_sk"][0])
                    else:
                        constants += [ins["inpt_sk"][0]]
                    binin1 += ["c" + str(i)]
                else:
                    binin1 += ["s" + ins["inpt_sk"][0][2:-1]]
                if isinstance(ins["inpt_sk"][1], int):
                    i = len(constants)
                    if ins["inpt_sk"][1] in constants:
                        i = constants.index(ins["inpt_sk"][1])
                    else:
                        constants += [ins["inpt_sk"][1]]
                    binin2 += ["c" + str(i)]
                else:
                    binin2 += ["s" + ins["inpt_sk"][1][2:-1]]
                binout += ["s" + ins["outpt_sk"][0][2:-1]]
                bincomm += [str(ins["commutative"]).lower()]
                bingas += [str(ins["gas"])]
                binsz += [str(ins["size"])]
                if len(self._lower_bounds) > 0:
                    binlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    binub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    binlb += [str(1)]
                    binub += [str(self._b0)]
            else:
                print(ins["id"], file=self._f)
                raise Exception("Unsuported operation")

        term = "TERM = { \'.\'"
        for v in self._variables:
            term += ", s" + v[2:-1]
        for v in range(len(constants)):
            term += ", c" + str(v)
        term += "};"
        print(term, file=self._f)
        print("null = \'.\';", file=self._f)
        print("s = " + str(self._b0) + ";", file=self._f)
        print("n = " + str(self._bs) + ";", file=self._f)
        print("min = " + str(self._min_length) + ";", file=self._f)
        # print("origsol = "+str(self._original_code_with_ids)+";", file=self._f)
        # print("% when empty means not available", file=self._f)

        dups = "DUP_ENUM = {"
        for x in range(self._bs - 1):
            if x == self._bs - 2: 
                dups += " DUP" + str(x + 1)
            else: 
                dups += " DUP" + str(x + 1) + ","
            
        swaps = "SWAP_ENUM = {"
        for x in range(self._bs - 1):
            if x == self._bs -2:
                swaps += " SWAP" + str(x + 1)
            else:
                swaps += " SWAP" + str(x + 1) + ","

        if len(ZEROARYOP) == 0:
            print("N0 = 0;", file=self._f)
            print(r"ZEROARYOP = {};", file=self._f)
            print("zeroout = [];", file=self._f)
            print("zerogas = [];", file=self._f)
            print("zerosz =  [];", file=self._f)
            print("zerolb =  [];", file=self._f)
            print(f"zeroub =  [];", file=self._f)
        else:
            print("N0 = " + str(len(ZEROARYOP)) + ";", file=self._f)
            print("ZEROARYOP = { " + make_list(ZEROARYOP) + " };", file=self._f)
            print("zeroout = [ " + make_list(zeout) + " ];", file=self._f)
            print("zerogas = [ " + make_list(zegas) + " ];", file=self._f)
            print("zerosz = [ " + make_list(zesz) + " ];", file=self._f)
            if len(zelb) > 0:
                print("zerolb = [ " + make_list(zelb) + " ];", file=self._f)
                print("zeroub = [ " + make_list(zeub) + " ];", file=self._f)
            else:
                print(f"zerolb =  [ {0} ];", file=self._f)
                print(f"zeroub =  [ {0} ];", file=self._f)
        if len(UNARYOP) == 0:
            print("N1 = 0;", file=self._f)
            print(r"UNARYOP = {};", file=self._f)
            print("unin =  [];", file=self._f)
            print("unout = [];", file=self._f)
            print("ungas = [];", file=self._f)
            print("unsz =  [];", file=self._f)
            print("unlb =  [];", file=self._f)
            print(f"unub =  [];", file=self._f)
        else:
            print("N1 = " + str(len(UNARYOP)) + ";", file=self._f)
            print("UNARYOP = { " + make_list(UNARYOP) + " };", file=self._f)
            print("unin = [ " + make_list(unin) + " ];", file=self._f)
            print("unout = [ " + make_list(unout) + " ];", file=self._f)
            print("ungas = [ " + make_list(ungas) + " ];", file=self._f)
            print("unsz = [ " + make_list(unsz) + " ];", file=self._f)
            if len(unlb) > 0:
                print("unlb = [ " + make_list(unlb) + " ];", file=self._f)
                print("unub = [ " + make_list(unub) + " ];", file=self._f)
            else:
                print(f"unlb =  [ {0} ];", file=self._f)
                print(f"unub =  [ {0} ];", file=self._f)
        if len(BINARYOP) == 0:
            print("N2 = 0;", file=self._f)
            print(r"BINARYOP = {};", file=self._f)
            print("binin1 =  [];", file=self._f)
            print("binin2 =  [];", file=self._f)
            print("binout = [];", file=self._f)
            print("bincomm = [];", file=self._f)
            print("bingas = [];", file=self._f)
            print("binsz =  [];", file=self._f)
            print("binlb =  [];", file=self._f)
            print(f"binub =  [];", file=self._f)
        else:
            print("N2 = " + str(len(BINARYOP)) + ";", file=self._f)
            print("BINARYOP = { " + make_list(BINARYOP) + " };", file=self._f)
            print("binin1 = [" + make_list(binin1) + " ];", file=self._f)
            print("binin2 = [" + make_list(binin2) + " ];", file=self._f)
            print("binout = [" + make_list(binout) + " ];", file=self._f)
            print("bincomm = [" + make_list(bincomm) + " ];", file=self._f)
            print("bingas = [" + make_list(bingas) + " ];", file=self._f)
            print("binsz = [" + make_list(binsz) + " ];", file=self._f)
            if len(binlb) > 0:
                print("binlb = [ " + make_list(binlb) + " ];", file=self._f)
                print("binub = [ " + make_list(binub) + " ];", file=self._f)
            else:
                print(f"binlb =  [ {0} ];", file=self._f)
                print(f"binub =  [ {0} ];", file=self._f)
        if len(ASSOCIATIVEADDOP) == 0:
            print("NA = 0;", file=self._f)
            print(r"ASSOCIATIVEADDOP = {};", file=self._f)
            print("naddin =  [];", file=self._f)
            print("addin =  [||];", file=self._f)
            print("addout = [];", file=self._f)
            print("addcomm = [];", file=self._f)
            print("addgas = [];", file=self._f)
            print("addsz =  [];", file=self._f)
            print("addlb =  [];", file=self._f)
            print(f"addub =  [];", file=self._f)
        else:
            print("NA = " + str(len(ASSOCIATIVEADDOP)) + ";", file=self._f)
            print("ASSOCIATIVEADDOP = { " + make_list(ASSOCIATIVEADDOP) + " };", file=self._f)
            print("naddin = [" + make_list(naddin) + " ];", file=self._f)
            str_addin = "[|" + "|".join(make_list(sublist) for sublist in addin) + "|]"
            print("addin =" + str_addin + ";", file=self._f)
            print("addout = [" + make_list(addout) + " ];", file=self._f)
            print("addcomm = [" + make_list(addcomm) + " ];", file=self._f)
            print("addgas = [" + make_list(addgas) + " ];", file=self._f)
            print("addsz = [" + make_list(addsz) + " ];", file=self._f)
            if len(addlb) > 0:
                print("addlb = [ " + make_list(addlb) + " ];", file=self._f)
                print("addub = [ " + make_list(addub) + " ];", file=self._f)
            else:
                print(f"addlb =  [ {0} ];", file=self._f)
                print(f"addub =  [ {0} ];", file=self._f)
        if len(PUSHOP) == 0:
            print("NPUSH = 0;", file=self._f)
            print(r"PUSHOP = {};", file=self._f)
            print("pushout = [];", file=self._f)
            print("pushgas = [];", file=self._f)
            print("pushsz =  [];", file=self._f)
            print("pushlb =  [];", file=self._f)
            print(f"pushub =  [];", file=self._f)
        else:
            print("NPUSH = " + str(len(PUSHOP)) + ";", file=self._f)
            print("PUSHOP = { " + make_list(PUSHOP) + " };", file=self._f)
            print("pushout = [ " + make_list(pushout) + " ];", file=self._f)
            print("pushgas = [ " + make_list(pushgas) + " ];", file=self._f)
            print("pushsz = [ " + make_list(pushsz) + " ];", file=self._f)
            if len(pushlb) > 0:
                print("pushlb = [ " + make_list(pushlb) + " ];", file=self._f)
                print("pushub = [ " + make_list(pushub) + " ];", file=self._f)
            else:
                print(f"pushlb =  [ {0} ];", file=self._f)
                print(f"pushub =  [ {0} ];", file=self._f)
        if len(STOROP) == 0:
            print("NSTORE = 0;", file=self._f)
            print(r"STOROP = {};", file=self._f)
            print("storin1 =  [];", file=self._f)
            print("storin2 =  [];", file=self._f)
            print("storlb =  [];", file=self._f)
            print(f"storub =  [];", file=self._f)
            print("storgas = [];", file=self._f)
            print("storsz = [];", file=self._f)
        else:
            print("NSTORE = " + str(len(STOROP)) + ";", file=self._f)
            print("STOROP = { " + make_list(STOROP) + " };", file=self._f)
            print("storin1 = [" + make_list(storin1) + " ];", file=self._f)
            print("storin2 = [" + make_list(storin2) + " ];", file=self._f)
            print("storgas = [ " + make_list(storgas) + " ];", file=self._f)
            print("storsz = [ " + make_list(storsz) + " ];", file=self._f)
            if len(storlb) > 0:
                print("storlb = [ " + make_list(storlb) + " ];", file=self._f)
                print("storub = [ " + make_list(storub) + " ];", file=self._f)
            else:
                print(f"storlb =  [ {0} ];", file=self._f)
                print(f"storub =  [ {0} ];", file=self._f)
        dups += "};"
        swaps += "};"
        print(dups, file=self._f)
        print(swaps, file=self._f)
        startstack = []
        for v in self._initial_stack:
            startstack += ["s" + v[2:-1]]
        if len(self._initial_stack) < self._bs:
            for i in range(self._bs - len(self._initial_stack)):
                startstack += ["null"]
        print("startstack = [ " + make_list(startstack) + " ];", file=self._f)

        endstack = []
        for v in self._final_stack:
            endstack += ["s" + v[2:-1]]
        if len(self._final_stack) < self._bs:
            for i in range(self._bs - len(self._final_stack)):
                endstack += ["null"]
        print("endstack = [ " + make_list(endstack) + " ];", file=self._f)

        before = []
        after = []
        for p in self._mem_order + self._sto_order:
            if p[0] in UNARYOP:
                before += ["U(" + p[0] + ")"]
            elif p[0] in BINARYOP:
                before += ["B(" + p[0] + ")"]
            elif p[0] in STOROP:
                before += ["S(" + p[0] + ")"]
            elif p[0] in PUSHOP:
                before += ["P(" + p[0] + ")"]
            if p[1] in UNARYOP:
                after += ["U(" + p[1] + ")"]
            elif p[1] in BINARYOP:
                after += ["B(" + p[1] + ")"]
            elif p[1] in STOROP:
                after += ["S(" + p[1] + ")"]
            elif p[1] in PUSHOP:
                after += ["P(" + p[1] + ")"]

        #print("before = [ " + make_list(before) + " ];", file=self._f)
        #print("after = [ " + make_list(after) + " ];", file=self._f)

        num_mem = len(self._mem_order)
        if (num_mem == 0):
            mem_dep = "[| |]"
        else: 
            mem_dep = "[|"
            for sublist in self._mem_order:
                mem_dep += make_list_deps(sublist) + "|"
            mem_dep += "]"
        
        num_store = len(self._sto_order)
        if (num_store == 0):
            store_dep = "[| |]"
        else:
            store_dep = "[|"
            for sublist in self._sto_order:
                store_dep += make_list_deps(sublist) + "|"
            store_dep += "]"
        
        print("m_dep_n = " + str(num_mem) + ";", file=self._f)
        print("memory_dependences = " + str(mem_dep) + ";", file=self._f)
        print("s_dep_n = " + str(num_store) + ";", file=self._f)
        print("store_dependences = " + str(store_dep) + ";", file=self._f)

        order_tgt = "[|"
        order_dis = []
        if (self._liberalize == False):
            order_tgt += " |]"
        elif(len(self._order_final_stack) == 0):
            order_tgt += " |]"
        else:
            for sublist in self._order_final_stack:
                order_tgt += " s" + str(sublist[0][2:-1]) + ", s" + str(sublist[1][2:-1]) + " |"
                order_dis += [sublist[2]]         
            order_tgt += "]"
        
        order_dis_p = "[" + make_list(order_dis) + "]"
        print("lib = " + str(self._liberalize).lower() + ";", file=self._f)
        print("nlib = " + str(len(order_dis)) + ";", file=self._f)
        print("lib_elem = " + order_tgt + ";", file=self._f)
        print("lib_dis = " + order_dis_p + ";", file=self._f)
        

if __name__ == "__main__":
    with open(sys.argv[1]) as f:
        json_data = json.load(f)

    out_file_name = ""
    if sys.argv[1].endswith(".json"):
        out_file_name = sys.argv[1][:-4] + "dzn"
    else:
        out_file_name = sys.argv[1] + "dzn"
    if len(sys.argv) > 2:
        name = out_file_name
        if '/' in name:
            p = len(name) - 1 - list(reversed(name)).index('/')
            name = name[p + 1:]
        out_file_name = sys.argv[2] + "/" + name

    with open(out_file_name, 'w') as f:
        encoding = SMSgreedy(json_data, f)
        encoding.generate_dzn()




