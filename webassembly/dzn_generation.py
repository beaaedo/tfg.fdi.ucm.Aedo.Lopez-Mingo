#!/usr/bin/env python3

# use it with
# python3 dzn_generator file.json

# --solver = chuffed

import json
import os
import sys

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


class SMSgreedy:

    def __init__(self, json_format, file=sys.stdout):
        self._bs = json_format['max_sk_sz']
        self._user_instr = json_format['user_instrs']
        self._b0 = json_format["init_progr_len"]
        self._initial_stack = json_format['src_ws']
        self._final_stack = json_format['tgt_ws']
        self._variables = json_format['vars']
        self._dependencies = json_format['dependencies']
        self._rules = json_format['rules']
        #self._mem_order = json_format['memory_dependences']
        #self._sto_order = json_format['storage_dependences']
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
        unstor = []
        ZEROARYOP = []
        zeout = []
        zegas = []
        zesz = []
        zelb = []
        zeub = []
        zestor = []
        BINARYOP = []
        binin1 = []
        binin2 = []
        binout = []
        bincomm = []
        bingas = []
        binsz = []
        binlb = []
        binub = []
        binstor = []
        TERNARYOP = []
        terin1 = []
        terin2 = []
        terin3 = []
        terout1 = []
        terout2 = []
        terout3 = []
        tercomm = []
        tergas = []
        tersz = []
        terlb = []
        terub = []
        terstor = []

        for ins in self._user_instr:
            if len(ins["inpt_sk"]) == 0 and len(ins["outpt_sk"]) == 1:
                ZEROARYOP += [ins["id"]]
                zeout += [ins["outpt_sk"][0]]
                zegas += [str(ins["gas"])]
                zesz += [str(ins["size"])]
                zestor += [str(ins["storage"])]
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
                    unin += [ins["inpt_sk"][0]]
                unout += [ins["outpt_sk"][0]]
                ungas += [str(ins["gas"])]
                unsz += [str(ins["size"])]
                unstor += [str(ins["storage"])]
                if len(self._lower_bounds) > 0:
                    unlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    unub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    unlb += [str(1)]
                    unub += [str(self._b0)]
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
                    binin1 += [ins["inpt_sk"][0]]
                if isinstance(ins["inpt_sk"][1], int):
                    i = len(constants)
                    if ins["inpt_sk"][1] in constants:
                        i = constants.index(ins["inpt_sk"][1])
                    else:
                        constants += [ins["inpt_sk"][1]]
                    binin2 += ["c" + str(i)]
                else:
                    binin2 += [ins["inpt_sk"][1]]
                binout += [ins["outpt_sk"][0]]
                bincomm += [str(ins["commutative"]).lower()]
                bingas += [str(ins["gas"])]
                binsz += [str(ins["size"])]
                binstor += [str(ins["storage"])]
                if len(self._lower_bounds) > 0:
                    binlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    binub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    binlb += [str(1)]
                    binub += [str(self._b0)]
            elif len(ins["inpt_sk"]) == 3 and len(ins["outpt_sk"]) == 3:   
                TERNARYOP += [ins["id"]]
                if isinstance(ins["inpt_sk"][0], int):
                    i = len(constants)
                    if ins["inpt_sk"][0] in constants:
                        i = constants.index(ins["inpt_sk"][0])
                    else:
                        constants += [ins["inpt_sk"][0]]
                    terin1 += ["c" + str(i)]
                else:
                    terin1 += [ins["inpt_sk"][0]]
                if isinstance(ins["inpt_sk"][1], int):
                    i = len(constants)
                    if ins["inpt_sk"][1] in constants:
                        i = constants.index(ins["inpt_sk"][1])
                    else:
                        constants += [ins["inpt_sk"][1]]
                    terin2 += ["c" + str(i)]
                else:
                    terin2 += [ins["inpt_sk"][1]]
                if isinstance(ins["inpt_sk"][2], int):
                    i = len(constants)
                    if ins["inpt_sk"][3] in constants:
                        i = constants.index(ins["inpt_sk"][2])
                    else:
                        constants += [ins["inpt_sk"][2]]
                    terin3 += ["c" + str(i)]
                else:
                    terin3 += [ins["inpt_sk"][2]]
                if isinstance(ins["outpt_sk"][0], int):
                    i = len(constants)
                    if ins["outpt_sk"][0] in constants:
                        i = constants.index(ins["outpt_sk"][0])
                    else:
                        constants += [ins["outpt_sk"][0]]
                    terout1 += ["c" + str(i)]
                else:
                    terout1 += [ins["outpt_sk"][0]]
                if isinstance(ins["outpt_sk"][1], int):
                    i = len(constants)
                    if ins["outpt_sk"][1] in constants:
                        i = constants.index(ins["outpt_sk"][1])
                    else:
                        constants += [ins["outpt_sk"][1]]
                    terout2 += ["c" + str(i)]
                else:
                    terout2 += [ins["outpt_sk"][1]]
                if isinstance(ins["outpt_sk"][2], int):
                    i = len(constants)
                    if ins["outpt_sk"][3] in constants:
                        i = constants.index(ins["outpt_sk"][2])
                    else:
                        constants += [ins["outpt_sk"][2]]
                    terout3 += ["c" + str(i)]
                else:
                    terout3 += [ins["outpt_sk"][2]]
                tercomm += [str(ins["commutative"]).lower()]
                tergas += [str(ins["gas"])]
                tersz += [str(ins["size"])]
                terstor += [str(ins["storage"])]
                if len(self._lower_bounds) > 0:
                    terlb += [str(self._lower_bounds[ins["id"]] + 1)]
                    terub += [str(self._upper_bounds[ins["id"]] + 1)]
                else:
                    terlb += [str(1)]
                    terub += [str(self._b0)]
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
        print("dependencies = " + str(self._dependencies) + ";", file=self._f)
        print("rules = " + str(self._rules) + ";", file=self._f)
        # print("min = " + str(self._min_length) + ";", file=self._f)
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
            print("zerostor =  [];", file=self._f)
            print("zerolb =  [];", file=self._f)
            print(f"zeroub =  [];", file=self._f)
        else:
            print("N0 = " + str(len(ZEROARYOP)) + ";", file=self._f)
            print("ZEROARYOP = { " + make_list(ZEROARYOP) + " };", file=self._f)
            print("zeroout = [ " + make_list(zeout) + " ];", file=self._f)
            print("zerogas = [ " + make_list(zegas) + " ];", file=self._f)
            print("zerosz = [ " + make_list(zesz) + " ];", file=self._f)
            print("zerostor = [ " + make_list(zestor) + " ];", file=self._f)
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
            print("unstor =  [];", file=self._f)
            print("unlb =  [];", file=self._f)
            print(f"unub =  [];", file=self._f)
        else:
            print("N1 = " + str(len(UNARYOP)) + ";", file=self._f)
            print("UNARYOP = { " + make_list(UNARYOP) + " };", file=self._f)
            print("unin = [ " + make_list(unin) + " ];", file=self._f)
            print("unout = [ " + make_list(unout) + " ];", file=self._f)
            print("ungas = [ " + make_list(ungas) + " ];", file=self._f)
            print("unsz = [ " + make_list(unsz) + " ];", file=self._f)
            print("unstor = [ " + make_list(unstor) + " ];", file=self._f)
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
            print("binstor =  [];", file=self._f)
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
            print("binstor = [" + make_list(binstor) + " ];", file=self._f)
            if len(binlb) > 0:
                print("binlb = [ " + make_list(binlb) + " ];", file=self._f)
                print("binub = [ " + make_list(binub) + " ];", file=self._f)
            else:
                print(f"binlb =  [ {0} ];", file=self._f)
                print(f"binub =  [ {0} ];", file=self._f)
        if len(TERNARYOP) == 0:
            print("N3 = 0;", file=self._f)
            print(r"TERNARYOP = {};", file=self._f)
            print("terin1 =  [];", file=self._f)
            print("terin2 =  [];", file=self._f)
            print("terin3 =  [];", file=self._f)
            print("terout1 = [];", file=self._f)
            print("terout2 = [];", file=self._f)
            print("terout3 = [];", file=self._f)
            print("tercomm = [];", file=self._f)
            print("tergas = [];", file=self._f)
            print("tersz =  [];", file=self._f)
            print("terstor =  [];", file=self._f)
            print("terlb =  [];", file=self._f)
            print(f"terub =  [];", file=self._f)
        else:
            print("N3 = " + str(len(TERNARYOP)) + ";", file=self._f)
            print("TERNARYOP = { " + make_list(TERNARYOP) + " };", file=self._f)
            print("terin1 = [" + make_list(terin1) + " ];", file=self._f)
            print("terin2 = [" + make_list(terin2) + " ];", file=self._f)
            print("terin3 = [" + make_list(terin3) + " ];", file=self._f)
            print("terout1 = [" + make_list(terout1) + " ];", file=self._f)
            print("terout2 = [" + make_list(terout2) + " ];", file=self._f)
            print("terout3 = [" + make_list(terout3) + " ];", file=self._f)
            print("tercomm = [" + make_list(tercomm) + " ];", file=self._f)
            print("tergas = [" + make_list(tergas) + " ];", file=self._f)
            print("tersz = [" + make_list(tersz) + " ];", file=self._f)
            print("terstor = [" + make_list(terstor) + " ];", file=self._f)
            if len(terlb) > 0:
                print("terlb = [ " + make_list(terlb) + " ];", file=self._f)
                print("terub = [ " + make_list(terub) + " ];", file=self._f)
            else:
                print(f"terlb =  [ {0} ];", file=self._f)
                print(f"terub =  [ {0} ];", file=self._f)
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

        #print("before = [ " + make_list(before) + " ];", file=self._f)
        #print("after = [ " + make_list(after) + " ];", file=self._f)


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




