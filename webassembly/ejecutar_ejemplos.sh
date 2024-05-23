#!/bin/bash

# PATHS
# Antes de la ejecución editar la variable base_folder con la ubicacion actual de los archivos y minizinc con la ubicación de el ejecutable de Minizinc
base_folder="/home/beaclaudia/wasm"
json_folder="$base_folder/dataset_circom"
dzn_folder="$base_folder/dataset_dzn"
results_folder="$base_folder/dataset_results"
mzn_script="$base_folder/webassembly/satisfaccion_webassembly.mzn"
verification_script="$base_folder/webassembly/process_solution.py"
minizinc="$base_folder/MiniZincIDE-2.8.3-bundle-linux-x86_64/bin/minizinc"

# Crear las carpetas que van a ser necesarias
mkdir -p "$results_folder"

# Función que ejecuta el solver de MiniZinc
solve_with_minizinc() {
    dzn_file="$1"
    result_folder="$2"
    minizinc="$3"
    mzn_script="$4"

    # Almacenar el nombre del dzn sin el .dzn para crear un archivo de texto con cada resultado
    base_name=$(basename "$dzn_file" .dzn)
    result_file="$result_folder/$base_name.txt"
    
    # Ejecución del código de minizinc
    "$minizinc" --solver Chuffed --output-time -i "$mzn_script" "$dzn_file" -o "$result_file"  --time-limit 180000
    
    # Devuelve éxito o error dependiendo de si se ha ejecutado bien mal. Si devuelve ERROR también devuelve los contenidos del archivo, mola para debugging.
    if [ $? -eq 0 ]; then
        echo "Ejecutado con éxito: $base_name"
        echo ""

    else
        echo "Error en la ejecución: $base_name"
        cat "$result_file"
    fi
}

# Exportar la función para que sea accesible para parallel
export -f solve_with_minizinc

# Ejecutar solver de MiniZinc concurrentemente en los 128 cores de la CPU
find "$dzn_folder" -type f -name "*.dzn" | parallel -j 128 solve_with_minizinc {} "$results_folder"  "$minizinc" "$mzn_script"

# Ejecutar python que crea el csv de las soluciones
python "$verification_script" "$json_folder" "$results_folder"
