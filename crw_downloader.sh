#!/bin/bash

# Configuración
start_year=1994
end_year=2025
base_url="https://www.star.nesdis.noaa.gov/pub/socd/mecb/crw/data/5km/v3.1_op/nc/v1.0/daily/sst"
output_dir="./data"
min_size_bytes=10240  # Tamaño mínimo aceptado: 10 KB

# Verificar que aria2c esté instalado
if ! command -v aria2c &> /dev/null; then
    echo "❌ Error: aria2c no está instalado. Instálalo con: sudo apt install aria2"
    exit 1
fi

# Bucle desde end_year hacia start_year
for year in $(seq $end_year -1 $start_year); do
    echo "🔄 Descargando archivos del año $year..."

    year_dir="$output_dir/$year"
    mkdir -p "$year_dir"

    url_list="urls_$year.txt"
    > "$url_list"
    archivos_a_descargar=0

    # Generar lista solo con archivos que faltan o están incompletos
    for day in $(seq -w 1 366); do
        date=$(date -d "$year-01-01 +$((10#$day - 1)) days" +%Y%m%d 2>/dev/null)
        if [ -z "$date" ]; then continue; fi

        filename="coraltemp_v3.1_${date}.nc"
        local_path="$year_dir/$filename"
        url="$base_url/$year/$filename"

        if [ -f "$local_path" ]; then
            size=$(stat -c%s "$local_path")
            if [ "$size" -ge "$min_size_bytes" ]; then
                echo "✔️ $filename ya existe y es válido. Omitido."
                continue
            else
                echo "⚠️ $filename existe pero es pequeño ($size bytes). Se volverá a descargar."
            fi
        else
            echo "📄 $filename no existe. Se descargará."
        fi

        echo "$url" >> "$url_list"
        ((archivos_a_descargar++))
    done

    # Verificar si hay archivos por descargar
    if [ "$archivos_a_descargar" -gt 0 ]; then
        echo "⬇️ Se descargarán $archivos_a_descargar archivos para $year..."
        aria2c -i "$url_list" \
            --dir="$year_dir" \
            --continue \
            --max-concurrent-downloads=10 \
            --auto-file-renaming=false \
            --summary-interval=0 \
            --console-log-level=warn
    else
        echo "✅ Todos los archivos de $year ya están completos. Nada que hacer."
    fi

    rm -f "$url_list"
    echo "⏸ Pausando 60 segundos..."
    sleep 60
done

echo "🏁 Descarga finalizada."
