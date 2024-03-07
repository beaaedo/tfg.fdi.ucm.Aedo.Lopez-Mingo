#!/bin/bash
base_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg"
json_folder="$base_folder/ejemplos_json"
dzn_folder="$base_folder/ejemplos_dzn"
python_script="$base_folder/dzn_generation.py"

mkdir -p "$dzn_folder"

for json_file in "$json_folder"/*.json; do
    if [ -f "$json_file" ]; then
        python "$python_script" "$json_file" 
    
    fi
done

mv "$json_folder"/*.dzn "$dzn_folder"