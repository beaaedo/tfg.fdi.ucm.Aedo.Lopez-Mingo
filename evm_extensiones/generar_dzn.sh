#!/bin/bash

# PATHS
# Antes de la ejecución editar la variable base_folder con la ubicacion actual de los archivos
base_folder="/c/Users/claud/OneDrive/Escritorio/Clase/TFG/tfg/evm"
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