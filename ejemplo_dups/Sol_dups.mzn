%0=NOP 1=DUP1 2=DUP2 3=DUP3 4=DUP4 5=DUP5

% Constantes
enum TERM = { '.', s0, s1};
int: s = 3; % init_progr_len
int: n = 5; % max_sk_sz
TERM: null = '.'; %string que representa null

%Listas del tamaño maximo del stack que contienen variables de TERM
array[1..n] of TERM: startstack = [ s0, s1, null, null, null ];
array[1..n] of TERM: endstack = [ s0, s1, s0, s0, s1 ];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..5: program;

% Assert
% Constraints
% Start stack and End stack
constraint forall (i in 1..n) (states[1,i] == startstack[i]);
constraint forall (i in 1..n) (states[s+1,i] == endstack[i]);

%NOP
constraint forall (i in 1..s, j in 1..n, z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

%DUP1
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,1] = states[i,1])/\(states[i+1,j+1] = states[i,j])/\(states[i,n] = null));
%DUP2
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 2)) ((states[i,2] != null)/\(states[i+1,1] = states[i,2])/\(states[i+1,j+1] = states[i,j])/\(states[i,n] = null));
%DUP3
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 3)) ((states[i,3] != null)/\(states[i+1,1] = states[i,3])/\(states[i+1,j+1] = states[i,j])/\(states[i,n] = null));
%DUP4
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 4)) ((states[i,4] != null)/\(states[i+1,1] = states[i,4])/\(states[i+1,j+1] = states[i,j])/\(states[i,n] = null));
%DUP5
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 5)) ((states[i,5] != null)/\(states[i+1,1] = states[i,5])/\(states[i+1,j+1] = states[i,j])/\(states[i,n] = null));

solve satisfy;