#!/bin/bash

# Configuración
data_dir="./data"
start_year=199
end_year=2025

# Paso 1: Combinar archivos diarios → anuales
echo "📦 Paso 1: Combinando archivos diarios por año..."

for year in $(seq $start_year $end_year); do
    daily_dir="$data_dir/$year"
    annual_raw="$data_dir/coraltemp_v3.1_${year}.nc"
    annual_compressed="$data_dir/coraltemp_v3.1_${year}_c.nc"

    if [ ! -f "$annual_compressed" ]; then
        echo "🔄 Año $year: combinando diarios..."
        cdo mergetime "$daily_dir"/*.nc "$annual_raw"

        echo "📦 Comprimiendo archivo anual..."
        nccopy -d 9 "$annual_raw" "$annual_compressed"
        rm -f "$annual_raw"
    else
        echo "✔️ Ya existe comprimido: $annual_compressed, omitido."
    fi
done

# Paso 2: Recortar y comprimir cada archivo anual comprimido
echo "✂️ Paso 2: Recortando y comprimiendo archivos anuales..."

for year in $(seq $start_year $end_year); do
    annual_compressed="$data_dir/coraltemp_v3.1_${year}_c.nc"
    cropped_tmp="$data_dir/tmp_crop_${year}.nc"
    cropped_compressed="$data_dir/coraltemp_v3.1_${year}_PACHO.nc"

    if [ ! -f "$cropped_compressed" ]; then
        echo "✂️ Año $year: recortando región..."
        cdo sellonlatbox,-120,-60,0,30 "$annual_compressed" "$cropped_tmp"

        echo "📦 Comprimiendo archivo recortado..."
        nccopy -d 9 "$cropped_tmp" "$cropped_compressed"
        rm -f "$cropped_tmp"
    else
        echo "✔️ Ya existe recortado: $cropped_compressed, omitido."
    fi
done

# Paso 3: Eliminar carpetas de diarios
echo "🧹 Paso 3: Eliminando archivos diarios..."
for year in $(seq $start_year $end_year); do
    rm -rf "$data_dir/$year"
done

# Paso 4: Combinar archivos recortados en uno global
echo "📦 Paso 4: Combinando archivos recortados..."

merged_tmp="$data_dir/tmp_combined_PACHO.nc"
final_combined="$data_dir/coraltemp_v3.1_PACHO.nc"

if [ ! -f "$final_combined" ]; then
    cdo mergetime $data_dir/coraltemp_v3.1_*_PACHO.nc "$merged_tmp"
    echo "📦 Comprimiendo archivo combinado final..."
    nccopy -d 9 "$merged_tmp" "$final_combined"
    rm -f "$merged_tmp"
    echo "✅ Archivo final creado: $final_combined"
else
    echo "✔️ Ya existe: $final_combined, omitido."
fi

echo "🏁 Procesamiento completo y todos los archivos comprimidos."
