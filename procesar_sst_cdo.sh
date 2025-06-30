#!/bin/bash

# Directorio base
data_dir="./data"

# Paso 1: Combinar archivos diarios en archivos anuales
echo "📦 Paso 1: Combinando archivos diarios en archivos anuales..."
for year in $(seq 1994 2025); do
    daily_dir="$data_dir/$year"
    output_file="$data_dir/coraltemp_v3.1_${year}.nc"

    if [ ! -f "$output_file" ]; then
        echo "🔄 Procesando año $year..."
        cdo mergetime "$daily_dir"/*.nc "$output_file"
    else
        echo "✔️ Ya existe: $output_file, omitido."
    fi
done

# Paso 2: Combinar archivos anuales en un único archivo
echo "📦 Paso 2: Combinando archivos anuales en coraltemp_v3.1.nc..."
combined_file="$data_dir/coraltemp_v3.1.nc"
if [ ! -f "$combined_file" ]; then
    cdo mergetime $data_dir/coraltemp_v3.1_*.nc "$combined_file"
    echo "✅ Archivo combinado creado: $combined_file"
else
    echo "✔️ Ya existe: $combined_file, omitido."
fi

# Paso 3: Recortar por región [Lat 0 a 30N, Lon -120 a -60]
echo "✂️ Paso 3: Recortando región [0N-30N, -120W a -60W]..."
cropped_file="$data_dir/coraltemp_v3.1_PACHO.nc"
if [ ! -f "$cropped_file" ]; then
    cdo sellonlatbox,-120,-60,0,30 "$combined_file" "$cropped_file"
    echo "✅ Archivo recortado creado: $cropped_file"
else
    echo "✔️ Ya existe: $cropped_file, omitido."
fi

echo "🏁 Procesamiento finalizado."
