## Apple Dictionary


The built-in macOS dictionary offers excellent lookup functionality activated by force touch (or tapping with three fingers); sadly, this feature is not supported on all applications. Therefore, I want to integrate the lookup feature from Apple Dictionary into Easydict, providing a swift and convenient word search using the system dictionary.

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HHp1I2-1695911764.png" width="50%" />
</div>

Easydict supports built-in dictionaries within Dictionary.app, including dictionaries like the Oxford English-Chinese Dictionary (Simplified Chinese-English) and the Modern Chinese Standard Dictionary (Simplified Chinese). To utilize these dictionaries, simply activate them within Dictionary.app.

![image-20230928213750505](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928213750505-1695908270.png)



Furthermore, Apple Dictionary also supports custom import dictionaries. This means that we can add third-party dictionaries like the Concise English-Chinese Dictionary or the Longman Dictionary of Contemporary Advanced English by importing them in the .dictionary format.

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/cQmL6r-1695958154.png">
</table>

### Adding third-party dictionaries

> ⚠️ To alleviate concerns related to copyright, acquire your paperback copy or app.

The easiest way to add a dictionary to macOS is to find a converted .dictionary file, drag it into the Dictionary folder of Apple Dictionary, and then restart the Dicionary.app to ensure the new dictionary appears in the Settings.

Attention: Each time a new dictionary is added, Easydict needs to be restarted to see the changes in effect. Also, modifying the dictionary application settings may cause Easydict to crash; this is an expected behaviour.

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928224622274-1695912382.png
" width="50%" />
</div>

For your convenience, I've created several .dictionary files and put them on Google Drive, so you can directly download and use them.

Longman, Collins, and Oxford are three substantial yet outstanding dictionaries. However, due to the extensive content in their entries, they may impact the loading speed of Easydict queries. Therefore, it is advisable to select only one of your favourites.

|             Dictionary              | Type |                             Source                             |                  .dictionary 下载                   |
| :---------------------------: | ---- | :----------------------------------------------------------: | :-------------------------------------------------: |
|         Concise English-Chinese dictionary          | Chinese-English |       [GitHub](https://github.com/skywind3000/ECDICT)        | https://drive.google.com/file/d/1-RoulJykOmcADGRHSmUjX2SkwiyLTHP1/view?usp=sharing |
|         Youdao Words Analysis          | Chinese-English | [freemdict](https://downloads.freemdict.com/%E5%B0%9A%E6%9C%AA%E6%95%B4%E7%90%86/%E5%85%B1%E4%BA%AB2020.5.11/qwjs/39_%E6%9C%89%E9%81%93%E8%AF%8D%E8%AF%AD%E8%BE%A8%E6%9E%90/) | https://drive.google.com/file/d/1-HGanRhQDRR0OSMLb19or07lPwn_R0cn/view?usp=sharing |
|            Great Cictionary            | Chinese-English |           [mdict](https://mdict.org/post/dacihai/)           | https://drive.google.com/file/d/1-8cBLcuA_N4PAjIMn_-d03ELv4uVrmIr/view?usp=sharing |
|     Longman Dictionary of Contemporary Advanced English     | Chinese-English |            [v2ex](https://www.v2ex.com/t/907272)             | https://drive.google.com/file/d/1scunXbe2JppVuKxNvn2uOidTbAZpiktk/view?usp=sharing |
|      Collins Advanced English-Chinese Dictionary       | Chinese-English | [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries) | https://drive.google.com/file/d/1-KQmILchx71L2rFqhIZMtusIcemIlM01/view?usp=sharing |
| Oxford Advanced Learner's English-Chinese Dictionary (8th Edition) | Chinese-English |        [Jianshu](https://www.jianshu.com/p/e279d4a979fa)        | https://drive.google.com/file/d/1-N0kiXmfTHREcBtumAmNn4sUM5poyiC7/view?usp=sharing |
|   Oxford Advanced Learner's English-Chinese Dictionary (8)   | Chinese-English |    Source unknown, I modified the css myself     | https://drive.google.com/file/d/1-SigzdPPjQlycPwBHICgQSUOHpR8mMf7/view?usp=sharing |

### Concise English-Chinese dictionary

![image-20231001175045564](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001175045564-1696153845.png)

### Youdao Words Analysis

![image-20231001182349593](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001182349593-1696155829.png)

### Great Cictionary

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

I can't remember the source of this dictionary, but the point is that the css of this dictionary was tuned by myself when I was learning how to make dictionaries, and the internal `DefaultStyle.css` file has detailed annotations, so beginners who want to try to customize the interface of the dictionary can start from this css.

![image-20231001190542557](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001190542557-1696158342.png)

### How to make a .dictionary dictionary

>  Attention: This part of the doc is aimed at advanced users, who need a bit of programming knowledge and love to spend time on this.

Below is an introduction to how to use the open-source project [pyglossary](https://github.com/ilius/pyglossary) to convert Mdict dictionaries into .dictionary files. This doc is based on [pyglossary apple](https://github.com/ilius/pyglossary/blob/master/doc/apple.md).


### Preparations

1. Install Python library

```shell
sudo pip3 install lxml beautifulsoup4 html5lib
```

2. Install [Command Line Tools for Xcode](http://developer.apple.com/downloads)

3. Install Dictionary Development Kit

   Dictionary Development Kit is part of [Additional Tools for Xcode](http://developer.apple.com/downloads), after downloading, you need to move `Dictionary Development Kit` to`/Applications/Utilities/Dictionary Development Kit`.

4. Download [pyglossary](https://github.com/ilius/pyglossary)

   Please move the downloaded pyglossary library to a fixed directory, you will need it every time you convert a dictionary.

   Assuming that pyglossary-master is located at `~/Downloads/pyglossary-master`

Mdict dictionary resources are available from the following website:

- [freemdict](https://forum.freemdict.com/c/12-category/12)
- [mdict](https://mdict.org/)

Now let's begin.

### Steps of conversion

Suppose the dictionary file in Mdict format is located in `~/Downloads/oald8/oald8.mdx`, and the picture and speech file `oald8.mdd` are also in the same folder.

```shell
cd ~/Downloads/oald8/

python3 ~/Downloads/pyglossary-master/main.py --write-format=AppleDict oald8.mdx oald8-apple

cd oald8-apple

sed -i "" 's:src="/:src=":g' oald8-apple.xml

make
```

If all goes well, you will end up with an `objects` file in that directory, with `oald8-apple.dictionary` in it, which is the converted Apple dictionary, which you can drag into the Dictionary folder.

Note that the dictionary generated above has a very simple interface, and usually Mdicts circulating on the web will come with a copy of beautified css, such as `oald8.css`. Since pyglossary does not handle css automatically, we need to do it manually by copying the contents of `oald8.css` and appending it to the `DefaultStyle.css` inside the `oald8-apple.dictionary` file. If you want to customize the css, you also modify this file.

The name of the dictionary can be changed via `Info.plist`, where the `Bundle name` is the name of the dictionary to be displayed in the application interface, and the `Bundle display name` is the name of the dictionary to be displayed in the settings page. For convenience, it is recommended that both be set to the same value.

END.

![image-20231002184455216](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231002184455216-1696243495.png)

### References (Chinese)

- [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries)
- [Mdict to macOS Dictionary 转换笔记](https://kaihao.io/2018/mdict-to-macos-dictionary/)
