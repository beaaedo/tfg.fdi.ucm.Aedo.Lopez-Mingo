% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

enum ZEROARYOP;
int: N0 = if ZEROARYOP[1] == "ZEROARY_dummy" then 0 else card(ZEROARYOP) endif;
array [ZEROARYOP] of TERM: zeroout;
array [ZEROARYOP] of int: zerogas;
array [ZEROARYOP] of int: zerosz;
array [ZEROARYOP] of int: zerolb;
array [ZEROARYOP] of int: zeroub;

enum UNARYOP;
int: N1 = if UNARYOP[0] = "UNARY_dummy" then 0 else card(UNARYOP) endif;
array [UNARYOP] of TERM: unin;
array [UNARYOP] of TERM: unout;
array [UNARYOP] of int: ungas;
array [UNARYOP] of int: unsz;
array [UNARYOP] of int: unlb;
array [UNARYOP] of int: unub;

enum BINARYOP;
int: N2 = if BINARYOP[0] = "BINARY_dummy" then 0 else card(BINARYOP) endif;
array [BINARYOP] of TERM: binin1;
array [BINARYOP] of TERM: binin2;
array [BINARYOP] of TERM: binout;
array [BINARYOP] of bool: bincomm;
array [BINARYOP] of int: bingas;
array [BINARYOP] of int: binsz;
array [BINARYOP] of int: binlb;
array [BINARYOP] of int: binub;

enum PUSHOP;
int: NPUSH = if PUSHOP[0] = "PUSH_dummy" then 0 else card(PUSHOP) endif;
array[PUSHOP] of TERM: pushout;
array[PUSHOP] of int: pushgas;
array[PUSHOP] of int: pushsz;
array[PUSHOP] of int: pushlb;
array[PUSHOP] of int: pushub;

enum STOROP;
int: NSTORE = if STOROP[0] = "STORE_dummy" then 0 else card(STOROP) endif;
array[STOROP] of TERM: storin1;
array[STOROP] of TERM: storin2;
array[STOROP] of int: storlb;
array[STOROP] of int: storub;

array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

%NOP = 0, POP = 1, DUP = 2..n, SWAP = n+1..2n-1, ZEROARY = 2n..2n+N0 -1, UNARY = 2n+N0..2n+N0+N1-1, BINARY = 2n+N0+N1..2n+N0+N1+N2-1, PUSH = 2n+N0+N1+N2..2n+N0+N1+N2+NPUSH-1, STORE = 2n+N0+N1+N2+NPUSH..NUMOPS
int: NDUPS_SWAPS = n - 1;
%2n = 2 + 2(n-1)
int: NUMOPS = 2*n + N0 + N1 + N2 + NPUSH + NSTORE - 1;

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
constraint forall (x in ZEROARYOP, i in 1..s, j in 2..n where (program[i] == 2)) ((states[i+1,1] = zeroout[x])/\(states[i+1,j] = states[i,j-1])/\(zeroout[x] != null));

% PUSH
constraint forall (x in PUSHOP, i in 1..s , j in 1..n-1 where (program[i] == 3)) ((states[i,n] = null)/\(states[i+1,1] = pushout[x])/\(states[i+1, j+1] = states[i,j])/\(pushout[x] != null));

% UNARY OP
constraint forall (x in UNARYOP,i in 1..s, j in 2..n where (program[i] == 4)) ((states[i,1] = unin[x])/\(states[i+1,1] = unout[x])/\(states[i+1,j] = states[i,j])/\(unout[x] != null));

% BINARY OP
constraint forall (x in BINARYOP,i in 1..s, j in 2..n where ((program[i] == 5)/\( not bincomm[x]))) ((states[i,1] = binin1[x])/\(states[i,2] = binin2[x])/\(states[i+1,1] = binout[x])/\(states[i+1,j] = states[i,j])/\(unout[x] != null));

constraint forall (x in BINARYOP,i in 1..s, j in 2..n-1 where ((program[i] == 5)/\(bincomm[x]))) (((states[i,1] = binin2[x])\/(states[i,2] = binin2[x]))/\((states[i,1] = binin1[x])\/(states[i,2] = binin1[x]))/\(states[i+1,1] = binout[x])/\(states[i+1,j] = states[i,j+1])/\(states[i+1,n] = null)/\(unout[x] != null));

% Dup
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where (program[i] == 5 + x)) ((states[i,x] != null)/\(states[i+1,1] = states[i,x])/\(states[i+1,j] == states[i,j-1])/\(states[i,n] = null));

% Swap
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where ((program[i] == 5 + 2*x)/\(j != x + 1))) ((states[i,1] != null)/\(states[i, x+1] != null)/\(states[i+1,1] == states[i, x+1])/\(states[i+1,x+1] == states[i,1])/\(states[i+1,j] == states[i,j]));
