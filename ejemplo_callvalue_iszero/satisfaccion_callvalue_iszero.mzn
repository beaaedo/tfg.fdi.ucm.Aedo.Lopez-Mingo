% "CALLVALUE ISZERO CALLVALUE ISZERO"

% 0=NOP

% Constantes
enum TERM = { '.', s2, s3};
int: s = 4; % init_progr_len
int: n = 2; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ null, null];
array[1..n] of TERM: endstack = [ s3, s3];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 1..3: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

%NOP
constraint forall (i in 1..s, j in 1..n, z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));
