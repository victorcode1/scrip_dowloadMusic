#!/bin/bash

# Verificar si se proporcionó la URL del video como argumento
if [ $# -ne 1 ]; then
    echo "Uso: $0 URL_DEL_VIDEO"
    exit 1
fi

# URL del video
VIDEO_URL="$1"

# Descargar el video con el mejor formato disponible (MP4)
yt-dlp --format 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]' "$VIDEO_URL"

# Comprobar si se descargó el video en formato MP4
if [ $? -eq 0 ]; then
    # Copiar el video al USB si la descarga fue exitosa
    echo "Copiando el video al USB..."
    # cp *.mp4 /Volumes/USB/
    cp *.mp4 ~/Desktop/
    echo "Video copiado exitosamente al USB."
    
    # Borrar el archivo de video descargado
    echo "Borrando el archivo descargado..."
    rm *.mp4
    echo "Archivo descargado borrado."
else
    # Mostrar mensaje de error y la lista de formatos disponibles
    echo "Error: No se pudo descargar el video en formato MP4."
    echo "El video está disponible en los siguientes formatos:"
    yt-dlp --list-formats "$VIDEO_URL"
fi
