#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
json_folder="$base_folder/ejemplos_json"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
python_script="$base_folder/dzn_generation.py"
mzn_script="$base_folder/satisfaccion.mzn"

# Crear las carpetas que van a ser necesarias
mkdir -p "$dzn_folder"
mkdir -p "$results_folder"

# Código que ejecuta el python y crea los dzns
for json_file in "$json_folder"/*.json; do
    if [ -f "$json_file" ]; then
        python "$python_script" "$json_file" 
    
    fi
done

# Se tarda menos en mover los archivos de golpe que en cada ejecución
mv "$json_folder"/*.dzn "$dzn_folder"

for dzn_file in "$dzn_folder"/*.dzn; do
    # Comprobar si existe el archivo
    if [ -e "$dzn_file" ]; then
        # Almacenar el nombre del dzn sin el ".dzn" para crear un archivo de texto con cada resultado
        base_name=$(basename "$dzn_file" .dzn)
        result_file="$results_folder/$base_name.txt"

        # Ejecución del código
        execution_time=$({ time $minizinc "$mzn_script" "$dzn_file" -o "$result_file" ; } 2>&1 | grep real)
        echo "time = $execution_time" >> $result_file
        #minizinc "$mzn_script" "$dzn_file" -o "$result_file"

        # Devuelve éxito o error dependiendo de si se ha ejecutado bien  mal. Si devuelve ERROR tambien devuelve los contenidos del archivo, mola para debugging.
        if [ $? -eq 0 ]; then
            echo "Ejecutado con éxito: $base_name"
        else
            echo "Error en la ejecución: $base_name"
            cat "$result_file"
        fi
    fi 
done