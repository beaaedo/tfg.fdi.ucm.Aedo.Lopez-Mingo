Instrucciones para la ejecución del código
------------------------------------------

Directorios
- evm_basico: contiene el código utilizado para la parte básica del proyecto en EVM.
- evm_extensiones: contiene el código utilizado para las extensiones EVM del proyecto.
- evm_webassembly: contiene el código utilizado para el modelo WASM del proyecto.

Archivos comunes en cada directorio
- Script generar_dzn.sh: este script genera los ficheros de datos de Minizinc y los guarda en una carpeta especificada por el script. Antes de la ejecución se debe editar la variable base_folder a la ubicación actual de la carpeta.
- Script ejecutar_ejemplos.sh: este script ejecuta el modelo de Minizinc para todos los archivos de datos Minizinc (.dzn) de el directorio especificado por la variable dzn_folder. Una vez ya ha sido ejecutado el modelo para todos ejecuta el script de python "process_solution.py" y genera un CSV con los resultados obtenidos, en los directorios de las extensiones. Antes de la ejecución se debe editar la variable base_folder a la ubicación actual de la carpeta y la variable Minizinc a donde se encuentre el ejecutable de Minizinc en su sistema.
- Script creardzn_ejecutarejemplos.sh: este script ejecuta los scripts de "generar_dzn.sh" y "ejecutar_ejemplos.sh". Antes de la ejecución se debe editar la variable base_folder a la ubicación actual de la carpeta.
- Modelo de Minizinc: en todos los directorios hay un modelo de Minizinc (.mzn) con el modelo que se ejecutará. Los contenidos y especificaciones de cada modelo están explicados en la memoria de este proyecto.

Archivos comunes en los directorios de evm_extensiones y webassembly: los siguientes archivos se han usado para la experimentación por lo que únicamente han sido usados para las extensiones.
- Script process_solution.py: script de python que procesa cada solución y ejecuta el script "symbolic_execution.py" para crear el csv con los resultados.
- Script symbolic_execution.py: script que ejecuta simbólicamente cada ejemplo.

Requisitos antes de la ejecución: para poder ejecutar en su sistema debe tener instalado los siguientes programas. Es importante comentar que los scripts de bash están preparados para correr en un entorno Linux, por lo que si se intentan ejecutar en Windows o MacOS podrían dar algún problema.
- Python
- Minizinc