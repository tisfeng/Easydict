<p align="center">
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/icon_512x512@2x.png" height="256">
  <h1 align="center">Easydict</h1>
  <h4 align="center"> Búsqueda palabras o traduce texto fácilmente</h4>
<p align="center">
<a href="https://github.com/tisfeng/easydict/blob/main/LICENSE">
<img src="https://img.shields.io/github/license/tisfeng/easydict"
            alt="Licencia"></a>
<a href="https://github.com/tisfeng/Easydict/releases">
<img src="https://img.shields.io/github/downloads/tisfeng/easydict/total.svg"
            alt="Descargas"></a>
<a href="https://img.shields.io/badge/-macOS-black?&logo=apple&logoColor=white">
<img src="https://img.shields.io/badge/-macOS-black?&logo=apple&logoColor=white"
            alt="macOS"></a>
</p>

<div align="center">
<a href="./README_ZH.md">中文</a> &nbsp;&nbsp;|&nbsp;&nbsp; <a href="./README.md">English</a> &nbsp;&nbsp;|&nbsp;&nbsp; <a href="./readme-es.md">Español</a>
</div>

## Easydict

`Easydict` es una aplicación de diccionario y traducción para macOS, concisa y fácil de usar, que te permite buscar palabras o traducir texto de manera fácil y elegante.

Easydict está listo para usar desde el primer momento, puede reconocer automáticamente el idioma del texto de entrada, soporta traducción por entrada de texto, traducción por selección y traducción por captura de pantalla OCR, y puede consultar resultados de múltiples servicios de traducción al mismo tiempo.

**Servicios de traducción soportados:** [**🍎 Diccionario Apple**](./docs/es/how-to-use-macos-system-dictionary-in-easydict.md), [🍎 **Traducción Apple**](./docs/es/how-to-use-macos-system-translation-in-easydict.md), [OpenAI](https://chat.openai.com/), [Gemini](https://gemini.google.com/), [DeepSeek](https://www.deepseek.com/), [Ollama](https://ollama.com/), [Groq](https://groq.com/), [Zhipu AI](https://open.bigmodel.cn/), [GitHub Models](https://github.com/marketplace/models), [DeepL](https://www.deepl.com/translator), [Google](https://translate.google.com), [Youdao](https://www.youdao.com/), [Tencent](https://fanyi.qq.com/), [Bing](https://www.bing.com/translator), [Baidu](https://fanyi.baidu.com/), [Niutrans](https://niutrans.com/), [Caiyun](https://fanyi.caiyunapp.com/), [Alibaba](https://translate.alibaba.com/), [Volcano](https://translate.volcengine.com/translate) y [Doubao](https://www.volcengine.com/docs/82379/1820188).

![Log](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/Log-1688378715.png)

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.18-1685262784.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-05-28_16.32.26-1685262803.png">
</table>

![immerse-1686534718.gif](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/immerse-1686534718.gif)

## Características

- 🚀 Listo para usar, reconocimiento automático de idioma
- 🖱️ Selección automática con ratón y atajos de teclado
- 📸 Traducción por captura de pantalla OCR y OCR silencioso
- 🔊 Múltiples servicios de voz TTS
- 📚 Soporta 🍎 [Diccionario del Sistema Apple](./docs/es/how-to-use-macos-system-dictionary-in-easydict.md) y [Traducción del Sistema](./docs/es/how-to-use-macos-system-translation-in-easydict.md)
- 🌐 Soporta más de 20 servicios de traducción (OpenAI, Gemini, DeepL, Google, Ollama, Groq, etc.)
- 🗣️ Soporte para 48 idiomas

**Si te gusta esta aplicación, considera darle una [Star](https://github.com/tisfeng/Easydict) ⭐️, ¡gracias! (^-^)**

## Contribuir

Si estás interesado en este proyecto, agradecemos tus contribuciones. Nuestro desarrollo sigue este flujo de trabajo:

- **Rama dev**: Código de desarrollo más reciente, puede contener funciones en progreso
- **Rama main**: Código de lanzamiento estable, se fusiona regularmente desde la rama dev

Por favor envía correcciones de errores y funciones a la rama dev; para funciones nuevas importantes o cambios de UI, por favor abre un issue primero para discutir. Consulta la [guía completa de contribución](./docs/es/guide.md#guía-del-colaborador).

### Programación con IA

Recomendamos usar `Codex` para el desarrollo asistido por IA en Easydict, especialmente para exploración del código, diagnóstico de problemas, generación de parches y refactorización.

- Prefiere los modelos GPT más recientes disponibles, como `GPT-5.4`.
- Revisa cuidadosamente los cambios generados por IA antes de abrir un PR, y asegúrate de que el resultado coincida con el flujo de contribución y los estándares de código de este repositorio.

#### Asistente de Envío con IA

Este repositorio soporta `Codex` y `Claude` para la generación automática de mensajes de confirmación.

- Primero prepara tus cambios, luego ejecuta `/git-commit`.
- El comando genera un mensaje de confirmación en estilo Angular en inglés desde los cambios preparados y proporciona una vista previa en chino simplificado.
- No se crea ninguna confirmación hasta que apruebes explícitamente el mensaje generado.

## Notas sobre Clasificación de Issue/PR

El mantenedor ha estado bastante ocupado recientemente y generalmente solo tiene tiempo para clasificar issues los fines de semana. Los PR (especialmente los PR de correcciones de errores) tienen prioridad. Además, debido a una bandeja de entrada y notificaciones sobrecargadas, algunos mensajes pueden no ser vistos o respondidos prontamente. Gracias por tu comprensión.

## Instalación

### Instalación con Homebrew (Recomendado)

```bash
brew install --cask easydict
```

### Instalación Manual

[Descarga](https://github.com/tisfeng/Easydict/releases) el último lanzamiento.

> [!NOTE]
> La última versión soporta macOS 13.0+, para sistemas anteriores usa [2.7.2](https://github.com/tisfeng/Easydict/releases/tag/2.7.2)

---

## Uso

| Forma                        | Descripción                                                                                                                                          | Vista Previa                                                                                                                                   |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Traducción por entrada texto | Presiona el atajo de entrada (por defecto `⌥ + A`), ingresa el texto a traducir y presiona `Enter` para traducir                                     | ![iShot_2023-01-20_11.28.46-1674185354](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.28.46-1674185354.gif) |
| Traducción selección ratón   | El ícono de consulta se muestra automáticamente después de seleccionar la palabra, y al pasar el ratón consulta                                      | ![iShot_2023-01-20_11.01.35-1674183779](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.01.35-1674183779.gif) |
| Traducción selección atajo   | Después de seleccionar el texto a traducir, presiona el atajo (por defecto `⌥ + D`)                                                                  | ![iShot_2023-01-20_11.24.37-1674185125](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.24.37-1674185125.gif) |
| Traducción captura pantalla  | Presiona el atajo de captura de pantalla (por defecto `⌥ + S`) para capturar el área a traducir                                                      | ![iShot_2023-01-20_11.26.25-1674185209](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/iShot_2023-01-20_11.26.25-1674185209.gif) |
| OCR captura silenciosa       | Presiona el atajo de captura silenciosa (por defecto `⌥ + ⇧ + S`) para capturar el área, los resultados OCR se copiarán directamente al portapapeles | ![屏幕录制 2023-05-20 22 39 11](https://github.com/Jerry23011/Easydict/assets/89069957/c16f3c20-1748-411e-be04-11d8fe0e61af)                   |

---

## Documentación

- 📖 [Guía Completa de Uso](./docs/es/guide.md) - Funciones detalladas, configuración y consejos
- 🔧 [Guía de Compilación para Desarrolladores](./docs/es/guide.md#compilación-para-desarrolladores) - Compila y ejecuta desde el código fuente
- 🍎 [Cómo usar el Diccionario del Sistema macOS](./docs/es/how-to-use-macos-system-dictionary-in-easydict.md)
- 🍎 [Cómo usar la Traducción del Sistema macOS](./docs/es/how-to-use-macos-system-translation-in-easydict.md)
- 🌍 [Cómo traducir Easydict](./docs/es/how-to-translate-easydict.md)

---

## Agradecimientos

- Este proyecto fue inspirado por [saladict](https://github.com/crimx/ext-saladict) y [Bob](https://github.com/ripperhe/Bob), y la versión inicial se basó en [Bob (GPL-3.0)](https://github.com/1xiaocainiao/Bob). Easydict ha realizado muchas mejoras y optimizaciones en el proyecto original, y muchas funciones y UI se toman como referencia de Bob.
- La función de captura de pantalla se basa en [isee15](https://github.com/isee15)'s [Capture-Screen-For-Multi-Screens-On-Mac](https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac), y se optimizó en este proyecto.
- La función de selección de texto se tomó como referencia de [PopClip](https://pilotmoon.com/popclip/).

## Declaración

Easydict está licenciado bajo la licencia de código abierto [GPL-3.0](https://github.com/tisfeng/Easydict/blob/main/LICENSE), la cual es solo para aprendizaje y comunicación. Cualquier persona puede obtener este producto y código fuente de forma gratuita. Si crees que tus derechos legales han sido violados, por favor contacta al [autor](https://github.com/tisfeng) inmediatamente. Puedes usar el código fuente libremente, pero debes adjuntar la licencia y los derechos de autor correspondientes.

## Patrocinio

Easydict es un proyecto gratuito y de código abierto, actualmente desarrollado y mantenido principalmente por el autor. Si te gusta este proyecto y lo encuentras útil, puedes considerar patrocinar este proyecto para apoyarlo, para que pueda ir más lejos.

Gracias a [@CanglongCl](https://github.com/CanglongCl) por proporcionar la cuenta de desarrollador de Apple, lo que resolvió el [problema de firma](https://github.com/tisfeng/Easydict/issues/2) de la aplicación, permitiendo que más personas usen Easydict convenientemente.

<a href="https://afdian.com/a/tisfeng"><img width="20%" src="https://pic1.afdiancdn.com/static/img/welcome/button-sponsorme.jpg" alt=""></a>

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/IMG_4739-1684680971.JPG" width="30%">
</div>

Gracias a todos los patrocinadores por su generoso apoyo. Para más detalles, consulta la [Lista de Patrocinadores](./docs/es/sponsor-list.md).

---

## Historial de Stars

<a href="https://star-history.com/#tisfeng/easydict&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date" />
    <img alt="Gráfico de Historial de Stars" src="https://api.star-history.com/svg?repos=tisfeng/easydict&type=Date" />
  </picture>
</a>
