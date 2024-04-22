# Auxiliary definitions

    - Id = str  -> an identifier used to identify a term (function symbol + args) unequivocally. 
    - Var = str -> shallow term that represents the value of a computation. Not every term has
                   a Var associated

## Comments on the relation between Id and Var:

    - Store operations have an Id but not a Var, because storing a term produces no computation
      as a result. 
    - Instructions with different Ids could share the same Var (not implemented yet).
      For instance, lt(a,b) and gt(b,a) compute the same value and hence, the same
      Var. However, they are distinct terms and have different ids.

# Mandatory parameters (must appear as keys in the JSON, marked with *)

## Global params:
    
* `init_progr_len` : int -> max number of operations in a sequence
* `vars` : List[Var] -> list of Vars that appear in our representation
* `original_instrs` : str -> textual representation of the initial sequence

## Stack parameters

* `max_sk_sz` : int -> max size the stack can reach during symbolic execution
* `src_ws` : List[Var] -> flattened list of Vars that represent the contents of the stack 
                          before executing the sequence. Vars sorted from top to bottom
* `tgt_ws` : List[Var] -> flattened list of Vars that represent the contents of the stack 
                          after executing the sequence. Vars sorted from top to bottom

## Instructions

* `user_instrs` : List[Instr] -> list of the terms that appear in the final state  
  
  where Instr : Dict that contains the following keys:
  
     * `id` : Id -> term identifier
     * `opcode` : str -> hexadecimal representation 
     * `disasm` : str -> textual representation of the function symbol
     * `inpt_sk` : List[Var] -> list of args of the term, ordered from left to
                                right
     * `outpt_sk` : List[Var] -> list of vars to represent the value of the computation associated
                                 to the term. It can be an empty list 
                                 (for instance, store operations), or contain
                                 more than one element (for instance, call operations in Wasm)
     * `push` : bool -> the function symbol represents an instruction that introduces a constant (PUSH)
     * `commutative` : bool -> the function symbol is commutative or not
     * `storage` : bool -> marks the operation is a Store operation or not. 
                           In a broad sense, it means this operation must 
                           be performed even if it does not appear 
                           as a computation in the final state.
     * `gas` : int -> cost of the function symbol w.r.t. corresponding 
                      optimization criterion. For Wasm, it is set to 1.
     * `size` : int -> cost of the function symbol w.r.t. corresponding 
                       optimization criterion. For Wasm, it is set to 1.
     
     
## Dependencies

* `dependencies` : List[Tuple[Id, Id]] -> list of tuples [Id1, Id2] that enforce that the term represented
                                          by Id1 must be computed before Id2. It does not include subterm
                                          dependencies (i.e. dependencies among subterms and the terms they are
                                          embedded)

# Optional parameters (can appear or not as keys in the JSON)

## Registers (a broader generalization of locals)
  
* `max_registers_sz` : int -> Max number of additional registers that can be used.
                              Neither their initial contents nor their final ones are
                              relevant, so we just specify the number
  
* `register_changes` : List[Tuple[Var, Var]] -> List of tuples [Var1, Var2] that represents the registers 
                                                whose initial and final values are relevant.
                                                Var1 represents the contents before the execution, and
                                                Var2 represents the contents after the execution.       
  

## Extra useful information

* `min_length` : int -> Lower bound on the number of operations a valid sequence must contain.
                        It can be inferred using static analysis techniques.
* `original_instrs_with_ids` : List[Id] -> List of Ids that represent the initial sequence we
                                           have considered. Useful to calculate the initial cost
                                           w.r.t. a criterion
* `instr_dependencies` : Dict[Id, Tuple[Id, Id]] -> dependencies that are inferred directly from 
                                                    subterms to terms. 
* `lower_bounds` : Dict[Id, int] -> for each term, first position in which it can appear in a sequence
* `upper_bounds` : Dict[Id, int] -> for each term, last position in which it can appear in a sequence
                                    assuming a sequence of 'init_progr_len' instructions
