# Primeros Pasos en Localización

Easydict usa el Catálogo de Cadenas de Xcode para gestionar traducciones, por lo que los siguientes pasos son lo que necesitas para comenzar a localizar la aplicación.

### Instalar Xcode 15+

Puedes instalar Xcode desde la [Mac App Store](https://apps.apple.com/app/xcode/id497799835) o sus versiones beta en [Apple Developer](https://developer.apple.com/xcode/resources/).

### Clonar y compilar el proyecto

1. Usa git para clonar el proyecto desde GitHub a tu Mac. Puedes hacerlo usando la [herramienta de línea de comandos git](https://docs.github.com/en/get-started/getting-started-with-git) o [GitHub Desktop](https://desktop.github.com).
2. Asegúrate de basar tus cambios en la rama [dev](https://github.com/tisfeng/Easydict/tree/dev); aquí es donde tiene lugar el trabajo de localización.
3. Abre el proyecto y complílalo. Puedes encontrar instrucciones detalladas sobre cómo compilar el proyecto [aquí](/README_EN.md#developer-build).

### Agregar tu idioma al Catálogo de Cadenas

¡Ahora puedes comenzar a agregar tu propio idioma!

1. Navega a `Easydict -> Easydict -> App -> Localizable.xcstrings`. También expande `Main.storyboard` para encontrar `Main.xcstrings (Cadenas)`. Estos dos archivos `.xcstrings` son en los que vas a trabajar.
2. Haz clic en el archivo `Localizable.xcstrings` y haz clic en el botón `+` para encontrar una lista de opciones disponibles. Si no ves el idioma que deseas localizar en la lista (por ejemplo, inglés canadiense), desplázate hasta el final del menú para encontrar `Más idiomas`.
3. Después de agregar un idioma, puedes comenzar a traducir. No olvides traducir las cadenas en `Main.xcstring (Cadenas)` 😉

### Previsualizar tus traducciones

Después de terminar tus traducciones, es bueno ejecutar la aplicación y revisar tu trabajo. Puedes configurar el idioma de la aplicación al que localizaste con unos sencillos clics.

1. Encuentra el ícono de Easydict en la barra de herramientas superior de Xcode y haz clic en él.
2. Haz clic en `Edit Scheme...` (Editar Esquema...)
3. Selecciona la pestaña `RUN` (EJECUTAR) en la barra lateral izquierda y ve a `Options` (Opciones)
4. Desplázate hacia abajo para encontrar `App Language` (Idioma de la aplicación) y luego elige el idioma que localizaste.
5. Cierra la pestaña y usa ⌘R para ejecutar la aplicación y ver tus traducciones.

### Enviar tus cambios a GitHub

Después de verificar tu localización, es hora de enviar los cambios a GitHub y comenzar una solicitud de extracción (pull request).

- [Iniciar una Solicitud de Extracción](https://docs.github.com/en/pull-requests).
- Recuerda establecer el objetivo de fusión en la rama `dev`

Ahora puedes esperar la revisión de un mantenedor y hacer que tus traducciones se adopten en la próxima versión.

### Recursos Adicionales

- [Localización - Apple Developer](https://developer.apple.com/documentation/Xcode/localization)
- [Localizar y variar texto con un catálogo de cadenas - Apple Developer](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Descubrir los Catálogos de Cadenas - Videos WWDC23](https://developer.apple.com/videos/play/wwdc2023/10155)
- [Glosarios de Localización de Apple](https://applelocalization.com)
- [Solicitud de Extracción de Ejemplo para Easydict](https://github.com/tisfeng/Easydict/pull/668)
