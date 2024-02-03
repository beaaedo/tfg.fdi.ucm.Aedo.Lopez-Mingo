% Constantes
set of string: TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
%set of int: ZEROARYOP;
%array[1..s] of 1..n: zeroout;
%set of int: UNARYOP;
%array[1..s] of 1..n: unin;
%array[1..s] of 1..n: unout;
set of int: BINARYOP = {4}; %0=NOP 1=POP  2=PUSH  3=DUP2  4=GT
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
array[1..s] of 0..s: program;

% Assert

% Constraints
% Start stack and End stack
constraint forall (i in 1..n) ((states[i,1] == startstack[i])/\(states[i,s+1] == endstack[i]));

% Zeroary operations
%constraint forall (i in index_set(ZEROARYOP), j in 1..s) (program[j] = ZEROARYOP[i]) = (states[1,j+1] = zeroout[i])

% Unary operations
%constraint forall (i in index_set(UNARYOP), j in 1..s) (program[j] = UNARYOP[i]) = ((states[1,j] = unin[i]) /\ (states[1,j+1] unout[i]));

% Binary operations
constraint forall (j in BINARYOP, i in 1..s where (states[i,1] == j)) ((states[i - 1,2] == binin1[j])/\(states[i - 1,3] == binin2[j])/\(states[i,2] == binout[j]));

% Push operations
constraint forall (j in PUSHOP, i in 1..s where (states[i,1] == j)) ((states[i,2] == pushout[j])/\(states[i,n] == 0));

%NOPs, si una operación es un NOP, las siguientes deben serlo también
constraint forall (j in 1..s, i in j+1..s) ((program[j] = 0) = (program[i] = 0));

% Solución