%0=NOP 1=POP 2=DUP1 3=DUP2 4=DUP3 5=SWAP1 6=SWAP2 7=ISZERO_0 8=PUSH_0

% Constantes
enum TERM = { '.', s0, s3, s5};
int: s = 5; % init_progr_len
int: n = 3; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ s0, null, null];
array[1..n] of TERM: endstack = [ s3, s5, s3];

%Datos de las operaciones unarias
enum UNARYOP = {ISZERO_0};
int: N1 = card(UNARYOP);
array[1..N1] of TERM: unin = [s0];
array[1..N1] of TERM: unout = [s3];

%Datos de las operaciones push
enum PUSHOP = {PUSH_0};
int: NP = card(PUSHOP);
array[1..NP] of TERM: pushout = [s5];

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

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 5)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 6)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));

% IsZero 0
constraint forall (i in 1..s , j in 2..n , z in 1..card(UNARYOP) where (program[i] == 7)) ((states[i,1] = unin[z])/\(states[i+1,1] = unout[z])/\(states[i+1,j] = states[i,j]));

% Push 0
constraint forall (i in 1..s , j in 1..n-1 , z in 1..card(PUSHOP) where (program[i] == 8)) ((states[i,n] = null)/\(states[i+1,1] = pushout[z])/\(states[i+1, j+1] = states[i,j]));