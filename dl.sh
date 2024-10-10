#!/bin/bash



# ----------------------------------------------
# Variables
# ----------------------------------------------
DOWNLOAD_DIR="$HOME/storage/shared/Download"
OS_TYPE=$(uname)
UPDATE_TIMESTAMP_FILE="$HOME/.yt_dlp_update_timestamp"

# Agregar ~/.local/bin al PATH
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------
# Función para instalar dependencias en diferentes plataformas
# ----------------------------------------------
install_dependencies() {
    echo "$(date): Instalando dependencias necesarias..."

    if [ "$OS_TYPE" = "Linux" ]; then
        if [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
            # Estamos en Termux y no somos root
            pkg update && pkg upgrade -y
            pkg install -y ffmpeg curl python python-pip
            pip install --upgrade yt-dlp

            # ----------------------------------------------
            # Corrección: Asegurar que el shebang de yt-dlp es correcto en Termux
            # ----------------------------------------------
            YTDLP_PATH="$HOME/.local/bin/yt-dlp"
            if [ -f "$YTDLP_PATH" ]; then
                # Verificar y corregir el shebang si es necesario
                SHEBANG=$(head -n 1 "$YTDLP_PATH")
                CORRECT_SHEBANG="#!/data/data/com.termux/files/usr/bin/python3"

                if [[ "$SHEBANG" != "$CORRECT_SHEBANG" ]]; then
                    echo "$(date): Corrigiendo el shebang de yt-dlp..."
                    sed -i "1c $CORRECT_SHEBANG" "$YTDLP_PATH"
                fi

                # Asegurar permisos de ejecución
                chmod +x "$YTDLP_PATH"
            else
                echo "$(date): yt-dlp no se encontró después de la instalación con pip."
                exit 1
            fi

        elif [ -x "$(command -v apt)" ]; then
            # Estamos en una distribución de Linux como Ubuntu
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y ffmpeg curl python3-pip
            sudo pip3 install --upgrade yt-dlp
        else
            echo "$(date): Gestor de paquetes no soportado en Linux."
            exit 1
        fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
        # Estamos en macOS
        if ! command -v brew &> /dev/null; then
            echo "$(date): Homebrew no está instalado. Por favor, instala Homebrew desde https://brew.sh/."
            exit 1
        fi
        brew update
        brew install yt-dlp ffmpeg
    else
        echo "$(date): Sistema operativo no soportado. Instala yt-dlp, ffmpeg, curl y python manualmente."
        exit 1
    fi
}

# ----------------------------------------------
# Verificar si yt-dlp está instalado
# ----------------------------------------------
check_yt_dlp_installed() {
    if ! command -v yt-dlp &> /dev/null; then
        echo "$(date): yt-dlp no está instalado. Instalándolo ahora..."
        install_dependencies
    else
        echo "$(date): yt-dlp ya está instalado."
    fi
}

# ----------------------------------------------
# Función para configurar el almacenamiento en Termux
# ----------------------------------------------
setup_termux_storage() {
    if [ "$OS_TYPE" = "Linux" ] && [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
        # Configuramos almacenamiento en Termux solo si no somos root
        if [ ! -d "$DOWNLOAD_DIR" ]; then
            echo "$(date): Configurando el almacenamiento de Termux..."
            termux-setup-storage
            # Esperar a que el usuario conceda permisos
            sleep 2
        fi
    fi
}

# ----------------------------------------------
# Función para actualizar herramientas condicionalmente
# ----------------------------------------------
update_tools() {
    local CURRENT_TIME=$(date +%s)
    local SEVEN_DAYS=$((7 * 24 * 60 * 60)) # 7 días en segundos

    if [ -f "$UPDATE_TIMESTAMP_FILE" ]; then
        local LAST_UPDATE=$(cat "$UPDATE_TIMESTAMP_FILE")
        local TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

        if [ "$TIME_DIFF" -lt "$SEVEN_DAYS" ]; then
            echo "$(date): Las herramientas ya están actualizadas. Última actualización hace menos de 7 días."
            return
        fi
    fi

    echo "$(date): Actualizando yt-dlp y ffmpeg..."

    yt-dlp -U
    if [ "$OS_TYPE" = "Linux" ]; then
        if [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
            # Solo actualizar con pkg si no somos root
            pkg upgrade -y ffmpeg
        elif [ -x "$(command -v apt)" ]; then
            sudo apt update && sudo apt upgrade -y
            sudo apt install --only-upgrade ffmpeg
        fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
        brew upgrade yt-dlp ffmpeg
    fi

    # Actualizar la marca de tiempo
    echo "$CURRENT_TIME" > "$UPDATE_TIMESTAMP_FILE"
    echo "$(date): Actualización completada y marca de tiempo actualizada."
}

# ----------------------------------------------
# Función para manejar el proceso de descarga y verificar el éxito
# ----------------------------------------------
download_file() {
    local VIDEO_URL="$1"
    local OPTION="$2"

    echo "$(date): Iniciando la descarga de $VIDEO_URL..."

    if [ "$OPTION" -eq 1 ]; then
        # Descargar como audio (mp3)
        yt-dlp -x --audio-format mp3 -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$VIDEO_URL"
        DOWNLOAD_STATUS=$?
    elif [ "$OPTION" -eq 2 ]; then
        # Descargar como video
        yt-dlp -f best -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$VIDEO_URL"
        DOWNLOAD_STATUS=$?
    else
        echo "$(date): Opción no válida."
        exit 1
    fi

    if [ "$DOWNLOAD_STATUS" -ne 0 ]; then
        echo "$(date): Error durante la descarga."
        exit 1
    fi

    echo "$(date): Descarga completada exitosamente en $DOWNLOAD_DIR."
}

# ----------------------------------------------
# Función Principal del Script
# ----------------------------------------------
main() {
    # Verificar si se proporcionaron los argumentos necesarios
    if [ -z "$1" ]; then
        echo "Error: No se proporcionó la URL del video."
        echo "Uso: $0 URL_DEL_VIDEO [1|2]"
        echo "1: Descargar como audio (MP3)"
        echo "2: Descargar como video"
        exit 1
    fi

    if [ -z "$2" ] || { [ "$2" -ne 1 ] && [ "$2" -ne 2 ]; }; then
        echo "Error: Opción inválida. Debes usar 1 para audio (MP3) o 2 para video."
        echo "Uso: $0 URL_DEL_VIDEO [1|2]"
        exit 1
    fi

    # Configurar almacenamiento si es necesario (solo para Termux)
    setup_termux_storage

    # Verificar que yt-dlp esté instalado
    check_yt_dlp_installed

    # Actualizar yt-dlp y ffmpeg condicionalmente
    update_tools

    # Crear directorio de descargas si no existe
    mkdir -p "$DOWNLOAD_DIR"

    # Descargar el archivo
    download_file "$1" "$2"
}

# ----------------------------------------------
# Ejecutar la Función Principal con los Argumentos
# ----------------------------------------------
main "$@"
