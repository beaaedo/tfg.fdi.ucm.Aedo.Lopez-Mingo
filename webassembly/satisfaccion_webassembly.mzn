%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      DEFINITIONS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTANTS FROM DZN
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
TERM: null; %string que representa null
int: option = 0; %Define si queremos optimizar gas(1), size(2) o length(0)

%Sets que se reusan
set of int: SS = 1..s;
set of int: SN = 1..n;
set of int: S1N = 1..n-1;
set of int: S2N = 2..n;
set of int: S3N = 3..n;
set of int: S4N = 4..n;
set of int: SN0 = 1..N0;
set of int: SN1 = 1..N1;
set of int: SN2 = 1..N2;
set of int: SN3 = 1..N3;
set of int: DN = 1..ndeps;
set of int: RN = 1..(NR+max_registers_sz);

enum ZEROARYOP;
int: N0;
array [SN0] of TERM: zeroout;
array [SN0] of int: zerogas;
array [SN0] of int: zerosz;
array [SN0] of bool: zerostor;
array [SN0] of int: zerolb;
array [SN0] of int: zeroub;

enum UNARYOP;
int: N1;
array [SN1] of TERM: unin;
array [SN1] of TERM: unout;
array [SN1] of int: ungas;
array [SN1] of int: unsz;
array [SN1] of bool: unstor;
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
array [SN2] of bool: binstor;
array [SN2] of int: binlb;
array [SN2] of int: binub;

enum TERNARYOP;
int: N3;
array [SN3] of TERM: terin1;
array [SN3] of TERM: terin2;
array [SN3] of TERM: terin3;
array [SN3] of TERM: terout1;
array [SN3] of TERM: terout2;
array [SN3] of TERM: terout3;
array [SN3] of bool: tercomm;
array [SN3] of int: tergas;
array [SN3] of int: tersz;
array [SN3] of bool: terstor;
array [SN3] of int: terlb;
array [SN3] of int: terub;

enum SET_ENUM;   %Contiene SETs necesarios
enum GET_ENUM;  %Contiene GETs necesarios
enum TEE_ENUM;  %Contiene TEEs necesarios
array[SN] of TERM: startstack;
array[SN] of TERM: endstack;
%array[1..0] of TERM: before;
%array[1..0] of TERM: after;

int: ndeps;
array[DN, 1..2] of int: dependencies;

int: max_registers_sz;
int: NR;
array[1..NR, 1..2] of TERM: registers;

% CONSTANTS USED FOR EXECUTION
enum OPCODES = {NOP, POP} ++ S(SET_ENUM) ++ G(GET_ENUM) ++ TEE(TEE_ENUM) ++ Z(ZEROARYOP) ++ U(UNARYOP) ++ BI(BINARYOP) ++ T(TERNARYOP); %Crea el enum opcodes sumando todos los enums

% VARIABLES
% matriz s + 1 x n, s+1 pilas
var int: value;
array[SS] of var int: fgas;
array[SS] of var int: fsize;
array[1..s+1, SN] of var TERM: states;
array[1..s+1, RN] of var TERM: register_states;
array[SS] of var OPCODES: program;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      CONSTRAINTS                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INITIAL AND FINAL STACKS
constraint forall (i in SN) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% INITIAL AND FINAL REGISTERS
constraint forall (i in 1..NR) ((register_states[1,i] == registers[i,1])/\(register_states[s+1,i] == registers[i,2]));
constraint forall (i in (NR+1)..(NR + max_registers_sz)) (register_states[1,i] = null);
% ESTA ABAJO BRRAR
constraint forall (i in (NR+1)..(NR + max_registers_sz)) (register_states[s+1,i] = null);

% NOP
constraint forall (i in SS where (program[i] == OPCODES[1]))
  ((forall (x in i+1..s) (program[x] == OPCODES[1])) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in SN)(states[i+1,j] = states[i,j])));

% POP
constraint forall (i in SS where (program[i] == OPCODES[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S2N)(states[i+1,j-1] = states[i,j])));

% SETX
constraint forall (i in SS where (program[i] in S(SET_ENUM))) 
  (let {var int: x = S^-1(program[i])} in (states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (register_states[i+1,x] == states[i,1]) /\
  (forall (j in RN where (j != x)) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S1N)(states[i+1,j] = states[i,j+1])));
  
% GETX
constraint forall (i in SS where (program[i] in G(GET_ENUM))) 
  (let {var int: x = G^-1(program[i])} in (states[i,n] = null) /\ 
  (states[i+1,1] = register_states[i,x]) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in SN2)(states[i+1,j-1] = states[i,j])));

% TEEX
constraint forall (i in SS where (program[i] in TEE(TEE_ENUM))) 
  (let {var int: x = TEE^-1(program[i])} in (states[i,n] = null) /\ 
  (register_states[i+1,x] = states[i,1]) /\
  (forall (j in RN where (j != x)) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in SS)(states[i+1,j] = states[i,j])));

% ZEROARY
constraint forall (i in SS where (program[i] in Z(ZEROARYOP))) 
  (let {var int: x = Z^-1(program[i])} in (states[i+1,1] = zeroout[x]) /\
  (states[i,n] = null) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S2N)(states[i+1,j] = states[i,j-1])));

% UNARY OP
constraint forall (i in SS where (program[i] in U(UNARYOP)))
  (let {var int: x = U^-1(program[i])} in (states[i,1] = unin[x]) /\
  (states[i+1,1] = unout[x]) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
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
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S3N)(states[i+1,j-1] = states[i,j])));
  
% TERNARY OP
constraint forall (i in SS where (program[i] in T(TERNARYOP))) 
  (let {var int: x = T^-1(program[i])} in 
  if (not tercomm[x]) then 
    ((states[i,1] = terin1[x]) /\ (states[i,2] = terin2[x]) /\ (states[i,3] = terin3[x]))
  else ((states[i,1] = terin1[x]) \/ (states[i,2] = terin1[x]) \/ (states[i,3] = terin1[x])) /\
  ((states[i,1] = terin2[x]) \/ (states[i,2] = terin2[x]) \/ (states[i,3] = terin2[x])) /\
  ((states[i,1] = terin3[x]) \/ (states[i,2] = terin3[x]) \/ (states[i,3] = terin3[x])) 
  endif 
  /\ (states[i+1,1] = terout1[x]) /\ (states[i+1,2] = terout2[x]) /\ (states[i+1,3] = terout3[x]) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S4N)(states[i+1,j] = states[i,j-3])));
  
% MEMORY DEPENDENCIES
constraint forall (i in DN, j in SS where (program[j] = dependencies[i,1])) (forall (z in 1..i)(program[z] != dependencies[i,2]));

% Contar el valor a minimizar dependiendo de option 
%constraint value = s - (sum(i in SS)(program[i] = OPCODES[1]));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   CONSTRAINTS TOSEM                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Todas las operaciones definidas deben aparecer en program
constraint (forall (x in Z(ZEROARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in U(UNARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in BI(BINARYOP)) (exists (z in SS) (program[z] = x)))/\(forall (x in T(TERNARYOP)) (exists (z in SS) (program[z] = x)));

%olve minimize value;
solve satisfy;