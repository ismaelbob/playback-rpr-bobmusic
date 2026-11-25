# PlaybackRPR

Interfaz web para controlar sesiones multipista en REAPER desde un teléfono o tablet en la misma red.

## Requisitos

- REAPER 5+
- Navegador web moderno (Chrome/Firefox/Safari)
- Misma red WiFi entre el dispositivo y el PC con REAPER

## Instalación

### 1. Copiar archivos

**Linux:**
```bash
cp session_bridge.lua ~/.config/REAPER/Scripts/
cp playback.html ~/.config/REAPER/Plugins/reaper_www_root/
```

**Windows:**
```batch
copy session_bridge.lua %APPDATA%\REAPER\Scripts\
copy playback.html %APPDATA%\REAPER\Plugins\reaper_www_root\
```

### 2. Registrar el script en REAPER

1. REAPER → **Actions** → **Show action list...**
2. Click **ReaScript: Load...**
3. Navegar y seleccionar `session_bridge.lua`
4. En la lista de acciones, buscar `session_bridge`
5. Click derecho → **Copy selected action Command ID**
   (se ve como `_RSxxxxxxxxxxxxx`)

### 3. Configurar `playback.html`

Editar `playback.html` y reemplazar:

```js
const BRIDGE_CMD = "_RSXXXXXXXXXXXXX";
```

con el Command ID copiado.

### 4. Configurar REAPER Web Interface

1. REAPER → **Options** → **Preferences** → **Control/OSC/web**
2. Click **Add**
3. `Control surface mode`: **Web Browser Interface**
4. En `Default Interface` seleccionar `playback.html`
5. Anotar la **Access URL** (ej: `http://192.168.1.100:8080`)
6. Click **OK**

### 5. Abrir desde el teléfono

En el navegador del teléfono (misma red WiFi), abrir:

```
http://<IP-DEL-PC>:8080/playback.html
```

## Uso

1. Tener múltiples proyectos abiertos en pestañas de REAPER
   (cada pestaña = una canción, cada canción con sus regiones)

2. Cada proyecto debe tener **regiones** para las secciones de la canción
   (intro, verse, chorus, etc.)

3. Abrir `playback.html` desde el teléfono

4. **Pantalla de inicio:** Lista de proyectos abiertos
   - Tap en una canción → cambia a esa pestaña en REAPER
   - Muestra las regiones de esa canción
   - Muestra las pistas con controles

5. **Controles por pista:**
   - **M** → Mute (toggle)
   - **S** → Solo (toggle)
   - **Slider** → Volumen

6. **Transporte:**
   - ▶️ Play / Pausa
   - ⏹ Stop
   - ◀◀ Región anterior
   - ▶▶ Siguiente región

7. **↻ Refresh** → Recargar lista de proyectos

## Verificar action IDs

Las acciones de cambio de pestaña usan IDs numéricos. Esta configuración usa
`3122` para "Go to project tab 01", `3123` para tab 02, etc. Otras versiones
de REAPER pueden usar `40830`, `40831`, ...

Para verificar: Actions → **Show action list...** → buscar
"Go to project tab". Si los IDs difieren, editar `TAB_CMD_BASE` en
`playback.html`.

## Estructura del proyecto

```
playbackRPR-bobmusic/
├── playback.html        # Interfaz web (servida por REAPER)
├── session_bridge.lua   # Script REAPER (enumera pestañas)
└── README.md
```

## Cómo funciona

- `playback.html` se sirve desde el servidor HTTP integrado de REAPER
- Se comunica con REAPER vía WebSocket usando `main.js`
- `session_bridge.lua` escribe `playback_data.json` con la lista de
  proyectos abiertos
- Al seleccionar una canción, envía command ID para cambiar de pestaña
  y luego consulta regiones/pistas del nuevo proyecto activo
