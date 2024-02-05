%0=NOP 1=POP  2=PUSH0  3=DUP2  4=GT 5=POP 6=DUP1 7=DUP2

% Constantes
set of string: TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
string: null; %string que representa null
%set of int: ZEROARYOP;
%array[1..s] of 1..n: zeroout;
%set of int: UNARYOP;
%array[1..s] of 1..n: unin;
%array[1..s] of 1..n: unout;
set of int: BINARYOP = {4};
array[1..s] of 1..n: binin1;
array[1..s] of 1..n: binin2;
array[1..s] of 1..n: binout;

set of int: PUSHOP={2};
array[1..s] of 1..n: pushout;

%Listas del tamaño maximo del stack que contienen variables de TERM
array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..n, 1..s+1] of TERM: states;
array[1..s] of int: program;

% Assert

% Constraints
% Start stack and End stack
constraint forall (i in 1..n) ((states[i,1] == startstack[i])/\(states[i,s+1] == endstack[i]));

% Zeroary operations
%constraint forall (i in index_set(ZEROARYOP), j in 1..s) (program[j] = ZEROARYOP[i]) = (states[1,j+1] = zeroout[i])

% Unary operations
%constraint forall (i in index_set(UNARYOP), j in 1..s) (program[j] = UNARYOP[i]) = ((states[1,j] = unin[i]) /\ (states[1,j+1] unout[i]));

% Binary operations
constraint forall (i in index_set(BINARYOP), j in 1..s) (program[j] = BINARYOP[i]) = ((states[1,j] = binin1[i])/\(states[2,j] = binin2[i])/\(states[1,j+1] = binout[i]));

% Push operations
constraint forall (i in index_set(PUSHOP), j in 1..s, z in 1..n-1) (program[j] = PUSHOP[i]) = ((states[z+1,j+1] = states[z,j])/\(states[1,j+1] = pushout[i]));

%NOPs, si una operación es un NOP, las siguientes deben serlo también
constraint forall (j in 1..s, i in j+1..s) ((program[j] = 0) = (program[i] = 0));

%POP
constraint forall (i in 1..s, j in 1..n-1) (program[i] = 5) = ((states[j,i+1] = states[j+1,i])/\(states[j,i+1] = null));

%DUP1
constraint forall (i in 1..s, j in 2..n-1) (program[i] = 6) = ((states[2,i+1] = states[1,i])/\(states[1,i+1] = states[1,i])/\(states[j+1,i+1] = states[j,i]))
%DUP2
constraint forall (i in 1..s, j in 3..n-1) (program[i] = 7) = ((states[2,i+1] = states[1,i])/\(states[1,i+1] = states[1,i])/\(states[3,i+1] = states[2,i])/\(states[4,i+1] = states[2,i])/\(states[j+2,i+1] = states[j,i]));

% Solución