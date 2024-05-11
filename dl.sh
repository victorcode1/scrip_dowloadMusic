#!/bin/bash

# Verificar si yt-dlp está instalado
if ! command -v yt-dlp &> /dev/null; then
    echo "yt-dlp no está instalado. Instalando..."
    brew install yt-dlp  # Esto asume que tienes Homebrew instalado
fi

# Verificar si se proporcionó la URL del video como argumento
if [ $# -lt 1 ]; then
    echo "Uso: $0 URL_DEL_VIDEO [1|2]"
    echo "1: Copiar al USB"
    echo "2: Copiar al escritorio"
    exit 1
fi

# URL del video
VIDEO_URL="$1"

# Descargar el video con el mejor formato disponible (MP4)
yt-dlp "$VIDEO_URL"




# Comprobar si se descargó el video en formato MP4
if [ $? -eq 0 ]; then
    # Determinar la ubicación de destino de la copia
    DESTINATION=""
    if [ "$2" = "1" ]; then
        DESTINATION="/Volumes/VIDEOS/"
    elif [ "$2" = "2" ]; then
        DESTINATION="$HOME/Desktop/"
    else
        echo "Destino no válido. Copiando al escritorio por defecto."
        DESTINATION="$HOME/Desktop/"
    fi
    
    # Copiar el video al destino especificado
    echo "Copiando el video..."
    cp *.mp4 "$DESTINATION"
    echo "Video copiado exitosamente."

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
