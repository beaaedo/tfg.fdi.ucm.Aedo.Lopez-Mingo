%1=POP 2=DUP2 3=SWAP1

% "POP DUP1 SWAP2"

% Constantes
enum TERM = { '.', s0, s1, s2, s3};
int: s = 3; % init_progr_len
int: n = 4; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ s0, s1, s2, null ];
array[1..n] of TERM: endstack = [ s2, s1, s1, null ];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 1..3: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Pop
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] == null));

% Dup 1
constraint forall (i in 1..s, j in 2..n  where (program[i] == 2)) ((states[i,1] != null)/\(states[i+1,1] = states[i,1])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));

% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 3)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));