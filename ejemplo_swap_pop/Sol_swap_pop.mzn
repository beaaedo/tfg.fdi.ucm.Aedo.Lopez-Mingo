%0=NOP 1=SWAP1 2=SWAP2 3=SWAP3 4=SWAP4 5=SWAP5 6=POP

% Constantes
enum TERM = {'.', s0, s1, s2, s3, s4};
int: s = 4; % init_progr_len
int: n = 6; % max_sk_sz
TERM: null = '.'; %string que representa null

%Listas del tamaño maximo del stack que contienen variables de TERM
array[1..n] of TERM: startstack = [s0, s1, s2, s3, s4, null];
array[1..n] of TERM: endstack = [s4, s3, s2, null, null, null];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..6: program;

% Assert
% Constraints
% Start stack and End stack
constraint forall (i in 1..n) (states[1,i] == startstack[i]);
constraint forall (i in 1..n) (states[s+1,i] == endstack[i]);

%NOP
constraint forall (i in 1..s, j in 1..n, z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

%SWAP1
constraint forall (i in 1..s, j in 2..n where ((program[i] == 1)/\(j != 2))) ((states[i,1] != null)/\(states[i,2] != null)/\(states[i+1,1] = states[i,2])/\(states[i+1,2] = states[i,1])/\(states[i+1,j] = states[i,j]));
%SWAP2
constraint forall (i in 1..s, j in 2..n where ((program[i] == 2)/\(j != 3))) ((states[i,1] != null)/\(states[i,3] != null)/\(states[i+1,1] = states[i,3])/\(states[i+1,3] = states[i,1])/\(states[i+1,j] = states[i,j]));
%SWAP3
constraint forall (i in 1..s, j in 2..n where ((program[i] == 3)/\(j != 4))) ((states[i,1] != null)/\(states[i,4] != null)/\(states[i+1,1] = states[i,4])/\(states[i+1,4] = states[i,1])/\(states[i+1,j] = states[i,j]));
%SWAP4
constraint forall (i in 1..s, j in 2..n where ((program[i] == 4)/\(j != 5))) ((states[i,1] != null)/\(states[i,5] != null)/\(states[i+1,1] = states[i,5])/\(states[i+1,5] = states[i,1])/\(states[i+1,j] = states[i,j]));
%SWAP5
constraint forall (i in 1..s, j in 2..n where ((program[i] == 5)/\(j != 6))) ((states[i,1] != null)/\(states[i,6] != null)/\(states[i+1,1] = states[i,6])/\(states[i+1,6] = states[i,1])/\(states[i+1,j] = states[i,j]));
%POP
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 6)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null));

solve satisfy;