%0=NOP 1=POP  2=PUSH0  3=DUP2  4=GT 5=POP 6=DUP1 7=DUP2 8=SWAP1 9=SWAP2 10=SWAP3

% "SWAP3 SWAP1 SWAP3 SWAP2"

% Constantes
enum TERM = { '.', s0, s1, s2, s3};
int: s = 4; % init_progr_len
int: n = 5; % max_sk_sz

array[1..n] of TERM: startstack = [ s0, s1, s2, s3, '.' ];
array[1..n] of TERM: endstack = [ s2, s3, s0, s1 , '.'];

% Variables
% matriz s + 1 x n, s+1 pilas
array[1..s+1, 1..n] of var TERM: states;
array[1..s] of var int: program;

% Init stacks
constraint forall (i in 1..n) ((states[1,i] == startstack[i])/\(states[s+1,i] == endstack[i]));

% Swap 1
constraint forall (i in 1..s where (program[i] == 8)) ((count(j in 1..n) (states[i,j] != '.')) >= 1);
constraint ((program[2] == 8)/\(states[3,1] == states[2,2])/\(states[3,2] == states[2,1]));
constraint forall (i in 1..n where ((i != 1)/\((i != 2)))) (states[3,i] == states[2,i]);

% Swap 2
constraint forall (i in 1..s where (program[i] == 9)) ((count(j in 1..n) (states[i,j] != '.')) >= 2);
constraint ((program[4] == 9)/\(states[5,1] == states[4,3])/\(states[5,3] == states[4,1]));
constraint forall (i in 1..n where ((i != 1)/\((i != 3)))) (states[5,i] == states[4,i]);

% Swap 3 
constraint forall (i in 1..s where (program[i] == 10)) ((count(j in 1..n) (states[i,j] != '.')) >= 3);
constraint ((program[1] == 10)/\(states[2,1] == states[1,4])/\(states[2,4] == states[1,1]));
constraint ((program[3] == 10)/\(states[4,1] == states[3,4])/\(states[4,4] == states[3,1]));
constraint forall (i in 1..n where ((i != 1)/\((i != 4)))) ((states[2,i] == states[1,i])/\(states[4,i] == states[3,i]));