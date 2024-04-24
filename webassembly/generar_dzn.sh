#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
base_folder="/Users/beaaedo/Desktop/tfg/codigo/webassembly"
json_folder="$base_folder/wasm-small-examples"
dzn_folder="$base_folder/ejemplos_dzn"
python_script="$base_folder/dzn_generation.py"

# Crear las carpetas que van a ser necesarias
mkdir -p "$dzn_folder"

# Código que ejecuta el python y crea los dzns
find "$json_folder" -type f -name "*.json" | while IFS= read -r json_file; do
    if [ -e "$json_file" ]; then 
        python3 "$python_script" "$json_file" 
        parent_dir=$(basename "$(dirname "$json_file")")
        
        subdirectory="$dzn_folder/$parent_dir"
        mkdir -p "$subdirectory"

        chmod 777 "${json_file%.json}.dzn"
        mv "${json_file%.json}.dzn" "$subdirectory"
    fi
done

