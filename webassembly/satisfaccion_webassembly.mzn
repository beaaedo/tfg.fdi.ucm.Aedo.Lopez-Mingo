%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      DEFINICIONES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CONSTANTES DEL DZN
%%%%%%%%%%%%%%%%%%%%
enum TERM;
int: s; % init_progr_len
int: n; % max_sk_sz
TERM: null; % string que representa null

% Sets 
set of int: SS = 1..s;
set of int: SN = 1..n;
set of int: S1N = 1..n-1;
set of int: S2N = 2..n;
set of int: S3N = 3..n;
set of int: S4N = 4..n;
set of int: SNO = 1..N;
set of int: DN = 1..ndeps;
set of int: NR1 = 1..(NR+1);
set of int: RN = 1..(NR+max_registers_sz);

% Constantes relacionadas con las operaciones
array [SNO] of int: in_ops;
array [SNO] of int: out_ops;
enum OP;
int: N;
array [SNO] of TERM: in1;
array [SNO] of TERM: in2;
array [SNO] of TERM: in3;
array [SNO] of TERM: out1;
array [SNO] of TERM: out2;
array [SNO] of TERM: out3;
array [SNO] of bool: comm;
array [SNO] of int: gas;
array [SNO] of int: sz;
array [SNO] of bool: stor;
array [SNO] of int: lb;
array [SNO] of int: ub;

enum SET_ENUM;   %Contiene SETs necesarios
enum GET_ENUM;  %Contiene GETs necesarios
enum TEE_ENUM;  %Contiene TEEs necesarios
array[SN] of TERM: startstack; % Stack inicial
array[SN] of TERM: endstack; % Stack final

% Constantes relacionadas con las dependencias de memoria
int: ndeps;
array[DN, 1..2] of OP: dependencies;

% Constantes relacionadas con registros
% Número de registros adicionales
int: max_registers_sz; 
% Número de registros necesarios
int: NR;
% Matriz con el estado inicial y final de los registros 
array[1..NR, 1..2] of TERM: registers; 

% CONSTANTS USADAS PARA LA EJECUCIÓN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Crea el enum opcodes sumando todos los enums
enum OPCODES = {NOP, POP} ++ S(SET_ENUM) ++ G(GET_ENUM) ++ TEE(TEE_ENUM) ++ O(OP); 
% Define si queremos optimizar gas(1), size(2) o length(0). En el caso de WebAssembly siempre será igual a 0.
int: option = 0; 

% VARIABLES
%%%%%%%%%%%
% Valor a optimizar
var int: value;
% Array con el gas gastado por las operaciones en cada estado
array[SS] of var int: fgas;
% Array con el size ocupado por las operaciones en cada estado
array[SS] of var int: fsize;
% Matriz con el estado de la pila en cada estado
array[1..s+1, SN] of var TERM: states;
% Matriz con el estado de los registros en cada estado
array[1..s+1, RN] of var TERM: register_states;
% Operaciones que se ejecutan en cada estado
array[SS] of var OPCODES: program;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     RESTRICCIONES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pila inicial y final
constraint forall (i in SN) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Registros iniciales y finales
constraint forall (i in 1..NR) ((register_states[1,i] == registers[i,1])/\(register_states[s+1,i] == registers[i,2]));
constraint forall (i in (NR+1)..(NR + max_registers_sz)) ((register_states[1,i] = null) /\ (register_states[s+1,i] = null));

% NOP
constraint forall (i in SS where (program[i] == OPCODES[1]))
  ((forall (x in i+1..s) (program[x] == OPCODES[1])) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in SN)(states[i+1,j] = states[i,j])) /\ fgas[i] == 0 /\ fsize[i] == 0);

% POP
constraint forall (i in SS where (program[i] == OPCODES[2])) 
  ((states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S2N)(states[i+1,j-1] = states[i,j])) /\ fgas[i] == 2 /\ fsize[i] == 1);

% SETX
constraint forall (i in SS where (program[i] in S(SET_ENUM))) 
  (let {var int: x = S^-1(program[i])} in (states[i,1] != null) /\ 
  (states[i+1,n] = null) /\
  (register_states[i+1,x] == states[i,1]) /\
  (forall (j in RN where (j != x)) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S1N)(states[i+1,j] = states[i,j+1])) /\ fgas[i] == 1 /\ fsize[i] == 1);
  
% GETX
constraint forall (i in SS where (program[i] in G(GET_ENUM))) 
  (let {var int: x = G^-1(program[i])} in (states[i,n] = null) /\
  (register_states[i,x] != null) /\ 
  (states[i+1,1] = register_states[i,x]) /\
  (forall (j in RN) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in S1N)(states[i+1,j+1] = states[i,j])) /\ fgas[i] == 1 /\ fsize[i] == 1);

% TEEX
constraint forall (i in SS where (program[i] in TEE(TEE_ENUM))) 
  (let {var int: x = TEE^-1(program[i])} in
  (states[i,1] != null) /\ 
  (register_states[i+1,x] = states[i,1]) /\
  (forall (j in RN where (j != x)) (register_states[i+1,j] == register_states[i,j])) /\
  (forall (j in SN)(states[i+1,j] = states[i,j])) /\ fgas[i] == 1 /\ fsize[i] == 1);
  
% Asegura que, dependiendo de la cantidad de parámetros de entrada sean iguales a los del array al antes de la operación - CONMUTATIVAS
constraint forall (i in SS where (program[i] in O(OP))) 
  (let {var int: x = O^-1(program[i])} in 
  if ((in_ops[x] == 2) /\ (comm[x])) then (((states[i,1] = in2[x]) /\ (states[i,2] = in1[x])) \/ ((states[i,1] = in1[x]) /\ (states[i,2] = in2[x])) /\ (fgas[i] = gas[x]) /\ (fsize[i] == gas[x])) endif);

% Asegura que, dependiendo de la cantidad de parámetros de entrada sean iguales a los del array al antes de la operación - NO CONMUTATIVAS
constraint forall (i in SS where (program[i] in O(OP))) 
  (let {var int: x = O^-1(program[i])} in 
  (fgas[i] == gas[x]) /\ (fsize[i] == gas[x]) /\ 
  (if ((in_ops[x] == 1) /\ (not comm[x])) then (states[i,1] = in1[x]) endif) /\
  (if ((in_ops[x] == 2) /\ (not comm[x])) then ((states[i,1] = in1[x]) /\ (states[i,2] = in2[x])) endif) /\
  (if ((in_ops[x] == 3) /\ (not comm[x])) then ((states[i,1] = in1[x]) /\ (states[i,2] = in2[x]) /\ (states[i,3] = in3[x])) endif));

% Asegura que, dependiendo de la cantidad de parámetros de salida sean iguales a los del array después de la operación 
constraint forall (i in SS where (program[i] in O(OP))) 
  (let {var int: x = O^-1(program[i])} in 
  (if (out_ops[x] == 1) then (states[i+1,1] = out1[x])/\(states[i,n] = null) endif) /\
  (if (out_ops[x] == 2) then ((states[i+1,1] = out1[x])/\(states[i+1,2] = out2[x])/\(states[i,n] = null)/\(states[i,n-1] = null)) endif) /\
  (if (out_ops[x] == 3) then ((states[i+1,1] = out1[x])/\(states[i+1,2] = out2[x])/\(states[i+1,3] = out3[x])/\(states[i,n] = null)/\(states[i,n-1] = null)/\(states[i,n-2] = null)) endif));
  
% Estado de los terms después de una operación  
constraint forall (i in SS where (program[i] in O(OP))) 
  (let {var int: x = O^-1(program[i])} in 
  (if (out_ops[x] > in_ops[x]) then ((forall (j in out_ops[x]+1..n)(states[i+1,j] = states[i,j-(out_ops[x] - in_ops[x])])) /\ (forall (j in (n - (out_ops[x] - in_ops[x]))..n) (states[i,j] = null))) endif) /\ 
  (if (out_ops[x] < in_ops[x]) then ((forall (j in out_ops[x]+1..n-in_ops[x])(states[i+1,j] = states[i,j+(in_ops[x] - out_ops[x])])) /\ (forall (j in (n-in_ops[x])..n) (states[i+1,j] = null))) endif) /\
  (if (out_ops[x] == in_ops[x]) then (forall (j in out_ops[x]+1..n)(states[i+1,j] = states[i,j])) endif));
  
% Estado de los registros después de una operación NO de memoria
constraint forall (i in SS where (program[i] in O(OP))) (forall (j in RN) (register_states[i+1,j] == register_states[i,j]));

% Dependencias de memoria
constraint forall (i in DN, j in SS where (program[j] = O(dependencies[i,1]))) (forall (z in 1..j)(program[z] !=  O(dependencies[i,2])));
 
% Contar el valor a minimizar dependiendo de option 
constraint if option = 0 then value = s - (sum(i in SS)(program[i] = OPCODES[1])) 
elseif option = 1 then value = sum(i in SS)(fgas[i]) 
else value = sum(i in SS)(fsize[i]) endif;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  RESTRICCIONES TOSEM                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Todas las operaciones definidas deben aparecer en program
constraint (forall (x in O(OP)) (exists (z in SS) (program[z] = x)));
  
% Cada operacion definida con coste de gas mayor o igual a 3 deberá utilizarse como máximo una vez.
constraint forall (o in O(OP)) (count (i in SS, j in SNO where (j == O^-1(program[i])))((program[i] == o)/\(gas[j] >= 3)) <= 1);

% La instrucción justo antes de POP no puede introducir un elemento en la pila. Antes de un POP solo puede ser otro POP o GETk.
constraint forall (i in 2..s where (program[i] == OPCODES[2])) ((program[i-1] == OPCODES[2])\/(exists (g in G(GET_ENUM)) (program[i-1] == g)));

solve minimize value;