#!/bin/bash

# PATHS
# Antes de la ejecución editar la variable base_folder con la ubicacion actual de los archivos
base_folder="/Users/beaaedo/Desktop/tfg/codigo/evm_basico"

# Llamada a los dos scripts
./"$base_folder"/generar_dzn.sh
./"$base_folder"/ejecutar_ejemplos.sh
