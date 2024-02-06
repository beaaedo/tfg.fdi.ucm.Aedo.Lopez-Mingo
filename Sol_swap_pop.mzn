%0=NOP 1=SWAP1 2=SWAP2 3=SWAP3 4=SWAP4 5=SWAP5 6=POP

% Constantes
int: s = 4; % init_progr_len
int: n = 6; % max_sk_sz
int: null = -1; %string que representa null

array[1..n] of int: startstack = [0,1,2,3,4,null];
array[1..n] of int: endstack = [4,3,2,null,null,null];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..n, 1..s+1] of var int: states;
array[1..s] of var 0..6: program;

% Assert
% Constraints
% Start stack and End stack
constraint forall (i in 1..n) ((states[i,1] == startstack[i])/\(states[i,s+1] == endstack[i]));

%NOPs, si una operación es un NOP, las siguientes deben serlo también
constraint forall (j in 1..s, i in j..s, z in 1..n) ((program[j] = 0) = ((program[i] = 0)/\(states[z,i+1] = states[z,i])));

%SWAP1
constraint forall(i in 1..s, j in 3..n) ((program[i] = 1) = ((states[1,i] != null)/\(states[2,i] != null)/\(states[1,i+1] = states[2,i])/\(states[2,i+1] = states[1,i])/\(states[j,i+1] = states[j,i])));
%SWAP2
constraint forall(i in 1..s, j in 4..n) ((program[i] = 2) = ((states[1,i] != null)/\(states[3,i] != null)/\(states[1,i+1] = states[3,i])/\(states[3,i+1] = states[1,i])/\(states[j,i+1] = states[j,i])/\(states[2,i+1] = states[2,i])));
%SWAP3
constraint forall(i in 1..s, j in 5..n, z in 2..3) ((program[i] = 3) = ((states[1,i] != null)/\(states[4,i] != null)/\(states[1,i+1] = states[4,i])/\(states[4,i+1] = states[1,i])/\(states[j,i+1] = states[j,i])/\(states[z,i+1] = states[z,i])));
%SWAP4
constraint forall(i in 1..s, j in 2..4) ((program[i] = 4) = ((states[1,i] != null)/\(states[5,i] != null)/\(states[1,i+1] = states[5,i])/\(states[5,i+1] = states[1,i])/\(states[j,i+1] = states[j,i])/\(states[6,i+1] = states[6,i])));
%SWAP5
constraint forall(i in 1..s, j in 2..5) ((program[i] = 5) = ((states[1,i] != null)/\(states[6,i] != null)/\(states[1,i+1] = states[6,i])/\(states[6,i+1] = states[1,i])/\(states[j,i+1] = states[j,i])));

%POP
constraint forall (i in 1..s, j in 1..n-1) ((program[i] = 6) = ((states[j,i+1] = states[j+1,i])/\(states[n,i+1] = null)/\(states[1,i] != null)));

% Solución
solve satisfy;