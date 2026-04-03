# Guía Completa de Uso de Easydict

> Este documento contiene descripciones detalladas de funciones, métodos de configuración y consejos de uso para Easydict.

## Tabla de Contenidos

- [Guía Completa de Uso de Easydict](#guía-completa-de-uso-de-easydict)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Lista Detallada de Funciones](#lista-detallada-de-funciones)
  - [Guía de Instalación](#guía-de-instalación)
    - [Instalación Manual](#instalación-manual)
    - [Homebrew](#homebrew)
    - [Compilación para Desarrolladores](#compilación-para-desarrolladores)
      - [Entorno de Compilación](#entorno-de-compilación)
  - [Instrucciones de Uso](#instrucciones-de-uso)
    - [Seleccionar Texto con el Ratón](#seleccionar-texto-con-el-ratón)
    - [Acerca de los Permisos](#acerca-de-los-permisos)
  - [Configuración de OCR](#configuración-de-ocr)
  - [Servicios TTS](#servicios-tts)
  - [Configuración de Servicios de Traducción](#configuración-de-servicios-de-traducción)
    - [🍎 Diccionario del Sistema Apple](#-diccionario-del-sistema-apple)
    - [Traducción OpenAI](#traducción-openai)
      - [Modo de Consulta OpenAI](#modo-de-consulta-openai)
    - [Traducción IA Integrada](#traducción-ia-integrada)
    - [Traducción Gemini](#traducción-gemini)
    - [Traducción DeepL](#traducción-deepl)
      - [Configurar punto de acceso API](#configurar-punto-de-acceso-api)
      - [Configurar método de llamada API](#configurar-método-de-llamada-api)
    - [Traducción Tencent](#traducción-tencent)
    - [Traducción Bing](#traducción-bing)
    - [Niutrans](#niutrans)
    - [Lingocloud](#lingocloud)
    - [Traducción Ali](#traducción-ali)
    - [Traducción Doubao](#traducción-doubao)
  - [Funciones Avanzadas](#funciones-avanzadas)
    - [Esquema URL](#esquema-url)
    - [Uso con PopClip](#uso-con-popclip)
  - [Configuración](#configuración)
    - [General](#general)
    - [Servicios](#servicios)
  - [Atajos dentro de la App](#atajos-dentro-de-la-app)
  - [Consejos](#consejos)
  - [Proyectos de Código Abierto Similares](#proyectos-de-código-abierto-similares)
  - [Motivación](#motivación)
  - [Guía del Colaborador](#guía-del-colaborador)
    - [Estructura de Ramas](#estructura-de-ramas)
    - [Directrices para Enviar PR](#directrices-para-enviar-pr)
    - [Participar en la Migración a Swift](#participar-en-la-migración-a-swift)

---

## Lista Detallada de Funciones

- [x] Listo para usar, busca palabras o traduce texto fácilmente.
- [x] Reconocimiento automático del idioma de entrada y consulta automática del idioma preferido de destino.
- [x] Traducción por selección automática, muestra automáticamente el ícono de consulta después de buscar palabras y consulta al pasar el ratón.
- [x] Soporte para configurar diferentes servicios para diferentes tipos de ventanas.
- [x] Soporte para modo de consulta inteligente.
- [x] Soporte para traducción por captura de pantalla del sistema OCR y OCR de captura silenciosa.
- [x] Soporte para TTS del sistema, junto con servicios en línea de Bing, Google, Youdao y Baidu Cloud.
- [x] Soporte para [🍎 Diccionario del Sistema Apple](./How-to-use-macOS-system-dictionary-in-Easydict.md), soporte para diccionarios de terceros con importación manual de diccionarios mdict.
- [x] Soporte para traducción del sistema macOS. (_Consulta [Cómo usar la traducción del sistema 🍎 macOS en Easydict](./How-to-use-macOS-system-translation-in-Easydict.md)_)
- [x] Soporte para Youdao Dictionary, DeepL, OpenAI, Gemini, DeepSeek, Google, Tencent, Bing, Baidu, Niutrans, Lingocloud, Ali, Volcano y Doubao Translate.
- [x] Soporte para 48 idiomas.

## Guía de Instalación

Puedes instalarlo usando uno de los siguientes dos métodos.

La última versión de Easydict requiere macOS 13.0+. Si la versión del sistema es macOS 11.0+, usa [2.7.2](https://github.com/tisfeng/Easydict/releases/tag/2.7.2).

### Instalación Manual

[Descarga](https://github.com/tisfeng/Easydict/releases) la última versión de la aplicación.

### Homebrew

Gracias a [BingoKingo](https://github.com/tisfeng/Easydict/issues/1#issuecomment-1445286763) por la versión de instalación inicial.

```bash
brew install --cask easydict
```

### Compilación para Desarrolladores

Si eres desarrollador, o si te interesa este proyecto, también puedes intentar compilarlo y ejecutarlo manualmente. Todo el proceso es muy simple, incluso sin conocimientos de desarrollo para macOS.

<details> <summary> Pasos de Compilación </summary>

<p>

1. Descarga este repositorio y luego abre el archivo `Easydict.xcworkspace` con [Xcode](https://developer.apple.com/xcode/) (⚠️⚠️⚠️ Ten en cuenta que NO es `Easydict.xcodeproj` ⚠️⚠️⚠️).
2. Usa `Cmd + R` para compilar y ejecutar.

![image-20231212125308372](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231212125308372-1702356789.png)

Los siguientes pasos son opcionales y están destinados solo para colaboradores de desarrollo.

Si a menudo necesitas depurar funciones relacionadas con permisos, como la captura de palabras o el OCR, puedes elegir ejecutarlo con tu propia cuenta de Apple, cambia `DEVELOPMENT_TEAM` en el archivo `Easydict-debug.xcconfig` a tu propio Apple Team ID (puedes encontrarlo iniciando sesión en el sitio web de desarrolladores de Apple) y `CODE_SIGN_IDENTITY` a Apple Development.

Ten cuidado de no confirmar el archivo `Easydict-debug.xcconfig`; puedes ignorar los cambios locales de este archivo con el siguiente comando git

```bash
git update-index --skip-worktree Easydict-debug.xcconfig
```

#### Entorno de Compilación

Xcode 13+, macOS Big Sur 11.3+. Para evitar problemas innecesarios, se recomienda usar la última versión de Xcode y macOS https://github.com/tisfeng/Easydict/issues/79

> [!NOTE]
> Dado que el código más reciente utiliza la función String Catalog, se requiere Xcode 15+ para compilar.
> Si tu versión de Xcode es inferior, usa la rama [xcode-14](https://github.com/tisfeng/Easydict/tree/xcode-14). Ten en cuenta que esta es una rama de versión fija y no se mantiene.

Si al ejecutar encuentras el siguiente error, intenta actualizar CocoaPods y luego `pod install`.

> [DT_TOOLCHAIN_DIR cannot be used to evaluate LD_RUNPATH_SEARCH_PATHS, use TOOLCHAIN_DIR instead](https://github.com/CocoaPods/CocoaPods/issues/12012)

</p>

</details>

## Instrucciones de Uso

Una vez lanzado Easydict, además de la ventana principal (oculta por defecto), habrá un ícono en el menú, y al hacer clic en la opción del menú se ejecutarán las acciones correspondientes, como sigue:

<div>
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/f0c7da85-b9e0-4003-b673-e93f6477a75b" width="50%" />
</div>

| Forma                        | Descripción                                                                                                                                  | Vista Previa                                                                                                                                  |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Traducción selección ratón   | El ícono de consulta se muestra automáticamente después de seleccionar la palabra, y al pasar el ratón consulta                            | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| Traducción selección atajo   | Después de seleccionar el texto a traducir, presiona el atajo (por defecto `⌥ + D`)                                                          | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| Traducción captura pantalla  | Presiona el atajo de captura de pantalla (por defecto `⌥ + S`) para capturar el área a traducir                                            | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| Traducción por entrada texto | Presiona el atajo de entrada (por defecto `⌥ + A`, o `⌥ + F`), ingresa el texto a traducir y presiona `Enter` para traducir                 | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |
| OCR captura silenciosa       | Presiona el atajo de captura silenciosa (por defecto `⌥ + ⇧ + S`) para capturar el área, los resultados OCR se copiarán directamente al portapapeles | ![屏幕录制 2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                    |

### Seleccionar Texto con el Ratón

Actualmente, se admiten múltiples métodos rápidos de selección de palabras con el ratón: doble clic para seleccionar, arrastrar para seleccionar, triple clic (párrafo) y selección con Shift (múltiples párrafos). En algunas aplicaciones, **la selección arrastrando** y **la selección con Shift** pueden fallar; en ese caso, puedes cambiar a otros métodos.

El atajo para seleccionar palabras puede funcionar normalmente en cualquier aplicación. Si encuentras una aplicación que no permite seleccionar palabras, puedes abrir un issue para resolverlo https://github.com/tisfeng/Easydict/issues/84

El flujo de la función de captura de palabras: Accesibilidad > AppleScript > atajos simulados, dando prioridad a la función secundaria de captura de Accesibilidad, y si la captura de Accesibilidad falla (no autorizado o no compatible con la aplicación), si es una aplicación de navegador (por ejemplo, Safari, Chrome), intentará usar AppleScript para la captura. Si la captura de AppleScript aún falla, entonces se realiza la captura final forzada: simulando el atajo Cmd+C para obtener la palabra.

Por lo tanto, se recomienda activar la opción "Permitir JavaScript en eventos Apple" en tu navegador para evitar el bloqueo de eventos en ciertas páginas web, como las que tienen [información de derechos de autor forzada](<(https://github.com/tisfeng/Easydict/issues/85)>), y optimizar la experiencia de captura de palabras.

Para usuarios de Safari, es altamente recomendable activar esta opción, ya que Safari no soporta la captura de Accesibilidad, y la captura de AppleScript es muy superior a simular atajos.

<div>
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/a1d8aa6b-69d7-459a-ac83-a6f090d04cae" width="45%">
    <img src="https://github.com/Jerry23011/Easydict/assets/89069957/4dbf038b-d939-454f-9205-648636f46ca8" width="45%">
</div>

### Acerca de los Permisos

1. `Traducción por selección` requiere `Accesibilidad Auxiliar`. La función de captura con el ratón solo solicita la aplicación de permisos de accesibilidad auxiliar cuando se usa por primera vez, y la función de traducción automática por captura solo puede usarse normalmente después de la autorización.

2. Para la Traducción por captura de pantalla, necesitas habilitar el permiso de `Grabación de Pantalla`. La aplicación solo mostrará automáticamente un cuadro de diálogo de solicitud de permiso cuando uses **Traducción por Captura de Pantalla** por primera vez. Si la autorización falla, debes activarla manualmente en la configuración del sistema.

## Configuración de OCR

Actualmente, solo se admite el OCR del sistema. Idiomas compatibles con OCR: chino simplificado, chino tradicional, inglés, japonés, coreano, francés, español, portugués, alemán, italiano, ruso, ucraniano.

## Servicios TTS

Actualmente se admiten TTS del sistema macOS, Bing, Google, Youdao y el servicio TTS en línea de Baidu.

- TTS del sistema: la opción más estable y confiable, pero no muy precisa. Se usa generalmente como opción de respaldo, es decir, se usa el TTS del sistema en lugar de otros TTS cuando ocurren errores.
- TTS de Bing: produce resultados óptimos generando síntesis de voz de red neuronal en tiempo real. Sin embargo, este proceso lleva más tiempo y la longitud del texto de entrada impacta directamente la duración de la generación. Actualmente, el límite máximo de caracteres soportado es de 2.000 caracteres, lo que equivale aproximadamente a 10 minutos de generación.
- TTS de Google: buenos resultados con inglés y la interfaz es estable. Sin embargo, solo puede generar hasta 200 caracteres a la vez.
- TTS de Youdao: el rendimiento general es encomiable con una interfaz estable y destaca en la pronunciación de palabras en inglés. Sin embargo, el límite máximo de caracteres es de 600 caracteres.
- TTS de Baidu: las oraciones en inglés se pronuncian bien con un acento distintivo, pero solo puede generar hasta unos 1.000 caracteres.

Por defecto, la aplicación usa el TTS de Youdao, pero los usuarios tienen la opción de seleccionar su servicio TTS preferido en la configuración.

Debido a su impresionante rendimiento con palabras en inglés, se recomienda el TTS de Youdao para ese contenido, mientras que el servicio TTS predeterminado permanece en uso para otros idiomas.

Cabe destacar que, aparte del TTS del sistema, todos los demás servicios TTS son interfaces no oficiales y pueden experimentar inestabilidades de vez en cuando.

## Configuración de Servicios de Traducción

### 🍎 Diccionario del Sistema Apple

Easydict se integra perfectamente con los diccionarios disponibles en la aplicación Diccionario de macOS, incluyendo opciones populares como el Diccionario Oxford Inglés-Chino-Chino-Inglés (Chino Simplificado-Inglés) y el Diccionario Estándar Chino Moderno (Chino Simplificado). Para usar estos diccionarios, simplemente actívalos a través de la página de configuración de la aplicación Diccionario.

Además, el Diccionario de Apple ofrece soporte para diccionarios personalizados, lo que te permite importar opciones de terceros como el Diccionario Conciso Inglés-Chino, el Longman Dictionary of Contemporary Advanced English y más. Estos se pueden agregar a tu sistema importando diccionarios en formato .dictionary.

Para información detallada, consulta [Cómo usar el diccionario del sistema macOS en Easydict](./How-to-use-macOS-system-dictionary-in-Easydict.md)

<table>
 		<td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HModYw-1696150530.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
</table>

### Traducción OpenAI

La versión 1.3.0 comienza a soportar la traducción OpenAI, que requiere una clave API de OpenAI.

Si no tienes tu propia clave API de OpenAI, puedes usar algunos proyectos de código abierto para convertir interfaces de LLM de terceros a interfaces estándar de OpenAI, para que puedas usarlas directamente en `Easydict`.

Por ejemplo, [one-api](https://github.com/songquanpeng/one-api), one-api es un buen proyecto de código abierto de gestión de interfaz de OpenAI, que soporta muchas interfaces de LLM, incluyendo Azure, Anthropic Claude, Google Gemini, ChatGLM, Baidu Wenxin, y más. ChatGLM, Baidu Wenxin Yiyin, Xunfei Starfire Cognition, Ali Tongyi Thousand Questions, 360 Intelligent Brain, Tencent Mixed Meta, Moonshot AI, Groq, Zero-One Everything, Step Star, DeepSeek, Cohere, etc., pueden usarse para la gestión de redistribución de claves, es un único archivo ejecutable, se ha empaquetado con una imagen Docker lista, implementación con un solo clic, lista para usar.

> [!IMPORTANT]
> La versión [2.6.0](https://github.com/tisfeng/Easydict/releases) implementa una nueva página de configuración de SwiftUI (compatible con macOS 13+), que permite configurar la clave API del servicio de forma gráfica. Otras versiones del sistema necesitan configurarse usando comandos en el campo de entrada de Easydict.

> [!TIP]
> Si el hardware de tu computadora lo permite, se recomienda actualizar al último sistema macOS para disfrutar de una mejor experiencia de usuario.

![](https://github.com/tisfeng/Easydict/assets/25194972/5b8f2785-b0ee-4a9e-bd41-1a9dd56b0231)

#### Modo de Consulta OpenAI

Actualmente, la traducción OpenAI admite tres modos de consulta: búsqueda de palabras, traducción de oraciones y traducción de texto largo. Todos están habilitados de forma predeterminada, aunque las palabras y oraciones se pueden deshabilitar.

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/2KIWfp-1695612945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/tCMiec-1695637289.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/qNk8ND-1695820293.png">
</table>

Un consejo rápido: si solo deseas excluir el análisis ocasional de oraciones sin desactivar el modo Oración, simplemente agrega una tilde (~) después de `[Oración]`. Esto lo convertirá en el modo Traducción.

<img width="475" alt="image" src="https://github.com/tisfeng/Easydict/assets/25194972/b8c2f0e3-a263-42fb-9cb0-efc68b8201c3">

### Traducción IA Integrada

Actualmente, algunos proveedores de servicios de LLM ofrecen modelos de IA gratuitos con restricciones, como [Groq](https://console.groq.com), [Google Gemini](https://aistudio.google.com/app/apikey), entre otros.

Para facilitar a los nuevos usuarios probar estas traducciones de IA de modelos grandes, hemos agregado un servicio de traducción de IA integrado, que se puede usar directamente sin necesidad de configurar la clave API.

Sin embargo, ten en cuenta que los modelos integrados tienen algunas limitaciones (principalmente en la cantidad gratuita). No garantizamos que puedan usarse de manera estable todo el tiempo, y recomendamos a los usuarios usar [AxonHub](https://github.com/looplj/axonhub) para construir su propio servicio de LLM.

![](https://github.com/tisfeng/Easydict/assets/25194972/6272d9aa-ddf1-47fb-be02-646ebf244248)

### Traducción Gemini ##

[Traducción Gemini](https://gemini.google.com/) requiere una clave API, que se puede obtener de forma gratuita en la [Consola](https://makersuite.google.com/app/apikey) oficial.

### Traducción DeepL

La API web gratuita de DeepL tiene un límite de frecuencia para una sola IP; el uso frecuente activará el error 429 "demasiadas solicitudes", por lo que la versión 1.3.0 agrega soporte para la API oficial de DeepL, pero la interfaz aún no se ha escrito y necesita habilitarse a través de comandos.

Si tienes DeepL AuthKey, se recomienda usar AuthKey personal para evitar límites de frecuencia y mejorar la experiencia del usuario. Si no, puedes usar el método de cambiar la IP del proxy para evitar el error 429.

> [!NOTE]
> Usar una nueva IP de proxy es una solución genérica que funciona para otros servicios con límites de frecuencia.

#### Configurar punto de acceso API

Si no tienes tu propio AuthKey y necesitas usar la traducción DeepL con frecuencia, puedes considerar implementar tu propio servicio de interfaz que soporte DeepL, o usar un servicio de terceros que soporte DeepL.

La forma de personalizar la URL de la API de DeepL es equivalente a la forma de la API AuthKey oficial de DeepL en Easydict.

Easydict soporta la API [DeepLX](https://github.com/OwO-Network/DeepLX), consulta [#464](https://github.com/tisfeng/Easydict/issues/464) para más detalles.

#### Configurar método de llamada API

1. La API web se usa de forma predeterminada, y el AuthKey personal se usará cuando la API web falle (si lo hay)

2. Usa AuthKey personal primero, y la API web cuando falle. Si usas DeepL con frecuencia, se recomienda usar este método, lo que puede reducir una solicitud fallida y mejorar la velocidad de respuesta.

3. Solo usar AuthKey personal

### Traducción Tencent

[Traducción Tencent](https://fanyi.qq.com/) requiere una APIKey. Para facilitar el uso, hemos incluido una clave integrada. Esta clave tiene un límite en la cantidad y no se garantiza que esté disponible todo el tiempo.

Se recomienda usar tu propia APIKey. Cada usuario registrado de Tencent Translate recibe 5 millones de caracteres de tráfico por mes, lo cual es suficiente para el uso diario.

### Traducción Bing

Actualmente, Bing Translator usa una interfaz web. Cuando encuentres un error 429 por activar los límites de frecuencia, puedes extender el uso configurando manualmente las cookies de la solicitud, además de cambiar proxies. La duración exacta de la extensión de tiempo actualmente no está clara.

Los pasos específicos son: usar el navegador para iniciar sesión en [Bing Translator](https://www.bing.com/translator), luego obtener la cookie en la consola ejecutando el siguiente comando:

```js
cookieStore.get("MUID").then(result => console.log(encodeURIComponent("MUID=" +result.value)));
```

> [!NOTE]
> Bing TTS también usa una API web, que también es fácil de activar restricciones de interfaz y no reporta errores. Por lo tanto, si configuras Bing como el TTS predeterminado, se recomienda configurar las cookies.

### Niutrans

[Niutrans](https://niutrans.com/) requiere una clave API. Para facilitar el uso, hemos incluido una clave integrada. Esta clave tiene un límite en la cantidad y no se garantiza que esté disponible todo el tiempo.

Se recomienda usar tu propia clave API. Cada usuario registrado de Niutrans recibe 200.000 caracteres de tráfico por día.

### Lingocloud

[Lingocloud](https://fanyi.caiyunapp.com/#/) necesita un Token. Para facilitar el uso, hemos incluido un token integrado. Este token tiene un límite en la cantidad y no se garantiza que esté disponible todo el tiempo.

Se recomienda usar tu propio Token. Cada usuario registrado de Lingocloud recibe 100.000 caracteres de tráfico por día.

### Traducción Ali
[Traducción Ali](https://translate.alibaba.com/) requiere una clave API. Para facilitar el uso, hemos incluido una clave integrada. Esta clave tiene un límite en la cantidad y no se garantiza que esté disponible todo el tiempo.

Se recomienda usar tu propia clave API. Cada usuario registrado de Ali Translate recibe 100.000 caracteres de tráfico por día.

### Traducción Doubao

[Traducción Doubao](https://www.volcengine.com/docs/82379/1820188) requiere una clave API, que se puede solicitar en la [Plataforma Volcano Ark](https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey).

Se recomienda usar tu propia clave API. Cada usuario registrado recibe 500.000 caracteres de traducción gratuitos.

## Funciones Avanzadas

### Esquema URL

Easydict soporta consultas rápidas para esquema URL: `easydict://query?text=xxx`, como `easydict://query?text=good`.

Si el contenido de consulta xxx contiene caracteres especiales, se necesita codificación URL, como `easydict://query?text=good%20girl`.

> [!WARNING]
> La versión antigua de easydict://xxx puede causar problemas en algunos escenarios, por lo que se recomienda usar el Esquema URL completo:
> easydict://query?text=xxx

### Uso con PopClip

Necesitas instalar [PopClip](https://pilotmoon.com/popclip/) primero, luego selecciona el siguiente bloque de código. `PopClip` mostrará "Instalar Extensión Easydict"; solo haz clic en ella.

```applescript
-- #popclip
-- name: Easydict
-- icon: iconify:ri:translate
-- language: applescript
tell application "Easydict"
  launch
  open location "easydict://query?text={popclip text}"
end tell
```

![image-20231215193814591](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231215193814591-1702640294.png)

> Referencia: https://www.popclip.app/dev/applescript-actions

## Configuración

La página de configuración proporciona algunas modificaciones de preferencias, como reproducir automáticamente la pronunciación de palabras después de activar una consulta, modificar los atajos de traducción, activar o desactivar servicios, o ajustar el orden de los servicios, etc.

### General

<img width="1036" alt="Preferencias" src="https://github.com/Jerry23011/Easydict/assets/89069957/7d63ad8e-927f-44e2-bc14-9d2199a927e4">

### Servicios

Easydict tiene 3 tipos de ventanas y puedes configurar diferentes servicios para cada una de ellas.

- Ventana mini: se muestra cuando el ratón recoge automáticamente palabras.
- Ventana flotante: se muestra cuando se usan atajos para buscar palabras y traducción por captura de pantalla.
- Ventana principal: oculta por defecto; puedes activarla en la configuración y mostrarla cuando se inicia el programa.

## Atajos dentro de la App

Easydict tiene algunos atajos dentro de la app para ayudarte a usarlo de manera más eficiente.

A diferencia de los atajos de traducción que son efectivos globalmente, los siguientes atajos solo funcionan cuando la ventana de Easydict está en primer plano.

<div style="display: flex; justify-content: space-between;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Mlw8ty-1681955887.png" width="50%">
</div>

- `Enter`: Después de ingresar el texto, presiona Enter para iniciar la consulta.
- `Shift + Enter`: Ingresa una nueva línea.
- `Cmd + ,`: Abre la página de configuración.
- `Cmd + Q`: Sale de la aplicación.
- `Cmd + K`: Borra el texto ingresado.
- `Cmd + Shift + K`: Borra el campo de entrada y los resultados de la consulta, igual que hacer clic en el botón de borrar en la esquina inferior derecha del texto ingresado.
- `Cmd + I`: Enfoca el campo de entrada de texto.
- `Cmd + Shift + C`: Copia el texto de consulta.
- `Cmd + S`: Reproduce la pronunciación del texto de consulta.
- `Cmd + R`: Consulta de nuevo.
- `Cmd + T`: Cambia el idioma de traducción.
- `Cmd + P`: Fija la ventana.
- `Cmd + W`: Cierra la ventana.
- `Cmd + Enter`: De forma predeterminada, se abre el motor de búsqueda Google, y el contenido a buscar es el texto ingresado, lo que equivale a hacer clic manualmente en el ícono de búsqueda del navegador en la esquina superior derecha.
- `Cmd + Shift + Enter`: Si la aplicación Eudic está instalada en la computadora, se mostrará un ícono de Eudic a la izquierda del ícono de Google, y la acción es abrir la aplicación Eudic para consultar.

## Consejos

Mientras la ventana de consulta esté activada, puedes abrir la página de configuración con el atajo `Cmd + ,`. Si ocultas el ícono de la barra de menús, puedes volver a abrirlo de esta manera.

<div style="display:flex;align-items:center;">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/584bb1b3-6ddd-4af8-a8b5-fc491a21605c" style="margin-right:50px;" width="40%">
  <img src="https://github.com/Jerry23011/Easydict/assets/89069957/9f9d99c3-ca07-48dd-9892-ac7fe595a981" width="30%">
</div>

Si descubres que el resultado de OCR es incorrecto, puedes corregir el resultado haciendo clic en el botón "Detectado xxx" para especificar el idioma de reconocimiento.

<div style="display:flex;align-items:flex-start;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230927000130422-1695744090.png" width="30%" style="margin-right:50px;">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/2O7y3w-1695821564.png" width="45%">
</div>

## Proyectos de Código Abierto Similares

- [Bob](https://github.com/ripperhe/Bob) - Una excelente aplicación de traducción y diccionario para macOS. Easydict se inspiró principalmente en Bob.
- [OpenCC](https://github.com/BYVoid/OpenCC) - Conversión de chino simplificado a tradicional.
- [Saladict](https://github.com/crimx/ext-saladict) - Extensión de diccionario para navegadores.

## Motivación

Bob es una excelente aplicación, pero ya no se mantiene. Al mismo tiempo, hay muchas aplicaciones de traducción y diccionario en macOS, pero la mayoría de ellas requieren suscripción o son demasiado complicadas de usar. Quiero una aplicación de traducción y diccionario simple, bonita, gratuita y de código abierto.

Easydict es una aplicación de traducción y diccionario simple, bonita, gratuita y de código abierto, construida con SwiftUI y AppKit, y usa Xcode String Catalog para gestionar traducciones. ¡Espero que te guste!

## Guía del Colaborador

¡Bienvenido a contribuir a Easydict!

### Estructura de Ramas

- `main`: Rama de lanzamiento estable, solo acepta solicitudes de PR para nuevas versiones.
- `dev`: Rama de desarrollo, acepta todo tipo de solicitudes de PR.

### Directrices para Enviar PR

1. Haz fork del repositorio y crea una rama desde `dev`.
2. Realiza tus cambios y confirma que el proyecto puede compilarse y ejecutarse normalmente.
3. Envía un PR a la rama `dev` con una descripción clara de los cambios realizados y el motivo.
4. Espera la revisión del mantenedor y realiza modificaciones según sea necesario.
5. Una vez fusionado, tu contribución se incluirá en la próxima versión.

### Participar en la Migración a Swift

Actualmente, Easydict se está migrando gradualmente de Objective-C a Swift. Si quieres participar en el trabajo de migración, consulta la rama [xcode-14](https://github.com/tisfeng/Easydict/tree/xcode-14). El trabajo de migración es muy bienvenido, y cada migración exitosa será reconocida en los registros de confirmación y notas de versión.
