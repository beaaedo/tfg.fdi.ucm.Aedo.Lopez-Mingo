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
array[1..n, 1..s+1] of var TERM: states;
array[1..s] of var 1..6: program;

% Assert
% Constraints
% Start stack and End stack
constraint forall (i in 1..n) (states[i,1] == startstack[i]);
constraint forall (i in 1..n) (states[i,s+1] == endstack[i]);

%SWAP1
constraint forall (i in 1..s, j in 2..n where ((program[i] == 1)/\(j != 2))) ((states[2,i] != null)/\(states[1,i+1] = states[2,i])/\(states[2,i+1] = states[1,i])/\(states[j,i+1] = states[j,i]));
%SWAP2
constraint forall (i in 1..s, j in 2..n where ((program[i] == 2)/\(j != 3))) ((states[3,i] != null)/\(states[1,i+1] = states[3,i])/\(states[3,i+1] = states[1,i])/\(states[j,i+1] = states[j,i]));
%SWAP3
constraint forall (i in 1..s, j in 2..n where ((program[i] == 3)/\(j != 4))) ((states[4,i] != null)/\(states[1,i+1] = states[4,i])/\(states[4,i+1] = states[1,i])/\(states[j,i+1] = states[j,i]));
%SWAP4
constraint forall (i in 1..s, j in 2..n where ((program[i] == 4)/\(j != 5))) ((states[5,i] != null)/\(states[1,i+1] = states[5,i])/\(states[5,i+1] = states[1,i])/\(states[j,i+1] = states[j,i]));
%SWAP5
constraint forall (i in 1..s, j in 2..n where ((program[i] == 5)/\(j != 6))) ((states[6,i] != null)/\(states[1,i+1] = states[6,i])/\(states[6,i+1] = states[1,i])/\(states[j,i+1] = states[j,i]));
%POP
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 6)) ((states[1,i] != null)/\(states[j,i+1] = states[j+1,i])/\(states[n,i+1] = null));

solve satisfy;