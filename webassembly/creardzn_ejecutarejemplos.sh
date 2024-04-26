#!/bin/bash

# ANTES DE EJECUTAR EN GIT BASH
# 1. Ejecutar el comando export PATH=$PATH:{MINIZINC} donde {MINIZINC} es el path a tu instalacion de minzinc
# 2. Cambiar el path de base_folder al de tu sistema
# 3. Se ejecuta primero el de generar_dzn.sh y luego el de ejecutar_ejemplos.sh o solamente el de creardzn_ejecutarejemplos.sh

# PATHS
 base_folder="/home/alejandro/tfg_minizinc/tfg/webassembly"

# Llamada a los dos scripts
bash $base_folder/generar_dzn.sh
bash $base_folder/ejecutar_ejemplos.sh
