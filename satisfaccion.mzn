%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      DEFINITIONS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTANTS FROM DZN
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

%Sets que se reusan
set of int: SS = 1..s;
set of int: SN = 1..n;
set of int: SDS = 1..NDUPS_SWAPS;
set of int: S2N = 2..n;
set of int: S3N = 3..n;
set of int: SN0 = 1..N0;
set of int: SN1 = 1..N1;
set of int: SN2 = 1..N2;
set of int: SNPUSH = 1..NPUSH;
set of int: SNSTORE = 1..NSTORE;

enum ZEROARYOP;
int: N0;
array [SN0] of TERM: zeroout;
array [SN0] of int: zerogas;
array [SN0] of int: zerosz;
array [SN0] of int: zerolb;
array [SN0] of int: zeroub;

enum UNARYOP;
int: N1;
array [SN1] of TERM: unin;
array [SN1] of TERM: unout;
array [SN1] of int: ungas;
array [SN1] of int: unsz;
array [SN1] of int: unlb;
array [SN1] of int: unub;

enum BINARYOP;
int: N2;
array [SN2] of TERM: binin1;
array [SN2] of TERM: binin2;
array [SN2] of TERM: binout;
array [SN2] of bool: bincomm;
array [SN2] of int: bingas;
array [SN2] of int: binsz;
array [SN2] of int: binlb;
array [SN2] of int: binub;

enum PUSHOP;
int: NPUSH;
array[SNPUSH] of TERM: pushout;
array[SNPUSH] of int: pushgas;
array[SNPUSH] of int: pushsz;
array[SNPUSH] of int: pushlb;
array[SNPUSH] of int: pushub;

enum STOROP;
int: NSTORE;
array[SNSTORE] of TERM: storin1;
array[SNSTORE] of TERM: storin2;
array[SNSTORE] of int: storlb;
array[SNSTORE] of int: storub;

enum BASIC_ENUM; %Contiene nop y pop
enum DUP_ENUM;   %Contiene Dups necesarios
enum SWAP_ENUM;  %Contiene Swaps necesarios
array[SN] of TERM: startstack;
array[SN] of TERM: endstack;
array[1..0] of TERM: before;
array[1..0] of TERM: after;

% CONSTANTS USED FOR EXECUTION
int: NDUPS_SWAPS = n - 1;
int: NUMOPS = 2*n + N0 + N1 + N2 + NPUSH + NSTORE;
enum OPCODES = BA(BASIC_ENUM) ++ D(DUP_ENUM) ++ SW(SWAP_ENUM) ++ Z(ZEROARYOP) ++ U(UNARYOP) ++ BI(BINARYOP) ++ P(PUSHOP) ++ ST(STOROP); %Crea el enum opcodes sumando todos los enums

% VARIABLES
% matriz s + 1 x n, s+1 pilas
var int: zeros;
array[1..s+1, SN] of var TERM: states;
array[SS] of var OPCODES: program;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      CONSTRAINTS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INITIAL AND FINAL STACKS
constraint forall (i in SN) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% NOP
constraint forall (i in SS where (BA^-1(program[i]) == BASIC_ENUM[1])) 
  ((if (i!=s) then BA^-1(program[i+1]) = BASIC_ENUM[1] endif) /\
  (forall (j in SN)(states[i+1,j] = states[i,j])));

% POP
constraint forall (i in SS where (BA^-1(program[i]) == BASIC_ENUM[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in S2N)(states[i+1,j-1] = states[i,j])));

% DUP
constraint forall (x in SDS, i in SS where (D^-1(program[i]) == DUP_ENUM[x])) 
  ((states[i,x] != null) /\
  (states[i+1,1] = states[i,x]) /\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1])));

% SWAP
constraint forall (x in SDS, i in SS, j in S2N  where (SW^-1(program[i]) == SWAP_ENUM[x])) 
  ((states[i,1] != null) /\
  (states[i, x+1] != null) /\
  (states[i+1,1] = states[i, x+1]) /\
  (states[i+1,x+1] = states[i,1]) /\
  (if j != x + 1 then states[i+1,j] = states[i,j] endif));

% ZEROARY
constraint forall (x in SN0, i in SS where (Z^-1(program[i]) == ZEROARYOP[x])) 
  ((states[i+1,1] = zeroout[x]) /\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1])));

% UNARY OP
constraint forall (x in SN1,i in SS where (U^-1(program[i]) == UNARYOP[x]))
  ((states[i,1] = unin[x]) /\
  (states[i+1,1] = unout[x]) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j])));

% BINARY OP NOT COMMUTATIVE
constraint forall (x in SN2, i in SS where (BI^-1(program[i]) == BINARYOP[x])/\( not bincomm[x])) 
  ((states[i,1] = binin1[x]) /\
  (states[i,2] = binin2[x]) /\
  (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in S3N)(states[i+1,j-1] = states[i,j])));

% BINARY OP COMMUTATIVE
constraint forall (x in SN2, i in SS where ((BI^-1(program[i]) == BINARYOP[x])/\(bincomm[x]))) 
  (((states[i,1] = binin2[x]) \/ (states[i,2] = binin2[x])) /\
  ((states[i,1] = binin1[x])\/(states[i,2] = binin1[x])) /\
  (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in S3N)(states[i+1,j-1] = states[i,j])));

% PUSH
constraint forall (x in SNPUSH, i in SS where (P^-1(program[i]) == PUSHOP[x])) 
  ((states[i,n] = null) /\
  (states[i+1,1] = pushout[x]) /\
  (forall (j in S2N)(states[i+1, j] = states[i,j-1])));

% STORE
constraint forall (x in SNSTORE, i in SS where (ST^-1(program[i]) == STOROP[x])) 
  ((states[i,1] == storin1[x]) /\
  (states[i,2] == storin2[x]) /\
  (states[i+1,n] = null) /\
  (states[i+1,n-1] = null) /\
  (forall (j in S3N)(states[i+1,j-2] = states[i,j])));

% COUNT NOP OPERATIONS
constraint zeros = sum(i in SS)(BA^-1(program[i]) = BASIC_ENUM[1]);

solve maximize zeros;
