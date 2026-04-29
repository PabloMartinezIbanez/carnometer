# Servicios de Mapbox para Splitway

Fecha de revision: 2026-04-29.

Este documento explica:

- Que servicios de Mapbox usamos ahora.
- Que informacion se envia en cada llamada.
- Que devuelve Mapbox.
- Cuando se usa cada llamada.
- Que servicios de Mapbox podrian venir bien para futuras ideas.

Los ejemplos usan coordenadas ficticias de Madrid. Mapbox recibe coordenadas en orden `longitud,latitud`, aunque en la app normalmente trabajamos con `latitude` y `longitude`.

## Resumen rapido

| Servicio | Estado en Splitway | Para que sirve |
| --- | --- | --- |
| Maps SDK for Flutter | En uso | Mostrar mapa, estilo, linea de ruta, waypoints y sectores. |
| Directions API | En uso | Crear una geometria de ruta ajustada a carretera a partir de waypoints. |
| Map Matching API | Preparado, pero no usado en UI | Ajustar una traza GPS real a la red de carreteras/caminos. |
| Search Box API | No usado | Buscar sitios, direcciones y POIs con autocompletado. |
| Geocoding API | No usado | Convertir texto a coordenadas o coordenadas a direccion/nombre. |
| Matrix API | No usado | Calcular tiempos/distancias entre varios puntos sin geometria. |
| Isochrone API | No usado | Ver zonas alcanzables en X minutos o X metros. |
| Static Images API | No usado | Generar miniaturas de mapas/rutas como imagen. |
| Styles / Mapbox Studio | Uso basico | Usar o crear estilos visuales propios para el mapa. |
| Offline Maps | No usado | Descargar zonas de mapa para uso sin conexion. |
| Navigation SDK | No usado | Navegacion giro a giro, progreso de ruta, rerouting y voz. |

## 1. Maps SDK for Flutter

### Cuando se usa

Se usa cada vez que la app muestra un mapa interactivo:

- En el editor de rutas.
- En la previsualizacion de una ruta guardada.
- Para pintar la linea de la ruta.
- Para pintar waypoints, salida/meta y sectores.

Este servicio no calcula rutas. Solo renderiza el mapa y nuestras anotaciones encima.

### Que informacion se envia

La app configura el SDK con:

```text
MAPBOX_ACCESS_TOKEN=<token publico de Mapbox>
MAPBOX_STYLE_URI=mapbox://styles/mapbox/streets-v12
```

En tiempo de uso, el SDK solicita a Mapbox los recursos necesarios para pintar el mapa segun:

- Estilo del mapa, por ejemplo `mapbox://styles/mapbox/streets-v12`.
- Centro de camara, por ejemplo `[-3.7038, 40.4168]`.
- Zoom, bearing y pitch.
- Tiles visibles en la pantalla.
- Sprites, fuentes y datos del estilo.

Ejemplo conceptual:

```dart
MapWidget(
  styleUri: 'mapbox://styles/mapbox/streets-v12',
  cameraOptions: CameraOptions(
    center: Point(coordinates: Position(-3.7038, 40.4168)),
    zoom: 13,
  ),
)
```

Ademas, Splitway crea anotaciones locales en el mapa:

```json
{
  "route_line": [
    [-3.7038, 40.4168],
    [-3.6991, 40.4181],
    [-3.6896, 40.4212]
  ],
  "waypoints": [
    [-3.7038, 40.4168],
    [-3.6896, 40.4212]
  ],
  "sectors": [
    [-3.6991, 40.4181]
  ]
}
```

Estas anotaciones son datos que la app dibuja sobre el mapa. No son una llamada a Directions.

### Que devuelve

El SDK devuelve/renderiza:

- Mapa visual en pantalla.
- Eventos de interaccion, por ejemplo un tap con coordenadas.
- Estado de carga del estilo.
- Herramientas para crear anotaciones de circulos, lineas y poligonos.

Ejemplo de evento que recibe la app al tocar el mapa:

```json
{
  "event": "tap",
  "coordinates": {
    "longitude": -3.7038,
    "latitude": 40.4168
  }
}
```

### Para que nos sirve

Es la base visual de Splitway. Permite crear rutas tocando el mapa, ver la ruta resultante y colocar sectores.

## 2. Directions API

### Cuando se usa

Se usa al crear o editar una ruta con waypoints manuales.

El usuario toca varios puntos en el mapa. Splitway manda esos puntos a Mapbox para obtener una linea ajustada a carretera/camino, en vez de unirlos con segmentos rectos.

Ejemplo:

- Usuario toca punto A.
- Usuario toca punto B.
- Usuario toca punto C.
- Splitway pide a Mapbox una ruta A -> B -> C.
- Mapbox devuelve la geometria real por carretera.

### Que informacion enviamos

La app no llama directamente a Mapbox. Llama a la Edge Function de Supabase `mapbox-routing`, y esa funcion llama a Mapbox con el token secreto.

Payload que manda la app a Supabase:

```json
{
  "mode": "directions",
  "profile": "driving",
  "points": [
    { "latitude": 40.4168, "longitude": -3.7038 },
    { "latitude": 40.4212, "longitude": -3.6896 },
    { "latitude": 40.4302, "longitude": -3.7031 }
  ]
}
```

La Edge Function convierte esos puntos al formato de Mapbox:

```text
-3.7038,40.4168;-3.6896,40.4212;-3.7031,40.4302
```

Llamada real a Mapbox:

```http
GET https://api.mapbox.com/directions/v5/mapbox/driving/-3.7038,40.4168;-3.6896,40.4212;-3.7031,40.4302?geometries=geojson&overview=full&steps=false&access_token=<MAPBOX_SECRET_TOKEN>
```

Parametros importantes:

- `mapbox/driving`: perfil de ruta. Tambien existen `driving-traffic`, `walking` y `cycling`.
- `coordinates`: lista de puntos en orden `longitud,latitud`.
- `geometries=geojson`: queremos una geometria GeoJSON, facil de parsear.
- `overview=full`: queremos la ruta completa, no una version simplificada.
- `steps=false`: no pedimos instrucciones giro a giro.
- `access_token`: token secreto en Supabase, no en el cliente.

### Que devuelve Mapbox

Mapbox Directions devuelve un objeto con rutas posibles. Simplificado:

```json
{
  "code": "Ok",
  "routes": [
    {
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-3.7038, 40.4168],
          [-3.7004, 40.4176],
          [-3.6961, 40.4192],
          [-3.6896, 40.4212],
          [-3.6948, 40.4261],
          [-3.7031, 40.4302]
        ]
      },
      "distance": 2840.7,
      "duration": 492.3,
      "legs": [
        {
          "distance": 1320.4,
          "duration": 220.1,
          "summary": "Calle de Alcala"
        },
        {
          "distance": 1520.3,
          "duration": 272.2,
          "summary": "Paseo de Recoletos"
        }
      ]
    }
  ],
  "waypoints": [
    {
      "name": "Puerta del Sol",
      "location": [-3.7038, 40.4168]
    },
    {
      "name": "Calle de Alcala",
      "location": [-3.6896, 40.4212]
    },
    {
      "name": "Recoletos",
      "location": [-3.7031, 40.4302]
    }
  ]
}
```

Ahora mismo Splitway solo aprovecha:

```json
{
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [-3.7038, 40.4168],
      [-3.7004, 40.4176],
      [-3.6961, 40.4192],
      [-3.6896, 40.4212]
    ]
  }
}
```

La Edge Function normaliza la respuesta y devuelve a la app:

```json
{
  "mode": "directions",
  "provider": "mapbox-directions",
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [-3.7038, 40.4168],
      [-3.7004, 40.4176],
      [-3.6961, 40.4192],
      [-3.6896, 40.4212]
    ]
  }
}
```

### Que podriamos aprovechar mas adelante

Directions puede devolver mas informacion que ahora estamos descartando:

- `distance`: distancia total en metros.
- `duration`: duracion estimada en segundos.
- `legs`: informacion entre cada waypoint.
- `steps=true`: maniobras giro a giro.
- `alternatives=true`: rutas alternativas.
- `annotations=distance,duration,speed`: datos por segmento.
- `maxspeed`: limites de velocidad donde este disponible.
- `driving-traffic`: rutas con trafico actual/historico.

Ejemplo futuro:

```http
GET https://api.mapbox.com/directions/v5/mapbox/driving-traffic/-3.7038,40.4168;-3.6896,40.4212?geometries=geojson&overview=full&alternatives=true&annotations=distance,duration,speed&access_token=<token>
```

Posible uso en Splitway:

- Mostrar distancia real de ruta por carretera, no solo distancia en linea recta.
- Guardar una duracion estimada de referencia.
- Comparar tiempo real del usuario contra tiempo estimado.
- Ofrecer rutas alternativas antes de guardar.

## 3. Map Matching API

### Cuando se usa

Map Matching sirve para una situacion distinta a Directions.

Directions se usa cuando tenemos pocos waypoints y queremos que Mapbox construya una ruta entre ellos.

Map Matching se usa cuando ya tenemos una traza GPS grabada y queremos limpiarla. Por ejemplo, una sesion real puede tener puntos con ruido, saltos o desviaciones de varios metros. Map Matching ajusta esa nube de puntos a la red de carreteras/caminos.

En Splitway el metodo existe, pero no esta conectado a una pantalla actual. Seria muy util para sesiones grabadas.

### Que informacion enviariamos

Payload de la app a Supabase:

```json
{
  "mode": "map-matching",
  "profile": "driving",
  "points": [
    { "latitude": 40.4168, "longitude": -3.7038 },
    { "latitude": 40.4170, "longitude": -3.7029 },
    { "latitude": 40.4174, "longitude": -3.7017 },
    { "latitude": 40.4181, "longitude": -3.7004 }
  ]
}
```

Llamada a Mapbox:

```http
GET https://api.mapbox.com/matching/v5/mapbox/driving/-3.7038,40.4168;-3.7029,40.4170;-3.7017,40.4174;-3.7004,40.4181?geometries=geojson&overview=full&tidy=true&access_token=<MAPBOX_SECRET_TOKEN>
```

Parametros:

- `coordinates`: muchos puntos de una traza GPS.
- `tidy=true`: Mapbox intenta limpiar clusters y remuestrear la traza.
- `geometries=geojson`: devuelve una linea GeoJSON.
- `overview=full`: devuelve la geometria completa.

Para una version mejor, deberiamos enviar tambien:

```json
{
  "timestamps": [1777485600, 1777485605, 1777485610, 1777485615],
  "radiuses": [8, 8, 12, 8]
}
```

`timestamps` ayuda a Mapbox a entender el orden temporal y la velocidad. `radiuses` indica la precision estimada de cada punto GPS.

### Que devuelve Mapbox

Respuesta simplificada:

```json
{
  "code": "Ok",
  "matchings": [
    {
      "confidence": 0.92,
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-3.7038, 40.4168],
          [-3.7024, 40.4172],
          [-3.7010, 40.4177],
          [-3.7004, 40.4181]
        ]
      },
      "distance": 390.4,
      "duration": 58.2
    }
  ],
  "tracepoints": [
    {
      "waypoint_index": 0,
      "matchings_index": 0,
      "location": [-3.7038, 40.4168],
      "name": "Calle Mayor"
    },
    {
      "waypoint_index": 1,
      "matchings_index": 0,
      "location": [-3.7024, 40.4172],
      "name": "Calle Mayor"
    }
  ]
}
```

Splitway podria guardar:

- Geometria GPS original: para datos reales y auditoria.
- Geometria ajustada: para replay limpio y comparaciones visuales.
- `confidence`: para saber si confiar en el ajuste.

### Limitaciones importantes

- Maximo 100 coordenadas por request normal.
- Funciona mejor con puntos separados unos 5 segundos.
- Para sesiones largas hay que dividir en bloques.
- Si una sesion tiene muchos puntos por segundo, conviene reducir la frecuencia antes de llamar.

## 4. Search Box API

### Cuando se usaria

Para que el usuario busque lugares en el editor:

- Buscar una direccion.
- Buscar un circuito.
- Buscar un parking.
- Buscar un punto de interes.
- Centrar el mapa en un resultado.
- Crear un waypoint desde una busqueda.

Esto seria mejor que obligar al usuario a navegar manualmente por el mapa.

### Que informacion enviariamos

Flujo de autocompletado:

1. Mientras el usuario escribe, llamar a `/suggest`.
2. Al seleccionar una sugerencia, llamar a `/retrieve/{id}`.
3. Usar la coordenada devuelta.

Request de sugerencias:

```http
GET https://api.mapbox.com/search/searchbox/v1/suggest?q=jarama&language=es&country=ES&limit=5&proximity=-3.7038,40.4168&session_token=<uuid>&access_token=<token>
```

Datos enviados:

- `q`: texto escrito por el usuario.
- `language`: idioma preferido.
- `country`: filtro opcional por pais.
- `limit`: numero maximo de sugerencias.
- `proximity`: punto desde el que priorizar resultados cercanos.
- `session_token`: UUID que agrupa la busqueda para facturacion.
- `access_token`: token de Mapbox.

### Que devuelve

Respuesta simplificada de `/suggest`:

```json
{
  "suggestions": [
    {
      "name": "Circuito del Jarama",
      "mapbox_id": "dXJuOm1ieHBva...",
      "feature_type": "poi",
      "address": "Autovia A-1",
      "place_formatted": "San Sebastian de los Reyes, Madrid, Espana"
    },
    {
      "name": "Jarama",
      "mapbox_id": "dXJuOm1ieHBsY...",
      "feature_type": "place",
      "place_formatted": "Espana"
    }
  ]
}
```

Cuando el usuario selecciona una sugerencia:

```http
GET https://api.mapbox.com/search/searchbox/v1/retrieve/dXJuOm1ieHBva...?session_token=<uuid>&access_token=<token>
```

Respuesta simplificada de `/retrieve`:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-3.5850, 40.6170]
      },
      "properties": {
        "name": "Circuito del Jarama",
        "feature_type": "poi",
        "full_address": "Autovia A-1, San Sebastian de los Reyes, Madrid"
      }
    }
  ]
}
```

### Para que nos vendria bien

- Buscador dentro del editor de rutas.
- Boton "ir a ubicacion".
- Crear rutas desde un punto buscado.
- Encontrar circuitos o zonas cercanas.

Nota de producto: Search Box es mejor que Geocoding para busqueda interactiva con autocompletado y POIs.

## 5. Geocoding API

### Cuando se usaria

Para convertir texto en coordenadas o coordenadas en texto cuando no necesitamos un autocompletado completo.

Casos:

- Mostrar ciudad/pais de una ruta guardada.
- Mostrar direccion aproximada de salida/meta.
- Convertir una busqueda puntual en coordenadas.
- Enriquecer una ruta con nombre de zona.

### Que informacion enviariamos

Forward geocoding: texto -> coordenadas.

```http
GET https://api.mapbox.com/search/geocode/v6/forward?q=Plaza%20Mayor%20Madrid&language=es&country=es&limit=1&access_token=<token>
```

Reverse geocoding: coordenadas -> lugar.

```http
GET https://api.mapbox.com/search/geocode/v6/reverse?longitude=-3.7038&latitude=40.4168&language=es&access_token=<token>
```

### Que devuelve

Respuesta simplificada:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-3.7060, 40.4154]
      },
      "properties": {
        "name": "Plaza Mayor",
        "feature_type": "address",
        "full_address": "Plaza Mayor, Madrid, Espana",
        "context": {
          "place": {
            "name": "Madrid"
          },
          "country": {
            "name": "Espana",
            "country_code": "ES"
          }
        }
      }
    }
  ]
}
```

### Para que nos vendria bien

- Etiquetas automaticas: "Ruta en Madrid".
- Direccion aproximada de inicio.
- Filtros por ciudad o pais.
- Mejor informacion en la ficha de ruta.

## 6. Matrix API

### Cuando se usaria

Cuando queremos saber tiempos o distancias entre varios puntos, pero no necesitamos dibujar la ruta.

Ejemplos:

- "Esta ruta esta a 12 min de tu ubicacion".
- Ordenar rutas cercanas por tiempo en coche.
- Comparar varios puntos de salida.
- Calcular distancias entre varios checkpoints sin pedir muchas rutas completas.

### Que informacion enviariamos

Ejemplo: usuario actual -> tres rutas guardadas.

```http
GET https://api.mapbox.com/directions-matrix/v1/mapbox/driving/-3.7038,40.4168;-3.6896,40.4212;-3.5850,40.6170;-3.9210,40.3000?sources=0&destinations=1;2;3&annotations=duration,distance&access_token=<token>
```

Datos:

- Primera coordenada: posicion del usuario.
- Resto: puntos de salida de rutas.
- `sources=0`: solo calculamos desde la posicion del usuario.
- `destinations=1;2;3`: destinos son las rutas.
- `annotations=duration,distance`: queremos tiempo y distancia.

### Que devuelve

```json
{
  "code": "Ok",
  "durations": [
    [326.5, 1840.0, 2420.7]
  ],
  "distances": [
    [1834.2, 28500.4, 38200.9]
  ],
  "sources": [
    {
      "name": "Puerta del Sol",
      "location": [-3.7038, 40.4168]
    }
  ],
  "destinations": [
    {
      "name": "Calle de Alcala",
      "location": [-3.6896, 40.4212]
    }
  ]
}
```

### Para que nos vendria bien

- Ranking de rutas por cercania real.
- Mostrar tiempo estimado hasta el inicio.
- Recomendaciones segun ubicacion actual.

## 7. Isochrone API

### Cuando se usaria

Para dibujar zonas alcanzables desde un punto en cierto tiempo o distancia.

Ejemplos:

- Mostrar que rutas quedan a 10, 20 o 30 minutos.
- Buscar rutas dentro de una zona alcanzable.
- Crear filtros visuales de disponibilidad.
- Sugerir zonas para entrenar cerca del usuario.

### Que informacion enviariamos

```http
GET https://api.mapbox.com/isochrone/v1/mapbox/driving/-3.7038,40.4168?contours_minutes=10,20,30&polygons=true&access_token=<token>
```

Datos:

- Perfil: `mapbox/driving`, `walking` o `cycling`.
- Coordenada central.
- `contours_minutes`: tiempos que queremos.
- `polygons=true`: queremos poligonos, no solo lineas.

Tambien se puede pedir por distancia:

```http
GET https://api.mapbox.com/isochrone/v1/mapbox/driving/-3.7038,40.4168?contours_meters=5000,10000,20000&polygons=true&access_token=<token>
```

### Que devuelve

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "contour": 10,
        "metric": "time"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [-3.75, 40.40],
            [-3.68, 40.39],
            [-3.65, 40.43],
            [-3.72, 40.45],
            [-3.75, 40.40]
          ]
        ]
      }
    }
  ]
}
```

### Para que nos vendria bien

- Mapa "rutas alcanzables en 20 min".
- Descubrir rutas cercanas con un criterio mas realista que radio en linea recta.
- Mejor onboarding: "elige una zona cerca de ti".

## 8. Static Images API

### Cuando se usaria

Para generar imagenes estaticas de rutas sin cargar un mapa interactivo.

Casos:

- Miniatura en lista de rutas.
- Imagen para compartir una ruta.
- Preview en historial.
- Imagen en notificaciones o exportaciones.

### Que informacion enviariamos

Ejemplo de imagen con una linea:

```http
GET https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/path-4+2563EB-0.8(-3.7038,40.4168;-3.7004,40.4176;-3.6896,40.4212)/auto/600x360@2x?access_token=<token>
```

Datos:

- Estilo: `mapbox/streets-v12`.
- Overlay: path con color, grosor y opacidad.
- Coordenadas de la ruta.
- Viewport: `auto`, para ajustar a la linea.
- Tamano: `600x360@2x`.

### Que devuelve

Devuelve una imagen, normalmente `PNG` o `JPEG`, no JSON.

Ejemplo de uso:

```html
<img src="https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/..." />
```

### Para que nos vendria bien

- Evitar cargar muchos `MapWidget` en una lista.
- Cachear miniaturas de rutas.
- Compartir rutas con una imagen visual.

Limitacion: si la ruta tiene muchisimos puntos, la URL puede ser demasiado larga. En ese caso habria que simplificar la geometria o usar otra estrategia.

## 9. Styles API y Mapbox Studio

### Cuando se usaria

Ahora usamos un estilo base. En el futuro podriamos usar estilos propios para que el mapa se lea mejor para Splitway.

Opciones:

- `mapbox://styles/mapbox/streets-v12`: calles generalistas.
- `mapbox://styles/mapbox/outdoors-v12`: mas util para caminos y zonas outdoor.
- `mapbox://styles/mapbox/satellite-streets-v12`: satelite con calles.
- Estilo propio en Mapbox Studio.

### Que informacion se envia

En la app solo cambiariamos:

```json
{
  "MAPBOX_STYLE_URI": "mapbox://styles/mapbox/outdoors-v12"
}
```

Si usamos Styles API directamente para leer un estilo:

```http
GET https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=<token>
```

### Que devuelve

Devuelve la definicion JSON del estilo:

```json
{
  "version": 8,
  "name": "Mapbox Streets",
  "sources": {
    "composite": {
      "type": "vector",
      "url": "mapbox://mapbox.mapbox-streets-v8"
    }
  },
  "layers": [
    {
      "id": "road-primary",
      "type": "line",
      "source": "composite"
    }
  ]
}
```

### Para que nos vendria bien

- Mapa con menos ruido visual.
- Colores pensados para que la ruta y sectores destaquen.
- Modo satelite para validar trazados.
- Estilo nocturno para sesiones de noche.

## 10. Offline Maps

### Cuando se usaria

Para permitir que el usuario descargue mapas antes de una sesion y pueda verlos aunque no tenga conexion.

Casos:

- Rutas en zonas con mala cobertura.
- Circuitos alejados.
- Ahorro de datos.
- Fiabilidad durante sesiones.

### Que informacion se enviaria

Normalmente se define:

- Estilo a descargar.
- Region geografica.
- Rango de zoom.
- Nombre/ID de la region offline.

Ejemplo conceptual:

```json
{
  "style_uri": "mapbox://styles/mapbox/streets-v12",
  "bounds": {
    "west": -3.75,
    "south": 40.39,
    "east": -3.65,
    "north": 40.45
  },
  "min_zoom": 10,
  "max_zoom": 16,
  "region_id": "route_madrid_centro"
}
```

### Que devuelve

No devuelve una ruta. Descarga recursos al dispositivo:

- Tiles.
- Datos del estilo.
- Fuentes.
- Sprites.
- Estado de progreso de descarga.

Ejemplo conceptual de progreso:

```json
{
  "region_id": "route_madrid_centro",
  "completed_resource_count": 420,
  "required_resource_count": 1000,
  "completed_resource_size": 18350080
}
```

### Para que nos vendria bien

- Mapa disponible durante cronometraje.
- Mejor experiencia en carretera o campo.
- Descarga de zona alrededor de una ruta guardada.

## 11. Navigation SDK

### Cuando se usaria

No es necesario para el MVP si Splitway solo crea rutas y cronometra sesiones. Pero seria util si queremos navegacion activa:

- Guiar al usuario hasta la salida.
- Navegar durante una ruta abierta.
- Detectar desvio de ruta.
- Recalcular ruta.
- Instrucciones de voz.
- Progreso de ruta.

### Que informacion se enviaria

Para navegar, se crea o solicita una ruta con origen/destino/waypoints:

```json
{
  "origin": [-3.7038, 40.4168],
  "destination": [-3.6896, 40.4212],
  "profile": "driving",
  "alternatives": true,
  "voice_instructions": true,
  "banner_instructions": true
}
```

### Que devuelve

Devuelve objetos de navegacion:

```json
{
  "route": {
    "geometry": "...",
    "distance": 1834.2,
    "duration": 326.5
  },
  "progress": {
    "distance_remaining": 920.0,
    "duration_remaining": 160.0,
    "fraction_traveled": 0.49,
    "current_state": "TRACKING"
  },
  "maneuver": {
    "instruction": "Gira a la derecha",
    "distance_to_maneuver": 120
  }
}
```

### Para que nos vendria bien

- Si Splitway evoluciona hacia navegacion real.
- Si queremos llevar al usuario desde su ubicacion hasta una ruta.
- Si queremos avisar "te has salido del trazado".

Coste tecnico: es mas pesado que usar solo Maps SDK + Directions API.

## 12. Servicios adicionales menos prioritarios

### Optimization API

Sirve para ordenar paradas de forma optima. Es util para repartos o rutas con muchos puntos obligatorios.

Ejemplo:

```json
{
  "locations": [
    { "name": "start", "coordinates": [-3.7038, 40.4168] },
    { "name": "checkpoint_a", "coordinates": [-3.6896, 40.4212] },
    { "name": "checkpoint_b", "coordinates": [-3.5850, 40.6170] }
  ],
  "vehicles": [
    { "name": "vehicle_1", "routing_profile": "mapbox/driving" }
  ],
  "services": [
    { "name": "visit_a", "location": "checkpoint_a" },
    { "name": "visit_b", "location": "checkpoint_b" }
  ]
}
```

Para Splitway solo lo veo interesante si algun dia queremos crear rutas automaticamente pasando por varios puntos.

### Tilequery API

Sirve para consultar informacion de un tileset en una coordenada concreta.

Ejemplo:

```http
GET https://api.mapbox.com/v4/{tileset_id}/tilequery/-3.7038,40.4168.json?radius=50&limit=5&access_token=<token>
```

Podria servir si en el futuro subimos datos propios a Mapbox:

- Segmentos.
- Zonas.
- Puntos peligrosos.
- Checkpoints.
- Circuitos privados.

## Recomendacion para futuras ideas

### Corto plazo

1. Aprovechar mas datos de Directions: `distance`, `duration`, `legs` y quizas `alternatives`.
2. Activar Map Matching para sesiones grabadas, guardando siempre la telemetria original.
3. Anadir Search Box al editor para buscar sitios y crear waypoints desde resultados.

### Medio plazo

1. Static Images para miniaturas de rutas.
2. Matrix para ordenar rutas por tiempo desde la ubicacion actual.
3. Geocoding para mostrar ciudad, pais y direccion aproximada.
4. Estilo propio de Mapbox Studio para que la ruta destaque mas.

### Largo plazo

1. Offline Maps para rutas en zonas con poca cobertura.
2. Navigation SDK si queremos navegacion guiada o deteccion avanzada de desvio.
3. Isochrone para descubrir rutas alcanzables en X minutos.
4. Optimization o Tilequery solo si aparecen features que lo justifiquen.

## Fuentes oficiales

- Directions API: https://docs.mapbox.com/api/navigation/directions/
- Map Matching API: https://docs.mapbox.com/api/navigation/map-matching/
- Search Box API: https://docs.mapbox.com/api/search/search-box/
- Geocoding API: https://docs.mapbox.com/api/search/geocoding/
- Matrix API: https://docs.mapbox.com/api/navigation/matrix/
- Isochrone API: https://docs.mapbox.com/api/navigation/isochrone/
- Static Images API: https://docs.mapbox.com/api/maps/static-images/
- Maps SDK for Flutter: https://docs.mapbox.com/flutter/maps/guides/
- Offline Maps for Flutter: https://docs.mapbox.com/flutter/maps/examples/offline/
- Navigation SDK for Android: https://docs.mapbox.com/android/navigation/overview/
