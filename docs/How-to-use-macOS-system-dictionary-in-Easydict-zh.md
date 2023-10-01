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

<div>
  <img src="https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20230928224622274-1695912382.png
" width="50%" />
</div>
为方便大家使用，我已经制作了几部 .dictionary 词典，放在天翼云盘上，直接下载即可用。

对于朗文、柯林斯和牛津，这三本大块头词典都很好，但由于内容实在太过丰富，可能会影响 Easydict 查询加载速度，因此建议选择一本自己喜欢的就好。

|             词典              | 类型 |                             来源                             |                  .dictionary 下载                   |
| :---------------------------: | ---- | :----------------------------------------------------------: | :-------------------------------------------------: |
|         简明英汉字典          | 中英 |       [GitHub](https://github.com/skywind3000/ECDICT)        | https://cloud.189.cn/t/aIFRNnBF7j6v（访问码：3b2r） |
|         有道词语辨析          | 中英 | [freemdict](https://downloads.freemdict.com/%E5%B0%9A%E6%9C%AA%E6%95%B4%E7%90%86/%E5%85%B1%E4%BA%AB2020.5.11/qwjs/39_%E6%9C%89%E9%81%93%E8%AF%8D%E8%AF%AD%E8%BE%A8%E6%9E%90/) | https://cloud.189.cn/t/f6NFBbBrU7ba（访问码：sgl5） |
|            大辞海             | 中文 |           [mdict](https://mdict.org/post/dacihai/)           | https://cloud.189.cn/t/nuuuYriMfiqi（访问码：yvi2） |
|     朗文当代高级英语辞典      | 中英 |            [v2ex](https://www.v2ex.com/t/907272)             | https://cloud.189.cn/t/2EZ7javyIZr2（访问码：vlm3） |
|      柯林斯高阶英汉双解       | 中英 | [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries) | https://cloud.189.cn/t/yyyUvmzQzIr2（访问码：j3kf） |
| 牛津高阶英汉双解词典（第8版） | 中英 |        [简书](https://www.jianshu.com/p/e279d4a979fa)        | https://cloud.189.cn/t/7FNnYjf2qeuy（访问码：1hlz） |
|   牛津高阶英汉双解词典（8）   | 中英 |                 来源不详，css 是我自己修改的                 | https://cloud.189.cn/t/7FVn6f6Vf2yq（访问码：ebd6） |

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

### 牛津高阶英汉双解词典（第8版）

![image-20231001185812289](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001185812289-1696157892.png)

### 牛津高阶英汉双解词典（8）

词典的来源记不清了，这个 css 是我之前学习制作字典时自己调的，内部 `DefaultStyle.css` 有详细注释，初学者如果想尝试自定义、美化词典界面，可以从这个 css 开始。

![image-20231001190542557](https://raw.githubusercontent.com/tisfeng/ImageBed/main/uPic/image-20231001190542557-1696158342.png)

### 参考

- [《柯林斯双解》for macOS](https://placeless.net/blog/macos-dictionaries)
- [Mdict to macOS Dictionary转换笔记](https://kaihao.io/2018/mdict-to-macos-dictionary/)
