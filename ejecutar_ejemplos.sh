#!/bin/bash

base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
mzn_script="$base_folder/satisfaccion.mzn"
minizinc="/c/Program Files/MiniZinc/minizinc.exe"

mkdir -p "$results_folder"

for dzn_file in "$dzn_folder"/*.dzn; do
    # Check if the file exists
    if [ -e "$dzn_file" ]; then
        base_name=$(basename "$dzn_file" .dzn)
        result_file="$results_folder/$base_name.txt"
        "$minizinc" --solver gecode "$mzn_script" "$dzn_file" -o "$result_file"
        if [ $? -eq 0 ]; then
            echo "Success: $base_name"
        else
            echo "Error: $base_name"
        fi
    fi 
done