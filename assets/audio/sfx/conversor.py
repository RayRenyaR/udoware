import os
import subprocess

def convertir_carpeta_a_wav(carpeta_origen, carpeta_destino=None):
    """
    Convierte todos los archivos de audio de una carpeta a formato .wav 
    usando FFmpeg directamente a través de la terminal.
    """
    if not carpeta_destino:
        carpeta_destino = carpeta_origen
    
    if not os.path.exists(carpeta_destino):
        os.makedirs(carpeta_destino)

    # Extensiones de audio comunes a buscar
    extensiones_validas = ('.mp3', '.ogg', '.flac', '.m4a', '.aac', '.wma', '.opus', '.wav')

    # Filtrar archivos (excluyendo los que ya son .wav si están en la misma carpeta para evitar bucles)
    archivos = [
        f for f in os.listdir(carpeta_origen) 
        if f.lower().endswith(extensiones_validas) and not f.lower().endswith('.wav')
    ]
    
    if not archivos:
        print("No se encontraron archivos de audio (diferentes de .wav) para convertir.")
        return

    print(f"Se encontraron {len(archivos)} archivos. Iniciando conversión...\n")

    for archivo in archivos:
        ruta_entrada = os.path.join(carpeta_origen, archivo)
        nombre_base, _ = os.path.splitext(archivo)
        ruta_salida = os.path.join(carpeta_destino, f"{nombre_base}.wav")

        # Comando nativo de FFmpeg para convertir a WAV estándar (PCM 16-bit)
        comando = [
            'ffmpeg', '-y', '-i', ruta_entrada, 
            '-ar', '44100', '-ac', '2', ruta_salida
        ]

        try:
            print(f"Procesando: {archivo} ...", end=" ")
            # Ejecuta ffmpeg ocultando la ventana de la consola para mayor limpieza
            resultado = subprocess.run(
                comando, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE, 
                text=True
            )
            
            if resultado.returncode == 0:
                print("OK")
            else:
                print("ERROR")
                print(f"Detalle: {resultado.stderr}")
        except Exception as e:
            print(f"ERROR CRÍTICO: {e}")
            
    print("\n¡Conversión por lotes completada!")

if __name__ == "__main__":
    # Configurado para leer y guardar en la misma carpeta actual
    directorio_origen = "./" 
    directorio_destino = "./"
    
    convertir_carpeta_a_wav(directorio_origen, directorio_destino)