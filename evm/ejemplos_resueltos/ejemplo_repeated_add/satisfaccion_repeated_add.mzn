%0=NOP 1=POP 2=DUP1 3=DUP2 4=DUP3 5=SWAP1 6=SWAP2 7=ADD_0

% Constantes
enum TERM = { '.', s0, s1, s2};
int: s = 5; % init_progr_len
int: n = 3; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ s0, s1, null];
array[1..n] of TERM: endstack = [ s2, s2, null];

%Datos de las operaciones binarias
enum BINARYOP = {ADD_0};
int: N2 = card(BINARYOP);
array[1..N2] of TERM: binin1 = [s1];
array[1..N2] of TERM: binin2 = [s0];
array[1..N2] of TERM: binout = [s2];
array[1..N2] of bool: bincomm = [true];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..7: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

%Condicion nulls
constraint forall (i in 1..s, j in 1..n, z in j..n where (states[i,j] == null)) (states[i,z] = null);

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

%ADD_0
%No conmutativa
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 7)/\(not bincomm[1]))) ((states[i,1] = binin1[1])/\(states[i,2] = binin2[2])/\(states[i+1,1] = binout[1])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));
%Conmutativa
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 7)/\(bincomm[1]))) ((((states[i,1] = binin1[1])/\(states[i,2] = binin2[1]))\/((states[i,1] = binin2[1])/\(states[i,2] = binin1[1])))/\(states[i+1,1] = binout[1])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));