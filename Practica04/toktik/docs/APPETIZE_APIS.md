# Fuentes de video en el APK release de Appetize

## Diagnóstico y corrección

`api_keys.json` no se carga en tiempo de ejecución. La configuración anterior
usaba String.fromEnvironment: requería pasar explícitamente el archivo al
compilador. Un flutter build apk --release común no incorporaba sus valores,
y Coverr/Pixabay quedaban sin configurar. No se pudo inspeccionar el binario
exacto publicado en Appetize; el APK local anterior no contenía las claves.

Las claves locales sí permitieron obtener ambos catálogos por el backend
(HTTP 200) y reproducir sus videos en Android. Una prueba directa con urllib
de Python recibió 403: el transporte/contexto de acceso también influye; eso
no demuestra que las claves sean inválidas.

La solución pública utiliza TOKTIK_API_BASE_URL y un backend HTTPS. En release
ApiConfig deshabilita las claves directas incluso si alguien pasa sus defines.
JsonApiClient envía al backend solo paginación. Las consultas privadas ocurren
en el servidor: Bearer para Coverr y parámetro key para Pixabay. Las URLs
firmadas de video se conservan y las claves de catálogo no se envían al CDN.

Se distinguen fallos de configuración, HTTP 401/403/404/429/5xx, red, esquema y
mapping; el reproductor muestra diagnósticos sanitizados de HTTP/codec/error
sin exponer excepciones nativas ni URLs. Pixabay prioriza tiny/small antes de
medium/large para reducir ancho de banda y carga del decodificador.
El permiso INTERNET ya estaba en el manifiesto principal de Android.
No se cambiaron temas, sonidos, animaciones, pantallas ni controles de audio.

## Generar el APK público

1. Desplegar [el backend](../backend/README.md) con ambas claves en secretos del
   alojamiento y un certificado HTTPS público válido.
2. Desde Practica04/toktik, ejecutar en PowerShell:

```powershell
$backendUrl = Read-Host 'URL HTTPS pública del backend desplegado'
.\scripts\build_appetize_release.ps1 -ApiBaseUrl $backendUrl
```

El script consulta ambos catálogos antes de compilar y ejecuta la auditoría
del APK. Usa únicamente `--dart-define=TOKTIK_API_BASE_URL=...`, sin claves.
El resultado es `build/app/outputs/flutter-apk/app-release.apk`.
Subirlo como nueva versión en Appetize y comprobar selección de cada fuente y
avance de reproducción. La publicación en Appetize no se realizó desde aquí.

Sin backend desplegado todavía no puede generarse un APK público con esas
fuentes autenticadas habilitadas de forma segura. La compilación release sin
defines sirve para verificar compilación; no habilita Coverr/Pixabay.

En desarrollo se conserva `flutter run --dart-define-from-file=api_keys.json`.
Nunca usar ese archivo como asset ni subirlo a Git o al alojamiento estático.

## Validación real

Se usó un emulador Pixel API 35 con datos de prueba aislados y un backend TLS
local, accesible mediante adb reverse. El entry point independiente
`integration_test/release_video_probe.dart` se compiló con --release. No usa
fallback: consultó cada fuente e inicializó/reprodujo su primer video real,
comprobando avance de al menos 500 ms.

| Fuente | Videos consultados | Inicialización | Avance real |
| --- | ---: | --- | --- |
| Coverr | 8 | Correcta | Correcto |
| Pixabay | 8 | Correcta | Correcto |
| Internet Archive | 6 | Correcta | Correcto |
| Assets locales | 3 | Correcta | Correcto |

Resultados sanitizados: [release_api_verification.json](release_api_verification.json).
Esta prueba demuestra el pipeline y reproducción en release Android, no la
conectividad desde la infraestructura de Appetize ni todos los videos posibles.

El entry point de prueba acepta únicamente el certificado público exacto del
localhost de prueba. Está separado de lib y no se compila en el APK normal.
No subir `build/api-verification/release-video-probe.apk` a Appetize.
Los certificados se preparan con scripts/prepare_release_api_verification.py
(requiere cryptography) y caducan en un día; regenerarlos al repetir la prueba.

Pruebas automatizadas: flutter analyze, flutter test y
`node --test backend/server.test.mjs`. Compilación normal: flutter build apk
--release. Auditoría: `python scripts/audit_public_apk.py`; busca los valores
literales de las claves locales y api_keys.json entre todas las entradas del
APK. No es una certificación universal de ausencia de otros secretos.

Resultados de esta ejecución: analyze sin incidencias; 71 pruebas Flutter
aprobadas y dos de red optativas omitidas; siete pruebas del backend aprobadas.
El APK normal release se compiló (50,5 MB), se instaló y abrió en API 35
(am start: Status ok). La auditoría no encontró el JSON ni las claves locales.
Ese APK normal se compiló sin URL porque aún no existe backend público:
no debe confundirse con el APK final configurado para Appetize.

