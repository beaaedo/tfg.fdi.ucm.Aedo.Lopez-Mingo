#!/bin/bash

# PATHS
# Antes de la ejecución editar la variable base_folder con la ubicacion actual de los archivos
base_folder=""/home/beaclaudia/wasm""
json_folder="$base_folder/dataset_circom"
dzn_folder="$base_folder/dataset_dzn"
python_script="$base_folder/dzn_generation.py"

# Crear las carpetas que van a ser necesarias
mkdir -p "$dzn_folder"

# Código que ejecuta el python y crea los dzns
find "$json_folder" -type f -name "*.json" | while IFS= read -r json_file; do
    if [ -e "$json_file" ]; then 
        python3 "$python_script" "$json_file" 
        chmod 777 "${json_file%.json}.dzn"
        mv "${json_file%.json}.dzn" "$dzn_folder"
    fi
done

