## Diccionario de Apple


El diccionario integrado de macOS ofrece una excelente función de búsqueda activada por toque forzado (o tocando con tres dedos); lamentablemente, esta función no es compatible con todas las aplicaciones. Por lo tanto, quiero integrar la función de búsqueda del Diccionario de Apple en Easydict, proporcionando una búsqueda de palabras rápida y conveniente usando el diccionario del sistema.

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HHp1I2-1695911764.png" width="50%" />
</div>

Easydict soporta diccionarios integrados en la aplicación Diccionario, incluyendo diccionarios como el Diccionario Oxford Inglés-Chino (Chino Simplificado-Inglés) y el Diccionario Estándar Chino Moderno (Chino Simplificado). Para utilizar estos diccionarios, simplemente actívalos dentro de la aplicación Diccionario.

![image-20230928213750505](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928213750505-1695908270.png)



Además, el Diccionario de Apple también soporta la importación personalizada de diccionarios. Esto significa que podemos agregar diccionarios de terceros como el Diccionario Conciso Inglés-Chino o el Longman Dictionary of Contemporary Advanced English importándolos en formato .dictionary.

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/cQmL6r-1695958154.png">
</table>

### Agregar diccionarios de terceros

> ⚠️ Para aliviar las preocupaciones relacionadas con los derechos de autor, adquiere tu copia impresa o aplicación.

La forma más fácil de agregar un diccionario a macOS es encontrar un archivo .dictionary convertido, arrastrarlo a la carpeta Dictionary del Diccionario de Apple y luego reiniciar la aplicación Diccionario para asegurarte de que el nuevo diccionario aparezca en la Configuración.

Ingresa al directorio [Carpeta Diccionario]: `cd ~/Library/Dictionaries/`; abre `.` y también puedes abrirlo a través de la aplicación Diccionario "Archivo -> Abrir Carpeta Diccionario".

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928224622274-1695912382.png" width="50%" />
</div>

Arrastra el diccionario .dictionary descargado a la carpeta de diccionarios. Como se muestra en la siguiente figura, se han agregado dos diccionarios personalizados.

![dictionary](https://ik.imagekit.io/tonngw/R8ndZGr6G2DVtzfpWaaSZMNGp266dROWbmIbVni5d9A.png)

Después de abrir EasyDict, el diccionario recién agregado se coloca en la parte inferior de forma predeterminada. Abre el Diccionario de Apple, presiona `Cmd + ,` para entrar en la página de configuración. Puedes arrastrar y ajustar el orden de los diccionarios instalados para colocarlo en la parte superior. Otros diccionarios no utilizados se pueden desactivar para mantener una página limpia.

![dictionary_settins](https://ik.imagekit.io/tonngw/IT8GgH9HQFG9oDwYKivxCOzVX0IvMvhhiUS9Gvh0fBo.png)

Atención: Cada vez que se agrega un nuevo diccionario, Easydict necesita reiniciarse para ver los cambios. Además, modificar la configuración de la aplicación de diccionario puede causar que Easydict se cierre inesperadamente; este es un comportamiento esperado.

Para tu conveniencia, he creado varios archivos .dictionary y los he puesto en Google Drive, para que puedas descargarlos y usarlos directamente.

Longman, Collins y Oxford son tres diccionarios sustanciales y excelentes. Sin embargo, debido al extenso contenido en sus entradas, pueden afectar la velocidad de carga de las consultas de Easydict. Por lo tanto, se aconseja seleccionar solo uno de tus favoritos.

|             Diccionario              | Tipo |                             Fuente                             |                  Descarga .dictionary                   |
| :---------------------------: | ---- | :----------------------------------------------------------: | :-------------------------------------------------: |
|         Diccionario Conciso Inglés-Chino          | Chino-Inglés |       [GitHub](https://github.com/skywind3000/ECDICT)        | https://drive.google.com/file/d/1-RoulJykOmcADGRHSmUjX2SkwiyLTHP1/view?usp=sharing |
|         Análisis de Palabras Youdao          | Chino-Inglés | [freemdict](https://downloads.freemdict.com/%E5%B0%9A%E6%9C%AA%E6%95%B4%E7%90%86/%E5%85%B1%E4%BA%AB2020.5.11/qwjs/39_%E6%9C%89%E9%81%93%E8%AF%8D%E8%AF%AD%E8%BE%A8%E6%9E%90/) | https://drive.google.com/file/d/1-HGanRhQDRR0OSMLb19or07lPwn_R0cn/view?usp=sharing |
|            Gran Diccionario C            | Chino-Inglés |           [mdict](https://mdict.org/post/dacihai/)           | https://drive.google.com/file/d/1-8cBLcuA_N4PAjIMn_-d03ELv4uVrmIr/view?usp=sharing |
|     Longman Dictionary of Contemporary Advanced English     | Chino-Inglés |            [v2ex](https://www.v2ex.com/t/907272)             | https://drive.google.com/file/d/1scunXbe2JppVuKxNvn2uOidTbAZpiktk/view?usp=sharing |
|      Collins Advanced English-Chinese Dictionary       | Chino-Inglés | [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries) | https://drive.google.com/file/d/1-KQmILchx71L2rFqhIZMtusIcemIlM01/view?usp=sharing |
| Oxford Advanced Learner's English-Chinese Dictionary (8th Edition) | Chino-Inglés |        [Jianshu](https://www.jianshu.com/p/e279d4a979fa)        | https://drive.google.com/file/d/1-N0kiXmfTHREcBtumAmNn4sUM5poyiC7/view?usp=sharing |
|   Oxford Advanced Learner's English-Chinese Dictionary (8)   | Chino-Inglés |    Fuente desconocida, yo mismo modifiqué el css     | https://drive.google.com/file/d/1-SigzdPPjQlycPwBHICgQSUOHpR8mMf7/view?usp=sharing |

### Diccionario Conciso Inglés-Chino

![image-20231001175045564](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001175045564-1696153845.png)

### Análisis de Palabras Youdao

![image-20231001182349593](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001182349593-1696155829.png)

### Gran Diccionario C

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001215418606-1696168458.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/aQ8tkW-1696168533.png">
</table>

### Longman Dictionary of Contemporary Advanced English

![image-20231001184055245](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001184055245-1696156855.png)

### Collins Advanced English-Chinese Dictionary

![image-20231001184454574](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001184454574-1696157094.png)

### Oxford Advanced Learner's English-Chinese Dictionary (8th Edition)

![image-20231001185812289](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001185812289-1696157892.png)

### Oxford Advanced Learner's English-Chinese Dictionary (8)

No recuerdo la fuente de este diccionario, pero el punto es que el css de este diccionario fue ajustado por mí mismo cuando estaba aprendiendo a hacer diccionarios, y el archivo `DefaultStyle.css` interno tiene anotaciones detalladas, por lo que los principiantes que quieran intentar personalizar la interfaz del diccionario pueden comenzar desde este css.

![image-20231001190542557](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001190542557-1696158342.png)

### Cómo hacer un diccionario .dictionary

> Atención: Esta parte del documento está dirigida a usuarios avanzados, quienes necesitan un poco de conocimientos de programación y les gusta pasar tiempo en esto.

A continuación se presenta una introducción sobre cómo usar el proyecto de código abierto [pyglossary](https://github.com/ilius/pyglossary) para convertir diccionarios Mdict en archivos .dictionary. Este documento se basa en [pyglossary apple](https://github.com/ilius/pyglossary/blob/master/doc/apple.md).


### Preparativos

1. Instalar la biblioteca de Python

```shell
sudo pip3 install lxml beautifulsoup4 html5lib
```

2. Instalar [Command Line Tools for Xcode](http://developer.apple.com/downloads)

3. Instalar Dictionary Development Kit

   Dictionary Development Kit es parte de [Additional Tools for Xcode](http://developer.apple.com/downloads). Después de descargarlo, debes mover `Dictionary Development Kit` a `/Applications/Utilities/Dictionary Development Kit`.

4. Descargar [pyglossary](https://github.com/ilius/pyglossary)

   Por favor, mueve la biblioteca pyglossary descargada a un directorio fijo; lo necesitarás cada vez que conviertas un diccionario.

   Suponiendo que pyglossary-master está ubicado en `~/Downloads/pyglossary-master`

Los recursos de diccionarios Mdict están disponibles en los siguientes sitios web:

- [freemdict](https://forum.freemdict.com/c/12-category/12)
- [mdict](https://mdict.org/)

Ahora comenzamos.

### Pasos de conversión

Supongamos que el archivo de diccionario en formato Mdict está ubicado en `~/Downloads/oald8/oald8.mdx`, y el archivo de imagen y voz `oald8.mdd` también está en la misma carpeta.

```shell
cd ~/Downloads/oald8/

python3 ~/Downloads/pyglossary-master/main.py --write-format=AppleDict oald8.mdx oald8-apple

cd oald8-apple

sed -i "" 's:src="/:src=":g' oald8-apple.xml

make
```

Si todo sale bien, terminarás con un archivo `objects` en ese directorio, con `oald8-apple.dictionary` dentro, que es el diccionario Apple convertido, el cual puedes arrastrar a la carpeta Dictionary.

Ten en cuenta que el diccionario generado arriba tiene una interfaz muy simple, y generalmente los Mdicts que circulan en la web vendrán con una copia de css embellecido, como `oald8.css`. Dado que pyglossary no maneja css automáticamente, necesitamos hacerlo manualmente copiando el contenido de `oald8.css` y agregándolo al final del archivo `DefaultStyle.css` dentro del archivo `oald8-apple.dictionary`. Si deseas personalizar el css, también debes modificar este archivo.

El nombre del diccionario se puede cambiar a través de `Info.plist`, donde `Bundle name` es el nombre del diccionario que se mostrará en la interfaz de la aplicación, y `Bundle display name` es el nombre del diccionario que se mostrará en la página de configuración. Por conveniencia, se recomienda que ambos se configuren con el mismo valor.

FIN.

![image-20231002184455216](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231002184455216-1696243495.png)

### Referencias (Chino)

- [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries)
- [Mdict to macOS Dictionary 转换笔记](https://kaihao.io/2018/mdict-to-macos-dictionary/)
