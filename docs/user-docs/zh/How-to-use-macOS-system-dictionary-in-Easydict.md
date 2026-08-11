## 苹果系统词典


macOS 词典的用力点按查询（或三指查询）功能很好用，但可惜不是每个应用都支持，因此我想把查询苹果词典的功能带到 Easydict 上，让所有应用都能够便捷地使用系统词典查询单词。

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/HHp1I2-1695911764.png" width="50%" />
</div>

Easydict 自动支持词典 App 中系统自带的词典，如牛津英汉汉英词典（简体中文-英语），现代汉语规范词典（简体中文）等，只需在词典 App 设置页启用相应的词典即可。

![image-20230928213750505](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928213750505-1695908270.png)



另外，苹果词典也支持自定义导入词典，因此我们可以通过导入 .dictionary 格式的词典来添加第三方词典，如简明英汉字典，朗文当代高级英语辞典等。

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231225548-1695913945.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928231345494-1695914025.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/cQmL6r-1695958154.png">
</table>

### 如何添加第三方词典

> ⚠️ 需自购纸书或 App，以缓解版权不安。

最简单的添加方式，就是找寻已转换好格式的 .dictionary 词典，将其拖入到 Dictionary 的【词典文件夹】，再重启词典 App，就可以在设置中看到这部词典了。

进入【词典文件夹】目录：`cd ~/Library/Dictionaries/; open .`，也可以通过词典 App 「文件 -> 打开词典文件夹」打开。
<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928224622274-1695912382.png" width="50%" />
</div>

将下载的 .dictionary 词典拖入到词典文件夹，如下图所示添加了两个自定义词典

![dictionary](https://ik.imagekit.io/tonngw/R8ndZGr6G2DVtzfpWaaSZMNGp266dROWbmIbVni5d9A.png)

打开 EasyDict 之后默认新添加的词典是放在最下面的，打开苹果词典，`Command + ,` 进入设置页面，可以拖动调整一下安装的词典顺序把它放到最上面，其他不使用的词典可以全部关掉，保留一个清爽的页面。

![dictionary_settins](https://ik.imagekit.io/tonngw/IT8GgH9HQFG9oDwYKivxCOzVX0IvMvhhiUS9Gvh0fBo.png)

注意：每次添加新词典后，需要重启 Easydict 才能在 Easydict 中看到该词典。另外，修改词典应用设置时，可能会导致 Easydict 崩溃，这是 feature。

为方便大家使用，我已经制作了几部 .dictionary 词典，放在 Google 云盘上，直接下载即可用。

朗文、柯林斯和牛津，这三本大块头词典都很好，但由于词条内容实在太过丰富，可能会影响 Easydict 查询加载速度，因此建议选择其中一本自己喜欢的就好。

|             词典              | 类型 |                             来源                             |                       .dictionary 下载                       |
| :---------------------------: | ---- | :----------------------------------------------------------: | :----------------------------------------------------------: |
|         简明英汉字典          | 中英 |       [GitHub](https://github.com/skywind3000/ECDICT)        | https://drive.google.com/file/d/1-RoulJykOmcADGRHSmUjX2SkwiyLTHP1/view?usp=sharing |
|         有道词语辨析          | 中英 | [freemdict](https://downloads.freemdict.com/%E5%B0%9A%E6%9C%AA%E6%95%B4%E7%90%86/%E5%85%B1%E4%BA%AB2020.5.11/qwjs/39_%E6%9C%89%E9%81%93%E8%AF%8D%E8%AF%AD%E8%BE%A8%E6%9E%90/) | https://drive.google.com/file/d/1-HGanRhQDRR0OSMLb19or07lPwn_R0cn/view?usp=sharing |
|            大辞海             | 中文 |           [mdict](https://mdict.org/post/dacihai/)           | https://drive.google.com/file/d/1-8cBLcuA_N4PAjIMn_-d03ELv4uVrmIr/view?usp=sharing |
|     朗文当代高级英语辞典      | 中英 |            [v2ex](https://www.v2ex.com/t/907272)             | https://drive.google.com/file/d/1scunXbe2JppVuKxNvn2uOidTbAZpiktk/view?usp=sharing |
|      柯林斯高阶英汉双解       | 中英 | [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries) | https://drive.google.com/file/d/1-KQmILchx71L2rFqhIZMtusIcemIlM01/view?usp=sharing |
| 牛津高阶英汉双解词典（第 8 版） | 中英 |        [简书](https://www.jianshu.com/p/e279d4a979fa)        | https://drive.google.com/file/d/1-N0kiXmfTHREcBtumAmNn4sUM5poyiC7/view?usp=sharing |
|   牛津高阶英汉双解词典（8）   | 中英 |                  来源不详，我自己修改的 css                  | https://drive.google.com/file/d/1-SigzdPPjQlycPwBHICgQSUOHpR8mMf7/view?usp=sharing |

### 简明英汉字典

![image-20231001175045564](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001175045564-1696153845.png)

### 有道词语辨析

![image-20231001182349593](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001182349593-1696155829.png)

### 大辞海

<table>
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001215418606-1696168458.png">
    <td> <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/aQ8tkW-1696168533.png">
</table>

### 朗文当代高级英语辞典

![image-20231001184055245](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001184055245-1696156855.png)

### 柯林斯英汉双解

![image-20231001184454574](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001184454574-1696157094.png)

### 牛津高阶英汉双解词典（第 8 版）

![image-20231001185812289](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001185812289-1696157892.png)

### 牛津高阶英汉双解词典（8）

这部词典的来源记不清了，重点是该词典的 css 是我之前学习制作字典时自己调的，内部 `DefaultStyle.css` 有详细注释，初学者如果想尝试自定义、美化词典界面，可以从这个 css 开始。

![image-20231001190542557](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001190542557-1696158342.png)

### 如何制作 .dictionary 词典

>  注意：这部份教程主要面向进阶用户，需要一点编程知识和折腾精神。

下面介绍一下如何借助开源项目 [pyglossary](https://github.com/ilius/pyglossary) 将 Mdict 词典转换为 .dictionary 词典，文档主要参考自 [pyglossary apple](https://github.com/ilius/pyglossary/blob/master/doc/apple.md)。


### 准备工作

1. 安装 Python 库

```shell
sudo pip3 install lxml beautifulsoup4 html5lib
```

2. 安装 Xcode 的命令行工具 [Command Line Tools for Xcode](http://developer.apple.com/downloads)

3. 安装 Dictionary Development Kit

   Dictionary Development Kit 是 [Additional Tools for Xcode](http://developer.apple.com/downloads) Xcode 开发工具的一部分，下载后，需要将 `Dictionary Development Kit` 移动到 `/Applications/Utilities/Dictionary Development Kit` 位置。

4. 下载 [pyglossary](https://github.com/ilius/pyglossary)

   请将下载的 pyglossary 库移动到一个固定目录，后面每次转换词典都需要用上它。

   假设 pyglossary-master 位于 `~/Downloads/pyglossary-master`

Mdict 词典资源可从下面网站获取：

- [freemdict](https://forum.freemdict.com/c/12-category/12)
- [mdict](https://mdict.org/)

准备工作已完成，下面开始进入正题。

### 转换步骤

假设 Mdict 格式的词典文件位于 `~/Downloads/oald8/oald8.mdx`, 图片、语音文件 `oald8.mdd` 也在同一文件夹下。

```shell
cd ~/Downloads/oald8/

python3 ~/Downloads/pyglossary-master/main.py --write-format=AppleDict oald8.mdx oald8-apple

cd oald8-apple

sed -i "" 's:src="/:src=":g' oald8-apple.xml

make
```

如果一切顺利，最后会在该目录下生成一个 `objects` 文件，里面的 `oald8-apple.dictionary` 就是转换后的苹果格式词典，将其拖入到 Dictionary 的【词典文件夹】就可以了。

注意，上面生成的词典，界面非常简陋，而通常流传于网上的 Mdict 都会带一份美化 css，例如 `oald8.css`，由于 pyglossary 并不会自动处理 css，因此这一步需要我们手动完成，具体步骤是将 `oald8.css` 中的内容复制，追加到 `oald8-apple.dictionary` 内部的 `DefaultStyle.css`。如果想自定义 css，同样也是修改这个文件。

词典的名字可通过 `Info.plist` 修改，其中 `Bundle name` 是词典在应用界面中显示的名字，`Bundle display name` 是词典在设置页中显示的名字。为使用方便，建议两者设置为同一个值。

（完）。

![image-20231002184455216](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231002184455216-1696243495.png)

### 参考

- [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries)
- [Mdict to macOS Dictionary 转换笔记](https://kaihao.io/2018/mdict-to-macos-dictionary/)
