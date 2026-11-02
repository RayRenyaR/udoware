## HOLA

La arquitectura para **UDOWare** en Godot 4 utiliza un **enfoque híbrido modular**: separa el motor central y los recursos reutilizables en carpetas globales, mientras encapsula cada uno de los 15 microjuegos en su propia subcarpeta para evitar mezclar decenas de scripts y escenas sueltas.

---

## 1. Organización de Carpetas (`res://`)

Crea exactamente este árbol de directorios en la pestaña *FileSystem* de Godot:

```text
res://
├── assets/                          # Recursos globales y reutilizables en todo el juego
│   ├── audio/
│   │   ├── bgm/                     # Música de menú, canciones de intermedio, temas de historia y arcade
│   │   ├── jingles/                 # Fanfarrias cortas de 2 seg: Victoria, Derrota, Speed Up, Boss, Game Over
│   │   └── sfx/                     # Efectos comunes: clic, explosión, mecha de bomba, golpe, botones UI
│   ├── fonts/                       # Fuentes tipográficas (.ttf / .otf) para textos de impacto ("¡PISA!")
│   ├── shaders/                     # Shaders globales (CRT, transiciones, distorsión bizarra, bordes)
│   └── sprites/
│       ├── ui/                      # Corazones (4 vidas), barra/mecha de tiempo, marcos, cursores de ratón
│       ├── transitions/             # Puertas/telones del intermedio, fondos animados entre rondas
│       ├── characters/              # Sprites de los protagonistas de las 3 historias para cinemáticas
│       └── shared_props/            # Objetos que se repiten en varios microjuegos (manos, partículas, explosiones)
│
├── core/                            # El "Motor" interno de UDOWare (Lógica pura y plantillas)
│   ├── autoloads/                   # Singletons globales configurados en Project Settings
│   │   ├── global_state.gd          # Guarda modo actual, vidas, puntos, velocidad y cola de juegos
│   │   ├── audio_manager.gd         # Controlador global para reproducir BGM/SFX cambiando el pitch según velocidad
│   │   └── network_bridge.gd        # Lógica de comunicación con Spring Boot y el iframe de React
│   ├── resources/                   # Definiciones de clases Resource personalizadas
│   │   └── microgame_data.gd        # Molde de metadatos de cada microjuego (título, instrucción, mecánica, escena)
│   ├── runner/                      # El controlador que ejecuta las partidas
│   │   ├── microgame_runner.tscn    # Escena contenedora donde ocurren los microjuegos y el intermedio
│   │   └── microgame_runner.gd      # Máquina de estados del bucle de partida
│   └── template/                    # El molde padre del que heredarán los 15 microjuegos
│       ├── microgame_base.tscn      # Escena base con temporizador y estructura estándar
│       └── microgame_base.gd        # Clase base con funciones win(), lose() y señales hacia el Runner
│
├── ui/                              # Pantallas fuera de los microjuegos
│   ├── main_menu/                   # Pantalla de título y elección entre Modo Historia y Modo Arcade
│   ├── story_select/                # Selector de las 3 historias (Cliqueo, Movimiento de Mouse, Teclado)
│   ├── cutscenes/                   # Reproductor de cinemáticas (Intro de historia y Final tras el jefe)
│   └── game_over/                   # Pantalla de puntuación final y envío de datos HTTP
│
└── microgames/                      # Los 15 microjuegos organizados por sus 3 mecánicas principales
	├── registry_all_games.tres      # Lista maestra (Resource) que referencia los 15 microjuegos
	├── 01_click/                    # Historia 1: Mecánica de Cliqueo (5 microjuegos)
	│   ├── mg_01_moscas/            # Contiene su .tscn, su .gd, su .tres y sprites exclusivos de este juego
	│   ├── mg_02_portaminas/
	│   ├── mg_03_.../
	│   ├── mg_04_.../
	│   └── mg_05_boss_click/
	├── 02_mouse_move/               # Historia 2: Mecánica de Movimiento de Ratón (5 microjuegos)
	│   ├── mg_06_ventana/
	│   ├── mg_07_pizarra/
	│   ├── mg_08_maraca/
	│   ├── mg_09_.../
	│   └── mg_10_boss_move/
	└── 03_keyboard/                 # Historia 3: Mecánica de Teclado (5 microjuegos)
		├── mg_11_tecla_exacta/
		├── mg_12_secuencia/
		├── mg_13_timing/
		├── mg_14_.../
		└── mg_15_boss_keyboard/

```

---

## 2. Hoja de Ruta Cronológica para Construir el Motor (Paso a Paso)

Sigue este orden estricto. No pases a la siguiente fase hasta haber verificado que la anterior funciona.

---

### FASE 1: Configuración del Proyecto y Cerebro Global (Autoloads)

El objetivo de esta fase es preparar las reglas del proyecto y la memoria persistente que no se destruye al cambiar de escena.

#### Paso 1.1: Ajustes en `Project Settings`

* [x] **Resolución base:** En `Display -> Window`, configura el tamaño en `800 x 600` (o `1280 x 720` en proporción 16:9 si prefieren panorámico, asegurándose de que coincida con el tamaño del `<iframe />` de su `GameView.tsx` en React).
* [x] **Modo de escalado (Stretch):** Configura `Mode` en `canvas_items` y `Aspect` en `keep` para que el juego se adapte sin deformar los píxeles ni la interfaz.
* [x] **Mapa de Entradas (`Input Map`):** Aunque muchos juegos usan ratón o teclas específicas, registra acciones base: `action_click` (Botón Izquierdo del Ratón), `action_space` (Barra Espaciadora), y las direcciones `ui_up`, `ui_down`, `ui_left`, `ui_right` (WASD y Flechas).

#### Paso 1.2: Ficha Técnica de Microjuego (`core/resources/microgame_data.gd`)

* [x] Crea un script que herede de `Resource` con el nombre de clase `MicrogameData`.
* [x] **Propósito:** Servir como "carta de presentación" para cada uno de los 15 microjuegos sin tener que cargar la escena pesada en memoria antes de tiempo.
* [x] **Variables exportadas (`@export`) que debe tener:**
* `id` (String): Identificador único (ej. `"mg_01_moscas"`).
* `title` (String): Nombre interno del juego.
* `command_text` (String): La palabra de orden que saldrá en gigante antes de empezar (ej. `"¡APLASTA!"`, `"¡AGITA!"`, `"¡TECLEA!"`).


* `mechanic_type` (Enum): `CLICK`, `MOUSE_MOVE`, o `KEYBOARD`.
* `is_boss` (bool): Define si es el 5to juego (jefe) de una historia (sin límite de tiempo corto o con tiempo extendido).
* `base_duration` (float): Duración en segundos a velocidad normal (por defecto `4.0` segundos).
* `scene` (`PackedScene`): Referencia al archivo `.tscn` del microjuego.



#### Paso 1.3: Estado Global (`core/autoloads/global_state.gd`)

* [x] Crea este script heredando de `Node` y regístralo en `Project Settings -> Globals (Autoload)` como `GlobalState`.
* [x] **Variables de estado que debe controlar:**
* `current_mode`: Enum con `STORY` o `ARCADE`.
* `selected_story`: Enum con `STORY_CLICK`, `STORY_MOUSE`, `STORY_KEYBOARD`.
* `lives` (int): Inicia siempre en `4` al comenzar una partida.


* `score` (int): Inicia en `0` y suma `+1` por cada microjuego superado.


* `speed_scale` (float): Inicia en `1.0` y sube progresivamente (ej. `1.15`, `1.3`, `1.5`) cada cierta cantidad de rondas para el efecto de *Speed Up*.


* `microgame_pool` (Array de `MicrogameData`): Lista con los 15 recursos `.tres` registrados.


* [x] **Funciones que debe tener:**
* Una función para reiniciar los valores al empezar partida (`reset_run()`).
* Una función que filtre y devuelva los 5 microjuegos de la historia elegida (en Modo Historia) o baraje los 15 microjuegos de forma infinita sin repetir el inmediatamente anterior (en Modo Arcade).



#### Paso 1.4: Gestor de Audio (`core/autoloads/audio_manager.gd`)

* [x] Crea un script registrado como Autoload llamado `AudioManager`.
* [x] **Qué debe hacer:** Instanciar por código un nodo `AudioStreamPlayer` para la música (`BGM`) y un grupo de 4 nodos `AudioStreamPlayer` para efectos (`SFX`).
* [x] **Detalle clave de WarioWare:** Añade una función que actualice la propiedad `pitch_scale` de los reproductores de audio igualándola al `GlobalState.speed_scale` (o una fracción, como `1.0 + (speed_scale - 1.0) * 0.5`). Así, cuando ocurra un *Speed Up*, toda la música y los efectos sonarán más agudos y frenéticos automáticamente.

---

### FASE 2: La Plantilla Madre de Microjuegos (`MicrogameBase`)

Antes de programar el contenedor de partidas, necesitas el "molde" del que nacerán los 15 microjuegos. Esto garantiza que todos funcionen bajo las mismas reglas.

#### Paso 2.1: Estructura de `core/template/microgame_base.tscn`

* [x] Crea una escena cuyo nodo raíz sea un `Node2D` llamado `MicrogameBase` y asígnale el script `microgame_base.gd`.
* [x] **Nodos hijos que debe incluir:**
1. `Background` (`ColorRect` o `Sprite2D`): Fondo por defecto del tamaño de la pantalla para que ningún microjuego se vea transparente.
2. `GameplayArea` (`Node2D`): Nodo vacío donde colocarás los sprites, colisiones y objetos propios de cada uno de los 15 microjuegos.
3. `Camera2D`: Centrada en la pantalla por si algún microjuego necesita agitar la pantalla (*screen shake*).



#### Paso 2.2: Lógica de `core/template/microgame_base.gd`

* [x] **Señales que debe emitir hacia arriba:**
* `signal microgame_finished(won: bool)`: Avisa inmediatamente si el jugador ya cumplió o falló la tarea.


* [x] **Variables internas:**
* `has_won` (bool): Define el estado actual del microjuego.
* `win_on_timeout` (bool, `@export`): ¡Muy importante! Hay dos tipos de microjuegos:
* **Juegos de Acción (Por defecto `false`):** Empiezas perdiendo y debes lograr el objetivo antes de que acabe el tiempo (ej. aplastar las moscas). Si se acaba el tiempo y no lo lograste, pierdes vida.
* **Juegos de Supervivencia (`true`):** Empiezas ganando y solo debes sobrevivir sin fallar hasta que se acabe el tiempo.




* [x] **Funciones estándar del molde:**
* `win()`: Marca `has_won = true`, reproduce una animación/sonido de victoria local y emite la señal.
* `lose()`: Marca `has_won = false`, reproduce el fallo visual y emite la señal.
* `on_time_up()`: Función que el controlador principal llamará cuando el reloj llegue a cero si el juego aún no se ha decidido.



#### Paso 2.3: Crear 2 Microjuegos de Prueba ("Dummies")

* [x] Antes de diseñar arte bizarro, crea dos escenas de prueba heredando de `MicrogameBase.tscn`:
1. `dummy_win.tscn`: Con un simple botón `Button` en medio que al darle clic llame a `win()`.
2. `dummy_lose.tscn`: Donde si no haces nada en 4 segundos, pierdes.


* [x] Crea sus dos archivos `.tres` (`MicrogameData`) para probar la Fase 3 sin distracciones.

---

### FASE 3: El Motor Controlador de Partida (`MicrogameRunner`)

Esta es la pieza más importante de toda tu arquitectura. Es la escena donde transcurre la acción, controla las 4 vidas, muestra la orden en pantalla, mide los 4 segundos y destruye el microjuego al terminar para cuidar la memoria RAM del navegador.

#### Paso 3.1: Jerarquía de Nodos en `core/runner/microgame_runner.tscn`

Construye esta estructura exacta de nodos:

```text
MicrogameRunner (Node2D o Control - con script microgame_runner.gd)
├── MicrogameViewport (Node2D)               # Carpeta vacía donde se instanciará el microjuego actual
├── IntermissionLayer (CanvasLayer - Layer 5)# Capa del telón/descanso entre microjuegos
│   ├── DoorsBackground (ColorRect/TextureRect) # El telón que tapa el microjuego mientras carga el siguiente
│   ├── LivesContainer (HBoxContainer)       # Contiene 4 TextureRect (los 4 corazones/vidas del jugador)
│   ├── ScoreCounter (Label)                 # Muestra la ronda/puntuación actual en grande ("005")
│   └── StatusBanner (Label)                 # Muestra textos del sistema: "¡MÁS RÁPIDO!", "¡JEFE!", "¡BIEN!", "¡MAL!"
├── HUDLayer (CanvasLayer - Layer 10)        # Capa que se ve ENCIMA del microjuego mientras juegas
│   ├── CommandLabel (Label)                 # Texto gigante en el centro: "¡CLIQUEA!", "¡MUEVE!" (con AnimationPlayer)
│   ├── ControlIcon (TextureRect)            # Ícono visual que indica si se usa Ratón o Teclado
│   └── BombTimerBar (TextureProgressBar)    # Barra o mecha de bomba en la parte inferior que baja de 100 a 0
├── RoundTimer (Timer)                       # Reloj maestro que dura los 4 segundos del microjuego (One Shot = true)
└── StateTimer (Timer)                       # Reloj corto para los tiempos de pausa entre estados (intermedios de 1.5s)

```

#### Paso 3.2: La Máquina de Estados en `microgame_runner.gd`

Programa un `enum State` con estos **6 estados secuenciales** que forman el bucle infinito:

1. **Estado 1: `INTERMISSION` (Sala de espera - Duración: ~1.5 segundos base):**
* El `IntermissionLayer` (telón) está cerrado tapando la pantalla.
* Se muestran las **4 vidas** actuales y el puntaje.


* El script extrae el siguiente `MicrogameData` de la cola de `GlobalState`.
* Reproduce el ritmo musical de espera.


2. **Estado 2: `PRE_GAME_PROMPT` (Aviso de orden - Duración: ~1.0 segundo base):**
* En el fondo (`MicrogameViewport`), se instancia (`instantiate()`) la escena `.tscn` del microjuego elegido, pero se mantiene pausada o sin recibir controles todavía.
* Aparece en pantalla gigante el `CommandLabel` con el `command_text` del recurso (ej. `"¡LIMPIA!"`) y el ícono del control (ratón o teclado).




3. **Estado 3: `PLAYING` (Ejecución del microjuego - Duración: `base_duration` ~4.0 segundos):**
* Se abre el telón (`IntermissionLayer` se oculta o hace animación de apertura).
* Desaparece el texto gigante de orden y se activa el `BombTimerBar`.
* Se inicia el `RoundTimer`. En cada frame (`_process`), `BombTimerBar.value` se actualiza con el `time_left` del `RoundTimer`.
* El jugador interactúa con el microjuego. Si el jugador logra el objetivo antes de que acabe el tiempo, el microjuego activa su bandera de victoria; si el reloj llega a `0`, se llama a `on_time_up()` del microjuego.


4. **Estado 4: `EVALUATION` (Veredicto - Duración: ~1.0 segundo base):**
* Se cierra el telón (`IntermissionLayer` vuelve a aparecer).
* **Limpieza de Memoria:** Se llama inmediatamente a `queue_free()` sobre el nodo hijo dentro de `MicrogameViewport`. Así garantizas que en WebAssembly nunca haya más de 1 microjuego consumiendo memoria.
* **Si ganó (`has_won == true`):** `GlobalState.score += 1`, suena el jingle de victoria, los corazones bailan y el `StatusBanner` dice `"¡SUPERADO!"`.
* **Si perdió (`has_won == false`):** `GlobalState.lives -= 1`, suena el jingle de derrota, se apaga/rompe uno de los 4 `TextureRect` en `LivesContainer` y el `StatusBanner` dice `"¡FALLASTE!"`.




5. **Estado 5: `CHECK_PROGRESSION` (Control de Flujo, Velocidad y Vidas):**
* **Revisión de Derrota:** ¿`GlobalState.lives <= 0`? Si es así, salta de inmediato al Estado 6 (`GAME_OVER`).


* **Revisión de Modo Historia:** ¿Estamos en Modo Historia y el jugador acaba de vencer al 5to microjuego (el Jefe)? Si es así, detiene el bucle y carga la escena de **Cinemática Final** de esa historia.
* **Revisión de *Speed Up*:** Si sigue vivo (por ejemplo, cada 5 microjuegos en Modo Arcade o antes del jefe en Modo Historia), incrementa `GlobalState.speed_scale += 0.15`, aplica `Engine.time_scale = GlobalState.speed_scale`, muestra en pantalla `"¡SPEED UP! / ¡MÁS RÁPIDO!"` durante 1 segundo y regresa al **Estado 1 (`INTERMISSION`)**.




6. **Estado 6: `GAME_OVER`:**
* Restaura `Engine.time_scale = 1.0` (vital para que los menús no vayan acelerados), reproduce el sonido de derrota definitiva y cambia de escena hacia `ui/game_over/game_over.tscn`.





---

### FASE 4: Menús, Modo Historia (Cinemáticas) y Modo Arcade

Una vez que tu `MicrogameRunner` sea capaz de ciclar tus 2 microjuegos *Dummy*, restar las 4 vidas y acelerar el tiempo, construye el envoltorio de modos de juego.

#### Paso 4.1: Menú Principal (`ui/main_menu/main_menu.tscn`)

* [x] **Nodo raíz:** `Control` con diseño de pantalla completa.
* [x] **Nodos hijos:**
* `Background` (`TextureRect` o fondo animado con estética bizarra).
* `TitleLogo` (`TextureRect` o `Label` con el logo de **UDOWare**).
* `ButtonsVBox` (`VBoxContainer`):
* `BtnStoryMode` (`Button`): Lleva a `story_select.tscn`.
* `BtnArcadeMode` (`Button`): Configura `GlobalState.current_mode = ARCADE`, llama a `GlobalState.reset_run()`, carga los 15 microjuegos en modo aleatorio infinito y abre directamente `microgame_runner.tscn`.





#### Paso 4.2: Selector de Historia (`ui/story_select/story_select.tscn`)

* [x] **Nodo raíz:** `Control`.
* [x] **Nodos hijos:** Un `HBoxContainer` con **3 Tarjetas/Botones grandes**, cada una representando una historia y su mecánica tutorial:
1. **Historia 1 (Mecánica de Cliqueo):** Muestra el personaje de la primera historia + etiqueta `"Controles: Solo Clic"`.
2. **Historia 2 (Mecánica de Movimiento de Ratón):** Muestra el segundo personaje + etiqueta `"Controles: Mover Cursor"`.
3. **Historia 3 (Mecánica de Teclado):** Muestra el tercer personaje + etiqueta `"Controles: Teclado"`.


* [x] **Comportamiento:** Al elegir cualquiera de las 3, guarda `GlobalState.selected_story`, configura `GlobalState.current_mode = STORY` y abre `cutscene_player.tscn` en modo `INTRO`.

#### Paso 4.3: Reproductor de Cinemáticas (`ui/cutscenes/cutscene_player.tscn`)

* [x] Para no programar 6 escenas de cinemáticas distintas (3 intros + 3 finales), haz **un único reproductor basado en diapositivas o viñetas cómicas** (estilo cómic absurdo con efectos de sonido):
* [x] **Nodos de la escena:**
* `SlideImage` (`TextureRect`): Muestra el dibujo bizarro de la escena actual de la historia.
* `DialogueBox` (`PanelContainer` + `RichTextLabel`): Muestra el texto gracioso de lo que le pasa al personaje.
* `NextButton` (`Button`): Para avanzar de viñeta o saltar la cinemática (`"Saltar >>"`).
* `AnimationPlayer`: Para dar rebotes (*squash and stretch*) o sacudidas a la imagen cuando pasa algo absurdo.


* [x] **Flujo:**
* Si estaba reproduciendo la **Intro**, al terminar la última viñeta carga `microgame_runner.tscn` con los 5 microjuegos de esa mecánica.
* Si estaba reproduciendo el **Outro** (después de pasar el 5to microjuego/Jefe), al terminar felicita al jugador y lo devuelve a `story_select.tscn` marcando esa historia como completada.



---

### FASE 5: Pantalla de Game Over y Puente HTTP con Spring Boot

Cuando el jugador pierde sus 4 vidas (o decide salir tras registrar récord), entra en acción la conexión con la Plataforma Web Principal.

#### Paso 5.1: Escena `ui/game_over/game_over.tscn`

* [ ] **Nodo raíz:** `Control`.
* [ ] **Nodos hijos:**
* `GameOverTitle` (`Label`): `"¡GAME OVER!"`.
* `FinalScoreLabel` (`Label`): Lee `GlobalState.score` y muestra `"Rondas superadas: X"`.
* `ServerStatusLabel` (`Label`): Muestra el estado del envío a la base de datos (`"Enviando puntuación al servidor..."` -> `"¡Puntuación guardada en el Ranking!"` o `"Modo local: sin conexión al servidor"`).
* `RetryButton` (`Button`): Reinicia `GlobalState.reset_run()` y recarga `microgame_runner.tscn`.
* `MenuButton` (`Button`): Regresa a `main_menu.tscn`.
* `ScoreHTTPRequest` (`HTTPRequest`): El nodo nativo de Godot encargado de comunicarse con el backend en Java Spring Boot.





#### Paso 5.2: Lógica de Envío en `game_over.gd` (y `network_bridge.gd`)

* [ ] En la función `_ready()` de la pantalla de Game Over, si `GlobalState.score > 0`, arma un diccionario JSON con el puntaje obtenido, el modo jugado y el identificador del juego.


* [ ] Ejecuta la petición `ScoreHTTPRequest.request("http://localhost:8080/api/scores", headers, HTTPClient.Method.POST, json_body)`.


* [ ] **Bonus para el `<iframe />` de React:** Usando la interfaz `JavaScriptBridge.eval()` de Godot 4 (solo cuando `OS.has_feature("web")` sea verdadero), puedes emitir un `window.parent.postMessage({ type: 'GAME_OVER', score: ... }, '*')` para que el componente `GameView.tsx` que hiciste con Gabriel actualice el marcador de la página web en tiempo real sin recargar la página.

---

### FASE 6: Producción en Serie de los 15 Microjuegos

Con las Fases 1 a 5 listas, ya tienes el motor completo funcionando de principio a fin. A partir de aquí, fabricar los 15 microjuegos del MVP es un proceso mecánico y repetitivo que no toca el motor principal:

1. En el menú superior de Godot, haz clic en **`Scene -> New Inherited Scene...`** (Nueva Escena Heredada) y selecciona `res://core/template/microgame_base.tscn`.
2. Guarda la nueva escena en su carpeta correspondiente (ej. `res://microgames/01_click/mg_01_moscas/mg_01_moscas.tscn`).
3. Haz clic derecho sobre el nodo raíz de esa nueva escena y selecciona **`Extend Script...`** (Extender Script) para crear `mg_01_moscas.gd` (que automáticamente tendrá `extends MicrogameBase`).
4. Coloca los sprites, áreas de clic (`Area2D` + `CollisionShape2D`) o detectores dentro del nodo `GameplayArea`.
5. Programa la condición única del juego en menos de 30 líneas: cuando el jugador cumpla el objetivo (ej. contador de moscas aplastadas llega a 3), llama a `win()`.
6. Haz clic derecho en la carpeta del microjuego -> **`New Resource...` -> `MicrogameData**`, rellena el comando (`"¡APLASTA!"`), arrastra la escena `.tscn` adentro, y agrega ese archivo `.tres` a tu lista en `GlobalState`.
