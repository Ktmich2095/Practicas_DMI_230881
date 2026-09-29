# Chat de respuestas Sí/No - Flutter

## Descripción

Aplicación de chat desarrollada en **Flutter**. Permite enviar mensajes y recibir respuestas automáticas de **Sí**, **No** o **Tal vez**, acompañadas de un GIF.

Permite:

- Mostrar una conversación inicial.
- Enviar mensajes desde el campo de texto.
- Solicitar una respuesta automática al enviar una pregunta terminada en `?`.
- Mostrar la respuesta y el GIF devueltos por la API.
- Consultar la hora y la fecha de cada mensaje.
- Usar una interfaz con tonos morados y un avatar de perfil.

---

## Funcionamiento

La pantalla principal presenta una conversación de ejemplo. Al enviar un mensaje que termina en `?`, la aplicación consulta la API [yesno.wtf](https://yesno.wtf/api), agrega la respuesta al chat y muestra el GIF recibido.

Las respuestas de la API se presentan en español: `yes` como **Sí**, `no` como **No** y `maybe` como **Tal vez**. La aplicación usa **Provider** para actualizar la conversación y **Dio** para realizar la petición HTTP.

Se requiere conexión a internet para consultar la API y cargar las imágenes remotas.

### Ejecución

Desde la carpeta `Practica03/yes_no_app`, ejecuta:

```bash
flutter pub get
flutter run
```

---

## Evidencias


### Pantalla inicial del chat

![alt text](/Practica03/yes_no_app/img/image.png)

### Envío de un mensaje y respuesta automática con GIF

![alt text](/Practica03/yes_no_app/img/imageTwo.png)
![alt text](/Practica03/yes_no_app/img/imageThree.png)



---

## Resultado

Se obtuvo una aplicación de chat que permite enviar mensajes y recibir respuestas automáticas con GIF, con una interfaz en español y una paleta de tonos morados.
