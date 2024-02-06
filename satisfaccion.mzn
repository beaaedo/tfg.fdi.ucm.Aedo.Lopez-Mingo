%0=NOP 1=POP  2=PUSH0  3=DUP2  4=GT 5=POP 6=DUP1 7=DUP2 8=SWAP2 9=SWAP3 10=SWAP4

% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

%COmo hacer que 1 sea s?
set of int: ZEROARYOP;
array[1..1] of 1..n: zeroout;
array[1..1] of 0..n: zerogas;
array[1..1] of 0..n: zerosz;
array[1..1] of 0..n: zerolb;
array[1..1] of 0..n: zeroub;
set of int: UNARYOP;
array[1..1] of 1..n: unin;
array[1..1] of 1..n: unout;
array[1..1] of 0..n: ungas;
array[1..1] of 0..n: unsz;
array[1..1] of 0..n: unlb;
array[1..1] of 0..n: unub;
set of int: BINARYOP;
array[1..1] of 0..n: binin1;
array[1..1] of 0..n: binin2;
array[1..1] of 0..n: binout;
array[1..1] of bool: bincomm;
array[1..1] of 0..n: bingas;
array[1..1] of 0..n: binsz;
array[1..1] of 0..n: binlb;
array[1..1] of 0..n: binub;

set of int: PUSHOP;
array[1..1] of 1..n: pushout;
array[1..1] of 0..n: pushgas;
array[1..1] of 0..n: pushsz;
array[1..1] of 0..n: pushlb;
array[1..1] of 0..n: pushub;
set of int: STOROP;
array[1..1] of 1..n:storin1;
array[1..1] of 1..n:storin2;
array[1..1] of 0..n:storlb;
array[1..1] of 0..n:storub;

%Listas del tamaño maximo del stack que contienen variables de TERM
% n a 2
array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..n, 1..s+1] of var TERM: states;
array[1..s] of var int: program;

% Assert

% Constraints
% Start stack and End stack
constraint forall (i in 1..n) ((states[i,1] == startstack[i])/\(states[i,s+1] == endstack[i]));

% Zeroary operations
%constraint forall (i in index_set(ZEROARYOP), j in 1..s) (program[j] = ZEROARYOP[i]) = (states[1,j+1] = zeroout[i])

% Unary operations
%constraint forall (i in index_set(UNARYOP), j in 1..s) (program[j] = UNARYOP[i]) = ((states[1,j] = unin[i]) /\ (states[1,j+1] unout[i]));

% Binary operations
constraint forall (i in index_set(BINARYOP), j in 1..s) ((program[j] = BINARYOP[i]) = ((states[1,j] = binin1[i])/\(states[2,j] = binin2[i])/\(states[1,j+1] = binout[i])));

% Push operations
constraint forall (i in index_set(PUSHOP), j in 1..s, z in 1..n-1) ((program[j] = PUSHOP[i]) = ((states[z+1,j+1] = states[z,j])/\(states[1,j+1] = pushout[i])));

%NOPs, si una operación es un NOP, las siguientes deben serlo también
constraint forall (j in 1..s, i in j+1..s) ((program[j] = 0) = (program[i] = 0));

%POP
constraint forall (i in 1..s, j in 1..n-1) ((program[i] = 5) = ((states[j,i+1] = states[j+1,i])/\(states[j,i+1] = TERM[0])));

%DUP1
constraint forall (i in 1..s, j in 2..n-1) ((program[i] = 6) = ((states[2,i+1] = states[1,i])/\(states[1,i+1] = states[1,i])/\(states[j+1,i+1] = states[j,i])));
%DUP2
constraint forall (i in 1..s, j in 3..n-1) ((program[i] = 7) = ((states[2,i+1] = states[1,i])/\(states[1,i+1] = states[1,i])/\(states[3,i+1] = states[2,i])/\(states[4,i+1] = states[2,i])/\(states[j+2,i+1] = states[j,i])));

%SWAP2
constraint forall (i in 1..s) ((program[i] = 8) = ((states[2,i+1] = states[1,i])/\(states[1,i+1] = states[2,i])));
%SWAP3
constraint forall (i in 1..s) ((program[i] = 9) = ((states[3,i+1] = states[1,i])/\(states[1,i+1] = states[3,i])));
%SWAP4
constraint forall (i in 1..s) ((program[i] = 10) = ((states[4,i+1] = states[1,i])/\(states[1,i+1] = states[4,i])));

% Solución