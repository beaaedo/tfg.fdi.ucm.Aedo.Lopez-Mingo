#!/bin/bash

base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
json_folder="$base_folder/ejemplos_json"
dzn_folder="$base_folder/ejemplos_dzn"
results_folder="$base_folder/ejemplos_results"
python_script="$base_folder/dzn_generation.py"
mzn_script="$base_folder/satisfaccion.mzn"
minizinc="/c/Program Files/MiniZinc/minizinc.exe"

mkdir -p "$dzn_folder"
mkdir -p "$results_folder"

for json_file in "$json_folder"/*.json; do
    if [ -f "$json_file" ]; then
        python "$python_script" "$json_file" 
    
    fi
done

mv "$json_folder"/*.dzn "$dzn_folder"

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