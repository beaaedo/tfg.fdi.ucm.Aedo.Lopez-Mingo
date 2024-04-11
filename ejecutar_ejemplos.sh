#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
#base_folder="/c/Users/claud/OneDrive/Escritorio/Clase/TFG/tfg"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
mzn_script="$base_folder/satisfaccion.mzn"
verification_script="$base_folder/verify_solution.py"

# Crear las carpetas que van a ser necesarias
mkdir -p "$results_folder"

for dzn_file in "$dzn_folder"/*.dzn; do
    # Comprobar si existe el archivo
    if [ -e "$dzn_file" ]; then
        # Almacenar el nombre del dzn sin el ".dzn" para crear un archivo de texto con cada resultado
        base_name=$(basename "$dzn_file" .dzn)
        result_file="$results_folder/$base_name.txt"
        json_file="$json_folder/$base_name.json"

        # Ejecución del código de minizinc
        timeout -k 1 1 minizinc --solver Gecode --output-time -i "$mzn_script" "$dzn_file" -o "$result_file";

        # Devuelve éxito o error dependiendo de si se ha ejecutado bien  mal. Si devuelve ERROR tambien devuelve los contenidos del archivo, mola para debugging.
        if [ $? -eq 0 ]; then
            echo "Ejecutado con éxito: $base_name"
            # AHC: Comentar esta línea si da problemas
            python3 "$verification_script" "$json_file" "$result_file"
            echo ""

        else
            echo "Error en la ejecución: $base_name"
            cat "$result_file"
        fi
    fi 
done