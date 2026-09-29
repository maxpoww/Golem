# La lista de ACCIONES — las 46, de ambos lotes

Compilado de los registros cerrados `work/batch-01/actions-40.md` y
`work/batch-02/actions-40.md`. Formato por acción: **la frase que Golem dice** ·
la pastilla-verbo que ofrece · el disparador (cuándo se activa) · estado actual.

El estado es el libro honesto del lote: **[live]** = puede hablar en el motor de
hoy; **[cheap]** / **[new]** = espera trabajo nombrado; **dormant** = bloqueado
por una ausencia del motor. El lote 01 entrega 34 (10 activas); el lote 02
entrega 12 (2 activas).

---

## LOTE 01 — 34 acciones

### A01 — el sonido rebelde
- **frase:** "El sonido viene de tu navegador, ¿quieres que lo silencie?"
- **verbo:** [siléncialo] / [muéstramelo]
- **disparador:** empieza la reproducción del navegador mientras su ventana lleva ≥10 s sin foco
- **estado:** [live]

### A02 — la respuesta que tecleas siempre
- **frase:** "Has copiado este mismo texto en tres días distintos, ¿quieres guardarlo como fragmento?"
- **verbo:** [guárdalo como fragmento]
- **disparador:** el mismo contenido del portapapeles (hash) en ≥3 días distintos
- **estado:** [cheap] en espera — la marca de anclado sobre el almacén de portapapeles existente

### A03 — el público
- **frase:** "Están compartiendo toda tu pantalla, ¿quieres que guarde el resto de ventanas hasta que termine?"
- **verbo:** [guarda el resto]
- **disparador:** empieza una captura de pantalla completa
- **estado:** **dormant** — el tipo de compartición no lo expone aún el portal

### A04 — callar el escritorio
- **frase:** "Tu micrófono acaba de activarse, ¿quieres que calle el escritorio?"
- **verbo:** [callar mi escritorio]
- **disparador:** micrófono activo pasada una base de 5 s (una llamada)
- **estado:** [live]

### A05 — la devolución
- **frase:** "Tu llamada ha terminado, ¿quieres ver lo que retuve?"
- **verbo:** [muéstramelo]
- **disparador:** el micrófono se desactiva después de que Golem retuviera la cola de notificaciones
- **estado:** [live] (después de la forma permanente de A04; si no, silenciosa)

### A07 — pausa cuando me aparto
- **frase:** "Pausas antes de apartarte del escritorio, ¿quieres que yo haga esa parte?"
- **verbo:** [pausa al apartarme]
- **disparador:** pausa manual + sesión que pasa a inactiva, ≥3× en días distintos
- **estado:** [cheap] en espera — fuente de inactividad vía idle-notify del compositor

### A09 — modo juego
- **frase:** "Un juego acaba de ocupar la pantalla, ¿quieres modo juego?"
- **verbo:** [modo juego]
- **disparador:** una ventana de clase juego pasa a pantalla completa
- **estado:** [live]

### A10 — mantenerlo en primer plano
- **frase:** "Tú mismo pones el reproductor en la esquina al volver al trabajo, ¿quieres que vaya solo?"
- **verbo:** [mantenlo arriba]
- **disparador:** un reproductor autónomo flotado en pequeño mientras el foco se va a otro lado, ≥3× en días distintos
- **estado:** [live]

### A11 — el tope susurrado
- **frase:** "Mantienes el volumen bajo a esta hora, ¿quieres que empiece bajo tras medianoche?"
- **verbo:** [empezar bajo tras medianoche]
- **disparador:** reproducción que empieza baja después de una hora tardía recurrente, en ≥3 noches
- **estado:** [live]

### A13 — el nombre corto
- **frase:** "Es el tercer día que tecleas este comando entero, ¿quieres un nombre corto?"
- **verbo:** [conviértelo en `gsu`] (propuesto en vivo desde las palabras del comando)
- **disparador:** el mismo comando largo (≥24 caracteres, salida 0) en ≥3 días distintos
- **estado:** [live] el disparador; [cheap] el verbo — el archivo de alias y una línea de source en `zsh.nix` aún no existen

### A14 — el reflejo
- **frase:** "Escribes `ls` después de casi todos los `cd`, ¿quieres que lo haga el shell?"
- **verbo:** [hazlo por mí]
- **disparador:** la pareja cd → ls adyacente ≥20× en ≥3 días cubriendo ≥60% de todos los cd
- **estado:** [cheap] el verbo — mismo archivo de hooks del shell que falta en A13

### A15 — llegar en texto plano
- **frase:** "Quitas el formato de casi todo lo que pegas, ¿quieres que llegue en plano?"
- **verbo:** [copia del navegador en plano]
- **disparador:** texto enriquecido copiado y reofrecido segundos después solo en plano, ≥3× (el ciclo de lavado)
- **estado:** [live]

### A16 — la actualización que espera
- **frase:** "Esta actualización lleva un rato esperando, ¿quieres aplicarla la próxima vez que reinicies?"
- **verbo:** [aplícala al próximo reinicio]
- **disparador:** una generación nix pendiente observada en ≥3 días distintos
- **estado:** [cheap] el verbo — la unidad de aplicación (`nixos-rebuild boot` vía archivo de intención) aún no existe

### A17 — la hora que siempre blindas
- **frase:** "Silencias las notificaciones a esta hora casi todos los días, ¿quieres que pase solo?"
- **verbo:** [cada día a esta hora]
- **disparador:** no molestar activado a mano a una hora recurrente, ≥3 días
- **estado:** [live]

### A18 — el diseño que sigue a la app
- **frase:** "Cambias la distribución del teclado cada vez que llegas a esta ventana, ¿quieres que siga a la app?"
- **verbo:** [recuerda la distribución por app]
- **disparador:** la distribución cambia a los segundos de llegar el foco a una clase, en ≥3 días
- **estado:** [cheap] en espera — el cableado del evento `activelayout`

### A19 — la captura recién hecha
- **frase:** "Dibujas sobre casi todas tus capturas, ¿quieres que se abran en el anotador?"
- **verbo:** [ábrelas en el anotador]
- **disparador:** una clase de anotador con foco a los ~60 s de una captura nueva, ≥3 días
- **estado:** [cheap] en espera — necesita un anotador/vigilancia de carpeta; solo existe donde el usuario instaló un anotador

### A20 — colores reales
- **frase:** "La protección ocular está activa y has abierto una foto, ¿quieres colores reales por un minuto?"
- **verbo:** [colores reales por un minuto]
- **disparador:** el usuario ha apagado a mano la protección ocular frente a una foto ≥3×; el momento = pantalla cálida + clase de imagen con foco
- **estado:** [live]

### A21 — el primer acierto fallido
- **frase:** "El lanzador sigue poniendo \<app\> primero y tú la cierras, ¿quieres que baje?"
- **verbo:** [deja de ponerla primero]
- **disparador:** el lanzador abre la app X para la consulta Q y la ventana se cierra en ~15 s, ≥3× para la pareja
- **estado:** [cheap] en espera — el almacén hermano (consulta, app) → penalización junto a `usage.json`

### A24 — parar en 80
- **frase:** "Esta máquina vive enchufada, ¿quieres que deje de cargar al 80%?"
- **verbo:** [parar en 80%]
- **disparador:** máquina en corriente casi toda la sesión, ≥3 sesiones, y la batería expone el límite de carga
- **estado:** [cheap] en espera — la unidad de aplicación con root; solo existe en hardware con el nodo sysfs

### A25 — estíralo
- **frase:** "Empiezas a ahorrar batería sobre estos niveles, ¿quieres que ocurra solo de ahora en adelante?"
- **verbo:** [hazlo a \<N\>% desde ahora]
- **disparador:** cambio manual a ahorro de energía a un nivel de batería recurrente, ≥3 ocurrencias
- **estado:** [live]

### A26 — la muñeca
- **frase:** "Mantienes la pantalla despierta a mano mientras lees, ¿quieres que se quede despierta aquí?"
- **verbo:** [mantenla despierta aquí]
- **disparador:** retorno de inactividad sin nada que lo siga, ≥3×
- **estado:** **dormant** — Golem no entrega ningún gestor de inactividad sobre el que actuar

### A27 — seguir a mis auriculares
- **frase:** "Pasas el sonido a mano cada vez que llegan estos auriculares, ¿quieres que lo tomen solos?"
- **verbo:** [sigue a mis auriculares]
- **disparador:** el destino por defecto movido a mano a un dispositivo recién llegado, mismo dispositivo ≥3×
- **estado:** [live]

### A28 — el buen sonido
- **frase:** "Tus auriculares bajan a sonido de llamada al usar el micrófono, ¿quieres conservar el buen sonido y usar el micrófono del portátil?"
- **verbo:** [conserva el buen sonido]
- **disparador:** el auricular BT (destino actual) cambia al perfil de llamada al empezar la captura
- **estado:** [cheap] en espera — un campo más leído del pw-dump ya analizado

### A29 — recuerda este escritorio
- **frase:** "Has vuelto a organizar estos monitores igual, ¿quieres que recuerde este escritorio?"
- **verbo:** [recuerda este escritorio]
- **disparador:** se añade un monitor y la misma reorganización manual en segundos, ≥3×
- **estado:** [new] en espera — el actuador `zwlr_output_manager`; no habla hasta que exista

### A31 — ábrelo allí
- **frase:** "Mueves \<app\> aquí cada vez que se abre, ¿quieres que se abra allí?"
- **verbo:** [ábrelo allí desde ahora]
- **disparador:** una ventana de clase C se abre y se corrige (mover/flotar) igual ≥3×
- **estado:** [cheap] en espera — dos ramas `parse_event` en el colector de Hyprland

### A32 — vigílalo por mí
- **frase:** "Sigues volviendo a mirar esto, ¿quieres que te avise cuando cambie?"
- **verbo:** [avísame cuando cambie] (una notificación, no una frase hablada)
- **disparador:** ≥3 retornos en ~15 min a una ventana con un NN% cambiante / marcador de CI en el título
- **estado:** [cheap] en espera — la rama del evento `windowtitle`

### A33 — el hueco antes de que duerma
- **frase:** "Bloqueas la pantalla a mano cada vez que te levantas, ¿quieres que quede bloqueada en cuanto duerma?"
- **verbo:** [bloquear al dormir la pantalla]
- **disparador:** el bloqueo propio del usuario seguido de inactividad, ≥3×
- **estado:** **dormant** — Golem no entrega ni gestor de inactividad ni candado

### A34 — otro dedo
- **frase:** "El lector de huellas falla la mitad de las veces, ¿quieres añadir otro dedo?"
- **verbo:** [añade otro dedo]
- **disparador:** ≥40% de las últimas 20 verificaciones de huella fallaron (mín. 10 intentos); solo existe donde se detecta un lector
- **estado:** [new] en espera — un nuevo colector lector del journal de fprintd

### A35 — la bóveda abierta
- **frase:** "Tu bóveda de contraseñas sigue desbloqueada, ¿quieres bloquearla?"
- **verbo:** [bloquéala] (el comando de bloqueo documentado de la propia bóveda)
- **disparador:** ventana de bóveda presente y desbloqueada, sin visita de foco durante ≥4 h; escritorio en uso mientras tanto
- **estado:** [live] (solo existe para bóvedas con comando de bloqueo D-Bus documentado)

### A36 — el portapapeles de la bóveda
- **frase:** "Eso salió de tu bóveda, ¿quieres borrarlo del portapapeles en 30 segundos?"
- **verbo:** [bórralo en 30 segundos]
- **disparador:** un contenido marcado como de bóveda sigue presente tras pasar la ventana, ≥2×
- **estado:** [live]

### A37 — de salida
- **frase:** "Borras tu historial casi cada vez que terminas con el navegador, ¿quieres que el navegador lo haga él solo al salir?"
- **verbo:** [bórralo al salir] — la preferencia del propio navegador, Golem jamás toca el historial
- **disparador:** aparece el diálogo de borrar datos del navegador, ≥3× en días distintos
- **estado:** [new] en espera — existe para Firefox; deliberadamente NO existe para el Chrome incluido

### A38 — la segunda perilla
- **frase:** ninguna — viaja en "Se ha puesto el sol, ¿quieres activar la protección ocular?" y añade una pastilla
- **verbo:** [y atenúa la pantalla]
- **disparador:** el aviso del atardecer está en pantalla + el usuario bajó el brillo a mano ≥3 tardes
- **estado:** [cheap] en espera — una lectura de brillo dentro de un `read_dir` existente

### A39 — el escritorio listo
- **frase:** "Este es el conjunto que abres casi todas las mañanas, ¿quieres el escritorio listo?"
- **verbo:** [ten el escritorio listo]
- **disparador:** un conjunto matinal recurrente de apps + hora de primer foco, estable ≥3 mañanas
- **estado:** [cheap] en espera — la ruta de lanzamiento debe saltarse el contador de uso (un bool)

### A40 — cerrar
- **frase:** "Has empezado a cerrar, ¿quieres que cierre el resto?"
- **verbo:** [cierra] (cierres educados del compositor, nunca señales)
- **disparador:** los dos primeros cierres del conjunto de trabajo dentro de una ventana recurrente de fin de sesión, ≥3 días
- **estado:** [cheap] en espera — una rama del evento `closewindow` en el colector

---

## LOTE 02 — 12 acciones

### A01 — el hola no oído
- **frase:** "Tu llamada acaba de conectar y tu micrófono sigue en silencio, ¿quieres abrirlo?"
- **verbo:** [abre el micrófono]
- **disparador:** el flujo de audio de una clase de llamada se activa mientras su fuente está en silencio
- **estado:** [cheap] en espera — leer una marca de silencio del documento de eventos que el colector de audio ya analiza

### A02 — el hogar de la descarga
- **frase:** "Siempre las pones en \<su carpeta\>, ¿quieres que la mueva allí?"
- **verbo:** [múevela allí]
- **disparador:** el tipo de una descarga terminada cae en un destino recurrente en ≥3 ocasiones
- **estado:** [cheap] en espera — el contador de pareja tipo→destino

### A03 — la compilación silenciosa
- **frase:** "Tu compilación lleva diez minutos callada, ¿quieres detenerla?"
- **verbo:** [detenla]
- **disparador:** proceso de compilación vivo, sin salida de terminal en ~10 min, CPU del sistema en ~cero — las tres
- **estado:** [cheap] en espera — un marcador de clase consola en el flujo del puente del shell

### A04 — la rama aterrizada
- **frase:** "Esa rama entró en el árbol, ¿quieres cerrar la local?"
- **verbo:** [cierra la rama] (`git branch -d` — rechaza ramas sin fusionar)
- **disparador:** un comando de merge sale con 0 en el repo y la punta de la rama local es alcanzable desde HEAD
- **estado:** [cheap] en espera — un subproceso `git merge-base --is-ancestor` en el evento de merge

### A06 — la app que este tipo quiere
- **frase:** "Sigues abriendo este tipo de cosa en \<app\>, ¿quieres que sea la predeterminada?"
- **verbo:** [haz que \<app\> sea la predeterminada]
- **disparador:** el mismo tipo MIME abierto en una app distinta a la anterior, ≥3 ocasiones
- **estado:** [cheap] en espera — el contador de pareja mime→app

### A08 — el compañero del proyecto
- **frase:** "Abres \<app\> cada vez que vienes a este proyecto, ¿quieres que esté lista cuando llegues?"
- **verbo:** [tenla siempre lista]
- **disparador:** la misma asociación cwd→lanzamiento recurre en ≥3 días distintos
- **estado:** [cheap] en espera — la memoria de asociación hash-de-cwd → clase-de-app

### A09 — la app en el comando muerto
- **frase:** "Ese comando no es un comando, pero \<app\> sí — ¿quieres que lo abra?"
- **verbo:** [abre \<app\>]
- **disparador:** el shell devuelve el código 127 y el comando tecleado coincide con el basename Exec de un archivo .desktop instalado
- **estado:** **[live]** — una de las dos que hablan hoy

### A10 — el descanso del almuerzo
- **frase:** "Es la hora a la que sueles apartarte, y el escritorio ha estado en calma — ¿quieres echar una siesta hasta que vuelvas?"
- **verbo:** [hibernar]
- **disparador:** escritorio inactivo a una hora mediana recurrente de mediodía
- **estado:** **dormant** — necesita el único listener de logind compartido (con A14)

### A12 — el nivel que funcionó
- **frase:** "Tu reunión está a punto de empezar, ¿quieres que ajuste tu micrófono al nivel que funcionó?"
- **verbo:** [ajusta mi nivel]
- **disparador:** una ventana de clase reunión tiene el foco y la captura aún no está activa
- **estado:** **[live]** — una de las dos que hablan hoy

### A13 — la foto que sabe de más
- **frase:** "Esa foto está a punto de salir y todavía lleva sus metadatos, ¿quieres que se los borre?"
- **verbo:** [borra sus metadatos]
- **disparador:** una imagen recién hecha + una ventana de clase compartir toma el foco; la imagen aún lleva un marcador EXIF/XMP
- **estado:** [new] en espera — no hay limpiador EXIF incluido; es el único [new] del lote

### A14 — el sueño limpio
- **frase:** "Estoy a punto de dormir y aún guardo tu historial del portapapeles, ¿quieres que lo borre?"
- **verbo:** [borra mi historial del portapapeles]
- **disparador:** la sesión entra en suspensión con el almacén de historial no vacío
- **estado:** **dormant** — comparte el listener de logind con A10; el verbo en sí es [live]

### A15 — la mano firme
- **frase:** "Estás en el editor de píxeles, ¿quieres suavizar el puntero para ello?"
- **verbo:** [suaviza el puntero]
- **disparador:** el foco cae en una ventana de clase precisión (imagen/CAD/píxeles) y se queda
- **estado:** [cheap] en espera — una escritura en tiempo real `input.sensitivity` en el carril eval

---

## Cuántas pueden hablar hoy

- **12 de 46 pueden hablar en el motor de hoy**: las 10 activas del lote 01, más A09 y A12 del lote 02.
- **34 esperan** el trabajo nombrado arriba — el recuento, fila a fila.