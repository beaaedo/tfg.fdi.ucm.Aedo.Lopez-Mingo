#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
mzn_script="$base_folder/satisfaccion.mzn"

# Crear las carpetas que van a ser necesarias
mkdir -p "$results_folder"

for dzn_file in "$dzn_folder"/*.dzn; do
    # Comprobar si existe el archivo
    if [ -e "$dzn_file" ]; then
        # Almacenar el nombre del dzn sin el ".dzn" para crear un archivo de texto con cada resultado
        base_name=$(basename "$dzn_file" .dzn)
        result_file="$results_folder/$base_name.txt"

        # Ejecución del código de minizinc
        execution_time=$({ time $minizinc "$mzn_script" "$dzn_file" -o "$result_file" ; } 2>&1 | grep real)
        echo "time = $execution_time" >> $result_file

        # Devuelve éxito o error dependiendo de si se ha ejecutado bien  mal. Si devuelve ERROR tambien devuelve los contenidos del archivo, mola para debugging.
        if [ $? -eq 0 ]; then
            echo "Ejecutado con éxito: $base_name"
        else
            echo "Error en la ejecución: $base_name"
            cat "$result_file"
        fi
    fi 
done