#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
#base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg/evm"
base_folder="/c/Users/claud/OneDrive/Escritorio/Clase/TFG/tfg/evm"
json_folder="$base_folder/ejemplos_json"
#json_folder="$base_folder/ejemplos_json_grande"
#json_folder="$base_folder/ejemplos_json_stack_deps"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
mzn_script="$base_folder/satisfaccion_evm.mzn"
verification_script="$base_folder/process_solution.py"
json_folder="$base_folder/ejemplos_json"

# Crear las carpetas que van a ser necesarias
mkdir -p "$results_folder"

solve_with_minizinc() {
    dzn_file="$1"
    result_folder="$2"
    minizinc="$3"
    mzn_script="$4"

    # Almacenar el nombre del dzn sin el .dzn para crear un archivo de texto con cada resultado
    base_name=$(basename "$dzn_file" .dzn)
    result_file="$result_folder/$base_name.txt"
    
    # Ejecución del código de minizinc
    timeout 300s "$minizinc" --solver Chuffed --output-time -i "$mzn_script" "$dzn_file" -o "$result_file"
    
    # Devuelve éxito o error dependiendo de si se ha ejecutado bien mal. Si devuelve ERROR también devuelve los contenidos del archivo, mola para debugging.
    if [ $? -eq 0 ]; then
        echo "Ejecutado con éxito: $base_name"
        echo ""

    else
        echo "Error en la ejecución: $base_name"
        cat "$result_file"
    fi
}

# Export the function so it's accessible to parallel
export -f solve_with_minizinc

# Run MiniZinc solver concurrently on multiple CPU cores
find "$dzn_folder" -type f -name "*.dzn" | parallel -j 128 solve_with_minizinc {} "$results_folder"  "$minizinc" "$mzn_script"

# AHC: Comentar esta línea si da problemas
python "$verification_script" "$json_folder" "$results_folder"

