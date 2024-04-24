%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      DEFINITIONS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTANTS FROM DZN
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
int: min;
TERM: null; %string que representa null

%Variables de control para usar unas constraints u otras (0 = no se usa, 1 = si se usa)
int: option = 0; %Define si queremos optimizar gas(1), size(2) o length(0)
bool: opt1 = true;
bool: opt2 = true;
bool: opt3 = true;
bool: opt4 = true;
bool: opt5 = true;

%Sets que se reusan
set of int: SS = 1..s;
set of int: SN = 1..n;
set of int: S2N = 2..n;
set of int: S3N = 3..n;
set of int: SN0 = 1..N0;
set of int: SN1 = 1..N1;
set of int: SN2 = 1..N2;
set of int: SNA = 1..NA;
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

enum ASSOCIATIVEADDOP;
int: NA;
array[SNA] of int: naddin;
array[SNA, 1..10] of TERM: addin;
array[SNA] of TERM: addout;
array[SNA] of bool: addcomm;
array[SNA] of int: addgas;
array[SNA] of int: addsz;
array[SNA] of int: addlb;
array[SNA] of int: addub;

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
array[SNSTORE] of int: storgas;
array[SNSTORE] of int: storsz;

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
enum OPCODES = {NOP, POP} ++ D(DUP_ENUM) ++ SW(SWAP_ENUM) ++ Z(ZEROARYOP) ++ U(UNARYOP) ++ BI(BINARYOP) ++ P(PUSHOP) ++ ST(STOROP) ++ A(ASSOCIATIVEADDOP); %Crea el enum opcodes sumando todos los enums

% VARIABLES
% matriz s + 1 x n, s+1 pilas
var int: value;
array[SS] of var int: fgas;
array[SS] of var int: fsize;
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
  (forall (j in SN)(states[i+1,j] = states[i,j])) /\ fgas[i] == 0 /\ fsize[i] == 1);

% POP
constraint forall (i in SS where (program[i] == OPCODES[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in S2N)(states[i+1,j-1] = states[i,j]))
  /\ fgas[i] == 2 /\ fsize[i] == 1);

% DUP
constraint forall (i in SS where (program[i] in D(DUP_ENUM))) 
  (let { var int: x = D^-1(program[i])} in (states[i,x] != null) /\
  (states[i+1,1] = states[i,x])/\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1]))
  /\ fgas[i] == 3 /\ fsize[i] == 1);

% SWAP
constraint forall (i in SS where (program[i] in SW(SWAP_ENUM))) 
  (let {var int: x = SW^-1(program[i])} in (states[i,1] != null) /\
  (states[i, x+1] != null) /\
  (states[i+1,1] = states[i, x+1]) /\
  (states[i+1,x+1] = states[i,1]) /\
  (forall (j in S2N) (if j != x + 1 then states[i+1,j] = states[i,j] endif))
  /\ fgas[i] == 3 /\ fsize[i] == 1);

% ZEROARY
constraint forall (i in SS where (program[i] in Z(ZEROARYOP))) 
  (let {var int: x = Z^-1(program[i])} in (states[i+1,1] = zeroout[x]) /\
  (states[i,n] = null) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1]))
  /\ fgas[i] == zerogas[x] /\ fsize[i] == zerosz[x]);

% UNARY OP
constraint forall (i in SS where (program[i] in U(UNARYOP)))
  (let {var int: x = U^-1(program[i])} in (states[i,1] = unin[x]) /\
  (states[i+1,1] = unout[x]) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j]))
  /\ fgas[i] == ungas[x] /\ fsize[i] == unsz[x]);

% BINARY OP (fusionadas para ahorrar codigo)
constraint forall (i in SS where (program[i] in BI(BINARYOP))) 
  (let {var int: x = BI^-1(program[i])} in 
  if (not bincomm[x]) then (states[i,1] = binin1[x]) /\
  (states[i,2] = binin2[x])
  else ((states[i,1] = binin2[x]) \/ (states[i,2] = binin2[x])) /\
  ((states[i,1] = binin1[x])\/(states[i,2] = binin1[x])) endif
  /\ (states[i+1,1] = binout[x]) /\
  (states[i+1,n] = null) /\
  (forall (j in S3N)(states[i+1,j-1] = states[i,j]))
  /\ fgas[i] == bingas[x] /\ fsize[i] == binsz[x]);

% PUSH
constraint forall (i in SS where (program[i] in P(PUSHOP))) 
  (let {var int: x = P^-1(program[i])} in (states[i,n] = null) /\
  (states[i+1,1] = pushout[x]) /\
  (forall (j in S2N)(states[i+1, j] = states[i,j-1]))
  /\ fgas[i] == pushgas[x] /\ fsize[i] == pushsz[x]);

% STORE
constraint forall (i in SS where (program[i] in ST(STOROP))) 
  (let {var int: x = ST^-1(program[i])} in (states[i,1] = storin1[x]) /\
  (states[i,2] = storin2[x]) /\
  (states[i+1,n] = null) /\
  (states[i+1,n-1] = null) /\
  (forall (j in S3N)(states[i+1,j-2] = states[i,j]))
  /\ fgas[i] == storgas[x] /\ fsize[i] == storsz[x]);
  
%MEMORY DEPENDENCIES
constraint forall (i in MDN, j in SS where (program[j] = memory_dependences[i,1])) (forall (z in 1..i)(program[z] != memory_dependences[i,2]));

% Contar el valor a minimizar dependiendo de option 
constraint if option = 0 then value = s - (sum(i in SS)(program[i] = OPCODES[1])) 
  elseif option = 1 then value = sum(i in SS)(fgas[i])
  else value = sum(i in SS)(fsize[i]) endif;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   CONSTRAINTS TOSEM                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Todas las operaciones definidas deben aparecer en program
constraint if opt1 then ((forall (x in Z(ZEROARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in U(UNARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in BI(BINARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in ST(STOROP)) (exists (z in SS) (program[z] = x)))/\(forall (x in P(PUSHOP)) (exists (z in SS) (program[z] = x)))) endif;

% Cada TERM que aparece como entrada de una operacion definida o en la pila final debe insertarse al menos una vez.
constraint if opt2 then (forall (e in endstack, ui in unin, bi1 in binin1, bi2 in binin2, si1 in storin1, si2 in storin2, a in addin where (a != null)) 
  (((e in zeroout)\/(e in unout)\/(e in binout)\/(e in pushout)\/(e in addout))/\
  ((ui in zeroout)\/(ui in unout)\/(ui in binout)\/(ui in pushout)\/(ui in addout))/\
  ((bi1 in zeroout)\/(bi1 in unout)\/(bi1 in binout)\/(bi1 in pushout)\/(bi1 in addout))/\
  ((bi2 in zeroout)\/(bi2 in unout)\/(bi2 in binout)\/(bi2 in pushout)\/(bi2 in addout))/\
  ((si1 in zeroout)\/(si1 in unout)\/(si1 in binout)\/(si1 in pushout)\/(si1 in addout))/\
  ((si2 in zeroout)\/(si2 in unout)\/(si2 in binout)\/(si2 in pushout)\/(si2 in addout))/\
  ((a in zeroout)\/(a in unout)\/(a in binout)\/(a in pushout)\/(a in addout)))) endif;

% La instrucción justo antes de POP no puede introducir un elemento en la pila. Antes de un POP solo puede ser otro POP o SWAPk.
constraint if opt3 then (forall (i in 2..s where (program[i] == OPCODES[2])) ((program[i-1] == OPCODES[2])\/(exists (sw in SW(SWAP_ENUM))         (program[i-1] == sw )))) endif;

% Cada operacion definida con coste de gas mayor o igual a 3 deberá utilizarse como máximo una vez.
constraint if opt4 then ((forall (z in Z(ZEROARYOP)) (count (i in SS, j in SN0 where (j == Z^-1(program[i])))((program[i] == z)/\(zerogas[j] >= 3)) <= 1))/\
  (forall (u in U(UNARYOP)) (count (i in SS, j in SN1 where (j == U^-1(program[i])))((program[i] == u)/\(ungas[j] >= 3)) <= 1))/\
  (forall (bi in BI(BINARYOP)) (count (i in SS, j in SN2 where (j == BI^-1(program[i])))((program[i] == bi)/\(bingas[j] >= 3)) <= 1))/\
  (forall (st in ST(STOROP)) (count (i in SS, j in SNSTORE where (j == ST^-1(program[i])))((program[i] == st)/\(storgas[j] >= 3)) <= 1))/\
  (forall (p in P(PUSHOP)) (count (i in SS, j in SNPUSH where (j == P^-1(program[i])))((program[i] == p)/\(pushgas[j] >= 3)) <= 1))) endif;
  
% (NO TOSEM)Si la cima de la pila es x, la instruccion anterior es nop, dup, swap o una operacion con output x.
constraint if opt5 then (forall (i in 2..s+1, x in TERM where (x == states[i,1]) /\ (x != null)) 
  (((program[i-1] == OPCODES[1])
  \/(program[i-1] in D(DUP_ENUM))
  \/(program[i-1] in SW(SWAP_ENUM))
  \/((program[i-1] in Z(ZEROARYOP))/\(x == zeroout[Z^-1(program[i-1])]))
  \/((program[i-1] in U(UNARYOP))/\(x == unout[U^-1(program[i-1])]))
  \/((program[i-1] in BI(BINARYOP))/\(x == binout[BI^-1(program[i-1])]))
  \/((program[i-1] in P(PUSHOP))/\(x == pushout[P^-1(program[i-1])]))
  \/((program[i-1] in A(ASSOCIATIVEADDOP))/\(x == addout[A^-1(program[i-1])]))))) endif;

%(NO TOSEM) Asociatividad -- de momento no conmutativa

constraint forall (i in SS where (program[i] in A(ASSOCIATIVEADDOP)))
  (let {var int: z = A^-1(program[i])} in (forall (k in 1..naddin[z])(addin[z,k] == states[i,k]))/\
  (states[i+1,1] == addout[z])/\
  (forall(l in 2..n-(naddin[z]-1)) (states[i+1,l] == states[i,l+(naddin[z]-1)]))/\
  (forall(p in n-(naddin[z]-2)..n)(states[i+1,p] == null))
  /\ fgas[i] == addgas[z] /\ fsize[i] == addsz[z]);

solve minimize value;