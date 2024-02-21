% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

enum ZEROARYOP;
int: n_ZEROARYOP = card(ZEROARYOP);
array [1..n_ZEROARYOP] of TERM: zeroout;
array [1..n_ZEROARYOP] of int: zerogas;
array [1..n_ZEROARYOP] of int: zerosz;
array [1..n_ZEROARYOP] of int: zerolb;
array [1..n_ZEROARYOP] of int: zeroub;

enum UNARYOP;
int: n_UNARYOP = card(UNARYOP);
array [1..n_UNARYOP] of TERM: unin;
array [1..n_UNARYOP] of TERM: unout;
array [1..n_UNARYOP] of int: ungas;
array [1..n_UNARYOP] of int: unsz;
array [1..n_UNARYOP] of int: unlb;
array [1..n_UNARYOP] of int: unub;

enum BINARYOP;
int: n_BINARYOP = card(BINARYOP);
array [1..n_BINARYOP] of TERM: binin1;
array [1..n_BINARYOP] of TERM: binin2;
array [1..n_BINARYOP] of TERM: binout;
array [1..n_BINARYOP] of bool: bincomm;
array [1..n_BINARYOP] of int: bingas;
array [1..n_BINARYOP] of int: binsz;
array [1..n_BINARYOP] of int: binlb;
array [1..n_BINARYOP] of int: binub;

enum PUSHOP;
int: n_PUSHOP = card(PUSHOP);
array[1..n_PUSHOP] of TERM: pushout;
array[1..n_PUSHOP] of int: pushgas;
array[1..n_PUSHOP] of int: pushsz;
array[1..n_PUSHOP] of int: pushlb;
array[1..n_PUSHOP] of int: pushub;

enum STOROP;
int: n_STOROP = card(STOROP);
array[1..n_STOROP] of TERM: storin1;
array[1..n_STOROP] of TERM: storin2;
array[1..n_STOROP] of int: storlb;
array[1..n_STOROP] of int: storub;

array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

int: NDUPS_SWAPS = if n < 5 then n - 1 else 4 endif;
int: NUMOPS = 5 + 2*NDUPS_SWAPS;

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..NUMOPS: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Nop
constraint forall (i in 1..s, j in 1..n , z in i..s where (program[i] == 0)) ((states[i+1,j] = states[i,j])/\(program[z] = 0));

% Pop
constraint forall (i in 1..s, j in 1..n-1 where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] == null));

% ZEROARY
constraint forall (x in 1..n_ZEROARYOP, i in 1..s, j in 2..n where (program[i] == 2)) ((states[i+1,1] = zeroout[x])/\(states[i+1,j] = states[i,j-1])/\(zeroout[x] != null));

% PUSH
constraint forall (x in 1..n_PUSHOP, i in 1..s , j in 1..n-1 where (program[i] == 3)) ((states[i,n] = null)/\(states[i+1,1] = pushout[x])/\(states[i+1, j+1] = states[i,j])/\(pushout[x] != null));

% UNARY OP
constraint forall (x in 1..n_UNARYOP,i in 1..s, j in 2..n where (program[i] == 4)) ((states[i,1] = unin[x])/\(states[i+1,1] = unout[x])/\(states[i+1,j] = states[i,j])/\(unout[x] != null));

% BINARY OP
constraint forall (x in 1..n_BINARYOP,i in 1..s, j in 2..n where ((program[i] == 5)/\( not bincomm[x]))) ((states[i,1] = binin1[x])/\(states[i,2] = binin2[x])/\(states[i+1,1] = binout[x])/\(states[i+1,j] = states[i,j])/\(unout[x] != null));

constraint forall (x in 1..n_BINARYOP,i in 1..s, j in 2..n-1 where ((program[i] == 5)/\(bincomm[x]))) (((states[i,1] = binin2[x])\/(states[i,2] = binin2[x]))/\((states[i,1] = binin1[x])\/(states[i,2] = binin1[x]))/\(states[i+1,1] = binout[x])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null)/\(unout[x] != null));

% Dup
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where (program[i] == 5 + x)) ((states[i,x] != null)/\(states[i+1,1] = states[i,x])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));

% Swap
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where ((program[i] == 5 + 2*x)/\(j != x + 1))) ((states[i,1] != null)/\(states[i, x+1] != null)/\(states[i+1,1] == states[i, x+1])/\(states[i+1,x+1] == states[i,1])/\(states[i+1,j] == states[i,j]));
