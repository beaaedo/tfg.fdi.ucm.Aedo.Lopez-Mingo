%0=NOP 1=POP 2=DUP1 3=DUP2 4=DUP3 5=DUP4 6=DUP5 7=SWAP1 8=SWAP2 9=SWAP3 10=SWAP4 11=SUB_0 12=ADD_0

% Constantes
enum TERM = { '.', s0, s1, s2, s3, s4};
int: s = 4; % init_progr_len
int: n = 5; % max_sk_sz
TERM: null = '.';

array[1..n] of TERM: startstack = [ s0, s1, s2, null, null];
array[1..n] of TERM: endstack = [ s3, null, null, null, null];

%Datos de las operaciones binarias
enum BINARYOP = {SUB_0, ADD_0};
int: N2 = card(BINARYOP);
array[1..N2] of TERM: binin1 = [s2, s1];
array[1..N2] of TERM: binin2 = [s4, s0];
array[1..N2] of TERM: binout = [s3, s4];
array[1..N2] of bool: bincomm = [false, true];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..12: program;

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
% Dup 4
constraint forall (i in 1..s, j in 2..n  where (program[i] == 5)) ((states[i,4] != null)/\(states[i+1,1] = states[i,4])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));
% Dup 5
constraint forall (i in 1..s, j in 2..n  where (program[i] == 6)) ((states[i,5] != null)/\(states[i+1,1] = states[i,5])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));

% Swap 1
constraint forall (i in 1..s, j in 2..n where (program[i] == 7)/\(j != 2)) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] == states[i,2])/\(states[i+1,2] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 2
constraint forall (i in 1..s, j in 2..n where (program[i] == 8)/\(j != 3)) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] == states[i,3])/\(states[i+1,3] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 3
constraint forall (i in 1..s, j in 2..n where (program[i] == 9)/\(j != 4)) ((states[i,1] != null)/\(states[i,4] != null)/\(states[i+1,1] == states[i,4])/\(states[i+1,4] == states[i,1])/\(states[i+1,j] == states[i,j]));
% Swap 4
constraint forall (i in 1..s, j in 2..n where (program[i] == 10)/\(j !=5)) ((states[i,1] != null)/\(states[i,5] != null)/\(states[i+1,1] == states[i,5])/\(states[i+1,5] == states[i,1])/\(states[i+1,j] == states[i,j]));

%SUB_0
%No conmutativas
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 11)/\(not bincomm[1]))) ((states[i,1] = binin1[1])/\(states[i,2] = binin2[1])/\(states[i+1,1] = binout[1])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));
%Conmutativas
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 11)/\(bincomm[1]))) ((((states[i,1] = binin1[1])/\(states[i,2] = binin2[1]))\/((states[i,1] = binin2[1])/\(states[i,2] = binin1[1])))/\(states[i+1,1] = binout[1])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));

%ADD_0
%No conmutativas
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 12)/\(not bincomm[2]))) ((states[i,1] = binin1[2])/\(states[i,2] = binin2[2])/\(states[i+1,1] = binout[2])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));
%Conmutativas
constraint forall (i in 1..s , j in 2..n-1 where ((program[i] == 12)/\(bincomm[2]))) ((((states[i,1] = binin1[2])/\(states[i,2] = binin2[2]))\/((states[i,1] = binin2[2])/\(states[i,2] = binin1[2])))/\(states[i+1,1] = binout[2])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));