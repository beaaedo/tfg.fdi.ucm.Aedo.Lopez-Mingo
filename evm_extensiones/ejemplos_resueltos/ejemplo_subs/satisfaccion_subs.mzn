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
array[1..s] of var 0..6: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

%NOP
constraint forall (i in 1..s, j in 1..n, z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

% Pop
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] == null));

% Dup 2
constraint forall (i in 1..s, j in 2..n  where (program[i] == 2)) ((states[i,2] != null)/\(states[i+1,1] = states[i,2])/\(states[i+1,j] == states[i,j-1]));

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 3)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));

% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 4)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));

% BINARY OP - SUB0
constraint forall (i in 1..s, j in 2..n-1 where ((program[i] == 5)/\( not bincomm[1]))) ((states[i,1] = binin1[1])/\(states[i,2] = binin2[1])/\(states[i+1,1] = binout[1])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));

constraint forall (i in 1..s, j in 2..n-1 where ((program[i] == 5)/\(bincomm[1]))) (((states[i,1] = binin2[1])\/(states[i,2] = binin2[1]))/\((states[i,1] = binin1[1])\/(states[i,2] = binin1[2]))/\(states[i+1,1] = binout[2])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));

% BINARY OP - SUB1
constraint forall (i in 1..s, j in 2..n-1 where ((program[i] == 6)/\( not bincomm[2]))) ((states[i,1] = binin1[2])/\(states[i,2] = binin2[2])/\(states[i+1,1] = binout[2])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));

constraint forall (i in 1..s, j in 2..n-1 where ((program[i] == 6)/\(bincomm[2]))) (((states[i,1] = binin2[2])\/(states[i,2] = binin2[2]))/\((states[i,1] = binin1[2])\/(states[i,2] = binin1[2]))/\(states[i+1,1] = binout[2])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));