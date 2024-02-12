%0=NOP 1=POP 2=DUP1 3=DUP2 4=DUP3 5=DUP4 6=SWAP1 7=SWAP2 8=SWAP3

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
array[1..s] of var 0..8: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Nop
constraint forall (i in 1..s, j in 1..n , z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

% Pop
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] == null));

% Dup 1
constraint forall (i in 1..s, j in 2..n  where (program[i] == 2)) ((states[i,1] != null)/\(states[i+1,1] = states[i,1])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));
% Dup 2
constraint forall (i in 1..s, j in 2..n  where (program[i] == 3)) ((states[i,2] != null)/\(states[i+1,1] = states[i,2])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));
% Dup 3
constraint forall (i in 1..s, j in 2..n  where (program[i] == 4)) ((states[i,3] != null)/\(states[i+1,1] = states[i,3])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));
% Dup 4
constraint forall (i in 1..s, j in 2..n  where (program[i] == 5)) ((states[i,4] != null)/\(states[i+1,1] = states[i,4])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 6)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 7)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 3
constraint forall (i in 1..s, j in 2..n where (program[i] == 8)/\(j != 4)) ((states[i,1] != null)/\(states[i,4] != null)/\(states[i+1,1] == states[i,4])/\(states[i+1,4] == states[i,1])/\(states[i+1,j] == states[i,j]));