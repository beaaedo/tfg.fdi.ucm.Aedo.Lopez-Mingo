#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
 base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
#base_folder="/c/Users/claud/OneDrive/Escritorio/Clase/TFG/tfg"
json_folder="$base_folder/ejemplos_json"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
python_script="$base_folder/dzn_generation.py"
mzn_script="$base_folder/satisfaccion.mzn"
verification_script="$base_folder/verify_solution.py"

# Llamada a los dos scripts
bash $base_folder/generar_dzn.sh
bash $base_folder/ejecutar_ejemplos.sh