% Constantes
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

enum ZEROARYOP;
int: N0 = card(ZEROARYOP);
array [ZEROARYOP] of TERM: zeroout;
array [ZEROARYOP] of int: zerogas;
array [ZEROARYOP] of int: zerosz;
array [ZEROARYOP] of int: zerolb;
array [ZEROARYOP] of int: zeroub;

enum UNARYOP;
int: N1 = card(UNARYOP);
array [UNARYOP] of TERM: unin;
array [UNARYOP] of TERM: unout;
array [UNARYOP] of int: ungas;
array [UNARYOP] of int: unsz;
array [UNARYOP] of int: unlb;
array [UNARYOP] of int: unub;

enum BINARYOP;
int: N2 = card(BINARYOP);
array [BINARYOP] of TERM: binin1;
array [BINARYOP] of TERM: binin2;
array [BINARYOP] of TERM: binout;
array [BINARYOP] of bool: bincomm;
array [BINARYOP] of int: bingas;
array [BINARYOP] of int: binsz;
array [BINARYOP] of int: binlb;
array [BINARYOP] of int: binub;

enum PUSHOP;
int: NPUSH = card(PUSHOP);
array[PUSHOP] of TERM: pushout;
array[PUSHOP] of int: pushgas;
array[PUSHOP] of int: pushsz;
array[PUSHOP] of int: pushlb;
array[PUSHOP] of int: pushub;

enum STOROP;
int: NSTORE = card(STOROP);
array[STOROP] of TERM: storin1;
array[STOROP] of TERM: storin2;
array[STOROP] of int: storlb;
array[STOROP] of int: storub;

array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

%NOP = 0, POP = 1, DUP = 2..n, SWAP = n+1..2n-1, ZEROARY = 2n..2n+N0 -1, UNARY = 2n+N0..2n+N0+N1-1, BINARY = 2n+N0+N1..2n+N0+N1+N2-1, PUSH = 2n+N0+N1+N2..2n+N0+N1+N2+NPUSH-1, STORE = 2n+N0+N1+N2+NPUSH..NUMOPS
var int: zeros;
int: NDUPS_SWAPS = n - 1;
%2n = 2 + 2(n-1)
int: NUMOPS = 2*n + N0 + N1 + N2 + NPUSH + NSTORE - 1;

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var 0..NUMOPS: program;

% Constraints inicial y final
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Nop
constraint forall (i in 1..s where (program[i] == 0)) ((if (i!=s) then program[i+1] = 0 endif)/\(forall (j in 1..n)(states[i+1,j] = states[i,j])));

% Pop
constraint forall (i in 1..s where (program[i] == 1)) ((states[i,1] != null)/\(states[i+1,n] = null)/\(forall (j in 1..n-1)(states[i+1,j] = states[i,j+1])));

% Dup
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s where (program[i] == 1+x)) ((states[i,x] != null)/\(states[i+1,1] = states[i,x])/\(states[i,n] = null)/\(forall (j in 2..n)(states[i+1,j] = states[i,j-1])));

% Swap
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where (program[i] == n+x)) ( (states[i,1] != null)/\(states[i, x+1] != null)/\(states[i+1,1] = states[i, x+1])/\(states[i+1,x+1] = states[i,1])/\(if j != x + 1 then states[i+1,j] = states[i,j] endif));

% ZEROARY
constraint forall (x in ZEROARYOP, i in 1..s where (program[i] == (2*n)-1+x)) ((states[i+1,1] = zeroout[x])/\(states[i,n] = null)/\(forall (j in 2..n)(states[i+1,j] = states[i,j-1])));

% UNARY OP
constraint forall (x in UNARYOP,i in 1..s where (program[i] == (2*n)+N0-1+x)) ((states[i,1] = unin[x])/\(states[i+1,1] = unout[x])/\(forall (j in 2..n)(states[i+1,j] = states[i,j])));

% BINARY OP
constraint forall (x in BINARYOP,i in 1..s where ((program[i] == (2*n)+N0+N1-1+x)/\( not bincomm[x]))) ((states[i,1] = binin1[x])/\(states[i,2] = binin2[x])/\(states[i+1,1] = binout[x])/\(states[i+1,n] = null)/\(forall (j in 2..n-1)(states[i+1,j] = states[i,j+1])));

constraint forall (x in BINARYOP,i in 1..s where ((program[i] == (2*n)+N0+N1-1+x)/\(bincomm[x]))) (((states[i,1] = binin2[x])\/(states[i,2] = binin2[x]))/\((states[i,1] = binin1[x])\/(states[i,2] = binin1[x]))/\(states[i+1,1] = binout[x])/\(states[i+1,n] = null)/\(forall (j in 2..n-1)(states[i+1,j] = states[i,j+1])));

% PUSH
constraint forall (x in PUSHOP, i in 1..s where (program[i] == (2*n)+N0+N1+N2-1+x)) ((states[i,n] = null)/\(states[i+1,1] = pushout[x])/\(forall (j in 1..n-1)(states[i+1, j+1] = states[i,j])));

% STORE
constraint forall (x in STOROP, i in 1..s where (program[i] == (2*n)+N0+N1+N2+NPUSH-1+x)) ((states[i,1] == storin1[x])/\(states[i,2] == storin2[x])/\(states[i+1,n] = null)/\(states[i+1,n-1] = null)/\(forall (j in 3..n)(states[i+1,j-2] = states[i,j])));

%Cuenta ceros
constraint zeros = sum(i in 1..s)(program[i] = 0);

solve maximize zeros;