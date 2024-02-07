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
array[1..n, 1..s+1] of var TERM: states;
array[1..s] of var 1..5: program;

% Assert
% Constraints
% Start stack and End stack
constraint forall (i in 1..n) (states[i,1] == startstack[i]);
constraint forall (i in 1..n) (states[i,s+1] == endstack[i]);

%DUP1
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[1,i] != null)/\(states[1,i+1] = states[1,i])/\(states[j+1,i+1] = states[j,i])/\(states[n,i] = null));
%DUP2
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 2)) ((states[2,i] != null)/\(states[1,i+1] = states[2,i])/\(states[j+1,i+1] = states[j,i])/\(states[n,i] = null));
%DUP3
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 3)) ((states[3,i] != null)/\(states[1,i+1] = states[3,i])/\(states[j+1,i+1] = states[j,i])/\(states[n,i] = null));
%DUP4
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 4)) ((states[4,i] != null)/\(states[1,i+1] = states[4,i])/\(states[j+1,i+1] = states[j,i])/\(states[n,i] = null));
%DUP5
constraint forall (i in 1..s, j in 1..n-1 where(program[i] == 5)) ((states[5,i] != null)/\(states[1,i+1] = states[5,i])/\(states[j+1,i+1] = states[j,i])/\(states[n,i] = null));

solve satisfy;