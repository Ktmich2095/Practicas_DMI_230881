# Backend de catálogos TokTik

Servicio Node.js sin dependencias externas. Mantiene las claves de Coverr y
Pixabay en el servidor; el APK recibe metadatos y URLs de reproducción, nunca
las claves. Internet Archive y los assets siguen funcionando directamente.

## Despliegue

Usar Node.js 24 LTS o construir el Dockerfile de esta carpeta. Configurar en el
gestor de secretos del alojamiento `COVERR_API_KEY` y `PIXABAY_API_KEY`, sin el
prefijo Bearer. Iniciar con `node server.mjs`. El puerto es `PORT` (8080 por
defecto). Publicar detrás del HTTPS del alojamiento con certificado válido.
El contenedor copia únicamente server.mjs, no api_keys.json.

No se ha desplegado este servicio: todavía hace falta un alojamiento y su URL
HTTPS pública. No utilizar localhost en el APK de Appetize.

Para desarrollo local, `TOKTIK_KEYS_FILE` puede indicar el api_keys.json
ignorado por Git. Las variables de entorno tienen prioridad. `TLS_CERT_PATH`
y `TLS_KEY_PATH` permiten TLS local para las pruebas Android; no publicar esas
claves de certificado. No guardar secretos en esta carpeta ni en archivos .env.

## Contrato

- `GET /health`: estado y nombres de proveedores configurados, sin credenciales.
- `GET /v1/videos/coverr?page=0&page_size=8`.
- `GET /v1/videos/pixabay?page=1&per_page=8`.

Respuestas exitosas conservan hits y contadores utilizados por los mappers.
Los errores conservan el estado HTTP y un código seguro, sin cuerpo remoto.
Solo se admiten estos proveedores y parámetros de paginación; no es un proxy
de URLs arbitrarias. Caché de Pixabay de 24 horas, Coverr de cinco minutos,
30 entradas y deduplicación de consultas concurrentes. Los MP4 se reproducen
desde su CDN, conservando los parámetros de las URLs firmadas.

El límite básico es 60 consultas por minuto por dirección de conexión. Detrás
de un proxy varias personas pueden compartirlo: configurar límites y cuotas
también en el alojamiento. CORS opcional con ALLOWED_ORIGIN no es autenticación.
La caché es en memoria por proceso; para varias réplicas o persistencia entre
reinicios se necesita caché compartida. Revisar cuotas y condiciones del
proveedor antes de abrir un servicio público.

Pruebas: `node --test backend/server.test.mjs` desde la raíz de TokTik.

Referencias: [Coverr](https://api.coverr.co/docs/auth/),
[Pixabay y su política de caché](https://pixabay.com/api/docs/).
