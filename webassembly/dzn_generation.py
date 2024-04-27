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
        self._max_registers_sz = json_format['max_registers_sz']
        self._register_changes = json_format['register_changes']
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
        
        in_ops = []
        out_ops = []

        OP = []
        in1 = []
        in2 = []
        in3 = []
        out1 = []
        out2 = []
        out3 = []
        comm = []
        gas = []
        sz = []
        lb = []
        ub = []
        stor = []

        for ins in self._user_instr:
            n_in = len(ins["inpt_sk"])
            n_out = len(ins["outpt_sk"])

            in_ops += [n_in]
            out_ops += [n_out]

            comm_op = "false"

            if (n_in > 0):
                in1 += ["'" + ins["inpt_sk"][0] + "'"]
            else:
                in1 += ["'.'"]
            if (n_in > 1):
                in2 += ["'" + ins["inpt_sk"][1] + "'"]
                comm_op = str(ins["commutative"]).lower()
            else:
                in2 += ["'.'"]
            if (n_in > 2):
                in3 += ["'" + ins["inpt_sk"][2] + "'"]
            else:
                in3 += ["'.'"]

            if (n_out > 0):
                out1 += ["'" + ins["outpt_sk"][0] + "'"]
            else:
                out1 += ["'.'"]
            if (n_out > 1):
                out2 += ["'" + ins["outpt_sk"][1] + "'"]
            else:
                out2 += ["'.'"]
            if (n_out > 2):
                out3 += ["'" + ins["outpt_sk"][2] + "'"]
            else:
                out3 += ["'.'"]
            
            if (n_in > 3) or (n_out > 3):
                print(ins["id"], file=self._f)
                raise Exception("Unsuported operation")
            
            comm += [comm_op]
            gas += [str(ins["gas"])]
            sz += [str(ins["size"])]
            stor += [str(ins["storage"]).lower()]
            if len(self._lower_bounds) > 0:
                lb += [str(self._lower_bounds[ins["id"]] + 1)]
                ub += [str(self._upper_bounds[ins["id"]] + 1)]
            else:
                lb += [str(1)]
                ub += [str(self._b0)]
            
            OP += ["'" + ins["id"] + "'"]

        term = "TERM = { \'.\'"
        for v in self._variables:
            term += ", '" + v + "'"
        for v in range(len(constants)):
            term += ", c" + str(v)
        term += "};"
        print(term, file=self._f)
        print("null = \'.\';", file=self._f)
        print("s = " + str(self._b0) + ";", file=self._f)
        print("n = " + str(self._bs) + ";", file=self._f)
        print("ndeps = " + str(len(self._dependencies)) + ";", file=self._f)
        print("max_registers_sz = " + str(self._max_registers_sz) + ";", file=self._f)
        print("NR = " + str(len(self._register_changes)) + ";", file=self._f)

        num_regs = len(self._register_changes)
        if (num_regs == 0):
            reg = "[| |]"
        else: 
            reg = '[' + ', '.join(["|'{}'".format("', '".join(map(str, sublist))) for sublist in self._register_changes]) + '|]'
        print("registers = " + str(reg) + ";", file=self._f)
        
        num_deps = len(self._dependencies)
        if (num_deps == 0):
            dep = "[| |]"
        else: 
            dep = '[' + ', '.join(["|'{}'".format("', '".join(map(str, sublist))) for sublist in self._dependencies]) + '|]'
        print("dependencies = " + str(dep) + ";", file=self._f)


        n_ops = len(self._register_changes) + self._max_registers_sz
        gets = "GET_ENUM = {"
        sets = "SET_ENUM = {"
        tees = "TEE_ENUM = {"
        for x in range(n_ops):
            if x == n_ops - 1: 
                gets += " GET" + str(x + 1)
                sets += " SET" + str(x + 1)
                tees += " TEE" + str(x + 1)
            else: 
                gets += " GET" + str(x + 1) + ","
                sets += " SET" + str(x + 1) + ","
                tees += " TEE" + str(x + 1) + ","
        gets += "};"
        sets += "};"
        tees += "};"

        print(gets, file=self._f)
        print(sets, file=self._f)
        print(tees, file=self._f)

        # print("min = " + str(self._min_length) + ";", file=self._f)
        # print("origsol = "+str(self._original_code_with_ids)+";", file=self._f)
        # print("% when empty means not available", file=self._f)

        if len(OP) == 0:
            print("N = 0;", file=self._f)
            print(r"OP = {};", file=self._f)
            print("in_ops =  [];", file=self._f)
            print("out_ops =  [];", file=self._f)
            print("in1 =  [];", file=self._f)
            print("in2 =  [];", file=self._f)
            print("in3 =  [];", file=self._f)
            print("out1 = [];", file=self._f)
            print("out2 = [];", file=self._f)
            print("out3 = [];", file=self._f)
            print("comm = [];", file=self._f)
            print("gas = [];", file=self._f)
            print("sz =  [];", file=self._f)
            print("stor =  [];", file=self._f)
            print("lb =  [];", file=self._f)
            print(f"ub =  [];", file=self._f)
        else:
            print("N = " + str(len(OP)) + ";", file=self._f)
            print("OP = { " + make_list(OP) + " };", file=self._f)
            print("in_ops = [" + make_list(in_ops) + " ];", file=self._f)
            print("out_ops = [" + make_list(out_ops) + " ];", file=self._f)
            print("in1 = [" + make_list(in1) + " ];", file=self._f)
            print("in2 = [" + make_list(in2) + " ];", file=self._f)
            print("in3 = [" + make_list(in3) + " ];", file=self._f)
            print("out1 = [" + make_list(out1) + " ];", file=self._f)
            print("out2 = [" + make_list(out2) + " ];", file=self._f)
            print("out3 = [" + make_list(out3) + " ];", file=self._f)
            print("comm = [" + make_list(comm) + " ];", file=self._f)
            print("gas = [" + make_list(gas) + " ];", file=self._f)
            print("sz = [" + make_list(sz) + " ];", file=self._f)
            print("stor = [" + make_list(stor) + " ];", file=self._f)
            if len(lb) > 0:
                print("lb = [ " + make_list(lb) + " ];", file=self._f)
                print("ub = [ " + make_list(ub) + " ];", file=self._f)
            else:
                print(f"lb =  [ {0} ];", file=self._f)
                print(f"ub =  [ {0} ];", file=self._f)

        startstack = []
        for v in self._initial_stack:
            startstack += ["'" + v + "'"]
        if len(self._initial_stack) < self._bs:
            for i in range(self._bs - len(self._initial_stack)):
                startstack += ["null"]
        print("startstack = [ " + make_list(startstack) + " ];", file=self._f)

        endstack = []
        for v in self._final_stack:
            endstack += ["'" + v + "'"]
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




