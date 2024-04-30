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