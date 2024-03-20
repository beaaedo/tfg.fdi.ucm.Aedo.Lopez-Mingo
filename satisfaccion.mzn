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
set of int: S2N = 2..n;
set of int: S3N = 3..n;
set of int: SN0 = 1..N0;
set of int: SN1 = 1..N1;
set of int: SN2 = 1..N2;
set of int: SNPUSH = 1..NPUSH;
set of int: SNSTORE = 1..NSTORE;
set of int: MDN = 1..m_dep_n;

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

enum DUP_ENUM;   %Contiene Dups necesarios
enum SWAP_ENUM;  %Contiene Swaps necesarios
array[SN] of TERM: startstack;
array[SN] of TERM: endstack;
%array[1..0] of TERM: before;
%array[1..0] of TERM: after;

int: m_dep_n;
array[MDN, 1..2] of int: memory_dependences;
int: s_dep_n;
array[1..s_dep_n, 1..2] of int: store_dependences;

% CONSTANTS USED FOR EXECUTION
int: NDUPS_SWAPS = n - 1;
enum OPCODES = {NOP, POP} ++ D(DUP_ENUM) ++ SW(SWAP_ENUM) ++ Z(ZEROARYOP) ++ U(UNARYOP) ++ BI(BINARYOP) ++ P(PUSHOP) ++ ST(STOROP); %Crea el enum opcodes sumando todos los enums

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
constraint forall (i in SS where (program[i] == OPCODES[1]))
  ((forall (x in i+1..s) (program[x] == OPCODES[1])) /\
  (forall (j in SN)(states[i+1,j] = states[i,j])));

% POP
constraint forall (i in SS where (program[i] == OPCODES[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in S2N)(states[i+1,j-1] = states[i,j])));

% DUP
constraint forall (i in SS where (program[i] in D(DUP_ENUM))) 
  (let { var int: x = D^-1(program[i])} in (states[i,x] != null) /\
  (states[i+1,1] = states[i,x])/\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1])));

% SWAP
constraint forall (i in SS where (program[i] in SW(SWAP_ENUM))) 
  (let {var int: x = SW^-1(program[i])} in (states[i,1] != null) /\
  (states[i, x+1] != null) /\
  (states[i+1,1] = states[i, x+1]) /\
  (states[i+1,x+1] = states[i,1]) /\
  (forall (j in S2N) (if j != x + 1 then states[i+1,j] = states[i,j] endif)));

% ZEROARY
constraint forall (i in SS where (program[i] in Z(ZEROARYOP))) 
  (let {var int: x = Z^-1(program[i])} in (states[i+1,1] = zeroout[x]) /\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1])));

% UNARY OP
constraint forall (i in SS where (program[i] in U(UNARYOP)))
  (let {var int: x = U^-1(program[i])} in (states[i,1] = unin[x]) /\
  (states[i+1,1] = unout[x]) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j])));

% BINARY OP (fusionadas para ahorrar codigo)
constraint forall (i in SS where (program[i] in BI(BINARYOP))) 
  (let {var int: x = BI^-1(program[i])} in 
  if (not bincomm[x]) then (states[i,1] = binin1[x]) /\
  (states[i,2] = binin2[x])
  else ((states[i,1] = binin2[x]) \/ (states[i,2] = binin2[x])) /\
  ((states[i,1] = binin1[x])\/(states[i,2] = binin1[x])) endif
  /\ (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in S3N)(states[i+1,j-1] = states[i,j])));

% PUSH
constraint forall (i in SS where (program[i] in P(PUSHOP))) 
  (let {var int: x = P^-1(program[i])} in (states[i,n] = null) /\
  (states[i+1,1] = pushout[x]) /\
  (forall (j in S2N)(states[i+1, j] = states[i,j-1])));

% STORE
constraint forall (i in SS where (program[i] in ST(STOROP))) 
  (let {var int: x = ST^-1(program[i])} in (states[i,1] = storin1[x]) /\
  (states[i,2] = storin2[x]) /\
  (states[i+1,n] = null) /\
  (states[i+1,n-1] = null) /\
  (forall (j in S3N)(states[i+1,j-2] = states[i,j])));
  
%MEMORY DEPENDENCIES
constraint forall (i in MDN, j in SS where (program[j] = memory_dependences[i,1])) (forall (z in 1..i)(program[z] != memory_dependences[i,2]));

% COUNT NOP OPERATIONS
constraint zeros = sum(i in SS)(program[i] = OPCODES[1]);

% Forzar las operaciones que hay definidas en los JSON a aparecer ya que no siempre va a ser lo más óptimo
constraint forall (x in Z(ZEROARYOP)) (exists (z in 1..s) (program[z] = x));
constraint forall (x in U(UNARYOP)) (exists (z in 1..s) (program[z] = x));
constraint forall (x in BI(BINARYOP)) (exists (z in 1..s) (program[z] = x));
constraint forall (x in ST(STOROP)) (exists (z in 1..s) (program[z] = x));
constraint forall (x in P(PUSHOP)) (exists (z in 1..s) (program[z] = x));

solve maximize zeros;