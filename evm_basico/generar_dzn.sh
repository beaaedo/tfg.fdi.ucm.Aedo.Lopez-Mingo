#!/bin/bash

# PATHS
base_folder="/home/beaclaudia/evm_basico"
json_folder="$base_folder/ejemplos_json"
dzn_folder="$base_folder/ejemplos_dzn"
python_script="$base_folder/dzn_generation.py"

# Crear las carpetas que van a ser necesarias
mkdir -p "$dzn_folder"

# Código que ejecuta el python y crea los dzns
for json_file in "$json_folder"/*.json; do
    if [ -f "$json_file" ]; then
        python "$python_script" "$json_file" 
    
    fi
done

# Se tarda menos en mover los archivos de golpe que en cada ejecución
mv "$json_folder"/*.dzn "$dzn_folder"