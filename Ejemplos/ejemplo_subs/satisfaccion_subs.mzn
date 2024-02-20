% ""DUP2 DUP2 SUB SWAP2 SUB"

%0=NOP 1=POP 3=BINARYOP

% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
TERM: null;

enum BINARYOP;
int: n_BINARYOP = card(BINARYOP);
array [1..n_BINARYOP] of TERM: binin1;
array [1..n_BINARYOP] of TERM: binin2;
array [1..n_BINARYOP] of TERM: binout;
array [1..n_BINARYOP] of bool: bincomm;
array [1..n_BINARYOP] of int: bingas;
array [1..n_BINARYOP] of int: binsz;
array [1..n_BINARYOP] of int: binlb;
array [1..n_BINARYOP] of int: binub;

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

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 2)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));

% BINARY OP
constraint forall (y in 1..n_BINARYOP,i in 1..s, j in 2..n where ((program[i] == 3)/\( not bincomm[y]))) ((states[i,1] = binin1[y])/\(states[i,2] = binin2[y])/\(states[i+1,1] = binout[y])/\(states[i+1,j] = states[i,j]));

constraint forall (y in 1..n_BINARYOP,i in 1..s, j in 3..n where ((program[i] == 3)/\(bincomm[y]))) (((states[i,1] = binin2[y])\/(states[i,2] = binin2[y]))/\((states[i,1] = binin1[y])\/(states[i,2] = binin1[y]))/\(states[i+1,1] = binout[y])/\(states[i+1,2] = null)/\(states[i+1,j] = states[i,j]));