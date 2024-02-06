%0=NOP 1=POP  2=PUSH0  3=DUP2  4=GT 5=POP 6=DUP1 7=DUP2 8=SWAP1 9=SWAP2 10=SWAP3

% "POP DUP1 SWAP2"

% Constantes
enum TERM = { '.', s0, s1, s2, s3};
int: s = 3; % init_progr_len
int: n = 4; % max_sk_sz

array[1..n] of TERM: startstack = [ s0, s1, s2, '.' ];
array[1..n] of TERM: endstack = [ s2, s1, s1, '.' ];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var int: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Pop
constraint forall (i in 1..s where (program[i] == 1)) ((count(j in 1..n) (states[i,j] != '.')) >= 1);
constraint ((program[1] == 1)/\(forall (i in 1..n - 1) (states[2,i] == states[1,i+1]))/\(states[2,n] == '.'));

% Dup 1
constraint forall (i in 1..s where (program[i] == 6)) ((count(j in 1..n) (states[i,j] != '.')) <= n - 1);
constraint ((program[2] == 6)/\(states[3,1] == states[2,1])/\(forall (i in 2..n) (states[3,i] == states[2,i-1])));

% Swap 2
constraint forall (i in 1..s where (program[i] == 9)) ((count(j in 1..n) (states[i,j] != '.')) >= 2);
constraint ((program[3] == 9)/\(states[4,1] == states[3,3])/\(states[4,3] == states[3,1]));
constraint forall (i in 1..n where ((i != 1)/\((i != 3)))) (states[4,i] == states[3,i]);