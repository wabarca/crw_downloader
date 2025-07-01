#!/bin/bash

# Configuración
data_dir="./data"
start_year=1994
end_year=2025

# Paso 1: Generar archivos anuales combinados y comprimidos
echo "📦 Paso 1: Combinando y comprimiendo archivos diarios por año..."

for year in $(seq $start_year $end_year); do
    daily_dir="$data_dir/$year"
    temp_file="$data_dir/coraltemp_v3.1_${year}.nc"
    compressed_file="$data_dir/coraltemp_v3.1_${year}_c.nc"

    if [ ! -f "$compressed_file" ]; then
        echo "🔄 Procesando año $year..."

        # Combinar archivos diarios
        cdo mergetime "$daily_dir"/*.nc "$temp_file"

        # Comprimir con nccopy -d 9
        echo "📦 Comprimiendo $temp_file..."
        nccopy -d 9 "$temp_file" "$compressed_file"
        rm -f "$temp_file"

        # Eliminar archivos diarios y carpeta
        echo "🧹 Eliminando archivos diarios de $year..."
        rm -rf "$daily_dir"
    else
        echo "✔️ Ya existe: $compressed_file, omitido."
    fi
done

# Paso 2: Unir todos los archivos anuales comprimidos y comprimir resultado
echo "📦 Paso 2: Uniendo y comprimiendo archivos anuales en coraltemp_v3.1.nc..."

merged_tmp="$data_dir/tmp_combined.nc"
combined_file="$data_dir/coraltemp_v3.1.nc"

if [ ! -f "$combined_file" ]; then
    cdo mergetime $data_dir/coraltemp_v3.1_*_c.nc "$merged_tmp"
    echo "📦 Comprimiendo archivo combinado..."
    nccopy -d 9 "$merged_tmp" "$combined_file"
    rm -f "$merged_tmp"
    echo "✅ Archivo combinado comprimido: $combined_file"
else
    echo "✔️ Ya existe: $combined_file, omitido."
fi

# Paso 3: Recortar región y comprimir
echo "✂️ Paso 3: Recortando y comprimiendo coraltemp_v3.1.nc..."

cropped_tmp="$data_dir/tmp_cropped.nc"
cropped_file="$data_dir/coraltemp_v3.1_PWP.nc"

if [ ! -f "$cropped_file" ]; then
    cdo sellonlatbox,-120,-60,0,30 "$combined_file" "$cropped_tmp"
    echo "📦 Comprimiendo archivo recortado..."
    nccopy -d 9 "$cropped_tmp" "$cropped_file"
    rm -f "$cropped_tmp"
    echo "✅ Archivo recortado comprimido: $cropped_file"
else
    echo "✔️ Ya existe: $cropped_file, omitido."
fi

echo "🏁 Procesamiento completo."
