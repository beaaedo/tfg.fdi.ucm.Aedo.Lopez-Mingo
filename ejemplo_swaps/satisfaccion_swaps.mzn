%1=SWAP1 2=SWAP2 3=SWAP3

% "SWAP3 SWAP1 SWAP3 SWAP2"

% Constantes
enum TERM = { '.', s0, s1, s2, s3};
int: s = 4; % init_progr_len
int: n = 5; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ s0, s1, s2, s3, null];
array[1..n] of TERM: endstack = [ s2, s3, s0, s1 , null];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 1..3: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 1)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));

% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 2)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));

% Swap 3 
constraint forall (i in 1..s, j in 2..n where (program[i] == 3)/\(j != 4)) ((states[i,1] != null)/\(states[i,4] != null)/\(states[i+1,1] == states[i,4])/\(states[i+1,4] == states[i,1])/\(states[i+1,j] == states[i,j]));