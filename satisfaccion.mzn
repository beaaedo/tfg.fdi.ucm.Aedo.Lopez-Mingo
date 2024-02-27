%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      DEFINITIONS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CONSTANTS FROM DZN
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

int: N0;
int: N0_DEF = if N0 > 0 then N0 else N0 +1 endif;
array [1..N0_DEF] of TERM: zeroout;
array [1..N0_DEF] of int: zerogas;
array [1..N0_DEF] of int: zerosz;
array [1..N0_DEF] of int: zerolb;
array [1..N0_DEF] of int: zeroub;

int: N1;
int: N1_DEF = if N1 > 0 then N1 else N1 +1 endif;
array [1..N1_DEF] of TERM: unin;
array [1..N1_DEF] of TERM: unout;
array [1..N1_DEF] of int: ungas;
array [1..N1_DEF] of int: unsz;
array [1..N1_DEF] of int: unlb;
array [1..N1_DEF] of int: unub;

int: N2;
int: N2_DEF = if N2 > 0 then N2 else N2 +1 endif;
array [1..N2_DEF] of TERM: binin1;
array [1..N2_DEF] of TERM: binin2;
array [1..N2_DEF] of TERM: binout;
array [1..N2_DEF] of bool: bincomm;
array [1..N2_DEF] of int: bingas;
array [1..N2_DEF] of int: binsz;
array [1..N2_DEF] of int: binlb;
array [1..N2_DEF] of int: binub;

int: NPUSH;
int: NPUSH_DEF = if NPUSH > 0 then NPUSH else NPUSH +1 endif;
array[1..NPUSH_DEF] of TERM: pushout;
array[1..NPUSH_DEF] of int: pushgas;
array[1..NPUSH_DEF] of int: pushsz;
array[1..NPUSH_DEF] of int: pushlb;
array[1..NPUSH_DEF] of int: pushub;

int: NSTORE;
int: NSTORE_DEF = if NSTORE > 0 then NSTORE else NSTORE +1 endif;
array[1..NSTORE_DEF] of TERM: storin1;
array[1..NSTORE_DEF] of TERM: storin2;
array[1..NSTORE_DEF] of int: storlb;
array[1..NSTORE_DEF] of int: storub;

enum OPCODES;
array[1..n] of TERM: startstack;
array[1..n] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

% CONSTANTS USED FOR EXECUTION
int: NDUPS_SWAPS = n - 1;
int: NUMOPS = 2*n + N0 + N1 + N2 + NPUSH + NSTORE;
array[1..NUMOPS] of OPCODES: OPCODES_ARR = OPCODES;

% VARIABLES
% matriz s + 1 x n, s+1 pilas
var int: zeros;
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var OPCODES: program;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      CONSTRAINTS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INITIAL AND FINAL STACKS
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% NOP
constraint forall (i in 1..s where (program[i] == OPCODES_ARR[1])) 
  ((if (i!=s) then program[i+1] = OPCODES_ARR[1] endif) /\
  (forall (j in 1..n)(states[i+1,j] = states[i,j])));

% POP
constraint forall (i in 1..s where (program[i] == OPCODES_ARR[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in 1..n-1)(states[i+1,j] = states[i,j+1])));

% DUP
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s where (program[i] == OPCODES_ARR[2+x])) 
  ((states[i,x] != null) /\
  (states[i+1,1] = states[i,x]) /\
  (states[i,n] = null) /\
  (forall (j in 2..n)(states[i+1,j] = states[i,j-1])));

% SWAP
constraint forall (x in 1..NDUPS_SWAPS, i in 1..s, j in 2..n  where (program[i] == OPCODES_ARR[n+x+1])) 
  ((states[i,1] != null) /\
  (states[i, x+1] != null) /\
  (states[i+1,1] = states[i, x+1]) /\
  (states[i+1,x+1] = states[i,1]) /\
  (if j != x + 1 then states[i+1,j] = states[i,j] endif));

% ZEROARY
constraint forall (x in 1..N0, i in 1..s where (program[i] == OPCODES_ARR[(2*n)+x])) 
  ((states[i+1,1] = zeroout[x]) /\
  (states[i,n] = null) /\
  (forall (j in 2..n)(states[i+1,j] = states[i,j-1])));

% UNARY OP
constraint forall (x in 1..N1,i in 1..s where (program[i] == OPCODES_ARR[(2*n)+N0+x])) 
  ((states[i,1] = unin[x]) /\
  (states[i+1,1] = unout[x]) /\
  (forall (j in 2..n)(states[i+1,j] = states[i,j])));

% BINARY OP NOT COMMUTATIVE
constraint forall (x in 1..N2, i in 1..s where (program[i] == OPCODES_ARR[(2*n)+N0+N1+x])/\( not bincomm[x])) 
  ((states[i,1] = binin1[x]) /\
  (states[i,2] = binin2[x]) /\
  (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in 2..n-1)(states[i+1,j] = states[i,j+1])));

% BINARY OP COMMUTATIVE
constraint forall (x in 1..N2, i in 1..s where ((program[i] == OPCODES_ARR[(2*n)+N0+N1+x])/\(bincomm[x]))) 
  (((states[i,1] = binin2[x]) \/ (states[i,2] = binin2[x])) /\
  ((states[i,1] = binin1[x])\/(states[i,2] = binin1[x])) /\
  (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in 2..n-1)(states[i+1,j] = states[i,j+1])));

% PUSH
constraint forall (x in 1..NPUSH, i in 1..s where (program[i] == OPCODES_ARR[(2*n)+N0+N1+N2+x])) 
  ((states[i,n] = null) /\
  (states[i+1,1] = pushout[x]) /\
  (forall (j in 1..n-1)(states[i+1, j+1] = states[i,j])));

% STORE
constraint forall (x in 1..NSTORE, i in 1..s where (program[i] == OPCODES_ARR[(2*n)+N0+N1+N2+NPUSH+x])) 
  ((states[i,1] == storin1[x]) /\
  (states[i,2] == storin2[x]) /\
  (states[i+1,n] = null) /\
  (states[i+1,n-1] = null) /\
  (forall (j in 3..n)(states[i+1,j-2] = states[i,j])));

% COUNT NOP OPERATIONS
constraint zeros = sum(i in 1..s)(program[i] = OPCODES_ARR[1]);

solve maximize zeros;