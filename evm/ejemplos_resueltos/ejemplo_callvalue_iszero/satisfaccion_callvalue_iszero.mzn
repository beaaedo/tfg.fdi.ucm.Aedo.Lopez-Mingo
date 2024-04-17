% "CALLVALUE ISZERO CALLVALUE ISZERO"

%0=NOP 1=POP 2=ZEROARYOP 3=UNARYOP

% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
TERM: null;

enum ZEROARYOP;
int: n_ZEROARYOP = card(ZEROARYOP);
array [1..n_ZEROARYOP] of TERM: zeroout;
array [1..n_ZEROARYOP] of int: zerogas;
array [1..n_ZEROARYOP] of int: zerosz;
array [1..n_ZEROARYOP] of int: zerolb;
array [1..n_ZEROARYOP] of int: zeroub;

enum UNARYOP;
int: n_UNARYOP = card(UNARYOP);
array [1..n_UNARYOP] of TERM: unin;
array [1..n_UNARYOP] of TERM: unout;
array [1..n_UNARYOP] of int: ungas;
array [1..n_UNARYOP] of int: unsz;
array [1..n_UNARYOP] of int: unlb;
array [1..n_UNARYOP] of int: unub;

array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..3: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

%NOP
constraint forall (i in 1..s, j in 1..n, z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

% Pop
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] == null));

% ZEROARY OP
constraint forall (y in 1..n_ZEROARYOP, i in 1..s, j in 2..n where (program[i] == 2)) ((states[i+1,1] = zeroout[y])/\(states[i+1,j] = states[i,j-1]));

% UNARY OP
constraint forall (y in 1..n_UNARYOP,i in 1..s, j in 2..n where (program[i] == 3)) ((states[i,1] = unin[y])/\(states[i+1,1] = unout[y])/\(states[i+1,j] = states[i,j]));