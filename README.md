# scrip_dowloadMusic

#Damos permisos
chmod +x yt

#instalamos
./yt.sh --install
#Reiniciamos bashrc
source ~/.bashrc
#Reiniciamos zsh
source ~/.zshrc
# Ubicacion del archivo
which yt


Uso del script yt
Ahora puedes usar el comando yt desde cualquier lugar en tu terminal.

Ejemplos:

Descargar audio (modo por defecto):

bash

yt https://www.youtube.com/watch?v=koEPnlHxUiU
Descargar video:

bash

yt -v https://www.youtube.com/watch?v=koEPnlHxUiU
Descargar una lista de reproducción completa como audio:

bash

yt -p "https://www.youtube.com/watch?v=RW7Hn24Agyc&list=PLhopS0O2QVwxTkCbR9qbCQ-CpnjtIQ1cR"
Nota: Es recomendable poner la URL entre comillas si contiene caracteres especiales como &.
Especificar un directorio de descarga personalizado:

bash

yt -d /ruta/a/descargas https://www.youtube.com/watch?v=koEPnlHxUiU


Mostrar la ayuda:

bash

yt -h


Mostrar la ayuda:

bash

yt -h

Descargar una lista de reproducción completa de videos
Para descargar una lista de reproducción completa de videos, utiliza el siguiente comando:

bash

yt -v -p "URL_DE_LA_LISTA_DE_REPRODUCCIÓN"
Ejemplo con tu URL:

bash

yt -v -p "https://www.youtube.com/watch?v=RW7Hn24Agyc&list=PLhopS0O2QVwxTkCbR9qbCQ-CpnjtIQ1cR"
Explicación de las opciones:
-v: Indica que deseas descargar el video en lugar del audio (que es el modo por defecto).
-p: Indica que deseas descargar una lista de reproducción completa.
"URL_DE_LA_LISTA_DE_REPRODUCCIÓN": La URL de la lista de reproducción que deseas descargar. Es recomendable ponerla entre comillas si contiene caracteres especiales como &.
Pasos a seguir:
Ejecuta el comando en tu terminal:

bash

yt -v -p "https://www.youtube.com/watch?v=RW7Hn24Agyc&list=PLhopS0O2QVwxTkCbR9qbCQ-CpnjtIQ1cR"
El script realizará las siguientes acciones:

Verificará e instalará yt-dlp y ffmpeg si es necesario.
Comprobará si hay actualizaciones disponibles para las herramientas y las aplicará si es necesario.
Iniciará la descarga de todos los videos de la lista de reproducción especificada.
Guardará los videos en el directorio de descargas predeterminado ($HOME/storage/shared/Download en Termux), con nombres que incluyen el índice de la lista y el título del video.
Visualización del progreso:

Verás barras de progreso durante la descarga de cada video, lo que te permitirá monitorear el avance de las descargas.
Notas adicionales:
Nombres de los archivos:

Los videos se guardarán con nombres que incluyen el índice de la lista de reproducción y el título del video, gracias al patrón de salida especificado en el script:
bash

-o "$DOWNLOAD_DIR/%(playlist_index)s - %(title)s.%(ext)s"
Comillas en la URL:

Es recomendable poner la URL entre comillas si contiene caracteres especiales como & para evitar problemas con el shell.
Verificación de actualizaciones:

El script comprobará automáticamente si es necesario actualizar yt-dlp y ffmpeg antes de proceder con las descargas.
Directorios de descarga personalizados:

Si deseas especificar un directorio de descarga diferente, puedes utilizar la opción -d:
bash

yt -v -p -d /ruta/a/descargas "URL_DE_LA_LISTA_DE_REPRODUCCIÓN"
Ejemplo completo:
bash

yt -v -p "https://www.youtube.com/watch?v=RW7Hn24Agyc&list=PLhopS0O2QVwxTkCbR9qbCQ-CpnjtIQ1cR"
Al ejecutar este comando, el script:

Descargará todos los videos de la lista de reproducción especificada.
Guardará los archivos de video en el directorio predeterminado, con nombres como 1 - Título del Video.mp4, 2 - Título del Video.mp4, etc.
Mostrará barras de progreso durante las descargas.