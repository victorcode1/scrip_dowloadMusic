#!/usr/bin/env bash

# ----------------------------------------------
# Variables y colores
# ----------------------------------------------
DOWNLOAD_DIR="$HOME/storage/shared/Download"
OS_TYPE=$(uname)
UPDATE_TIMESTAMP_FILE="$HOME/.yt_dlp_update_timestamp"
FORCE_UPDATE=false
PLAYLIST="--no-playlist"
YTDLP_PATH="$PREFIX/bin/yt-dlp"
SCRIPT_NAME="yt"
UPDATE_CHECK_INTERVAL=$((24 * 60 * 60)) # 1 día en segundos

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# ----------------------------------------------
# Funciones para mensajes
# ----------------------------------------------
print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# ----------------------------------------------
# Función para instalarse a sí mismo
# ----------------------------------------------
self_install() {
    # Verificar si el usuario es root
    if [ "$(id -u)" -eq 0 ]; then
        print_error "No es necesario ejecutar este script como root."
        exit 1
    fi

    OS_TYPE=$(uname)
    INSTALL_DIR=""

    if [ "$OS_TYPE" = "Linux" ]; then
        if [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
            # Termux
            INSTALL_DIR="$PREFIX/bin"
        else
            # Otras distribuciones de Linux
            INSTALL_DIR="$HOME/.local/bin"
        fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
        # macOS
        INSTALL_DIR="/usr/local/bin"
    else
        print_error "Sistema operativo no soportado."
        exit 1
    fi

    # Crear el directorio de instalación si no existe
    mkdir -p "$INSTALL_DIR"

    # Copiar este script al directorio de instalación
    cp "$0" "$INSTALL_DIR/$SCRIPT_NAME"

    # Asegurar permisos de ejecución
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

    # Añadir el directorio al PATH si no está ya incluido
    SHELL_RC="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi

    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
        source "$SHELL_RC"
    fi

    print_success "El script '$SCRIPT_NAME' ha sido instalado en $INSTALL_DIR y está listo para usarse."
    exit 0
}

# ----------------------------------------------
# Función para instalar yt-dlp y dependencias
# ----------------------------------------------
install_yt_dlp() {
    print_info "Instalando yt-dlp..."

    if [ "$OS_TYPE" = "Linux" ]; then
        if [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
            # Termux
            pkg update && pkg upgrade -y
            pkg install -y ffmpeg curl

            # Eliminar versión de yt-dlp instalada por pkg si existe
            pkg uninstall -y yt-dlp

            # Descargar binario de yt-dlp
            curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$PREFIX/bin/yt-dlp"
            chmod a+rx "$PREFIX/bin/yt-dlp"
        elif [ -x "$(command -v apt)" ]; then
            # Ubuntu/Debian
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y ffmpeg curl

            # Descargar binario de yt-dlp
            sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
            sudo chmod a+rx /usr/local/bin/yt-dlp
            YTDLP_PATH="/usr/local/bin/yt-dlp"
        else
            print_error "Gestor de paquetes no soportado en Linux."
            exit 1
        fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew no está instalado. Por favor, instala Homebrew desde https://brew.sh/."
            exit 1
        fi
        brew update
        brew install yt-dlp ffmpeg
        YTDLP_PATH="$(brew --prefix)/bin/yt-dlp"
    else
        print_error "Sistema operativo no soportado."
        exit 1
    fi

    # Verificar que yt-dlp se instaló correctamente
    if [ ! -x "$YTDLP_PATH" ]; then
        print_error "La instalación de yt-dlp falló."
        exit 1
    fi

    print_info "yt-dlp instalado correctamente."
}

# ----------------------------------------------
# Verificar si yt-dlp está instalado
# ----------------------------------------------
check_yt_dlp_installed() {
    if ! command -v yt-dlp &> /dev/null; then
        install_yt_dlp
    else
        YTDLP_PATH="$(command -v yt-dlp)"
        print_info "yt-dlp ya está instalado."
    fi
}

# ----------------------------------------------
# Función para configurar el almacenamiento en Termux
# ----------------------------------------------
setup_termux_storage() {
    if [ "$OS_TYPE" = "Linux" ] && [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
        if [ ! -d "$DOWNLOAD_DIR" ]; then
            print_info "Configurando el almacenamiento de Termux..."
            termux-setup-storage
            sleep 5
        fi
    fi
}

# ----------------------------------------------
# Función para verificar y actualizar herramientas automáticamente
# ----------------------------------------------
update_tools_if_needed() {
    local CURRENT_TIME=$(date +%s)
    local LAST_UPDATE=0

    if [ -f "$UPDATE_TIMESTAMP_FILE" ]; then
        LAST_UPDATE=$(cat "$UPDATE_TIMESTAMP_FILE")
    fi

    local TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

    if [ "$TIME_DIFF" -ge "$UPDATE_CHECK_INTERVAL" ] || [ "$FORCE_UPDATE" = true ]; then
        print_info "Comprobando actualizaciones para yt-dlp y ffmpeg..."
        update_tools
    else
        print_info "Las herramientas están actualizadas."
    fi
}

# ----------------------------------------------
# Función para actualizar herramientas
# ----------------------------------------------
update_tools() {
    if [ "$OS_TYPE" = "Linux" ]; then
        if [ -x "$(command -v pkg)" ] && [ "$(id -u)" != "0" ]; then
            pkg update && pkg upgrade -y
            pkg install -y ffmpeg

            # Eliminar versión de yt-dlp instalada por pkg si existe
            pkg uninstall -y yt-dlp

            # Actualizar yt-dlp
            curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$PREFIX/bin/yt-dlp"
            chmod a+rx "$PREFIX/bin/yt-dlp"
        elif [ -x "$(command -v apt)" ]; then
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y ffmpeg

            # Actualizar yt-dlp
            sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$YTDLP_PATH"
            sudo chmod a+rx "$YTDLP_PATH"
        fi
    elif [ "$OS_TYPE" = "Darwin" ]; then
        brew update
        brew upgrade yt-dlp ffmpeg
    fi

    local CURRENT_TIME=$(date +%s)
    echo "$CURRENT_TIME" > "$UPDATE_TIMESTAMP_FILE"
    print_info "Actualización completada."
}

# ----------------------------------------------
# Función para manejar el proceso de descarga
# ----------------------------------------------
download_file() {
    local VIDEO_URL="$1"
    local MODE="$2"

    print_info "Iniciando la descarga de $VIDEO_URL..."

    if [ "$MODE" = "audio" ]; then
        "$YTDLP_PATH" $PLAYLIST --progress -x --audio-format mp3 -o "$DOWNLOAD_DIR/%(playlist_index)s - %(title)s.%(ext)s" "$VIDEO_URL"
        DOWNLOAD_STATUS=$?
    elif [ "$MODE" = "video" ]; then
        "$YTDLP_PATH" $PLAYLIST --progress -o "$DOWNLOAD_DIR/%(playlist_index)s - %(title)s.%(ext)s" "$VIDEO_URL"
        DOWNLOAD_STATUS=$?
    else
        print_error "Modo no válido."
        exit 1
    fi

    if [ "$DOWNLOAD_STATUS" -ne 0 ]; then
        print_error "Error durante la descarga."
        exit 1
    fi

    print_success "Descarga completada exitosamente en $DOWNLOAD_DIR."
}

# ----------------------------------------------
# Función Principal del Script
# ----------------------------------------------
main() {
    # Si se ejecuta con '--install', instalarse a sí mismo
    if [ "$1" = "--install" ]; then
        self_install
    fi

    MODE="audio"  # Modo por defecto es 'audio'

    # Parsear opciones
    while getopts ":mvhd:puf" opt; do
        case $opt in
            m)
                MODE="audio"
                ;;
            v)
                MODE="video"
                ;;
            d)
                DOWNLOAD_DIR="$OPTARG"
                ;;
            p)
                PLAYLIST="--yes-playlist"
                ;;
            u|f)
                FORCE_UPDATE=true
                ;;
            h)
                echo "Uso: yt [--install] [-m|-v] [-d DIRECTORIO] [-p] [-u] URL_DEL_VIDEO"
                echo "  --install       Instalar el script en el sistema"
                echo "  -m              Descargar como audio (MP3) [por defecto]"
                echo "  -v              Descargar como video"
                echo "  -d DIRECTORIO   Especificar el directorio de descarga"
                echo "  -p              Descargar lista de reproducción completa"
                echo "  -u              Forzar actualización de herramientas"
                echo "  -h              Mostrar esta ayuda"
                exit 0
                ;;
            \?)
                print_error "Opción inválida: -$OPTARG"
                echo "Usa 'yt -h' para mostrar la ayuda."
                exit 1
                ;;
            :)
                print_error "La opción -$OPTARG requiere un argumento."
                exit 1
                ;;
        esac
    done

    shift $((OPTIND -1))

    # Capturar la URL completa
    VIDEO_URL="$*"

    # Validación de la URL
    if [ -z "$VIDEO_URL" ]; then
        print_error "No se proporcionó la URL del video."
        echo "Usa 'yt -h' para mostrar la ayuda."
        exit 1
    fi

    if ! [[ "$VIDEO_URL" =~ ^https?:// ]]; then
        print_error "La URL proporcionada no es válida."
        exit 1
    fi

    # Configurar almacenamiento si es necesario (solo para Termux)
    setup_termux_storage

    # Eliminar posibles versiones antiguas de yt-dlp en ~/.local/bin
    if [ -f "$HOME/.local/bin/yt-dlp" ]; then
        print_info "Eliminando versiones antiguas de yt-dlp en ~/.local/bin..."
        rm -f "$HOME/.local/bin/yt-dlp"
    fi

    # Verificar que yt-dlp esté instalado
    check_yt_dlp_installed

    # Verificar y actualizar herramientas si es necesario
    update_tools_if_needed

    # Crear directorio de descargas si no existe
    mkdir -p "$DOWNLOAD_DIR"

    # Descargar el archivo
    download_file "$VIDEO_URL" "$MODE"
}

# ----------------------------------------------
# Ejecutar la Función Principal con los Argumentos
# ----------------------------------------------
main "$@"
