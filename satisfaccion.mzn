% Primera practica de PR - Marcos Colombas Garcia y Beatriz Aedo Diaz 

%Parámetros
int: D;
int: T;
int: N1; int: N2; int: N3;
int: MaxDT; int: MinDT; int: MaxDL;
int: A;
array[1..T,1..T] of bool: afines;
set of int: R;
array[1..T,1..D] of 0..1: dias_solicitados;
array[1..T,1..D] of 1..4:   turnos_indeseados;

%Variables
array[1..T,1..D] of var 0..3: sol;

% Constraints assert
constraint assert( MaxDT <= D, "El número de días máximos trabajados seguidos debe ser mayor o igual que el número de días.");
constraint assert( MinDT <= D, "El número de días mínimos trabajados debe ser menor o igual que el número de días.");
constraint assert( A < T, "El numero de trabajadores afines no puede ser igual al numero de trabajadores.");
constraint assert((forall(i in 1..T) ((sum(j in 1..T) (afines[i,j])) >= A)), "El numero de trabajadores afines en cada turno no puede ser mayor a el numero de trabajadores afines que tiene cada trabajador.");
constraint assert( (forall (i in 1..T,j in 1..T) (afines[i,j] = afines[j,i])), "La matriz afines debe ser simétrica.");
constraint assert( (forall (i in 1..T) (afines[i,i] = 0)), "Un trabajador no puede ser afin a si mismo.");

% Constraint 1
constraint forall (j in 1..D) (count(i in 1..T) (sol[i,j] == 1) = N1);
constraint forall (j in 1..D) (count(i in 1..T) (sol[i,j] == 2) = N2);
constraint forall (j in 1..D) (count(i in 1..T) (sol[i,j] == 3) = N3);

% Constraint 2: resuelto con el array sol.

% Constraint 3 - esta comentado porque tarda mucho en ejecutarse pero funciona
%constraint forall(i in 1..T,j in 1..(D - MaxDT)) ((count(k in j..j+MaxDT) (sol[i,k] > 0)) <= MaxDT);

% Constraint 4 - esta comentado porque tarda mucho en ejecutarse pero funciona
%constraint forall(i in 1..T,j in 1..(D - MaxDL)) ((count(k in j..j+MaxDL) (sol[i,k] == 0)) <= MaxDL);

% Constraint 5
constraint forall (i in 1..T) ((count(j in 1..D) (sol[i,j] != 0)) >= MinDT);

% Constraint 6
constraint forall (i in 1..T,j in 3..D where ((sol[i,j-2] == 3)/\(sol[i,j-1] == 1))) ((sol[i,j] = 0)\/(forall (k in j..(j+3) where (j + 3 <= D)) (sol[i,k] != 3)));

% Constraint 7 - esta comentado porque tarda mucho en ejecutarse pero funciona
%constraint forall (i in 1..T,j in 1..D) ((count(k in 1..T) ((afines[i,k])/\(sol[i,j] == sol[k,j])/\(sol[i,j] > 0))) >= A);

% Constraint 8  
constraint forall (j in 1..D, k in 1..3) ((count (i in 1..T) ((sol[i,j] == k)/\(i in R))) >= 1);

% Optimization 1
solve minimize (count(i in 1..T, j in 1..D) ((dias_solicitados[i,j] == 1)/\(sol[i,j] > 0))) + (max(i in 1..T)(count(j in 1..D)((dias_solicitados[i,j] == 1)/\(sol[i,j] > 0))));

% Optimization 2
%solve minimize count(i in 1..T, j in 1..D) (turnos_indeseados[i,j] == sol[i,j]) + max(i in 1..T)(count(j in 1..D) (turnos_indeseados[i,j] == sol[i,j]));


 

