#!/bin/bash

set -x

json_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg/ejemplos_json"
output_folder="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg/ejemplos_dzn"
python_script="/c/Users/Bea/Documents/curso23-24/tfg/codigo/tfg/dzn_generation.py"

for json_file in "$json_folder"/*.json; do
    if [ -f "$json_file" ]; then
        base_name=$(basename -- "$json_file")
        file_name="${base_name%.*}"

        python "$python_script" "$json_file" > "$output_folder/$file_name.dzn"
    fi
done
