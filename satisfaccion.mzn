% Constantes
set of string: TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
%set of int: ZEROARYOP;
%array[1..s] of 1..n: zeroout;
%set of int: UNARYOP;
%array[1..s] of 1..n: unin;
%array[1..s] of 1..n: unout;
set of int: BINARYOP = {2};
array[1..s] of 1..n: binin1;
array[1..s] of 1..n: binin2;
array[1..s] of 1..n: binout;
set of int: PUSHOP;
array[1..s] of 1..n: pushout;

array[1..n] of 1..n: startstack;
array[1..n] of 1..n: endstack;

% Variables
% matriz n + 1 x s
array[1..s, 1..n+1] of int: states;

% Assert

% Constraints
% Start stack and End stack
constraint forall (i in 1..n) ((states[1,i+1] == startstack[i])/\(states[s,i+1] == endstack[i]));

% Zeroary operations
%constraint forall (j in ZEROARYOP, i in 1..s where (states[i,1] == j)) (states[i,2] == zeroout[j]);

% Unary operations
%constraint forall (j in UNARYOP, i in 1..s where (states[i,1] == j)) ((states[i - 1,2] == unin[j])/\(states[i,2] == unout[j]));

% Binary operations
constraint forall (j in BINARYOP, i in 1..s where (states[i,1] == j)) ((states[i - 1,2] == binin1[j])/\(states[i - 1,3] == binin2[j])/\(states[i,2] == binout[j]));

% Push operations
constraint forall (j in PUSHOP, i in 1..s where (states[i,1] == j)) ((states[i,2] == pushout[j])/\(states[i,n] == 0));

% Solución